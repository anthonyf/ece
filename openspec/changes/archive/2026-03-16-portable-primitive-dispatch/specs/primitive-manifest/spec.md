## ADDED Requirements

### Requirement: manifest file format
ECE SHALL have a primitive manifest file (`primitives.def`) containing S-expression entries of the form `(id name arity platform description)` where `id` is a non-negative integer, `name` is a symbol, `arity` is an integer (-1 for variadic), `platform` is one of `core`, `cl`, or `browser`, and `description` is a string.

#### Scenario: manifest is valid S-expressions
- **WHEN** `primitives.def` is read by the ECE reader or CL reader
- **THEN** each entry SHALL parse as a list of 5 elements

#### Scenario: IDs are unique
- **WHEN** the manifest is loaded
- **THEN** no two entries SHALL share the same numeric ID

#### Scenario: names are unique
- **WHEN** the manifest is loaded
- **THEN** no two entries SHALL share the same name

### Requirement: ID stability
Once a numeric ID is assigned to a primitive name in the manifest, that ID SHALL NOT be reassigned to a different primitive in any future version. IDs may be marked deprecated but not reused.

### Requirement: ID range conventions
Core primitives SHALL use IDs 0-99. CL platform primitives SHALL use IDs 100-199. Browser platform primitives SHALL use IDs 200-299. Future platforms SHALL use ranges 300+.

### Requirement: all existing primitives are in manifest
Every primitive currently registered in `*primitive-procedures*` and `*wrapper-primitives*` SHALL have a corresponding entry in `primitives.def` with platform tag `core` or `cl`.

#### Scenario: core primitives present
- **WHEN** the manifest is loaded
- **THEN** it SHALL contain entries for `+`, `-`, `*`, `/`, `car`, `cdr`, `cons`, `list`, `null?`, `pair?`, `eq?`, `display`, `newline`, `read-char`, `write-char`, and all other standard primitives

#### Scenario: CL-only primitives tagged
- **WHEN** the manifest is loaded
- **THEN** `open-input-file`, `open-output-file`, `with-input-from-file`, `with-output-to-file`, `save-image!`, `trace`, `untrace` SHALL have platform tag `cl`
