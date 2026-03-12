## ADDED Requirements

### Requirement: List accessors defined in prelude
The prelude SHALL define `cadr`, `caddr`, `caar`, `cddr`, `list-ref`, and `list-tail` as ECE functions, replacing the CL primitive registrations.

#### Scenario: cadr returns second element
- **WHEN** `(cadr (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `2`

#### Scenario: list-ref accesses by index
- **WHEN** `(list-ref (list 10 20 30) 2)` is evaluated
- **THEN** the result SHALL be `30`

#### Scenario: list-tail returns sublist
- **WHEN** `(list-tail (list 10 20 30) 1)` is evaluated
- **THEN** the result SHALL be `(20 30)`

### Requirement: Core list functions defined in prelude
The prelude SHALL define `reverse`, `length`, `append`, `member`, and `assoc` as ECE functions, replacing the CL primitive registrations. These SHALL appear before `map`/`filter` which depend on `reverse`.

#### Scenario: reverse a list
- **WHEN** `(reverse (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `(3 2 1)`

#### Scenario: length of a list
- **WHEN** `(length (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `3`

#### Scenario: append two lists
- **WHEN** `(append (list 1 2) (list 3 4))` is evaluated
- **THEN** the result SHALL be `(1 2 3 4)`

#### Scenario: member finds element
- **WHEN** `(member 2 (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `(2 3)`

#### Scenario: assoc finds entry
- **WHEN** `(assoc 'b (list (list 'a 1) (list 'b 2)))` is evaluated
- **THEN** the result SHALL be `(b 2)`

### Requirement: Derived predicates defined in prelude
The prelude SHALL define `not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, and `>=` as ECE functions, replacing the CL primitive registrations.

#### Scenario: not negates truthy
- **WHEN** `(not t)` is evaluated
- **THEN** the result SHALL be `()`

#### Scenario: not negates falsy
- **WHEN** `(not ())` is evaluated
- **THEN** the result SHALL be `t`

#### Scenario: zero? on zero
- **WHEN** `(zero? 0)` is evaluated
- **THEN** the result SHALL be `t`

#### Scenario: even? and odd?
- **WHEN** `(even? 4)` and `(odd? 3)` are evaluated
- **THEN** both SHALL return `t`

#### Scenario: <= and >= comparisons
- **WHEN** `(<= 3 3)` and `(>= 5 3)` are evaluated
- **THEN** both SHALL return `t`

### Requirement: Math helpers defined in prelude
The prelude SHALL define `abs`, `min`, and `max` as ECE functions. `min` and `max` SHALL accept variadic arguments (one or more).

#### Scenario: abs of negative
- **WHEN** `(abs -5)` is evaluated
- **THEN** the result SHALL be `5`

#### Scenario: min of multiple values
- **WHEN** `(min 3 1 4 1 5)` is evaluated
- **THEN** the result SHALL be `1`

#### Scenario: max of multiple values
- **WHEN** `(max 3 1 4 1 5)` is evaluated
- **THEN** the result SHALL be `5`

### Requirement: Hash table operations defined in prelude
The prelude SHALL define `hash-table`, `hash-table?`, `hash-ref`, `hash-set!`, `hash-set`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, and `hash-remove!` as ECE functions, replacing the CL wrapper functions. These operate on alist-based `(:hash-table . alist)` structures. These definitions SHALL appear before `define-record` which depends on them.

#### Scenario: hash-table constructor
- **WHEN** `(hash-table 'a 1 'b 2)` is evaluated
- **THEN** the result SHALL be an alist-based hash table with keys `a` and `b`

#### Scenario: hash-ref lookup
- **WHEN** `(hash-ref (hash-table 'x 42) 'x)` is evaluated
- **THEN** the result SHALL be `42`

#### Scenario: hash-set! mutates in place
- **WHEN** a hash table is mutated with `hash-set!`
- **THEN** the original hash table object SHALL reflect the change

#### Scenario: hash-keys returns all keys
- **WHEN** `(hash-keys (hash-table 'a 1 'b 2))` is evaluated
- **THEN** the result SHALL be a list containing `a` and `b`
