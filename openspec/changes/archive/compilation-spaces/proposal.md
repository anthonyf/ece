## Why

ECE stores all compiled instructions in a single global vector. Every procedure address, continuation return point, and label is an absolute offset into this one array. This creates three problems: (1) the monolithic vector cannot be compiled to host code in one piece — SBCL overflows compiling 62K instructions as a single unit, (2) recompiling one file invalidates every PC in every file loaded after it, making incremental compilation impossible, and (3) the entire vector must be serialized/deserialized as a blob, preventing the per-file host-code image format that eliminates the binary serializer for browser targets.

Splitting the instruction vector into per-file **compilation spaces** — each with its own instruction array and local PCs — solves all three problems. Each space is small enough to compile independently, has stable addresses unaffected by other spaces, and maps 1:1 to a host compilation unit (FASL, `.wasm` module, or `.js` file). This is well-established prior art: Erlang/BEAM manages code per-module with hot reload, Chez Scheme compiles files to independent `.so` objects, and the JVM links per-class bytecode units via symbolic references.

## What Changes

- **Per-file instruction spaces**: Each `(load ...)` or `(compile-and-go ...)` targets its own instruction array instead of appending to the global vector. PCs become space-local offsets (0-based per space).
- **Space-qualified procedure addresses**: `make-compiled-procedure` stores `(space-id . local-pc)` instead of a bare integer. `compiled-procedure-entry` returns this pair. Continuations capture space-qualified addresses in `continue`.
- **Space registry**: A runtime table mapping space IDs to their instruction arrays (and, when compiled-to-host, their compiled code functions). New spaces are registered on `(load ...)`.
- **Single-loop executor**: `execute-instructions` tracks the current space-id and instruction array as local variables. Cross-space jumps update these locals inline — no throw/catch, no dispatcher function, no allocation per transition.
- **Codegen per space**: The codegen emits one host file per space instead of one monolithic file. Each generated file is independently compilable. The collection of compiled spaces IS the image.
- **`save-image!` redefined**: Instead of serializing the instruction vector to a binary blob, saving an image means emitting the set of compiled host files plus environment reconstruction code. `load-image!` becomes loading those files in order.
- **REPL space**: REPL expressions compile into an ephemeral space that is interpreted (dynamic zone). This replaces the dual-zone "compiled limit" concept with a cleaner per-space property: each space knows whether it has compiled host code or runs interpreted.

### What is NOT changing

- **Register machine architecture**: all six registers (`val`, `env`, `proc`, `argl`, `continue`, `stack`), the stack, control flow via `goto`/`branch`/`save`/`restore` — unchanged.
- **`call/cc`**: Continuations capture register state + stack. The `continue` register now holds a space-qualified address instead of a bare PC, but the capture/restore mechanism is identical.
- **TCO**: Tail calls are `goto` instructions. Within a space, they're direct jumps. Across spaces, the executor swaps its local instruction array reference with no stack growth.
- **The ECE compiler**: Still compiles `.scm` to register machine instructions. The assembler targets a space instead of the global vector.
- **Global environment**: Variable lookup remains `lookup-variable-value` against `*global-env*`. No namespace changes. Cross-space procedure calls resolve through the environment, not through linking.

## Capabilities

### New Capabilities
- `compilation-space`: Runtime representation of a compilation space — an instruction array with local PCs, a local label table, and metadata (source file, compiled-host-code function). Includes space registry, creation, lookup, and the space-qualified address representation.
- `space-aware-codegen`: Per-space code generation that emits one host file per space. Replaces the monolithic codegen from `compile-to-host-cl`. Each generated file is independently compilable and loadable.

### Modified Capabilities
- `instruction-executor`: The executor is a single loop with space-id and instruction array as local variables. Cross-space jumps update these locals inline — no throw/catch, no dispatcher, no allocation.
- `compile-and-go`: `mc-compile-and-go` and `assemble-into-global` target a specific space instead of the single global vector.
- `image-serialization`: The image format becomes a collection of per-space host files plus environment state, replacing the monolithic binary blob. The binary format remains available as a fallback for CL development.

## Impact

- **`src/runtime.lisp`**: New space registry data structures. `make-compiled-procedure` / `compiled-procedure-entry` change to use space-qualified addresses. `execute-instructions` gains `space-id`/`instrs`/`ltab` locals for inline space switching (replaces throw/catch + `execute-space-dispatch`). `assemble-into-global` targets a space.
- **`src/assembler.scm`**: `ece-assemble-into-global` modified to target a named space. New `create-space` / `register-space` primitives.
- **`src/compiler.scm`**: `mc-compile-and-go` passes space context to assembler. Minimal changes — the compiler doesn't know about spaces, only the assembler does.
- **`src/codegen-cl.lisp`**: Rewritten to iterate spaces and emit one file per space. Each file is small and independently compilable, eliminating the SBCL stack overflow blocker.
- **`load` in `assembler.scm`**: Each `(load "file.scm")` creates a new space named after the file.
- **Image format**: `save-image!` emits per-space host files + environment. `load-image!` loads them. Binary image format retained as fallback.
- **Continuation representation**: Continuations captured by `call/cc` now contain space-qualified PCs. Compatible with cross-space invocation via the inline space switch.
- **`compile-to-host-cl` change**: This proposal supersedes the chunking approach in that change. The per-space architecture solves the same problem (SBCL can't compile one huge file) with a cleaner design that also enables incremental compilation and maps directly to WASM modules.
- **Browser port (Phase 2)**: Each space becomes a `.wasm` module or `.js` file. No binary serializer/deserializer needed. The image is the collection of compiled space files.
