## Investigation Plan

The deserialization pipeline for continuations:

```
Serialized form:  (%ser/continuation <stack> (<space-id> . <pc>))
                        ↓
read:             (list '%ser/continuation <stack-form> (cons space-id pc))
                        ↓
deserialize-value:  (deser (cadr form))  → stack
                    (caddr form)         → conts (raw, NOT deserialized)
                        ↓
%make-continuation:  (struct.new $continuation stack conts)
```

### Hypothesis 1: conts field format mismatch
The `conts` field should be a pair `(fixnum-space-id . fixnum-pc)` where both values are WasmGC i31 fixnums. After `read`, the pair might contain plain integers (also i31 fixnums from the reader), so this should work. But maybe the `read` form has them as floats or other types.

### Hypothesis 2: stack reconstruction
The stack is a cons-list of saved register values. After deserialization, each element needs to be the correct WasmGC type. If a compiled-procedure in the stack isn't properly reconstructed, invoking the continuation would fail when it tries to restore registers.

### Hypothesis 3: continuation? check fails
If `%make-continuation` (prim 164) IS called but its result passes through `deser` processing that wraps it (e.g., shared-structure `%ser/def`), the wrapper might not be a `$continuation` struct.

## Approach

1. Add diagnostic: check what type `loaded-k` actually is after deserialization
2. Check if `%make-continuation` is even being called during deserialization
3. If it IS called, check the struct type of the result
4. Fix the reconstruction path based on findings
5. Add end-to-end tests
