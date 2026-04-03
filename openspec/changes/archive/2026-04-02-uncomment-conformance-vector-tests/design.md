## Context

Five tests in `tests/conformance/chibi-r5rs.scm` were commented out when the conformance suite was first adapted, because ECE's `equal?` didn't support deep vector comparison. Since then, `equal?` gained vector support in `src/prelude.scm:515-520`. All five tests have been verified to pass against the current ECE on CL. The `conformance-skip!` mechanism in the framework was never adopted.

## Goals / Non-Goals

**Goals:**
- Restore all 5 commented-out vector tests to active conformance coverage
- Remove dead `conformance-skip!` code from the framework
- Update conformance test count baseline

**Non-Goals:**
- Adding new conformance tests beyond the 5 that were commented out
- Changing the conformance framework beyond removing dead code
- Fixing any other conformance gaps

## Decisions

**Uncomment rather than rewrite.** Four of the five tests are complete expressions that can simply be uncommented. Line 260 (`#(0 ("Sue" "Sue") "Anna")`) was truncated with `...` — this needs the full R5RS example reconstructed:
```scheme
(test '#(0 ("Sue" "Sue") "Anna")
  (let ((vec (vector 0 '(2 2 2 2) "Anna")))
    (vector-set! vec 1 '("Sue" "Sue"))
    vec))
```

**Remove skip comments.** The `; skipped: equal? doesn't deeply compare vectors in ECE` comments should be removed since the reason no longer applies.

**Remove dead skip mechanism.** `conformance-skip!`, `conformance-skipped?`, `*conformance-skip-list*`, and `*conformance-skips*` are unused. The `conformance-test` macro references `conformance-skipped?` so it needs a small update to remove the skip branch. The `conformance-summary` display of skips should also be removed.

## Risks / Trade-offs

**Risk**: The reconstructed line 260 test uses `vector` constructor — need to verify it exists in ECE.
**Mitigation**: Test locally before committing. If `vector` isn't available, use `make-vector` + `vector-set!`.

**Risk**: WASM conformance tests also run these — vector `equal?` must work on WASM too.
**Mitigation**: The `equal?` implementation lives in `prelude.scm` which is compiled to `.ecec` and runs on both platforms. Verify with `make test-wasm`.
