## 1. CL dependencies and manifest entries

- [x] 1.1 Add `usocket` to `qlfile` and pin via `qlfile.lock`. Run `qlot install` and confirm the new dist appears in the lockfile.
- [x] 1.2 Add `"usocket"` to the `:depends-on` list in `ece.asd` so the system loads it when the `ece` ASDF system is built.
- [x] 1.3 Add the eight new entries to `primitives.def` at ids 229–236 in a dedicated `DEV-TOOLING PRIMITIVES` section, all marked platform `cl`.

## 2. Helper defuns and primitive templates

- [x] 2.1 Add helper defuns to `src/runtime.lisp` immediately before the `(load primitives-auto-path)` block: `ece-tcp-recv-nowait-impl`, `ece-tcp-send-nowait-impl`, `ece-fs-watch-start-impl`, `ece-fs-watch-poll-impl`, `ece-fs-watch-stop-impl`, plus `*fs-watchers*` and `*fs-watcher-counter*` defvars to back the watcher registry.
- [x] 2.2 Implement `ece-tcp-recv-nowait-impl` using `usocket:wait-for-input :timeout 0 :ready-only t` for readiness detection and `(read-byte stream nil nil)` to distinguish "data ready" from "peer closed". The naive approach using only `(listen stream)` does NOT detect peer close — verified by the `test-tcp-recv-eof-on-closed-peer` test catching that bug on the first implementation attempt.
- [x] 2.3 Add `define-host-primitive` templates to `src/primitives.scm` in a new `Dev-tooling (ids 229-236)` section. The TCP primitives wrap `usocket` directly; `tcp-recv-nowait` / `tcp-send-nowait` and the `fs-watch-*` templates delegate to the helper defuns from 2.1.

## 3. Bridge primitives-auto.lisp and verify codegen

- [x] 3.1 Hand-add the eight `defun ece-NAME` forms to `bootstrap/primitives-auto.lisp` so the runtime loads with the new manifest entries. This is a one-time bridge — the next regen overwrites with codegen output.
- [x] 3.2 Run `make ece` (or just `qlot exec sbcl --eval '(asdf:load-system :ece)'`) and confirm the runtime loads cleanly with the new entries — `validate-primitive-dispatch-tables` does not error.
- [x] 3.3 Run `touch src/primitives.scm && make bootstrap/primitives-auto.lisp` to regenerate from templates. Verify the regenerated file is byte-stable across two consecutive regenerations (idempotent codegen check).

## 4. Tests

- [x] 4.1 Add `test-tcp-listen-accept-roundtrip` to `tests/ece.lisp`: bind on port 0, no client → `accept-nowait` returns scheme `#f`, then a CL-side usocket client connects, server accepts, client→server→client byte round-trip via `tcp-send-nowait` / `tcp-recv-nowait`. Cleanup closes everything.
- [x] 4.2 Add `test-tcp-recv-would-block`: open a client, accept on the server, immediately call `tcp-recv-nowait` on the new connection. Expected result: `:would-block`.
- [x] 4.3 Add `test-tcp-recv-eof-on-closed-peer`: open a client, accept on the server, close the client. Server's `tcp-recv-nowait` must return `:eof` (not `:would-block`).
- [x] 4.4 Add `test-fs-watch-detects-modification`: create a temp file, start the watcher, sleep past the 1-second `file-write-date` granularity, rewrite the file, poll. Expected: the path appears in the result. A second poll without further modification returns the empty list.
- [x] 4.5 Add `test-fs-watch-stop-discards-watcher`: start a watcher, immediately stop it, poll on the now-stopped id. Expected: empty list (no error).

## 5. Validation

- [x] 5.1 Run `make test-rove` and confirm 148 tests pass (143 baseline + 5 new dev-tools tests).
- [x] 5.2 Run `make test-ece` and confirm the count matches main (923 pass, 3 pre-existing continuation-size failures unrelated to this change).
- [x] 5.3 Run `make test-wasm` and confirm 782 tests pass with no new failures.
- [x] 5.4 Run `make test` (full suite: rove + ece + wasm + conformance + golden + server-mode + web-apps) and confirm no new regressions.

## 6. Update the parent `ece-serve` change

- [x] 6.1 In `openspec/changes/ece-serve/proposal.md`, change the bullet that says `ADDED a narrow set of CL-side primitives ...` to a `PRE-LANDED` note pointing at this change, mirroring how the sha1/base64 bullet was rewritten.
- [x] 6.2 In `openspec/changes/ece-serve/tasks.md`, mark all of section 1 (1.1–1.4) as `[x]` and add a header note that they were pre-landed via this change.
- [x] 6.3 In `openspec/changes/ece-serve/design.md`, leave Decision 4 essentially as-is (the primitive surface is unchanged), but add a one-line "**Pre-landed by `ece-serve-tcp-fs-primitives`**" note at the top of Decision 4 so future readers know where to find the implementation.

## 7. Archive and commit

- [x] 7.1 Archive this change in-PR via `/opsx:archive ece-serve-tcp-fs-primitives` (date stamp 2026-04-14) BEFORE merging, per the `feedback_archive_before_merge` rule.
- [x] 7.2 Commit the implementation, the new openspec change artifacts, and the `ece-serve` parent change updates as a single commit on the branch.
- [x] 7.3 Open the PR with the test results and a summary that points back at the parent `ece-serve` change. Reference the prior `sha1-base64-utilities` extraction as the precedent for this pattern.
