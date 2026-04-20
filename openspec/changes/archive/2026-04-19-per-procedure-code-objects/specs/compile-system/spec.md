## MODIFIED Requirements

### Requirement: compile-system produces a code-object archive

`compile-system` SHALL accept a list of `.scm` filenames and an output path, compile each file to a sequence of code objects (one per top-level procedure definition, plus code objects for inner lambdas), and write all resulting code objects to a single `.ecec` archive file. The archive SHALL preserve the order of source files and the order of top-level forms within each file.

#### Scenario: Compile two files into an archive

- **GIVEN** files `a.scm` defining `(define (add1 x) (+ x 1))` and `b.scm` defining `(define (use-add1) (add1 5))`
- **WHEN** `(compile-system '("a.scm" "b.scm") "out.ecec")` is called
- **THEN** `out.ecec` SHALL be a code-object archive containing at least two code objects
- **AND** the code objects derived from `a.scm` SHALL precede those derived from `b.scm`

#### Scenario: Each code object records its source origin

- **WHEN** an archive is produced from files `a.scm` and `b.scm`
- **THEN** code objects originating from `a.scm` SHALL have `a.scm` in their source-location field
- **AND** code objects originating from `b.scm` SHALL have `b.scm` in their source-location field

#### Scenario: Inner lambdas become distinct code objects

- **WHEN** an archive is produced from a file containing `(define (outer x) (let ((f (lambda (y) y))) (f x)))`
- **THEN** the archive SHALL contain at least two code objects derived from this file: one for `outer`'s body and one for the inner lambda
- **AND** the inner lambda's code object SHALL be referenced as a constant by `outer`'s `make-compiled-procedure` instruction

### Requirement: load reads a code-object archive

The runtime loader for `.ecec` files SHALL read a code-object archive, register each code object as a runtime value, and execute any top-level initialization code in archive order.

#### Scenario: Archive loads and registers code objects

- **GIVEN** an `.ecec` file produced by `(compile-system '("a.scm") "a.ecec")` where `a.scm` defines `(define (f x) x)`
- **WHEN** the runtime loads `a.ecec`
- **THEN** `f` SHALL be bound in the global environment to a compiled procedure whose code object was read from the archive

#### Scenario: Top-level forms execute in archive order

- **GIVEN** a file `init.scm` containing, in order, `(define *counter* 0)` and `(set! *counter* 1)`
- **WHEN** the compiled archive is loaded
- **THEN** after load completes, `*counter*` SHALL equal `1`

### Requirement: CL runtime loads code-object archives

The CL runtime SHALL load code-object archive `.ecec` files produced by `compile-system`. Code objects SHALL be materialized as CL struct values; closures and continuations captured during load SHALL reference code objects by direct value reference.

#### Scenario: CL runtime loads and executes

- **WHEN** a code-object archive `.ecec` is loaded by the CL runtime and a procedure defined in that archive is invoked
- **THEN** execution SHALL proceed through the procedure's code-object instructions
- **AND** produce results identical to the file having been evaluated from source

### Requirement: WASM runtime loads code-object archives

The WASM runtime SHALL load code-object archive `.ecec` files produced by `compile-system`. Code objects SHALL be materialized as WASM struct values; dispatch SHALL update the executor's current-code-object pointer, not a space-id index.

#### Scenario: WASM runtime loads and executes

- **WHEN** a code-object archive `.ecec` is loaded by the WASM runtime and a procedure defined in that archive is invoked
- **THEN** execution SHALL proceed through the procedure's code-object instructions
- **AND** produce results identical to the CL runtime executing the same archive
