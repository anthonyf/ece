## 1. CL Runtime Changes

- [x] 1.1 Add `parameter-p` predicate and `ece-parameter-p` wrapper
- [x] 1.2 Add `ece-make-parameter-value`: returns `(parameter (<value> . <converter>))`, applies converter via `apply-ece-procedure`
- [x] 1.3 Add `parameter-ref`: read value from cell
- [x] 1.4 Add `parameter-set!`: mutate cell value, apply converter if present, return old value
- [x] 1.5 Add `parameter-raw-set!`: mutate cell value without converter, return old value
- [x] 1.6 Add `apply-parameter` (0/1/2 arg dispatch) and all ops to `get-operation`
- [x] 1.7 Add `parameter-p`/`parameter?` to `*wrapper-primitives*` and `primitives.def`
- [x] 1.8 Legacy `*parameter-table*`/`*parameter-counter*` kept for bootstrap transition (used by old .ecec)
- [x] 1.9 Remove `ece-%parameter-table-entries` and `ece-%parameter-counter` functions
- [x] 1.10 Add parameter-p safety check in `apply-primitive-procedure` for compiled code without parameter? branch
- [x] 1.11 Legacy `ece-make-parameter-legacy` kept for bootstrap transition
- [x] 1.12 Remove `%parameter-table-entries` and `%parameter-counter` from `*wrapper-primitives*` and `primitives.def`

## 2. Compiler Changes

- [x] 2.1 Add `parameter?` check to `mc-compile-procedure-call` — new branch after continuation branch
- [x] 2.2 Parameter branch uses `(op apply-parameter)` with `compiled-linkage` to prevent fall-through to primitive branch
- [x] 2.3 `parameterize` macro works unchanged — 3-pass bootstrap required for calling convention change

## 3. Serializer Changes

- [x] 3.1 Add `(parameter ...)` tag to `serialize-value` (scan and emit)
- [x] 3.2 Add `(%ser/parameter <value> <converter>)` serialization
- [x] 3.3 Add `%ser/parameter` deserialization in `deserialize-value`

## 4. Bootstrap and Tests

- [x] 4.1 3-pass bootstrap with legacy params, then final pass with new params
- [x] 4.2 All existing parameter tests pass (test-make-parameter)
- [x] 4.3 All existing parameterize tests pass (test-parameterize)
- [x] 4.4 Round-trip test: parameter value preserved through save/load
- [x] 4.5 Parameter value in serialized continuation test
- [x] 4.6 Full test suite — 433 tests pass
