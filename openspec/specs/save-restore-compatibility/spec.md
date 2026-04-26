## Requirements

### Requirement: archive-backed saves detect code drift
Serialized code-object references SHALL include a fingerprint when the runtime
can inspect the referenced code object's metadata and source instructions.
Deserializing such a reference SHALL verify that the currently loaded archive
entry still matches the saved fingerprint before returning the code object.

#### Scenario: matching archive entry loads
- **GIVEN** a serialized `(%ser/co-ref stem index fingerprint)` whose
  `fingerprint` matches the currently loaded archive entry
- **WHEN** the value is deserialized
- **THEN** deserialization SHALL return the registered code object

#### Scenario: archive entry changed
- **GIVEN** a serialized `(%ser/co-ref stem index fingerprint)` whose
  `stem` and `index` resolve to a loaded code object
- **AND** the loaded code object's current fingerprint differs from the saved
  `fingerprint`
- **WHEN** the value is deserialized
- **THEN** deserialization SHALL raise `ece-deser-archive-mismatch-error`
- **AND** the error SHALL expose `stem`, `index`, `expected`, and `actual`
  fields

#### Scenario: legacy co-ref remains readable
- **GIVEN** a serialized legacy `(%ser/co-ref stem index)` without a
  fingerprint
- **WHEN** `stem` and `index` resolve to a loaded code object
- **THEN** deserialization SHALL return the registered code object without a
  fingerprint check

### Requirement: save/restore policy is explicit
ECE documentation SHALL state that continuation saves are compatible with the
same archive identity, not merely the same archive filename, and that code
changes invalidate continuation saves unless an application provides its own
migration or checkpoint layer.

### Requirement: host resources are not restored implicitly
ECE documentation SHALL state that host resources such as file ports, sockets,
native streams, process handles, and browser handles are not restored by value.
Serializing a continuation whose `dynamic-wind` stack requires unserializable
host state SHALL fail loudly rather than strip wind frames.

