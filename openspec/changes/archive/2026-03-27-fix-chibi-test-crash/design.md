## Context

`(let () 42)` crashes with "car: The value 42 is not of type LIST". The root cause: in CL, `nil` is both a symbol and the empty list. ECE's `(symbol? '())` returns `#t`. The `let` macro (prelude.scm:174) checks `(symbol? bindings)` to distinguish named let from regular let. When bindings is `()`, it incorrectly takes the named let branch, which then tries `(map car (car body))` where `(car body)` is the first body expression (e.g., `42`), crashing.

This blocks loading the Chibi R5RS conformance tests, which contain `(let () (define x 2) ...)`.

## Goals / Non-Goals

**Goals:**
- Fix `(let () body)` to work correctly
- Enable the Chibi R5RS conformance tests

**Non-Goals:**
- Fixing `symbol?` itself — CL's `nil` being a symbol is a platform fact, and changing `symbol?` could break other things

## Decisions

### Fix the let macro guard, not symbol?

Add a `(not (null? bindings))` check to the named let branch:

```scheme
(if (and (symbol? bindings) (not (null? bindings)))
    ;; Named let
    ...
    ;; Regular let
    ...)
```

**Alternative considered:** Change `symbol?` to return `#f` for `nil`. Rejected because `nil` genuinely IS a symbol in CL, and other code might depend on this behavior.

### Regenerate bootstrap after the fix

Since `prelude.scm` changes, `make bootstrap` must be run to regenerate `bootstrap/prelude.ecec`.

## Risks / Trade-offs

**[Minimal risk]** — Single guard added to a well-understood macro. The fix is conservative: it only changes behavior for the `()` case which was already broken.
