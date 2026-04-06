## ADDED Requirements

### Requirement: Hash table round-trip serialization

`serialize-value` SHALL recognize CL native hash table objects (not just tagged-pair representations) and emit `(%ser/hash-table (key value) ...)` format. `deserialize-value` SHALL reconstruct a working hash table from this format.

#### Scenario: Round-trip a hash table with symbol keys
- **WHEN** a hash table containing `{a: 1, b: 2}` is serialized and deserialized
- **THEN** the result is a hash table where `(hash-ref result 'a)` returns `1` and `(hash-ref result 'b)` returns `2`

#### Scenario: Empty hash table round-trip
- **WHEN** an empty hash table is serialized and deserialized
- **THEN** the result is an empty hash table

### Requirement: Continuation serialization handles non-serializable wind frames

When serializing a continuation whose `winds` field contains `dynamic-wind` frames with non-serializable objects (CL ports, native closures), the serializer SHALL strip those frames and emit a `(%ser/wind-stripped)` sentinel. Deserialization SHALL skip stripped wind sentinels gracefully.

#### Scenario: Continuation captured inside parameterize round-trips
- **WHEN** a continuation is captured inside a `(parameterize ((current-output-port ...)) ...)` form and serialized/deserialized
- **THEN** serialization/deserialization completes without error and any non-serializable wind frames are stripped and skipped gracefully during deserialization

#### Scenario: Continuation with no non-serializable winds is unchanged
- **WHEN** a continuation with only serializable wind frames is serialized
- **THEN** all wind frames are preserved (no stripping occurs)
