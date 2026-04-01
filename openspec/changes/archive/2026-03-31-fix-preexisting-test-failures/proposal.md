## Why

Several pre-existing test failures prevent `make test-ece` from completing and silently skip test assertions. The serialization tests OOM the process, `with-output-to-file`/`with-input-from-file` crash on compiled thunks, and `test-roundtrip.scm` isn't included in the CL test suite. Fixing these brings the test suite to full green and eliminates silent skips.

## What Changes

- **Fix `with-output-to-file` and `with-input-from-file`**: These CL functions call `apply-primitive-procedure` on the thunk argument, but thunks from ECE are compiled procedures. Replace with `apply-ece-procedure` (which handles both primitives and compiled procedures), matching the pattern already used by `call-with-input-file` and `call-with-output-file` on line 945-955.
- **Fix `make test-ece` OOM**: The `run-tests` function uses `try-eval` which nests `mc-compile-and-go` → `execute-instructions` calls. When serialization tests run inside this nested context, compiled procedure environment chains are pathologically deep, and `serialize-value` builds O(n²) intermediate strings via recursive `string-append`. Fix by either switching to port-based serialization or limiting env chain traversal depth.
- **Add `test-roundtrip.scm` to CL test suite**: Currently only runs in WASM tests. Add to `run-common.scm` so CL also validates roundtrip behavior.

## Capabilities

### New Capabilities

_None_

### Modified Capabilities

- `value-serialization`: Fix O(n²) string-append memory usage in serialize-value for compiled procedure environments
- `ports`: Fix `with-output-to-file` and `with-input-from-file` to handle compiled procedure thunks

## Impact

- `src/runtime.lisp`: Fix `ece-with-input-from-file` and `ece-with-output-to-file` to use `apply-ece-procedure`
- `src/prelude.scm` or `src/runtime.lisp`: Fix `serialize-value` memory usage (depending on where serialization lives)
- `tests/ece/run-common.scm`: Add `test-roundtrip.scm` to the load list
- `make test-ece` target becomes usable again (currently always OOMs)
