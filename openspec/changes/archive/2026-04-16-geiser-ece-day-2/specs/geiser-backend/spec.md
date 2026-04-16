## MODIFIED Requirements

### Requirement: geiser-completions returns prefix-filtered global symbols

The `geiser-completions` handler in `src/geiser-ece.scm` SHALL accept a prefix string and optional extra arguments, query `%global-env-symbols` for all global bindings, filter to those whose name starts with the prefix, sort alphabetically, and return the resulting list of strings. The Geiser elisp side SHALL wire `C-M-i` (completion-at-point) and REPL TAB to call this handler.

#### Scenario: Prefix match returns filtered results

- **WHEN** `(geiser-completions "string-")` is called
- **THEN** it SHALL return a sorted list of strings, each starting with `"string-"` (e.g., `"string-append"`, `"string-length"`, `"string-ref"`)

#### Scenario: Empty prefix returns all symbols

- **WHEN** `(geiser-completions "")` is called
- **THEN** it SHALL return a sorted list of all global symbol names

#### Scenario: No match returns empty list

- **WHEN** `(geiser-completions "zzz-nonexistent-prefix-xyz")` is called
- **THEN** it SHALL return the empty list `()`

#### Scenario: C-M-i triggers completions in emacs

- **WHEN** user types `(str` in a `.scm` buffer and presses `C-M-i`
- **THEN** Geiser SHALL display a completion popup containing symbol names starting with `"str"` (e.g., `"string-append"`, `"string-length"`)
