## Why

A reported "primitive 212 illegal cast" bug in dunge-cl turned out to be a corrupt `js-set\!` symbol in source (stray backslash inserted by zsh heredoc expansion). Two independent weaknesses made this miserable to debug: (1) the WAT `$lookup-variable-value` silently returns null on miss, so the failure surfaced as a `ref.cast` deep inside `compiled-procedure-entry` with no mention of the variable name or source location; (2) the ECE reader happily accepts backslash inside bare symbols, so the corruption was only caught at lookup time rather than at read time. Both are cheap to fix and turn an opaque runtime crash into two self-diagnosing errors.

## What Changes

- WAT `$lookup-variable-value` in `wasm/runtime.wat` SHALL signal an `"Unbound variable: <name>"` error sentinel on miss instead of returning `ref.null eq`. The existing error-sentinel bridge in the assign-from-op dispatch (around line 2146) already routes sentinels through ECE's `error` function, so no new plumbing.
- CL runtime `lookup-variable-value` SHALL use the same `"Unbound variable: <name>"` message format so both platforms agree (verify and align if needed).
- ECE reader `read-symbol` in `src/reader.scm` SHALL reject backslash (`\`) inside bare symbol tokens, signaling a read-time error with source location. Other R7RS-reserved characters (`|`, `#` mid-symbol) are out of scope for this change.
- Keep the WAT lookup happy-path branch-free — the error path is a cold branch that only executes on miss.
- Add WASM and ECE regression tests covering both fixes.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `wasm-runtime-errors`: strengthen the existing "Undefined variable lookup signals an error" requirement with scenarios that pin the error message format and confirm the sentinel propagates through the assign-from-op bridge (so `compiled-procedure-entry` never sees null).
- `ece-reader`: add a requirement that `read-symbol` rejects stray backslash with a read-time error identifying the offending character and source location.

## Impact

- **Code touched**: `wasm/runtime.wat` (`$lookup-variable-value`, possibly `$lookup-global-variable`); `src/reader.scm` (`read-symbol`); potentially `src/runtime.lisp` if CL-side message needs alignment.
- **Bootstrap**: `src/reader.scm` changes require `make bootstrap` to regenerate `bootstrap/bootstrap.ecec`. Reader-level errors at bootstrap read time would be catastrophic, so the rejection must trigger only on actual stray backslashes — no accidental false positives on legitimate ECE source (verified: current tree has none).
- **Tests**: new cases in the WASM integration test suite (unbound variable under `guard` → catchable error) and an ECE test for reader rejection.
- **No breaking changes to users**: any program that already worked remains working. Programs that previously silently crashed with "illegal cast" now get a precise error.
