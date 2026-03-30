## Why

`%global-ref` (the syntax-rules hygiene mechanism for protecting free variables from lexical shadowing) works on CL but silently fails on WASM. On CL, compiled `let`/`lambda` creates vector frames which `lookup-variable-value` skips, accidentally making `%global-ref` resolve to global bindings. On WASM, all frames use the same `$env-frame` structure, so `lookup-variable-value` finds the local (shadowed) binding first. This causes hygiene tests like `(let ((+ *)) (add1 3))` to return 3 instead of 4.

## What Changes

- Add a new register machine operation `lookup-global-variable` that searches from the global environment only, bypassing lexical frames
- Implement `lookup-global-variable` in both CL (`runtime.lisp`) and WASM (`runtime.wat`) runtimes
- Change the compiler's `mc-compile-global-ref` to emit `(op lookup-global-variable)` instead of `(op lookup-variable-value) ... (reg env)`
- Two-pass bootstrap to propagate the compiler change

## Capabilities

### New Capabilities

- `global-ref-operation`: New register machine operation `lookup-global-variable` for hygiene-safe global variable access

### Modified Capabilities

- `syntax-rules`: WASM hygiene now correctly resolves free template variables via global lookup

## Impact

- **src/compiler.scm**: `mc-compile-global-ref` emits new operation (1 line change)
- **src/runtime.lisp**: Add `lookup-global-variable` function + register in `get-operation` dispatch
- **wasm/runtime.wat**: Add `$lookup-global-variable` function + operation dispatch case in executor
- **bootstrap/**: Two-pass rebuild
- **tests/ece/test-syntax-rules.scm**: Hygiene tests now pass on WASM
