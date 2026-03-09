## Context

ECE is a single 1391-line file (`src/ece.lisp`) containing everything: package definition, environment operations, primitives, readtable, expression predicates, compiler, executor, and REPL. To support porting the runtime to JSCL (and eventually writing the compiler in ECE itself), we need a clean separation between what's needed to *execute* compiled code and what's needed to *produce* it.

## Goals / Non-Goals

**Goals:**
- Split `src/ece.lisp` into `src/runtime.lisp` and `src/compiler.lisp`
- Runtime must be independently loadable — sufficient to execute pre-assembled instruction vectors
- Compiler depends on runtime but not vice versa
- All existing tests pass unchanged
- Public API unchanged

**Non-Goals:**
- Porting the runtime to JSCL (future work)
- Writing the compiler in ECE (future work)
- Serializing instruction vectors (future work)
- Changing any behavior or APIs

## Decisions

### 1. What goes in `runtime.lisp`

Everything the executor needs at runtime, in dependency order:

1. **Package definition** (`defpackage`) — all exports stay here
2. **Environment operations** (lines 128-200): `make-frame`, `frame-variables`, `frame-values`, `extend-environment`, `lookup-variable-value`, `set-variable-value!`, `define-variable!`
3. **Primitive registration** (lines 202-651): `*primitive-procedures*`, `*primitive-procedure-names*`, `*primitive-procedure-objects*`, `*global-env*`, all `ece-*` wrapper functions, `*wrapper-primitives*`, primitive setup loop
4. **Compiled procedure types** (lines 1160-1191): `make-compiled-procedure`, `compiled-procedure-p`, `compiled-procedure-entry`, `compiled-procedure-env`, `primitive-procedure-p`, `apply-primitive-procedure`, `continuation-p`, `continuation-stack`, `continuation-conts`, `capture-continuation`
5. **Operations dispatch** (lines 1196-1215): `get-operation`
6. **Executor** (lines 1219-1308): `execute-instructions`
7. **Global instruction accumulator** (lines 1314-1346): `*global-instruction-vector*`, `*global-label-table*`, `resolve-operations`, `assemble-into-global`

Note: The readtable (`*ece-readtable*`) must go in the runtime because primitives like `ece-read`, `ece-load-continuation`, and `ece-load` use it. It's also wrapped in `eval-when` for compile-time availability.

### 2. What goes in `compiler.lisp`

Everything needed to compile ECE expressions:

1. **Expression predicates** (lines 645-703): `self-evaluating-p`, `variable-p`, `define-special-form-predicate` macro, all generated predicates, `qq-expand`, `*special-forms*`, `application-p`
2. **Instruction sequence combinators** (lines 718-784): `make-instruction-sequence`, accessors, `append-instruction-sequences`, `preserving`, `tack-on-instruction-sequence`
3. **Label generation** (lines 789-791): `make-label`
4. **Linkage** (lines 795-808): `compile-linkage`, `end-with-linkage`
5. **Compile-time macro environment** (lines 811-815): `*compile-time-macros*`, `*compile-lexical-env*`
6. **Compile dispatch + all compile functions** (lines 819-1150)
7. **Integration** (lines 1350-1391): `compile-and-go`, `compile-file-ece`, `evaluate`, prelude loading, `repl`

### 3. `evaluate` and `compile-and-go` go in compiler.lisp

`evaluate` calls `compile-and-go` which calls `ece-compile`. These are compiler entry points. The runtime doesn't know about `evaluate` — it just runs instruction vectors.

However, `ece-try-eval` (a wrapper primitive) calls `evaluate`. This creates a cross-dependency: the runtime defines `ece-try-eval` which calls a compiler function.

**Solution:** Define `ece-try-eval` in `compiler.lisp` after `evaluate` is defined, and register it there. Same for `ece-load` which calls `compile-file-ece`. Move these two primitives and their registration to `compiler.lisp`.

### 4. Prelude loading stays in compiler.lisp

`(compile-file-ece ...)` for the prelude is a top-level side effect that must run after the compiler is loaded. It stays at the bottom of `compiler.lisp`.

### 5. ASDF loads runtime before compiler

```lisp
:components ((:module "src"
              :components
              ((:file "runtime")
               (:file "compiler" :depends-on ("runtime"))
               (:static-file "prelude.scm"))))
```

## Risks / Trade-offs

- **[Risk] Cross-dependency between runtime primitives and compiler** → Mitigated by moving `ece-try-eval` and `ece-load` registration to `compiler.lisp`. The runtime has no references to `evaluate` or `compile-and-go`.
- **[Risk] Load order sensitivity** → Mitigated by ASDF `:depends-on` ensuring runtime loads first.
- **[Risk] `ece-load` depends on `compile-file-ece`** → `ece-load` body calls `compile-file-ece`, so it must be defined in `compiler.lisp`. Its primitive registration moves there too.
