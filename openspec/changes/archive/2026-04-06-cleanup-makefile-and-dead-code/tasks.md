## 1. Makefile Cleanup

- [x] 1.1 Replace `run` target body with `run: repl` (prerequisite delegation, no recipe)
- [x] 1.2 Replace `clean-fasl` target body with `clean-fasl: clean` (prerequisite delegation, no recipe)
- [x] 1.3 Replace `TEST_OUTPUT_DIR := $(shell mktemp -d)` with `TEST_OUTPUT_DIR := .tmp/test-output`
- [x] 1.4 Add `@mkdir -p $(TEST_OUTPUT_DIR)` at the start of the `test-rove` recipe
- [x] 1.5 Ensure `.tmp/` is in `.gitignore`

## 2. Dead Code Removal

- [x] 2.1 Delete `*parameter-table*`, `*parameter-counter*`, and `ece-make-parameter-legacy` from runtime.lisp (lines 2162-2179)
- [x] 2.2 Delete the associated comment block (lines 2162-2167)

## 3. Verification

- [x] 3.1 Run `make test` — all suites pass
- [x] 3.2 Run `make clean` and `make clean-fasl` — both work
- [x] 3.3 Run `make repl` and `make run` — both launch REPL
- [x] 3.4 Verify `make clean` does not create a temp dir
