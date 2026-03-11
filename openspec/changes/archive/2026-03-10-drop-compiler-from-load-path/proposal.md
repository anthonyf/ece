## Why

The CL bootstrap compiler (`compiler.lisp`, 620 lines) is loaded every time `(asdf:load-system :ece)` runs, even though the bootstrap image already contains the fully self-hosted metacircular compiler. This adds ~1.3s to startup, compiles 4 `.scm` files from source on every load, and keeps cold-boot-only code in the normal load path. Since `image-repl` proved that `runtime.lisp` + an image is sufficient for a working system, compiler.lisp should only be needed for `make image` (cold boot).

## What Changes

- Add `src/boot.lisp` (~25 lines): loads the bootstrap image and defines `evaluate`, `ece-try-eval`, and `repl` as thin wrappers around the metacircular compiler in the image
- **BREAKING**: Change `ece.asd` so the `"ece"` system loads `runtime.lisp` → `boot.lisp` instead of `runtime.lisp` → `compiler.lisp`
- Add `"ece/cold"` ASDF system that loads `runtime.lisp` → `compiler.lisp` (for cold boot / `make image`)
- Update `Makefile` `image:` target to use `ece/cold` system
- Remove `image-repl` and `ece-try-eval-via-mc` from runtime.lisp (boot.lisp subsumes them)

## Capabilities

### New Capabilities
- `boot-from-image`: Defines the fast image-based startup path via `boot.lisp`, providing `evaluate`, `ece-try-eval`, and `repl` without the CL compiler

### Modified Capabilities
- `image-startup`: The `image-repl` function moves to boot.lisp as `repl`; `mc-eval` gains optional env parameter support
- `compile-and-go`: The `evaluate` CL function is now provided by boot.lisp (delegates to mc-compile-and-go) instead of compiler.lisp

## Impact

- **ece.asd**: `"ece"` system component list changes; new `"ece/cold"` system added
- **src/boot.lisp**: New file (~25 lines)
- **src/runtime.lisp**: Remove `image-repl`, `ece-try-eval-via-mc`; update `mc-eval` to accept optional env
- **Makefile**: `image:` target uses `ece/cold`; `run:` target simplified
- **Tests**: No test changes needed — tests call `evaluate` which boot.lisp provides with the same signature
- **bootstrap/ece.image**: No changes — existing image works as-is
