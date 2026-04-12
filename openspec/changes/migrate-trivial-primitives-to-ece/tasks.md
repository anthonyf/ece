## Scope narrowed during implementation

Tiers 1-3 were abandoned after discovering that the targeted primitives have
**platform-specific representations** — `compiled-procedure`, `continuation`,
`primitive`, and `port` are tagged lists on CL but WasmGC structs on WASM
(see `wasm/runtime.wat` lines 4852-5043). An ECE definition like
`(define (compiled-procedure-entry p) (cadr p))` works on CL but fails on
WASM with "car: not a pair". The CL/WASM mismatch means these primitives
must stay primitive until there's a portability story for field access.

Only tier 4 (`list`, `clear-screen`) is genuinely portable and was implemented.

## 1. Tier 4 — trivial standalone (only tier implemented)

- [x] 1.1 Add ECE definitions to `src/prelude.scm` for: `list`, `clear-screen`
- [x] 1.2 Run `make bootstrap` (Pass 1) and verify it succeeds
- [x] 1.3 Run `make test-rove` and verify zero failures
- [x] 1.4 Remove the corresponding `define-host-primitive` declarations from `src/primitives.scm`
- [x] 1.5 Mark the corresponding lines in `primitives.def` as `ece` platform — do NOT renumber other entries
- [x] 1.6 Run `make bootstrap` (Pass 2) and verify it succeeds
- [x] 1.7 Run all four test suites: `make test-rove`, `make test-ece`, `make test-conformance`, `make test-wasm` — verify zero failures
- [x] 1.8 Commit tier 4 with message listing the migrated primitives

## 2. Final validation and cleanup

- [x] 2.1 Verify `bootstrap/primitives-auto.lisp` has 2 fewer `defun` forms (`ece-list`, `ece-clear-screen` removed) — confirmed 171 vs 173
- [x] 2.2 Verify `bootstrap/*-zone.lisp` files regenerated — prelude-zone went from 43910 to 44106 PCs (+196 for the two ECE defs)
- [x] 2.3 Update the change's spec delta to reflect the narrowed scope
- [ ] 2.4 Open PR with tier 4 commit and a summary of why tiers 1-3 were abandoned
