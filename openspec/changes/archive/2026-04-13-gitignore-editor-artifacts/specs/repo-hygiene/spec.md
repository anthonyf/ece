## ADDED Requirements

### Requirement: Editor and tooling temporary files SHALL be gitignored
The repository's root `.gitignore` SHALL include patterns that exclude editor temporary files and local tooling state from `git status`, so a clean working tree on `main` reports no untracked files after a routine editing or tooling session.

#### Scenario: Emacs auto-save backup exists
- **WHEN** a developer has an open Emacs buffer with unsaved changes on any file in the repository
- **AND** Emacs has written its canonical auto-save file (`#filename#`) next to the source
- **THEN** `git status` SHALL NOT list the auto-save file as untracked

#### Scenario: Emacs lockfile exists
- **WHEN** a developer has an open Emacs buffer visiting any file in the repository
- **AND** Emacs has created its canonical lockfile (`.#filename`) next to the source
- **THEN** `git status` SHALL NOT list the lockfile as untracked

#### Scenario: Claude Code scheduler lockfile exists
- **WHEN** the Claude Code CLI is running and has written its internal scheduler lock at `.claude/scheduled_tasks.lock`
- **THEN** `git status` SHALL NOT list that lockfile as untracked
