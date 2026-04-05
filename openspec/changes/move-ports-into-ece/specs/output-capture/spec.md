## ADDED Requirements

### Requirement: with-output-to-string captures display output
`with-output-to-string` SHALL execute its body expressions with `current-output-port` rebound to a fresh string output port, then return the accumulated string.

#### Scenario: Captures a single display call
- **WHEN** `(with-output-to-string (display "hello"))` is evaluated
- **THEN** the result SHALL be the string `"hello"`

#### Scenario: Captures multiple writes
- **WHEN** `(with-output-to-string (display "a") (display "b") (newline))` is evaluated
- **THEN** the result SHALL be the string `"ab\n"`

#### Scenario: Captures write in readable form
- **WHEN** `(with-output-to-string (write "hi"))` is evaluated
- **THEN** the result SHALL be the string `"\"hi\""` (with escape-visible quotes)

#### Scenario: Does not leak captured port after body exits
- **GIVEN** `(with-output-to-string (display "x"))` has returned
- **WHEN** `(display "y")` is subsequently evaluated at top level
- **THEN** the output SHALL go to the original `current-output-port` (stdout), not the captured string port

### Requirement: with-output-to-string isolates nested captures
Nested `with-output-to-string` invocations SHALL each capture only the output from their own body, restoring the outer port on exit.

#### Scenario: Nested capture produces disjoint strings
- **WHEN** `(with-output-to-string (display "outer-pre") (let ((inner (with-output-to-string (display "inner")))) (display "outer-post") inner))` is evaluated
- **THEN** the returned value of the `let` binding SHALL be `"inner"`
- **AND** the string returned by the outer `with-output-to-string` SHALL be `"outer-preouter-post"`

### Requirement: with-output-to-string restores port on non-local exit
If the body of `with-output-to-string` exits non-locally (via `raise`, captured continuation, or error), `current-output-port` SHALL be restored to its prior value by the `parameterize` / `dynamic-wind` machinery.

#### Scenario: Error inside body restores outer port
- **GIVEN** a guard handler that catches errors
- **WHEN** `(guard (e (#t 'caught)) (with-output-to-string (display "before") (raise 'boom)))` is evaluated
- **THEN** the result SHALL be `caught`
- **AND** `(current-output-port)` AFTER the guard form SHALL equal its value BEFORE the `with-output-to-string`

### Requirement: with-input-from-string feeds input from a string
`with-input-from-string` SHALL execute its body expressions with `current-input-port` rebound to a fresh string input port initialized with the given string.

#### Scenario: Reads characters from string
- **WHEN** `(with-input-from-string "abc" (read-char))` is evaluated
- **THEN** the result SHALL be the character `#\a`

#### Scenario: Reads structured data from string
- **WHEN** `(with-input-from-string "(1 2 3)" (read))` is evaluated
- **THEN** the result SHALL be the list `(1 2 3)`

### Requirement: with-output-to-port and with-input-from-port
`with-output-to-port` SHALL execute body with `current-output-port` bound to an explicitly-supplied port. `with-input-from-port` SHALL do the same for input.

#### Scenario: with-output-to-port redirects to caller-supplied port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(with-output-to-port p (display "hi"))` then `(get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hi"`

#### Scenario: with-input-from-port reads from caller-supplied port
- **GIVEN** `(define p (open-input-string "xyz"))`
- **WHEN** `(with-input-from-port p (read-char))` is evaluated
- **THEN** the result SHALL be `#\x`
