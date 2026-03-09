## 1. Create runtime.lisp

- [x] 1.1 Create `src/runtime.lisp` with the `defpackage` and `(in-package :ece)`
- [x] 1.2 Move environment operations: `make-frame`, `frame-variables`, `frame-values`, `extend-environment`, `lookup-variable-value`, `set-variable-value!`, `define-variable!`
- [x] 1.3 Move readtable setup (`*ece-readtable*`, `eval-when` block with string interpolation, hash literal, quasiquote/unquote readers)
- [x] 1.4 Move primitive infrastructure: `ece-boolean-p`, `*primitive-procedures*`, `*primitive-procedure-names*`, `*primitive-procedure-objects*`, `*global-env*`, `*eof-sentinel*`
- [x] 1.5 Move all `ece-*` wrapper functions (except `ece-try-eval` and `ece-load` which depend on compiler)
- [x] 1.6 Move `*wrapper-primitives*` list and registration loop (remove `try-eval` and `load` entries — those move to compiler)
- [x] 1.7 Move compiled procedure types: `make-compiled-procedure`, `compiled-procedure-p`, `compiled-procedure-entry`, `compiled-procedure-env`
- [x] 1.8 Move primitive/continuation helpers: `primitive-procedure-p`, `apply-primitive-procedure`, `continuation-p`, `continuation-stack`, `continuation-conts`, `capture-continuation`
- [x] 1.9 Move operations dispatch: `get-operation`
- [x] 1.10 Move executor: `execute-instructions`
- [x] 1.11 Move global instruction accumulator: `*global-instruction-vector*`, `*global-label-table*`, `resolve-operations`, `assemble-into-global`

## 2. Create compiler.lisp

- [x] 2.1 Create `src/compiler.lisp` with `(in-package :ece)`
- [x] 2.2 Move expression predicates: `self-evaluating-p`, `variable-p`, `define-special-form-predicate` macro, all generated predicates, `*special-forms*`, `application-p`
- [x] 2.3 Move `qq-expand`
- [x] 2.4 Move instruction sequence combinators: `make-instruction-sequence`, accessors, `append-instruction-sequences`, `append-2-sequences`, `tack-on-instruction-sequence`, `preserving`, `parallel-instruction-sequences`
- [x] 2.5 Move label generation: `make-label`
- [x] 2.6 Move linkage: `compile-linkage`, `end-with-linkage`
- [x] 2.7 Move compile-time macro environment: `*compile-time-macros*`, `*compile-lexical-env*`
- [x] 2.8 Move compile dispatch and all compile functions: `ece-compile`, `expand-macro-at-compile-time`, `compile-self-evaluating` through `compile-apply-form`
- [x] 2.9 Move integration: `compile-and-go`, `compile-file-ece`, `evaluate`
- [x] 2.10 Move `ece-try-eval`, `ece-load`, and register them as primitives after `evaluate`/`compile-file-ece` are defined
- [x] 2.11 Move prelude loading (`compile-file-ece` call) and `repl`

## 3. Update build system

- [x] 3.1 Update `ece.asd` to load `runtime` before `compiler` with `:depends-on`
- [x] 3.2 Remove `src/ece.lisp`

## 4. Verification

- [x] 4.1 Clear FASL cache and run full test suite — all tests must pass unchanged
