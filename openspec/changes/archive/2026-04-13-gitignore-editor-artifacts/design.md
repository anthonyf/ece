## Context

The root `.gitignore` already covers build artefacts (`*.fasl`, `/.fasl-cache/`, `/.tmp/`, `/bin/ece*`, etc.) and generated files (`wasm/runtime.wasm`, `sandbox/ece-*.js`, `/share/`). It does not cover editor temporary files, so any Emacs user editing `.md` or `.scm` files leaves auto-save and lockfile artefacts in the tree. Similarly, the Claude Code CLI writes a scheduler lock under `.claude/` which is also not gitignored.

The fix is a single-file edit to `.gitignore`. No tooling changes, no build changes, no spec deltas.

## Goals / Non-Goals

**Goals:**
- Stop `slides/#presentation.md#`, `slides/.#presentation.md`, and `.claude/scheduled_tasks.lock` from appearing in `git status`.
- Use patterns narrow enough that they only cover the intended artefacts and don't accidentally ignore files developers actually want to track.

**Non-Goals:**
- No attempt to centralise editor-config hygiene into `.gitattributes` or an editor-specific directory.
- No changes to how Emacs or Claude Code manage their lockfiles — they keep writing them; git just stops reporting them.
- No broad wildcard ignores (`*.bak`, `*~`, etc.) unless the user also wants them. The minimal change targets only what's currently showing up.

## Decisions

### 1. Glob patterns for Emacs, exact path for Claude

**Choice:**
- `#*#` — matches Emacs auto-save files anywhere in the tree (canonical naming: `#filename#`).
- `.#*` — matches Emacs lockfiles anywhere in the tree (canonical naming: `.#filename`, usually a symlink).
- `.claude/scheduled_tasks.lock` — exact path for Claude's scheduler lock.

**Rationale:** Emacs auto-save and lockfile names are well-defined by the editor and don't conflict with any sensible real filename (`#foo#` isn't a name anyone uses for source files). Globbing covers the full tree without false positives.

The Claude lock is a single known file under a specific directory, so an exact path is cleaner than adding `.claude/**/*.lock` or similar. If Claude starts creating other lock files, we can broaden the pattern then.

**Alternatives considered:**
- **Ignore the whole `.claude/` directory.** Rejected — `.claude/` contains useful user-specific settings (`settings.local.json`, `skills/`, etc.) that aren't currently tracked but might be in the future. Ignoring the whole directory would make future tracking harder. Ignoring a specific file keeps the door open.
- **Use `*.lock` globally.** Rejected — `qlfile.lock` and `package-lock.json` (if added later) are common names that DO want to be tracked.

### 2. Put the new entries at the bottom of `.gitignore`

**Choice:** Append the three patterns to the end of `.gitignore`, in a section labelled `# Editor / tooling artefacts`.

**Rationale:** The existing file has build-related patterns at the top. Keeping editor/tooling patterns separate and clearly commented makes the file easier to audit.

## Risks / Trade-offs

- **Glob shadowing risk:** If a future source file is named something like `#data#` or `.#config`, these patterns would ignore it. Very unlikely (nobody names source files that way), but noted.
- **Wider discoverability:** These patterns only silence files that are already being produced locally. If a contributor uses a different editor (VS Code, vim) that produces different artefacts (`.swp`, `.DS_Store`, etc.), they'll still see those in `git status`. This change doesn't try to solve for every editor — adding more patterns can happen incrementally.

## Migration Plan

Not applicable. Adding ignore patterns is purely additive and takes effect on the next `git status` call.

## Open Questions

- **Should there be a global `$HOME/.gitignore_global` instead?** That's the proper place for user-specific editor preferences (so they apply to every repo the user works on), and git has `git config --global core.excludesfile` for it. The user could adopt that pattern separately. For this change, the repo-local approach is faster and covers everyone who checks out the codebase.
