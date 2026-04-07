## 1. Display/Write Refactor

- [x] 1.1 Extract `ece-output-to-stream` helper that takes `(obj stream print-fn)` with the shared cond tree (handles #f, #t, (), procedures, hash-tables, default)
- [x] 1.2 Rewrite `ece-display-to-stream` and `ece-write-to-stream` as thin wrappers calling the helper
- [x] 1.3 Rewrite `ece-%display-to-port` and `ece-%write-to-port` as thin wrappers calling the helper

## 2. Primitive Dispatch Bounds Check

- [x] 2.1 Add bounds validation before `(aref *primitive-dispatch-table* id-or-name)` in `apply-primitive-procedure` with descriptive error message

## 3. Port Accessor Cleanup

- [x] 3.1 Add `set-ece-port-line!` and `set-ece-port-col!` mutator functions next to the existing read accessors
- [x] 3.2 Replace raw `(setf (cadddr p) ...)` and `(setf (car (cddddr p)) ...)` in `ece-read-char` with the new mutators

## 4. Manifest Load Validation

- [x] 4.1 Add `probe-file` check before `with-open-file` in `parse-primitives-manifest`
- [x] 4.2 Add `probe-file` check before `with-open-file` in `parse-operations-manifest`
- [x] 4.3 Add non-empty validation after parsing each manifest

## 5. Verification

- [x] 5.1 Run `make test` — all suites pass
- [x] 5.2 Run `make repl` — REPL starts, `(display "hello")` and `(write "hello")` produce correct output
