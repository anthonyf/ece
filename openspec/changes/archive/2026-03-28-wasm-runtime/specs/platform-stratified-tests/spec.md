## ADDED Requirements

### Requirement: Common test entry point for all hosts
A `run-common.scm` entry point SHALL load only tests that use core primitives (IDs 0-99) and can run on any ECE host.

#### Scenario: Common tests on CL host
- **WHEN** `run-common.scm` is loaded on the CL host
- **THEN** all common tests SHALL pass

#### Scenario: Common tests on WASM host
- **WHEN** `run-common.scm` is loaded on the WASM host
- **THEN** all common tests SHALL pass

### Requirement: CL-only test entry point
A `run-cl.scm` entry point SHALL load only tests that require CL-specific primitives (IDs 100-199), such as file I/O and CL-only introspection.

#### Scenario: CL-only tests identified
- **WHEN** `run-cl.scm` is loaded
- **THEN** it SHALL include tests for file I/O (`test-file-io.scm`) and any other tests that use CL platform primitives

### Requirement: WASM-only test entry point
A `run-wasm.scm` entry point SHALL load tests specific to the WASM/browser host, such as browser primitive tests.

#### Scenario: WASM-specific tests
- **WHEN** `run-wasm.scm` is loaded on the WASM host
- **THEN** it SHALL run tests for browser-specific primitives (IDs 200-299) when they are implemented

### Requirement: run-all.scm composes platform entry points
The existing `run-all.scm` SHALL be updated to compose `run-common.scm` + the platform-specific entry point. On CL, `run-all.scm` loads `run-common.scm` + `run-cl.scm`. The existing CL test workflow SHALL not change.

#### Scenario: CL run-all unchanged behavior
- **WHEN** `run-all.scm` is executed on the CL host
- **THEN** all the same tests that currently pass SHALL still pass (common + CL-only)

#### Scenario: WASM run-all
- **WHEN** `run-all.scm` is executed on the WASM host (or `run-common.scm` directly)
- **THEN** all platform-independent tests SHALL pass

### Requirement: Test files classified by platform dependency
Each test file SHALL be classified as common or platform-specific based on which primitives it uses. Tests using only core primitives (0-99) are common. Tests using CL primitives (100-199) are CL-only.

#### Scenario: test-file-io.scm classified as CL-only
- **WHEN** the test suite is reorganized
- **THEN** `test-file-io.scm` SHALL be loaded only by `run-cl.scm` (uses `open-input-file`, `open-output-file` — CL primitives 100-101)

#### Scenario: test-arithmetic.scm classified as common
- **WHEN** the test suite is reorganized
- **THEN** `test-arithmetic.scm` SHALL be loaded by `run-common.scm` (uses only core primitives)

### Requirement: All common tests pass on WASM host
The WASM runtime SHALL be validated by running `run-common.scm` and all tests SHALL pass. This is the acceptance criterion for the WASM runtime.

#### Scenario: Full common test suite passes on WASM
- **WHEN** the WASM runtime boots from `.ececb` files and executes `run-common.scm`
- **THEN** all common tests SHALL pass with zero failures
