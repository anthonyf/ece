## MODIFIED Requirements

### Requirement: flat serializer emits stack-based build instructions
The `ece-%write-image` function SHALL serialize ECE image data to a flat, line-oriented text format. Each line SHALL contain exactly one opcode with its arguments. The opcodes SHALL be: `int`, `sym`, `kwd`, `str`, `chr`, `nil`, `t`, `cons`, `list`, `vec`, `def`, `ref`, `float`, `gsym`.

#### Scenario: Serialize vector frame in environment
- **WHEN** the image data contains an environment frame that is a simple vector `#(10 20 30)`
- **THEN** the serializer SHALL emit `int 10`, `int 20`, `int 30`, then `vec 3`

#### Scenario: Serialize mixed environment (vector and list frames)
- **WHEN** the image data contains an environment with vector frames (lexical) and a list-based global frame
- **THEN** each frame type SHALL be serialized according to its type (vector frames as `vec`, list frames as `cons`/`list`)
