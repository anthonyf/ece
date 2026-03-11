## Context

ECE cold-bootstraps every time it loads: `runtime.lisp` sets up the CL infrastructure, `compiler.lisp` defines the CL bootstrap compiler, then four `.scm` files (prelude, compiler, reader, assembler) are compiled via `compile-file-ece`. This takes ~1.3s (warm) and is identical work every time. `save-image!`/`load-image!` exist and can restore state in ~0.1s, but parameter objects break on round-trip because they store CL closures in `symbol-function` which can't be serialized.

The `repl` function is a CL `defun` in `compiler.lisp` that calls `evaluate` — so skipping `compiler.lisp` also means no REPL entry point. A new CL-side entry point is needed that loads an image and starts the REPL via the executor.

## Goals / Non-Goals

**Goals:**
- Fix parameter objects so they survive image save/load round-trips
- Add a startup path: `runtime.lisp` → `load-image!` → REPL (no `compiler.lisp` needed)
- Provide `make image` to regenerate the bootstrap image from source
- Provide `make run` for fast image-based startup
- Check in the bootstrap image so clones can skip cold boot

**Non-Goals:**
- Removing `compiler.lisp` — it stays for cold boot, image regeneration, and tests
- SBCL core dumps — image format remains ECE's text S-expression format
- Changing the ASDF system structure — `(asdf:load-system :ece)` still cold-boots as before

## Decisions

### Decision: Use a parameter table instead of symbol-function closures
**Choice:** Store parameter state in a `*parameter-table*` hash table (keyed by parameter name symbol) instead of `symbol-function` closures. Each entry holds `(value . converter)`. The `apply-primitive-procedure` dispatch for parameter names looks up this table.

**Alternatives considered:**
- Serialize closures specially in `save-image!` — complex and fragile; closures close over mutable `cons` cells that are the actual state
- Re-create parameters on image load by replaying definitions — would require tracking creation order and arguments, hard to get right

**Rationale:** A hash table is naturally serializable (just an alist). The parameter name symbol (`PARAM1`, etc.) already serves as the key. The dispatch can happen in `apply-primitive-procedure` — when the proc name is found in `*parameter-table*`, use the table entry directly instead of `funcall`ing the symbol.

### Decision: Serialize parameter table as 6th image element
**Choice:** Add `*parameter-table*` as the 6th element of the image list, alongside existing instruction vector, label table, environment, macro table, and name table. `*parameter-counter*` is also saved to avoid name collisions after load.

**Rationale:** Follows the existing pattern. Backward compatibility with old 5-element images is not a concern since this is pre-1.0.

### Decision: Add `image-repl` function in runtime.lisp
**Choice:** Add a CL function `image-repl` in `runtime.lisp` that:
1. Calls `ece-load-image` on the bootstrap image path
2. Invokes the `repl-loop` function from the loaded image's global env via `execute-compiled-call`

**Rationale:** This is the minimal CL-side entry point needed. The REPL logic itself (reading, eval, print loop) is already compiled into the image. We just need to kick it off.

### Decision: Bootstrap image at `bootstrap/ece.image`
**Choice:** Check in the image at `bootstrap/ece.image`. `make image` regenerates it via cold boot + `save-image!`.

**Rationale:** ~3.7 MB text file. Diffs will be noisy but this is a build artifact, not human-edited source. It's the same pattern as self-hosting compilers checking in their stage-0 binary.

## Risks / Trade-offs

- **Stale image**: If `.scm` files change but `make image` isn't re-run, the checked-in image is stale → tests will catch this since they cold-boot via `asdf:load-system :ece`
- **Repo size**: ~3.7 MB per image update in git history → acceptable for now; can move to Git LFS later if needed
- **Parameter table performance**: One extra hash table lookup per parameter access → negligible since parameters are rarely called in hot loops
