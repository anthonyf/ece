## Context

The sandbox (`sandbox.js`) currently evaluates ECE code through a JS-side pipeline: `parseScheme()` parses source into a JS AST, `buildECEValue()` converts that AST into WASM handles, then ECE's `eval` is called per expression. ECE already has a full reader bootstrapped from `reader.ececb` and `open-input-string` (primitive 73) for string ports. The JS parser is redundant and incomplete.

## Goals / Non-Goals

**Goals:**
- Eliminate the JS S-expression parser by using ECE's own reader
- Provide `eval-string` and `eval-string-last` as standard ECE procedures
- Simplify `evalECE()` and `evalRepl()` in sandbox.js

**Non-Goals:**
- Changing the reader itself
- Modifying the WASM runtime or adding new primitives
- Changing how pre-compiled `.ececb` programs are loaded (that path stays as-is)

## Decisions

### 1. Procedures live in `prelude.scm`

`eval-string` and `eval-string-last` go in the prelude since they compose existing primitives (`open-input-string`, `read`, `eval`, `eof-object?`) with no new runtime support needed.

**Alternative**: A separate `sandbox-lib.scm` — rejected because these are generally useful, not sandbox-specific.

### 2. Two variants: `eval-string` and `eval-string-last`

- `eval-string` — evaluates all expressions for side effects, returns void. Used by the editor "Run" button.
- `eval-string-last` — evaluates all expressions, returns the value of the last one. Used by the REPL.

**Alternative**: Single procedure that always returns the last value — rejected because the editor path doesn't need it, and `write`-ing a void result to the REPL would be confusing.

### 3. JS calls via `call_ece_proc`

The sandbox already uses `call_ece_proc` to invoke ECE procedures from JS. The simplified `evalECE` looks up `eval-string` in the environment and calls it with the source string. No new WASM exports needed.

### 4. Pre-compiled `.ececb` path unchanged

`evalECE` still checks for pre-compiled programs first and loads them via the existing binary path. `eval-string` is only the fallback for runtime compilation of edited/new source.

## Risks / Trade-offs

- **Error reporting**: ECE reader errors will now surface as ECE exceptions rather than JS errors. The JS side already catches exceptions from `call_ece_proc`, so this should work — but error messages may differ. → Mitigation: test with malformed input to verify error messages are clear.
- **Bootstrap dependency**: `eval-string` must be available after bootstrap. Since it's in `prelude.scm` (first bootstrap file), this is safe. → Mitigation: verify during testing.
- **Performance**: ECE's reader may be slightly slower than the JS parser for trivial inputs (the JS parser skips compilation overhead). → Mitigation: for the sandbox use case this is negligible; pre-compiled `.ececb` handles the hot path.
