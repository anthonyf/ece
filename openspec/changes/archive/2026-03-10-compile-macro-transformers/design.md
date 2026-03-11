## Context

Macro transformers in ECE are currently stored as `(params body env)` source triples. When a macro is used, `mc-expand-macro-at-compile-time` manually extends the environment with the unevaluated operands, then compiles and evaluates each body form via `mc-compile-and-go`. This is effectively interpretation — the transformer is re-compiled on every expansion.

ECE is a compile-only system: `eval` compiles its input. Macro transformers are ordinary functions (`sexp → sexp`) and should be compiled once at definition time, then called at expansion time.

## Goals / Non-Goals

**Goals:**
- Compile macro transformers at definition time, store as compiled procedures
- Call compiled transformer directly at expansion time (no per-expansion compilation)
- Shrink image size by storing entry PCs instead of source code in the macro table
- All existing macro tests pass unchanged

**Non-Goals:**
- Changing macro semantics (still receives unevaluated operands, returns expanded form)
- Removing `*compile-time-macros*` table (still needed, just stores procedures now)
- Changing how the compiler detects/dispatches macro usage

## Decisions

### Decision 1: Compile transformer as lambda at define-macro time

`mc-compile-define-macro` will compile `(lambda params . body)` via `mc-compile-and-go`, which returns a `(compiled-procedure entry env)` value. This compiled procedure is stored in the macro table.

**Alternative**: Store a closure with a PC (custom representation). Rejected — compiled procedures already exist and work with `execute-compiled-call`.

### Decision 2: Call transformer via execute-compiled-call at expansion time

`mc-expand-macro-at-compile-time` receives a compiled procedure from the macro table and calls it with the unevaluated operands using `execute-compiled-call`. This is the same mechanism used for all compiled procedure calls.

**Alternative**: Use `mc-compile-and-go` to apply the procedure. Unnecessary indirection — the procedure is already compiled.

### Decision 3: mc-compile-define-macro becomes a side-effect-only compile-time operation

Currently `mc-compile-define-macro` calls `set-macro!` as a side effect during compilation (not at runtime). This stays the same — the difference is that it now calls `mc-compile-and-go` to build the compiled transformer before storing it.

The compiled code emitted for the `define-macro` form itself remains a simple `(assign val (const <name>))` — it just returns the macro name, same as before.

### Decision 4: Image serialization unchanged

Compiled procedures in the macro table are `(compiled-procedure entry-pc env)`. The entry PC points into the instruction vector, the env is the global env. Both already serialize correctly via `*print-circle*` — no changes to `ece-save-image` or `ece-load-image`.

The macro table entries become smaller (a 3-element list with an integer PC vs. source code with params and body forms).

## Risks / Trade-offs

**[Risk] Macro defined before compiler is fully loaded** → During cold boot, `mc-compile-and-go` must be available when `define-macro` is encountered. This is already the case: macros are defined in prelude.scm which is loaded after compiler.scm defines `mc-compile-and-go`.

**[Risk] Rest parameters in macro transformers** → Macros like `(define-macro (when test . body) ...)` use rest params. `mc-compile-and-go` of `(lambda (test . body) ...)` must handle dotted parameter lists. The compiler already supports this via rest-parameter compilation — no issue.

**[Trade-off] Compile cost moves to definition time** → Each `define-macro` now compiles a lambda. This adds a small cost during cold boot / prelude loading, but eliminates the per-expansion cost. Net win since macros are defined once and expanded many times.
