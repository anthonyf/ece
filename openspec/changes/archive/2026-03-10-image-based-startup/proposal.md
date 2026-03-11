## Why

The cold bootstrap compiles four `.scm` files through the CL compiler every time ECE loads (~1.3s warm). An image can restore the same state in ~0.1s. More importantly, image-based startup is a prerequisite for eventually dropping the CL bootstrap compiler — without it, there's no way to start ECE from just `runtime.lisp` + a pre-built image.

Currently, `load-image!` cannot fully restore a working system because parameter objects (`make-parameter`) use CL closures stored via `symbol-function`, which don't survive `write`/`read` serialization. The metacircular compiler uses `*mc-compile-lexical-env*` (a parameter), so compiling anything after image load fails with "The function PARAM1 is undefined."

## What Changes

- Fix parameter object serialization so parameters survive image round-trips
- Add a startup path that loads `runtime.lisp` + image instead of cold-bootstrapping through `compiler.lisp`
- Add a `make image` target to generate the bootstrap image from source
- Check the bootstrap image into the repo (at `bootstrap/ece.image`) so users can skip cold boot
- Add a `make run` target that uses the image for fast startup

## Capabilities

### New Capabilities
- `image-startup`: The ability to start ECE from `runtime.lisp` + a saved image, bypassing the CL bootstrap compiler entirely

### Modified Capabilities
- `parameterize`: Parameter objects must survive image save/load round-trips (currently broken — closures in `symbol-function` are lost)
- `image-serialization`: Images must include parameter state so loaded images produce a fully functional system

## Impact

- `src/runtime.lisp`: Fix `ece-make-parameter` to use serializable state instead of `symbol-function` closures; add `ece-load-image` restoration of parameter state; add a CL-side entry point for image-based startup
- `src/compiler.lisp`: No changes needed (kept for cold boot / image regeneration)
- `Makefile`: Add `image` and `run` targets
- `bootstrap/ece.image`: New checked-in file (~3.7 MB text, ~371 KB compressed)
- `tests/ece.lisp`: Add tests for parameter round-trip and image-based startup
