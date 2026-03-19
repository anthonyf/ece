## Why

ECE's executor dispatches each instruction at runtime via a `case` form inside a `tagbody/go` loop. A codegen tool that translates the instruction vector into direct host code eliminates per-instruction dispatch overhead and enables the host compiler to optimize across instruction boundaries.

More significantly, the codegen output can serve as the **image format itself** for non-CL targets. Instead of serializing the instruction vector to a binary image and shipping a deserializer + interpreter, the codegen emits a self-contained host-language file that includes both the compiled code and the environment setup. For the browser, this means the `.js` or `.wasm` file IS the image — no binary serializer, no deserializer, no interpreter needed for shipped games. This eliminates ~550 lines of CL image serialization code from the porting surface.

The register machine is preserved — it's what gives ECE `call/cc`, TCO, and continuations. The codegen doesn't replace the register machine; it compiles the register machine instructions to native host operations instead of interpreting them. The six registers (`val`, `env`, `proc`, `argl`, `continue`, `stack`) remain explicit local variables. `goto (reg continue)` becomes a host-level jump. `save`/`restore` become push/pop on the stack variable. `call/cc` captures the same register state and stack — it just happens to be running as native code instead of interpreted bytecode.

This is Phase 1: proving the compile-to-host pattern on CL before building WASM and JS backends.

## What Changes

- **New codegen tool**: walks the global instruction vector and emits host source code that directly manipulates registers — no dispatch loop, no `case` form per instruction. The register machine architecture is preserved: all six registers, the stack, `goto (reg continue)` for returns, `save`/`restore` for the control stack.
- **Environment emission**: the codegen also emits host code to reconstruct the global environment, macro table, and procedure name table. The generated file is self-contained — it IS the image.
- **Dual-zone executor** (CL only): pre-compiled code runs as native CL (the compiled zone), while REPL and `(load ...)` code runs on the existing interpreter (the dynamic zone). Both zones share registers, stack, environment, and primitives. This is needed on CL for interactive development but may not be needed for shipped browser games.
- **New build step**: `(codegen-cl)` or similar entry point that reads the current instruction vector and environment and writes a `.lisp` file containing the complete image as host code.

### What is NOT changing

- **Register machine architecture**: all six registers, the stack, control flow via `goto`/`branch`/`save`/`restore` — unchanged.
- **`call/cc`**: continuations capture register state + stack. This works identically whether the code is interpreted or compiled to host — the registers and stack are the same local variables either way.
- **TCO**: tail calls are `goto` instructions in the register machine. The codegen emits these as host-level jumps (`go` in CL, jump in WASM). No stack growth, same as the interpreter.
- **The ECE compiler**: it still compiles `.scm` to register machine instructions. The codegen is a second pass that translates those instructions to host code.

## Capabilities

### New Capabilities
- `cl-codegen`: Codegen tool that translates ECE instruction vectors into CL source code. Covers instruction translation, label resolution, operand evaluation, environment emission, and output formatting. Produces a self-contained host file that serves as the image.
- `dual-zone-executor`: Executor that supports two zones — a pre-compiled native code zone and an interpreter zone — sharing the same machine state. Covers zone boundary detection, cross-zone calls/returns, and continuation compatibility.

### Modified Capabilities
- `instruction-executor`: The executor gains awareness of compiled zones and delegates to native code when PC falls within the compiled range.

## Impact

- **src/runtime.lisp**: `execute-instructions` modified to support dual-zone dispatch. New function to load/invoke compiled zone code.
- **New file** (`src/codegen-cl.lisp`): The codegen tool, initially in CL. Generates self-contained CL source files.
- **Build workflow**: New step after compilation — emit host code from the instruction vector and environment. The generated file can replace the binary image for deployment.
- **Binary image format**: Unchanged and still used for CL development workflow (faster to load than re-evaluating generated source). The codegen output is an alternative image format for deployment and cross-platform targets.
- **Browser port (Phase 2)**: The codegen architecture established here directly applies to WASM/JS backends. The browser "image" will be the codegen output — no binary serializer/deserializer needed in the WASM runtime.
- **Test suite**: New tests for codegen output correctness, dual-zone boundary crossing, and call/cc across zones. Existing tests must continue to pass.
