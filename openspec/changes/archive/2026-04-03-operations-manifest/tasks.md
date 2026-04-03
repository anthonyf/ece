## 1. Create operations.def

- [x] 1.1 Create `operations.def` at project root with all 27 operations, stable IDs, names, arities, and descriptions. Superset of CL's `get-operation` (26 ops) and WASM's dispatch (23 ops, including `cdr`).

## 2. CL Runtime: Manifest-Driven Dispatch

- [x] 2.1 Add manifest parsing for `operations.def` — reuse or parallel the existing `parse-primitives-manifest` pattern. Build `*operation-dispatch-table*` (vector indexed by ID) and `*operation-name-to-id*` (hash table).
- [x] 2.2 Replace `get-operation` ecase with manifest-driven lookup: `(aref *operation-dispatch-table* id)`. Add `get-operation-id` for name→ID resolution.
- [x] 2.3 Update `resolve-operations` to use the manifest-driven path — still pre-resolves to `(op-fn #'func)` at assembly time, but goes through the operation table.
- [x] 2.4 Add `cdr` to CL's operation function map (trivially maps to CL `cdr`).

## 3. WASM Runtime: Align Operation IDs

- [x] 3.1 Update `$ecec-op-id` symbol-scan slot assignments in `runtime.wat` to match canonical IDs from `operations.def`
- [x] 3.2 Update `$exec-machine-op` dispatch chain to use canonical IDs
- [x] 3.3 Implement missing operations in WASM: `lookup-global-variable`, `parameter-ref`, `parameter-set!`, `parameter-raw-set!`

## 4. Bootstrap and Validation

- [x] 4.1 Two-pass `make bootstrap` — first pass boots from old .ecec, recompiles to new .ecec with updated operation resolution; second pass validates the new .ecec files boot correctly
- [x] 4.2 Run CL test suite (rove + ECE self-hosted + conformance) — all must pass
- [x] 4.3 Run WASM test suite — all must pass
- [x] 4.4 Verify operation ID consistency: spot-check that CL and WASM resolve the same operation names to the same numeric IDs
