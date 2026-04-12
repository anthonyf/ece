## ADDED Requirements

### Requirement: Sub-function splitting for large spaces

When a compilation space's instruction count exceeds a configurable chunk-size threshold, the codegen SHALL partition the space into multiple CL chunk functions plus a dispatcher, so that no single tagbody form exceeds the threshold number of tags.

#### Scenario: Space below threshold
- **WHEN** a space has fewer than CHUNK-SIZE instructions
- **THEN** the codegen SHALL emit a single `(defun zone-NAME ...)` with one tagbody — identical to the unsplit output

#### Scenario: Space above threshold
- **WHEN** a space has N instructions where N > CHUNK-SIZE
- **THEN** the codegen SHALL emit ceil(N/CHUNK-SIZE) chunk functions named `zone-NAME-chunk-K` (K = 0, 1, ...) and one dispatcher function named `zone-NAME`
- **AND** each chunk function's tagbody SHALL contain at most CHUNK-SIZE tags

#### Scenario: Chunk function calling convention
- **WHEN** a chunk function is invoked by the dispatcher
- **THEN** its lambda list SHALL be `(initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)`
- **AND** it SHALL return `(values pc val env proc argl continue stack)` when execution leaves the chunk's PC range, reaches halt, or bails on a register-valued goto

#### Scenario: Intra-chunk control flow
- **WHEN** a goto or branch within a chunk targets a PC inside the same chunk's [start, end) range
- **THEN** the chunk SHALL handle it via a direct `(go pc-N)` tag jump with no function-call overhead

#### Scenario: Cross-chunk control flow
- **WHEN** a goto or branch within a chunk targets a PC outside the chunk's [start, end) range
- **THEN** the chunk SHALL set pc to the target PC and return to the dispatcher
- **AND** the dispatcher SHALL invoke the chunk that owns the target PC with the updated register state

#### Scenario: Halt inside a chunk
- **WHEN** a halt instruction is reached inside any chunk
- **THEN** the chunk SHALL set pc past the total instruction count and return
- **AND** the dispatcher SHALL exit and return the final register state

#### Scenario: Self-registration
- **WHEN** the generated zone file is loaded
- **THEN** the dispatcher function `zone-NAME` SHALL be registered in `*compiled-zone-functions*` under the space's symbol
- **AND** the chunk functions SHALL NOT be independently registered

### Requirement: Dispatcher loop

The dispatcher function SHALL loop, routing the current pc to the owning chunk, until the chunk returns with pc >= the space's total instruction count (halt) or execution needs to leave the zone (register-valued goto bail).

#### Scenario: Dispatcher routing
- **WHEN** the dispatcher is invoked with initial-pc in chunk K's range
- **THEN** it SHALL call `zone-NAME-chunk-K` with the current register state

#### Scenario: Dispatcher loop on cross-chunk jump
- **WHEN** a chunk returns with pc in a different chunk's range
- **THEN** the dispatcher SHALL call the new chunk with the returned register state
- **AND** SHALL NOT re-invoke the original chunk

#### Scenario: Dispatcher exit on halt
- **WHEN** a chunk returns with pc >= total instruction count
- **THEN** the dispatcher SHALL return `(values pc val env proc argl continue stack)` to the caller

#### Scenario: Dispatcher exit on zone bail
- **WHEN** a chunk returns with pc < total instruction count but the register state indicates a zone exit (register-valued goto)
- **THEN** the dispatcher SHALL return the register state to the executor
