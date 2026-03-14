## Why

Variable lookup accounts for 44% of ECE's runtime. The current compiler emits `(op lookup-variable-value) (const name) (reg env)` which performs an O(frames × vars) linear scan at runtime. Since the compiler already knows the lexical position of every variable, it can emit direct indexed access instructions instead, reducing lookup to O(depth) frame traversal + O(1) offset access. This is the standard optimization described in SICP Exercise 5.41–5.43.

## What Changes

- The compiler will compute lexical addresses (depth, offset) for all lexically-bound variables at compile time
- New runtime operations `lexical-ref` and `lexical-set!` will perform indexed environment access
- Variable lookup, assignment, and definition instructions will use lexical addresses for local variables
- Global/free variables will continue to use name-based lookup (unchanged behavior)
- Environment frames will use vectors instead of parallel lists for O(1) indexed access
- **BREAKING**: Image format changes — old images cannot be loaded (new frame representation)

## Capabilities

### New Capabilities
- `lexical-addressing`: Compiler computes (depth, offset) pairs for lexically-bound variables and emits indexed access instructions; runtime provides O(1) frame slot access via vector-backed frames

### Modified Capabilities
- `instruction-executor`: New instruction forms for lexical ref/set operations; vector-backed frame access in extend-environment
- `compiler-core`: Compile-time lexical environment tracking to compute variable addresses
- `flat-image-serializer`: Serialize vector-backed frames instead of list-backed frames
- `flat-image-deserializer`: Deserialize vector-backed frames

## Impact

- **src/compiler.lisp / src/compiler.scm**: Lexical environment tracking during compilation, new instruction emission
- **src/runtime.lisp**: `extend-environment`, `lookup-variable-value`, `set-variable-value!`, `define-variable!` updated for vector frames; new `lexical-ref`/`lexical-set!` operations; `execute-instructions` handles new instruction forms
- **src/runtime.lisp (image)**: `flat-image-serialize`/`flat-image-deserialize` handle vector frames
- **bootstrap/ece.image**: Must be regenerated after changes
- **Performance**: Expected ~40% reduction in total execution time based on profiling data
