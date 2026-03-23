## Context

The .ecec text format is already the canonical output of the ECE compiler and the CL runtime's native loading format. The WASM runtime uses a secondary binary format (.ececb) only because it lacked an s-expression reader. Adding one to WAT eliminates the entire binary pipeline.

The .ecec format has a simple, fixed grammar — much simpler than full Scheme:
- Header: `(ecec-header (space name) (macros (sym ...)))`
- Units: flat lists of instructions and labels
- Instructions: 7 types (assign, test, branch, goto, save, restore, perform)
- Values: fixnums, floats, strings, symbols, booleans, nil, pairs, vectors
- Labels: bare symbols

No quasiquote, no string interpolation, no hash table literals, no character literals.

## Goals / Non-Goals

**Goals:**
- Single compiled format (.ecec) for both runtimes
- WAT-native .ecec reader (no JS parsing for bootstrap)
- Shorter compiler labels (reduce .ecec size by ~23%)
- Remove all binary format code and artifacts

**Non-Goals:**
- Full Scheme reader in WAT (the ECE reader handles that after bootstrap)
- Optimizing .ecec parsing speed (it runs once at boot)
- Compressing the sandbox embed (future optimization if needed)

## Decisions

### 1. WAT reader architecture

A single exported function `load_ecec(text_offset, text_len)` that:
1. Parses the ecec-header to get the space name and macro list
2. Creates a compilation space
3. For each unit: parses the instruction list, resolves labels to PCs, builds `$instr` structs, stores them in the space
4. Returns the space ID

The reader uses a position cursor into linear memory. Helper functions: `skip-ws`, `read-char`, `peek-char`, `read-atom`, `read-list`, `read-string`, `read-number`.

The reader builds WasmGC values directly — symbols via `$intern`, pairs via `$cons`, strings via `$string` arrays. No handle table involvement.

### 2. Instruction recognition in WAT

Rather than parsing into a generic AST and then converting, the reader recognizes instruction keywords directly during parsing:

```
read "assign" → opcode 0, parse target register, parse source
read "test"   → opcode 1, parse op + operands
read "branch" → opcode 2, parse label
read "goto"   → opcode 3, parse dest
read "save"   → opcode 4, parse register
read "restore"→ opcode 5, parse register
read "perform"→ opcode 6, parse op + operands
bare symbol   → label, register in label table at current PC
```

This combines parsing and instruction building in one pass.

### 3. Short labels in compiler

`mc-make-label` changes from:
```scheme
(string-append "mc-" (symbol->string name) "-" (number->string mc-label-counter))
```
to:
```scheme
(string-append "L" (number->string mc-label-counter))
```

The `name` parameter is still accepted (for compatibility) but ignored. The label counter ensures uniqueness.

### 4. JS bootstrap loading changes

The sandbox boot changes from:
```javascript
// Old: decode base64 binary, parse in JS, build via handles
const bytes = Uint8Array.from(atob(ECE_BOOTSTRAP[name]), c => c.charCodeAt(0));
const parsed = ECE.parseBinary(bytes);
ECE.loadParsed(parsed);
ECE.wasm.run(symId, 0, envHandle);
```
to:
```javascript
// New: decode base64 text, write to linear memory, call WAT reader
const text = atob(ECE_BOOTSTRAP[name]);
// write UTF-16 to linear memory
const mem = new Uint16Array(ECE.wasm.memory.buffer);
for (let i = 0; i < text.length; i++) mem[i] = text.charCodeAt(i);
const spaceId = ECE.wasm.load_ecec(0, text.length);
ECE.wasm.run(spaceId, 0, envHandle);
```

### 5. Build pipeline simplification

```
Current:  .scm → compile-file → .ecec → ecec-to-binary → .ececb → base64 embed
New:      .scm → compile-file → .ecec → base64 embed
```

The Makefile `bootstrap` target drops the ecec-to-binary step entirely.

### 6. Pre-compiled sandbox programs

The sandbox pre-compiles "Hello World" to .ececb. This changes to .ecec — the WAT reader handles it the same way as bootstrap files.

## Risks / Trade-offs

- **Sandbox size increase**: ~1.5 MB → ~2.8 MB for ece-bootstrap.js. Acceptable for local use; gzip reduces it for served deployments.
- **WAT complexity**: ~365 lines of hand-written WAT. Tedious but the grammar is simple and fixed. Once written, it rarely changes.
- **Boot time**: Text parsing is slower than binary decoding. But bootstrap runs once at page load. The difference is likely <100ms.
- **Linear memory usage**: The .ecec text must fit in linear memory during loading. The largest file (prelude.ecec) is ~1.2 MB (~600K chars). With 1 page = 64 KB and auto-growing memory, this is fine.
