## 1. Core Serializer (ECE-side)

- [x] 1.1 Implement `serialize-value` in prelude.scm — dispatch on type, produce tagged s-expression string
- [x] 1.2 Handle plain types: numbers, strings, chars, booleans (#t/#f), symbols, nil
- [x] 1.3 Handle pairs and proper lists (recursive serialization)
- [x] 1.4 Handle vectors as `(%ser/vector el0 el1 ...)`
- [x] 1.5 Handle hash tables as `(%ser/hash-table (k1 v1) (k2 v2) ...)`
- [x] 1.6 Handle compiled procedures as `(%ser/compiled-procedure entry env)` with space-qualified entry
- [x] 1.7 Handle continuations as `(%ser/continuation stack continue-reg)`
- [x] 1.8 Handle primitives as `(%ser/primitive name)` using primitive name table lookup
- [x] 1.9 Handle global env sentinel — detect global env frame, emit `(%ser/global-env)` instead of serializing all bindings

## 2. Shared Structure Detection

- [x] 2.1 Implement identity-scan pass — walk value graph, count occurrences of each object (by eq? identity)
- [x] 2.2 Emit `(%ser/def N value)` on first occurrence of shared objects
- [x] 2.3 Emit `(%ser/ref N)` on subsequent references
- [x] 2.4 Test: shared list structure preserved through round-trip

## 3. Core Deserializer (ECE-side)

- [x] 3.1 Implement `deserialize-value` — read s-expression, dispatch on tags to reconstruct values
- [x] 3.2 Handle plain types (pass through from reader)
- [x] 3.3 Handle `(%ser/vector ...)` — reconstruct vector
- [x] 3.4 Handle `(%ser/hash-table ...)` — reconstruct HAMT hash table
- [x] 3.5 Handle `(%ser/compiled-procedure entry env)` — reconstruct with space-qualified entry
- [x] 3.6 Handle `(%ser/continuation stack continue)` — reconstruct continuation
- [x] 3.7 Handle `(%ser/primitive name)` — look up current primitive ID by name
- [x] 3.8 Handle `(%ser/global-env)` — reconnect to current `*global-env*`
- [x] 3.9 Handle `(%ser/def N value)` and `(%ser/ref N)` — rebuild shared structure

## 4. File I/O Primitives

- [x] 4.1 Implement `save-continuation!` — open file, call `serialize-value`, write to port, close
- [x] 4.2 Implement `load-continuation` — open file, read with ECE reader, call `deserialize-value`, close
- [x] 4.3 Register as ECE functions (defined in prelude.scm, available after boot)

## 5. Tests

- [x] 5.1 Round-trip test: plain values (numbers, strings, booleans, symbols, chars)
- [x] 5.2 Round-trip test: lists and pairs
- [x] 5.3 Round-trip test: vectors
- [x] 5.4 Round-trip test: hash tables
- [x] 5.5 Round-trip test: compiled procedures (verify entry address preserved)
- [x] 5.6 Round-trip test: continuations (capture, save, load, invoke)
- [x] 5.7 Round-trip test: shared structure preservation
- [x] 5.8 Round-trip test: save-continuation! returns #t, file created
- [x] 5.9 ECE-native tests in test-serialization.scm (CL-side tests deferred — functions are now ECE-level)
- [x] 5.10 Run full test suite — all 431 tests pass
