## 1. .gitignore update

- [x] 1.1 Append a new `# Editor / tooling artefacts` section to `.gitignore` (root) with three entries. Note: the leading `#` in Emacs patterns is escaped (`\#*\#`, `.\#*`) because a bare leading `#` starts a `.gitignore` comment.
- [x] 1.2 Verified the three specific files are no longer listed as untracked (they still exist on disk — checked via `ls` — but `git status` no longer reports them).
- [x] 1.3 Verified `git status` reports only the expected modifications (the `.gitignore` edit and the new `openspec/changes/archive/2026-04-13-gitignore-editor-artifacts/` directory).

## 2. Archive and commit

- [x] 2.1 Archived in-PR to `openspec/changes/archive/2026-04-13-gitignore-editor-artifacts/`.
- [x] 2.2 Commit with a short message describing the fix.
- [x] 2.3 Open a PR with the diff and a note that this is a no-op cleanup.
