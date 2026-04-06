## ADDED Requirements

### Requirement: Demo programs stored as .scm files
Each sandbox demo program SHALL be stored as a standalone `.scm` file in `sandbox/programs/`. The file SHALL contain valid ECE source code that can be displayed in the editor and evaluated by the runtime.

#### Scenario: Program files are valid ECE
- **WHEN** any `.scm` file in `sandbox/programs/` is loaded via `eval-string`
- **THEN** it SHALL execute without errors (given the sandbox runtime environment)

#### Scenario: Program files are human-readable
- **WHEN** a developer opens a `.scm` file in `sandbox/programs/`
- **THEN** they SHALL see the program source directly, not escaped inside another language's string literal

### Requirement: S-expression manifest indexes programs
A manifest file `sandbox/programs/manifest.sexp` SHALL list all demo programs as s-expression entries. Each entry SHALL include at minimum a display name and filename.

#### Scenario: Manifest is valid s-expressions
- **WHEN** `manifest.sexp` is read by the ECE reader
- **THEN** it SHALL parse as a list of entries

#### Scenario: Manifest references existing files
- **WHEN** the manifest lists a file `hello-world.scm`
- **THEN** `sandbox/programs/hello-world.scm` SHALL exist

### Requirement: Sandbox build inlines program source
The sandbox build step SHALL read the manifest and each referenced `.scm` file, and produce output suitable for the sandbox UI (program names and source text available to JavaScript for display in the editor dropdown and execution).

#### Scenario: Programs available in sandbox UI
- **WHEN** the sandbox page loads
- **THEN** the program dropdown SHALL contain all programs from the manifest
- **AND** selecting a program SHALL populate the editor with its source text

#### Scenario: Program source is editable
- **WHEN** a user selects a demo program and modifies the source in the editor
- **THEN** the modified source SHALL be what gets evaluated on "Run"
