## 1. Infrastructure

- [x] 1.1 Add `$labels` field (hash table) to `$comp-space` struct in runtime.wat
- [x] 1.2 Add `$current-space-id` global in runtime.wat
- [x] 1.3 Add `$resolve-op-name` function — maps operation symbols to numeric IDs
- [x] 1.4 Add `$ece-instr-to-wasm-instr` function — converts ECE list instruction to `$instr` struct
- [x] 1.5 Update primitives.def: IDs 125-135 from `cl` to `core`

## 2. Bootstrap Assembler Primitives (IDs 92-97)

- [x] 2.1 Implement `%intern-ece` (92): intern string as symbol (already have $intern)
- [x] 2.2 Implement `%instruction-vector-length` (93): bootstrap space instruction count
- [x] 2.3 Implement `%instruction-vector-push!` (94): delegate to space-instruction-push! for bootstrap
- [x] 2.4 Implement `%label-table-set!` (95): delegate to space-label-set! for bootstrap
- [x] 2.5 Implement `%label-table-ref` (96): delegate to space-label-ref for bootstrap
- [x] 2.6 Implement `%procedure-name-set!` (97): store name (can be no-op for now)

## 3. Space Management Primitives (IDs 125-135)

- [x] 3.1 Implement `%create-space` (125): create new compilation space
- [x] 3.2 Implement `%space-instruction-length` (126): instruction count
- [x] 3.3 Implement `%space-name` (127): space name symbol
- [x] 3.4 Implement `%current-space-id` (128): get current space
- [x] 3.5 Implement `%set-current-space-id!` (129): set current space
- [x] 3.6 Implement `%space-instruction-push!` (130): convert + append instruction
- [x] 3.7 Implement `%space-label-set!` (131): register label in space
- [x] 3.8 Implement `%space-label-ref` (132): look up label

## 4. Execution Primitives

- [x] 4.1 Implement `execute-from-pc` (85): recursive $execute call with qualified address
- [x] 4.2 Implement `apply-compiled-procedure` (89): call compiled proc with args
- [x] 4.3 Implement `try-eval` (90): call mc-compile-and-go with error trapping

## 5. Wiring

- [x] 5.1 Register all new primitives in glue.js buildGlobalEnv
- [x] 5.2 Wire all primitives in $apply-primitive dispatch in runtime.wat

## 6. Sandbox Integration

- [x] 6.1 Update sandbox evalECE to use ECE's `load` via full dispatch
- [x] 6.2 Update sandbox REPL to compile and run via load

## 7. Validation

- [x] 7.1 Existing WASM tests: 329 pass
- [x] 7.2 CL tests: 490 pass (0 failures)
- [x] 7.3 Sandbox REPL: `(+ 1 2)` → `3` (via JS parser + eval, bypassing ECE reader bug)
- [x] 7.4 Sandbox: Hello World runs from editor (via JS parser + eval)
- [ ] 7.5 `(load "file.scm")` works on WASM via localStorage (blocked: pre-existing ECE reader bug — reader-delimiter? fails in list context, including `)` in symbol names)
