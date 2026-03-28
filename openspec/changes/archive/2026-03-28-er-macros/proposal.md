## Why

The last conformance test skip (3.1) requires full referential hygiene — free variables in macro templates must refer to bindings at the definition site, not the use site. This also makes `syntax-rules` correct for any code that shadows standard identifiers inside a macro use site, which is required by R5RS.

## What Changes

- Add `er-macro-transformer` as a new macro primitive alongside `define-macro`
- Add `%global-ref` compiler special form — resolves a variable against the global env, bypassing lexical scope
- Reimplement `syntax-rules` template instantiation to wrap free variables in `%global-ref`, ensuring they resolve to their definition-site bindings
- Unskip pitfall test 3.1

## Capabilities

### New Capabilities
_(none — internal mechanism for correct hygiene)_

### Modified Capabilities
_(none)_

## Impact

- **compiler.scm**: New `%global-ref` special form (5 lines), add to special forms list
- **syntax-rules.scm**: Change `syntax-instantiate` to wrap non-pattern-variable symbols in `(%global-ref sym)` instead of leaving them bare
- **tests/conformance/r5rs-pitfall.scm**: Unskip test 3.1
- **bootstrap/**: Regenerate (double bootstrap for compiler change)
