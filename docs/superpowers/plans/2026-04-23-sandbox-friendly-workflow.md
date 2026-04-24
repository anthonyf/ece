# Sandbox-Friendly Dev Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close the qlot-install gap in the Makefile so fresh worktrees self-bootstrap in-sandbox, and update assistant memory so sandbox-disable stops being reflexive.

**Architecture:** One file-target sentinel in the Makefile (`.qlot/qlot.conf` as the proof-of-install marker) wired as a prerequisite of every qlot-using target. One new memory file documenting the new default behavior. One MEMORY.md index line linking to it.

**Tech Stack:** GNU make, qlot (Quicklisp manager), Claude memory markdown files.

**Spec:** `docs/superpowers/specs/2026-04-23-sandbox-friendly-workflow-design.md`
**Base branch:** `sandbox-friendly-workflow` (already created off main; spec committed at `b07dfa1`-ish — verify with `git log --oneline -3`).

---

## File Structure

Files this plan touches:

- Modify: `Makefile` — add `.qlot/qlot.conf` file target, add it as a prerequisite of qlot-using targets.
- Create: `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_sandbox_trust.md`
- Modify: `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md` — add link under "User Interaction Preferences".

---

## Task 1: Add qlot-install sentinel to Makefile

**Files:**
- Modify: `/Users/anthonyfairchild/git/ece/Makefile`

### Step 1.1: Locate insertion point

Run:
```
grep -n '^export ASDF_OUTPUT\|^\.fasl-cache' /Users/anthonyfairchild/git/ece/Makefile
```

Expected: line 83 is the `export ASDF_OUTPUT_TRANSLATIONS = ...` line. Insertion point is immediately after it — we want the `.qlot/qlot.conf` rule to benefit from the exported env var.

### Step 1.2: Add the sentinel rule

Insert just after the `export ASDF_OUTPUT_TRANSLATIONS` line:

```makefile

# qlot-install marker. `.qlot/qlot.conf` is produced by `qlot install`
# and stays put across runs, so it's a reliable sentinel. Re-runs
# whenever qlfile.lock changes (e.g. after a dep bump), otherwise it's
# a no-op. Lives under project-local .qlot/ (sandbox-writable); the
# exported ASDF_OUTPUT_TRANSLATIONS above ensures any SBCL invocation
# qlot makes during install writes FASLs to .fasl-cache/ too.
.qlot/qlot.conf: qlfile.lock
	qlot install
```

### Step 1.3: Verify sentinel is a real post-install file

Run:
```
ls /Users/anthonyfairchild/git/ece/.qlot/qlot.conf
```

Expected: file exists (proves the sentinel is a valid target; if missing in your environment, swap for `.qlot/quicklisp/setup.lisp` which also reliably exists post-install).

### Step 1.4: Run make to verify no regression

```
cd /Users/anthonyfairchild/git/ece && make -n ece 2>&1 | tail -5
```

Expected: clean. `-n` dry-run confirms the Makefile parses without error. If make complains about the new rule, fix syntax (tabs for recipe lines!) before proceeding.

### Step 1.5: Commit

```
cd /Users/anthonyfairchild/git/ece
git add Makefile
git commit -m "Makefile: add qlot-install sentinel

.qlot/qlot.conf serves as a file-target marker for \`qlot install\`
completion. Re-runs if qlfile.lock changes, otherwise no-op.
Wired into qlot-using targets in the next commit.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Wire the sentinel as a prerequisite of qlot-using targets

**Files:**
- Modify: `/Users/anthonyfairchild/git/ece/Makefile`

### Step 2.1: Enumerate qlot-using targets

Run:
```
grep -n 'qlot exec sbcl\|^[a-zA-Z].*:$\|^[a-zA-Z].*:[^=]' /Users/anthonyfairchild/git/ece/Makefile | head -40
```

Expected matches (based on the earlier survey): `bin/ece:`, `bootstrap:`, `wasm:` if it uses qlot, `test-rove:`, `test-ece:`, `test-conformance:`, `test-golden:`, `test-web-server:`, `repl:`, `run:`, `run-lisp:`, the zone-regen sentinel under bootstrap, and any other target whose recipe contains `qlot exec sbcl`.

Record the full list — you'll add a prerequisite to each.

### Step 2.2: Add `.qlot/qlot.conf` as a prereq to each target

For each target whose recipe invokes `qlot exec sbcl`, add `.qlot/qlot.conf` to its prerequisite list.

Patterns to apply:

- **Targets with existing prerequisites** (e.g., `bin/ece: scripts/build-ece-binary.lisp bootstrap/bootstrap.ecec share/ece/ece-main.ecec`): append `.qlot/qlot.conf` to the list:
  ```makefile
  bin/ece: scripts/build-ece-binary.lisp bootstrap/bootstrap.ecec share/ece/ece-main.ecec .qlot/qlot.conf
  ```
- **Targets with no prerequisites** (e.g., `test-rove:`): add one:
  ```makefile
  test-rove: .qlot/qlot.conf
  ```
- **`.PHONY` list**: already includes `setup` — no change needed.

Do NOT add the prerequisite to targets that don't invoke `qlot exec sbcl` (e.g., `clean`, `clean-fasl`, pure `.PHONY` aliases).

Do NOT add it recursively to file-targets that already depend on a target that has it (e.g., if `ece:` has it and `bin/ece:` is the real target, the prereq goes on `bin/ece:` not both).

### Step 2.3: Extend `setup:` to include the sentinel

Current:
```makefile
setup:
	ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
	@echo "Pre-commit hook installed."
```

Replace with:
```makefile
setup: .qlot/qlot.conf
	ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
	@echo "Pre-commit hook installed."
```

### Step 2.4: Dry-run verify

```
cd /Users/anthonyfairchild/git/ece && make -n setup 2>&1 | head -5
```

Expected (since .qlot/qlot.conf already exists locally): only the ln/echo lines in output. If `qlot install` shows up in the dry-run despite the file existing, the prerequisite is mis-spelled.

```
cd /Users/anthonyfairchild/git/ece && make -n ece 2>&1 | tail -10
```

Expected: normal ece build steps, no `qlot install` (because .qlot/qlot.conf exists).

### Step 2.5: Simulate a fresh worktree to confirm self-bootstrap

This is the important end-to-end test. Don't actually delete the main checkout's `.qlot/`. Instead create a worktree and test there:

```
git worktree add -b sandbox-sentinel-test /tmp/claude/ece-worktrees/sentinel-test main
cd /tmp/claude/ece-worktrees/sentinel-test
# Fresh worktree has no .qlot/, so:
ls .qlot 2>&1  # expected: "No such file or directory"
make -n setup 2>&1 | head -3  # expected: output mentions `qlot install`
```

If make plans to run `qlot install` — that confirms the prereq is wired. Actually running `make setup` in the test worktree is optional; the dry-run plus the file-target being correctly scheduled is sufficient.

Clean up:
```
cd /Users/anthonyfairchild/git/ece
git worktree remove /tmp/claude/ece-worktrees/sentinel-test
git branch -D sandbox-sentinel-test
```

### Step 2.6: Commit

```
cd /Users/anthonyfairchild/git/ece
git add Makefile
git commit -m "Makefile: wire qlot-install sentinel as prereq of qlot-using targets

make ece / make test / make bootstrap / make repl etc. now self-
bootstrap qlot on fresh worktrees. Closes the gap where qlot install
had to be run manually outside the Makefile's exported
ASDF_OUTPUT_TRANSLATIONS env.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Add `feedback_sandbox_trust.md` memory

**Files:**
- Create: `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_sandbox_trust.md`

### Step 3.1: Write the file

```markdown
---
name: Trust the Makefile's sandbox setup; stop pre-emptively disabling sandbox
description: The ECE Makefile exports ASDF_OUTPUT_TRANSLATIONS so project-local FASL cache works in-sandbox; run make targets in-sandbox by default and only disable sandbox when a command actually fails with a sandbox error
type: feedback
---

**Default:** run `make <target>` in-sandbox. The Makefile exports `ASDF_OUTPUT_TRANSLATIONS` (line 82-83 in Makefile) so FASLs land in project-local `.fasl-cache/`. Common project paths — `.qlot/`, `.fasl-cache/`, and `/tmp/claude/...` worktrees — are sandbox-writable. Fresh worktrees self-bootstrap via the Makefile's `.qlot/qlot.conf` sentinel; `make setup` (or any qlot-using target) runs `qlot install` under the right env.

**Only disable sandbox when:**

1. A command actually fails with a sandbox error (filesystem permission denial, path not in the allowlist, network denial for an non-allowed host).
2. `gh` CLI over HTTPS — separate TLS cert issue, not a sandbox issue; `dangerouslyDisableSandbox: true` is the workaround.
3. `make test-web-server` — binds a TCP socket, so needs sandbox off for this machine's config.

**Stop doing:**

- Pre-emptively passing `dangerouslyDisableSandbox: true` on every `make` / SBCL call. If the Makefile is run in-sandbox, it works — the project is set up for that.
- Manually prepending `ASDF_OUTPUT_TRANSLATIONS=...` to `make` invocations. The Makefile already `export`s it; prepending is redundant noise.
- Running raw `rm -rf .fasl-cache/` when clearing FASLs. Use `make clean-fasl` — the target exists and does exactly that (depends on `make clean`).

**Why:** session noise from permission prompts interrupts flow. User set up FASL redirection specifically to make in-sandbox runs work.

**How to apply:** When about to run a `make` or `sbcl` or `qlot` command, reach for it bare (no `dangerouslyDisableSandbox: true`, no env-var prepend). If it fails with a sandbox error, then disable sandbox for that specific command and figure out whether the Makefile needs a new target.
```

### Step 3.2: Verify the file exists

```
ls -la /Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/feedback_sandbox_trust.md
```

Expected: file present, non-empty.

---

## Task 4: Link from MEMORY.md

**Files:**
- Modify: `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md`

### Step 4.1: Locate insertion point

Run:
```
grep -n 'User Interaction Preferences\|feedback_check_copilot' /Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md | head
```

The `## User Interaction Preferences` section is where feedback memories are indexed. The most recently added entry is the Copilot-review one. Add the new entry after it.

### Step 4.2: Add the link

Use the Edit tool. `old_string` is the last line of the User Interaction Preferences list (the Copilot-review entry). `new_string` is that same line plus the new one appended:

```
old_string: - [Check Copilot review before merging](feedback_check_copilot_before_merge.md) — even with CI green, fetch Copilot's inline comments and address/defer each before running `gh pr merge`

new_string: - [Check Copilot review before merging](feedback_check_copilot_before_merge.md) — even with CI green, fetch Copilot's inline comments and address/defer each before running `gh pr merge`
- [Trust Makefile's sandbox setup](feedback_sandbox_trust.md) — run `make <target>` in-sandbox by default; only disable sandbox on actual failures; use `make clean-fasl` not raw `rm`
```

### Step 4.3: Verify

```
grep -c 'feedback_sandbox_trust' /Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/MEMORY.md
```

Expected: 1 match.

---

## Task 5: Final verification + push + PR

### Step 5.1: Confirm the branch contains the expected commits

```
cd /Users/anthonyfairchild/git/ece
git log --oneline main..HEAD
```

Expected (bottom to top):
```
<hash> Makefile: wire qlot-install sentinel as prereq of qlot-using targets
<hash> Makefile: add qlot-install sentinel
<hash> Add design spec: sandbox-friendly dev workflow
```

Memory-folder files are not in git (they live under `~/.claude/projects/...`). That's expected.

### Step 5.2: Sanity-check the Makefile edits

```
cd /Users/anthonyfairchild/git/ece
git diff main -- Makefile | head -40
```

Expected: shows the new `.qlot/qlot.conf:` rule and the added prerequisites on each qlot-using target. No other Makefile edits.

### Step 5.3: Push

```
cd /Users/anthonyfairchild/git/ece
git push -u origin sandbox-friendly-workflow
```

### Step 5.4: Open PR

```
cd /Users/anthonyfairchild/git/ece
gh pr create --base main --head sandbox-friendly-workflow --title "Makefile: self-bootstrap qlot install for sandbox-friendly dev" --body "$(cat <<'EOF'
## Summary

Closes the qlot-install gap in the Makefile: \`make ece\` / \`make test\` /
\`make bootstrap\` etc. on a fresh worktree or clone now auto-runs
\`qlot install\` under the Makefile's exported \`ASDF_OUTPUT_TRANSLATIONS\`
env. No more manual setup step, no more sandbox-disable prompts for
routine make invocations.

**Key change:** \`.qlot/qlot.conf\` is a file-target sentinel that depends
on \`qlfile.lock\`. Every target that invokes \`qlot exec sbcl\` gains it
as a prerequisite.

\`make setup\` now does both the pre-commit hook install AND (via the
sentinel) \`qlot install\` — one call prepares a fresh worktree for
everything.

## Test plan

- [x] make -n setup in main checkout (sentinel exists) — only echoes the
  ln/echo lines, no qlot install.
- [x] make -n setup in a fresh worktree with no .qlot/ — plans to run
  qlot install.
- [x] make -n ece behaves the same — no unexpected qlot install when
  sentinel exists.

## Specs

- docs/superpowers/specs/2026-04-23-sandbox-friendly-workflow-design.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review Notes

**Spec coverage:**
- Design §1 (Makefile change) → Tasks 1 and 2.
- Design §2 (memory change) → Tasks 3 and 4.
- Design §Error handling → implicit (qlot failures stop make normally).
- Design §Testing → Task 2.5 (worktree simulation) + Task 5.2 (diff sanity check).

**Placeholder scan:** none. Every step has concrete commands and code blocks.

**Type consistency:** the sentinel path `.qlot/qlot.conf` appears identically in Task 1.2, Task 2.2, Task 2.3, Task 2.4, Task 2.6 commit message, Task 5.2 diff check.

**Memory path:** `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/` is the ECE project's memory directory — verified in session context.
