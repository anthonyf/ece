## 1. ECE Reader (reader.scm)

- [x] 1.1 Remove `string-upcase` from `read-symbol` — intern symbol with original case
- [x] 1.2 Remove `string-upcase` from `read-number` fallback path (non-numeric tokens like `+`, `-`)
- [x] 1.3 Remove `string-upcase` from string interpolation identifier reading (`$identifier`)

## 2. CL Runtime (runtime.lisp)

- [x] 2.1 Update `ece-string->symbol` to intern without `string-upcase`
- [x] 2.2 Update `ece-symbol->string` to return `symbol-name` without `string-downcase`
- [x] 2.3 Update `ece-%intern-ece` docstring (no longer "already-upcased")
- [x] 2.4 Remove `string-upcase` from `create-space` and `find-space-by-name`
- [x] 2.5 Remove `string-upcase` from primitive loading (3 call sites in `setup-primitives` area)

## 3. CL-side Symbol References

- [x] 3.1 Audit and update CL-side code referencing ECE symbols by uppercase name
- [x] 3.2 Update CL-side test files that reference ECE symbols as uppercase
- [x] 3.3 Update executor case/ecase clauses to use lowercase pipe notation
- [x] 3.4 Update `get-operation` ecase to lowercase
- [x] 3.5 Update `resolve-operations` to lowercase
- [x] 3.6 Add `downcase-ece-symbols` for .ecec loading transition
- [x] 3.7 Add `ece-sym` helper for primitive function map building
- [x] 3.8 Update `write-to-string-flat` to use `:preserve` readtable-case
- [x] 3.9 Update serializer to use `symbol->string` instead of `write-to-string-flat` for symbols
- [x] 3.10 Update `continuation` type tag to lowercase

## 4. Bootstrap Rebuild

- [x] 4.1 Run `make bootstrap` to recompile all `.scm` → `.ecec` with lowercase symbols
- [x] 4.2 Verify the system boots cleanly and REPL works

## 5. Verification

- [x] 5.1 Run full test suite (all 492 ECE native + CL-side tests pass)
- [x] 5.2 Verify case-sensitive distinction: `foo` and `FOO` are different symbols
- [x] 5.3 Verify mixed-case symbols work: `myVar`, `HashMap`
- [x] 5.4 Verify `symbol->string` preserves case

## 6. Additional Fixes (discovered during implementation)

- [x] 6.1 Fix bare `t` → `#t` in prelude.scm `parameterize` macro
- [x] 6.2 Update Makefile bootstrap and test-ece targets for lowercase
- [x] 6.3 Fix paren balance in reader.scm after removing `(string-upcase ...)`
