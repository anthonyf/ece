## Context

runtime.lisp contains four near-identical cond trees for display/write operations, an unguarded array access in the hot primitive dispatch path, raw `cadddr` mutations bypassing defined port accessors, and no validation on manifest file loading. All were flagged in a code review.

## Goals / Non-Goals

**Goals:**
- Consolidate display/write into a single parameterized helper
- Make primitive dispatch errors descriptive (show the bad primitive ID)
- Use port accessors/mutators consistently — no raw `cadddr`
- Fail fast with a clear message if manifest files are missing or empty

**Non-Goals:**
- Changing display/write output format or behavior
- Restructuring the primitive dispatch architecture
- Converting port representation to `defstruct`
- Standardizing all error messages across the file (5.4 — cosmetic)

## Decisions

### 1. Shared display/write helper

Extract `ece-output-to-stream (obj stream print-fn)` that contains the shared cond tree:
- `#f`, `#t`, `()` → `write-string`
- procedure → `princ (format-ece-proc obj)`
- hash-table → `format-ece-hash-table` with `print-fn` for recursive values
- default → `(funcall print-fn obj stream)` under `*print-circle*`

The four existing functions become thin wrappers:
- `ece-display-to-stream` → calls helper with `#'princ`
- `ece-write-to-stream` → calls helper with `#'prin1`
- `ece-%display-to-port` → extracts stream from port, calls helper with `#'princ`, finish-output
- `ece-%write-to-port` → extracts stream from port, calls helper with `#'prin1`, finish-output

Note: the two stream functions currently lack the procedure and hash-table branches that the port functions have. The helper unifies this — all four paths now handle all types consistently. This is a minor behavior improvement (display-to-stream will now format procedures nicely instead of falling through to `princ`).

### 2. Primitive dispatch bounds check

Before `(aref *primitive-dispatch-table* id-or-name)`, add:
```lisp
(unless (and (integerp id-or-name)
             (<= 0 id-or-name)
             (< id-or-name (length *primitive-dispatch-table*)))
  (error "Invalid primitive ID: ~A" id-or-name))
```

This matches the pattern already used in `ece-%primitive-name`.

### 3. Port mutator functions

Add `set-ece-port-line!` and `set-ece-port-col!` alongside the existing read accessors, then use them in `ece-read-char`. Implementation:
```lisp
(defun set-ece-port-line! (port val) (setf (cadddr port) val))
(defun set-ece-port-col!  (port val) (setf (car (cddddr port)) val))
```

The raw `cadddr`/`cddddr` mutations in `ece-read-char` become:
```lisp
(set-ece-port-line! p (1+ (ece-port-line p)))
(set-ece-port-col! p 0)
```

### 4. Manifest load validation

Wrap `parse-primitives-manifest` and `parse-operations-manifest` calls with:
1. `(unless (probe-file path) (error "Manifest not found: ~A" path))`
2. After parsing: `(when (null entries) (error "No entries parsed from ~A" path))`

## Risks / Trade-offs

- **Risk**: The display/write helper unification adds procedure/hash-table handling to the stream functions that previously lacked it.
  → **Mitigation**: This is strictly better behavior — procedures printed via `ece-display-to-stream` will now show `#<procedure name>` instead of raw CL list representation. No existing code depends on the old broken output.

- **Risk**: Bounds check in primitive dispatch adds a branch to a hot path.
  → **Mitigation**: The branch is a single integer comparison. The existing `handler-case` around the dispatch already dominates any overhead.
