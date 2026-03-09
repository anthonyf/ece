## 1. Instruction Source Vector

- [x] 1.1 Add `*global-instruction-source*` parallel vector to runtime.lisp
- [x] 1.2 Modify `assemble-into-global` to store unresolved instructions in source vector alongside resolved instructions in execution vector
- [x] 1.3 Verify existing tests still pass with dual storage

## 2. Image Save/Load Functions

- [x] 2.1 Add `ece-save-image` function in runtime.lisp — serialize instruction source vector (as list), label table (as alist), global environment, and compile-time macros (as alist) to file using `write` with `*print-circle*`
- [x] 2.2 Add `ece-load-image` function in runtime.lisp — deserialize image file, replace all four globals, rebuild execution vector by running `resolve-operations` on each source instruction, rebuild label hash-table from alist
- [x] 2.3 Register `save-image!` and `load-image!` as primitives in compiler.lisp global environment

## 3. Tests — Basic Round-Trip

- [x] 3.1 Test save-image! returns #t and creates a file
- [x] 3.2 Test load-image! restores simple variable bindings (numbers, strings, booleans, symbols, lists)
- [x] 3.3 Test load-image! restores compiled procedures — define a function, save, load, call it
- [x] 3.4 Test load-image! restores closures — define a closure over a variable, save, load, verify closed-over state

## 4. Tests — Advanced Round-Trip

- [x] 4.1 Test compile-time macros survive round-trip — define-macro, save, load, use the macro in new code
- [x] 4.2 Test prelude functions work after round-trip — map, filter, reduce on loaded image
- [x] 4.3 Test hash tables and vectors survive round-trip
- [x] 4.4 Test continuations survive round-trip — capture with call/cc, save image, load, invoke continuation
- [x] 4.5 Test new code can be compiled and run after loading an image (the compiler still works)
