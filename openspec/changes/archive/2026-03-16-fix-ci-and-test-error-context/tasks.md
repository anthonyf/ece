## 1. Fix CI exit code

- [x] 1.1 Update `.github/workflows/test.yml` to call `rove:run` directly and exit 1 on failure
- [x] 1.2 Verify locally that a failing test produces exit code 1

## 2. Fix test-error-context

- [x] 2.1 Update "error includes visible environment bindings" subtest to handle vector frames — check that innermost frame is a `simple-vector` containing `5` at index 0
- [x] 2.2 Run full test suite and confirm test-error-context passes
