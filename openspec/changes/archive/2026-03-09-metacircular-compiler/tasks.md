## 1. Foundation: Prelude Additions & New Primitives

- [x] 1.1 Add `union` function to `src/prelude.scm` (eq?-based set union for register lists)
- [x] 1.2 Add `set-difference` function to `src/prelude.scm` (eq?-based set difference for register lists)
- [x] 1.3 Add `ece-execute-from-pc` function to `src/runtime.lisp` and register `execute-from-pc` primitive
- [x] 1.4 Register `assemble-into-global` as ECE primitive in `src/compiler.lisp`
- [x] 1.5 Export new symbols (`union`, `set-difference`, `execute-from-pc`, `assemble-into-global`) from ECE package
- [x] 1.6 Write tests for `union`, `set-difference`, `assemble-into-global`, and `execute-from-pc`

## 2. Instruction Sequence Infrastructure (compiler.scm part 1)

- [x] 2.1 Create `src/compiler.scm` with file header and `make-instruction-sequence`, `empty-instruction-sequence`, accessors (`registers-needed`, `registers-modified`, `instructions`)
- [x] 2.2 Implement `append-instruction-sequences`, `append-2-sequences` using `union` and `set-difference`
- [x] 2.3 Implement `tack-on-instruction-sequence` and `parallel-instruction-sequences`
- [x] 2.4 Implement `preserving` (the core optimization combinator)
- [x] 2.5 Write tests verifying instruction sequence operations match CL compiler output

## 3. Label Generation & Linkage (compiler.scm part 2)

- [x] 3.1 Implement `make-label` with mutable counter and `string->symbol`/`fmt`
- [x] 3.2 Implement `compile-linkage` and `end-with-linkage`
- [x] 3.3 Write tests for label uniqueness and linkage code generation

## 4. Core Compile Functions (compiler.scm part 3)

- [x] 4.1 Implement expression predicates (`self-evaluating?`, `variable?`, `quoted?`, `if?`, `begin?`, `lambda?`, `define?`, `assignment?`, `callcc?`, `apply-form?`, `define-macro?`, `quasiquote?`, `application?`)
- [x] 4.2 Implement `compile-self-evaluating`, `compile-variable`, `compile-quoted`
- [x] 4.3 Implement `compile-if` with `true-branch`/`false-branch`/`after-if` labels
- [x] 4.4 Implement `compile-begin`, `compile-sequence`, `extract-define-names`
- [x] 4.5 Write tests for core compile functions (compile each form, verify instruction output)

## 5. Lambda & Application (compiler.scm part 4)

- [x] 5.1 Implement `compile-lambda`, `compile-lambda-body`, `flatten-params`
- [x] 5.2 Implement `compile-application`, `construct-arglist`, `code-to-get-rest-args`
- [x] 5.3 Implement `compile-procedure-call`, `compile-proc-appl` with `*all-regs*`
- [x] 5.4 Write tests for lambda compilation and procedure application

## 6. Remaining Special Forms (compiler.scm part 5)

- [x] 6.1 Implement `compile-assignment` and `compile-define` (including function shorthand)
- [x] 6.2 Implement `compile-callcc`
- [x] 6.3 Implement `compile-apply-form`
- [x] 6.4 Implement `compile-define-macro` and `expand-macro-at-compile-time`
- [x] 6.5 Implement `compile-quasiquote` and `qq-expand`
- [x] 6.6 Write tests for each special form compilation

## 7. Main Dispatch & Integration (compiler.scm part 6)

- [x] 7.1 Implement `ece-compile` main dispatch (with `*compile-lexical-env*` and macro lookup)
- [x] 7.2 Implement `mc-compile-and-go` (compile + assemble-into-global + execute-from-pc)
- [x] 7.3 Add `compiler.scm` to load sequence in `src/compiler.lisp` (after prelude)
- [x] 7.4 Write integration tests: compile-and-execute via metacircular compiler for arithmetic, closures, recursion, macros, call/cc
- [x] 7.5 Verify all existing tests still pass with metacircular compiler loaded
