## MODIFIED Requirements

### Requirement: REPL buffer displays clean results

The Geiser REPL buffer SHALL display evaluation results in clean form, not as raw wire protocol alists. Side-effect output SHALL appear before the result value.

#### Scenario: Simple eval shows clean result

- **WHEN** user types `(+ 1 2)` in the REPL buffer and presses Enter
- **THEN** the REPL buffer SHALL display `3`, not `((result "3") (output . ""))`

#### Scenario: Eval with side-effect output

- **WHEN** user types `(begin (display "hello") 42)` in the REPL buffer
- **THEN** the REPL buffer SHALL display `hello` followed by `42`

#### Scenario: Void result shows nothing

- **WHEN** user types `(define x 1)` in the REPL buffer
- **THEN** the REPL buffer SHALL display nothing, not a raw alist

#### Scenario: Parse failure falls back to raw display

- **WHEN** the REPL emits output that cannot be parsed as an alist
- **THEN** the REPL buffer SHALL display the raw output unchanged
