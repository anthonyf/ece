## 1. Fix scan range

- [x] 1.1 In `wasm/runtime.wat` line 5092, change `(i32.ge_u (local.get $i) (i32.const 39))` to `(i32.gt_u (local.get $i) (i32.const 39))` in `$ecec-op-id`
- [x] 1.2 Update the comment on line 5089 from "slots 17-38" to "slots 17-39 (ops 0-22)"

## 2. Rebuild and test

- [x] 2.1 Rebuild `runtime.wasm` via `make wasm`
- [x] 2.2 Run `make test-wasm` — all 5 space validation failures should be resolved (32 passed, 0 failed)
- [x] 2.3 Add `do-continuation-winds` to the op-id exhaustive check in `wasm/test.js` (line 34-41 opNames array)
