## 1. Prelude wrapper

- [x] 1.1 Add `make-parameter` wrapper that applies converter and passes both value+converter to raw primitive

## 2. CL simplification

- [x] 2.1 Simplify `ece-make-parameter-value` to store value+converter without re-applying converter (prelude already applied it)

## 3. Validate

- [x] 3.1 Bootstrap rebuilt (double pass)
- [x] 3.2 CL tests: 496 passed, 0 failed
- [x] 3.3 WASM tests: 329 passed, 0 failed
