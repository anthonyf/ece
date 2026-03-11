## MODIFIED Requirements

### Requirement: ECE starts from a saved image without the CL compiler
ECE SHALL be able to start from `runtime.lisp` plus `boot.lisp` plus a saved image file, without loading `compiler.lisp`. The `boot.lisp` file loads the image and provides `evaluate`, `ece-try-eval`, and `repl`. The `image-repl` function in runtime.lisp is removed in favor of `repl` in boot.lisp.

#### Scenario: REPL startup via boot.lisp
- **WHEN** the `"ece"` ASDF system is loaded and `(ece:repl)` is called
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
A `make image` target SHALL cold-boot ECE using the `"ece/cold"` ASDF system and save the resulting state as a bootstrap image.

#### Scenario: Generate bootstrap image
- **WHEN** `make image` is run
- **THEN** it SHALL use the `"ece/cold"` system to load the CL compiler
- **AND** a bootstrap image SHALL be written to `bootstrap/ece.image`
- **AND** the image SHALL contain the fully bootstrapped system (prelude, compiler, reader, assembler)

#### Scenario: Fast startup target
- **WHEN** `make run` is run
- **THEN** ECE SHALL start using the `"ece"` system (boot.lisp + image)
- **AND** the REPL SHALL be functional

## REMOVED Requirements

### Requirement: mc-eval supports optional env parameter
**Reason**: `mc-eval` in runtime.lisp gains optional env support, but this is not a removal — see boot-from-image spec for the new `evaluate` function that subsumes this.
**Migration**: Use `evaluate` instead of `mc-eval` directly.
