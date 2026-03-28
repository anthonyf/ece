## 1. Implement

- [x] 1.1 Add `let-syntax`/`letrec-syntax` as compiler special form in `src/compiler.scm` — saves/restores macro table around body compilation. Handles both forms identically.
- [x] 1.2 (merged with 1.1 — single handler via `mc-let-syntax?` predicate)
- [x] 1.3 Run `make bootstrap` to regenerate .ecec files.

## 2. Enable tests

- [x] 2.1 Unskip pitfall tests 3.2–3.4 and 8.3. Keep 3.1 skipped (requires full referential hygiene).
- [x] 2.2 Run `make test-conformance`: 156 passed, 0 failed, 1 skipped.
- [x] 2.3 Verify existing ECE tests still pass (0 failures).
