## 1. Add Core Primitives to Hosts

- [x] 1.1 Add `truncate` (108) and `floor` (109) entries to primitives.def as `core`
- [x] 1.2 Add CL wrappers in runtime.lisp — `ece-truncate` using `(values (cl:truncate x))`, `ece-floor` using `(values (cl:floor x))`; register in `*wrapper-primitives*`
- [x] 1.3 Add WASM dispatch for IDs 108, 109 in runtime.wat — fixnum identity, float via `f64.trunc`/`f64.floor` with safe i32 conversion

## 2. ECE Definitions in prelude.scm

- [x] 2.1 Insert new "Integer arithmetic" section before derived predicates (before line 67): define `quotient`, `remainder`, `modulo`
- [x] 2.2 Insert "Rounding" section after derived predicates (after `even?`): define `ceiling`, `round` with banker's rounding

## 3. Bootstrap Pass 1

- [x] 3.1 Run `make bootstrap` with host modulo (ID 4) still present — generates new .ecec files where modulo is a compiled procedure
- [x] 3.2 Run CL test suite — verify all existing tests pass
- [x] 3.3 Verify `(modulo -13 4)` returns `3` on CL

## 4. Migrate modulo from Core to ECE

- [x] 4.1 Change primitives.def: modulo ID 4 platform from `core` to `ece`
- [x] 4.2 Remove `(modulo . mod)` from `*primitive-procedures*` in runtime.lisp
- [x] 4.3 Remove `i32.rem_s` dispatch for ID 4 from runtime.wat
- [x] 4.4 Run `make bootstrap` pass 2 — verify bootstrap succeeds without host modulo

## 5. Tests

- [x] 5.1 Add tests for `truncate` and `floor` (integer identity, positive/negative floats)
- [x] 5.2 Add tests for `quotient` and `remainder` (positive, negative dividend, negative divisor, both negative, identity property)
- [x] 5.3 Add tests for `modulo` with negative operands (the bugfix: -13 mod 4 = 3, 13 mod -4 = -3)
- [x] 5.4 Add tests for `ceiling` (positive/negative floats, integer identity)
- [x] 5.5 Add tests for `round` with banker's rounding (3.5→4, 4.5→4, negative values)
- [x] 5.6 Add test for division-by-zero propagation through ECE `modulo` and `quotient`
- [x] 5.7 Run full CL test suite including conformance tests (chibi-r5rs.scm:185 should pass)
