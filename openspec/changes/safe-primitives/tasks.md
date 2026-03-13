## Approach: CL-level error bridging (replaces ECE-level wrappers)

The original approach wrapped primitives with ECE-level type-checking functions,
causing ~35x performance regression. Replaced with CL-level error catching in
`apply-primitive-procedure` via sentinel struct — negligible overhead (~5ns/call).

## 1. Revert Primitives and Add CL-level Error Bridging

- [x] 1.1 Revert `*primitive-procedures*` to standard names (remove `%raw-` prefixes, keep `%raw-error`)
- [x] 1.2 Add `ece-error-sentinel` struct to runtime.lisp
- [x] 1.3 Add `handler-case` in `apply-primitive-procedure` catching `type-error` and `division-by-zero`
- [x] 1.4 Add sentinel check in executor `assign/op-fn` — calls ECE's `error` function to create proper error-objects

## 2. Clean Up Prelude

- [x] 2.1 Remove `%raw-` aliases from top of prelude.scm (lines 4-31)
- [x] 2.2 Remove safe wrappers from bottom of prelude.scm (lines 945-1062)

## 3. Rebuild and Test

- [x] 3.1 Cold boot succeeds
- [x] 3.2 Save new bootstrap image
- [x] 3.3 Update test-error-messages.scm (use error-object? checks instead of exact message matching)
- [x] 3.4 All rove tests pass
- [x] 3.5 ECE native test suite: 393 passed, 0 failed
