## Context

ECE has a complete set of port constructors (`open-output-string`, `open-input-string`, `open-output-file`, `open-input-file`) and exposes `current-output-port` / `current-input-port`. It has `make-parameter` and `parameterize`. On paper, R7RS output capture should already work. It does not, because of two independent shortcuts taken during earlier port work:

1. **`display`, `write`, `newline`, `write-char`, `write-string` are host primitives** in `src/runtime.lisp`. When called with no port argument, they write to CL's `*standard-output*` directly — not to any ECE-level "current port" value. The path from `(display x)` to output bypasses `current-output-port` entirely.
2. **`current-output-port` is a zero-argument CL accessor**, implemented as `(defun ece-current-output-port () *current-output-port*)`. It cannot be called with an argument to set a value, so the `parameterize` macro — which invokes the parameter with the new value as `(,param ,val)` — cannot rebind it.

The net effect is that `(parameterize ((current-output-port p)) ...)` either fails at the primitive call or silently has no effect on output, and no idiom for output capture exists in pure ECE. This blocks the ECE SDK test runner (ece-test) and the Dunge port.

Fixing this aligns with a standing goal in the project: minimize the CL kernel. The more that lives in `.scm`, the smaller the eventual WASM port surface. `display` and friends are thin wrappers — they belong in ECE.

## Goals / Non-Goals

**Goals:**
- `(parameterize ((current-output-port p)) ...)` rebinds output correctly for all of `display` / `write` / `newline` / `write-char` / `write-string`.
- Pure-ECE `with-output-to-string` and `with-input-from-string` are available.
- The CL kernel loses host implementations of `display` / `write` / `newline` and gains only low-level port primitives.
- Dynamic-wind interactions (errors, continuations) restore the outer port correctly.
- No behavior change for callers that already passed an explicit port argument.

**Non-Goals:**
- No changes to `read`, `read-char`, `peek-char`, `read-line` — these already take an optional port and honor it; their default-port wiring will be adjusted only as a trivial consequence of the `current-input-port` parameter change.
- No R7RS textual/binary port distinction.
- No bytevector ports or record-based port objects.
- No changes to file port open/close semantics.
- No tail-call or performance optimization of the new wrappers (one extra function call per `display` is acceptable).

## Decisions

### D1. Push the R7RS-surface procedures into prelude.scm

Move `display`, `write`, `newline`, `write-char`, `write-string` out of `runtime.lisp` entirely. Define them in `prelude.scm` as ECE procedures that delegate to low-level primitives:

```scheme
(define (display obj . port)
  (%display-to-port obj (if (null? port) (current-output-port) (car port))))

(define (write obj . port)
  (%write-to-port obj (if (null? port) (current-output-port) (car port))))

(define (newline . port)
  (%newline-to-port (if (null? port) (current-output-port) (car port))))
```

**Alternative considered:** keep `display` etc. as host primitives with optional port args, but have them call an ECE-callback primitive `%get-current-output-port` when no port is passed. Rejected because it requires a CL→ECE call on every output line, inverts the usual direction, and doesn't serve the kernel-minimization goal.

### D2. Low-level primitives are port-required, no ambient-port fallback

`%display-to-port`, `%write-to-port`, `%newline-to-port`, `%write-char-to-port`, `%write-string-to-port` MUST be called with an explicit port object. They have no 1-argument form. This keeps the primitive contract simple and pushes the "default port" policy entirely into ECE.

**Alternative considered:** give the primitives an optional port argument that falls back to `(current-output-port)`. Rejected — it just re-creates the bug we are fixing, and duplicates default-port logic in both kernel and prelude.

### D3. Initial ports come from boot-time primitives, not CL defvars

Define two new primitives:
- `%initial-output-port` → returns an output port wrapping the host's standard-output stream
- `%initial-input-port` → returns an input port wrapping the host's standard-input stream

These are called once during prelude load to produce the initial `make-parameter` values. They are NOT updated if the host swaps its standard streams later — the parameter is the sole source of truth after boot.

```scheme
(define current-output-port (make-parameter (%initial-output-port)))
(define current-input-port  (make-parameter (%initial-input-port)))
```

**Alternative considered:** keep `*current-output-port*` as a CL defvar and have the parameter's converter write back to it, so CL-side writes can "see" the ECE parameter value. Rejected because nothing in the CL kernel reads that defvar any longer — the primitives take explicit ports. Keeping the defvar around would be dead-code-by-symmetry.

### D4. Capture macros live in prelude.scm, built on parameterize

```scheme
(define-macro (with-output-to-string . body)
  `(let ((%p (open-output-string)))
     (parameterize ((current-output-port %p)) ,@body)
     (get-output-string %p)))
```

Same pattern for `with-input-from-string`, `with-output-to-port`, `with-input-from-port`. The existing `parameterize` macro already composes with `dynamic-wind` via its winding stack, so continuation-and-error restore semantics come for free.

**Alternative considered:** implement capture as a primitive that runs a thunk with a swapped CL stream. Rejected — same "inversion of control" problem as D1's alternative, and bypasses `parameterize` so nested capture in Scheme-level parameter-sensitive code would not work uniformly.

### D5. Two-pass bootstrap protocol

Because existing `.ecec` files contain compiled calls to the host `(display ...)` primitive (ID assigned in current `primitives.def`), we cannot simply remove the host primitives in one step. The migration:

1. Add new primitives `%display-to-port` (etc.) and `%initial-*-port` to `primitives.def` and `runtime.lisp`. Keep the old `display` / `write` / `newline` / `write-char` / `write-string` host primitives in place.
2. Add the ECE wrappers in `prelude.scm` under a different name initially (e.g., `display-new`) OR: gate the wrapper on a compile-time flag. Simpler: just add them and accept the name collision — ECE's `define` rebinds the earlier host primitive.
3. Run `make bootstrap` to regenerate `.ecec` files. New files now refer to the ECE wrappers, which call `%display-to-port`.
4. Remove the old `display` / `write` / `newline` / `write-char` / `write-string` host primitives from `runtime.lisp` and `primitives.def`.
5. Run `make bootstrap` again to verify the system bootstraps cleanly without the host primitives.
6. Remove `*current-output-port*` / `*current-input-port*` CL defvars and their accessors (now entirely unused).

**Alternative considered:** one-pass migration by renaming the new primitives and rewriting `.ecec` in-place. Rejected — more complex than two bootstraps, and the two-pass pattern is already established project practice (per memory's "Known Pitfalls").

### D6. WASM runtime mirrors the CL kernel

The `wasm/runtime.wat` implementation also exposes `display` / `write` / `newline` as primitives. It must receive the same treatment: add `%display-to-port` (etc.) in WAT, remove the old forms in the second pass. Since the primitive IDs are shared via `primitives.def`, the two runtimes stay in lock-step.

## Risks / Trade-offs

- **[Risk] Two-pass bootstrap can leave the tree in an intermediate state.** → Mitigation: document the exact command sequence in `tasks.md`. Each pass runs `make bootstrap`, which is idempotent.
- **[Risk] Existing test that does `(display x)` without a port may behave differently if it previously depended on CL side-effects.** → Mitigation: initial port wraps `*standard-output*`, so default behavior is byte-for-byte unchanged at boot. Only code that tried to swap `*current-output-port*` on the CL side would notice — and as established, that never actually worked for the affected primitives.
- **[Risk] Per-call `(current-output-port)` lookup on every `display` adds overhead (a parameter dereference).** → Mitigation: this is cheap (one function call + one pair access in the parameter table). If it ever matters, we can inline in the compiler later.
- **[Trade-off] `display` and `write` become variadic (`obj . port`) instead of fixed-arity in the primitive table.** That's the same shape they already had externally; only the implementation moves.
- **[Risk] WASM runtime drift.** If the WASM port lags, `wasm-integration-tests` will fail until both kernels have the new primitives. → Mitigation: land WAT changes in the same change, don't ship a half-migrated primitives.def.
- **[Risk] `write-to-string` (internal CL helper) may still reference `*current-output-port*`.** → Mitigation: audit `runtime.lisp` before removing the defvars; any remaining reference is dead-code to clean up.

## Migration Plan

1. Two-pass bootstrap as described in D5.
2. WASM runtime changes land in the same PR.
3. Re-run the full test battery: `make test-rove`, `make test-ece`, `make test-wasm`, `make test-conformance`, `make test-web-apps`.
4. Commit updated `bootstrap/bootstrap.ecec`, `primitives.def`, `operations.def` (if changed), `wasm/runtime.wasm` binary.
5. No rollback script needed — revert the PR and re-bootstrap.

## Open Questions

- **Q1.** Should the R7RS `write-string` variant accept optional `start` / `end` substring arguments now, or track that separately? (Lean: track separately — out of scope for this change.)
- **Q2.** Does `write-char` need an `(optional port)` variant on the CL side for FFI-style callers? (Lean: no — CL callers that need byte output already use port primitives directly.)
