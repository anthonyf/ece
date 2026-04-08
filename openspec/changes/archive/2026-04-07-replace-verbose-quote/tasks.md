## 1. Replace verbose quote in prelude

- [x] 1.1 Replace `(quote ())` → `'()` in `reverse`, `map`, `filter`, `for-each`, `iota`, `set-difference` (6 instances)
- [x] 1.2 Replace `(quote else)` → `'else` in `cond` and `case` macro definitions (2 instances)

## 2. Replace verbose quote in tests

- [x] 2.1 Replace `(quote (x y))` → `'(x y)` and `(quote ())` → `'()` in `test-roundtrip.scm`

## 3. Verify

- [x] 3.1 Run `make test-wasm` to confirm no regressions
