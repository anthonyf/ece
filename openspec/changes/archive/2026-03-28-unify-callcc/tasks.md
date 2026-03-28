## Tasks

### WAT runtime changes
- [ ] Add `$winds` field to `$continuation` struct
- [ ] Add `$winding-stack` WAT global (synced with ECE `*winding-stack*`)
- [ ] Add `%set-winding-stack!` primitive to sync the WAT global from ECE code
- [ ] Update `capture-continuation` (op 21) to include `$winding-stack` as the third field
- [ ] Update executor continuation invoke handler: compare `$winds` with current `$winding-stack`, call `do-winds!` if different
- [ ] Update `%make-continuation` (prim 164) to accept 3 fields (for deserialization)
- [ ] Update `continuation-stack` / `continuation-conts` primitives (field offsets may shift)

### Prelude changes
- [ ] Simplify `call/cc` macro: `(define-macro (call/cc receiver) \`(%raw-call/cc ,receiver))`
- [ ] Update `dynamic-wind` to call `%set-winding-stack!` when mutating `*winding-stack*`
- [ ] Update serializer: `%ser/continuation` emits 3 fields (stack, conts, winds)
- [ ] Update deserializer: `%ser/continuation` reads 3 fields

### CL runtime changes
- [ ] Update CL continuation struct to include winds field
- [ ] Update CL continuation invoke to call `do-winds!` if needed

### Tests
- [ ] All existing dynamic-wind tests pass
- [ ] All existing continuation tests pass
- [ ] `(continuation? (call/cc (lambda (k) k)))` returns `#t` (not compiled-procedure)
- [ ] Serialized `call/cc` continuation invokes correctly
- [ ] Serialized `call/cc` continuation invokes correctly from inside `dynamic-wind`
- [ ] Run full test suite (`make test-wasm` and CL tests)
