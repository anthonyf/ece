## 1. ECE-side procedures

- [x] 1.1 Add `eval-string` to `src/prelude.scm` — read/eval loop over `open-input-string` port
- [x] 1.2 Add `eval-string-last` to `src/prelude.scm` — same loop but returns last value
- [x] 1.3 Rebuild bootstrap (`make bootstrap`) to include new procedures in `prelude.ececb`

## 2. Sandbox JS simplification

- [x] 2.1 Remove `parseScheme()` from `sandbox.js`
- [x] 2.2 Remove `buildECEValue()` from `sandbox.js`
- [x] 2.3 Rewrite `evalECE()` to call ECE's `eval-string` via `call_ece_proc`
- [x] 2.4 Rewrite `evalRepl()` to call ECE's `eval-string-last` via `call_ece_proc` and display the result

## 3. Testing

- [x] 3.1 Add ECE-side tests for `eval-string` (multiple exprs, empty string, comments-only)
- [x] 3.2 Add ECE-side tests for `eval-string-last` (single expr, multiple exprs, empty string)
- [x] 3.3 Rebuild sandbox (`make sandbox`) and verify editor Run + REPL work end-to-end
