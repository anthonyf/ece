## 1. Implementation

- [x] 1.1 Create `src/sha1.scm` with pure-ECE SHA-1 per RFC 3174 / FIPS 180-1. Public API: `sha1-bytes` (byte-list input), `sha1-string` (string input via `char->integer`).
- [x] 1.2 Use a preallocated 80-element vector for the message schedule and a 5-element state vector for `h0..h4`, so the block loop does O(1) per-byte access.
- [x] 1.3 Name internal helpers with a `sha1/` prefix to keep the global namespace clean.
- [x] 1.4 Create `src/base64.scm` with pure-ECE Base64 encoding per RFC 4648 standard alphabet. Public API: `base64-encode-bytes` (byte-list input, string output).
- [x] 1.5 Handle all three pad-length cases (0, 1, 2 trailing `=` characters).
- [x] 1.6 Name internal helpers with a `base64/` prefix.

## 2. Tests

- [x] 2.1 Create `tests/ece/common/test-sha1.scm` with RFC 3174 test vectors (empty, `"abc"`, 448-bit two-block message).
- [x] 2.2 Add the intermediate SHA-1 digest test for the RFC 6455 WebSocket handshake example, using the digest value derived from the passing end-to-end round-trip.
- [x] 2.3 Create `tests/ece/common/test-base64.scm` with RFC 4648 test vectors covering all pad-length cases.
- [x] 2.4 Add the end-to-end WebSocket handshake test: `base64-encode-bytes(sha1-string("dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))` must equal `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="` per RFC 6455 §1.3.

## 3. Wiring

- [x] 3.1 Modify the `test-ece` target in `Makefile` to load `src/sha1.scm` and `src/base64.scm` before running the test framework, so test files can use them.
- [ ] 3.2 (Out of scope, deferred to `ece-serve`.) Add these files to the `share/ece/ece-main.ecec` target's `compile-system` invocation so they're part of the shipped `ece` binary. Deferred until `ece-serve.scm` itself lands and needs them at runtime.

## 4. Validation

- [x] 4.1 Run `make test-ece` and confirm all 448 tests pass, including the 13 new sha1 + base64 tests.
- [x] 4.2 Verify the full `make test-ece` output shows `0 failed` overall.
- [x] 4.3 Re-verify the SHA-1 test expectations against the RFC 3174 published values (not hand-computed). The initial implementation had two typos in the test expectations (`"abc"` ended with `9c` instead of `9d`; WebSocket intermediate digest was guessed); both fixed after the first test run surfaced them.

## 5. Update ece-serve proposal

- [x] 5.1 In `openspec/changes/ece-serve/proposal.md`'s "What Changes" section, replaced the `ADDED src/sha1.scm + src/base64.scm` bullet with a `PRE-LANDED` note explaining that they're in the `sha1-base64-utilities` change.
- [x] 5.2 In `openspec/changes/ece-serve/tasks.md` section 3, marked 3.1–3.3 complete and annotated 3.4 as "done in ece-serve's implementation PR (still pending)".
- [x] 5.3 In `openspec/changes/ece-serve/design.md` Decision 4 + Open Questions, noted that SHA-1 and Base64 are pre-landed by this change and ece-serve just loads them.

## 6. Archive and commit

- [ ] 6.1 Archive this change (`/opsx:archive sha1-base64-utilities`) on the branch BEFORE merging, per the `feedback_archive_before_merge` rule.
- [ ] 6.2 Commit the proposal artifacts (proposal, design, specs, tasks) and the ece-serve proposal updates as a follow-up commit on the same branch.
- [ ] 6.3 Open the PR with a concise summary pointing at the test results and the relationship to `ece-serve`.
