## MODIFIED Requirements

### Requirement: scoped port redirection
`with-input-from-file` SHALL open a file, set it as the current input port for the duration of a thunk, then close it. `with-output-to-file` SHALL do the same for output. The thunk MAY be a compiled procedure, a primitive procedure, or a continuation — the dispatch SHALL handle all procedure types.

#### Scenario: with-input-from-file redirects input
- **WHEN** a file contains "hello" and `(with-input-from-file "test.txt" (lambda () (read-char)))` is evaluated
- **THEN** `read-char` SHALL read from the file, returning the first character

#### Scenario: with-input-from-file restores port after thunk
- **WHEN** `with-input-from-file` completes (or errors)
- **THEN** `current-input-port` SHALL be restored to its previous value

#### Scenario: with-output-to-file with compiled thunk
- **WHEN** `(with-output-to-file "out.txt" (lambda () (display "hi")))` is evaluated where the lambda is a compiled procedure
- **THEN** the thunk SHALL execute successfully, writing "hi" to the file

#### Scenario: with-input-from-file with compiled thunk
- **WHEN** `(with-input-from-file "in.txt" (lambda () (read-char)))` is evaluated where the lambda is a compiled procedure
- **THEN** the thunk SHALL execute successfully, reading from the file
