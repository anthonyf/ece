## MODIFIED Requirements

### Requirement: WASM hygiene for free template variables
Free symbols in operator position within syntax-rules templates SHALL be resolved from the global environment on all runtimes, including WASM. The `%global-ref` wrapping SHALL use `lookup-global-variable` to ensure lexical bindings do not shadow template references.

#### Scenario: shadowed + in operator position on WASM
- **WHEN** a syntax-rules macro `add1` with template `(+ e 1)` is used inside `(let ((+ *)) (add1 3))`
- **THEN** the result SHALL be `4` (global `+` used, not local `*`)

#### Scenario: shadowed cons in operator position on WASM
- **WHEN** a syntax-rules macro `my-pair` with template `(cons a b)` is used inside `(let ((cons list)) (my-pair 1 2))`
- **THEN** the result SHALL be `(1 . 2)` (global `cons` used, not local `list`)
