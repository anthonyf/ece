## MODIFIED Requirements

### Requirement: string interpolation expands to executable code
String interpolation with `~{expr}` inside double-quoted strings SHALL expand to a `(string-append ...)` form that concatenates literal segments with `(write-to-string expr)` calls for interpolated expressions.

Previously expanded to `(fmt ...)`. Now expands to standard Scheme operations only.

#### Scenario: Single interpolation
- **WHEN** the reader encounters `"Hello ~{name}"`
- **THEN** it SHALL produce `(string-append "Hello " (write-to-string name))`

#### Scenario: Multiple interpolations
- **WHEN** the reader encounters `"~{a} and ~{b}"`
- **THEN** it SHALL produce `(string-append (write-to-string a) " and " (write-to-string b))`

#### Scenario: No interpolation
- **WHEN** the reader encounters `"plain string"`
- **THEN** it SHALL produce the string literal `"plain string"` directly

#### Scenario: Interpolation result is a string
- **WHEN** an interpolated expression evaluates to a string
- **THEN** `write-to-string` SHALL wrap it in quotes (as `write` would)
- **AND** this is acceptable — interpolation uses `write` semantics, not `display` semantics
