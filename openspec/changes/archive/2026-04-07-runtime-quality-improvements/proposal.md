## Why

A code review identified four substantive quality issues in runtime.lisp: duplicated display/write logic (4 near-identical cond trees), an unchecked array bounds access in primitive dispatch, raw `cadddr` usage bypassing defined port accessors, and no validation when loading manifest files. These make the runtime harder to maintain and debug.

## What Changes

- **Extract shared display/write helper**: Replace the four duplicated cond trees in `ece-display-to-stream`, `ece-write-to-stream`, `ece-%display-to-port`, `ece-%write-to-port` with a shared helper parameterized by the print function.
- **Bounds check in primitive dispatch**: Add a bounds check before `(aref *primitive-dispatch-table* id-or-name)` in `apply-primitive-procedure` so out-of-range primitive IDs produce a descriptive error instead of a cryptic CL array-index-out-of-bounds.
- **Fix raw port accessor bypass**: Replace direct `(cadddr p)` and `(car (cddddr p))` mutations in `ece-read-char` with proper port accessor/mutator functions.
- **Manifest load validation**: Add `probe-file` checks and descriptive errors when `primitives.def` or `operations.def` are missing or produce no entries.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `ports`: Add port mutator functions (`set-ece-port-line!`, `set-ece-port-col!`) and use them consistently
- `primitive-manifest`: Add validation on manifest load (file existence, non-empty entries)

## Impact

- **runtime.lisp**: Display/write refactor (~40 lines net reduction), primitive dispatch hardening, port accessor cleanup, manifest validation
- **No behavior changes** for correctly-functioning code — only error messages improve for edge cases
- **No test changes needed** — existing tests cover all modified code paths
