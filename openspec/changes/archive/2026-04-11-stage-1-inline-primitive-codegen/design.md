## Context

`emit-host-primitives` (Stage 0) moved every `core`/`cl` primitive into ECE-side templates and emits `bootstrap/primitives-auto.lisp` from them. The runtime still calls primitives through `apply-primitive-procedure` → `*primitive-dispatch-table*` → `funcall` indirection, exactly as it did before the migration. The benefit of Stage 0 was structural (one source of truth), not behavioral.

The compiler emits instructions like `(perform (op-fn #'apply-primitive-procedure) (reg proc) (reg argl))` for primitive calls; the executor's hot loop dereferences the proc, looks up the function pointer, and dispatches at runtime. For a fully compiled space — one whose code never changes after build — almost every primitive call site is statically resolvable: the compiler knows which primitive ID is being called, and the template tells us exactly what CL form to emit. Stage 1 is the codegen pass that turns those statically-resolvable call sites into inlined CL forms.

The architectural trick is the **dual-zone runtime**. Both zones share the same registers, environment, stack, helpers, and primitive defuns. The compiled zone is just a CL function whose body is the inlined translation of one space's instruction vector; the dynamic zone is `execute-instructions` running over the same vectors. The runtime can flow between them at any boundary — a continuation captured in the compiled zone can be resumed by the interpreter, a `(load ...)` invoked from compiled code creates a new dynamic-zone space, and a redefinition via the REPL takes effect for both zones because both go through `*global-env*` for variable lookup.

This design exists because Stage 3's WASM backend needs the same shape: there will be a "compiled WAT zone" for ahead-of-time code and a "dynamic WAT zone" running an interpreter over instruction vectors. Stage 1 rehearses that boundary in CL — same registers, same stack, same call/cc semantics — so that by the time Stage 3 ports `execute-instructions` and the codegen to WAT, the boundary is already proven.

The infrastructure already in place:
- `*host-primitives*` hash table populated by `(define-host-primitive ...)` forms in `src/primitives.scm`
- `expand-template` walks a quasiquoted template and substitutes parameters
- `*primitive-name-to-id*` and `*primitive-dispatch-table*` map names to IDs and IDs to functions
- `compilation-space` struct holds per-space instruction arrays and label tables
- `*executing-space-id*` is already a CL special; the same value works inside both zones

## Goals / Non-Goals

**Goals:**

- Walk a chosen compilation space's instruction vector and emit ONE CL function whose body is the inlined translation of those instructions.
- Inline primitive call sites: when the compiler emitted `apply-primitive-procedure` against a known primitive ID, the codegen replaces it with the expanded `:cl` template body, with parameters substituted from the appropriate registers / stack slots.
- Inline operation call sites the same way for the operation table (so `lookup-variable-value`, `extend-environment`, etc. become direct CL calls in the compiled zone).
- Wire the compiled-zone function into the runtime: when `execute-instructions` enters a space that has a registered compiled-zone function, it calls that function instead of running the dispatch loop. The function returns the same `(values ...)` shape that the executor maintains.
- Allow flow between zones: a `(goto)` to a label in another space, a continuation captured in the compiled zone resumed by the interpreter, a primitive that calls a compiled procedure that calls the interpreter that calls another primitive, all keep working.
- REPL function redefinition still affects compiled-zone code because compiled-zone calls to ECE-defined procedures still go through `*global-env*` lookup, not direct CL function references.
- Test parity: every test that passes against the interpreted prelude space passes when the prelude space is compiled. Including call/cc, dynamic-wind, continuation serialization, and tracing.
- Establish the codegen as ECE code (not CL) so the same tool ports to WAT/JS in Stages 2-3.

**Non-Goals:**

- Compiling EVERY space at build time. Stage 1 ships ONE space wired up end-to-end as a proof of concept; the rest stay interpreted by default.
- Replacing `*primitive-dispatch-table*` or `apply-primitive-procedure`. They remain the source of truth and are still called from the dynamic zone.
- Inlining ECE-level primitives (`equal?`, `gensym`, etc.) — those are already self-hosted in `src/prelude.scm` and have no template.
- Targeting WAT or JS. Stage 1 only emits CL.
- Porting `execute-instructions` to ECE. That is Stage 2.
- Source-level optimizations beyond template substitution: no constant folding, no dead-code elimination, no register allocation pass.
- Compile-time inlining of cross-space jumps. The codegen handles intra-space control flow inline; cross-space jumps fall back to a runtime call into the executor for the target space.
- Removing the dynamic zone. The REPL, `(load ...)`, and any space that hasn't been explicitly compiled keep using the interpreter.
- Performance benchmarking as a gate. Stage 1's success criterion is correctness parity, not speed. Performance work is a follow-up.

## Decisions

### 1. Codegen lives in ECE, not CL

**Choice**: `src/codegen-cl-inline.scm` is an ECE program (loaded the same way `codegen-cl.scm` is). It walks an instruction vector by calling the existing space introspection primitives (`%space-instruction-length`, `%space-source-ref`), reads templates from `*host-primitives*`, and emits CL source via the same emitter helpers in `codegen-cl.scm`.

**Rationale**: Same reason Stage 0 wrote the codegen in ECE — keeping build tooling on the right side of the language boundary, and positioning the same tool for eventual native compilation. Stages 2-3 will swap the CL emitter for a WAT one without changing the walker.

**Alternatives considered**:
- **CL codegen** — faster iteration loop initially but commits to a future rewrite. Rejected: violates `prefer-ECE-over-host` preference.
- **Two-phase codegen with a CL macro** — emit CL forms with a custom macro that expands at SBCL load time. Rejected: hides the codegen logic behind macroexpansion, harder to port to WAT.

### 2. Per-space CL function shape

**Choice**: Each compiled space becomes a CL function with the signature `(defun zone-NAME (initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack) ...)` returning `(values pc val env proc argl continue stack)` on zone exit. The body is a single big `tagbody` whose labels mirror the instruction vector's labels (with a `pc-N` tag for each PC), and whose forms are the inlined translation of each instruction.

**Rationale**: `tagbody` is CL's native structured-goto, which maps cleanly onto the instruction vector's `goto`/`branch` semantics. Each instruction becomes a small `(progn ...)` followed by `(go ...)` for branches and unconditional jumps. The function's return value lets the interpreter/compiled-zone hand off cleanly when execution leaves the space.

**Alternatives considered**:
- **Closure over registers** — return a function that captures lexical `let` bindings. Rejected: `tagbody/go` is faster and matches the instruction model exactly.
- **Trampoline of small functions** — one CL function per basic block. Rejected: dispatching between blocks reintroduces the indirection we're trying to remove.
- **CL `cond` over PC** — emit `(case pc ...)` and increment in a loop. Rejected: same indirection problem, no escape from the dispatch loop.

### 3. Inline primitive substitution at call sites

**Choice**: When the codegen sees a `(perform (op-fn #'apply-primitive-procedure) (reg proc) (reg argl))` instruction whose preceding instructions statically prove `proc` is a specific primitive (typically `(assign proc (const (primitive ID)))` followed by argl construction), it substitutes the primitive's `:cl` template body with the constructed arguments. The substitution emits the template body inline, NOT a `(funcall #'ece-NAME ...)`.

**Rationale**: Inlining the template body eliminates one level of indirection, gives SBCL's compiler full visibility into the primitive's body for further optimization, and proves that the `:cl` templates are reusable beyond `defun` emission. This is the "stage 1" point: validate the templates as reusable IR.

**When inlining is NOT possible** (the primitive isn't statically known, the arg list is dynamic, etc.), the codegen falls back to emitting `(funcall #'ece-NAME args...)` against the existing auto-generated defun. The fall-back path is the safety net — it's the same code Stage 0 already validated.

**Alternatives considered**:
- **Always emit funcall** — simpler but doesn't validate the templates as IR. Rejected: defeats the purpose of Stage 1.
- **Always inline (fail loudly when impossible)** — would reject valid programs. Rejected.

### 4. Dual-zone runtime hook

**Choice**: `execute-instructions` gains a small dispatch wrapper at entry: if the target `space-id` has a registered compiled-zone function (`*compiled-zone-functions*` hash table, keyed by space symbol), call it instead of running the dispatch loop. The compiled-zone function returns the same `(values ...)` tuple the executor uses internally, and the executor resumes from that state if the compiled function returned because of a cross-space jump.

The compiled zone is OPT-IN per space. A space without a registered compiled-zone function falls through to the existing dispatch loop unchanged. The default for every space is interpreted.

**Rationale**: Minimum surgery to `execute-instructions`. The hot path stays exactly as it was for the dynamic zone. The compiled zone gets a fast-path entry that bypasses the dispatch loop entirely.

**Alternatives considered**:
- **Replace `execute-instructions` with a compiled-only version** — too invasive, breaks the REPL. Rejected.
- **Compile the dispatch loop itself** — i.e., have one compiled-zone function per space that dispatches instructions like the interpreter does. Rejected: that's Stage 2 (porting `execute-instructions`).
- **Per-procedure compilation instead of per-space** — would require deeper integration with the compiler's procedure-name table. Rejected for Stage 1: per-space is the larger granularity that proves the boundary semantics, and per-procedure can be added later without changing the runtime hook.

### 5. Cross-zone calls go through `*global-env*`

**Choice**: A compiled-zone procedure that calls another ECE procedure looks the procedure up in `*global-env*` (or a captured lexical frame) exactly as the interpreted version did. It never embeds a direct CL function reference to another compiled-zone procedure — even if both end up compiled.

**Rationale**: This is the load-bearing decision for REPL function redefinition. If `(define foo ...)` re-evaluated at the REPL replaces the binding in `*global-env*`, the next call from compiled code picks up the new definition automatically because compiled code reads through `*global-env*`. If compiled code embedded direct CL references, redefinition would only affect the dynamic zone — a major regression.

**Alternatives considered**:
- **Direct CL refs with REPL invalidation** — feasible but complicates the REPL. Rejected: `*global-env*` is already the source of truth.
- **Per-call cache** — would need invalidation. Rejected: same reason.

### 6. call/cc and dynamic-wind across the boundary

**Choice**: Continuations captured in the compiled zone include the same `(stack continue winds)` triple that interpreted continuations have. Resumption uses the same `do-continuation-winds` and `*winding-stack*` machinery. The compiled-zone function's `tagbody` exits via the same `(values pc val ...)` return when `continue` points outside the current space, and the executor resumes from the continuation in whichever zone the target space lives in.

**Rationale**: This is exactly how the interpreted call/cc already works — the continuation is just a snapshot of register state. Compiling a procedure doesn't change the shape of the snapshot. The only thing the compiled zone has to do is honor `continue` correctly when exiting (which it already must to handle returns).

**Alternatives considered**:
- **CL-native continuations via `cl-cont`** — would couple us to a third-party library. Rejected.
- **Disable call/cc inside compiled spaces** — half-baked semantics, breaks dynamic-wind. Rejected.

### 7. Build integration: opt-in per space, sibling generated files

**Choice**: A new Makefile target `compile-zone SPACE=<name>` (or an ECE entry point) generates `bootstrap/<space>-zone.lisp` for one space at a time. The runtime loads any `bootstrap/*-zone.lisp` files it finds at boot, after `bootstrap/primitives-auto.lisp` and before `(boot-from-compiled)`. Stage 1 ships one such file checked in (probably for `prelude` or a small benchmark space), regenerated deterministically.

**Rationale**: Same model as Stage 0's `bootstrap/primitives-auto.lisp` — checked-in artifact, regenerated by `make`, byte-deterministic, rolls back via `git checkout`. The opt-in nature means the rest of the system stays interpreted and the new code path can be validated incrementally.

**Alternatives considered**:
- **Compile every space at boot** — too slow, breaks startup. Rejected.
- **Compile every space at build** — premature. Rejected for Stage 1; can be enabled later.
- **Inline the compiled code into the .ecec** — couples the .ecec format to a specific host. Rejected.

### 8. Choice of proof-of-concept space

**Choice**: TBD during implementation, but the candidate is `prelude` because it's the largest and most-exercised space, OR a small dedicated space (e.g., a benchmark loop) if `prelude` proves too invasive for the first attempt. The implementation will start with the smallest possible space (e.g., a hand-written 5-instruction test space) and grow from there.

**Rationale**: Starting tiny lets the parity test fail fast with a small diff. Once trivial cases work, we step up to a real space.

**Open**: Final choice depends on what the parity tests reveal during implementation.

## Risks / Trade-offs

- **[Boundary semantics are subtle]** — A continuation captured in compiled code that resumes inside the interpreter (or vice versa) must reconstruct the right register state. Mitigation: parity test exercises every test that touches call/cc against both the interpreted and compiled versions of the chosen space. Any divergence is a P0.

- **[REPL redefinition could break]** — If the codegen accidentally embeds a direct CL function reference (e.g., for an ECE-level helper that happens to be a CL function), redefining that helper at the REPL would only affect the interpreter. Mitigation: codegen unit test that captures the emitted code for a small test space and asserts every call goes through `lookup-variable-value` for ECE-level names.

- **[Tagbody size limits]** — SBCL's `tagbody` can hit compiler limits for very large bodies (the prelude space has ~20K instructions). Mitigation: split a space into multiple `tagbody` blocks if needed, with each block returning a continuation PC for the next block. Stage 1 will measure the prelude and split if necessary.

- **[`*executing-space-id*` updates]** — The compiled zone must update `*executing-space-id*` on cross-space jumps just like the interpreter does. Forgetting this would break primitives like `capture-continuation` that read it. Mitigation: codegen always emits `(setq *executing-space-id* 'target)` before any cross-space transition, and the parity test exercises continuation capture inside compiled code.

- **[Determinism]** — Same risk as Stage 0: identical inputs must produce byte-identical output. Mitigation: stable sort by PC order, deterministic naming for tagbody labels, no `gensym` in the emitter.

- **[Build pipeline order]** — `bootstrap/<space>-zone.lisp` depends on `bootstrap/primitives-auto.lisp` (the codegen reads `*host-primitives*` to expand templates). Mitigation: Makefile rule wires the dependency.

- **[Codegen runs against a fully booted ECE]** — Generating the compiled-zone file requires `*host-primitives*` populated, which means loading `src/codegen-cl.scm` and `src/primitives.scm`. Same chicken-and-egg as Stage 0; same recovery procedure (`git checkout` if regeneration breaks).

- **[Parity test doubles test runtime]** — Running every test against both zones doubles wall-clock time. Mitigation: parity test runs in CI but only for the one space we ship Stage 1 with; per-space gating can disable it for fast local iteration.

## Migration Plan

1. **Foundations**: extract a reusable `expand-host-primitive-template` entry point in `src/codegen-cl.scm`. No behavior change; just refactoring.

2. **Skeleton compiled zone**: write a tiny test program — a space with 5-10 instructions doing fixed arithmetic. By hand, write the equivalent CL `tagbody` form. Verify it produces the same final register state as the interpreter when run end-to-end.

3. **Codegen MVP**: implement `src/codegen-cl-inline.scm` with the walker, instruction-to-CL translator, and emitter. Run it against the toy space; diff against the hand-written version. Iterate until they match.

4. **Runtime hook**: add `*compiled-zone-functions*` and the `execute-instructions` entry-point check. Register the toy space's compiled-zone function manually. Run the toy program through both zones and confirm identical results.

5. **Parity test harness**: write a test that, given a space name, runs the same set of test programs through both the interpreted and compiled versions, comparing outputs. Initially run it against the toy space.

6. **Real space**: pick the first real candidate space. Generate, register, run the parity test. Fix any divergence. Iterate.

7. **call/cc and friends**: write targeted parity tests for call/cc, dynamic-wind, continuation serialization, and tracing inside the chosen space. Fix any divergence.

8. **Build integration**: add the Makefile target, check in the generated file, wire it into `make bootstrap`, document the regeneration command.

9. **Full validation**: run all four test suites (rove, ECE self-hosted, conformance, WASM) with the compiled space loaded. Confirm zero failures.

10. **Rollback**: delete `bootstrap/<space>-zone.lisp`. The runtime falls through to the interpreter for that space without code changes. Reverting the PR removes the new files entirely.

## Open Questions

- **Which space to compile first?** Smallest sensible candidate is a hand-rolled benchmark space; first realistic candidate is `prelude` or `compiler`. Defer to implementation; the parity test framework is the same regardless.
- **Should `*compiled-zone-functions*` live in `runtime.lisp` or in the generated file itself?** Likely the latter — each generated file does its own `(setf (gethash ...))` registration on load. Confirm during implementation.
- **Should the codegen emit CL declarations for type information?** Probably not for Stage 1 (parity over performance). Stage 1.5 follow-up.
- **How do we handle instructions the codegen doesn't yet understand?** Either fail loudly or fall back to a `(funcall #'execute-instructions ...)` against just that PC range. Decision deferred.
- **Should the parity test compile the chosen space FRESH for every test run?** Or load a pre-generated artifact? Both are useful; the build path uses the artifact, the test harness can do either. Decision deferred.
