## Context

ECE uses SICP 5.5's register-machine evaluator as its foundation. In SICP 5.5 the compiler emits a flat instruction list for whatever you pass to it, and all lambdas are lifted into that same list. ECE preserved that shape and wrapped it: one `.scm` file compiles to one `compilation-space` struct holding a flat instruction vector plus a label table. A compiled procedure is the tagged list `(compiled-procedure (space-id . local-pc) env)`. Every procedure defined in `prelude.scm` lives concatenated in one `prelude` space.

Dybvig's 1987 dissertation ("Three Implementation Models for Scheme") is the canonical departure point from SICP's teaching model toward a production model. Key bits we've ingested:

- §3.4.2: `(define compile (lambda (x next) ...))` — compile is a pure function. It takes an expression and a "next" continuation, returns an instruction DAG. No side effects.
- §3.2.3: the heap-model closure is `(body env vars)` — body IS the code, embedded as a first-class value. Called procedures don't look up a PC; they evaluate the body field directly.
- §3.4 — Lambda compiles to `(close vars (compile body '(return)) next)`. The inner lambda's compiled form is inlined into the outer's `close` instruction.
- Ch 4 — stack-based model (Chez's production shape) goes further: free variables pre-resolved, display closures, stack-allocated frames. We are **not** doing Ch 4 here; that's a future proposal.

ECE is partway between models already: it pre-resolves local variables (`(op lexical-ref) (const m) (const n) (reg env)`) like the stack model, but keeps rib-chain env and does symbol lookup for free vars like the heap model. This proposal keeps that split.

Related recent work: PR #162 added `disassemble` (`src/disassemble.scm`, `tests/ece/cl-only/test-disassemble.scm`). Its ~200-line implementation includes a reachability walk that exists purely because the compilation unit ≠ the procedure. That reachability walk is what motivated this change, so one measure of success is that `disassemble` shrinks dramatically.

Also recent: `%procedure-name-ref`/`%procedure-name-set!` (primitive ids 97, 240) use a side table `*procedure-name-table*` keyed on `(space-id . local-pc)`. Once code objects are the identity, the name becomes a field on the code object and that table retires.

## Goals / Non-Goals

**Goals:**

- Make the code object a first-class ECE value. `(code-object? x)` is a predicate; the compiler returns one; `disassemble` accepts one directly.
- Make the compiler pure: `(compile expr) → code-object`. No "append to current space."
- Closure shape: `(compiled-procedure <code-object> <env>)`, where `env` is today's rib-chain env.
- Preserve single-executor-loop, no-throw/catch dispatch. Code-object transitions use the same inline-state-update pattern `switch-space` uses today.
- Retire `*space-registry*` and `compilation-space` as runtime entities. Code-object grouping into `.ecec` archives is an *archive-file* concept, not a runtime one.
- `disassemble` becomes trivial: iterate `0..(code-object-length obj)`, emit instructions with inline labels. Reachability walk retires.
- Bootstrap story preserved: each `.scm` still produces one `.ecec`, but that `.ecec` now holds many code objects.
- Two-pass bootstrap is the migration path (matches existing CLAUDE.md convention).

**Non-Goals:**

- Display closures / free-var indices (Dybvig §4.4). Future proposal.
- Stack-based call frames (Dybvig Ch 4). Future proposal.
- Changing how `*global-env*` works, or any R7RS-visible semantics.
- Compile-to-host implementation. The `native-fn` slot exists but is left `#f`; populating it is a future proposal.
- Code-object equality beyond `eq?`.
- REPL sub-REPL / stepping / inspector (diagnostics threads 4, 6) — this change unlocks them but doesn't implement them.
- Removing `lookup-variable-value` for free vars. Unchanged.
- Performance optimization beyond what falls out naturally.

## Decisions

### Decision: Code object is a tagged value, ECE-visible

**What:** A code object is represented as `(code-object <instructions> <resolved> <labels> <meta>)`, tagged at head. Accessible from ECE via predicates and field accessors (`code-object?`, `code-object-instructions`, `code-object-labels`, `code-object-name`, etc.). On the CL runtime it's a defstruct; on WASM it's a struct; on ECE it prints as `#<code-object ...>`.

**Why not keep it internal?** The user explicitly confirmed (during explore): "code objects first-class at the ECE level — I think we do." First-class code objects let `disassemble`, a future `inspect`, a future stepper, and compile-to-host all operate on the same value. It's also the natural return type for a pure `compile`. Hiding it would require a facade whose only purpose is to be unwrapped.

**Why a tagged list shape for CL compat?** Matches the existing pattern for `(compiled-procedure ...)`, `(continuation ...)`, `(primitive ...)`. On CL the runtime uses defstructs internally for speed; the tagged list is how it appears to ECE (consistent with the primitives chapter in CLAUDE.md regarding tagged-type accessors staying primitive — see `project_tagged_type_primitives_not_portable.md`).

**Alternatives considered:**
- *Flat vector (no tag).* Rejected — breaks the ECE idiom, loses printability, and forces `code-object?` to guess.
- *ECE record via `define-record`.* Candidate; works today. Would mean the runtime and ECE both use the same record type via the generated accessors. Deferred to implementation: if records work cleanly in the compiler and executor, use them; otherwise fall back to the tagged-list shape.

### Decision: Closure shape is `(compiled-procedure <code-object> <env>)`

**What:** The second field, previously `(space-id . local-pc)`, becomes a direct code-object reference. The third field, `env`, is unchanged — today's rib-chain.

**Why:** User-confirmed (during explore): "if env is how we start environment today, then go with (code . env)." This matches Dybvig's heap-model closure `(body env vars)` (we drop `vars` because ECE already resolves locals by index at compile time). Minimal delta from today's shape.

**What existing code moves:**
- `compiled-procedure-entry` returns a code object now, not a `(sid . pc)` pair.
- Callers that dispatch on entry-pc (goto target resolution, continuation capture, etc.) now dispatch on code object + entry-local-pc (always 0 for a freshly-built procedure, since the procedure's body starts at its own PC 0).

**Alternatives considered:**
- *`(code . captured-vector)` flat closure (Ikarus/Chez).* Rejected for this change — user chose the simple path. Deferred to the "display closures" future proposal.
- *Retain `(sid . pc)` and map sid → code-object via registry.* Rejected — that's exactly what we're retiring. Keeping the registry would preserve the lookup overhead we want to eliminate.

### Decision: Compiler is a pure function `(compile expr) → code-object`

**What:** The top-level compile entry point is renamed / reshaped to return a fresh code-object value. No "compile into the current space." Nested lambdas compose bottom-up: compile inner first, reference its code object as a constant, then emit the outer that references it.

**Why:** User-confirmed: "Yes. This seems like clean design for ECE." Matches Dybvig §3.4.2 verbatim. A pure compiler composes naturally, supports REPL incremental compilation trivially, and makes testing the compiler a matter of comparing values.

**The `make-compiled-procedure` instruction changes operand shape.** Today it uses `(label entry)` — an assembler-resolved local label. After this change, the inner lambda has its own code object allocated bottom-up, and the outer's instruction becomes `(make-compiled-procedure (const <code-object>) (reg env))` — a constant reference to the child.

**Alternatives considered:**
- *Two-pass: emit placeholder, patch after compilation.* Rejected — adds backpatching complexity and doesn't match Dybvig's elegant bottom-up form.
- *Keep mutation but return the code-object.* Mixed semantics; rejected for clarity.

### Decision: Executor dispatch by code-object field access, not hash lookup

**What:** The CL executor today maintains `(space-id, instrs, ltab)` locals and does `get-space` (a hash lookup on `*space-registry*`) on cross-space transitions. After this change, the executor maintains `(code-obj, instrs, ltab)` locals. Transitions update those from the target code-object's fields directly. No hash lookup.

**Why:** The hash lookup was overhead we accepted to support cross-space calls. Code objects ARE the identity — `(goto (reg val))` where `val = (cons code-obj local-pc)` just sets the executor's current code-obj pointer. This makes cross-procedure dispatch *cheaper* than today, not more expensive, despite happening more often.

**Also kills the `*compiled-zone-functions*` hash.** Compiled-zone dispatch becomes a direct `code-object-native-fn` field access. Today it's another hash lookup per transition.

### Decision: `.ecec` becomes an archive of code objects, not a flat space body

**What:** The file format changes:

```
Current .ecec:                       New .ecec:
(ecec-header (space X)  ...)         (ecec-archive
<flat instruction list>                 (code-object ... source-map ...)
(ecec-header (space Y) ...)            (code-object ... name ...)
<flat instruction list>                 (code-object ... arity ...)
...                                     ...)
```

Each file still corresponds to one `.scm` source. "One file per .scm" is preserved for build simplicity and the Makefile doesn't need structural changes. What the file CONTAINS changes from "one-or-more flat spaces" to "an archive of code objects."

**Why not one .ecec per procedure?** Too many small files (thousands), slow to load, harder to manage. The archive-in-a-file shape (like JAR) is the right tradeoff.

**BREAKING.** Old `.ecec` files won't load. Migration: `make bootstrap` regenerates everything. Same pattern as every prior bootstrap schema change.

**Alternatives considered:**
- *One .ecec per procedure (JVM .class model).* Rejected — scale problem.
- *Whole-program .ecec (Smalltalk image).* Rejected — regresses on incremental build.

### Decision: Two-pass bootstrap migration

**What:** Same dance CLAUDE.md already documents for primitive migration. Pass 1: introduce code-object primitives in CL kernel + hand-bridge the `ece-NAME` defuns in `primitives-auto.lisp`; old space-keyed primitives coexist. Pass 2: `make bootstrap` regenerates all .ecec files under the new format. Pass 3: remove the old space-keyed primitives and re-bootstrap.

**Why:** Mandatory for any format-breaking change. Already a known pattern.

### Decision: `disassemble` and `%procedure-name-*` simplify, not change externally

**What:** `disassemble` now accepts: a compiled procedure, a symbol, OR a code object directly. Internally, a procedure unwraps to its code object and iterates 0..length. Reachability walk retires. `%procedure-name-ref` becomes a metadata field read on the code object; `%procedure-name-set!` stays for runtime naming of anonymous lambdas (rare, but used).

**External behavior:** same. All existing `disassemble` tests in `tests/ece/cl-only/test-disassemble.scm` must still pass.

**Why:** The whole point of the change. Measure of success: if `src/disassemble.scm` doesn't shrink substantially, something went wrong.

### Decision: Label namespace is per-code-object

**What:** Labels (L1, L2, ...) are local to a code object. Each code object has its own label table. `%space-label-ref` becomes `%code-object-label-ref`. Cross-procedure jumps don't exist (they go through the procedure-call ABI: `make-compiled-procedure` → push-arg → call → `goto (reg val)`).

**Why:** Labels are compile-time artifacts; they never need to cross a procedure boundary. Per-code-object keeps the label table small (most procedures have 2–5 labels). Enables the "alist for small, hash for large" memory optimization later if needed.

### Decision: Preserve current env representation (rib-chain)

**What:** Today's `((:hash-frame . ht) (#vector-frame ...) ...)` env chain is untouched. `lookup-variable-value` is untouched. `lexical-ref` addressing is untouched.

**Why:** User-confirmed (during explore): "If env is how we start environment today, then go with (code . env)." And user-confirmed rib-chain → free-var indices can be a later proposal. Keeping env unchanged means this proposal's risk is contained to *identity* of code, not *access* to variables.

### Decision: WASM parity preserved

**What:** The WASM executor (`wasm/runtime.wat`) gets the same shape change: `current-space-id` register becomes `current-code-obj` register. Struct definitions update. `%code-object-*` primitives implemented in WAT.

**Why:** WASM must stay runnable. The WASM executor already has a single-loop dispatch that's structurally parallel to the CL one; the changes mirror.

## Risks / Trade-offs

- **Risk: compile-to-host partial work.** ECE has compiled zones today (`.lisp` files generated from spaces). Those break under this change and need regeneration. **Mitigation:** regen is already part of `make bootstrap`; the zone files are generated, not hand-written. Update the codegen tool (`src/codegen-cl.scm`) to emit per-code-object CL functions.

- **Risk: performance regression on intra-file helper calls.** Same-space calls today can goto directly via label; after this, always cross-object (one more state update). Estimate +10–20% on mutual recursion patterns. **Mitigation:** benchmark fib (self-recursion, no change), ackermann (cross-procedure, expected hit), map-over-large-list (higher-order, no change) on a spike before merging. If worse than estimated, revisit.

- **Risk: bootstrap startup cost.** Creating many small code-objects instead of a few big spaces costs ~100–500ms one-time. **Mitigation:** acceptable. If measured higher, add lazy label-table allocation (alist for small, hash for ≥8 labels).

- **Risk: the archive .ecec format must round-trip.** Serialization and deserialization of code-objects must agree. **Mitigation:** add round-trip tests (compile → serialize → deserialize → execute, compare results).

- **Risk: .ecec files in `bootstrap/` are binary-indistinguishable from old format at load time → cryptic error.** **Mitigation:** include a format version tag in the new `.ecec`; loader errors with "this .ecec was produced by an older version — run `make bootstrap`."

- **Risk: cross-proposal coordination with `geiser-ece-day-4` and `ece-serve` (both in-progress).** **Mitigation:** this proposal shouldn't collide with either — they're in different files. If they land first, they rebase cleanly. If this lands first, they adjust to code-object shape (minor).

- **Trade-off: WASM parity doubles the implementation cost.** CL executor + WAT executor both need updating. **Mitigation:** WASM changes are mechanical translations of CL changes; do them in lockstep in the same PR.

- **Trade-off: `.ecec` archive inflates per-file overhead (one "archive wrapper" per file instead of one space header).** Minor — ~100 bytes per file over maybe 10 files. Not meaningful.

- **Trade-off: This proposal can't land in one PR cleanly.** It touches the executor, compiler, assembler, compile-system, bootstrap, WASM, and tests. **Mitigation:** sequence the work: (1) add code-object struct alongside space (coexistence); (2) switch compile to return code-objects while retaining space-based execution; (3) switch executor; (4) drop space. Each step is its own commit.

## Migration Plan

1. **Add `code-object` struct to CL runtime and WASM runtime.** Include fields: instructions, resolved-instructions, labels, name, arity, source-loc, native-fn. At this step, both spaces and code-objects coexist.
2. **Add `%code-object-*` primitives (new ids) on both runtimes.** Hand-add the `ece-NAME` defuns in `primitives-auto.lisp` per the chicken-and-egg bridge.
3. **Teach the compiler to emit code-objects alongside (or inside) the current space.** Initially: the outer file produces a space AND a code-object for each lambda. This lets us validate the code-object shape before committing the executor.
4. **Switch the closure representation.** `(compiled-procedure code-obj env)`. Update `compiled-procedure-entry` to return the code-object. Update `make-compiled-procedure` instruction to take a code-object constant.
5. **Switch the executor dispatch.** `execute-instructions` tracks current code-object. `switch-space` becomes `switch-code-object`.
6. **Retire the space struct and `*space-registry*`.** Remove `%space-*` primitives (leave `platform-has?` stubs). Update `disassemble` to use code-object primitives.
7. **Update `.ecec` format to archive-of-code-objects.** Update `compile-system` writer and the reader. Add format-version tag.
8. **Two-pass bootstrap.** First pass generates new-format .ecec files using still-present old primitives; second pass runs on new-format .ecec; third removes old-format support.
9. **Update codegen-cl.** Emit per-code-object CL `defun` instead of per-space tagbody.
10. **Regen WASM.** `wasm/runtime.wat` parallel changes, regenerate `runtime.wasm`.
11. **Update tests.** Most test surfaces are unchanged (ECE-level semantics). `disassemble` tests should still pass. `test-serialization.scm` continuation-size tests may shift (measure; don't patch until we see actual numbers).

Rollback: revert the PR. All `.ecec` files regenerate on `make bootstrap` from the previous state's sources.

## Open Questions

- **Code-object as ECE record vs tagged list?** Both work. Prefer record if `define-record` composes cleanly with the runtime's struct types; otherwise tagged list matching `(compiled-procedure ...)` pattern. Settle during implementation by trying the record path first.
- **Does the `native-fn` slot need a getter/setter primitive exposed to ECE, or stay purely a runtime field?** Leaning "runtime-only" — users shouldn't set native functions from ECE. Revisit if compile-to-host tooling needs it.
- **Serialization of code objects in continuations.** Today continuations serialize via s-expression form and use `(%ser/global-env)` for the global frame. Code objects in captured closures need a serialization rule. Proposal: serialize by reference to an `.ecec` file + code-object index within it, OR emit the whole instruction vector inline. Defer the concrete decision to implementation; both approaches work.
- **How do REPL-defined code objects get collected?** Once no closure references them, normal GC. But the REPL's global-env may hold the last reference via the binding. `(define foo ...)` → rebind → old code-object becomes garbage. Need a test that verifies this.
- **Should the label table be a field of the code object or embedded in the instruction vector?** Leaning "field" for accessibility. Revisit if memory pressure shows up.
