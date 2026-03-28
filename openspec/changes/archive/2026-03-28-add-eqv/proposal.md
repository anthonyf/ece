## Why

`eqv?` is a core R5RS primitive missing from ECE. Two conformance tests are skipped and several Chibi tests are commented out because of it. It's a trivial addition — CL's `eql` is the exact equivalent.

## What Changes

- Add `eqv?` primitive in runtime.lisp (map to CL's `eql`)
- Unskip pitfall tests 4.3 and 5.2
- Uncomment Chibi R5RS `eqv?` tests

## Capabilities

### New Capabilities
_(none — standard primitive)_

### Modified Capabilities
_(none)_

## Impact
- **runtime.lisp**: one new primitive binding
- **tests/conformance/**: unskip and uncomment tests
