## Context

ECE has a SICP 5.5 compiler written in Common Lisp (`compiler.lisp`, 579 lines) that compiles Scheme expressions to register machine instructions. The runtime (`runtime.lisp`) provides the instruction executor, environment operations, and primitives. Image save/load serializes the full system state. The goal is to rewrite the compiler in ECE itself, enabling self-hosting and eventual CL-free deployment.

The CL compiler uses `union`, `set-difference`, `format`, `intern`, `member`, `mapcar`, `reduce`, `append`, `reverse`, `gensym`, hash tables, and list manipulation — all available or easily added in ECE.

## Goals / Non-Goals

**Goals:**
- Faithful port of `compiler.lisp` to ECE (`compiler.scm`)
- All existing tests pass when using the metacircular compiler
- Incremental implementation: start with core forms, add features progressively
- Test-driven: each compiler function gets ECE-level tests before/during implementation
- CL compiler remains as bootstrap and reference

**Non-Goals:**
- Replacing the CL compiler in the boot sequence (future work)
- Optimizations beyond what the CL compiler does
- Cross-compilation or multi-target output
- Removing `compiler.lisp` from the codebase

## Decisions

### 1. Translation Strategy: Direct Port
**Decision**: Translate each CL function 1:1 to ECE, preserving structure and naming.

**Rationale**: The CL compiler is already written in a mostly-functional Scheme-compatible style. A direct port minimizes risk and makes the two implementations easy to compare. CL-specific patterns have clear ECE equivalents:

| CL Pattern | ECE Equivalent |
|---|---|
| `(defun name ...)` | `(define (name ...))` |
| `(let ((x v)) ...)` | `(let ((x v)) ...)` |
| `(cond ...)` | `(cond ...)` |
| `(mapcar f lst)` | `(map f lst)` |
| `#'func` | Not needed (first-class) |
| `(member x lst)` | `(member x lst)` |
| `(format nil "~A-~D" ...)` | `(fmt name "-" counter)` + `string->symbol` |
| `(gethash k ht)` | `(hash-ref ht k)` |
| `(setf (gethash ...) ...)` | `(hash-set! ht k v)` |

**Alternative considered**: DSL or simplified compiler — rejected because the CL compiler is already clean and porting 1:1 is simpler than redesigning.

### 2. Label Generation: String Concatenation + Counter
**Decision**: Use a mutable counter variable and `string->symbol`/`fmt` for label generation.

```scheme
(define label-counter 0)
(define (make-label name)
  (set label-counter (+ label-counter 1))
  (string->symbol (fmt (symbol->string name) "-" label-counter)))
```

**Rationale**: Matches the CL `(intern (format nil "~A-~D" name counter))` pattern directly. `string->symbol` already calls `string-upcase` internally, so labels are interned correctly.

### 3. Instruction Sequences as Lists
**Decision**: Represent instruction sequences as `(needs modifies instructions)` — same triple as CL.

**Rationale**: No CL-specific types involved. Lists, symbols, and cons cells work identically in ECE. The `union`/`set-difference` operations on register lists need to be added to the prelude.

### 4. New Primitives: `assemble-into-global` and `execute-from-pc`
**Decision**: Expose two runtime operations as ECE primitives.

- `assemble-into-global`: Takes an instruction list, appends to global vectors, registers labels, returns start PC. Already exists in CL — just needs primitive registration.
- `execute-from-pc`: Wrapper that calls `execute-instructions` with current global state from a given PC. New function needed because `execute-instructions` takes 4 arguments including internal state.

```lisp
;; In runtime.lisp
(defun ece-execute-from-pc (start-pc)
  (execute-instructions *global-instruction-vector*
                        *global-label-table*
                        *global-env*
                        start-pc))
```

**Rationale**: The compiler needs to emit code into the global instruction vector and then run it. These are the minimal hooks needed — everything else (instruction sequence construction, optimization) is pure data manipulation that ECE handles natively.

### 5. Compile-Time Macro Sharing
**Decision**: The metacircular compiler uses the same `*compile-time-macros*` hash table as the CL compiler, accessed via existing `hash-ref`/`hash-set!` after exposing it as an ECE variable.

**Rationale**: Macros registered by the CL-compiled prelude must be visible to the metacircular compiler. Sharing the table (exposed as an ECE binding) is simpler than maintaining two separate macro environments.

### 6. Incremental Build Order
**Decision**: Build the compiler in stages, each with its own tests:

1. **Foundation**: `union`, `set-difference` in prelude; new primitives
2. **Instruction sequences**: `make-instruction-sequence`, `append-instruction-sequences`, `preserving`, `parallel-instruction-sequences`, `tack-on-instruction-sequence`
3. **Label + linkage**: `make-label`, `compile-linkage`, `end-with-linkage`
4. **Core forms**: `compile-self-evaluating`, `compile-variable`, `compile-quoted`, `compile-if`, `compile-begin`/`compile-sequence`
5. **Lambda + application**: `compile-lambda`, `compile-lambda-body`, `compile-application`, `construct-arglist`, `compile-procedure-call`, `compile-proc-appl`
6. **Special forms**: `compile-assignment`, `compile-define`, `compile-callcc`, `compile-apply-form`
7. **Macros + quasiquote**: `compile-define-macro`, `compile-quasiquote`, `qq-expand`
8. **Integration**: `compile-and-go`, `evaluate`, main dispatch (`ece-compile`), predicates

**Rationale**: Each stage produces testable output. Earlier stages are pure data manipulation (no runtime interaction needed), making them easy to test in isolation.

## Risks / Trade-offs

**[Risk] Macro expansion uses `evaluate` recursively** → The metacircular compiler's `expand-macro-at-compile-time` calls `evaluate`, which calls `compile-and-go`, which calls the compiler. This is inherent to the design and works because macro expansion happens at compile time in a separate environment. The CL compiler already does this.

**[Risk] Bootstrap ordering** → `compiler.scm` must be loaded after `prelude.scm` (needs macros like `cond`, `let`, `and`) and after the new primitives are registered. Load order: runtime.lisp → compiler.lisp → prelude.scm → compiler.scm.

**[Risk] Performance** → The metacircular compiler will be slower than the CL compiler since it runs as compiled ECE instructions rather than native CL. This is acceptable — compilation speed is not a bottleneck for the intended use case (interactive fiction games).

**[Trade-off] Two compilers in codebase** → Maintaining both `compiler.lisp` and `compiler.scm` creates duplication. This is intentional: `compiler.lisp` is the bootstrap compiler and reference. Once `compiler.scm` is proven via image save/load, `compiler.lisp` could eventually be made optional.
