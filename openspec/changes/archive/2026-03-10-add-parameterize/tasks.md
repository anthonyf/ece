## 1. Parameter Object Primitive

- [x] 1.1 Implement `ece-make-parameter` in `src/runtime.lisp` — creates a parameter object as a `(primitive <gensym>)` that dispatches on arg count (0=get, 1=set), with optional converter support
- [x] 1.2 Register `make-parameter` as ECE primitive in `src/compiler.lisp`
- [x] 1.3 Export `make-parameter` and `parameterize` from ECE package in `src/runtime.lisp`
- [x] 1.4 Write tests for `make-parameter`: create, read, set, converter on init, converter on set

## 2. Parameterize Macro

- [x] 2.1 Add `parameterize` macro to `src/prelude.scm` — expands to save/set/body/restore using gensyms
- [x] 2.2 Write tests for `parameterize`: basic rebinding, restore after exit, dynamic scope propagates to called functions, multiple bindings, nested parameterize
- [x] 2.3 Write test for `parameterize` with converter: verify converter applied during rebinding

## 3. MC Compiler Refactoring

- [x] 3.1 Change `*mc-compile-lexical-env*` from `(define *mc-compile-lexical-env* '())` to `(define *mc-compile-lexical-env* (make-parameter '()))` in `src/compiler.scm`
- [x] 3.2 Replace all bare reads of `*mc-compile-lexical-env*` with `(*mc-compile-lexical-env*)` in `src/compiler.scm`
- [x] 3.3 Replace `let` rebindings of `*mc-compile-lexical-env*` with `parameterize` in `mc-compile-begin` and `mc-compile-lambda-body`
- [x] 3.4 Write test verifying MC compiler macro shadowing works: define a macro, shadow it with local define, confirm application (not macro expansion) is compiled
- [x] 3.5 Verify all existing tests still pass (518 assertions)
