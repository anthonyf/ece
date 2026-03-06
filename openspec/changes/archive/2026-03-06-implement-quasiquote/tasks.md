## 1. Core Quasiquote

- [x] 1.1 Add `quasiquote-p` predicate and add `quasiquote` to `*special-forms*`
- [x] 1.2 Implement `qq-expand` — pure CL function that walks a template and produces cons/append construction expressions
- [x] 1.3 Add `ev-quasiquote` handler that calls `qq-expand` and re-dispatches the result
- [x] 1.4 Export `quasiquote`, `unquote`, `unquote-splicing`

## 2. Reader Support

- [x] 2.1 Create `*ece-readtable*` with reader macros for `` ` `` → `quasiquote`, `,` → `unquote`, `,@` → `unquote-splicing`
- [x] 2.2 Update `ece-read` to bind `*readtable*` to `*ece-readtable*`

## 3. Tests

- [x] 3.1 Add tests for quasiquote with all-literal templates and atomic templates
- [x] 3.2 Add tests for unquote (variable, expression, tail position)
- [x] 3.3 Add tests for unquote-splicing (list splice, empty list splice)
- [x] 3.4 Add test for quasiquote in macro definition
