## 1. Condition Type and Accessors

- [x] 1.1 Define `ece-runtime-error` condition class with slots: `original-error`, `ece-procedure`, `ece-arguments`, `ece-environment`, `ece-instruction`, `ece-backtrace`
- [x] 1.2 Define `report` method on `ece-runtime-error` that formats the error with procedure, arguments, bindings, and backtrace
- [x] 1.3 Export condition class and accessor symbols from the ECE package

## 2. Backtrace Extraction

- [x] 2.1 Implement `extract-ece-backtrace` that walks the register stack to find saved continue/proc pairs, limited to 10 frames
- [x] 2.2 Implement `format-ece-backtrace` to render the backtrace as readable text

## 3. Error Interception

- [x] 3.1 Wrap the `execute-instructions` tagbody loop body with `handler-bind` for `error` conditions
- [x] 3.2 In the handler, collect register state and signal `ece-runtime-error`
- [x] 3.3 Guard the handler body with `ignore-errors` fallback to original error on handler failure

## 4. Tests

- [x] 4.1 Test that unbound variable error includes procedure name and arguments
- [x] 4.2 Test that error includes visible environment bindings
- [x] 4.3 Test that original error is accessible via `ece-original-error`
- [x] 4.4 Test that nested calls produce a backtrace with multiple frames
- [x] 4.5 Test that `ece-runtime-error` condition slots are programmatically accessible
- [x] 4.6 Test that normal execution performance is not degraded
