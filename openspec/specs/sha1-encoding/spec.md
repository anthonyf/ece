## ADDED Requirements

### Requirement: `sha1-bytes` computes a SHA-1 digest of a byte list
The `sha1-bytes` procedure in `src/sha1.scm` SHALL accept a list of integers in `[0, 255]` and return a list of exactly 20 integers in `[0, 255]` representing the SHA-1 digest of the input as defined by RFC 3174 / FIPS 180-1. The procedure SHALL behave deterministically: identical inputs SHALL produce identical outputs.

#### Scenario: Empty input
- **WHEN** `sha1-bytes` is called with `'()`
- **THEN** the result SHALL equal the byte-list representation of `da39a3ee5e6b4b0d3255bfef95601890afd80709` (RFC 3174 empty-string digest)
- **AND** the result SHALL have length 20

#### Scenario: RFC 3174 test vector 1
- **WHEN** `sha1-bytes` is called with the byte list for ASCII `"abc"` (`(97 98 99)`)
- **THEN** the result SHALL equal the byte-list representation of `a9993e364706816aba3e25717850c26c9cd0d89d`

#### Scenario: RFC 3174 test vector 2 (two-block message)
- **WHEN** `sha1-bytes` is called with the 56-byte ASCII message `"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"`
- **THEN** the result SHALL equal the byte-list representation of `84983e441c3bd26ebaae4aa1f95129e5e54670f1`

### Requirement: `sha1-string` computes SHA-1 of a string via character code points
The `sha1-string` procedure in `src/sha1.scm` SHALL accept a string and return a 20-byte list representing the SHA-1 digest of the character code points interpreted as bytes. For ASCII and Latin-1 inputs this matches standard SHA-1 over the UTF-8 byte sequence (because UTF-8 of code points `[0, 127]` equals the code point itself). For non-ASCII inputs, callers that need specific Unicode encoding semantics SHALL pre-encode the string to a byte list and use `sha1-bytes` directly.

#### Scenario: ASCII input
- **WHEN** `sha1-string` is called with `"abc"`
- **THEN** the result SHALL equal `(sha1-bytes '(97 98 99))`

### Requirement: SHA-1 implementation does not depend on new primitives
The SHA-1 implementation SHALL use only existing core primitives (bitwise operations, arithmetic shift, vector operations, string operations). It SHALL NOT require any CL-side additions to `primitives.def`, any WASM runtime changes, or any bootstrap regeneration.

#### Scenario: Loading without runtime changes
- **WHEN** `(ece:evaluate '(load "src/sha1.scm"))` is called in an SBCL image that has already loaded the current bootstrap
- **THEN** the load SHALL succeed without error
- **AND** the exported procedures `sha1-bytes` and `sha1-string` SHALL be defined in the global environment
