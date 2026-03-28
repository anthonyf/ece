## Why

Last WASM test failure: `(make-parameter "hello" string-length)` returns a parameter with value `"hello"` instead of `5`. The converter function isn't applied. Fixing this achieves 329/329 on the WASM common test suite.

## What Changes

- ECE prelude gains a `make-parameter` wrapper that applies the converter to the initial value before calling the raw primitive
- CL's `ece-make-parameter-value` simplified to not apply converter (prelude handles it for both hosts)
- Converter application at creation time and during `parameterize` happens in ECE code, where calling compiled procedures works naturally

## Capabilities

### Modified Capabilities
- `wasm-primitives`: make-parameter converter handled at prelude level

## Impact

- **src/prelude.scm**: ~5 lines — capture raw primitive, define wrapper
- **src/runtime.lisp**: simplify `ece-make-parameter-value` to not apply converter
- **bootstrap/**: rebuilt
