## Why

runtime.lisp has ~15 sites that perform raw structure checks (`(eq (car obj) '|compiled-procedure|)`) and raw slot access (`(cadr proc)`) on tagged list values instead of using the defined predicates (`compiled-procedure-p`) and accessors (`compiled-procedure-entry`). This makes the code fragile — if the internal representation changes, every raw access site must be found and updated. Issue #107 flagged this during a code review.

Additionally, the ECE-facing predicates (`ece-compiled-procedure?`, `ece-primitive?`, `ece-continuation?`) duplicate the same tag-check logic as the CL-facing predicates instead of delegating to them.

## What Changes

- **Replace all raw predicate checks** with calls to `compiled-procedure-p`, `primitive-procedure-p`, `continuation-p`, and `parameter-p` throughout runtime.lisp
- **Replace all raw slot access** with calls to existing accessors (`compiled-procedure-entry`, `compiled-procedure-env`, `continuation-stack`, etc.)
- **Add missing CL-internal accessors**: `primitive-procedure-id` (wraps `(cadr prim)`), `parameter-cell` (wraps `(cadr param)`), and `procedure-name` (wraps `*procedure-name-table*` lookup)
- **Consolidate duplicate predicates**: Make `ece-compiled-procedure?`, `ece-primitive?`, `ece-continuation?` delegate to the CL-facing `-p` predicates instead of re-implementing the tag check

## Capabilities

### New Capabilities

_None._ This is an internal code quality refactoring — no new user-facing capabilities.

### Modified Capabilities

_None._ No spec-level behavior changes. All modifications are to internal CL implementation code; the ECE-visible API is unchanged.

## Impact

- **runtime.lisp**: ~15 call sites updated to use predicates/accessors, ~5 new accessor functions added, 3 ECE predicate functions simplified
- **No behavior changes** — strictly a refactoring for maintainability
- **No test changes needed** — existing tests cover all affected code paths
