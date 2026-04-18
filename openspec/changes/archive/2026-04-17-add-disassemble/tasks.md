## 1. Host primitive `%procedure-name-ref`

- [x] 1.1 Add `%procedure-name-ref` to `src/primitives.scm` directly below `%procedure-name-set!` (primitives.scm:351). Body: `:cl `(cl:gethash ,pc-or-qualified *procedure-name-table*)`. Accept the same key shape as the setter (bare PC integer or `(space-id . local-pc)` pair).
- [x] 1.2 Export `%procedure-name-ref` from the `ece` package alongside `%procedure-name-set!`.
- [x] 1.3 Regenerate CL side: `make clean-fasl && make` to pick up the new primitive.
- [x] 1.4 Quick smoke test at REPL: `(%procedure-name-set! '(foo . 0) "hello")` then `(%procedure-name-ref '(foo . 0))` should return `"hello"`; `(%procedure-name-ref '(foo . 1))` should return `#f`.

## 2. Self-hosted `disassemble` skeleton

- [x] 2.1 Create `src/disassemble.scm` with module header and a stub `(define (disassemble x) ...)` that dispatches on input type and prints a placeholder.
- [x] 2.2 Add `src/disassemble.scm` to the bootstrap compilation list (wherever `prelude.scm`, `compiler.scm`, etc. are listed). Run `make bootstrap` and confirm the new `.ecec` is produced and loads cleanly.
- [x] 2.3 Export `disassemble` from the `ece` package.

## 3. Input dispatch and error paths

- [x] 3.1 Implement symbol → global lookup branch: given a symbol, call the appropriate global-env lookup primitive; on unbound, print `"no global binding for `<name>`"` and return.
- [x] 3.2 Implement `compiled-procedure?` branch (happy path hooks into §4/§5 below).
- [x] 3.3 Implement error branches for primitives, continuations, and other values, each producing the scenario text from `specs/procedure-disassembler/spec.md`. Use `write-to-string-flat` for value formatting where needed.
- [x] 3.4 Write a tiny test at the REPL for each error branch and confirm output matches spec scenarios.

## 4. Reachability walk

- [x] 4.1 Write `(reached-pcs space-id entry-pc)` returning a set (list with no duplicates, or a hash set) of PCs reachable from `entry-pc` within that space.
- [x] 4.2 Algorithm: worklist initialized with `entry-pc`; at each PC, examine the source instruction; add successors:
  - `(goto (label L))` → add `(%space-label-ref space-id L)` if known; no fall-through.
  - `(goto (reg <r>))` → no static successor; no fall-through (return from procedure or indirect jump).
  - `(branch (label L))` → add `(%space-label-ref space-id L)` AND fall through to PC+1.
  - any other instruction → fall through to PC+1.
- [x] 4.3 Bound the walk by `%space-instruction-length` to avoid reading past the vector end; if walk would exceed, stop and silently cap (compiler bug, but don't crash).
- [x] 4.4 Unit-test reachability on a simple `(define (square x) (* x x))` — verify the set is contiguous and ends at the expected `goto (reg continue)`.
- [x] 4.5 Unit-test on a `(define (outer) (let ((f (lambda (x) x))) (f 1)))` — verify the reached set does NOT include the inner lambda's body instructions.

## 5. Label index and print

- [x] 5.1 Build a PC → list-of-label-names map from `(%space-label-entries space-id)`, keyed only on PCs in the reached set.
- [x] 5.2 Compute target-PC for each instruction whose head is `goto` or `branch` with a `(label ...)` operand; store as an annotation for printing.
- [x] 5.3 Compute header text: procedure name via `%procedure-name-ref` on the entry (try both the `(space . pc)` key and bare PC key); default `<anonymous>`. Space name via `%space-name`. Also note `compiled-fn` presence — if the space's `compiled-fn` is non-nil, include the compiled-zone note. (Note: no primitive exists yet to query `compiled-fn`; use `%space-name` only for the address and skip the compiled-zone note in v1 if this primitive is missing. If missing, add a small `%space-compiled-to-host?` primitive — counts against kernel delta; only do so if it keeps the code simple. Otherwise defer the compiled-zone note to a follow-up.)
- [x] 5.4 Print loop: for each PC in the reached set in ascending numeric order:
  - emit label lines for any labels at this PC
  - emit the instruction line (padded PC + source form via `write-to-string-flat` + optional `; → pc N` annotation)
- [x] 5.5 Surface unreached labels whose PC falls within `[min(reached), max(reached)]` but not in the reached set; print them in the header under an "unreached labels in span" section.

## 6. Tests

- [x] 6.1 Create `tests/test-disassemble.scm` (or matching the project's test file pattern).
- [x] 6.2 Test: `(disassemble square)` for a trivial compiled procedure emits at least one instruction line and a header containing the name.
- [x] 6.3 Test: `(disassemble 'square)` output equals `(disassemble square)` output.
- [x] 6.4 Test: `(disassemble 'does-not-exist)` output contains `no global binding` and `does-not-exist`.
- [x] 6.5 Test: `(disassemble car)` output contains `primitive` and `car`.
- [x] 6.6 Test: `(disassemble 42)` output contains `not a compiled procedure`.
- [x] 6.7 Test: for a procedure containing an inner lambda, assert the inner lambda's distinctive body instructions are NOT in the output.
- [x] 6.8 Test: branch annotation — find an output line with `branch` or `goto (label ...)` and assert a `; → pc` annotation is present with a valid integer.
- [x] 6.9 Wire the new test file into whatever runs under `make test-ece` (or the appropriate `make test-*` target per Makefile).

## 7. Bootstrap & validation

- [x] 7.1 Run `make bootstrap` end-to-end; confirm the two-pass migration (new primitive, then `.ecec` regen) succeeds.
- [x] 7.2 Run `make test-ece` (and any other test target that exercises ECE) — all green.
- [x] 7.3 Run `make test` (full suite — rove, ECE, conformance, WASM, web) per user preference `feedback_run_all_tests`. All green before PR.
- [x] 7.4 Clean up any leftover background SBCL/node processes.

## 8. Review & PR

- [x] 8.1 Code-reviewer subagent pass on changed files.
- [x] 8.2 Self-review: contract audit (every spec scenario exercised by a test?), edge-case brainstorm, walk the generated `.ecec` diff.
- [x] 8.3 Update `CLAUDE.md` only if a discoverable pitfall emerged; otherwise leave it alone.
- [x] 8.4 Commit on a feature branch, push, open PR. Include `/opsx:archive add-disassemble` in the same PR per project workflow.
