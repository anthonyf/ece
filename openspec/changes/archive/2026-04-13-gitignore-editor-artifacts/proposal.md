## Why

Three categories of local-only files consistently show up in `git status` on a clean main branch and add noise to every session:

- `slides/#presentation.md#` — Emacs auto-save backup (created whenever `slides/presentation.md` is edited with unsaved changes)
- `slides/.#presentation.md` — Emacs lockfile (symlink created while a buffer visits the file)
- `.claude/scheduled_tasks.lock` — Claude Code internal scheduler lock file

None of these should ever be committed. They're either transient (Emacs) or internal tooling state (Claude). Over the last few sessions they've all sat in the "Untracked files" section of `git status`, cluttering the output and making it harder to spot genuinely-new files.

## What Changes

- **MODIFIED** `.gitignore` — add three patterns:
  - `#*#` — Emacs auto-save backups anywhere in the tree
  - `.#*` — Emacs lockfiles anywhere in the tree
  - `.claude/scheduled_tasks.lock` — Claude's scheduler lock specifically

The globs for Emacs cover the canonical naming convention (`#name.ext#` for auto-save, `.#name.ext` for lockfiles) so editing any file anywhere in the repo won't leave untracked artefacts.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
None — this is a build/tooling hygiene fix, no runtime behaviour or capability surface changes.

## Impact

- **Affected code**: single file, `.gitignore`.
- **Affected workflows**: cleaner `git status` output. No functional change to build, test, run, or any tooling.
- **Risk**: near zero. Adding ignore patterns can't break anything already working; the three patterns are narrow enough not to mask files a developer actually wants to track.
- **Rollback**: revert the three added lines. Trivial.
