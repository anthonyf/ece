## 1. Fix off-by-one in $ecec-op-id scan

- [x] 1.1 Change scan upper bound from 38 to 39 to include `capture-continuation` at slot 38

## 2. Two-phase label resolution (immutable $instr)

- [x] 2.1 Revert `$instr.$c` and `$instr.$val` to immutable
- [x] 2.2 Remove `$continuation` tag field (unnecessary with immutable $instr)
- [x] 2.3 Rewrite `load_ecec` to two-phase: read all units + collect labels, then build instructions
- [x] 2.4 Add `$labels` parameter to `$ecec-parse-instr` and `$ecec-build-operand-list`
- [x] 2.5 Resolve labels inline during instruction creation (branch, goto, assign-label, operand lists)
- [x] 2.6 Remove `$ecec-resolve-labels` and `$ecec-resolve-operand-labels`

## 3. Handle procedure-name metadata

- [x] 3.1 Add `$ecec-is-instr-keyword` helper to check if a symbol is one of the 7 instruction types
- [x] 3.2 Skip `procedure-name` items in phase 1 (don't count as instructions)
- [x] 3.3 Skip null results from `$ecec-parse-instr` in phase 2

## 4. Cleanup

- [x] 4.1 Re-disable tracing in executor dispatch loop
- [x] 4.2 Remove `dbg_yield_raw_k` debug export

## 5. Verification

- [x] 5.1 `make test` — CL tests pass
- [x] 5.2 `make test-wasm` — 329 WASM tests pass
- [x] 5.3 Node.js game loop simulation — 5 frames yield/resume correctly
- [x] 5.4 `make sandbox` — builds successfully
