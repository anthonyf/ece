## Why

ECE is fully self-hosting: the image contains its own compiler, reader, assembler, and compaction logic. The CL bootstrap compiler (`compiler.lisp`), CL readtable (`readtable.lisp`), and the `ece/cold` ASDF system exist only for cold-booting from zero — but the committed `bootstrap/ece.image` makes that unnecessary. Removing them eliminates ~830 lines of dead CL code and makes the self-hosting story explicit: ECE rebuilds itself using itself.

## What Changes

- **BREAKING**: Delete `src/compiler.lisp` (674 lines) — the CL bootstrap compiler
- **BREAKING**: Delete `src/readtable.lisp` (156 lines) — the CL readtable (`*ece-readtable*`)
- Delete `src/boot.lisp` (48 lines) — dead code, already folded into `runtime.lisp`
- Remove `"ece/cold"` ASDF system definition from `ece.asd`
- Rewrite `make image` to use ECE's own compiler/reader to rebuild the image from `.scm` sources (self-hosting rebuild)
- Delete stale `.fasl` files from `src/` (`main.fasl`, `runtime.fasl`)
- Tag the current commit as `last-cl-bootstrap` for disaster recovery

## Capabilities

### New Capabilities
- `self-hosting-image-rebuild`: `make image` uses the running ECE system (runtime + existing image) to load `.scm` sources via ECE's own `load` and save a new image via `save-image!`

### Modified Capabilities
- `boot-from-image`: Remove the `ece/cold` requirement — no cold boot system exists anymore
- `image-startup`: `make image` uses self-hosting rebuild instead of `ece/cold`
- `makefile`: `image:` target rewritten for self-hosting; stale `.fasl` cleanup

## Impact

- **`src/compiler.lisp`** — deleted
- **`src/readtable.lisp`** — deleted
- **`src/boot.lisp`** — deleted
- **`src/main.fasl`**, **`src/runtime.fasl`** — deleted
- **`ece.asd`** — `ece/cold` system removed
- **`Makefile`** — `image:` target rewritten
- **Disaster recovery**: If the image is ever corrupted, recover by checking out the `last-cl-bootstrap` tag and cold-booting from there
