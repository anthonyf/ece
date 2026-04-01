## MODIFIED Requirements

### Requirement: serializer detects and skips code objects
The `serialize-value` function SHALL detect code-like objects (instruction vectors, compilation space internals) and emit skip sentinels instead of recursively serializing them. The serializer SHALL use port-based output (writing to an output string port) instead of recursive `string-append`, ensuring O(n) memory usage for serializing structures of depth n.

#### Scenario: Vector containing instructions
- **WHEN** serializing a vector whose elements are instruction lists (e.g., `(assign val ...)`)
- **THEN** the serializer SHALL emit `(%ser/code-skip)` instead of serializing each instruction

#### Scenario: Data vector preserved
- **WHEN** serializing a vector like `#(1 2 3)` or `#("a" "b")`
- **THEN** the serializer SHALL serialize it normally as `(%ser/vector 1 2 3)`

#### Scenario: Deep environment chain serialization
- **WHEN** serializing a compiled procedure with a deeply nested environment chain (100+ frames)
- **THEN** the serializer SHALL complete without exhausting heap memory and produce a valid serialized string

#### Scenario: Serialization inside nested execution context
- **WHEN** `serialize-value` is called on a compiled procedure created inside a `try-eval` / nested `mc-compile-and-go` context
- **THEN** the serializer SHALL complete successfully and produce output that `deserialize-value` can reconstruct
