## 1. Add Missing CL-Internal Accessors

- [x] 1.1 Add `primitive-procedure-id` accessor: `(defun primitive-procedure-id (proc) (cadr proc))`
- [x] 1.2 Add `parameter-cell` accessor: `(defun parameter-cell (param) (cadr param))`
- [x] 1.3 Add `procedure-name` accessor that wraps the `*procedure-name-table*` lookup (including the `(cdr entry)` fallback for qualified entries)

## 2. Reorder Definitions

- [x] 2.1 Move CL-internal predicates (`compiled-procedure-p`, `primitive-procedure-p`, `continuation-p`, `parameter-p`) and their accessors above the ECE-facing primitives block so the ECE predicates can delegate

## 3. Consolidate ECE Predicates

- [x] 3.1 Rewrite `ece-compiled-procedure?` to delegate: `(scheme-bool (compiled-procedure-p x))`
- [x] 3.2 Rewrite `ece-primitive?` to delegate: `(scheme-bool (primitive-procedure-p x))`
- [x] 3.3 Rewrite `ece-continuation?` to delegate: `(scheme-bool (continuation-p x))`

## 4. Replace Raw Checks and Access

- [x] 4.1 `format-ece-proc`: replace raw `(eq (car proc) '|compiled-procedure|)` with `compiled-procedure-p`, raw `(cadr proc)` with `compiled-procedure-entry`
- [x] 4.2 `format-ece-proc`: replace raw `(eq (car proc) '|primitive|)` with `primitive-procedure-p`, raw `(cadr proc)` with `primitive-procedure-id`
- [x] 4.3 `format-ece-proc`: use `procedure-name` accessor for the `*procedure-name-table*` lookup
- [x] 4.4 `extract-ece-backtrace`: replace raw `(or (eq (car item) '|compiled-procedure|) (eq (car item) '|primitive|))` with `(or (compiled-procedure-p item) (primitive-procedure-p item))`
- [x] 4.5 `apply-primitive-procedure`: replace `(cadr proc)` with `primitive-procedure-id`
- [x] 4.6 `do-continuation-winds`: replace `(cadddr cont)` with `ece-continuation-winds`
- [x] 4.7 `parameter-ref`: replace `(car (cadr param))` with `(car (parameter-cell param))`
- [x] 4.8 `parameter-set!`: replace `(cadr param)` with `(parameter-cell param)`
- [x] 4.9 `parameter-raw-set!`: replace `(cadr param)` with `(parameter-cell param)`

## 5. Verification

- [x] 5.1 Run `make test` — all suites pass (rove, ECE self-hosted, golden, conformance)
- [x] 5.2 Grep for remaining raw tag checks: no `(eq (car ...) '|compiled-procedure|)` outside the canonical predicate definitions
