## Tasks

### Investigation
- [x] Dump the compiled-procedure space-id and PC for a late-defined function
- [x] Check if that space/PC points to valid instructions
- [x] Compare space/PC for the same function defined early vs late
- [x] Add diagnostic at the crash point to identify which ref.cast fails and on what type
- [x] Root cause: executor env register leaks between .ecec compilation units — function call leaves env pointing to callee's frame instead of global env

### Fix
- [x] Inject `(assign env (const <global-env>))` between compilation units in `load_ecec` Phase 2
- [x] Account for extra instructions in Phase 1 PC count
- [x] Re-enable string/vector round-trip tests in test-roundtrip.scm
- [x] Add regression tests: top-level define called from multiple thunks

### Verify
- [x] Run full test suite: 441 passed, 0 failed (409 ECE + 32 integration)
- [x] Run CL tests: all passed
