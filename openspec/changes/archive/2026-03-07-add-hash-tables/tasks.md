## 1. Reader and Self-Evaluation

- [x] 1.1 Add `{` and `}` reader macros to `*ece-readtable*` that read `{k v ...}` and produce `(:hash-table (k . v) ...)`
- [x] 1.2 Add hash table check to `self-evaluating-p`: `(and (consp expr) (eq (car expr) :hash-table))`
- [x] 1.3 Add `hash-table` to package exports

## 2. Constructor and Predicate

- [x] 2.1 Implement `ece-hash-table` wrapper function (alternating key-value args) and register in `*wrapper-primitives*`
- [x] 2.2 Implement `ece-hash-table-p` predicate and register in `*wrapper-primitives*`

## 3. Accessors and Queries

- [x] 3.1 Implement `ece-hash-ref` (key lookup with optional default) and register
- [x] 3.2 Implement `ece-hash-has-key-p` and register
- [x] 3.3 Implement `ece-hash-keys` and `ece-hash-count` and register

## 4. Mutation and Functional Update

- [x] 4.1 Implement `ece-hash-set!` (mutate in place, preserve identity) and register
- [x] 4.2 Implement `ece-hash-set` (return new hash table, original unchanged) and register
- [x] 4.3 Implement `ece-hash-remove!` (remove key in place) and register

## 5. Tests

- [x] 5.1 Add tests for literal syntax, self-evaluation, and serialization round-trip
- [x] 5.2 Add tests for constructor, predicate, hash-ref, hash-has-key?, hash-keys, hash-count
- [x] 5.3 Add tests for hash-set!, hash-set, hash-remove!
- [x] 5.4 Run full test suite to verify no regressions
