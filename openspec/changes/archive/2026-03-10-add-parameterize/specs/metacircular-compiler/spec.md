## MODIFIED Requirements

### Requirement: metacircular compiler correctly shadows macros with local defines
The metacircular compiler SHALL track locally-defined names via a dynamically-scoped parameter and skip macro expansion when a macro name is shadowed by a local `define`.

#### Scenario: Local define shadows macro
- **WHEN** a macro `foo` is defined and then a `begin` block contains `(define foo 42)` followed by `(foo)`
- **THEN** the MC compiler SHALL compile `(foo)` as a variable reference, not a macro expansion

#### Scenario: Lambda parameter shadows macro
- **WHEN** a macro `foo` is defined and a lambda has parameter `foo`
- **THEN** uses of `foo` inside the lambda body SHALL be compiled as variable references
