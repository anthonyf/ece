## ADDED Requirements

### Requirement: Architecture section includes "What Makes ECE Different" subsection
The README Architecture section SHALL include a subsection titled "What Makes ECE Different" positioned after the WASM Runtime subsection and before the Shared ECE Modules table.

#### Scenario: Subsection exists and is positioned correctly
- **WHEN** a user reads the Architecture section
- **THEN** they find "What Makes ECE Different" between "WASM Runtime" and "Shared ECE Modules"

### Requirement: First-class continuations are explained as an architectural consequence
The subsection SHALL explain that `call/cc` captures the full machine state (stack, env, pc) because ECE uses an explicit register machine with its own stack, not the host's call stack.

#### Scenario: Continuations explanation
- **WHEN** a user reads the differentiators subsection
- **THEN** they understand that first-class continuations are a natural consequence of the explicit-stack architecture

### Requirement: Full TCO is explained as an architectural consequence
The subsection SHALL explain that all tail positions execute in constant stack space, enabled by the explicit stack.

#### Scenario: TCO explanation
- **WHEN** a user reads the differentiators subsection
- **THEN** they understand that TCO covers all core forms and derived forms

### Requirement: Serializable continuations are explained as an architectural consequence
The subsection SHALL explain that because the entire machine state is ECE data structures (not host stack frames), continuations can be serialized to disk and restored later.

#### Scenario: Serialization explanation
- **WHEN** a user reads the differentiators subsection
- **THEN** they understand that serializable continuations enable save/restore for games and persistent workflows

### Requirement: Dual runtime and small kernel are highlighted
The subsection SHALL explain that the same .ecec files run on both CL and WASM, and that the CL kernel is ~2,300 lines with everything else written in ECE itself.

#### Scenario: Dual runtime and kernel size
- **WHEN** a user reads the differentiators subsection
- **THEN** they understand the portability story (small kernel = scope of any future port)
