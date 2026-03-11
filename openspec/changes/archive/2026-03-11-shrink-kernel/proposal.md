## Why

The CL runtime (runtime.lisp) is the portability surface for a future WebAssembly port. Every line of CL must be rewritten for each target platform. Image compaction is currently 257 lines of CL that only walks ECE data structures — it should be self-hosted ECE code. `print-text` and `fmt` in the prelude are non-standard Scheme conveniences that don't belong in the core.

## What Changes

- Move instruction vector compaction from CL (runtime.lisp) to ECE (new `compaction.scm` loaded into the image)
- Remove the ~257 lines of compaction CL code from runtime.lisp
- Add minimal CL primitives needed for ECE-side compaction (if any beyond what already exists)
- Remove `print-text`, `lines`, and `fmt` from the prelude — non-standard
- Update the reader's string interpolation to expand to `(string-append ... (write-to-string expr) ...)` instead of `(fmt ...)`
- `write-to-string` stays: used by the compiler and now by string interpolation
- **BREAKING**: `print-text`, `lines`, `fmt` no longer available after image load

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `image-serialization`: `save-image!` still compacts, but compaction logic is now ECE code in the image rather than CL code in the runtime
- `prelude-functions`: Remove `print-text`, `lines`, and `fmt` non-standard formatting helpers
- `ece-reader`: String interpolation expands to `string-append`/`write-to-string` instead of `fmt`

## Impact

- `src/runtime.lisp`: Remove ~257 lines of compaction code, keep `ece-save-image` calling into ECE-side compaction
- `src/prelude.scm`: Remove `print-text` and `lines`
- New `src/compaction.scm`: ECE implementation of `compact-for-save`
- `bootstrap/ece.image`: Regenerated with compaction code and without removed prelude functions
- `tests/ece.lisp`: Update any tests that use removed functions
