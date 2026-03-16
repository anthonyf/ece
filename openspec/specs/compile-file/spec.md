## ADDED Requirements

### Requirement: compile-file compiles a source file
`compile-file` SHALL read all forms from a `.scm` source file, compile each one, and write the compiled units to an output file with a `.ecec` extension. The output filename SHALL be derived from the input filename by replacing the extension.

#### Scenario: Compile a source file
- **WHEN** `(compile-file "mylib.scm")` is called on a file containing valid ECE forms
- **THEN** a file `mylib.ecec` is created containing serialized compiled units

#### Scenario: Return value is the output filename
- **WHEN** `(compile-file "mylib.scm")` is called
- **THEN** the return value is the string `"mylib.ecec"`

### Requirement: compile-file executes macros at compile time
When `compile-file` encounters a `define-macro` form, it SHALL execute that macro definition at compile time so that subsequent forms in the same file can use the macro. The macro definition SHALL also be included in the compiled output.

#### Scenario: Macro used in same file
- **WHEN** a source file contains a `define-macro` followed by forms that use that macro
- **THEN** `compile-file` succeeds and the compiled output contains the expanded forms

#### Scenario: Macro available after load-compiled
- **WHEN** a compiled file containing a `define-macro` is loaded with `load-compiled`
- **THEN** the macro is registered and available for use in subsequent compilations

### Requirement: load-compiled loads a compiled file
`load-compiled` SHALL read compiled units from a `.ecec` file and execute each one in sequence against the global environment.

#### Scenario: Load and execute a compiled file
- **WHEN** `(load-compiled "mylib.ecec")` is called on a file produced by `compile-file`
- **THEN** all definitions from the original source are available in the global environment

#### Scenario: Return value
- **WHEN** `(load-compiled "mylib.ecec")` is called
- **THEN** the return value is the result of the last executed compiled unit

### Requirement: compile-file and load-compiled round-trip
Loading a compiled file SHALL produce the same observable effects as loading the original source file with `load`.

#### Scenario: Equivalence with load
- **WHEN** a source file is compiled with `compile-file` and then loaded with `load-compiled`
- **THEN** the resulting global environment state matches what `load` on the source file would produce
