## Why

The current image format uses Common Lisp's `write`/`read` with `*print-circle*` and a custom readtable (`*ece-readtable*`). This means any runtime that loads an image must implement a full s-expression reader with `#n=`/`#n#` structural sharing, quasiquote, string interpolation, and hash table literal syntax. For portability (e.g., a C port), this is a significant burden — implementing a recursive descent parser just to load an image is code we want to avoid. A flat, line-oriented format requires only a trivial deserializer (a switch statement over ~12 opcodes), making the runtime portable with minimal effort.

After the first flat-format image is saved, the system is fully self-hosting: the image contains the ECE reader, compiler, assembler, and prelude. The CL reader infrastructure (`*ece-readtable*`, reader macros, `ece-read`) is only needed for the one-time bootstrap transition and can be removed from the runtime entirely.

## What Changes

- **New image serializer**: Walk data structures depth-first, emit flat build instructions (one per line) with structural sharing via `def`/`ref` opcodes. Implemented as a CL function replacing `%write-image`.
- **New image deserializer**: Stack-based loader reads lines, pushes values, pops to build compound structures. ~80 lines of CL replacing `ece-load-image`.
- **BREAKING**: Remove CL reader infrastructure from runtime — `*ece-readtable*`, quasiquote/unquote reader macros, string interpolation reader macro, `{...}` hash table reader macro, `ece-read` function (~230 lines). Cold boot (`ece/cold` system) retains the CL reader temporarily for the one-time transition build.
- **Character serialization by code point**: Use integer char codes instead of CL-specific character names (avoids SBCL `#\Combining_Tilde` style names).
- **Image file extension**: Change from `.image` to `.flat` (or keep `.image` — TBD) to distinguish format versions.

## Capabilities

### New Capabilities
- `flat-image-serializer`: Serializes ECE system state to a flat, line-oriented text format using stack-based build instructions with structural sharing
- `flat-image-deserializer`: Loads a flat-format image file using a trivial stack-based deserializer (no parser required)

### Modified Capabilities
- `image-serialization`: **BREAKING** — `%write-image` changes from CL `write` with `*print-circle*` to flat format emitter; `ece-load-image` changes from CL `read` to line-based stack loader
- `boot-from-image`: Image loading uses new flat deserializer; CL readtable no longer needed at boot time

## Impact

- **`src/runtime.lisp`**: Remove `*ece-readtable*` and all reader macro definitions (~230 lines). Replace `ece-%write-image` and `ece-load-image` with flat format equivalents.
- **`src/boot.lisp`**: Update image loading call to use new deserializer.
- **`src/compiler.lisp`** (cold boot only): Retains CL reader for the transition build that produces the first flat-format image.
- **`bootstrap/ece.image`**: Regenerated in flat format after implementation.
- **`Makefile`**: Update `make image` target if file extension changes.
- **`tests/ece.lisp`**: Update image round-trip tests to work with new format.
- **No runtime dependencies change** — this is purely internal serialization format.
