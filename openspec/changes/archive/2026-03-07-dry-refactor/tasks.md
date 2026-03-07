## 1. Consolidate Primitive Alist

- [x] 1.1 Define `*primitive-procedures*` as the single alist, replace `*primitive-procedure-names*` and `*primitive-procedure-objects*` to derive from it
- [x] 1.2 Extract wrapper primitives into a `*wrapper-primitives*` alist, replace verbose dolist block with a loop over the alist
- [x] 1.3 Run tests to verify no regressions

## 2. Generate Special Form Predicates

- [x] 2.1 Define a `define-special-form-predicate` macro and use it to generate all 10 predicate functions, removing the hand-written versions
- [x] 2.2 Run tests to verify no regressions
