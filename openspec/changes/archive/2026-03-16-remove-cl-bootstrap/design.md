## Context

ECE currently has two boot paths: a warm path (`runtime.lisp` + image) and a cold path (`ece/cold` loading `runtime.lisp` → `readtable.lisp` → `compiler.lisp`). The cold path uses the CL compiler to read `.scm` source files via `*ece-readtable*` and compile them with a CL-native compiler. However, the image already contains a fully functional metacircular compiler, ECE reader, assembler, and compaction system — all written in ECE itself. The CL compiler served its purpose as the original bootstrap seed and is no longer needed.

The `boot.lisp` file (48 lines) is dead code — its functionality was folded into the bottom of `runtime.lisp` in the previous change (PR #8).

## Goals / Non-Goals

**Goals:**
- Remove all CL bootstrap compiler and readtable code from the repository
- Provide a self-hosting `make image` that uses ECE to rebuild itself
- Tag a recovery point for disaster scenarios
- Clean up stale build artifacts

**Non-Goals:**
- Changing the runtime (`runtime.lisp`) behavior — it stays as-is
- Modifying any `.scm` source files
- Changing the image format
- Adding git-lfs (830K image is fine for plain git)

## Decisions

### 1. Self-hosting image rebuild via `make image`

The new `make image` target loads the `"ece"` system (runtime + existing image), then uses ECE's own `load` to read each `.scm` source file in the same order the cold path did:

```
prelude.scm → compiler.scm → reader.scm → assembler.scm → compaction.scm
```

Then calls `ece-save-image` to write the new image. This is implemented as a single `sbcl --eval` invocation that calls `(ece:evaluate '(begin (load "src/prelude.scm") ...))`.

**Why not a `.scm` rebuild script?** A shell-level `--eval` keeps the rebuild self-contained in the Makefile with no extra files. The load sequence is short (5 files) and unlikely to change.

### 2. Tag `last-cl-bootstrap` before deletion

Before deleting the CL compiler files, we tag the current HEAD as `last-cl-bootstrap`. This provides a recovery path: if the image is ever corrupted and no valid image exists anywhere in git history, you can checkout this tag and cold-boot from scratch using the CL compiler.

**Alternative considered:** Keep `compiler.lisp` and `readtable.lisp` in a `bootstrap/` archive directory. Rejected because git history already preserves them, and dead code in the tree invites confusion.

### 3. Delete stale `.fasl` files

`src/main.fasl` and `src/runtime.fasl` are compiled CL artifacts that predate the `.gitignore` rule. They serve no purpose and should be removed from tracking.

## Risks / Trade-offs

- **[Risk] Image corruption with no CL compiler** → Mitigated by the `last-cl-bootstrap` git tag. Also, any prior commit with the image can serve as a recovery seed — you only need *some* working image to self-host.
- **[Risk] Load order dependency in `make image`** → The 5-file sequence must match the cold path order. This is documented in the Makefile and is unlikely to change since it follows the natural dependency chain (prelude → compiler → reader → assembler → compaction).
- **[Trade-off] 830K binary in git history** → Each image rebuild adds ~830K to history. Acceptable at this scale. If the image grows significantly, git-lfs can be added later without changing the workflow.
