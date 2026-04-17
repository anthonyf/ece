## Why

ECE has no way to inspect the bytecode of a compiled procedure at runtime. When a user wants to understand why a procedure behaves a certain way — or how the compiler lowered a particular form — they have no recourse short of reading the compiler and mentally executing it. Common Lisp programmers reach for `disassemble` reflexively; ECE programmers currently have nothing.

This is also the first concrete step on the diagnostics roadmap. Thread 4 (REPL inspector) and thread 6 (stepping) both need a way to display the instructions belonging to a single procedure. Shipping `disassemble` as a standalone feature makes the inspector and stepper work straightforward to scope later.

## What Changes

- Add a Scheme-visible `disassemble` procedure that accepts either a compiled-procedure value or a symbol, and prints the reachable instructions of that procedure to the current output port.
- Symbol inputs are resolved as global bindings in `*global-env*`; lexical bindings are out of scope (matches CL's `disassemble` semantics for symbol → fdefinition).
- Output format: header with procedure name and entry address, then one line per instruction showing `PC  label?  (source-form)`. Branch/goto targets are annotated with their resolved PC.
- Function extent is determined by a **reachability walk** from the entry PC, following fall-through, `goto`, `branch`, and save/restore-continue successors to fixed point. Inner lambdas are naturally excluded because the enclosing procedure only references their entry labels as constants, never as jump targets.
- Non-disassemblable inputs (primitives, continuations, ordinary values) print a clear human-readable error and return unspecified — no crash.
- Add one new host primitive `%procedure-name-ref` in `src/primitives.scm`, paired with the existing `%procedure-name-set!`. No other CL-kernel changes.
- The implementation itself is self-hosted in a new ECE source file (`src/disassemble.scm`) included in bootstrap. All other needed primitives already exist (`%space-source-ref`, `%space-instruction-length`, `%space-label-entries`, `%space-name`, `compiled-procedure?/entry/env`, `write-to-string-flat`).

### Deferred (explicitly out of scope)

- Source-location annotations — waits on diagnostics roadmap thread 5.
- Disassembling continuations — requires choosing how to render a captured stack.
- Showing the enclosing environment / closed-over bindings — inspector territory (thread 4).
- Cross-space jumps — v1 reachability walk stays within one space.
- A `make disasm`-style CLI entry point for live procedures — `disassemble` is called from the REPL.

## Capabilities

### New Capabilities
- `procedure-disassembler`: A user-facing `disassemble` procedure that prints the bytecode of a single compiled procedure (or a global binding resolved from a symbol) using a reachability walk to determine extent. Distinct from the existing `image-disassembler` capability, which dumps whole `.ecec` files from the CLI.

### Modified Capabilities
<!-- none -->

## Impact

- **New file**: `src/disassemble.scm` — self-hosted disassembler, added to the bootstrap compilation list.
- **CL kernel**: one new host primitive `%procedure-name-ref` in `src/primitives.scm` next to `%procedure-name-set!`. No other kernel changes.
- **Bootstrap**: two-pass required because the new primitive must exist in the CL kernel before `.ecec` files referencing it can boot. Standard primitive-migration dance (per CLAUDE.md "Two-pass bootstrap for primitive migration").
- **Tests**: new `tests/test-disassemble.scm` exercising compiled-procedure input, symbol input, primitive/non-procedure error paths, and reachability containment (inner lambdas excluded).
- **User-facing surface**: one new exported symbol `disassemble` from the ECE package.
- **No breaking changes**. No changes to existing instruction format, procedure representation, or compilation pipeline.
