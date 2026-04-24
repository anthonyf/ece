# Sandbox-Friendly Dev Workflow

**Date:** 2026-04-23
**Status:** Designed, ready for implementation plan
**Scope:** small — one Makefile edit + one assistant-memory file

## Context

Working with Claude on this project has been leaking sandbox-permission prompts whenever an SBCL/qlot/make command runs. Two root causes:

1. **Assistant over-caution:** the Makefile already exports `ASDF_OUTPUT_TRANSLATIONS` (line 82-83) so that FASLs land in project-local `.fasl-cache/` (sandbox-writable). `make ece`, `make test`, etc. should run in-sandbox with no manual env-var juggling. But the assistant has been pre-emptively passing `dangerouslyDisableSandbox: true` on every make/sbcl call defensively.

2. **Real gap in the Makefile:** `qlot install` is not covered by any make target. Fresh worktrees (and fresh clones) need it, but the assistant has to invoke `qlot install` directly — outside the Makefile's exported env — so SBCL in that process falls back to its default FASL cache path `~/.cache/common-lisp/`, which IS sandbox-denied.

## Goals

1. Running `make ece` / `make test` / `make bootstrap` etc. on a fresh worktree should "just work" in-sandbox — no manual setup step, no sandbox-disable.
2. The assistant stops pre-emptively disabling sandbox on make/sbcl calls. It only reaches for `dangerouslyDisableSandbox: true` when a command actually fails with a sandbox error.

## Non-goals

- Running fully sandbox-clean for `make test-web-server` (binds a TCP socket — fundamentally needs sandbox off for this session's config). Out of scope.
- Automating `git worktree add` (worktree creation is user-initiated; it lands in a sandbox-writable path by convention).
- Fixing the TLS cert issue that affects `gh` CLI. Separate concern.

## Design

### 1. Makefile change

Add a file-target sentinel for the qlot-installed state. Sentinel path is `.qlot/qlot.conf` — qlot produces it on every install and it stays put. No normal prerequisites: make runs the recipe only when the target is missing (fresh clone/worktree). If `qlfile.lock` is bumped, the user explicitly `rm -rf .qlot && make setup` (matches how most projects treat package-manager lockfiles):

```makefile
# qlot-install marker. Lives under project-local .qlot/ (sandbox-
# writable); the exported ASDF_OUTPUT_TRANSLATIONS ensures any SBCL
# invocation qlot makes during install writes FASLs to .fasl-cache/.
.qlot/qlot.conf:
	qlot install
	@test -f $@ || { echo "error: qlot install did not create $@"; exit 1; }
```

Make it an **order-only** prerequisite of every target that invokes `qlot exec sbcl` (using the `|` syntax — the sentinel gates build order, not rebuild decisions). Without order-only, the sentinel's mtime could force unrelated rebuilds:

- `bin/ece` (the file target behind `ece:`)
- `bootstrap/bootstrap.ecec` (the file target behind `bootstrap:`)
- Each test target that shells out to qlot: `test-rove`, `test-ece`, `test-conformance`, `test-golden`, `test-web-server`
- `wasm` if it invokes qlot (TBD — verify during implementation)
- `repl`, `run`, `run-lisp`
- The zone-regeneration sentinel under `bootstrap:`

Extend the existing `setup` target so explicit `make setup` is the canonical "prepare this worktree" call (order-only):

```makefile
setup: | .qlot/qlot.conf
	ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
	@echo "Pre-commit hook installed."
```

### 2. Assistant-memory change

Add `feedback_sandbox_trust.md` to the project memory folder:

> **Default:** run `make <target>` in-sandbox. The Makefile exports `ASDF_OUTPUT_TRANSLATIONS` so FASLs land in project-local `.fasl-cache/`, and common project paths (`.qlot/`, `.fasl-cache/`, `/tmp/claude/...` worktrees) are sandbox-writable.
>
> **Only disable sandbox when:** a command actually fails with a sandbox error (network denial, path not in allowlist); `gh` CLI over HTTPS (TLS cert issue, separate from sandbox); `make test-web-server` (binds a TCP socket).
>
> **Stop doing:** pre-emptively passing `dangerouslyDisableSandbox: true` on every `make` / SBCL call. Stop manually prepending `ASDF_OUTPUT_TRANSLATIONS=...` — the Makefile already exports it. Stop running raw `rm -rf .fasl-cache/` — the `make clean-fasl` target exists and does exactly that (it depends on `make clean`).

Update `MEMORY.md` to link the new entry under "User Interaction Preferences".

## Error handling

- If `qlot install` fails (e.g., network unreachable, qlfile.lock malformed): make stops with the error, user sees it, can re-run. No special handling needed.
- If the prerequisite chain causes an infinite re-install loop (e.g., qlot is not producing the expected sentinel file): mitigation is to verify the sentinel exists post-install during implementation testing. If qlot's file layout differs, pick a different sentinel.

## Testing

Manual verification:
1. `rm -rf .qlot .fasl-cache`
2. `make ece` — should run `qlot install` automatically then proceed with the normal build.
3. Assistant in a fresh session runs `make test` — should not hit any sandbox prompt.

No automated test harness for this (it's a workflow change, not a feature).

## Scope / complexity

Genuinely small:
- Makefile: ~10 lines added (file target + dep-list edits).
- Memory: one new markdown file + one line in MEMORY.md.

Could have been a commit without any design doc, but following the Superpowers flow for consistency.
