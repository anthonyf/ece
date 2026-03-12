## 1. Flat Image Serializer

- [x] 1.1 Implement `ece-serialize-flat` reference-counting pre-pass — walk image data with identity hash table (`eq`), count occurrences of each cons/vector/string value
- [x] 1.2 Implement `ece-serialize-flat` emitter — depth-first walk emitting opcodes (`int`, `sym`, `kwd`, `str`, `chr`, `nil`, `t`, `cons`, `list`, `vec`) one per line, with `def N` for multi-referenced values
- [x] 1.3 Handle edge cases: gensym keywords (`kwd |1|`), strings with escapes (`\n`, `\t`, `\\`, `\"`), negative integers, empty strings, empty vectors
- [x] 1.4 Replace `ece-%write-image` to call `ece-serialize-flat` instead of CL `write` with `*print-circle*`

## 2. Flat Image Deserializer

- [x] 2.1 Implement `ece-load-flat-image` — line-by-line reader with stack and `case` dispatch over opcodes, `def`/`ref` array for structural sharing
- [x] 2.2 Handle string unescaping (`\n` → newline, `\t` → tab, `\\` → backslash, `\"` → double quote)
- [x] 2.3 Handle keyword name parsing including `|...|` escaped names
- [x] 2.4 Replace `ece-load-image` to use `ece-load-flat-image` instead of CL `read` with `*ece-readtable*`

## 3. Round-Trip Verification

- [x] 3.1 Build transition image: use current CL-reader cold boot to compile system, save in new flat format via `make image`
- [x] 3.2 Verify flat-format image loads correctly: `(asdf:load-system :ece)` + `(ece:repl)` works with flat image
- [x] 3.3 Update image round-trip tests in `tests/ece.lisp` to work with flat format
- [x] 3.4 Verify all existing tests pass (689 assertions, 0 failures)

## 4. Remove CL Reader Infrastructure

- [x] 4.1 Move `*ece-readtable*` and reader macros to separate `src/readtable.lisp` (removed from `runtime.lisp`)
- [x] 4.2 Delete `ece-read` function and primitive binding from `runtime.lisp`
- [x] 4.3 Convert `ece-save-continuation!` and `ece-load-continuation` to flat format (no more CL reader for data loading)
- [x] 4.4 Retain CL reader in `readtable.lisp` (shared by `ece` and `ece/cold` systems for CL-side code)
- [x] 4.5 Verify `make image` (cold boot) still works
- [x] 4.6 Verify all tests pass after CL reader removal

## 5. Cleanup and Final Verification

- [x] 5.1 Update `bootstrap/ece.image` with the new flat-format image
- [x] 5.2 Run full test suite and verify all assertions pass (689 assertions, 0 failures)
- [x] 5.3 Verify REPL startup works: `make run`
