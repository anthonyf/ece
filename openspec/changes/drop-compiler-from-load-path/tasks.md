## 1. Update runtime.lisp

- [x] 1.1 Update `mc-eval` to accept optional env parameter: `(defun mc-eval (expr &optional env)` — when env is supplied, pass it to `mc-compile-and-go` via `execute-compiled-call`; when not supplied, call without env so mc-compile-and-go uses its default
- [x] 1.2 Remove `image-repl` function from runtime.lisp (boot.lisp's `repl` replaces it)
- [x] 1.3 Remove `ece-try-eval-via-mc` function from runtime.lisp (boot.lisp's `ece-try-eval` replaces it)
- [x] 1.4 Remove `image-repl` and `ece-try-eval-via-mc` from the export list

## 2. Create boot.lisp

- [x] 2.1 Create `src/boot.lisp` with: `(ece-load-image ...)` to load bootstrap image at load time
- [x] 2.2 Define `evaluate` in boot.lisp: `(defun evaluate (expr &optional (env *global-env* env-p))` — uses `mc-eval` with env when env-p, plain `mc-eval` when not
- [x] 2.3 Define `ece-try-eval` in boot.lisp: wraps `evaluate` with `handler-case`, prints error and returns nil on failure
- [x] 2.4 Define `repl` in boot.lisp: uses `evaluate` to compile and run the REPL loop expression (same body as current compiler.lisp `repl`)
- [x] 2.5 Export `evaluate`, `repl`, and `mc-eval` from boot.lisp

## 3. Update ASDF system definitions

- [x] 3.1 Change `"ece"` system in ece.asd: replace `(:file "compiler")` with `(:file "boot")` in components
- [x] 3.2 Add `"ece/cold"` system in ece.asd: loads `runtime.lisp` → `compiler.lisp` for cold boot
- [x] 3.3 Ensure `"ece/tests"` depends on `"ece"` (not `"ece/cold"`)

## 4. Update Makefile

- [x] 4.1 Update `image:` target to use `(asdf:load-system :ece/cold)` instead of `(asdf:load-system :ece)`
- [x] 4.2 Update `run:` target to use `(asdf:load-system :ece)` and `(ece:repl)` instead of loading runtime.lisp directly
- [x] 4.3 Update `repl:` target to use same approach as `run:` (both now load image via boot.lisp)

## 5. Verify

- [x] 5.1 Run `make test` — all existing tests pass without modification
- [x] 5.2 Run `make repl` — REPL starts and can evaluate expressions
- [x] 5.3 Run `make image` using ece/cold — regenerate bootstrap image successfully
- [x] 5.4 Run `make run` — REPL starts from regenerated image
