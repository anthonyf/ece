## 1. Space Data Structures

- [x] 1.1 Define `space` struct in runtime.lisp with fields: name, instructions (adjustable vector), resolved-instructions (adjustable vector), label-table (hash-table), compiled-fn (nil or function)
- [x] 1.2 Add `*space-registry*` global — an adjustable vector of space records
- [x] 1.3 Implement `create-space` (allocates a new space, registers it, returns space-id) and `get-space` (lookup by ID)
- [x] 1.4 Implement `find-space-by-name` (lookup by name string)
- [x] 1.5 Export space primitives to ECE: `%create-space`, `%get-space`, `%space-instruction-length`, `%space-name`

## 2. Space-Qualified Addresses

- [x] 2.1 Change `make-compiled-procedure` to accept a `(space-id . local-pc)` cons pair as the entry argument
- [x] 2.2 Update `compiled-procedure-entry` to return the cons pair
- [x] 2.3 Update the `make-compiled-procedure` operation in the compiler to emit qualified addresses — the assembler must pass the current space-id when creating procedures
- [x] 2.4 Update `capture-continuation` to store space-qualified `continue` values in captured continuations
- [x] 2.5 Update continuation restore to set `continue` from the space-qualified value

## 3. Space-Aware Assembler

- [x] 3.1 Add `assemble-into-space` (CL version) that takes a space-id and instruction list, appends to the space's arrays, registers labels in the space's label table, returns local start PC
- [x] 3.2 Create initial "bootstrap" space (space 0) that receives the CL-assembled bootstrap instructions (everything before the ECE assembler takes over)
- [x] 3.3 Modify `ece-assemble-into-global` in assembler.scm to target the current space — add a `*current-space-id*` variable that `(load ...)` sets per file
- [x] 3.4 Modify `(load ...)` in assembler.scm to create a new space per file and set `*current-space-id*` before compiling forms

## 4. Single-Loop Executor (replaces throw/catch design)

- [x] 4.1 Add `space-id`, `instrs`, and `ltab` as local variables in `execute-instructions`, initialized from the space registry using `current-space-id`
- [x] 4.2 Replace `throw 'space-exit` in `goto (reg ...)` with inline space switch: update `space-id`/`instrs`/`ltab` locals, set `pc`, `(go loop-start)`
- [x] 4.3 Replace `throw 'space-exit` in apply-compiled-procedure with inline space switch
- [x] 4.4 Replace `throw 'space-exit` in error handler dispatch with inline space switch
- [x] 4.5 Update `resolve-label` local function to use the `ltab` local variable (so it resolves labels in the current space)
- [x] 4.6 Remove `space-exit-request` struct definition
- [x] 4.7 Remove `execute-space-dispatch` function
- [x] 4.8 Remove `catch 'space-exit` from all call sites
- [x] 4.9 Run the full test suite with space 0 as the only space — all existing tests must pass

## 5. Compatibility Layer (Global Vector as Space 0)

- [x] 5.1 On startup, create space 0 from the existing `*global-instruction-vector*` and `*global-instruction-source*`
- [x] 5.2 Wrap bare integer PCs in existing `*procedure-name-table*` entries as `(0 . pc)` qualified addresses
- [x] 5.3 Ensure existing image load (binary format) populates space 0 correctly
- [x] 5.4 Run the full test suite with the compatibility layer — all existing tests must pass with space 0 as the only space (re-validate after task 4)

## 6. Per-File Space Loading

- [x] 6.1 Enable per-file spaces in `(load ...)` (task 3.4) and test loading a fresh image where compilation-unit.scm and compaction.scm each get their own space (prelude/compiler/reader/assembler still in space 0 from bootstrap)
- [x] 6.2 Verify cross-space procedure calls work — prelude functions called from compilation-unit/compaction space resolve through the global environment
- [x] 6.3 Verify `call/cc` works across spaces — all call/cc tests pass with multi-space image
- [x] 6.4 Verify TCO across spaces — all TCO tests pass with multi-space image

## 7. Per-Space Codegen

- [x] 7.1 Refactor codegen-cl.lisp to iterate the space registry instead of the global vector — emit one file per space
- [x] 7.2 Update generated code to handle space-qualified addresses — `goto (reg continue)` checks space-id, exits to dispatcher on mismatch
- [x] 7.3 Generate a manifest file listing spaces in load order with metadata (name, instruction count, space-id)
- [x] 7.4 Generate an operation table initialization file (shared across all spaces)
- [ ] 7.5 Test: generate per-space files, compile each with `compile-file`, load in manifest order, run the test suite — requires per-file spaces (task 6) so each space is small enough for SBCL to compile

## 8. Image as Space Collection

- [x] 8.1 Implement multi-space binary serialization — `save-image!` collects non-zero spaces via `collect-non-zero-spaces`, passes as 8th element to `%write-image` which serializes them in `+section-spaces+`
- [x] 8.2 Implement multi-space binary deserialization — `binary-image-deserialize` reads `+section-spaces+` section and populates space registry with restored spaces
- [x] 8.3 Test save/load round-trip: v3 image with spaces 0-2, all 409 tests pass
- [x] 8.4 Binary image format retained with backward compat — images without `+section-spaces+` section load as single space 0

## 9. Cleanup

- [ ] 9.1 Remove `*global-instruction-vector*` and `*global-instruction-source*` once all code uses spaces
- [ ] 9.2 Remove chunking logic from codegen-cl.lisp (no longer needed with per-space generation)
- [x] 9.3 Update `*procedure-name-table*` to use space-qualified PCs natively — done: table uses `(space-id . local-pc)` keys with `:test 'equal`, `ece-%procedure-name-set!` normalizes bare integers
- [ ] 9.4 Document the compilation space architecture and build workflow
