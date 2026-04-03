## ADDED Requirements

### Requirement: Vector do-loop conformance test is active
The conformance suite SHALL include the R5RS `do` loop test that builds a vector via `make-vector` and `vector-set!`, comparing the result with `equal?`.

#### Scenario: do-loop vector construction
- **WHEN** `(do ((vec (make-vector 5)) (i 0 (+ i 1))) ((= i 5) vec) (vector-set! vec i i))` is evaluated
- **THEN** the result SHALL be `equal?` to `#(0 1 2 3 4)`

### Requirement: Vector equal? conformance test is active
The conformance suite SHALL include a test verifying deep structural equality of vectors.

#### Scenario: equal? on identical vectors
- **WHEN** `(equal? (make-vector 5 'a) (make-vector 5 'a))` is evaluated
- **THEN** the result SHALL be `#t`

### Requirement: Vector-set! with nested data conformance test is active
The conformance suite SHALL include the R5RS vector mutation example with nested list data.

#### Scenario: vector-set! with list value
- **WHEN** a vector is created with `(vector 0 '(2 2 2 2) "Anna")` and slot 1 is set to `'("Sue" "Sue")`
- **THEN** the result SHALL be `equal?` to `#(0 ("Sue" "Sue") "Anna")`

### Requirement: list->vector conformance test is active
The conformance suite SHALL include the R5RS `list->vector` conversion test.

#### Scenario: list->vector round-trip
- **WHEN** `(list->vector '(dididit dah))` is evaluated
- **THEN** the result SHALL be `equal?` to `#(dididit dah)`

### Requirement: for-each vector mutation conformance test is active
The conformance suite SHALL include the R5RS `for-each` + `vector-set!` test producing squared values.

#### Scenario: for-each builds squared vector
- **WHEN** `(let ((v (make-vector 5))) (for-each (lambda (i) (vector-set! v i (* i i))) '(0 1 2 3 4)) v)` is evaluated
- **THEN** the result SHALL be `equal?` to `#(0 1 4 9 16)`

### Requirement: Dead skip mechanism is removed
The conformance framework SHALL NOT contain unused `conformance-skip!` infrastructure.

#### Scenario: No skip-related symbols in framework
- **WHEN** `conformance-framework.scm` is inspected
- **THEN** it SHALL NOT define `conformance-skip!`, `conformance-skipped?`, `*conformance-skip-list*`, or `*conformance-skips*`
