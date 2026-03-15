## Context

ECE images are currently serialized as text — a stack-machine program where each line is an opcode + argument. The bootstrap image is 220,284 lines / 2.0 MB. Loading it requires:

1. `flat-image-deserialize`: 220k `read-line` calls, each parsed via `string-trim` → `position #\Space` → `subseq` → `string=` dispatch. Builds a nested cons-tree representation.
2. `resolve-operations`: Second pass over all instructions, replacing `(op name)` with `(op-fn #'function)` via `get-operation` lookup.

The executor (`execute-instructions`) consumes instructions as cons trees like `(assign env (op-fn #'compiled-procedure-env) (reg proc))`, dispatching on `(car instr)` and `(car source)`.

The image stores 7 sections as a single nested list: instruction list, label alist, environment, macro alist, name alist, parameter alist, parameter counter.

## Goals / Non-Goals

**Goals:**
- Reduce image load time by 5-10x through binary encoding and single-pass deserialization
- Build resolved `(op-fn #'function ...)` forms directly during deserialization (eliminate `resolve-operations` pass)
- Produce smaller image files (~620KB vs 2MB)
- Provide a disassembler that renders binary images as human-readable register machine instructions
- Maintain identical `ece-save-image` / `ece-load-image` API — no changes to callers

**Non-Goals:**
- Changing the executor's instruction representation (still cons trees with `op-fn`)
- Changing the register machine architecture
- Backward compatibility with old text images in production (a one-time bootstrap regeneration is acceptable)
- Compression (binary encoding is already compact enough; compression adds complexity)

## Decisions

### 1. File structure: header + symbol table + sections

The binary file has a fixed layout:

```
┌────────────────────────────────┐
│ Header (12 bytes)              │
│   magic: "ECE" (3B)           │
│   version: 1 (1B)             │
│   symbol-count (u32)          │
│   section-count (u32)         │
├────────────────────────────────┤
│ Symbol Table                   │
│   For each symbol:             │
│     package-tag (1B)           │
│       0=:ece, 1=:keyword,      │
│       2=:cl, 3=uninterned,     │
│       4=other (followed by     │
│         length-prefixed pkg)   │
│     name-length (u16)          │
│     name-bytes (UTF-8)         │
├────────────────────────────────┤
│ Section Directory              │
│   For each section:            │
│     section-type (1B)          │
│     offset (u32)               │
│     length (u32)               │
├────────────────────────────────┤
│ Section 0: Instructions        │
│ Section 1: Labels              │
│ Section 2: Environment         │
│ Section 3: Macros              │
│ Section 4: Procedure Names     │
│ Section 5: Parameters          │
│ Section 6: Parameter Counter   │
└────────────────────────────────┘
```

**Why a section directory**: Allows the deserializer to skip sections or read them in any order. Future sections can be added without breaking the format.

**Alternative considered**: Single linear stream (current approach). Rejected because sections enable partial loads and easier debugging.

### 2. Instruction encoding: typed binary, not generic stack-machine

Instructions are the dominant content (~95% of the image). Instead of encoding them as generic cons trees via the stack machine, use a typed format that mirrors the executor's dispatch:

```
Instruction opcodes (1 byte):
  0x01 = assign
  0x02 = test
  0x03 = perform
  0x04 = save
  0x05 = restore
  0x06 = goto
  0x07 = branch

Register enum (1 byte):
  0x00=val 0x01=env 0x02=proc 0x03=argl
  0x04=continue 0x05=stack

Operation enum (1 byte):
  0x00=lookup-variable-value  0x01=set-variable-value!
  0x02=define-variable!       0x03=lexical-ref
  0x04=lexical-set!           0x05=extend-environment
  0x06=make-compiled-procedure 0x07=compiled-procedure-entry
  0x08=compiled-procedure-env 0x09=primitive-procedure?
  0x0A=continuation?          0x0B=apply-primitive-procedure
  0x0C=capture-continuation   0x0D=continuation-stack
  0x0E=continuation-conts     0x0F=false?
  0x10=list                   0x11=cons
  0x12=car

Source type (1 byte, for assign):
  0x00=const  0x01=reg  0x02=op  0x03=label

Operand encoding (for op arguments):
  0x00=reg(1B reg-id)
  0x01=const(inline value using data encoding)
```

Example: `(assign env (op compiled-procedure-env) (reg proc))`
```
01          ; assign
01          ; target: env
02          ; source-type: op
08          ; operation: compiled-procedure-env
01          ; operand-count: 1
00 02       ; operand: reg proc
```

**Why typed encoding over generic**: The executor dispatches on `(car instr)` then `(car source)` — the instruction set is fixed and small. Generic encoding wastes 9 lines / ~100 bytes per instruction on structural overhead (sym/list opcodes) that carries no information beyond the instruction type.

**Why still build cons trees**: The executor expects `(assign env (op-fn #'compiled-procedure-env) (reg proc))`. Changing the executor to use a struct/array representation would be a much larger change. The binary deserializer builds these cons trees directly with `#'function` already resolved — no intermediate generic form, no resolve-operations pass.

### 3. Data section encoding: binary stack-machine

The non-instruction sections (environment, macros, parameters) contain arbitrary ECE values (lists, strings, vectors, hash tables, compiled procedures). These use a binary version of the current stack-machine format:

```
Value type tags (1 byte):
  0x01=nil  0x02=t  0x03=false
  0x04=int(i64)  0x05=float(f64)
  0x06=char(u32)
  0x07=sym(u16 symbol-table-index)
  0x08=keyword(u16 symbol-table-index)
  0x09=string(u32 length, bytes)
  0x0A=cons    0x0B=list(u16 count)
  0x0C=def(u16 id)  0x0D=ref(u16 id)
  0x0E=vector(u16 count)
  0x0F=gensym(u16 symbol-table-index)
```

Same semantics as the text format but byte-encoded. Symbols reference the shared symbol table by index instead of being spelled out as strings each time.

### 4. Disassembler: binary → human-readable text

The disassembler reads a binary image and produces structured text output:

```
;; ECE Image v1 — 14,832 instructions, 287 symbols
;;
;; === Instructions ===
;;  PC   Instruction
;; ----  ------------------------------------------------
;; 0000  (assign env (op compiled-procedure-env) (reg proc))
;; 0001  (assign env (op extend-environment) (const x) (reg argl) (reg env))
;; 0002  (assign proc (op lookup-variable-value) (const car) (reg env))
;;
;; === Labels ===
;; entry0          → PC 0
;; entry1          → PC 42
;;
;; === Environment ===
;; car             → <primitive>
;; map             → <compiled-procedure @4201>
```

It reconstitutes register machine instructions from the binary encoding, showing the symbolic form rather than raw bytes. This reuses the existing symbol names from the text serializer.

Exposed as `(ece-disassemble-image filename &optional output-stream)` and a `make disasm` target.

### 5. Migration: one-time bootstrap regeneration

- Add binary save/load alongside text save/load
- Switch `ece-save-image` / `ece-load-image` to binary format
- Regenerate `bootstrap/ece.image` via `make image`
- Keep text deserializer for the disassembler (it reads binary, writes text)
- Old `flat-image-deserialize` retained but not called by default

`ece-load-image` can auto-detect format by checking the first 3 bytes for the "ECE" magic. If not present, fall back to text format. This provides a smooth transition.

## Risks / Trade-offs

- **[Risk] Binary format is harder to debug than text** → Mitigated by the disassembler, which provides better output than the raw text format. `make disasm` makes it one command.

- **[Risk] Endianness** → Use big-endian (network byte order) throughout. ECE currently runs on ARM64 Mac and x86-64 Linux CI. Both handle big-endian reads efficiently. Alternatively, match platform endianness and store it in the header — but big-endian is simpler and the performance difference is negligible for this data volume.

- **[Risk] Operation enum must stay in sync with `get-operation`** → Single source of truth: define the enum as a defconstant array, derive both `get-operation` dispatch and binary encoding from it.

- **[Trade-off] Still building cons trees for instructions** → Optimal would be a flat struct/array instruction format, but that requires changing the executor. The cons-tree representation is good enough — the bottleneck is parsing, not allocation.

## Open Questions

- Should integers use variable-length encoding (saves space for small ints which are common) or fixed i64 (simpler)? Leaning toward fixed i64 for simplicity — the size savings are marginal given instructions dominate the image.
