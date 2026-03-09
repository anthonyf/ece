## Context

ECE currently uses an explicit control evaluator (SICP Chapter 5.4) — a register machine interpreter with registers `stack`, `conts`, `val`, `unev`, `argl`, `proc`, `env` and a ~1200-line `case` dispatch loop with ~30 labels. Every expression is type-checked at runtime via a 13-way `cond` in `:ev-dispatch`, and operand evaluation conservatively saves/restores registers on the stack even when unnecessary.

SICP Chapter 5.5 describes a compiler for the same language that targets the same register machine. The compiler analyzes expressions at compile time, emits only the necessary register operations, and eliminates dispatch overhead entirely.

## Goals / Non-Goals

**Goals:**
- Implement a compiler following SICP 5.5 that compiles ECE expressions to register machine instruction sequences
- Use the `preserving` combinator with register metadata (needs/modifies) to eliminate unnecessary save/restore
- Handle all current expression types: self-eval, variable, quoted, quasiquote, if, lambda, begin, application, define, set, call/cc, define-macro, apply
- Macro expansion at compile time
- Replace `evaluate` with `compile-and-go` so all code runs compiled
- Maintain full `call/cc` support with compiled code
- All existing tests pass unchanged

**Non-Goals:**
- Bytecode or native compilation (list-based instructions are the target for now; bytecode is a future optimization with a clean upgrade path)
- Lexical addressing / compile-time environment (future optimization)
- Optimization passes beyond `preserving` (constant folding, inlining, etc.)
- Source maps or debug info

## Decisions

### 1. Instruction representation: lists

Instructions are lists like `(assign val (const 42))`, `(test (op false?) (reg val))`, `(branch (label L1))`, `(goto (reg continue))`.

**Rationale:** Matches SICP directly. Easy to inspect and debug. The assembler/executor can be swapped to bytecode later without changing the compiler — only the encoding and dispatch change.

**Alternatives considered:**
- CL structs: Faster access but harder to inspect. Premature optimization.
- Bytecode vectors: Best performance but more complex assembler. Clean upgrade path from lists means we can defer this.
- Compile to CL closures: Fastest execution but loses `call/cc` (CL has no first-class continuations).

### 2. Instruction sequence abstraction: (needs modifies instructions)

Each compiled chunk is a triple `(needs modifies instructions)` where:
- `needs`: set of registers read before any write
- `modifies`: set of registers written
- `instructions`: list of instruction forms

The `preserving` combinator wraps save/restore around two sequences only when the first modifies a register the second needs. This is the core optimization — the interpreter does ~44 stack ops per loop iteration; the compiler can reduce this to near zero.

**Rationale:** Direct from SICP 5.5.4. Proven correct. Simple implementation.

### 3. Compiled procedure representation

A new procedure type `(compiled-procedure entry-label env)` where `entry-label` is an index/label into the compiled instruction vector. The executor's apply-dispatch handles three types: `primitive`, `compiled-procedure`, and `continuation`.

The old `(procedure params body env)` type (interpreted closures) is eliminated — all lambdas compile to `compiled-procedure`.

**Rationale:** Since `evaluate` becomes `compile-and-go`, there are no interpreted closures. Only compiled procedures and primitives.

### 4. Replace evaluate entirely

`evaluate` calls `compile-and-go` which compiles the expression and executes the resulting instructions. The interpreter dispatch loop is deleted.

**Rationale:** Single execution model. No need to maintain two code paths. No interop complexity between compiled and interpreted code. The REPL gets compiled speed.

### 5. Macro expansion at compile time

When the compiler encounters `(define-macro ...)`, it stores the macro in the compile-time environment. When it encounters a macro application, it expands inline during compilation and compiles the expanded form. No `:macro-apply` / `:macro-apply-result` at runtime.

**Rationale:** Standard compiler behavior. Eliminates runtime macro expansion overhead. Macros must be defined before use (already the case with the prelude loading order).

### 6. call/cc with compiled code

`call/cc` compiles to instructions that capture `(copy-list stack)` and `(copy-list conts)` — the same mechanism as the interpreter. The captured continuation is a `(continuation stack conts)` object. Applying it restores the registers.

This works because compiled code uses the same stack and conts registers. The stack may have fewer entries (due to `preserving` optimization), making captured continuations smaller.

**Rationale:** No change to the continuation model. `call/cc` is central to ECE's purpose (save/restore for IF). Must work identically.

### 7. Compilation of the prelude

`compile-file` compiles all forms in a file sequentially, handling `define-macro` forms by registering macros in the compile-time environment so subsequent forms can use them. The prelude bootstraps naturally since macros like `let`, `cond`, `and`, `or` are defined before they're used.

**Rationale:** Prelude already has a natural definition order. No changes to `prelude.scm` needed.

## Risks / Trade-offs

- **[Correctness risk]** The compiler must handle every expression type the interpreter handles. → Mitigation: All existing tests pass through `evaluate` which now calls `compile-and-go`. The test suite is the safety net.

- **[Macro bootstrap]** Macros must be defined before use at compile time. → Mitigation: Already the case — the prelude defines macros in dependency order. Document as a language constraint.

- **[Debugging difficulty]** Compiled code is harder to trace than interpreter labels. → Mitigation: Keep list-based instructions (inspectable). Consider adding a debug/trace mode later.

- **[Big bang risk]** Replacing the interpreter entirely in one change is high-risk. → Mitigation: Build compiler alongside interpreter first, validate with tests, then swap `evaluate` to `compile-and-go` as the final step.
