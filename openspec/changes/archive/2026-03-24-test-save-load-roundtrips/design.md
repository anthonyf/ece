## Approach

Add integration tests in `wasm/test.js` that exercise `serialize-value` / `deserialize-value` and `save-continuation!` / `load-continuation` through `eval-string`. Each test serializes a value, reads it back, and checks `equal?`.

## Test Categories

### 1. In-memory round-trips (`serialize-value` → `deserialize-value`)
Use the pattern:
```scheme
(equal? (deserialize-value (read (open-input-string (serialize-value VAL)))) VAL)
```
Cover: fixnum, string, symbol, boolean, nil, dotted pair, proper list, nested list, vector, compiled procedure (identity check on entry point).

### 2. File-based round-trips (`save-continuation!` → `load-continuation`)
Use the pattern:
```scheme
(begin (save-continuation! "/tmp/ece-test.dat" VAL)
       (equal? (load-continuation "/tmp/ece-test.dat") VAL))
```
Cover: list, vector, nested structure.

### 3. Shared structure
Verify that values appearing multiple times in a tree serialize with `%ser/def` / `%ser/ref` tags and round-trip correctly:
```scheme
(let ((x (list 1 2)))
  (let ((v (list x x)))
    (equal? ... v)))
```

### 4. Continuation round-trip
Capture a continuation with `call/cc`, serialize it, deserialize it, and verify it can be invoked:
```scheme
(call/cc (lambda (k) (save-continuation! "/tmp/k.dat" k) ...))
```

## Key Decisions

- All tests use `eval-string` / `eval-string-last` — no new WASM exports needed.
- Tests compare with `equal?` and check the result is truthy (type 1 or 10 in `dbg_type`).
- Existing type-only serialization tests in `wasm/test.js` are replaced by the semantic round-trip versions.
- Temp files use `/tmp/ece-test-*.dat` and are cleaned up after each test.

## Risks

- Continuation serialization may not yet work end-to-end (compiled-procedure env reconstruction). If so, mark those tests as known-failing with a comment and skip.
