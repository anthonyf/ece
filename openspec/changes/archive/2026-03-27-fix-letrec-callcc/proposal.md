## Why

The last R5RS conformance failure (pitfall 1.1) tests letrec + call/cc interaction. ECE's letrec expansion evaluates and assigns init values sequentially, so when a continuation captured during one initializer is invoked, earlier variables keep their mutated values. The R5RS-correct behavior requires all inits to be re-assigned when any init's continuation is resumed.

## What Changes

- Change letrec expansion in `prelude.scm` to evaluate all init values as lambda arguments, then assign variables inside the lambda body
- Add a helper function to build the set!/assignment pairs (since ECE's `map` only takes one list)
- Remove the skip for pitfall test 1.1

## Capabilities

### New Capabilities

_(none — bug fix only)_

### Modified Capabilities

_(none)_

## Impact

- **prelude.scm**: letrec macro rewrite + new helper function
- **bootstrap/prelude.ecec**: regenerated
- **tests/conformance/r5rs-pitfall.scm**: unskip test 1.1
