## Context

ECE already has all the building blocks: `ece-read` reads s-expressions with the ECE readtable, `evaluate` evaluates any expression, and `*eof-sentinel*` detects end of input. `load` just wires these together with file I/O.

## Goals / Non-Goals

**Goals:**
- Load and evaluate all expressions from an ECE source file
- Fail-fast on errors (propagate CL conditions)
- Return the value of the last expression evaluated

**Non-Goals:**
- Port objects or stream primitives (future work)
- Relative path resolution or search paths
- `include` (compile-time inclusion)

## Decisions

### Implementation as CL wrapper
`ece-load` is a CL function that:
1. Opens the file with `with-open-file`
2. Binds `*readtable*` to `*ece-readtable*` and `*read-eval*` to `nil`
3. Loops: `read` → `evaluate` → repeat until EOF
4. Returns the last evaluated value

This is ~10 lines. No new ECE-level abstractions needed.

### Error handling
Errors propagate naturally — if any expression signals a CL error, `with-open-file` ensures the stream is closed and the error reaches the caller. This matches Scheme's `load` behavior. Users can wrap `(load "file.scm")` in `try-eval` if they want error recovery.

### Return value
Returns the value of the last expression, or nil for empty files. This is useful for files that define a value or function as their last form.

## Risks / Trade-offs

- **No path resolution**: `load` takes a literal filename string. Relative paths are relative to CL's `*default-pathname-defaults*`, which is typically the process working directory. Good enough for now.
