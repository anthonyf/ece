## 1. Fix Parameter Serialization

- [x] 1.1 Add `*parameter-table*` hash table (keyed by parameter name symbol, value is `(value . converter)`) and `*parameter-counter*` to runtime.lisp globals
- [x] 1.2 Rewrite `ece-make-parameter` to store state in `*parameter-table*` instead of `symbol-function` closures — keep the `(primitive PARAMn)` representation but dispatch through the table
- [x] 1.3 Update `apply-primitive-procedure` to check `*parameter-table*` when the primitive name is found there (0 args = get, 1 arg = set with converter, 2 args = raw set)
- [x] 1.4 Remove the `symbol-function` closure from `ece-make-parameter` (no longer needed)

## 2. Update Image Save/Load

- [x] 2.1 Update `ece-save-image` to serialize `*parameter-table*` (as alist) and `*parameter-counter*` as 6th and 7th elements of the image list
- [x] 2.2 Update `ece-load-image` to restore `*parameter-table*` and `*parameter-counter*` from the image

## 3. Add Image-Based Startup

- [x] 3.1 Add `image-repl` function in runtime.lisp — loads an image and starts the REPL by calling `repl-loop` from the image's global env via `execute-compiled-call`
- [x] 3.2 Add `make image` target to Makefile — cold-boots via `asdf:load-system :ece`, saves to `bootstrap/ece.image`
- [x] 3.3 Add `make run` target to Makefile — loads `runtime.lisp`, calls `image-repl` with `bootstrap/ece.image`
- [x] 3.4 Generate and check in `bootstrap/ece.image`

## 4. Tests

- [x] 4.1 Add tests for parameter round-trip — create parameter, save image, load image, verify parameter get/set works
- [x] 4.2 Add test for image-based startup — load only runtime.lisp + image, verify `mc-compile-and-go` works (compiles and executes an expression)
- [x] 4.3 Run full test suite and verify all existing tests pass
