## Why

The conformance test files define local shims for four standard R5RS functions (`memq`, `assq`, `list?`, `procedure?`) because ECE doesn't provide them. These are core Scheme functions that belong in the language, not test-local workarounds. The `procedure?` shim is particularly fragile — it extracts type tags from live objects rather than using proper predicates. Issue #108 flagged this.

## What Changes

- **Add `memq`** to the prelude — like `member` but uses `eq?` for comparison
- **Add `assq`** to the prelude — like `assoc` but uses `eq?` for comparison
- **Add `list?`** to the prelude — proper list predicate (recursive null/pair check)
- **Add `procedure?`** as a CL primitive — returns `#t` for compiled procedures, primitives, and continuations
- **Remove shim definitions** from `tests/conformance/chibi-r5rs.scm` and `tests/conformance/r5rs-pitfall.scm`

## Capabilities

### New Capabilities

_None._ These are additions to existing capability areas (list search, predicates).

### Modified Capabilities

- `list-search`: Add `memq` and `assq` requirements (eq?-based variants of `member` and `assoc`)
- `predicates-and-equality`: Add `list?` and `procedure?` requirements

## Impact

- **src/prelude.scm**: Add `memq`, `assq`, `list?` definitions
- **src/runtime.lisp**: Add `ece-procedure?` primitive (checks all three callable tags)
- **src/boot-env.scm**: Register `procedure?` primitive
- **tests/conformance/chibi-r5rs.scm**: Remove shim definitions
- **tests/conformance/r5rs-pitfall.scm**: Remove `procedure?` shim
- **No breaking changes** — these are pure additions
