## 1. Lexical Environment Infrastructure

- [x] 1.1 Restructure `*mc-compile-lexical-env*` from flat name list to list-of-frames representation
- [x] 1.2 Add `mc-find-variable` that searches frame-structured env and returns `(depth . offset)` or `#f`
- [x] 1.3 Add `*mc-compile-macro-shadows*` parameter (flat list) for begin-level define names
- [x] 1.4 Add `mc-lexically-shadows-macro?` that checks both `mc-find-variable` and `*mc-compile-macro-shadows*`
- [x] 1.5 Update macro shadow check in `mc-compile` application dispatch (line 502) to use `mc-lexically-shadows-macro?`

## 2. Deep Extract-Define-Names

- [x] 2.1 Update `mc-extract-define-names` to recurse into `begin` blocks
- [x] 2.2 Update `mc-extract-define-names` to recurse into `if` branches
- [x] 2.3 Update `mc-extract-define-names` to expand compile-time macros and recurse into expansions
- [x] 2.4 Update `mc-compile-begin` to add define names to `*mc-compile-macro-shadows*` instead of `*mc-compile-lexical-env*`

## 3. Lambda Body Compilation

- [x] 3.1 Update `mc-compile-lambda-body` to call `mc-extract-define-names` and compute extra-slots count
- [x] 3.2 Update `mc-compile-lambda-body` to build frame as `(append param-names define-names)` and push onto `*mc-compile-lexical-env*`
- [x] 3.3 Update `mc-compile-lambda-body` to emit 4-arg `extend-environment` with `(const extra-slots)`

## 4. Lexical Variable Access

- [x] 4.1 Update `mc-compile-variable` to check `mc-find-variable` and emit `lexical-ref` when address is found
- [x] 4.2 Update `mc-compile-assignment` to check `mc-find-variable` and emit `lexical-set!` when address is found
- [x] 4.3 Update `mc-compile-define` to check `mc-find-variable` and emit `lexical-set!` for internal defines

## 5. Testing & Image Rebuild

- [x] 5.1 Run existing test suite to verify all tests pass with the new compiler
- [x] 5.2 Rebuild the bootstrap image using the updated metacircular compiler
- [x] 5.3 Verify the rebuilt image boots and passes the test suite
