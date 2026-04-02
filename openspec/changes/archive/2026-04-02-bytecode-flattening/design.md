## Context

The .ecec format currently stores N instruction lists per file (one per top-level source expression). Both loaders (CL `load-ecec-file` in runtime.lisp and WASM `load_ecec` in runtime.wat) read units in a loop, inject env-reset instructions between them, and resolve labels across boundaries. This worked for incremental development but adds complexity and makes .ecec files hard to read or diff.

Key files:
- `src/compilation-unit.scm` — `compile-file` reads source, compiles each form, writes units
- `src/runtime.lisp` — `load-ecec-file` loops reading units, assembles and executes each
- `wasm/runtime.wat` — `load_ecec` two-phase scan across units
- `bootstrap/*.ecec` — 5 files (prelude, compiler, reader, assembler, compilation-unit)

## Goals / Non-Goals

**Goals:**
- One flat instruction list per .ecec file, human-readable (one instruction per line)
- Simplified loaders (single read/scan instead of loop)
- Golden-file tests for compiler output stability
- Clean migration via two-pass bootstrap

**Non-Goals:**
- Binary .ecec format (text stays — readability is the point)
- Changing the instruction set or opcodes
- Changing the ecec-header format (space name, macro list stay the same)
- Incremental compilation of individual forms (compile-file always compiles whole files)

## Decisions

### 1. Flat format: one instruction list with explicit env-resets

**Decision**: `compile-file` concatenates all compiled units into a single instruction list, inserting `(assign env (const *global-env*))` between units explicitly. The output is one s-expression containing all instructions.

**Current format:**
```
(ecec-header (space prelude) (macros (cond let ...)))
((assign val (const 42)) (goto (label L1)) L1 ...)
((assign val (const 99)) (goto (label L2)) L2 ...)
```

**New flat format:**
```
(ecec-header (space prelude) (macros (cond let ...)))
((assign val (const 42))
 (goto (label L1))
 L1
 ...
 (assign env (const *global-env*))
 (assign val (const 99))
 (goto (label L2))
 L2
 ...)
```

**Alternative considered**: Multiple lines with a separator marker (e.g., `;;--- unit ---`). Rejected because a single flat list is simpler for loaders and enables straightforward golden-file diffing.

### 2. Pretty-print one instruction per line

**Decision**: Write each instruction on its own line within the outer parentheses. Labels get their own line too. This makes git diffs meaningful — a compiler change shows exactly which instructions changed.

**Alternative considered**: Compact single-line (current approach). Rejected because the whole point is readability and diffability.

### 3. Macro compilation ordering preserved

**Decision**: `compile-file` still processes forms in order. When it encounters a `define-macro`, it compiles and executes it immediately (as now) so subsequent forms can use the macro. The flat output contains the compiled `set-macro!` form's instructions at the correct position in the stream. No change to macro handling — just the output format.

### 4. Golden-file test design

**Decision**: A fixed set of `.scm` files in `tests/golden/` contain known Scheme expressions. A make target compiles them and writes the flat instruction output to `tests/golden/*.expected`. CI recompiles and diffs against the expected files.

```
tests/golden/
  basic-arithmetic.scm       # source
  basic-arithmetic.expected   # checked-in golden output
  closures.scm
  closures.expected
  callcc.scm
  callcc.expected
  ...
```

The golden files are the flat .ecec instruction lists (without the header, since headers contain space names that may vary). A simple `diff` catches regressions.

**Alternative considered**: Structured comparison (parse instructions and compare ASTs). Rejected — text diff is simpler, more transparent, and catches formatting changes too.

### 5. Two-pass bootstrap migration

**Decision**: Migration uses the existing `make bootstrap` two-pass approach:
1. Boot from old multi-unit .ecec files
2. Recompile all .scm → new flat .ecec files
3. Boot from new flat .ecec files
4. Recompile again to verify idempotence (output should match step 2)

The CL loader needs a brief compatibility shim during migration: detect whether the second read returns a list-of-lists (old format) or a flat instruction list (new format). This shim can be removed after migration.

**Alternative considered**: Dual-format loader permanently. Rejected — unnecessary complexity. One clean migration, then remove the old path.

### 6. Loader simplification

**CL loader** (`load-ecec-file`) becomes:
```lisp
(defun load-ecec-file (pathname)
  (with-open-file (stream pathname)
    (let* ((header (cl:read stream))
           (space-sym (extract-space-name header))
           (sid (create-space (symbol-name space-sym)))
           (all-instrs (cl:read stream)))
      (let ((*current-space-id* sid))
        (assemble-into-space sid all-instrs)
        (execute-instructions sid 0 *global-env*)))))
```

**WASM loader** (`load_ecec`) becomes single-pass: read one list, scan for labels, build instruction vector. No unit boundaries to track.

## Risks / Trade-offs

**[Risk] Large .ecec files may be slow to read as one s-expression** → Mitigation: CL reader handles large lists fine. WASM ecec-read-sexp already processes the full file; fewer reads is actually faster.

**[Risk] Golden files are fragile — label names change with compiler modifications** → Mitigation: Labels are gensym-based (`L13458`). Reset the gensym counter before compiling golden test files so labels are deterministic. Alternatively, golden files could normalize labels (L0, L1, L2...) but that adds complexity.

**[Risk] Two-pass bootstrap could fail if new compile-file has bugs** → Mitigation: The second pass verifies idempotence. If output differs, the migration is not clean and should be investigated before committing.

**[Trade-off] Losing per-form granularity** → Acceptable: nobody uses per-form .ecec loading. The REPL compiles forms individually (not via compile-file). The flat format is strictly better for the file-compilation use case.
