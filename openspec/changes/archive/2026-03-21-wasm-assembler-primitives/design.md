## Context

The WASM runtime has `$comp-space` structs with instruction vectors and label tables. The JS `loadParsed` function builds these from `.ececb` data. The assembler primitives need to do the same thing but from within ECE code running on the executor.

On CL, `%space-instruction-push!` calls `resolve-operations` to convert `(op name)` → `(op-fn #'function)`. On WASM, the `.ececb` loader already resolves operations to numeric IDs. But the self-hosted compiler emits instructions with `(op name)` that need resolution at assembly time.

## Goals / Non-Goals

**Goals:**
- Self-hosted compiler works on WASM (compile-and-go, load, REPL)
- Sandbox REPL evaluates arbitrary expressions
- `try-eval` works for error isolation in tests
- Existing 329 WASM tests still pass

**Non-Goals:**
- Performance optimization of runtime compilation
- Compile-file to .ecec on WASM (needs binary output)

## Decisions

### 1. Instruction representation for runtime-compiled code

On CL, runtime-compiled instructions are stored as Lisp lists: `(assign val (op-fn #'lookup-variable-value) ...)`. On WASM, instructions are `$instr` structs with opcode/a/b/c/val fields.

The self-hosted compiler emits instructions as ECE lists. `%space-instruction-push!` receives these lists and needs to convert them to `$instr` structs. This conversion is the same as what `buildInstruction` does in glue.js — parse opcode, extract operands, create `$instr`.

**Choice:** Implement instruction conversion in WAT. The `$space-instr-push` function parses the ECE list instruction and creates a `$instr` struct. This is ~50 lines of WAT dispatch code.

### 2. Operation resolution

The compiler emits `(op lookup-variable-value)`. This needs to be resolved to op-ID 0 at assembly time. On CL, `resolve-operations` does this via `get-operation`. On WASM, we need the same mapping — symbol → op-ID.

**Choice:** Add a `$resolve-op-name` WAT function with the same 25-entry symbol→ID table as the CL `get-operation`. Match by symbol ID (interned symbols are identity-equal).

### 3. execute-from-pc (recursive executor entry)

`mc-compile-and-go` compiles an expression, then calls `execute-from-pc` to run from the new PC. This calls `$execute` recursively. WASM supports this — each call gets its own locals.

**Choice:** `execute-from-pc` extracts space-id and PC from the qualified address, then calls `$execute` with the current global env.

### 4. try-eval

`try-eval` calls `evaluate` (which is `mc-compile-and-go`) with error handling. On CL, it uses `handler-case`. On WASM, we don't have CL's condition system, but we can catch WASM traps.

**Choice:** `try-eval` calls `mc-compile-and-go` (a compiled procedure) via the dispatch pattern. On error (WASM trap), it returns the eof sentinel. The trap is caught by JS.

Actually simpler: `try-eval` is called from ECE code. The ECE prelude can define it as:
```scheme
(define (try-eval expr)
  (mc-compile-and-go expr))  ;; errors propagate naturally
```
For error isolation, the test framework already catches via the WASM trap mechanism.

### 5. Label table as hash table

On CL, label tables are CL hash tables. On WASM, the `$comp-space` has a separate label table. For runtime compilation, labels are ECE symbols. We need to store symbol→PC mappings.

**Choice:** Reuse the `$hash-table` struct for label tables in runtime-compiled spaces. `%space-label-set!` stores `(symbol . fixnum-PC)` pairs. `%space-label-ref` looks them up.

Actually, the existing `$comp-space` doesn't have a separate label table — the `.ececb` loader resolves labels at load time and stores resolved PCs directly in instructions. For runtime compilation, we need a label table per space.

**Choice:** Add a `$labels` field to `$comp-space` — a `$hash-table` for symbol→PC mappings. Populated by `%space-label-set!`, queried by `%space-label-ref`. After assembly, the executor uses resolved PCs in instructions (same as .ececb loading).

### 6. Current space ID

A global `$current-space-id` tracks which space the assembler targets. `%current-space-id` reads it, `%set-current-space-id!` sets it.
