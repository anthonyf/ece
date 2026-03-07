## 1. Create Prelude File

- [x] 1.1 Create `src/prelude.scm` with all stdlib definitions extracted from `ece.lisp`, written as native ECE (strip `(evaluate '...)` wrappers), preserving definition order

## 2. Update System Loading

- [x] 2.1 Add `ece-load` call in `ece.lisp` to load `src/prelude.scm` via `(asdf:system-relative-pathname :ece "src/prelude.scm")` after the evaluator is defined
- [x] 2.2 Remove all `(evaluate '...)` stdlib calls and the surrounding `*readtable*` switch block from `ece.lisp`
- [x] 2.3 Register `prelude.scm` as a `:static-file` component in `ece.asd`

## 3. Verify

- [x] 3.1 Run test suite and confirm all existing tests pass unchanged
