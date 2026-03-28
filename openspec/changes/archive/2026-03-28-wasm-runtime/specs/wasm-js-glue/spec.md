## ADDED Requirements

### Requirement: WASM module instantiation
The JS glue SHALL load the compiled `.wasm` module and instantiate it with the required imports.

#### Scenario: Module loads successfully
- **WHEN** the HTML page loads
- **THEN** the JS glue SHALL fetch the `.wasm` file, compile it, and instantiate it with I/O imports

#### Scenario: Module load failure
- **WHEN** the `.wasm` file fails to load or compile
- **THEN** the JS glue SHALL display an error message in the output area

### Requirement: Bootstrap .ececb loading
The JS glue SHALL fetch `.ececb` files and pass the raw bytes to the WASM runtime for loading.

#### Scenario: Load bootstrap files in order
- **WHEN** the runtime starts
- **THEN** the JS glue SHALL fetch and pass bootstrap `.ececb` files (prelude, reader, compiler, assembler, compilation-unit) to the WASM loader in the correct boot order

#### Scenario: Program .ececb loading
- **WHEN** a user program `.ececb` is specified
- **THEN** the JS glue SHALL fetch it and pass it to the WASM runtime after bootstrap completes

### Requirement: Console output bridge
The JS glue SHALL provide imported functions for text output that render to an HTML element.

#### Scenario: Display string output
- **WHEN** the WASM runtime calls the `io.display_string` import
- **THEN** the JS glue SHALL append the text content to the output `<pre>` element

#### Scenario: Newline output
- **WHEN** the WASM runtime calls the `io.newline` import
- **THEN** the JS glue SHALL append a newline character to the output element

### Requirement: Minimal HTML harness
The JS glue SHALL include a minimal HTML page for running ECE programs.

#### Scenario: Output area exists
- **WHEN** the HTML page loads
- **THEN** it SHALL contain a `<pre>` element for program output

#### Scenario: Self-contained page
- **WHEN** the HTML page is served
- **THEN** it SHALL load the WASM module and all `.ececb` files, requiring only a static file server
