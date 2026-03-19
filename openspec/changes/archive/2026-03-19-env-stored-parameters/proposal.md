## Why

Parameters (`make-parameter`, `parameterize`) store their values in a CL-side hash table (`*parameter-table*`) separate from the ECE environment. This was designed for the old image serializer which had special handling for the parameter table. That serializer is gone — replaced by the ECE-side `serialize-value` which walks the environment. Since parameter values live outside the environment, they're invisible to serialization: `save-continuation!` silently loses parameter state, and `parameterize` bindings aren't captured in continuations. This also adds unnecessary CL kernel complexity (`*parameter-table*`, `*parameter-counter*`, special `symbolp` dispatch path in `apply-primitive-procedure`).

## What Changes

- **Parameters as tagged values**: `make-parameter` returns `(parameter <value> <converter>)` stored directly in the environment, instead of `(primitive PARAM3)` pointing to a CL hash table.
- **Executor parameter dispatch**: The executor's procedure call dispatch gains a `parameter?` check alongside `primitive-procedure?`, `compiled-procedure?`, and `continuation?`. Parameter get (0 args) reads the value; set (1 arg) mutates the cell.
- **Remove CL-side parameter state**: `*parameter-table*`, `*parameter-counter*`, and the `symbolp` dispatch path in `apply-primitive-procedure` are removed.
- **`parameterize` unchanged**: The macro already works by saving the old value, setting the new one, and restoring on exit. The same mechanism works with env-stored parameters — it just mutates the tagged value's car instead of a hash table cell.
- **Serialization works automatically**: The serializer already handles tagged lists in the environment. Parameters serialize as `(%ser/parameter <value> <converter>)` with no special handling needed.

## Capabilities

### New Capabilities
- `env-stored-parameters`: Parameters stored as `(parameter <value> <converter>)` directly in the ECE environment, callable as procedures, serializable by default.

### Modified Capabilities
- `parameterize`: Same semantics, but operates on env-stored parameter cells instead of CL hash table cells.

## Impact

- **`src/runtime.lisp`**: Remove `*parameter-table*`, `*parameter-counter*`, `ece-make-parameter`, `ece-%parameter-table-entries`, `ece-%parameter-counter`. Remove `symbolp` dispatch path in `apply-primitive-procedure`. Add `parameter-p`, `ece-make-parameter` (new version), `ece-parameter-ref`, `ece-parameter-set!` to CL. Add `parameter?` check to executor's procedure dispatch.
- **`src/prelude.scm`**: Update `parameterize` macro if needed (may work as-is since it calls the parameter as a function).
- **`src/compiler.scm`**: Compiler may need to recognize `parameter?` for the procedure call dispatch.
- **`primitives.def`**: Remove `%parameter-table-entries`, `%parameter-counter`. Add `make-parameter` (new ID), `parameter?`.
- **`src/prelude.scm` (serializer)**: Add `(%ser/parameter ...)` tag handling in `serialize-value` and `deserialize-value`.
- **`tests/`**: All existing parameter and parameterize tests must pass. Add serialization round-trip test for parameters.
