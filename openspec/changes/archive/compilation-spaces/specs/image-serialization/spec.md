## MODIFIED Requirements

### Requirement: save-image! serializes full system state
`save-image!` SHALL serialize the system state as a collection of per-space host files plus environment reconstruction code. Each space SHALL be emitted as an independent host source file. A manifest file SHALL list spaces in load order with metadata.

#### Scenario: Save image produces per-space files
- **WHEN** `(save-image! "my-image")` is called
- **THEN** a directory `my-image/` SHALL be created
- **AND** one host source file SHALL be emitted per space
- **AND** a manifest file SHALL be emitted listing spaces in load order
- **AND** an environment reconstruction file SHALL be emitted

#### Scenario: Save image round-trips correctly
- **WHEN** an image is saved with `save-image!` and loaded with `load-image!`
- **THEN** all state SHALL be restored identically
- **AND** all spaces SHALL be present in the registry
- **AND** all procedures SHALL have correct space-qualified entry points

### Requirement: load-image! restores full system state
`load-image!` SHALL load a saved image by reading the manifest and loading space files in order. Each space's instructions SHALL be restored and optionally compiled to host code.

#### Scenario: Load image restores spaces
- **WHEN** a saved image directory is loaded with `load-image!`
- **THEN** the space registry SHALL be populated with all saved spaces
- **AND** each space SHALL have its instruction arrays restored
- **AND** the global environment SHALL be restored from the environment file

#### Scenario: Load image with compiled FASLs
- **WHEN** a saved image has pre-compiled FASLs alongside source files
- **THEN** `load-image!` SHALL load the FASLs for faster startup
- **AND** each space's `compiled-fn` SHALL be set from the FASL

### Requirement: binary image format retained as fallback
The existing binary image format SHALL remain available as a fallback for CL development workflows where load speed is critical. The binary format SHALL continue to work with the global vector compatibility layer during migration.

#### Scenario: Binary save during migration
- **WHEN** the system is in migration mode (global vector as space 0)
- **AND** `save-image!` is called with a `:format :binary` option
- **THEN** the binary serializer SHALL produce the same format as before
- **AND** the binary image SHALL be loadable by the existing deserializer
