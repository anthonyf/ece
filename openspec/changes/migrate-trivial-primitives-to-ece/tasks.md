## 1. Tier 1 — pure list accessors

- [ ] 1.1 Add ECE definitions to `src/prelude.scm` for: `compiled-procedure-entry`, `compiled-procedure-env`, `continuation-stack`, `continuation-conts`, `continuation-winds`, `%primitive-id-of`, `%global-env-frame`, `port-line`, `port-col`
- [ ] 1.2 Run `make bootstrap` (Pass 1) and verify it succeeds
- [ ] 1.3 Run `make test-rove` and verify zero failures
- [ ] 1.4 Remove the corresponding `define-host-primitive` declarations from `src/primitives.scm`
- [ ] 1.5 Remove (or comment) the corresponding lines in `primitives.def` — do NOT renumber other entries
- [ ] 1.6 Run `make bootstrap` (Pass 2) and verify it succeeds
- [ ] 1.7 Run all four test suites: `make test-rove`, `make test-ece`, `make test-conformance`, `make test-wasm` — verify zero failures
- [ ] 1.8 Commit tier 1 with message listing the migrated primitives

## 2. Tier 2 — pure list constructors

- [ ] 2.1 Add ECE definitions to `src/prelude.scm` for: `%make-compiled-procedure`, `%make-continuation`, `%make-primitive`, `make-parameter`
- [ ] 2.2 Run `make bootstrap` (Pass 1) and verify it succeeds
- [ ] 2.3 Run `make test-rove` and verify zero failures
- [ ] 2.4 Remove the corresponding `define-host-primitive` declarations from `src/primitives.scm`
- [ ] 2.5 Remove (or comment) the corresponding lines in `primitives.def` — do NOT renumber other entries
- [ ] 2.6 Run `make bootstrap` (Pass 2) and verify it succeeds
- [ ] 2.7 Run all four test suites and verify zero failures
- [ ] 2.8 Commit tier 2 with message listing the migrated primitives

## 3. Tier 3 — structural and tagged-list predicates

- [ ] 3.1 Add ECE definitions to `src/prelude.scm` for: `input-port?`, `output-port?`, `port?`, `parameter?`, `keyword?`, `null?`, `compiled-procedure?`, `continuation?`, `primitive?`, `procedure?`, `%env-frame?`
- [ ] 3.2 Run `make bootstrap` (Pass 1) and verify it succeeds
- [ ] 3.3 Run `make test-rove` and verify zero failures
- [ ] 3.4 Remove the corresponding `define-host-primitive` declarations from `src/primitives.scm`
- [ ] 3.5 Remove (or comment) the corresponding lines in `primitives.def` — do NOT renumber other entries
- [ ] 3.6 Run `make bootstrap` (Pass 2) and verify it succeeds
- [ ] 3.7 Run all four test suites and verify zero failures
- [ ] 3.8 Commit tier 3 with message listing the migrated primitives

## 4. Tier 4 — trivial standalone

- [ ] 4.1 Add ECE definitions to `src/prelude.scm` for: `list`, `clear-screen`
- [ ] 4.2 Run `make bootstrap` (Pass 1) and verify it succeeds
- [ ] 4.3 Run `make test-rove` and verify zero failures
- [ ] 4.4 Remove the corresponding `define-host-primitive` declarations from `src/primitives.scm`
- [ ] 4.5 Remove (or comment) the corresponding lines in `primitives.def` — do NOT renumber other entries
- [ ] 4.6 Run `make bootstrap` (Pass 2) and verify it succeeds
- [ ] 4.7 Run all four test suites and verify zero failures
- [ ] 4.8 Commit tier 4 with message listing the migrated primitives

## 5. Final validation and cleanup

- [ ] 5.1 Verify the regenerated `bootstrap/primitives-auto.lisp` has ~26 fewer `defun` forms than before the migration
- [ ] 5.2 Verify all `bootstrap/*-zone.lisp` files have been regenerated to reflect the new call sites
- [ ] 5.3 Run a deterministic regeneration check: `generate-all-zones!` twice produces byte-identical output
- [ ] 5.4 Update MEMORY.md to reflect the kernel size reduction (note in "Kernel Minimization" section)
- [ ] 5.5 Open PR with all four tier commits and a summary of the kernel size reduction
