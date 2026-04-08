## Why

Library and test code uses `(quote ...)` where `'` shorthand is idiomatic. These files serve as reference code for users, so they should model standard Scheme style. Issue #106.

## What Changes

- **Replace verbose `(quote ...)` with `'` shorthand** in `src/prelude.scm` (8 instances) and `tests/ece/common/test-roundtrip.scm` (2 instances)
- **Keep explicit `(quote ...)`** where it aids readability: quasiquote templates, dynamic code construction via `(list 'quote ...)`, and syntax-rules templates

## Capabilities

### New Capabilities

_None._ This is a code style cleanup with no behavioral changes.

### Modified Capabilities

_None._ No requirement-level changes.

## Impact

- **src/prelude.scm**: 8 lines changed — `(quote ())` → `'()` in map/reverse/filter/for-each/iota/set-difference; `(quote else)` → `'else` in cond/case macros
- **tests/ece/common/test-roundtrip.scm**: 1 line changed — `(quote (x y))` → `'(x y)` and `(quote ())` → `'()`
- **No behavioral changes** — all functions produce identical results
- **No API or dependency changes**
