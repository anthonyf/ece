## Why

ECE needs `syntax-rules` and `define-syntax` to conform to R5RS/R7RS and to enable integration of published Scheme conformance test suites (primarily the Chibi R7RS tests). Many standard Scheme libraries and test suites rely on `syntax-rules` for hygienic macros. Without it, ECE cannot run these tests or claim R7RS-small conformance.

## What Changes

- Add `syntax-rules` as a hygienic pattern-matching macro transformer, implemented as a `define-macro` expansion with gensym-based hygiene
- Add `define-syntax` as a binding form that registers a `syntax-rules` transformer (sugar over `define-macro`)
- Both forms implemented in ECE itself (a `.scm` file compiled to `.ecec`), not in the CL kernel
- `define-macro` remains available as the low-level escape hatch — both systems coexist

## Capabilities

### New Capabilities
- `syntax-rules`: R7RS-compliant hygienic pattern-matching macro transformer with ellipsis support, literal matching, and automatic hygiene via gensym
- `define-syntax`: Binding form for registering syntax-rules transformers in the macro table

### Modified Capabilities
- `define-macro`: No spec-level changes, but implementation must ensure `define-syntax` transformers are stored in the same macro table so the compiler's existing `get-macro`/`set-macro!` dispatch handles both

## Impact

- **Source files**: New `src/syntax-rules.scm` compiled to `bootstrap/syntax-rules.ecec`
- **Boot sequence**: Must load after `prelude.ecec` (needs `gensym`, list operations) and before any user code that uses `syntax-rules`
- **Compiler**: No changes needed — `define-syntax` expands to `define-macro` at the surface, so the compiler's existing macro infrastructure handles it
- **Existing macros**: No impact — all current `define-macro` usage continues to work
- **Tests**: New test file `tests/ece/test-syntax-rules.scm`
