## Requirements

### Requirement: ECE starts from a saved image without the CL compiler
ECE SHALL be able to start from `runtime.lisp` plus a saved image file, without loading `compiler.lisp`. The image provides all compiled state (prelude, metacircular compiler, reader, assembler).

#### Scenario: Image-based REPL startup
- **WHEN** `runtime.lisp` is loaded and `image-repl` is called with a valid bootstrap image path
- **THEN** the image SHALL be loaded and the ECE REPL SHALL start
- **AND** the user SHALL be able to evaluate expressions, define functions, and use all stdlib features

#### Scenario: Metacircular compiler works after image load
- **WHEN** an image containing the metacircular compiler is loaded without `compiler.lisp`
- **THEN** `mc-compile-and-go` SHALL compile and execute expressions correctly
- **AND** macro expansion SHALL work (including `parameterize` and other parameter-using macros)

#### Scenario: Image-based startup is faster than cold boot
- **WHEN** ECE starts via image load
- **THEN** the startup time SHALL be significantly faster than cold-bootstrapping through `compiler.lisp`

### Requirement: Bootstrap image can be regenerated from source
A `make image` target SHALL cold-boot ECE and save the resulting state as a bootstrap image.

#### Scenario: Generate bootstrap image
- **WHEN** `make image` is run
- **THEN** a bootstrap image SHALL be written to `bootstrap/ece.image`
- **AND** the image SHALL contain the fully bootstrapped system (prelude, compiler, reader, assembler)

#### Scenario: Fast startup target
- **WHEN** `make run` is run
- **THEN** ECE SHALL start using the bootstrap image (not cold boot)
- **AND** the REPL SHALL be functional
