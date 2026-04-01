## MODIFIED Requirements

### Requirement: O(n) memory serialization
The `serialize-value` function SHALL use O(n) total memory when serializing structures of depth n, where n is the total number of tokens in the output. The implementation SHALL use port-based output (`open-output-string` / `display` / `get-output-string`) rather than recursive string concatenation.

#### Scenario: Deep environment chain serialization
- **WHEN** serializing a compiled procedure with a deeply nested environment chain (100+ frames)
- **THEN** the serializer SHALL complete without exhausting heap memory and produce a valid serialized string

#### Scenario: Serialization inside nested execution context
- **WHEN** `serialize-value` is called on a compiled procedure created inside a nested compilation context
- **THEN** the serializer SHALL complete successfully and produce output that `deserialize-value` can reconstruct

#### Scenario: Output format unchanged
- **WHEN** serializing any value
- **THEN** the output SHALL be identical to the previous `string-append` implementation for the same input

#### Scenario: Cyclic structure round-trip via deserialize-value
- **WHEN** deserializing a serialized value that contains cyclic references (via `%ser/def`/`%ser/ref` tags where a `%ser/ref` appears inside the body of its own `%ser/def`)
- **THEN** `deserialize-value` SHALL reconstruct the cycle correctly with the back-reference resolving to the pre-allocated placeholder
