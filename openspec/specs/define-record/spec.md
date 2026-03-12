## Requirements

### Requirement: define-record generates a constructor
`define-record` SHALL generate a constructor function `make-<name>` that accepts one argument per field and returns a hash table with a `type` key set to the record name and each field stored by its symbol name.

#### Scenario: Constructor creates a typed hash table
- **WHEN** `(define-record point x y)` is evaluated and `(make-point 10 20)` is called
- **THEN** the result SHALL be a hash table with `(hash-ref result 'type)` equal to `'point`, `(hash-ref result 'x)` equal to `10`, and `(hash-ref result 'y)` equal to `20`

#### Scenario: Constructor with no fields
- **WHEN** `(define-record empty)` is evaluated and `(make-empty)` is called
- **THEN** the result SHALL be a hash table with `(hash-ref result 'type)` equal to `'empty` and `(hash-count result)` equal to `1`

### Requirement: define-record generates a type predicate
`define-record` SHALL generate a predicate function `<name>?` that returns `#t` if the argument is a hash table with `type` equal to the record name, and `#f` otherwise.

#### Scenario: Predicate returns true for matching record
- **WHEN** `(define-record point x y)` is evaluated and `(point? (make-point 1 2))` is called
- **THEN** the result SHALL be `#t`

#### Scenario: Predicate returns false for non-matching value
- **WHEN** `(point? 42)` is called
- **THEN** the result SHALL be `#f` (or nil)

#### Scenario: Predicate returns false for different record type
- **WHEN** `(define-record point x y)` and `(define-record vec x y)` are evaluated and `(point? (make-vec 1 2))` is called
- **THEN** the result SHALL be `#f` (or nil)

### Requirement: define-record generates field accessors
`define-record` SHALL generate an accessor function `<name>-<field>` for each field that retrieves the field value from a record via `hash-ref`.

#### Scenario: Accessor retrieves field value
- **WHEN** `(define-record point x y)` is evaluated and `(point-x (make-point 10 20))` is called
- **THEN** the result SHALL be `10`

#### Scenario: Each field has its own accessor
- **WHEN** `(point-y (make-point 10 20))` is called
- **THEN** the result SHALL be `20`

### Requirement: define-record generates field mutators
`define-record` SHALL generate a mutator function `set-<name>-<field>!` for each field that mutates the record in place via `hash-set!` and returns the modified record.

#### Scenario: Mutator updates field in place
- **WHEN** a point is created with `(define p (make-point 1 2))` and `(set-point-x! p 99)` is called
- **THEN** `(point-x p)` SHALL be `99`

### Requirement: define-record generates functional update accessors
`define-record` SHALL generate a functional update function `<name>-with-<field>` for each field that returns a new hash table with the specified field changed, leaving the original unchanged.

#### Scenario: Functional update returns new record
- **WHEN** `(define p (make-point 1 2))` and `(define p2 (point-with-x p 99))` are evaluated
- **THEN** `(point-x p2)` SHALL be `99` and `(point-x p)` SHALL remain `1`

### Requirement: define-record generates a copy function
`define-record` SHALL generate a copy function `copy-<name>` that returns a new hash table with the same type and field values as the original (shallow copy).

#### Scenario: Copy creates independent record
- **WHEN** `(define p (make-point 1 2))` and `(define p2 (copy-point p))` are evaluated and `(set-point-x! p2 99)` is called
- **THEN** `(point-x p)` SHALL remain `1` and `(point-x p2)` SHALL be `99`

### Requirement: Records are compatible with hash table operations
Records produced by `define-record` SHALL be HAMT-backed hash tables, fully compatible with `hash-ref`, `hash-set!`, `hash-set`, `hash-keys`, `hash-count`, `hash-table?`, and serialization via `save-continuation!`/`load-continuation`.

#### Scenario: Hash table operations work on records
- **WHEN** a record is created with `(make-point 10 20)`
- **THEN** `(hash-table? (make-point 10 20))` SHALL be `t` and `(hash-keys (make-point 10 20))` SHALL include `type`, `x`, and `y`
