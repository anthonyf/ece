## Scope narrowed during implementation

The original four-tier proposal was reduced twice:

1. **Tiers 1-3 abandoned** after discovering the targeted primitives have
   **platform-specific representations** — `compiled-procedure`, `continuation`,
   `primitive`, and `port` are tagged lists on CL but WasmGC structs on WASM
   (see `wasm/runtime.wat` lines 4852-5043). An ECE definition like
   `(define (compiled-procedure-entry p) (cadr p))` works on CL but fails on
   WASM with "car: not a pair". These primitives must stay primitive until
   there's a portability story for field access.

2. **`clear-screen` reverted from tier 4** after PR feedback clarified that
   terminal-control functions belong in a platform library, not the kernel.
   The CL implementation writes ANSI escapes; the WASM answer is a future
   canvas/DOM/raylib operation dispatched through FFI. Unifying them under a
   single ECE definition would drag CL-centric behavior into the browser.

Only `list` was actually migrated.

## 1. Migration (list only)

- [x] 1.1 Add `(define (list . args) args)` to `src/prelude.scm`
- [x] 1.2 Run `make bootstrap` (Pass 1) and verify it succeeds
- [x] 1.3 Run `make test-rove` and verify zero failures
- [x] 1.4 Remove the `define-host-primitive (list . args)` declaration from `src/primitives.scm`
- [x] 1.5 Change `primitives.def` ID 8 (`list`) from `core` to `ece` — ID not renumbered
- [x] 1.6 Run `make bootstrap` (Pass 2) and verify it succeeds
- [x] 1.7 Run all four test suites: `make test-rove`, `make test-ece`, `make test-conformance`, `make test-wasm` — verify zero failures
- [x] 1.8 Commit with a message naming the migrated primitive

## 2. Final validation and cleanup

- [x] 2.1 Verify `bootstrap/primitives-auto.lisp` has 1 fewer `defun` form (`ece-list` removed)
- [x] 2.2 Verify `bootstrap/*-zone.lisp` files regenerated to match the new prelude
- [x] 2.3 Update the change's spec delta to reflect the narrowed scope
- [x] 2.4 Open PR with the tier-4 commit and a summary of why earlier tiers were abandoned — https://github.com/anthonyf/ece/pull/144
