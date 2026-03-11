## Context

ECE has two compilation paths: the CL bootstrap compiler (`compiler.lisp`, 620 lines) and the self-hosted metacircular compiler (`compiler.scm`, compiled into the image). After the image-based-startup change, `runtime.lisp` + a bootstrap image provides a fully working system via `mc-eval` and `image-repl`. However, the ASDF system still loads compiler.lisp on every `(asdf:load-system :ece)`, re-compiling prelude.scm, compiler.scm, reader.scm, and assembler.scm from source — all of which are already in the image.

Tests call `evaluate` (a CL function currently defined in compiler.lisp) ~500 times. The image's `try-eval` primitive binds to `ece-try-eval` (also in compiler.lisp). These are the only two CL functions from compiler.lisp that the normal runtime path needs.

## Goals / Non-Goals

**Goals:**
- Remove compiler.lisp from the default ASDF load path (`"ece"` system)
- Provide `evaluate`, `ece-try-eval`, and `repl` via a slim `boot.lisp` that loads the image
- Keep compiler.lisp available via `"ece/cold"` system for cold boot / image generation
- All existing tests pass without modification

**Non-Goals:**
- Modifying the bootstrap image format
- Changing the metacircular compiler
- Removing compiler.lisp from the repository (it's still needed for cold boot)

## Decisions

### 1. `boot.lisp` loads the image at ASDF load time

**Decision**: `boot.lisp` calls `(ece-load-image ...)` at top level, so loading the `"ece"` system immediately populates all global state.

**Alternative**: Lazy loading (load image on first `evaluate` call). Rejected — adds complexity for no benefit since tests and REPL both need the image immediately.

### 2. `evaluate` delegates to `mc-compile-and-go` via `execute-compiled-call`

**Decision**: `evaluate` looks up `mc-compile-and-go` from `*global-env*` and calls it with `execute-compiled-call`, passing the optional env argument through.

```
(evaluate expr)       → mc-compile-and-go sees env-args=() → uses global env
(evaluate expr env)   → mc-compile-and-go sees env-args=(env) → uses provided env
(evaluate expr nil)   → mc-compile-and-go sees env-args=(nil) → uses nil env
```

This matches the current `evaluate` signature exactly: `(defun evaluate (expr &optional (env *global-env*)))`.

**Alternative**: Have `evaluate` always pass env (defaulting to `*global-env*`). This also works since `mc-compile-and-go` handles both paths, but the supplied-p approach is cleaner — when no env is given, `mc-compile-and-go` uses its own default (global env), keeping the semantics identical.

### 3. `ece-try-eval` defined in boot.lisp (not runtime.lisp)

**Decision**: Define `ece-try-eval` in boot.lisp, wrapping `evaluate` with `handler-case`. This means the image's existing `(primitive ece-try-eval)` binding works via `symbol-function` lookup.

**Rationale**: `ece-try-eval-via-mc` in runtime.lisp was a stopgap for `image-repl`. With boot.lisp providing the real `ece-try-eval`, both `image-repl` and `ece-try-eval-via-mc` become unnecessary and can be removed from runtime.lisp.

### 4. Two ASDF systems sharing runtime.lisp

**Decision**:
- `"ece"` system: `runtime.lisp` → `boot.lisp`
- `"ece/cold"` system: `runtime.lisp` → `compiler.lisp`

Both share runtime.lisp. The `"ece/cold"` system is only used by `make image`.

### 5. `expand-macro` dead binding left as-is

**Decision**: The image contains `(primitive expand-macro-at-compile-time)` but the CL function won't exist at runtime. This is harmless — nothing calls it (the mc-compiler uses its own `mc-expand-macro-at-compile-time`). No cleanup needed.

**Alternative**: Strip the binding during image save or add a dummy function. Rejected — unnecessary complexity for dead code.

## Risks / Trade-offs

- **[Risk] Bootstrap image must be kept in sync with code changes** → This is already the case since image-based-startup. `make image` regenerates it. No new risk introduced.
- **[Risk] `expand-macro` dead binding could confuse users who call it** → Mitigation: it was never documented or intended for user use. The mc-compiler's own macro expansion is the supported path.
- **[Trade-off] Two ASDF systems to maintain** → The cold system is trivial (just swaps boot.lisp for compiler.lisp). Worth it for the clean separation.
- **[Trade-off] `make image` requires `ece/cold` system name** → Clear naming makes the intent obvious. Makefile handles it.
