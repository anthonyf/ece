## Why

The last 5 conformance test skips all require `let-syntax` / `letrec-syntax`. These are R5RS scoped macro binding forms — like `let` but for macros instead of values. Implementing them completes R5RS pitfall conformance (157/0/0 target).

## What Changes

- Add `let-syntax` and `letrec-syntax` as macros in `src/syntax-rules.scm`
- Unskip pitfall tests 3.1–3.4 and 8.3
- No compiler changes — implemented using the existing `define-macro` / `set-macro!` / `get-macro` infrastructure

## Capabilities

### New Capabilities
_(none — standard R5RS forms)_

### Modified Capabilities
_(none)_

## Impact
- **src/syntax-rules.scm**: new macros
- **bootstrap/syntax-rules.ecec**: regenerated
- **tests/conformance/r5rs-pitfall.scm**: unskip 5 tests
