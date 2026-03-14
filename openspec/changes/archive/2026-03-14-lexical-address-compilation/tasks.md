## 1. Runtime: New Operations and Vector Frames

- [x] 1.1 Add `lexical-ref` function to runtime.lisp: traverse `depth` frames, return `(svref frame offset)`
- [x] 1.2 Add `lexical-set!` function to runtime.lisp: traverse `depth` frames, `(setf (svref frame offset) val)`
- [x] 1.3 Register `lexical-ref` and `lexical-set!` in `get-operation` ecase dispatch
- [x] 1.4 Modify `extend-environment` to create vector frames from argument lists (handle proper params, dotted params, and rest-only params)
- [x] 1.5 Ensure `lookup-variable-value` still works for the global list-based frame (no change needed, but verify mixed env traversal works — vector frames are skipped by name-based lookup since they have no names)

## 2. Compiler: Lexical Address Computation

- [x] 2.1 Change `*compile-lexical-env*` from flat name list to list-of-frames structure
- [x] 2.2 Add `find-variable` function that searches compile-time env and returns `(depth . offset)` or nil
- [x] 2.3 Update `compile-lambda-body` to push a new frame (including internal define names) onto `*compile-lexical-env*`
- [x] 2.4 Update `compile-begin` to include define names in the current frame (for top-level begin blocks within lambdas)
- [x] 2.5 Ensure macro shadowing still works with the new frame-based `*compile-lexical-env*`

## 3. Compiler: Emit Lexical Instructions

- [x] 3.1 Modify `compile-variable` to emit `lexical-ref` when `find-variable` returns an address, fall back to `lookup-variable-value` for globals
- [x] 3.2 Modify `compile-assignment` to emit `lexical-set!` when variable has a lexical address, fall back to `set-variable-value!` for globals
- [x] 3.3 Modify `compile-define` for internal defines (within lambda bodies) to emit `lexical-set!` to pre-allocated slots

## 4. Runtime: Mixed-Frame Environment Support

- [x] 4.1 Update `lookup-variable-value` to handle mixed environments — skip vector frames (no variable names) and search list-based frames by name
- [x] 4.2 Update `set-variable-value!` to handle mixed environments similarly
- [x] 4.3 Ensure `define-variable!` still only operates on the global (list-based) frame for top-level defines

## 5. Image Serialization

- [x] 5.1 Verify `flat-image-serialize` handles vector frames correctly (vectors already supported via `vec N` opcode)
- [x] 5.2 Verify `flat-image-deserialize` restores vector frames correctly
- [x] 5.3 Regenerate bootstrap image with `make image`

## 6. Testing and Validation

- [x] 6.1 Run existing ECE test suite (`make test-ece`) — all 393 tests must pass
- [x] 6.2 Run CL-level tests (`make test`) — all tests must pass
- [x] 6.3 Verify image save/load round-trip works with vector frames
- [x] 6.4 Profile with sb-sprof — local variable lookups now use O(1) lexical-ref; global lookups still use lookup-variable-value (expected per SICP 5.42)
