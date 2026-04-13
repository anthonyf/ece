## Why

The larger `ece-serve` change (Stage 1 of the browser-dev-loop plan) needs SHA-1 and Base64 encoding for the WebSocket handshake — RFC 6455 §4.2.2 defines `Sec-WebSocket-Accept` as `base64(sha1(client-key || magic-guid))`. While writing `ece-serve` it became clear that these two modules are:

1. **Foundational and reusable** — any future ECE code that needs cryptographic hashing or binary encoding can pick them up without new primitives. They are not tied to the dev server in any way beyond their original motivation.
2. **Independently complete** — both modules implement RFC-specified algorithms, both have full test coverage against the authoritative RFC test vectors, and both pass the entire 448-test ECE suite with zero regressions.
3. **Shippable now** — they depend only on the existing bitwise primitives (`bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`) and standard vector operations. No new CL primitives, no bootstrap regeneration, no runtime changes.

Rather than sit on these utilities until the rest of `ece-serve` (scheduler, socket primitives, HTTP/WS server, sandbox integration) is ready, this change extracts them into a dedicated proposal so they can merge independently. The `ece-serve` proposal is updated in the same PR to remove sha1/base64 from its scope; when its implementation continues, it builds on these already-landed utilities.

## What Changes

- **ADDED** `src/sha1.scm` — pure-ECE implementation of SHA-1 per RFC 3174 / FIPS 180-1. ~170 lines. Public API: `(sha1-bytes byte-list)`, `(sha1-string str)`, both returning a 20-byte list. Uses a preallocated 80-element vector for the expanded message schedule and a 5-element state vector for `h0..h4`, giving O(1) per-byte access inside the block loop.
- **ADDED** `src/base64.scm` — pure-ECE implementation of Base64 encoding per RFC 4648 with the standard alphabet (`A-Za-z0-9+/`, padding `=`). ~60 lines. Public API: `(base64-encode-bytes byte-list)` returning a string. Encoding only — no decoder, no MIME line wrapping, no URL-safe alphabet. Add those if and when a concrete caller needs them.
- **ADDED** `tests/ece/common/test-sha1.scm` — 5 tests covering the RFC 3174 vectors (empty string, `"abc"`, the 448-bit two-block message), a length check, and the intermediate digest from the RFC 6455 WebSocket handshake example.
- **ADDED** `tests/ece/common/test-base64.scm` — 8 tests covering the RFC 4648 standard test vectors (empty, `f`, `fo`, `foo`, `foob`, `fooba`, `foobar`) and an end-to-end composition test that verifies `base64-encode-bytes(sha1-string(websocket-key || magic))` equals `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="` from RFC 6455 §1.3.
- **MODIFIED** `Makefile` — the `test-ece` target now loads `src/sha1.scm` and `src/base64.scm` before running the test framework, so the new test files can use the modules. One-line addition between existing `sdk-lib.scm` and `ece-unit.scm` loads.
- **NO new primitives**, **no runtime changes**, **no CL-side additions**, **no bootstrap regeneration**, **no changes to any existing .scm file**.

## Capabilities

### New Capabilities
- `sha1-encoding` — SHA-1 hash function available to ECE programs. Contract: produces a 20-byte digest conforming to RFC 3174 for any byte-list input.
- `base64-encoding` — Base64 encoder available to ECE programs. Contract: encodes arbitrary byte-list input to an RFC 4648-standard alphabet string with padding.

### Modified Capabilities
None. These are pure additions.

## Impact

- **Affected code**: two new source files (`src/sha1.scm`, `src/base64.scm`), two new test files, one one-line `Makefile` edit. Nothing existing is touched beyond the `test-ece` target.
- **Affected workflows**: none — the modules are opt-in. Code that doesn't load them is unchanged. Code that does gets two new functions.
- **Performance**: no runtime-level impact. SHA-1 for a 1-block input (up to 55 bytes) runs in ~80 rounds of Scheme-level bitwise operations; acceptable for the WebSocket handshake use case. Base64 is linear in input size, a few arithmetic ops per byte. Neither is optimized for large volumes; both are correct and readable.
- **Test plan**: `make test-ece` runs the full 448-test suite including the 13 new tests. All pass. The SHA-1 RFC 3174 vectors (empty, `"abc"`, 448-bit two-block) are the most rigorous standard tests for SHA-1 correctness. The Base64 RFC 4648 vectors cover all pad-length cases (0, 1, 2 pad characters). The composite WebSocket handshake test verifies both modules work together end-to-end against the RFC 6455 authoritative example.
- **Rollback**: single-commit revert. Nothing depends on these modules yet — the `ece-serve` proposal that will eventually use them is still in the design phase at the time of this change.
- **Relationship to `ece-serve`**: foundational pre-req. `ece-serve` needs these modules for the WebSocket handshake; landing them independently keeps the `ece-serve` PR smaller when it eventually ships, and makes these utilities available to any other crypto/encoding need that surfaces in the meantime.
