## Why

ECE's primitive system is tightly coupled to Common Lisp. Primitives are stored as `(primitive <cl-symbol>)` and dispatched via `(symbol-function name)`. This makes the image non-portable — it can't load on a WASM or JS runtime. As ECE targets multiple platforms (CL for development, WASM for browser-hosted games including canvas-based games at 60fps), primitives need a platform-neutral identification and dispatch mechanism.

## What Changes

- Introduce a **primitive manifest** (`primitives.def`) — an S-expression file that is the canonical registry of all primitives with stable numeric IDs, names, arity, and platform tags
- Change primitive representation from `(primitive <cl-symbol>)` to `(primitive <numeric-id>)` in the runtime and image format
- Each runtime implements a **dispatch table** (array indexed by ID) mapping IDs to native functions
- Primitives are categorized: `core` (all runtimes must implement), `cl` (CL-only), `browser` (browser-only), extensible to future platforms
- Add `platform-has?` primitive for runtime capability discovery
- Add `%platform-primitives` primitive that returns the list of available primitive names
- Update binary image serialization to store primitives by numeric ID instead of CL symbol

## Capabilities

### New Capabilities
- `primitive-manifest`: Canonical registry of all primitives with stable IDs, names, arity, and platform tags
- `portable-primitive-dispatch`: Numeric ID-based primitive dispatch replacing CL symbol-function lookup
- `platform-discovery`: `platform-has?` and `%platform-primitives` for runtime capability detection

### Modified Capabilities
- `instruction-executor`: Primitive dispatch changes from symbol-function lookup to table index
- `flat-image-serializer`: Primitives serialized by numeric ID instead of CL symbol
- `flat-image-deserializer`: Primitives deserialized by looking up numeric ID in platform dispatch table

## Impact

- `primitives.def` (new): Canonical primitive manifest
- `src/runtime.lisp`: Primitive registration, dispatch table, `apply-primitive-procedure`, image serialization/deserialization
- `src/compiler.scm`: No changes expected — compiler emits `(op name)` which is resolved at assembly time
- `src/prelude.scm`: Add `platform-has?` if implemented in ECE
- Tests: Verify round-trip image save/load with numeric IDs, verify platform-has? discovery

## Non-Goals

- Implementing the WASM or JS runtime (that's a separate change that builds on this)
- Changing how `(op ...)` operations work in the instruction executor (those are internal VM operations, not user-callable primitives)
- Foreign function interface for dynamically registering new primitives at runtime from host language
