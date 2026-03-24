## MODIFIED Requirements

### Requirement: Named let uses lexical binding (not define-variable!)
Named `let` SHALL expand to a letrec-style pattern that binds the loop name as a lambda parameter with `set!`, NOT as a `define` that requires runtime `define-variable!`.

#### Scenario: Nested named-let doesn't use define-variable!
- **WHEN** a named-let appears nested inside another expression (e.g., as an argument to a function call)
- **THEN** the loop name SHALL be bound via lexical `set!`, not `define-variable!`
- **AND** the compiled code SHALL use `lexical-ref`/`lexical-set!` for the loop name, not `lookup-variable-value`/`define-variable!`

#### Scenario: Named-let in tail position still has TCO
- **WHEN** evaluating `(let loop ((n 1000000)) (if (= n 0) 'done (loop (- n 1))))`
- **THEN** the result SHALL be `done` without stack overflow

#### Scenario: Named-let as argument to function call
- **WHEN** evaluating `(string-append "(" (let loop ((xs (list 1)) (first #t)) (if (null? xs) ")" (string-append (if first "" " ") (write-to-string-flat (car xs)) (loop (cdr xs) #f)))))`
- **THEN** the result SHALL be `"(1)"`
- **AND** execution SHALL NOT crash
