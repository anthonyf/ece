# .ececb Binary Format v1

Binary encoding of compiled ECE instructions for the WASM runtime.
Produced by `ecec-to-binary.scm` (ECE), consumed by `glue.js` (JS).

## Overview

JS parses the binary and calls WASM builder functions to construct
instruction structs and compilation spaces. The WASM runtime never
touches raw bytes.

## File Layout

```
[header] [unit]* EOF
```

## Header

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0 | 4 | magic | "ECEB" (0x45 0x43 0x45 0x42) |
| 4 | 1 | version | 0x01 |
| 5 | 2 | name_len | Space name length (u16-le) |
| 7 | N | name | Space name (UTF-8) |
| 7+N | 2 | macro_count | Number of macros (u16-le) |
| 9+N | var | macros | macro_count × (u16-le len + UTF-8 name) |

## Unit

Each unit corresponds to one top-level expression (one line in .ecec).

| Size | Field | Description |
|------|-------|-------------|
| 1 | marker | 0xFE (unit start) |
| 4 | label_count | Number of labels (u32-le) |
| var | labels | label_count × label-entry |
| 4 | instr_count | Number of instructions (u32-le) |
| var | instrs | instr_count × encoded-instruction |

### Label Entry

| Size | Field | Description |
|------|-------|-------------|
| 2 | name_len | Label name length (u16-le) |
| N | name | Label name (UTF-8) |
| 4 | pc | Local PC within the space (u32-le) |

## Instruction Encoding

### Opcode Byte

| Value | Opcode | Description |
|-------|--------|-------------|
| 0 | assign | Set register from source |
| 1 | test | Call operation, set flag |
| 2 | branch | Jump if flag true |
| 3 | goto | Unconditional jump |
| 4 | save | Push register to stack |
| 5 | restore | Pop stack to register |
| 6 | perform | Call operation, discard result |

### Register IDs

| ID | Register |
|----|----------|
| 0 | val |
| 1 | env |
| 2 | proc |
| 3 | argl |
| 4 | continue |
| 5 | stack |

### Machine Operation IDs

| ID | Operation |
|----|-----------|
| 0 | lookup-variable-value |
| 1 | compiled-procedure-entry |
| 2 | compiled-procedure-env |
| 3 | make-compiled-procedure |
| 4 | extend-environment |
| 5 | primitive-procedure? |
| 6 | apply-primitive-procedure |
| 7 | continuation? |
| 8 | continuation-stack |
| 9 | continuation-conts |
| 10 | parameter? |
| 11 | apply-parameter |
| 12 | false? |
| 13 | list |
| 14 | cons |
| 15 | car |
| 16 | set-variable-value! |
| 17 | define-variable! |
| 18 | lexical-ref |
| 19 | lexical-set! |
| 20 | capture-continuation |

### assign (opcode 0)

```
[0x00] [target-reg: u8] [source-type: u8] [source-data...]
```

Source types:
- 0 = const: [encoded-value]
- 1 = reg: [reg-id: u8]
- 2 = label: [name-len: u16-le] [name: UTF-8]
- 3 = op: [op-id: u8] [operand-count: u8] [operands...]

### test (opcode 1)

```
[0x01] [op-id: u8] [operand-count: u8] [operands...]
```

### branch (opcode 2)

```
[0x02] [label-name-len: u16-le] [label-name: UTF-8]
```

### goto (opcode 3)

```
[0x03] [dest-type: u8] [dest-data]
```

- dest-type 0 = label: [name-len: u16-le] [name: UTF-8]
- dest-type 1 = reg: [reg-id: u8]

### save (opcode 4)

```
[0x04] [reg-id: u8]
```

### restore (opcode 5)

```
[0x05] [reg-id: u8]
```

### perform (opcode 6)

```
[0x06] [op-id: u8] [operand-count: u8] [operands...]
```

## Operand Encoding

```
[type: u8] [data...]
```

- 0 = const: [encoded-value]
- 1 = reg: [reg-id: u8]
- 2 = label: [name-len: u16-le] [name: UTF-8]

## Value Encoding

```
[type: u8] [data...]
```

| Type | Meaning | Data |
|------|---------|------|
| 0 | fixnum | i32-le (4 bytes) |
| 1 | string | u32-le length + UTF-8 bytes |
| 2 | symbol | u16-le length + UTF-8 name |
| 3 | #t | (no data) |
| 4 | #f / #S(SCHEME-FALSE) | (no data) |
| 5 | nil / NIL | (no data) |
| 6 | eof | (no data) |
| 7 | char | u32-le codepoint |
| 8 | float | f64-le (8 bytes) |
| 9 | void | (no data) |
| 10 | pair | car-value + cdr-value (recursive) |

## Notes

- Labels are stored unresolved (by name). The JS loader resolves them
  to PCs after processing all labels in a unit.
- Operation names are mapped to numeric IDs by the ECE converter.
- Register names are mapped to numeric IDs by the ECE converter.
- The format is designed for sequential reading — no random access needed.
