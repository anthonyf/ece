## MODIFIED Requirements

### Requirement: O(n) memory serialization
The `serialize-value` function SHALL use O(n) total memory when serializing structures of depth n, where n is the total number of tokens in the output. The implementation SHALL use port-based output (`open-output-string` / `display` / `get-output-string`) rather than recursive string concatenation.

#### Scenario: Deep environment chain serialization
- **WHEN** serializing a compiled procedure with a deeply nested environment chain (100+ frames)
- **THEN** the serializer SHALL complete without exhausting heap memory and produce a valid serialized string

#### Scenario: Serialization inside nested execution context
- **WHEN** `serialize-value` is called on a compiled procedure created inside a `try-eval` / nested `mc-compile-and-go` context
- **THEN** the serializer SHALL complete successfully and produce output that `deserialize-value` can reconstruct

#### Scenario: Output format unchanged
- **WHEN** serializing any value
- **THEN** the output SHALL be identical to the previous `string-append` implementation for the same input

## NEW Requirements

### Requirement: String output ports
The runtime SHALL provide `open-output-string` and `get-output-string` as core primitives on all platforms.

#### Scenario: Basic string port round-trip
- **GIVEN** a port created by `(open-output-string)`
- **WHEN** characters or strings are written via `display` / `write` / `write-char`
- **THEN** `(get-output-string port)` SHALL return the accumulated content as a string
