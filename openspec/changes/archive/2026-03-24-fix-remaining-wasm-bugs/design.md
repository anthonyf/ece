## Bug 2 Fix: String quoting in write-to-string

In `$write-to-string-impl`, the string fast-path (line 2740) returns the string object directly. Fix: build a new string with `"` prefix, escaped contents, and `"` suffix.

Escaping rules (standard Scheme `write`):
- `\` → `\\`
- `"` → `\"`
- Other characters pass through

Implementation: new helper `$wts-string` that allocates a result string, copies characters with escaping, wraps in quotes. Called from the string branch of `$write-to-string-impl`.

## Bug 3 Fix: Vector equal?

In `$prim-equal`, add a vector case after the pair case:
1. Check both values are vectors (`$is-vector`)
2. Check lengths match
3. Recursively compare each element with `$prim-equal`
4. Return `#t` if all match, `#f` otherwise

## Bug 1 Investigation: Late top-level define crash

This needs investigation before a fix can be designed. The crash occurs when `define-variable!` is called on the global env after hundreds of compilation units have already been executed. The global env frame has grown via repeated `frame-append` calls.

Hypothesis: after many `frame-append` calls, the names-count and vals-length diverge. The `frame-append` fix (PR #41) uses `target-idx = names-count` and reuses existing slots when `target-idx < old-len`. But for the global env (which starts with 0 slots and grows entirely via `frame-append`), names-count should always equal vals-length since there are no extra-slots. Something else is going wrong.

Approach: add a diagnostic that logs names-count vs vals-length at each `frame-append` call to find the divergence point. Then fix the root cause.

## Key Decisions

- Bugs 2 and 3 are straightforward fixes, implement first
- Bug 1 requires investigation — may be deferred if complex
- Tests should be updated to cover the fixed cases
