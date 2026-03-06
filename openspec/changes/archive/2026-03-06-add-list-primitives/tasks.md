## 1. Add CL-backed primitives

- [x] 1.1 Add `cadr`, `caddr`, `caar`, `cddr` to primitive procedure lists
- [x] 1.2 Add `append`, `length` to primitive procedure lists
- [x] 1.3 Add `pair?` primitive (mapped to CL `consp`)
## 2. Add apply special form

- [x] 2.1 Add `apply-form-p` predicate and `apply` to `*special-forms*`
- [x] 2.2 Add dispatch clause for `apply` in `ev-dispatch`
- [x] 2.3 Implement `ev-apply`, `ev-apply-did-proc`, `ev-apply-dispatch` continuation handlers: evaluate proc, evaluate arg list, set argl/proc, jump to `:apply-dispatch`

## 3. Add ECE-defined functions

- [x] 3.1 Define `map` as an ECE function using `define` in `*global-env*` (single-list map using recursion)

## 4. Export and test

- [x] 4.1 Export new symbols (`pair?`, `map`, `apply`) from ece package (cadr/caddr/caar/cddr/append/length are CL symbols, already available)
- [x] 4.2 Add tests for all new primitives, map, and apply
