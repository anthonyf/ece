## 1. CL runtime: add code-object struct alongside spaces

- [x] 1.1 Add `code-object` defstruct to `src/runtime.lisp` with fields: `source-instructions`, `resolved-instructions`, `labels`, `name`, `arity`, `source-loc`, `native-fn`. Keep `compilation-space` struct in place for now (coexistence phase).
- [x] 1.2 Add CL helpers: `make-code-object`, `code-object-p`, field accessors. Export `code-object` from the `ece` package.
- [x] 1.3 Add `code-object?` predicate function to be exposed as an ECE primitive.
- [x] 1.4 Decide: CL struct + tagged-list facade for ECE, OR ECE `define-record` producing a struct both sides use. Prototype the record-path first; fall back to defstruct+facade if the record can't satisfy the executor's hot-path access patterns.

## 2. Primitive manifest: code-object primitives

- [x] 2.1 Reserve new primitive ids in `primitives.def` for: `code-object?`, `code-object-instructions`, `code-object-resolved-instructions`, `code-object-length`, `code-object-label-entries`, `code-object-label-ref`, `code-object-name`, `code-object-native-fn`, `code-object-source-loc`. Pick the next free ids (currently 241+).
- [x] 2.2 Add CL implementations in `src/primitives.scm` using `:cl` bodies.
- [x] 2.3 Register each in `src/boot-env.scm`.
- [x] 2.4 Hand-add the `ece-NAME` defuns to `bootstrap/primitives-auto.lisp` as the chicken-and-egg bridge (per CLAUDE.md), then regenerate via `touch src/primitives.scm && make bootstrap/primitives-auto.lisp`.
- [x] 2.5 Smoke-test each new primitive from a CL REPL script.

## 3. WASM parity for new primitives

- [x] 3.1 Add `$code-object` struct type in `wasm/runtime.wat` with fields mirroring the CL defstruct.
- [x] 3.2 Implement each new primitive (ids from §2.1) in the WAT dispatch block.
- [x] 3.3 Add integration tests in `wasm/test.js` that construct a code object and invoke each accessor; assert parity with the CL runtime's outputs for a shared set of fixtures.

## 4. Compiler: emit code objects bottom-up

- [x] 4.1 Change the top-level compile entry point (`mc-compile-and-go` or equivalent) to return a code object instead of mutating the current space. Keep the old entry point callable during coexistence with a shim that wraps the new one.
      *Implemented as a parallel `mc-compile-to-code-object` function (pure; returns a code-object). `mc-compile-and-go` unchanged during coexistence — the "shim" relationship collapses into a single call once the executor can run code-objects directly (§6).*
- [x] 4.2 Update lambda compilation: compile the inner body first, assemble it into its own code object, then emit the outer's `make-compiled-procedure` instruction referencing the inner code object as a constant operand. Verify with a trace that inner code objects are constructed before their outer references them.
      *Gated behind `*emit-code-object-lambdas*` parameter — bound `#t` by `mc-compile-to-code-object`, default `#f` for the bootstrap/`compile-file` path. The executor's `switch-space` handles code-object identity; `make-compiled-procedure` treats a code-object entry as `(cons entry 0)`. Tests cover nested lambdas (outer body holds child code-object), higher-order closures, and end-to-end execution.*
- [x] 4.3 Update the `procedure-name` pseudo-instruction to attach the name to the code object currently being assembled, not to a side table.
      *Implemented in `mc-compile-define`: in the bottom-up path the compiler holds the inner code-object value directly, so we skip the pseudo-instruction entirely and call `%code-object-set-name!` on the inner code-object at compile time. The label-based path keeps the pseudo-instruction + side-table flow.*
- [x] 4.4 Update the `procedure-params` pseudo-instruction similarly (code-object metadata, not a side table).
      *Same pattern as §4.3: `%code-object-set-arity!` writes the `(param-names . rest-flag)` pair directly to the inner code-object. Adds `code-object-arity` accessor primitive (id 257).*
- [x] 4.5 Update `compile-define` paths (both CL compiler and MC compiler) to pass the name through to the inner compile call so the generated code object has its name field set from the start.
      *Name threading happens in `mc-compile-define` as part of §4.3 — by the time `mc-compile-to-code-object` returns, the inner code-object already has its `name` field populated. Anonymous lambdas leave `name` as `#f`.*

## 5. Assembler: pure, per-code-object

- [x] 5.1 Rewrite `assemble` in `src/assembler.scm` as a pure function: `(assemble instruction-list) → code-object`. Build a fresh code object, walk the instruction list, push instructions into the code object's vectors, register labels in the code object's label table.
      *Implemented as `assemble-into-code-object co instrs` in src/assembler.scm (paired with §4.1). The `co` parameter makes allocation explicit; callers pass `(%make-code-object)` for a fresh object. Pure in the sense that it mutates only the passed-in object, not shared state.*
- [ ] 5.2 Retire `assemble-into-global` as the public entry point. Keep it as a thin shim during coexistence, but not beyond the final commit of this change.
      *Deferred — cleanup happens after §6 executor switch.*
- [x] 5.3 Retire operation resolution from its current "append to global resolved-instructions" shape; the code object now carries its own resolved-instructions vector.
      *`%code-object-push-instruction!` resolves operations per-code-object; `resolve-operations` applies to each instruction as it's pushed. The old `%space-*` path keeps its own resolution until §6 lands.*
- [x] 5.4 Add unit tests (under `tests/ece/common/`) for `assemble`: idempotence, fresh-object-per-call, label-table correctness, procedure-name field attachment.
      *Common-runtime tests for the mutator primitives live in `tests/ece/common/test-code-object-primitives.scm`; CL-specific compile+assemble tests (fresh-object-per-call, idempotence, label-table correctness, no-mutation) live in `tests/ece/cl-only/test-compile-to-code-object.scm`. Procedure-name attachment waits on §4.3.*

## 6. Executor: dispatch on code object

- [ ] 6.1 Update `execute-instructions` in `src/runtime.lisp` to track current code-object (renaming the `space-id` local to `code-obj`), `instrs`, `ltab` as before but sourced from the code object.
- [ ] 6.2 Update `switch-space` → `switch-code-object`. Target is a code-object value, not a symbol. Remove the `get-space` hash lookup — set `instrs`/`ltab` directly from code-object accessors.
- [ ] 6.3 Update the `goto (reg ...)` dispatch case: `(eq? (car addr) space-id)` becomes `(eq? (car addr) current-code-obj)`. The `addr` shape changes from `(space-id . local-pc)` to `(code-obj . local-pc)`.
- [x] 6.4 Update `execute-from-pc` to accept either a (code-obj . local-pc) pair or a bare code-obj (implying local-pc = 0).
      *CL primitive now dispatches on `(code-object-p start)` (bare) and `(consp start) && (code-object-p (car start))` (pair) before falling through to the legacy qualified-address path. Tests cover both shapes.*
- [x] 6.5 Replace `*compiled-zone-functions*` hash lookups with direct `code-object-native-fn` field reads.
      *`maybe-dispatch-compiled-zone` now reads `code-object-native-fn` directly when space-id is a code-object, and falls back to the hash lookup for legacy symbol-keyed spaces. Code-object native-fn defaults to #f so dispatch falls through to bytecode — populating the slot stays a future compile-to-host proposal.*
- [ ] 6.6 Parallel WASM executor changes in `wasm/runtime.wat`: `$current-space-id` → `$current-code-obj` (struct pointer). `$switch-space` → `$switch-code-obj`. Remove the `get-space` equivalent.

## 7. Closure shape and continuation shape

- [x] 7.1 Update `%make-compiled-procedure` to accept `(code-obj env)` and produce `(compiled-procedure code-obj env)`.
      *`make-compiled-procedure` now stores a bare code-object in the entry slot (no `(code-obj . 0)` wrapper). goto-reg dispatch gained a code-object branch that switches and sets `pc = 0`. qualified-space-id/qualified-local-pc recognise bare code-objects so the error path and execute-compiled-call still work.*
- [x] 7.2 Update `compiled-procedure-entry` to return the code object (its current callers expect a `(sid . pc)` pair; audit and update).
      *`compiled-procedure-entry` is unchanged — it returns whatever `make-compiled-procedure` stored. Callers audited: `procedure-name` now reads `code-object-name` directly for code-object closures; `execute-compiled-call` computes the return-pc from `code-object-resolved-instructions` when the entry is a code-object; the error-path already flows through the qualified-* helpers.*
- [x] 7.3 Update `%make-continuation` and the continuation dispatch path: saved `continue` becomes `(code-obj . local-pc)`.
      *Falls out of the executor/goto changes: the `(assign continue (label X))` handler already wraps with `space-id`, so when space-id is a code-object, continue stores `(code-obj . pc)`. The goto-reg cons-dispatch handles that shape unchanged.*
- [x] 7.4 Update the format machinery (`format-ece-proc`, disassemble header, error printers) to read names/source from the code object rather than the `*procedure-name-table*` side table.
      *`procedure-name` now reads `code-object-name` for code-object closures (§7.1). `format-ece-proc` reads `code-object-source-loc` for bare and paired code-object entries; legacy (symbol . pc) entries still flow through `resolve-ece-source-location`.*

## 8. .ecec archive format

- [ ] 8.1 Define the on-disk code-object archive format. Include: a format version tag, file name, and a sequence of code-object entries. Each entry carries its source-instructions, resolved-instructions (rebuilt at load time or serialized), labels, name, arity, source-loc.
- [ ] 8.2 Update `compile-system` to produce code-object archives: compile each `.scm` source, collect all code objects, emit them in order with the archive wrapper.
- [ ] 8.3 Update the `.ecec` reader (both CL and WASM) to parse the archive format, register code objects, and execute top-level init code in order.
- [ ] 8.4 Add a format-version mismatch diagnostic: a pre-this-change `.ecec` attempt yields a clear error message citing the format version and recommending `make bootstrap`.
- [ ] 8.5 Round-trip test: compile a `.scm`, write to `.ecec`, load from `.ecec`, execute, compare to direct-eval result.

## 9. Two-pass bootstrap

- [ ] 9.1 With code-object primitives present but `.ecec` still in old format, build: `make clean-fasl && make bootstrap`. Confirm the old format still loads via compatibility shim.
- [ ] 9.2 Switch `compile-system` output to the new archive format. Re-bootstrap; now `.ecec` files are new-format.
- [ ] 9.3 Remove the old-format compatibility shim from the loader. Re-bootstrap. Confirm the whole bootstrap loads exclusively via the new format.
- [ ] 9.4 Remove the space-struct-based primitive stubs (`%space-*` that retire) and their registrations in `boot-env.scm`. Re-bootstrap. Confirm everything still loads.

## 10. disassemble: simplify

- [ ] 10.1 Rewrite `src/disassemble.scm` to accept code objects directly in addition to compiled procedures and symbols.
- [ ] 10.2 Remove the reachability walk entirely. `dis/reached-pcs`, `dis/labels-at`, `dis/unreached-labels-in-span`, `dis/successors`, `dis/branch-target-pc` all retire or simplify.
- [ ] 10.3 New implementation: iterate `0..(code-object-length obj) - 1`, emit inline labels from `(code-object-label-entries obj)`, emit one instruction line per PC. Branch/goto annotations read targets from the code object's own label table.
- [ ] 10.4 Update `tests/ece/cl-only/test-disassemble.scm` to cover the new "disassemble a code object directly" path. Remove (or mark deferred) the "unreached labels in span" test if it's no longer reachable.
- [ ] 10.5 Manually verify that `disassemble` output for `square` is qualitatively similar (header + instructions + branch annotations) but noticeably smaller (reachability-walk padding retires).

## 11. Retire old primitives and dead code

- [ ] 11.1 Remove `%space-source-ref`, `%space-instruction-length`, `%space-label-entries`, `%space-label-ref`, `%space-name`, `%space-instruction-push!`, `%space-label-set!`, `%space-count`, `%create-space`, `%current-space-id`, `%set-current-space-id!` from `src/primitives.scm`, `src/boot-env.scm`, `primitives.def`, and the WASM runtime.
- [ ] 11.2 Remove `%procedure-name-set!` / `%procedure-name-ref` as side-table primitives. Replace their behavior with code-object metadata accessors (either retire the primitive ids, or repurpose them to read/write the code-object name field).
- [ ] 11.3 Remove the `*space-registry*`, `*procedure-name-table*`, `*procedure-params-table*` CL globals. Remove their WASM equivalents.
- [ ] 11.4 Remove the `compilation-space` defstruct once no code references it. Leave a deprecated typedef during a grace window if needed; otherwise delete outright.

## 12. Update generated files and codegen

- [ ] 12.1 Update `src/codegen-cl.scm` to emit per-code-object CL functions (one `defun` per code object) rather than per-space tagbody/go functions.
- [ ] 12.2 Regenerate `bootstrap/*-zone.lisp` via the updated codegen.
- [ ] 12.3 Verify the regenerated zone files load cleanly and no stale references to retired primitives remain.

## 13. Tests and regression coverage

- [ ] 13.1 Add `tests/ece/cl-only/test-code-objects.scm` covering: `(code-object? (compile expr))` is `#t`, fresh objects per call, length correctness, label-table correctness, name-field correctness for named defines and anonymous lambdas, native-fn default `#f`, nested-lambda bottom-up identity.
- [ ] 13.2 Add end-to-end compilation tests: `(disassemble (compile '(lambda (x) (+ x 1))))` produces expected output.
- [ ] 13.3 Add round-trip archive test: compile file → write .ecec → load .ecec → invoke defined procedure → compare to direct eval.
- [ ] 13.4 Run the full existing test suite: `make test`. All of `test-rove`, `test-ece`, `test-wasm`, `test-conformance`, `test-golden`, `test-web-server`, `test-web-apps` must pass.
- [ ] 13.5 Benchmark: fib(30), ackermann(3, 9), map-over-100K, deep let*-chain — compare against baseline (pre-change main) and confirm hot-path performance is within expected bounds (self-recursion ±0%, mutual recursion ≤+20%).
- [ ] 13.6 Benchmark startup: time `sbcl --eval '(asdf:load-system :ece)' --quit` against baseline; confirm ≤ +500ms.

## 14. Documentation and convention updates

- [ ] 14.1 Update CLAUDE.md's "Architecture: Compiler & .ecec Boot" section to describe the code-object model. Retire mentions of "compilation spaces" as the primary unit.
- [ ] 14.2 Update the "Browser Port: Compile-to-Host Strategy" section in CLAUDE.md to note that the `native-fn` slot is now per-code-object (cleaner than per-space).
- [ ] 14.3 Update `openspec/roadmap-if.md` if it references per-space assumptions.
- [ ] 14.4 Document the new `.ecec` archive format (either in a README next to `bootstrap/` or an OpenSpec note).

## 15. Review and PR

- [ ] 15.1 Code-reviewer subagent pass on changed files.
- [ ] 15.2 Self-review: contract audit (every spec scenario has a test), edge-case brainstorm, RFC walk of the executor and compiler changes.
- [ ] 15.3 Run `make test` cleanly one final time.
- [ ] 15.4 Commit on a feature branch, push, open PR. Include `/opsx:archive per-procedure-code-objects` in the same PR per project workflow.
- [ ] 15.5 On merge: bump anything that needs bumping (the .ecec format version tag should already be bumped as part of §8.1).
