## ADDED Requirements

### Requirement: Variable interpolation with $var
Strings containing `$` followed by an identifier SHALL expand at read time to a `fmt` call with the variable reference.

#### Scenario: Simple variable
- **WHEN** `(begin (define name "Alice") "Hello $name")` is evaluated
- **THEN** the result SHALL be `"Hello Alice"`

#### Scenario: Variable with special chars
- **WHEN** `(begin (define *count* 5) "Total: $*count*")` is evaluated
- **THEN** the result SHALL be `"Total: 5"`

### Requirement: Expression interpolation with $(expr)
Strings containing `$(` SHALL read a full s-expression and expand to a `fmt` call with the expression.

#### Scenario: Arithmetic expression
- **WHEN** `(begin (define x 3) "result: $(+ x 1)")` is evaluated
- **THEN** the result SHALL be `"result: 4"`

#### Scenario: Function call
- **WHEN** `(begin (define items (list 1 2 3)) "count: $(length items)")` is evaluated
- **THEN** the result SHALL be `"count: 3"`

### Requirement: Literal dollar sign with $$
`$$` inside a string SHALL produce a single literal `$` character.

#### Scenario: Escaped dollar sign
- **WHEN** `"Price: $$5.00"` is evaluated
- **THEN** the result SHALL be `"Price: $5.00"`

### Requirement: Plain strings are unchanged
Strings without `$` SHALL be returned as plain strings with no `fmt` wrapper.

#### Scenario: No interpolation
- **WHEN** `"hello world"` is evaluated
- **THEN** the result SHALL be the plain string `"hello world"`

### Requirement: Non-string values are auto-stringified
Interpolated values that are not strings SHALL be converted to strings automatically via `fmt`.

#### Scenario: Number interpolation
- **WHEN** `(begin (define age 30) "Age: $age")` is evaluated
- **THEN** the result SHALL be `"Age: 30"`
