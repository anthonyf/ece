## Context

The `ece-serve` proposal (Stage 1 of the browser-dev-loop plan) requires SHA-1 and Base64 for the RFC 6455 WebSocket handshake. During implementation it became apparent that these two modules are self-contained enough to ship independently: both are RFC-defined algorithms with fixed inputs and outputs, both depend only on already-available bitwise operations and vector primitives, and both have standard test vectors that let us verify correctness without wiring them up to anything else.

This change extracts them from `ece-serve` so they can merge on their own, clearing the way for subsequent `ece-serve` work (scheduler, socket primitives, HTTP/WS protocols, sandbox integration) to build on a landed foundation instead of dragging these modules along through a large bundled PR.

## Goals / Non-Goals

**Goals:**
- Ship correct, RFC-conformant SHA-1 and Base64 encoding implementations in pure ECE.
- Test them exhaustively against published RFC test vectors so correctness isn't a matter of "looks right to me."
- Keep the implementation readable — these modules will be maintained for the long term, not rewritten.
- Introduce no new CL primitives, no bootstrap regeneration, no runtime changes.
- Leave the modules available for any future caller, not just `ece-serve`'s WebSocket handshake.

**Non-Goals:**
- Constant-time implementation. SHA-1 here is not used for password comparisons, HMAC, or any other timing-sensitive path. The WebSocket `Sec-WebSocket-Accept` check is an ordinary equality test done by the browser, not a server-side secret comparison.
- Base64 decoding. The dev-server use case only needs encoding. A decoder can be added later when a caller needs it; premature addition would be speculative API.
- MIME-style Base64 line wrapping, URL-safe alphabet, or other RFC 4648 variants. Same reasoning — add when needed.
- Optimization for large inputs. SHA-1 over a 60-byte WebSocket handshake input runs through one 64-byte block; Base64 over a 20-byte SHA-1 digest is 28 output chars. Neither is a performance concern at these sizes. If and when a caller streams megabytes through either module, optimize then.
- Bytevector abstraction. ECE has `make-vector` / `vector-ref` / `vector-set!` but no dedicated bytevector type. Both modules use lists-of-integers as the byte representation on input and output; this matches how the existing `ece-build.scm` does file I/O.

## Decisions

### 1. Pure ECE, no new primitives

**Choice:** Both `src/sha1.scm` and `src/base64.scm` are implemented entirely in ECE using existing primitives (`bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`, `make-vector`, `vector-ref`, `vector-set!`, `string-append`, `substring`, `char->integer`, `string-length`, `string-ref`).

**Rationale:** The "prefer ECE over host languages" feedback rule applies. SHA-1 is small enough to implement directly (~170 lines) and doesn't need CL-side optimization. Adding primitives would be overengineering: each new primitive is a portability cost (CL vs WASM), and these modules have no need for capabilities not already in the language.

**Tradeoff:** Pure-ECE SHA-1 is slower than an FFI-wrapped `sb-ironclad` or similar would be. Unmeasured, but probably 100-1000× slower than native. Acceptable for the WebSocket handshake case (one hash per connection, input is ~60 bytes) and irrelevant for anything else we're currently building.

**Alternatives considered:**
- **Wrap a CL hash library via a new primitive.** Rejected — adds a CL dependency and a non-portable primitive for a use case that doesn't need the performance.
- **Use a shell-out to `openssl` or similar via a process primitive.** Rejected for the same reason and because it would introduce a runtime dependency on an external binary.

### 2. Byte representation is list-of-integers, not bytevector

**Choice:** Both modules take and return lists of integers in `[0, 255]`. Input strings for `sha1-string` are decoded via `char->integer` directly; output digests are 20-element lists.

**Rationale:** ECE has no dedicated bytevector type. The existing `ece-build.scm` byte-I/O path uses lists of integers for its `read-file-as-bytes` / `copy-file-binary` helpers, so using the same convention keeps these modules consistent with the rest of the codebase. When/if ECE adds a bytevector primitive, both modules can be updated in a follow-up without changing their external API semantics.

**Tradeoff:** Lists are slow for large inputs (O(n) access). Internally, `sha1-bytes` converts the padded list to a vector once before the block loop, so per-byte access is O(1) during the expensive part. The front-end conversion is O(n) but bounded by the input size.

**Alternatives considered:**
- **Add a bytevector primitive.** Rejected — out of scope, and the existing list-of-integers convention works fine.
- **Use strings as bytevectors.** Rejected — character encoding ambiguity (are strings UTF-8? UTF-16? something else?), and `string-ref` returns characters, not integers.

### 3. Test against authoritative RFC vectors, not hand-computed values

**Choice:** All test expectations are copied from RFC 3174 (for SHA-1) and RFC 4648 (for Base64), plus the composite test uses the RFC 6455 WebSocket handshake example. No test uses a value I computed by hand or eyeballed.

**Rationale:** During initial development I introduced two typos in my "expected" SHA-1 hex strings (writing `9c` instead of the correct `9d` at the end of `SHA-1("abc")`, and guessing the WebSocket intermediate digest instead of deriving it). Both failures were caught by comparing to the published RFC, not by the code. The fix was to update the test expectations to match the authoritative source.

**Rule going forward:** test expectations for standardized algorithms come from the standard, not from the developer's memory. If a test vector isn't in an RFC, compute it in a different tool (Python's `hashlib`, openssl, etc.) and paste the result, don't guess.

**Alternatives considered:**
- **Write property-based tests (random inputs compared to a reference implementation).** Interesting but overkill for a Stage 1 foundation module. RFC vectors are the canonical correctness check.

### 4. Internal helper naming uses `module/name` convention

**Choice:** Non-public helpers inside `src/sha1.scm` are named `sha1/u32`, `sha1/rotl`, `sha1/pad`, etc. Same convention for `base64/char`, `base64/encode-3`, etc. Only `sha1-bytes`, `sha1-string`, and `base64-encode-bytes` are public, unprefixed names.

**Rationale:** ECE doesn't have a formal module system; everything lives in the global environment once loaded. The slash-prefix convention acts as a soft namespace, making it obvious at a call site that `sha1/rotl` is internal to the SHA-1 module and not a general rotate-left utility someone can depend on. If ECE adds a real module system later, the rename to expose them as proper exports is mechanical.

**Alternatives considered:**
- **Use underscore prefixes** (`_sha1-rotl`) — conflicts with Scheme's `_` used in macros.
- **Use hyphen prefixes** (`-sha1-rotl`) — less visually distinct from normal identifiers.
- **Just inline the helpers** — makes the code unreadable; 5 nested `u32+` calls without a name is worse than a named helper.

## Risks / Trade-offs

- **[SHA-1 is broken for collision resistance]** SHA-1 has been cryptographically broken since ~2017 (SHAttered). Using it for anything security-sensitive (password hashing, digital signatures, HMAC for untrusted input) would be a real risk. → **Mitigation**: document in the module header that SHA-1 here is confined to the WebSocket handshake where only the key-agreement property is relied on, and the RFC mandates this specific algorithm. If a future caller wants a real cryptographic hash, they should add SHA-256 (similar algorithm, minor tweaks) rather than reuse SHA-1.
- **[No bytevector primitive yet]** Using lists for byte representation is inefficient compared to a native bytevector type. → **Mitigation**: acceptable performance for current use cases. When/if a bytevector primitive is added, both modules can migrate in a focused follow-up.
- **[Initial test expectations had typos]** Caught during verification — the SHA-1 tests failed the first run due to two wrong hex strings in my test file (not in the implementation). → **Mitigation**: lesson captured in Decision 3 above (always use authoritative RFC values, never hand-computed).
- **[Unicode / non-ASCII strings]** `sha1-string` uses character code points directly as bytes, which matches ASCII and Latin-1 but not UTF-8 for non-ASCII characters. → **Mitigation**: documented in the `sha1-string` docstring. Callers that need UTF-8 or other encodings should pre-encode to a byte list and call `sha1-bytes` directly.

## Migration Plan

Not applicable. Pure addition. Nothing existing is deprecated, renamed, or changed. No data migration, no API version bump. `make test-ece` continues to run and pass exactly as before, plus 13 new tests.

## Open Questions

- **Should these modules be loaded by `compile-system` so `ece-main.ecec` always includes them?** Not yet. The `test-ece` target's one-line addition is enough for now. When `ece-serve.scm` is written and needs them at runtime, the `share/ece/ece-main.ecec` Makefile target gets updated in that change to include them in its `compile-system` invocation. Deferring this keeps this change's Makefile delta to one line.
- **SHA-256 at the same time?** Tempting (both share similar structure) but out of scope. Add when a concrete caller needs it. The current design puts SHA-1 in a dedicated file per-algorithm, so a `src/sha256.scm` later would be a parallel addition without disturbing `sha1.scm`.
