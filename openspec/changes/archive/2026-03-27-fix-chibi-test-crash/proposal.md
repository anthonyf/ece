## Why

The Chibi R5RS conformance tests crash at compile time when a `syntax-rules` macro expansion contains internal defines — e.g., `(test -2 (let () (define x 2) ...))`. The compiler's `mc-extract-define-names` encounters the bare symbol `define` where it expects a list form, calling `cdr` on a symbol. This blocks enabling the 97 adapted Chibi R5RS tests.

## What Changes

- Fix `mc-extract-define-names` in `compiler.scm` to handle the code path where macro-expanded forms contain nested `define` forms
- Enable the Chibi R5RS tests in `run-conformance.scm` (currently commented out)
- No new features — purely a compiler bug fix

## Capabilities

### New Capabilities

_(none — bug fix only)_

### Modified Capabilities

_(none — no spec-level behavior change)_

## Impact

- **compiler.scm**: Fix in `mc-extract-define-names` (line ~196)
- **tests/conformance/run-conformance.scm**: Uncomment Chibi test loading
- **Risk**: Minimal — the fix adds guards to an existing function, no architectural change
