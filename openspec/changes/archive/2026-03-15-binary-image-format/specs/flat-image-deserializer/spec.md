## MODIFIED Requirements

### Requirement: flat deserializer loads image from line-oriented format
The `flat-image-deserialize` function SHALL remain available as a fallback for loading legacy text-format images. It SHALL no longer be the default deserialization path — `ece-load-image` SHALL auto-detect format and prefer binary. The function's behavior SHALL remain unchanged.

#### Scenario: Still loads text format images
- **WHEN** `flat-image-deserialize` is called with a text-format image stream
- **THEN** it SHALL produce the same result as before this change

#### Scenario: Used as fallback by ece-load-image
- **WHEN** `ece-load-image` detects a text-format file (no "ECE" magic header)
- **THEN** it SHALL delegate to `flat-image-deserialize`
