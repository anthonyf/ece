## Context

ECE currently runs on a Common Lisp host. The CL runtime (`src/runtime.lisp`, ~2044 lines) implements the register machine executor, environment operations, compilation spaces, primitives, and bootstrap loading. The compiler, reader, assembler, and prelude are self-hosted in `.ecec` files that boot on the CL executor.

The architecture was designed for portability: a small kernel (the executor + primitives) with everything else in `.ecec` files that run on any host. The `primitives.def` manifest assigns stable numeric IDs to all primitives with explicit platform annotations (core/cl/browser).

## Goals / Non-Goals

**Goals:**
- Run compiled ECE programs in the browser via WebAssembly
- Hand-written WAT for full control and minimal output size
- Use WasmGC for memory management (no custom GC)
- Keep JS glue layer as thin as possible — only browser API bridging
- Binary `.ececb` format for efficient program loading
- Build tool written in ECE itself (self-hosting philosophy)
- Same `.ecec` bootstrap files compile to either host

**Non-Goals:**
- REPL in the browser (future milestone)
- Canvas/graphics primitives (future milestone)
- Replacing the CL host — both hosts coexist
- WASM-to-WASM compilation (compiled zone from Phase 1 plan — deferred)
- Source-level debugging in browser
- npm packaging or build tool integrations

## Decisions

### 1. WasmGC over linear memory + custom GC

**Choice:** Use WasmGC managed reference types for all ECE values.

**Rationale:** WasmGC eliminates the need to write a garbage collector in WAT (estimated 200-400 lines of subtle, bug-prone code). The browser's GC is battle-tested and optimized. WasmGC has shipped in all major browsers (Chrome 119, Firefox 120, Safari 18.2).

**Alternatives considered:**
- *Linear memory + mark-and-sweep*: Full control over memory layout, enables NaN-boxing for native f64 performance. Rejected because GC complexity dominates the implementation effort and risk.
- *Linear memory + NaN-boxing*: Best numeric performance (native f64, full 32-bit fixnums). Rejected because WasmGC's simplicity outweighs the float boxing cost for the expected workload.

**Trade-off:** Floats are boxed in a GC struct (allocation per float operation). Fixnums are 31-bit via i31ref (±1B range instead of ±2B). Acceptable for the target use cases.

### 2. Value representation via WasmGC type hierarchy

**Choice:** Each ECE value kind maps to a distinct WasmGC type. Runtime type checks use `ref.test`.

```
(ref eq)                    ;; universal ECE value type
├── i31ref                  ;; fixnums (31-bit signed immediate)
├── (ref $pair)             ;; cons cells (mutable car/cdr)
├── (ref $symbol)           ;; interned symbols (id + name)
├── (ref $string)           ;; UTF-16 character arrays
├── (ref $float-box)        ;; boxed f64
├── (ref $vector)           ;; mutable arrays of values
├── (ref $compiled-proc)    ;; (space, pc, env)
├── (ref $continuation)     ;; (stack, continue-addr)
├── (ref $primitive)        ;; (numeric id)
├── (ref $parameter)        ;; mutable value cell (R7RS)
├── (ref $hash-table)       ;; key-value storage
├── (ref $port)             ;; I/O port wrapper
└── globals: $true, $false, $nil, $eof, $void
```

### 3. UTF-16 strings in WasmGC arrays

**Choice:** Strings are `(array (mut i16))` — UTF-16 code units, GC-managed.

**Rationale:** UTF-16 gives O(1) character access for the Basic Multilingual Plane (covers virtually all game/IF text), 2 bytes per character (half of UTF-32), and matches JavaScript's internal encoding for easy boundary crossing when needed.

**Alternatives considered:**
- *UTF-32 (array i32)*: True O(1) for all Unicode, but 4 bytes per character. Rejected for memory cost.
- *UTF-8 (array i8)*: Most compact, but `string-ref` is O(n). Rejected because Scheme expects O(1) string indexing.
- *JS strings via externref*: Delegate all string ops to JS. Rejected because every operation would cross the WASM↔JS boundary.

### 4. Binary .ececb format with ECE-written converter

**Choice:** A binary encoding of compiled instructions, produced by a tool written in ECE.

**Rationale:** The `.ecec` files are s-expressions — text that requires parsing. A binary format avoids writing a parser in WAT and loads faster (just deserialize flat bytes into instruction arrays). Writing the converter in ECE (not CL) keeps the CL kernel minimal and makes the tool portable to future hosts.

**Format sketch:**
```
.ececb file:
  header:
    magic: "ECEB" (4 bytes)
    version: u8
    space-name-length: u16
    space-name: UTF-8 bytes
    macro-count: u16
    macro entries...
  units[]:
    instruction-count: u32
    instructions[]:
      opcode: u8 (0=assign, 1=test, 2=branch, 3=goto, 4=save, 5=restore, 6=perform)
      operands encoded per opcode type
    labels[]:
      name-length: u16
      name: UTF-8 bytes
      pc: u32
```

Exact format will be refined during implementation. Key constraint: must be efficiently loadable by sequential scan (no random access needed).

### 5. Instruction representation in WASM

**Choice:** Instructions stored as WasmGC arrays/structs, not linear memory.

Each compilation space holds:
- A `(array (ref $instruction))` for the instruction vector
- A symbol→i32 mapping for the label table (could be a WasmGC array scanned linearly, or a hash table)

The `.ececb` loader constructs these GC-managed structures at load time.

### 6. Primitive dispatch via table

**Choice:** Primitives dispatched by numeric ID through a function table.

```wat
;; Table of primitive implementations indexed by ID
(table $prim_table funcref ...)

;; apply-primitive-procedure: extract ID, call_indirect
(func $apply_primitive (param $prim (ref $primitive)) (param $args (ref null eq)) (result (ref eq))
  (call_indirect $prim_table
    (struct.get $primitive $id (local.get $prim))))
```

This maps directly to `primitives.def` IDs. Same IDs, same dispatch mechanism, different host.

### 7. Environment representation

**Choice:** Classic SICP frame chain using WasmGC structs.

```
$env-frame:
  (struct
    (field $vars (ref $symbol-list))   ;; or just for debugging
    (field $vals (ref $val-array))     ;; (array (mut (ref null eq)))
    (field $enclosing (ref null eq)))  ;; parent frame or null
```

`lexical-ref (depth, offset)` walks `depth` frames via `$enclosing`, then indexes into `$vals`. Same algorithm as the CL runtime.

### 8. JS glue — minimal imports

The WASM module imports only what it cannot do itself:

| Import | Purpose |
|--------|---------|
| `io.display_string` | Write string to output area |
| `io.display_number` | Write number to output area |
| `io.newline` | Write newline to output area |
| `io.read_line` | Read user input (async) |
| `loader.fetch_ececb` | Load a .ececb file (returns bytes) |

Canvas, DOM, and audio imports added in future milestones.

## Risks / Trade-offs

- **Float boxing overhead** → For float-heavy code (particle systems, physics), every arithmetic op allocates a GC struct. Mitigation: browser GCs are optimized for short-lived allocations; profile before optimizing. Future: could add unboxed float arrays for hot paths.

- **31-bit fixnum range** → `i31ref` gives ±1,073,741,823. Exceeding this requires boxed integers (not yet planned). Mitigation: sufficient for game logic, pixel coordinates, array indexing. Add boxed bigints later if needed.

- **WasmGC browser support** → Requires Chrome 119+, Firefox 120+, Safari 18.2+. Mitigation: these versions are 1-2+ years old; coverage is broad. No polyfill path — this is a hard requirement.

- **Binary format stability** → `.ececb` format must be versioned from the start. A version byte in the header allows format evolution without breaking existing files.

- **Async I/O** → `read-line` in a browser is inherently async (user types in an input box). The WASM executor is a synchronous loop. Mitigation: use JavaScript Promise + Atomics.wait, or restructure as a coroutine that yields at I/O points. Design TBD — not needed for Milestone 1 (output only).

- **UTF-16 surrogate pairs** → Characters above U+FFFF (emoji, rare CJK) occupy two i16 slots. `string-ref` returns a surrogate half, not the full codepoint. Mitigation: same behavior as JavaScript. Document it. Add `string-ref/codepoint` later if needed.
