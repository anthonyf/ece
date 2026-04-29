# ECE Language and VM Architecture

This document describes the current ECE language and virtual-machine design as implemented in `main`. It focuses on the live source tree, not historical OpenSpec plans.

## System Shape

ECE is a Scheme-like language implemented as a small register-machine kernel plus a self-hosted toolchain. The reader, compiler, assembler, standard library, syntax-rules expander, browser library, and disassembler are written in ECE source under `src/`. The Common Lisp runtime in [`src/runtime.lisp`](../../src/runtime.lisp) and the WebAssembly runtime in [`wasm/runtime.wat`](../../wasm/runtime.wat) execute the same instruction model and expose the primitive operations needed by the self-hosted code.

The normal source path is:

1. Read source forms with [`src/reader.scm`](../../src/reader.scm).
2. Expand macros during compilation through the compile-time macro table.
3. Compile expressions with [`src/compiler.scm`](../../src/compiler.scm) into register-machine instruction sequences.
4. Assemble instructions with [`src/assembler.scm`](../../src/assembler.scm) into a fresh code object.
5. Execute the code object on the CL or WASM runtime.
6. For files and bootstrap bundles, serialize code objects into `.ecec` archive sections with [`src/compilation-unit.scm`](../../src/compilation-unit.scm), then load those archive sections on the target runtime.

The major boot path is:

1. CL loads generated host primitive functions from [`bootstrap/primitives-auto.lisp`](../../bootstrap/primitives-auto.lisp), produced from [`primitives.def`](../../primitives.def) and [`src/primitives.scm`](../../src/primitives.scm).
2. CL loads generated `bootstrap/*-zone.lisp` files, when present, so native-zone functions register themselves.
3. CL loads [`bootstrap/bootstrap.ecec`](../../bootstrap/bootstrap.ecec), a concatenated bundle of `.ecec` archive sections for the self-hosted modules listed in `BOOTSTRAP_SRCS` in [`Makefile`](../../Makefile).
4. The WASM browser path builds an initial environment in [`wasm/glue.js`](../../wasm/glue.js), fetches `bootstrap.ecec`, and iterates the archive sections with `load_archive`, `load_archive_continue`, and `run_code_object`.

## Source Modules

| File | Role |
| --- | --- |
| [`src/boot-env.scm`](../../src/boot-env.scm) | First bootstrap module. Registers primitive IDs, assembler symbols, continuation/error symbols, and compatibility boot hooks. It deliberately avoids macros and prelude dependencies. |
| [`src/prelude.scm`](../../src/prelude.scm) | Standard library, derived forms, records, parameters, current ports, `dynamic-wind`, exception handling, value serialization, save/load helpers, and continuation save support. |
| [`src/reader.scm`](../../src/reader.scm) | ECE reader for lists, dotted pairs, vectors, characters, strings, string interpolation, hash table literals, comments, source locations, and symbols. |
| [`src/compiler.scm`](../../src/compiler.scm) | SICP-style metacircular compiler with lexical addressing, macro expansion, code-object lambda emission, `call/cc`, and `mc-compile-and-go`. |
| [`src/assembler.scm`](../../src/assembler.scm) | Pure assembler that fills one code object at a time and defines source `load`. |
| [`src/compilation-unit.scm`](../../src/compilation-unit.scm) | File compilation, `.ecec` archive writer/reader, code-object archive materialization, and bundle loading. |
| [`src/syntax-rules.scm`](../../src/syntax-rules.scm) | R7RS-style `syntax-rules` and `define-syntax` implemented on top of `define-macro`. |
| [`src/codegen-cl.scm`](../../src/codegen-cl.scm) | CL primitive code generator from primitive templates. |
| [`src/codegen-cl-inline.scm`](../../src/codegen-cl-inline.scm) | CL native-zone generator for archive code objects. |

## Reader and Surface Syntax

ECE source is read as S-expressions. The reader handles ordinary lists, dotted pairs, quoted forms, quasiquote/unquote/unquote-splicing reader syntax, vectors with `#(...)`, booleans, characters, numbers, strings, and comments.

Notable language extensions are:

- String interpolation: `"hello $name"` and `"sum $(+ a b)"` read into expressions using `string-append` and `write-to-string`; `$$` reads as a literal dollar sign.
- Hash table literals: `{name "Ada" age 37}` read as a `(hash-table 'name "Ada" 'age 37)` expression. Symbol keys in key position are quoted by the reader.
- Keyword-like symbols: `:foo` is treated as an ECE symbol and as a self-evaluating value by the compiler. This is important for hash-table internals and archive metadata.
- There is intentionally no R6RS pipe-escape stripping in the ECE reader. The primitive code generator relies on symbols whose printed names include pipe characters so generated CL can preserve lowercase data tags.

When `*source-file-name*` is set, the reader records source locations for list objects in `*source-locations*`. The compiler consumes this side table and can emit source-location markers for compile-file diagnostics. Current archive compilation records file-level origin in the archive wrapper, while detailed per-PC source maps remain limited and transitional.

## Macro Systems

ECE has two macro layers.

`define-macro` is the primitive macro system. A macro definition is compiled into an ECE procedure at compile time and stored in the runtime macro table via `set-macro!`. During compilation, if the operator of an application names an installed macro and is not lexically shadowed, the compiler calls the transformer with the unevaluated operands and compiles the expansion. `compile-file-to-archive` also rewrites top-level `define-macro` forms into runtime `set-macro!` expressions so the macro remains available when the compiled archive is loaded.

`define-syntax` and `syntax-rules` live in [`src/syntax-rules.scm`](../../src/syntax-rules.scm). They are implemented by generating `define-macro` transformers. The expander supports pattern variables, literals, `_`, ellipses, nested syntax-rules forms, and gensym-based renaming of introduced binding identifiers. It also wraps free symbols in operator position with `%global-ref` when needed. The compiler handles `%global-ref` through `lookup-global-variable`, bypassing lexical frames to preserve the intended global operator binding.

This gives ECE a useful hygienic pattern-macro layer, but it is not a Racket-style phase-separated syntax-object system. Macro transformers are ordinary ECE procedures and expansion state is a runtime table.

## Compiler

The compiler in [`src/compiler.scm`](../../src/compiler.scm) follows the SICP 5.5 structure:

- An instruction sequence is `(needs modifies instructions)`.
- `preserving` wraps sequences with `save` and `restore` when a register modified by one sequence is needed later.
- Linkage is expressed as `next`, `return`, or a label.
- Main registers are `env`, `proc`, `val`, `argl`, and `continue`; the executor also has `stack` and `flag`.
- The instruction language uses `assign`, `test`, `branch`, `goto`, `save`, `restore`, `perform`, and `halt`.

Core forms include `quote`, `if`, `lambda`, `begin`, `define`, `set!`/`set`, `apply`, `%raw-call/cc`, `define-macro`, `let-syntax`, `letrec-syntax`, `quasiquote`, and `%global-ref`. Most familiar Scheme forms such as `let`, `let*`, `letrec`, `cond`, `case`, `when`, `unless`, `and`, `or`, `do`, `loop`, `collect`, `parameterize`, `guard`, and `assert` are prelude macros.

Lexical variable access is compiled to `(op lexical-ref)` and `(op lexical-set!)` with `(depth . offset)` coordinates when the variable is found in the compile-time lexical environment. Otherwise variables compile to named lookup or mutation in the environment. Top-level definitions use `define-variable!`, which mutates the first hash-table-backed global frame.

Internal definitions are handled by scanning bodies for `define` forms, including definitions that appear after macro expansion. Lambda compilation extends the compile-time lexical environment with formal parameters plus internal definition slots. At runtime, `extend-environment` creates vector frames with extra slots for those internal definitions.

### Lambda and Code-Object Emission

The compiler has two lambda emission modes:

- Label-based emission embeds lambda bodies as labels in a single instruction stream.
- Code-object emission compiles lambdas bottom-up. Each lambda body becomes its own code object, and the outer code object references it as a constant operand of `make-compiled-procedure`.

The current `mc-compile-to-code-object` path binds `*emit-code-object-lambdas*` to true, assembles the expression into a fresh `%make-code-object`, appends `halt`, and returns the code object without executing it. `mc-compile-and-go` calls that path and then runs `execute-code-object`.

Function names and arity metadata are attached directly to the inner code object for `(define (name args...) ...)`. Older procedure-name and procedure-params side tables are retired.

### Calls, Tail Calls, and `call/cc`

Procedure calls evaluate the operator into `proc`, operands into `argl`, then dispatch among primitive procedures, compiled procedures, continuations, and parameters.

Compiled procedure calls jump to the procedure entry stored in the closure. In tail position with target `val` and linkage `return`, the compiler emits a direct jump to the callee entry while preserving the caller's `continue`, giving tail calls constant ECE stack use.

`call/cc` is compiled as `%raw-call/cc`. It captures `(stack, continue, winding-stack)` into a continuation object. Invoking a continuation sets `val`, runs `do-continuation-winds`, restores the saved `stack` and `continue`, and jumps to the saved continuation address. There is a separate tail-position `call/cc` path that avoids adding a return trampoline.

## Assembler and Code Objects

The assembler is intentionally small. `assemble-into-code-object` walks an instruction list:

- Bare symbols are labels and are registered at the current local PC.
- Procedure metadata pseudo-instructions are ignored in the current code-object path.
- Source-location markers are ignored after source-map extraction.
- Real instructions are appended with `%code-object-push-instruction!`.

A CL code object is a struct with:

- `source-instructions`: the raw instruction vector.
- `resolved-instructions`: an instruction vector where `(op name)` references are resolved to host operation functions.
- `labels`: local label table.
- `name`, `arity`, and `source-loc` metadata.
- `native-fn`: optional CL native-zone function.
- `archive-key`: `(file-stem . index)` for archive-registered code objects.

WASM has a parallel `$code-object` struct with instruction storage, label storage, metadata, `native-fn`, and `archive-key`. Some introspection primitives expose less on WASM than on CL; for example raw instruction vectors are not returned as ECE-visible vectors on WASM.

Closures are tagged compiled-procedure values containing an entry and an environment. In the current per-code-object path, the entry is normally a bare code object, meaning PC 0 of that code object. Continuation addresses and some older paths can use `(code-object . pc)` pairs.

## Archive Format

The current file compiler writes `.ecec` archive sections. A bundle is one or more archive sections concatenated.

The current writer emits keyword-style ECE symbols:

```scheme
(:ecec-archive
  :version 2
  :file "prelude.scm"
  :entries ((:code-object :name #f :arity #f ...)))
```

Loaders also accept the older plain-symbol spelling, such as `(ecec-archive version 2 ...)`, during the transition. Version `2` is required.

Each archive section has:

- `:file`: the source basename.
- `:entries`: one code-object entry for the file init plus all nested lambdas reachable from it.
- Entry 0: the init code object produced by wrapping all top-level forms in `(begin ...)`.
- Entries 1..N: nested lambda code objects collected by DFS reachability order.
- `:instructions`: source-form instructions, not pre-resolved host function pointers.
- `:labels`: local label table for that code object.
- `:name`, `:arity`, and `:source-loc` metadata.

Nested code-object constants are rewritten to `(co-ref N)` on disk. Loading is two-pass:

1. Allocate all code objects and populate metadata and labels.
2. Patch `(const (co-ref N))` operands back to live code-object references, push instructions, and rebuild resolved instructions.

`compile-system` writes one archive section per input source file and concatenates them into a bundle. The bootstrap bundle is built from `src/boot-env.scm`, `src/prelude.scm`, `src/compiler.scm`, `src/reader.scm`, `src/assembler.scm`, `src/compilation-unit.scm`, `src/syntax-rules.scm`, `src/browser-lib.scm`, and `src/disassemble.scm`.

## Environments and Globals

Environments are chains of frames. Local lexical frames are vectors for O(1) lexical access by depth and offset. The global frame is hash-table-backed for named top-level lookup, definition, mutation, and introspection.

The compiler chooses lexical access when a binding is known at compile time. Otherwise it emits named lookup/mutation. `define-variable!` skips vector frames and writes into the first hash frame; `set-variable-value!` searches hash frames by name and skips vector frames. `%global-ref` bypasses local frames entirely by reading from `*global-env*`.

This model makes the REPL, `load`, and ordinary file archive execution share
one mutable top-level environment. Module archive sections are separate runtime
units: each module instantiates once into a private hash-table-backed module
environment, imports declared bindings from dependency module exports, and
publishes only its declared exports. Loading a bundle first registers module
sections and their code objects, then instantiates modules in dependency order.
File sections still execute immediately for compatibility.

The CLI can run a module export as an application entry point:

```sh
ece --module '(app main)' --entry main app.ecec
```

`run-module-export` resolves the module instance, looks up the exported symbol,
requires it to be callable, and applies it.

## Parameters, Exceptions, and `dynamic-wind`

Parameters are mutable cells represented as parameter objects. Applying a parameter with no arguments reads its value; one argument sets it through its converter; two arguments perform a raw set used by `parameterize`.

`parameterize` is a macro in the prelude. It records old and new values and uses `dynamic-wind` to install the new value on entry and restore the old value on exit, including non-local exits through continuations or exceptions.

`dynamic-wind` maintains `*winding-stack*`, a list of `(before . after)` pairs. Continuations capture this winding stack. On continuation invocation, `do-continuation-winds` computes the shared tail between current and target stacks, runs after thunks for exited extents, and before thunks for entered extents.

Exceptions are implemented in ECE with `raise`, `with-exception-handler`, `guard`, and `error-object` records. Primitive type errors and division by zero are bridged from the runtime into ECE-level `error` when possible, making many primitive failures catchable by `guard`.

## Value Serialization and Save/Load

The prelude implements `serialize-value` and `deserialize-value` for Scheme values, shared structure, cyclic pairs, vectors, hash tables, parameters, primitives, compiled procedures, continuations, environment frames, and code objects. Archive-registered code objects serialize by reference as `(%ser/co-ref stem index fingerprint)` when the runtime can compute a fingerprint. Anonymous or REPL-created code objects can serialize inline.

Continuations serialize their saved stack, continuation entry, and complete `dynamic-wind` stack. Wind frames must serialize losslessly so restored continuations can replay their `before` and `after` thunks through `do-winds!`. If a wind frame closes over host-only state such as a port or stream, serialization raises `ece-serialization-unserializable-wind-error` instead of silently stripping the frame. `save`, `load-saved`, and `save-continuation!` provide file-based save/restore helpers.

This serialization layer depends on archive code-object registry state when deserializing by-reference code objects. Loading a saved continuation that refers to archive code objects requires the corresponding archive to be loaded first, and fingerprinted saves require the loaded archive entry to match the code that was present at save time. The full policy is documented in [`save-restore-compatibility.md`](save-restore-compatibility.md).

## Primitive and Operation Dispatch

ECE separates user-facing primitives from internal register-machine operations.

Primitives are declared in [`primitives.def`](../../primitives.def) with stable numeric IDs and platforms. CL implementations are generated from templates in [`src/primitives.scm`](../../src/primitives.scm) into `bootstrap/primitives-auto.lisp`; WASM implements primitive dispatch manually by numeric ID. ECE-platform functions are implemented in the prelude and registered as ordinary bindings.

Internal machine operations are declared in [`operations.def`](../../operations.def). CL resolves `(op name)` to host functions through `resolve-operations` when instructions are pushed into a code object. WASM maps operation IDs during instruction parsing and dispatches through `$dispatch-op`.

## CL Runtime

The CL runtime owns:

- The Scheme false sentinel distinct from CL `nil`.
- Environment frames and named global lookup/mutation.
- Primitive and operation dispatch tables.
- Code-object structs and resolved-instruction vectors.
- The register-machine executor.
- Archive parsing during cold boot before the ECE-side archive loader exists.
- Native-zone registration and dispatch.
- Host I/O, filesystem, process, port, and CL-only support.

`execute-instructions` is a single fetch/decode/execute loop over a current code object and PC. It dynamically stores register values in CL locals, uses a CL list as the ECE stack, and updates the current code object on cross-procedure jumps. It catches host errors and wraps them with ECE procedure, argument, environment, instruction, and backtrace context.

The executor has a compiled-zone hook. When entering a code object, it checks `code-object-native-fn`. If present, it calls the generated CL zone function with the current register set and receives updated register values and PC. If absent, it continues in the interpreter.

## Native Zones

Native zones are generated CL functions for individual archive code objects. [`src/codegen-cl-inline.scm`](../../src/codegen-cl-inline.scm) reads archive code objects, emits one `zone-...` CL function per code object, and writes a self-registration form that stores the function in `*archive-zone-fns*` under `(file-stem . index)`.

Boot loads zone files before `bootstrap.ecec`. Then the archive loader materializes code objects and calls `attach-archive-native-fns`, attaching matching zone functions to the `native-fn` slot. This makes native dispatch an optional acceleration layer over the same code-object identity, environment, stack, primitive dispatch, continuation, and `dynamic-wind` state.

Zones can fall back to the interpreter by returning updated registers. This preserves a single semantic model while allowing CL-only native execution for code objects that have generated zones.

## WASM Runtime

The WASM runtime is hand-written WAT using WasmGC. It represents values as `ref eq`, with special structs for false, true, nil, eof, void, primitives, continuations, parameters, ports, hash tables, JS references, and code objects. Fixnums use `i31ref`; floats are boxed.

WASM implements:

- Environment frames as WasmGC structs with names, values, and an enclosing pointer.
- The same instruction opcodes and register-machine dispatch.
- Code-object loading from text `.ecec` archives.
- Primitive dispatch by stable numeric ID.
- Continuation capture and invocation.
- A winding-stack mirror used by continuation capture and `dynamic-wind`.
- Browser I/O, localStorage-backed file ports, canvas primitives, JavaScript FFI, and handle-table interop.

The JS glue creates the global environment, registers boot primitives needed by `boot-env.ecec`, initializes assembler symbol IDs for the WAT archive loader, defines `#t`, `#f`, and `*global-env*`, fetches `bootstrap.ecec`, and executes each archive init code object in order.

WASM currently does not use the CL native-zone pipeline. Its `native-fn` field exists for structural parity, but there is no generated WAT zone loader equivalent to `bootstrap/*-zone.lisp`.

The intended next step is an ECE-authored WASM host layer plus a WASM native-zone
registry. JavaScript should provide only browser capabilities such as root VM
instantiation, `fetch`, side-module instantiation, and promise/import-object
bridging. ECE code should own archive reload policy, native-zone manifest
parsing, `(unit-id . co-index)` registration, and interpreter fallback.
That design is documented in [`wasm-native-zone-plan.md`](wasm-native-zone-plan.md).

## Current Parity Boundaries

The core language, reader/compiler/assembler pipeline, archive loading, code-object execution, tail calls, `call/cc`, parameters, `dynamic-wind`, exceptions, and many tests run across CL and WASM.

Important parity boundaries remain:

- CL has generated native zones; WASM runs code objects through the WAT interpreter.
- CL exposes raw code-object instruction vectors; WASM stubs some raw instruction-vector introspection.
- CL has real filesystem/process primitives; WASM maps file I/O to localStorage and stubs or browser-implements several process/filesystem operations.
- CL cold boot can parse archives with the CL reader; WASM has its own WAT-native archive reader with separate validation and failure modes.

## Reference Links

- Local source: [`src/compiler.scm`](../../src/compiler.scm), [`src/compilation-unit.scm`](../../src/compilation-unit.scm), [`src/runtime.lisp`](../../src/runtime.lisp), [`wasm/runtime.wat`](../../wasm/runtime.wat), [`wasm/glue.js`](../../wasm/glue.js), [`primitives.def`](../../primitives.def), [`operations.def`](../../operations.def).
- Existing archive reference: [`bootstrap/README.md`](../../bootstrap/README.md). Note that parts of that document describe the older plain-symbol archive spelling; current code emits keyword-style tags while still accepting legacy plain-symbol tags.
