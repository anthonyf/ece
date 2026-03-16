## Why

`lookup-variable-value` consumes 51% of CPU time during tests, due to O(n) linear scans through the 309-element global environment frame. Every global variable access (both from bootstrap-compiled code and runtime-compiled code) walks a linked list averaging ~155 comparisons. Replacing this with a hash-table-backed frame reduces global lookups to O(1), cutting overall test suite time roughly in half.

## What Changes

- Replace the global environment frame structure from `((var1 var2 ...) . (val1 val2 ...))` with a CL hash-table-backed frame
- Modify `lookup-variable-value`, `set-variable-value!`, and `define-variable!` to dispatch on frame type (hash-table vs list-based)
- Update `extend-environment` to support creating hash-table frames (for the global frame only; local frames remain as vectors/lists)
- Update image serialization/deserialization to handle hash-table frames
- Update ECE-side compaction code (`compaction.scm`) to handle hash-table frames in environment walks

## Capabilities

### New Capabilities
- `hash-table-frame`: Hash-table-backed environment frame type for O(1) variable lookup, with integration into serialization and compaction

### Modified Capabilities
- `binary-image-serializer`: Must serialize hash-table frames in the environment data section
- `binary-image-deserializer`: Must deserialize hash-table frames and reconstruct the hash-table on load

## Impact

- `src/runtime.lisp`: Variable access functions, environment frame constructors, binary serializer/deserializer
- `src/compaction.scm`: Environment walking and deep-copy-and-remap functions
- `bootstrap/ece.image`: Must be regenerated with hash-table global frame
- Test suite runtime: Expected ~50% reduction (~8 min → ~4 min locally)
