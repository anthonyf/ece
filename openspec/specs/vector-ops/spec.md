## ADDED Requirements

### Requirement: Vectors are self-evaluating
Vector literals written as `#(...)` SHALL evaluate to themselves.

#### Scenario: Vector literal self-evaluates
- **WHEN** evaluating `#(1 2 3)`
- **THEN** the result SHALL be the vector `#(1 2 3)`

### Requirement: vector? tests for vector type
The evaluator SHALL provide `vector?` as a primitive that returns true for vectors and false otherwise.

#### Scenario: Vector is a vector
- **WHEN** evaluating `(vector? #(1 2 3))`
- **THEN** the result SHALL be true

#### Scenario: List is not a vector
- **WHEN** evaluating `(vector? '(1 2 3))`
- **THEN** the result SHALL be false

#### Scenario: String is not a vector
- **WHEN** evaluating `(vector? "hello")`
- **THEN** the result SHALL be false

### Requirement: make-vector creates a vector of given size
The evaluator SHALL provide `make-vector` that creates a vector of n elements, optionally filled with a given value.

#### Scenario: Make vector with default fill
- **WHEN** evaluating `(vector-length (make-vector 5))`
- **THEN** the result SHALL be `5`

#### Scenario: Make vector with fill value
- **WHEN** evaluating `(vector-ref (make-vector 3 42) 0)`
- **THEN** the result SHALL be `42`

### Requirement: vector creates a vector from arguments
The evaluator SHALL provide `vector` that creates a vector containing the given arguments.

#### Scenario: Create vector from arguments
- **WHEN** evaluating `(vector 1 2 3)`
- **THEN** the result SHALL be the vector `#(1 2 3)`

### Requirement: vector-length returns the length of a vector
The evaluator SHALL provide `vector-length` that returns the number of elements in a vector.

#### Scenario: Length of a vector
- **WHEN** evaluating `(vector-length #(1 2 3))`
- **THEN** the result SHALL be `3`

#### Scenario: Length of empty vector
- **WHEN** evaluating `(vector-length #())`
- **THEN** the result SHALL be `0`

### Requirement: vector-ref returns the element at an index
The evaluator SHALL provide `vector-ref` that returns the element at a zero-based index.

#### Scenario: First element
- **WHEN** evaluating `(vector-ref #(10 20 30) 0)`
- **THEN** the result SHALL be `10`

#### Scenario: Last element
- **WHEN** evaluating `(vector-ref #(10 20 30) 2)`
- **THEN** the result SHALL be `30`

### Requirement: vector-set! mutates a vector element
The evaluator SHALL provide `vector-set!` that sets the element at a given index to a new value.

#### Scenario: Mutate and read back
- **WHEN** evaluating `(begin (define v (make-vector 3 0)) (vector-set! v 1 42) (vector-ref v 1))`
- **THEN** the result SHALL be `42`

#### Scenario: Mutation is visible
- **WHEN** evaluating `(begin (define v (vector 1 2 3)) (vector-set! v 0 99) v)`
- **THEN** the result SHALL be the vector `#(99 2 3)`

### Requirement: vector->list converts a vector to a list
The evaluator SHALL provide `vector->list` that returns a list of the vector's elements.

#### Scenario: Convert vector to list
- **WHEN** evaluating `(vector->list #(1 2 3))`
- **THEN** the result SHALL be `(1 2 3)`

### Requirement: list->vector converts a list to a vector
The evaluator SHALL provide `list->vector` that returns a vector containing the list's elements.

#### Scenario: Convert list to vector
- **WHEN** evaluating `(list->vector '(1 2 3))`
- **THEN** the result SHALL be the vector `#(1 2 3)`
