## Why

The R5RS conformance suite has 5 failures. Three have clear fixes, one needs investigation, and one (letrec+call/cc) is deferred. Fixing these moves ECE closer to R5RS conformance and validates that the compiler handles lexical scoping correctly for special forms.

## What Changes

- Fix named let expansion in `prelude.scm` — init values must be evaluated outside the letrec scope so the loop name doesn't shadow outer bindings
- Fix special form dispatch in `compiler.scm` — check lexical scope before dispatching `begin`, `set!`, `define`, etc., so lambda parameters can shadow special forms per R5RS
- Fix `procedure?` shim in conformance tests — add continuation recognition
- Investigate and fix `(symbol? 'nil)` failure in Chibi tests

## Capabilities

### New Capabilities

_(none — bug fixes only)_

### Modified Capabilities

_(none)_

## Impact

- **prelude.scm**: Named let expansion change
- **compiler.scm**: Special form dispatch order in `mc-compile`
- **tests/conformance/chibi-r5rs.scm**: `procedure?` shim update
- **bootstrap/**: Regenerate after prelude + compiler changes
