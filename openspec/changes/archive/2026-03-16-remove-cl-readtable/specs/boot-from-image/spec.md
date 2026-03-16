## MODIFIED Requirements

### Requirement: ece ASDF system loads boot.lisp instead of compiler.lisp
The `"ece"` ASDF system SHALL load only `runtime.lisp`. The image load, `evaluate`, `ece-try-eval`, and `repl` definitions (previously in `boot.lisp`) SHALL be included in `runtime.lisp`. Neither `boot.lisp` nor `readtable.lisp` SHALL be loaded. The runtime SHALL NOT contain CL readtable infrastructure (`*ece-readtable*`, reader macros).

#### Scenario: Normal system load
- **WHEN** `(asdf:load-system :ece)` is evaluated
- **THEN** only `runtime.lisp` SHALL be loaded
- **AND** the bootstrap image SHALL be restored using the flat-format deserializer
- **AND** `evaluate`, `ece-try-eval`, and `repl` SHALL be available
- **AND** no CL readtable customization SHALL be required

### Requirement: ece/cold ASDF system loads compiler.lisp for cold boot
A separate `"ece/cold"` ASDF system SHALL load `runtime.lisp`, `readtable.lisp`, and `compiler.lisp`, providing the full CL bootstrap compiler and readtable for image generation from source.

#### Scenario: Cold boot for image generation
- **WHEN** `(asdf:load-system :ece/cold)` is evaluated
- **THEN** the CL bootstrap compiler and readtable SHALL be loaded
- **AND** `ece-save-image` SHALL be callable to generate a new bootstrap image
