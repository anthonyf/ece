## Why

Five conformance tests in `chibi-r5rs.scm` were commented out because `equal?` didn't support deep vector comparison. That limitation was fixed when `equal?` gained vector support in `prelude.scm`, but the tests were never uncommented. Additionally, the `conformance-skip!` mechanism exists in the framework but is unused dead code.

## What Changes

- Uncomment all 5 vector-related tests in `tests/conformance/chibi-r5rs.scm` (lines 122, 170, 260-261, 277)
- Fix any tests that need adjustment (e.g., the line 260 test references a complex expression that was truncated)
- Remove unused `conformance-skip!` / `conformance-skipped?` / `*conformance-skip-list*` dead code from `conformance-framework.scm`
- Update the conformance test count baseline in `tests/test-counts.json`

## Capabilities

### New Capabilities

- `conformance-vector-coverage`: Restore vector-related R5RS conformance tests that were disabled due to a now-fixed `equal?` limitation

### Modified Capabilities

## Impact

- `tests/conformance/chibi-r5rs.scm` — 5 tests uncommented/restored
- `tests/conformance/conformance-framework.scm` — dead skip mechanism removed
- `tests/test-counts.json` — conformance baseline bumped (~157 to ~162)
