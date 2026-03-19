## 1. Operation Table Infrastructure

- [x] 1.1 Build operation table extraction — walk the global instruction vector, collect unique `op-fn` function objects, assign each an index, produce a table (vector of functions) and a mapping from function object to index
- [x] 1.2 Add `*compiled-zone-op-table*` to runtime.lisp — a global variable holding the operation table, populated at codegen time

## 2. CL Codegen Tool (ECE)

- [ ] 2.1 Create `src/codegen-cl.scm` with the core codegen function that walks the instruction vector and emits CL source text
- [ ] 2.2 Implement instruction translation — emit CL code for each instruction type: `assign` (const, reg, label, op-fn), `test`, `branch`, `goto` (label, reg), `save`, `restore`, `perform`
- [ ] 2.3 Implement `goto (reg ...)` zone-exit check — emit code that checks if target PC is within compiled zone range, dispatches to label if yes, returns registers if no
- [ ] 2.4 Implement entry dispatch — emit a `case` form at function entry that jumps to the label matching the starting PC
- [ ] 2.5 Implement operation table references — replace `op-fn` function objects with `(aref *compiled-zone-op-table* N)` lookups in emitted code
- [ ] 2.6 Emit the complete CL `defun` wrapping — `tagbody`, register bindings, `return-from` on zone exit, return `val` on completion
- [ ] 2.7 Emit operation table initialization code — generate the `defun` or `let` form that populates `*compiled-zone-op-table*` from the instruction vector at load time

## 3. Dual-Zone Executor

- [x] 3.1 Add `*compiled-zone-function*` and `*compiled-zone-limit*` globals to runtime.lisp
- [ ] 3.2 Implement `ece-dual-zone-execute` — outer loop that dispatches to compiled zone or interpreter based on PC range, passing registers via multiple values
- [ ] 3.3 Modify interpreter (`execute-instructions`) to return registers on zone exit — when a `goto (reg ...)` targets a PC in the compiled zone, return `(values pc val env proc argl continue stack)` instead of looping
- [ ] 3.4 Wire `execute-from-pc` to use dual-zone executor when a compiled zone is loaded, fall back to standard interpreter otherwise

## 4. Build Workflow Integration

- [ ] 4.1 Add `(codegen-cl filename)` entry point in ECE that runs the codegen and writes the output file
- [ ] 4.2 Add a CL-side `load-compiled-zone` function that loads the generated file and sets `*compiled-zone-function*` and `*compiled-zone-limit*`
- [ ] 4.3 Document the build workflow: compile image → codegen → load compiled zone → run

## 5. Testing

- [ ] 5.1 Verify existing test suite passes with dual-zone executor (no compiled zone loaded — pure interpreter fallback)
- [ ] 5.2 Generate a compiled zone from the current image's instruction vector, load it, and run the full test suite
- [ ] 5.3 Add cross-zone boundary tests — compiled code calling REPL-defined functions, REPL code calling compiled functions
- [ ] 5.4 Add call/cc cross-zone tests — capture continuation in compiled zone, invoke from dynamic zone, and vice versa
- [ ] 5.5 Add function redefinition test — redefine a compiled function from the REPL, verify subsequent calls use the new definition

## 6. Benchmarking

- [ ] 6.1 Benchmark: run TCO iteration test (1M iterations) in interpreter-only mode and dual-zone compiled mode, compare
- [ ] 6.2 Benchmark: run a representative workload (image rebuild or test suite) in both modes, compare
- [ ] 6.3 Document results and assess whether the speedup justifies the complexity for future WASM/JS backends
