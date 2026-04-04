## ADDED Requirements

### Requirement: Shared ECE Modules table includes syntax-rules.scm
The modules table SHALL include `src/syntax-rules.scm` with its role: R7RS `define-syntax` / `syntax-rules` hygienic pattern-matching macros.

#### Scenario: syntax-rules.scm in table
- **WHEN** a user reads the Shared ECE Modules table
- **THEN** `src/syntax-rules.scm` appears with a description of its role

### Requirement: Shared ECE Modules table includes browser-lib.scm
The modules table SHALL include `src/browser-lib.scm` with its role: Browser DOM access, event handling, and CSS helpers (WASM/browser).

#### Scenario: browser-lib.scm in table
- **WHEN** a user reads the Shared ECE Modules table
- **THEN** `src/browser-lib.scm` appears with a description of its role

### Requirement: Macro Key Feature describes both macro systems
The Key Features bullet for macros SHALL describe both `define-macro` (CL-style unhygienic) and `define-syntax`/`syntax-rules` (R7RS hygienic pattern-matching). The "hygienic-ish" qualifier SHALL be removed.

#### Scenario: Both macro systems mentioned
- **WHEN** a user reads the Key Features list
- **THEN** the macro bullet mentions both `define-macro` and `define-syntax`/`syntax-rules`
- **THEN** the description does not say "hygienic-ish"

### Requirement: define-syntax appears in Core Forms
The Core Forms listing SHALL include `define-syntax`.

#### Scenario: Core Forms includes define-syntax
- **WHEN** a user reads the Core Forms line
- **THEN** `define-syntax` is listed

### Requirement: ece-build CL target is documented
The Building a Web App section (or a new sibling section) SHALL document the `--target cl` option for `ece-build`, showing usage and output structure.

#### Scenario: CL target documented
- **WHEN** a user reads the build documentation
- **THEN** they find `ece-build --target cl` usage with output directory contents and how to run the result
