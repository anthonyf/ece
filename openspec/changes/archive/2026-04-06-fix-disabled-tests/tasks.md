## 1. Rove Test Runner Fix

- [x] 1.1 Replace `rove/core/suite::suite-stats` call in Makefile with `rove:run` API that returns `(values passedp results)`
- [x] 1.2 Verify `make test-rove` exits 0 when all tests pass

## 2. Predicate Fixes (keyword?, platform-has?)

- [x] 2.1 Change `ece-keyword?` in `src/runtime.lisp` to check symbol name starts with `":"` instead of using CL `keywordp`
- [x] 2.2 Uncomment `keyword? on keyword` test in `tests/ece/common/test-misc.scm`
- [x] 2.3 Fix `ece-platform-has?` in `src/runtime.lisp` to return ECE `#f` (not CL `nil`) for unknown primitives
- [x] 2.4 Uncomment `platform-has?` tests in `tests/ece/common/test-misc.scm`
- [x] 2.5 Run `make test-ece` to verify predicate tests pass

## 3. Hash Table Serialization

- [x] 3.1 Add `hash-table?` branch to `serialize-value` in `src/prelude.scm` that detects CL native hash tables and emits `(%ser/hash-table ...)` format
- [x] 3.2 Uncomment `round-trip hash table` test in `tests/ece/cl-only/test-serialization.scm`
- [x] 3.3 Run serialization tests to verify hash table round-trip

## 4. Continuation Serialization Under Parameterize

- [x] 4.1 Add wind-frame filtering to continuation serializer — detect non-serializable objects in wind frames and emit `(%ser/wind-stripped)` sentinel
- [x] 4.2 Update `deserialize-value` to handle `(%ser/wind-stripped)` sentinel during continuation restoration
- [x] 4.3 Uncomment `round-trip continuation` test in `tests/ece/cl-only/test-serialization.scm`
- [x] 4.4 Uncomment `parameter in lexical scope captured by continuation` test
- [x] 4.5 Uncomment `round-trip recursive define in let body via call/cc` test
- [x] 4.6 Uncomment `lexical state pattern: save and load preserves all state` test
- [x] 4.7 Uncomment `loaded continuation reverts state to save time` test
- [x] 4.8 Uncomment `loaded continuation reverts multiple parameters` test
- [x] 4.9 Run full serialization test suite to verify all continuation tests pass

## 5. Compilation Unit Label Scoping

- [x] 5.1 Investigate `write-compiled-unit` label resolution failure when called from compiled ECE context
- [x] 5.2 Fix label scoping so `write-compiled-unit` operates on self-contained instruction sequences
- [x] 5.3 Uncomment `write-compiled-unit / read-compiled-unit round-trip` test in `tests/ece/cl-only/test-compilation-units.scm`
- [x] 5.4 Uncomment `round-trip with definition` test
- [x] 5.5 Run compilation unit tests to verify

## 6. Full Test Suite Verification

- [x] 6.1 Run `make test` (all suites) and verify all targets exit 0
- [x] 6.2 Confirm zero commented-out tests remain (or document clear reason for any that persist)
