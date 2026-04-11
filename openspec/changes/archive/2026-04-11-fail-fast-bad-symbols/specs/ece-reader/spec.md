## ADDED Requirements

### Requirement: read rejects stray backslash in bare symbols
The ECE reader SHALL signal a read-time error when a backslash character (`\`) appears inside a bare (non-pipe-quoted, non-string, non-character) symbol token. The error message SHALL name the offending character and include source location when `*source-file-name*` is set. Character literals (`#\X`) and string escapes (`"\n"`, `"\\"`) retain their existing behavior.

#### Scenario: Stray backslash in symbol at top level
- **WHEN** `(read (open-input-string "foo\\!"))` is evaluated
- **THEN** the reader SHALL signal an error whose message mentions `"invalid character in symbol"` and the backslash character

#### Scenario: Backslash as initial character
- **WHEN** the reader encounters a token beginning with `\` in a context expecting a symbol
- **THEN** the reader SHALL signal the same error as when backslash appears mid-token

#### Scenario: Backslash in string literal still works
- **WHEN** `(read (open-input-string "\"a\\nb\""))` is evaluated
- **THEN** the result SHALL be the string `"a\nb"` (existing escape behavior preserved)

#### Scenario: Character literal still works
- **WHEN** `(read (open-input-string "#\\x"))` is evaluated
- **THEN** the result SHALL be the character `#\x` (existing character-literal behavior preserved)

#### Scenario: Source location reported when reading from a file
- **WHEN** a `.scm` file contains a symbol with a stray backslash and is loaded via `(load "file.scm")` or `compile-file`
- **THEN** the error message SHALL identify the file, line, and column of the offending symbol
