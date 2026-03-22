## Why

The sandbox (`sandbox.js`) contains a 65-line JavaScript S-expression parser (`parseScheme`) and a 20-line AST-to-WASM-handle builder (`buildECEValue`) that duplicate functionality already present in ECE's bootstrapped reader (`reader.ececb`). This redundancy means two parsers to maintain, the JS one being incomplete (no quasiquote, no `#(...)` vectors, no block comments, etc.). By exposing an `eval-string` procedure from ECE, the JS side can pass source text directly and let ECE's own reader and compiler handle everything.

## What Changes

- Add an `eval-string` procedure in ECE (in `prelude.scm`) that opens a string port, reads all expressions with ECE's reader, and evaluates each with `eval`
- Add an `eval-string-last` variant that returns the value of the last expression (for REPL use)
- Remove `parseScheme()` (~65 lines) and `buildECEValue()` (~20 lines) from `sandbox.js`
- Simplify `evalECE()` and `evalRepl()` in `sandbox.js` to call the ECE-side procedures via `call_ece_proc`

## Capabilities

### New Capabilities
- `eval-string`: ECE-native string evaluation — read and eval all expressions from a source string

### Modified Capabilities

(none)

## Impact

- **sandbox.js**: ~85 lines of JS removed, `evalECE` and `evalRepl` simplified to ~5 lines each
- **prelude.scm**: ~10 lines added (`eval-string`, `eval-string-last`)
- **Bootstrap**: prelude.ececb must be rebuilt (`make bootstrap`) to include the new procedures
- **Correctness**: sandbox now uses the same reader as the CL runtime — no more parser divergence
