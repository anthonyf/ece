## ADDED Requirements

### Requirement: %procedure-params returns parameter metadata

ECE SHALL provide a `%procedure-params` host primitive that, given a callable value, returns its parameter metadata as `(param-names . rest-flag)` where `param-names` is a list of strings and `rest-flag` is `0` (no rest parameter) or `1` (last name is a rest parameter). For host primitives, it SHALL return arity-based metadata. If no metadata is available, it SHALL return `#f`.

#### Scenario: Returns parameter names for compiled procedure

- **WHEN** `(define (foo x y) (+ x y))` has been evaluated and `(%procedure-params foo)` is called
- **THEN** it SHALL return `(("x" "y") . 0)`

#### Scenario: Returns rest-parameter info

- **WHEN** `(define (bar x . rest) rest)` has been evaluated and `(%procedure-params bar)` is called
- **THEN** it SHALL return `(("x" "rest") . 1)` where the last parameter name is the rest parameter

#### Scenario: Returns arity for host primitives

- **WHEN** `(%procedure-params car)` is called
- **THEN** it SHALL return `(("arg1") . 0)`

#### Scenario: Returns #f for values without metadata

- **WHEN** `(%procedure-params 42)` is called
- **THEN** it SHALL return `#f`

### Requirement: Parameter metadata persists through bootstrap

The compiler/assembler SHALL emit `%procedure-params-set!` instructions alongside `%procedure-name-set!` so that parameter metadata for all `define`-form procedures is available after booting from `.ecec` files.

#### Scenario: Prelude functions have metadata

- **WHEN** `(%procedure-params map)` is called after bootstrap
- **THEN** it SHALL return parameter metadata (not `#f`)
