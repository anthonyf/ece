## Why

Named-let expands to `(begin (define (name ...) ...) (name args...))`. When this appears at the top of a lambda body, `mc-extract-define-names` hoists the define — the compiler reserves a frame slot and uses fast `lexical-ref`/`lexical-set!` for access. But when named-let appears nested inside another expression (e.g., as an argument to `string-append`), the define is NOT hoisted. It falls back to runtime `define-variable!` which calls `$frame-append` to grow the frame dynamically.

`$frame-append` has had three bugs (two fixed in PR #41, one still open) because the vals array and names list get out of sync. These bugs only manifest for unhoisted defines — hoisted defines never touch `frame-append`. The cleanest fix is to eliminate the unhoisted path entirely by changing the named-let macro to NOT use `define` when nested. Instead, it should expand to a self-calling lambda (letrec-style), which the compiler handles natively without `define-variable!`.

## What Changes

- Change the named-let macro expansion from `(begin (define (name ...) body) (name args...))` to a letrec-style `((lambda (name) (set! name (lambda (vars...) body)) (name args...)) #f)` pattern, or equivalently use the existing `letrec` macro
- This eliminates ALL runtime `define-variable!` calls from named-let, regardless of nesting depth
- No changes to the compiler's `mc-extract-define-names` — it continues to hoist top-level defines in lambda bodies as before
- Regenerate bootstrap `.ecec` files

## Capabilities

### New Capabilities

_None_ — this is a macro-level fix, no new capabilities.

### Modified Capabilities

- `named-let`: Expansion strategy changes from `define` to letrec-style self-application

## Impact

- `src/prelude.scm` — named-let macro definition (~5 lines)
- `bootstrap/*.ecec` — regenerated from updated prelude
- All existing code using named-let continues to work with identical semantics
- `$frame-append` becomes unreachable from named-let patterns (still used for other unhoisted defines)
