## Context

ECE's stdlib is currently ~180 lines of `(evaluate '...)` calls in `ece.lisp` (lines 1087-1320), sandwiched between `(setf *readtable* *ece-readtable*)` and `(setf *readtable* (copy-readtable nil))` switches. This is pure ECE code wearing a CL costume. The existing `ece-load` function already handles reading ECE source files with the correct readtable and package bindings.

## Goals / Non-Goals

**Goals:**
- Extract all pure-ECE stdlib definitions into `src/prelude.scm`
- Load the prelude automatically at system initialization via `ece-load`
- Eliminate the CL readtable dance from `ece.lisp`
- Preserve identical behavior — same functions and macros available at startup

**Non-Goals:**
- Changing what's in the stdlib (no additions, removals, or modifications)
- User-configurable prelude paths
- Prelude caching or compilation

## Decisions

### 1. File location: `src/prelude.scm`

Place the prelude alongside `ece.lisp` in the `src/` directory. It's part of the system, not user data.

**Alternative**: Top-level `prelude.scm`. Rejected — it's a source file, belongs in `src/`.

### 2. Load mechanism: `ece-load` with ASDF path resolution

Call `ece-load` at the end of `ece.lisp` initialization (after the evaluator is defined, before `defun repl`). Use ASDF to resolve the file path reliably:

```lisp
(ece-load (asdf:system-relative-pathname :ece "src/prelude.scm"))
```

**Alternative**: Use `*load-truename*` for relative path. Rejected — ASDF path resolution is more robust across different loading scenarios (REPL, ASDF, qlot).

### 3. Prelude content: strip `(evaluate '...)` wrappers, write native ECE

Each `(evaluate '(define ...))` becomes just `(define ...)`. Each `(evaluate '(define-macro ...))` becomes just `(define-macro ...)`. The CL readtable switches are no longer needed since `ece-load` binds `*readtable*` to `*ece-readtable*` internally.

### 4. Definition order preserved

Keep the same definition order in `prelude.scm` as in the current `ece.lisp`. Dependencies matter: `map` must be defined before macros that use it (like `let`, `fmt`).

### 5. Register prelude.scm as an ASDF static-file component

Add `prelude.scm` to the ASDF system definition as a `:static-file` component so it's included in system distribution and ASDF knows about it.

## Risks / Trade-offs

- **No FASL caching**: The prelude is parsed and evaluated fresh on every system load rather than being compiled into a FASL. For ~20 definitions this is negligible (milliseconds). → Acceptable for the cleanliness gain.
- **File-not-found at load time**: If `prelude.scm` is missing, system init fails. → Clear error message from `ece-load`'s `with-open-file`. ASDF static-file ensures it's distributed with the system.
- **Test environment**: Tests load the system via ASDF which triggers prelude loading. No change to test workflow needed.
