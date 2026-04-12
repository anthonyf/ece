## Why

Stage 0 (`emit-host-primitives`, archived 2026-04-11) moved the implementation of every `core`/`cl` primitive into ECE-side templates and emits `bootstrap/primitives-auto.lisp` from them. The runtime still calls primitives the same way it always did — through `*primitive-dispatch-table*` lookup followed by `funcall`. That indirection is fine for the dynamic zone (REPL, late-loaded code, dispatched-by-ID instructions) but it leaves performance and codegen flexibility on the table for the compiled zone: the templates know exactly what each primitive does, and a per-space codegen can splice that body inline at the call site instead of routing through the table. Stage 1 of the self-hosting roadmap proves the templating infrastructure is suitable for inline substitution as well as defun emission, and lays the groundwork that Stage 3's WASM backend will later reuse.

## What Changes

- **NEW** `src/codegen-cl-inline.scm` — ECE program that walks a compilation space's instruction vector, identifies primitive call sites, and emits a per-space CL function whose body is the inlined translation of those instructions. Primitive call sites whose templates are simple enough are spliced in directly; the rest fall back to a `funcall` against the existing `ece-NAME` defun. The codegen reuses `*host-primitives*` and the template expander already living in `src/codegen-cl.scm`.
- **NEW** "compiled zone" runtime hook — `src/runtime.lisp` gains a small dispatch wrapper that, for each space, prefers a precompiled native function if one is registered for the entry PC, and otherwise falls through to the existing `execute-instructions` interpreter loop. The two zones share `*executing-space-id*`, `*global-env*`, the stack, and all helpers; switching from compiled to interpreted at runtime is allowed (call/cc into a native frame can resume in the interpreter and vice versa).
- **NEW** opt-in build path — `make compile-zone SPACE=<name>` (or an equivalent ECE entry point) generates the inline CL function for a single space and writes it to a sibling `bootstrap/<space>-zone.lisp` file. The runtime loads any such files it finds at boot. Stage 1 ships ONE space wired up end-to-end (likely `prelude` or a small dedicated benchmark space) as a proof of concept; the rest stay interpreted.
- **NEW** validation harness — a CL test that compiles the chosen space, loads its compiled-zone file, and runs the same suite that exercises the interpreted path. The two paths must produce identical results for every test, including ones that exercise `call/cc`, dynamic-wind, REPL function redefinition, and continuation serialization across the compiled/interpreted boundary.
- **MODIFIED** `src/codegen-cl.scm` — minor refactor to expose the per-primitive template expander as a reusable entry point that the inline codegen can call. No change to the existing defun emission path; `bootstrap/primitives-auto.lisp` regeneration stays byte-deterministic.
- **UNCHANGED** `*primitive-dispatch-table*`, `apply-primitive-procedure`, `init-primitive-dispatch-tables`, `bootstrap/primitives-auto.lisp`, the operations dispatch path, and `execute-instructions` itself. The dynamic zone is the source of truth and the safety net.

## Capabilities

### New Capabilities

- `inline-primitive-codegen`: Per-space inline-substitution codegen that walks an instruction vector, expands primitive templates from `*host-primitives*` at call sites, and emits a CL function whose body is the inlined translation. Covers the codegen entry point, the compiled-zone runtime hook, the interpreted/compiled boundary semantics (call/cc, redefinition, serialization), the build integration, and the parity-test harness.

### Modified Capabilities

None. `host-primitive-templates`, `primitive-manifest`, `portable-primitive-dispatch`, `instruction-executor`, and `generated-primitive-table` keep their existing requirements unchanged. Stage 1 only adds a new code path that runs alongside the existing dispatch-table path.

## Impact

- **Affected code**: `src/codegen-cl.scm` (small refactor), `src/codegen-cl-inline.scm` (new), `src/runtime.lisp` (compiled-zone hook + per-space loader, ~30 lines), `Makefile` (new target), one new test file in `tests/`.
- **Generated artifacts**: One sibling file per compiled space at `bootstrap/<space>-zone.lisp`. Stage 1 ships exactly one such file, generated from a representative space, checked in alongside `bootstrap/primitives-auto.lisp`.
- **Runtime behavior**: Functionally a no-op for the dynamic zone. For the compiled zone, primitive calls become direct CL forms instead of dispatch-table calls. Test parity is the gating criterion.
- **No API changes**: Primitive dispatch, the operation table, and the metacircular compiler are untouched. Existing `.ecec` files keep loading exactly as today.
- **Future-enabling**: Stage 2 (port `execute-instructions` to ECE) and Stage 3 (WASM backend) both reuse the per-space codegen tool. The CL backend in Stage 1 is the rehearsal — once it's correct and parity-tested, swapping the emitter for a WAT/JS one is mechanical.
- **Rollback**: Delete `bootstrap/<space>-zone.lisp`. The runtime will fall through to the interpreter for that space without code changes. Reverting the PR removes the new files entirely.
