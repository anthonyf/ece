## MODIFIED Requirements

### Requirement: Per-space inline codegen entry point

ECE SHALL provide `src/codegen-cl-inline.scm`, an ECE program that takes a compilation space's symbol ID and writes a CL source file containing one `(defun zone-NAME ...)` whose body is the inlined translation of that space's instruction vector. For spaces whose instruction count exceeds the chunk-size threshold, the codegen SHALL emit multiple chunk functions plus a dispatcher (see compiled-zone-splitting spec). The codegen SHALL reuse `*host-primitives*` and the template expander from `src/codegen-cl.scm` for primitive call sites.

#### Scenario: Generate compiled zone for a small space
- **WHEN** the codegen is invoked with a space symbol whose instruction count is below the chunk-size threshold
- **THEN** it SHALL produce a CL file containing exactly one `(defun zone-<spacename> ...)` form with a single tagbody
- **AND** the function's lambda list SHALL be `(initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)`
- **AND** the function body SHALL be a `tagbody` whose tags correspond to the instruction PCs
- **AND** the function SHALL return `(values pc val env proc argl continue stack)` on zone exit

#### Scenario: Generate compiled zone for a large space
- **WHEN** the codegen is invoked with a space symbol whose instruction count exceeds the chunk-size threshold
- **THEN** it SHALL produce a CL file containing chunk functions and a dispatcher per the compiled-zone-splitting spec
- **AND** the dispatcher function SHALL have the same lambda list and return convention as the single-function case

#### Scenario: Unknown space
- **WHEN** the codegen is invoked with a space symbol that does not exist in the space registry
- **THEN** it SHALL signal an error naming the missing space
- **AND** it SHALL NOT write any output file

#### Scenario: Empty space
- **WHEN** the codegen is invoked with a space whose instruction vector has zero entries
- **THEN** it SHALL emit a `defun` that returns the initial register state unchanged

### Requirement: Batch zone generation

ECE SHALL provide a `(generate-all-zones! output-dir)` entry point that generates compiled-zone files for all bootstrap spaces with non-zero instruction counts in a single invocation.

#### Scenario: Batch generation
- **WHEN** `generate-all-zones!` is invoked with an output directory
- **THEN** it SHALL write one `<space>-zone.lisp` file per bootstrap space that has at least one instruction
- **AND** it SHALL skip spaces with zero instructions (e.g., browser-lib in the CL image)

#### Scenario: Idempotent regeneration
- **WHEN** `generate-all-zones!` is invoked twice with unchanged inputs
- **THEN** both runs SHALL produce byte-identical output files for every space
