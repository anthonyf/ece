## 1. Flatten compile-file output

- [x] 1.1 Modify `compile-file` in `src/compilation-unit.scm` to collect all compiled units' instruction lists into a single merged list, inserting explicit `(assign env (op lookup-variable-value) (const *global-env*) (reg env))` between units
- [x] 1.2 Modify `write-compiled-unit` (or add `write-flat-ecec`) to write the merged instruction list with one instruction per line, labels on their own lines
- [x] 1.3 Verify that `compile-file` still handles `define-macro` forms correctly — compile-time execution before subsequent forms
- [x] 1.4 Test: compile a small .scm file, inspect the .ecec output visually to confirm flat format and readability

## 2. Update CL loader

- [x] 2.1 Modify `load-ecec-file` in `src/runtime.lisp` to read a single instruction list instead of looping over units
- [x] 2.2 Add temporary migration shim: detect old multi-unit format (second read returns a list whose car is a list of instructions) vs new flat format, handle both during transition
- [x] 2.3 Test: load a flat .ecec file on CL, verify it boots and executes correctly

## 3. Update WASM loader

- [x] 3.1 Simplify `load_ecec` in `wasm/runtime.wat` to single-pass scan of one instruction list (remove multi-unit boundary tracking)
- [x] 3.2 Update `wasm/glue.js` if any format-parsing changes are needed
- [x] 3.3 Test: load a flat .ecec file on WASM, verify it boots and executes correctly

## 4. Two-pass bootstrap migration

- [x] 4.1 First pass: boot from existing multi-unit .ecec files (using migration shim), recompile all .scm → new flat .ecec files
- [x] 4.2 Second pass: boot from new flat .ecec files, recompile again, verify output matches first pass (idempotence check)
- [x] 4.3 Commit the new flat .ecec files in `bootstrap/`
- [x] 4.4 Remove migration shim from CL loader (old format no longer needed)

## 5. Golden-file test infrastructure

- [x] 5.1 Create `tests/golden/` directory with 4-6 small .scm files exercising key compiler features: basic arithmetic, closures, tail calls, call/cc, macros, conditionals
- [x] 5.2 Ensure deterministic label names: reset gensym counter (or normalize labels) before compiling golden files
- [x] 5.3 Compile golden .scm files and save output as `.expected` files (flat instruction lists without ecec-header)
- [x] 5.4 Add `make test-golden` target that recompiles golden files and diffs against .expected
- [x] 5.5 Add `make update-golden` target that overwrites .expected files with current compiler output
- [x] 5.6 Add golden test step to `.github/workflows/test.yml`

## 6. Final validation

- [x] 6.1 Run full test suite on CL: `make test-ece`
- [x] 6.2 Run full test suite on WASM: `make test-wasm`
- [x] 6.3 Run golden tests: `make test-golden`
- [x] 6.4 Run bootstrap idempotence check: compile, boot from output, recompile, diff
- [x] 6.5 Verify .ecec files are human-readable: inspect `bootstrap/prelude.ecec` line count and structure
