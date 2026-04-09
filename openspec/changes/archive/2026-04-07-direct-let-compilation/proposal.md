## Why

ECE's compiler macro-expands `let`/`let*` into nested lambda applications, creating N procedure objects, N call dispatches, and N `extend-environment` calls per `let*` with N bindings. In tight loops (like the sandbox game loop), this causes measurable performance regression — 90+ FPS drops to ~28 FPS when converting two internal `define`s to `let*`. Additionally, ECE currently allows `define` anywhere in a lambda body, which is non-standard and can lead to subtle scoping bugs.

## What Changes

- **Compile `let` and `let*` as special forms in the compiler** — Instead of macro-expanding to `((lambda ...) ...)`, emit inline environment extension code. One `extend-environment` call per `let`/`let*`, zero procedure objects, zero call dispatches.
- **`let*` uses progressive scoping** — Single frame with N empty slots; each binding's init is compiled with only prior bindings visible (correct `let*` semantics, not `letrec*`).
- **`let` uses parallel binding** — All init expressions compiled before any bindings are visible (correct `let` semantics).
- **Proper TCO for `let`/`let*` in tail position** — Body compiled with `'return` linkage when the `let` is in tail position; env restoration only emitted for non-tail positions.
- **Named `let` unchanged** — Continues to compile via `letrec` + lambda.
- **BREAKING: Enforce internal `define` at top of body** — Like Racket, signal a compile-time error if `define` appears after an expression in a lambda body. Internal defines retain `letrec*` semantics with pre-allocated slots.
- **Add `enclosing-environment` operation** to both CL and WASM runtimes for env restoration after non-tail `let` bodies.

## Capabilities

### New Capabilities
- `direct-let-compilation`: Compiler special-form handling for `let` and `let*` with correct scoping semantics and TCO support.
- `define-at-top-enforcement`: Compile-time validation that internal `define` forms appear only at the beginning of a lambda body.

### Modified Capabilities
- `metacircular-compiler`: Compiler dispatch extended to recognize `let`/`let*` before macro expansion.
- `tail-call-optimization`: TCO coverage extended to `let`/`let*` in tail position.

## Impact

- **`src/compiler.scm`** — New `mc-compile-let`, `mc-compile-let*` functions; define-at-top validation in `mc-compile-lambda-body`.
- **`src/prelude.scm`** — `let`/`let*` macros retained for non-compiled contexts but compiler intercepts them first.
- **`wasm/runtime.wat`** — Add `enclosing-environment` operation (read enclosing field of env frame).
- **`src/runtime.lisp`** — Same operation for CL runtime.
- **Test files** — New tests for scoping correctness, TCO, and define restriction. Existing tests that use `define` after expressions in bodies will need updating.
- **Bootstrap** — Requires two-pass `make bootstrap` since compiled .ecec files contain the old compilation strategy.
