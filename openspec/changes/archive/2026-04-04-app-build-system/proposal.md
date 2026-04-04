## Why

There is no way to package an ECE application for distribution. Building a web app or CL executable requires manually copying runtime files, compiling .scm files individually, and stitching together HTML/JS/WASM artifacts. Users working in their own repos have no entry point — they'd need to understand the ECE build internals. A `compile-system` function and `ece-build` script would let users go from .scm source files to a runnable app directory in one command.

## What Changes

- **Add multi-space `.ecec` bundle format**: Multiple `(ecec-header ...) (instruction-list ...)` pairs concatenated in a single file. Each .scm file compiles to its own named space with its own source-map. Existing single-space .ecec files remain valid.
- **Add `compile-system` ECE function**: Takes a list of .scm filenames and an output path. Calls `compile-file` on each, writes all spaces to one bundle. Lives in `compilation-unit.scm`.
- **Add `load-bundle` ECE function**: Reads a multi-space .ecec bundle, loading each space sequentially. Counterpart to `compile-system` for runtime loading.
- **Add `bin/ece-build` shell script**: SDK entry point. Takes `--target web|cl`, a list of .scm files, and `-o <dir>`. Boots ECE, calls `compile-system`, then packages the result with runtime files for the target platform.
- **Add web app template**: `templates/web/index.html` with a minimal HTML shell that loads the runtime and app bundle.
- **Add CL app template**: `templates/cl/run.lisp` boot script that loads runtime, bootstrap, and app bundle.

## Capabilities

### New Capabilities
- `compile-system`: Multi-file compilation to a single .ecec bundle with `compile-system` and `load-bundle` functions.
- `app-packaging`: Shell script and templates for packaging ECE apps for web (HTML+WASM) and CL targets.

### Modified Capabilities
- `compile-file`: The existing .ecec format is extended — `load-compiled` must tolerate multi-space bundles (read until EOF instead of expecting exactly one space).

## Impact

- **`src/compilation-unit.scm`**: New `compile-system` and `load-bundle` functions.
- **`src/runtime.lisp`**: CL-side `load-ecec-file` updated to support multi-space bundles.
- **`wasm/runtime.wat`**: WASM `load_ecec` updated to support multi-space bundles (loop until EOF).
- **`bin/ece-build`**: New shell script (SDK entry point).
- **`templates/web/`**: New HTML template for web target.
- **`templates/cl/`**: New CL boot script template.
- **No breaking changes**: Existing single-space .ecec files continue to work unchanged.
