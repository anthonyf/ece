## 1. Binary Encoding Infrastructure

- [x] 1.1 Define constants: instruction opcodes (assign=0x01..branch=0x07), register enum (val=0x00..stack=0x05), operation enum (lookup-variable-value=0x00..car=0x12), source-type enum, data type tags
- [x] 1.2 Implement binary write helpers: `write-u8`, `write-u16-be`, `write-u32-be`, `write-i64-be`, `write-f64-be` for writing to a byte output stream
- [x] 1.3 Implement binary read helpers: `read-u8`, `read-u16-be`, `read-u32-be`, `read-i64-be`, `read-f64-be` for reading from a byte input stream

## 2. Symbol Table

- [x] 2.1 Implement `collect-symbols`: walk image data and collect all unique symbols into a vector, return symbol-to-index hash table
- [x] 2.2 Implement `write-symbol-table`: write symbol count + entries (package-tag, name-length, name-bytes) to binary stream
- [x] 2.3 Implement `read-symbol-table`: read symbol entries and intern them, return index-to-symbol vector

## 3. Binary Serializer

- [x] 3.1 Implement `binary-serialize-instruction`: encode a single register machine instruction using typed opcode format (assign/test/perform/save/restore/goto/branch with register and operation enums)
- [x] 3.2 Implement `binary-serialize-data`: encode arbitrary ECE values (int, sym, string, list, cons, vector, etc.) using binary stack-machine type tags, with symbol table index references and def/ref for shared objects
- [x] 3.3 Implement `binary-image-serialize`: write complete binary image — header, symbol table, section directory, then instruction section + data sections (labels, env, macros, names, params, param-counter)
- [x] 3.4 Update `ece-%write-image` to call `binary-image-serialize` instead of `flat-image-serialize`

## 4. Binary Deserializer

- [x] 4.1 Implement `binary-deserialize-instruction`: decode a typed instruction and build the resolved cons-tree form directly (with `op-fn` + function pointers), plus the source form (with `op` + symbol)
- [x] 4.2 Implement `binary-deserialize-data`: decode binary stack-machine values, resolving symbol indices via the symbol table vector
- [x] 4.3 Implement `binary-image-deserialize`: read header, symbol table, section directory, then deserialize all sections. Build both `*global-instruction-vector*` (resolved) and `*global-instruction-source*` (unresolved) directly
- [x] 4.4 Update `ece-load-image` to auto-detect format (check first 3 bytes for "ECE" magic) and dispatch to binary or text deserializer

## 5. Disassembler

- [x] 5.1 Implement `ece-disassemble-image`: read binary image and produce human-readable output — header summary, instruction listing with PC numbers and symbolic forms, label table, environment summary
- [x] 5.2 Add `make disasm` target to Makefile

## 6. Bootstrap & Integration

- [x] 6.1 Regenerate `bootstrap/ece.image` in binary format via `make image`
- [x] 6.2 Run full test suite (`make test`) — all 45 image round-trip tests must pass with binary format
- [x] 6.3 Verify disassembler output on bootstrap image is correct and readable
- [x] 6.4 Measure and compare: load time (binary vs text), image size, full test suite time
