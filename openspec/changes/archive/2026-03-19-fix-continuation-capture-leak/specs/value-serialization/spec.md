## MODIFIED Requirements

### Requirement: serializer detects and skips code objects
The `serialize-value` function SHALL detect code-like objects (instruction vectors, compilation space internals) and emit skip sentinels instead of recursively serializing them.

#### Scenario: Vector containing instructions
- **WHEN** serializing a vector whose elements are instruction lists (e.g., `(assign val ...)`)
- **THEN** the serializer SHALL emit `(%ser/code-skip)` instead of serializing each instruction

#### Scenario: Data vector preserved
- **WHEN** serializing a vector like `#(1 2 3)` or `#("a" "b")`
- **THEN** the serializer SHALL serialize it normally as `(%ser/vector 1 2 3)`
