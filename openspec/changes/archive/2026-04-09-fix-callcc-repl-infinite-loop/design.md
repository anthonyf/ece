## Context

ECE's register machine executor (`execute-instructions`) runs compiled code from a shared, append-only instruction vector per compilation space. Each REPL expression is compiled by `mc-compile-and-go` with linkage `'next` (fall-through) and appended to the global space. The executor exits when `pc >= len` (past the end of the vector).

Continuations captured by `call/cc` store the `stack` and `continue` register (an absolute PC in the compilation space). When invoked, they restore these registers and jump to the saved PC.

The bug: a continuation captured in one REPL expression has return addresses pointing to what was the past-end PC at compilation time. When the next REPL expression is compiled, new instructions are appended starting at that very PC. Invoking the continuation now falls through into the next unit's code instead of exiting, creating an infinite loop.

## Goals / Non-Goals

**Goals:**
- Prevent compiled code from one `mc-compile-and-go` call from falling through into the next call's instructions
- Fix the infinite loop when invoking continuations captured in the REPL
- Maintain the existing append-only instruction space model (no per-expression spaces)
- Support both CL and WASM executors

**Non-Goals:**
- Changing the continuation capture/restore mechanism
- Per-REPL-expression compilation spaces (too invasive, breaks cross-expression continuations)
- Modifying how `call/cc` is compiled

## Decisions

### 1. Add a `halt` instruction to the register machine

A new `halt` instruction causes the executor to exit immediately, equivalent to reaching past-end. This is a physical barrier in the instruction stream.

**Rationale**: The simplest possible fix. A single instruction addition to the executor dispatch and a single append in `mc-compile-and-go`. No changes to continuation capture, the compiler, or the space model.

**Alternatives considered**:
- *Compile with linkage `'return` + set `initial-continue` to past-end*: Would work but requires coordinating between `mc-compile-and-go` (ECE side) and `execute-from-pc` (CL primitive). The `halt` approach is self-contained — the barrier is in the instruction stream itself.
- *Per-expression compilation spaces*: Would isolate units but breaks cross-expression jumps that continuations rely on. The whole point is that the continuation jumps back into a prior compilation's instructions.

### 2. Emit `halt` in `mc-compile-and-go` only

The `halt` instruction is appended after the compiled expression in `mc-compile-and-go`. It is not emitted by `compile-file` or other compilation paths — those already handle boundaries correctly (separate spaces per file, or `execute-compiled-call` with past-end continue).

### 3. `halt` passes through assembler unchanged

The `halt` instruction has no operands and needs no operation resolution. Both the CL assembler (`resolve-operations`) and the ECE assembler (`ece-assemble-into-global`) handle it naturally — `resolve-operations` returns unknown instructions unchanged, and the ECE assembler pushes non-label non-pseudo items directly.

## Risks / Trade-offs

- **Instruction space growth**: Each `mc-compile-and-go` call adds one extra instruction. Negligible — the space already grows by tens of instructions per expression.
- **WASM executor**: The WAT `execute-instructions` dispatch loop needs the same `halt` case. Low risk — it's a single `br` to the loop exit.
- **Future instruction set changes**: `halt` is a permanent addition. This is fine — it's a natural instruction for any register machine and useful beyond this bug fix.
