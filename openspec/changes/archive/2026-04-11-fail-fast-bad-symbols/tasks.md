## 1. WAT lookup: emit unbound-variable error sentinel

- [x] 1.1 Audit all callers of `$lookup-variable-value` (grep `wasm/runtime.wat`) to confirm none of them rely on null as a legitimate "absent" signal — record any that do, and decide per-caller whether to use a new `$try-lookup-variable-value` helper or migrate to the sentinel.
- [x] 1.2 Add a static `$err-unbound-prefix` string (`"Unbound variable: "`) next to `$err-unbound-var` in the `(global ...)` section — or reuse `$err-unbound-var` if its content already matches the required format.
- [x] 1.3 Modify `$lookup-variable-value` (`wasm/runtime.wat:1075`) so the `$not-found` exit constructs a fresh `$error-sentinel` with message `(string-append "Unbound variable: " (symbol->string name))` and empty irritants, and returns it instead of `(ref.null eq)`. Use existing string-concat / symbol-to-string helpers.
- [x] 1.4 If the caller audit in 1.1 was clean, tighten the return type from `(ref null eq)` to `(ref eq)` and fix any resulting wasm-as errors.
- [x] 1.5 Confirm `$lookup-global-variable` (op 1 dispatch around `wasm/runtime.wat:2451`) routes through the same error path — either via the modified `$lookup-variable-value` (if it calls it) or by duplicating the sentinel construction.
- [x] 1.6 Rebuild: `make wasm`. Confirm the assembler succeeds and `wasm/runtime.wasm` updates.

## 2. WAT error bridge: verify sentinel propagation

- [x] 2.1 Read `wasm/runtime.wat:2146` (assign-from-op error-sentinel bridge) and confirm an error sentinel returned from `$dispatch-op` on op 0 (`lookup-variable-value`) reaches ECE's `error` function with source location (`$error-space-id`, `$error-pc`) set.
- [x] 2.2 Confirm op 1 (`lookup-global-variable`) takes the same bridge path.
- [x] 2.3 Verify early-boot fallback: when `$error-sym` is null (pre-boot lookups), the existing fall-through to `$signal-error-str` handles the sentinel correctly.

## 3. CL runtime: align unbound-variable message format

- [x] 3.1 Locate the CL-side `lookup-variable-value` in `src/runtime.lisp` and its error path.
- [x] 3.2 Confirm it emits exactly `"Unbound variable: <name>"` (no trailing punctuation, no prefix difference). If it drifts, align the CL side to the WAT format.

## 4. ECE reader: reject stray backslash in symbols

- [x] 4.1 Modify `read-symbol` in `src/reader.scm` (`src/reader.scm:68`) to error when the initial character is `#\\` OR when a `#\\` is seen inside the loop body.
- [x] 4.2 Use `(error "invalid character in symbol: \\" ...)` with irritants including the partial symbol buffer and, when `*source-file-name*` is set, a `(file line col)` triple derived from `port-line`/`port-col`.
- [x] 4.3 Confirm character literals (`#\X`) and string escapes (`"\n"`) use their own reader paths (`read-character` and `read-string-with-interpolation` respectively) and are unaffected.
- [x] 4.4 Run `grep -P '[^"\\\\]\\\\[^"nt\\\\]' src/*.scm` (or equivalent) to confirm no existing legitimate ECE source file contains a bare-symbol backslash that would now trigger the error.
- [x] 4.5 Bootstrap: `make bootstrap` (two-pass). The first pass boots from the existing `bootstrap/bootstrap.ecec` and recompiles; the reader change must not break bootstrap.

## 5. Tests

- [x] 5.1 Add a WASM integration test (in `wasm/test.js`): `(guard (e ((error-object? e) (error-object-message e))) undefined-xyz)` → asserts result equals `"Unbound variable: undefined-xyz"`. *(Landed in `tests/ece/common/test-error-messages.scm`, which runs on both WASM and CL. Host-level spot check added in `wasm/test.js` via `test_lookup_returns_sentinel`.)*
- [x] 5.2 Add a WASM regression test that the "illegal cast" crash from the original bug report no longer occurs: compile a bundle that references an unbound variable at top level, load it, and assert the error is catchable (`try-eval` surfaces it as the EOF sentinel, not an uncaught WASM trap). *(Covered by the `"unbound procedure call is catchable (no illegal-cast trap)"` scenario in `tests/ece/common/test-error-messages.scm`.)*
- [x] 5.3 Add an ECE-side test in `tests/ece/common/` that reads `"foo\\!"` via the ECE reader and asserts an error is signaled whose message mentions `"invalid character in symbol"`.
- [x] 5.4 Add a cross-runtime conformance test (in the conformance suite) that the WASM and CL runtimes produce identical `"Unbound variable: <name>"` strings for the same program. *(Satisfied by `test-error-messages.scm` running with `assert-equal` against the same expected string on both runtimes.)*
- [x] 5.5 Run `make test-wasm` — all tests pass.
- [x] 5.6 Run `make test-rove test-ece test-conformance` — all suites pass.

## 6. Documentation and cleanup

- [x] 6.1 Update `openspec/specs/wasm-runtime-errors/spec.md` with the modified requirement (automatic via `/opsx:archive`).
- [x] 6.2 Update `openspec/specs/ece-reader/spec.md` with the new backslash-rejection requirement (automatic via `/opsx:archive`).
- [x] 6.3 Remove the `project_bang_escape_heredoc_pitfall.md` memory, or update it to note that reader and lookup now surface the issue clearly.
- [x] 6.4 Verify `make test` passes end-to-end before opening a PR.
