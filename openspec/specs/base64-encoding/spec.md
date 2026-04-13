## ADDED Requirements

### Requirement: `base64-encode-bytes` encodes byte lists per RFC 4648
The `base64-encode-bytes` procedure in `src/base64.scm` SHALL accept a list of integers in `[0, 255]` and return a string containing the Base64 encoding of those bytes using the standard RFC 4648 alphabet (`A-Z`, `a-z`, `0-9`, `+`, `/`) with `=` padding.

#### Scenario: Empty input
- **WHEN** `base64-encode-bytes` is called with `'()`
- **THEN** the result SHALL equal the empty string `""`

#### Scenario: RFC 4648 test vectors (all pad-length cases)
- **WHEN** `base64-encode-bytes` is called with the byte list for ASCII `"f"` (1 byte, 2 pad chars)
- **THEN** the result SHALL equal `"Zg=="`
- **WHEN** called with `"fo"` (2 bytes, 1 pad char)
- **THEN** the result SHALL equal `"Zm8="`
- **WHEN** called with `"foo"` (3 bytes, 0 pad chars)
- **THEN** the result SHALL equal `"Zm9v"`
- **WHEN** called with `"foob"` (4 bytes, 2 pad chars)
- **THEN** the result SHALL equal `"Zm9vYg=="`
- **WHEN** called with `"fooba"` (5 bytes, 1 pad char)
- **THEN** the result SHALL equal `"Zm9vYmE="`
- **WHEN** called with `"foobar"` (6 bytes, 0 pad chars)
- **THEN** the result SHALL equal `"Zm9vYmFy"`

### Requirement: `base64-encode-bytes` composes with `sha1-string` for RFC 6455 handshakes
The combination `(base64-encode-bytes (sha1-string (string-append client-key magic-guid)))` SHALL produce the exact string the RFC 6455 WebSocket handshake protocol specifies for `Sec-WebSocket-Accept`, for any client-key input the RFC defines as valid.

#### Scenario: RFC 6455 authoritative example
- **WHEN** `sha1-string` is called with `"dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"`
- **AND** its result is passed through `base64-encode-bytes`
- **THEN** the result SHALL equal `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="` (RFC 6455 §1.3)

### Requirement: Base64 implementation is encoding-only and uses the standard alphabet
The Base64 module SHALL implement only encoding, SHALL use the standard RFC 4648 alphabet, and SHALL always emit `=` padding to align output to 4-character groups. It SHALL NOT provide a decoder, URL-safe alphabet, or MIME line wrapping in this change — those are deliberately deferred until a concrete caller needs them.

#### Scenario: Output is always a multiple of 4 characters
- **WHEN** `base64-encode-bytes` is called with any non-empty byte list
- **THEN** the length of the result string SHALL be a positive multiple of 4
