## Why

ECE currently compiles a whole `.scm` file into a single shared instruction vector ("compilation space"). Procedures inside a file live concatenated and are identified by a PC offset within that space. This makes natural procedure-level operations — disassembling, source-mapping, attaching native code, GC'ing redefined procedures — require working around a compilation unit that doesn't match the natural boundary.

Concretely:

- `disassemble` (shipped in PR #162) needs a reachability walk to carve a procedure out of a shared instruction vector. The walk is a workaround for the wrong unit of identity.
- Compile-to-host (roadmap item) wants one host function per procedure. Today's tagbody-over-a-whole-file approach exists because there's no procedure-sized unit to target.
- REPL redefinition leaks: the old procedure's instructions stay in the REPL space forever because there's no garbage-collectible boundary around them.
- Dybvig's 1987 dissertation and every production Scheme since (Chez, Ikarus, Gambit, Chicken, Guile) use the procedure as the compilation unit. Our divergence is a teaching-era artifact, not an intentional design.

Doing this now, right after shipping `disassemble`, means we fix the smell the feature revealed before more code comes to depend on it.

## What Changes

Three locked design decisions (confirmed during /opsx:explore):

- **D1. Code objects are first-class at the ECE level.** A `code-object` is an ECE value containing the compiled instructions, the per-procedure label table, arity metadata, source location, and a slot for a native function. Users can pass code objects around, and the compiler returns them as values.
- **D2. Closure = `(compiled-procedure <code-object> <env>)`.** The entry field — today `(space-id . local-pc)` — becomes a code-object value. The env slot remains today's rib-chain env, unchanged.
- **D3. The compiler is a pure function: `(compile expr) → code-object`.** No mutation. Nested lambdas compose via bottom-up compilation: the inner's code object becomes a constant referenced by the outer's "make-compiled-procedure" instruction.

Derived changes:

- **Kill `*space-registry*` and the `compilation-space` struct.** Replaced by code-object values (self-identifying, naturally GC'd when unreferenced).
- **`.ecec` format becomes an archive of code objects.** One file may contain many (preserving the "one .ecec per .scm" bootstrap shape). Internals change from one flat header+body to a sequence of code-object blobs. **BREAKING** at the .ecec file-format level — regeneration via two-pass bootstrap required.
- **Executor dispatches on code objects, not `(sid . pc)` pairs.** `execute-instructions` tracks the current code object rather than the current space.
- **`%space-*` primitives retire; `%code-object-*` primitives replace them where still needed.** Most uses in `disassemble` drop out entirely because the code object is self-describing.
- **`%procedure-name-set!` / `%procedure-name-ref` become metadata accessors on the code-object itself** (not a side table keyed on `(sid . pc)`).
- **`disassemble` simplified.** Reachability walk retired. Implementation shrinks from ~200 lines to ~20.
- **Compile-to-host positioning.** Each code object has a `native-fn` slot. Populating it is out of scope here, but the slot is now the natural place to wire it.

Explicitly deferred to separate future proposals:

- Display closures / free-variable indices (Dybvig §4.4, Chez's production model). Closure stays `(code . env)` with rib-chain env. The code-object struct leaves room for a future `free-vars` field without a schema break.
- Stack-based call frames (Dybvig Ch 4). Current heap-allocated env/frames unchanged.
- Code-object equality beyond `eq?`.
- Inspector / stepper (diagnostics roadmap threads 4, 6) — unlocked by this change, not implemented here.

Non-goals:

- No R7RS semantic changes.
- No call/cc, dynamic-wind, continuation, or exception-handling changes.
- No changes to lexical-ref addressing `(m n)`.
- No changes to `*global-env*` structure or access.
- No changes to primitive dispatch.

## Capabilities

### New Capabilities

- `code-object-compilation`: The code-object value type (instructions, labels, metadata, native-fn slot), the pure `(compile expr) → code-object` entry point, and executor dispatch on code objects.

### Modified Capabilities

- `ece-assembler`: `assemble` becomes pure and returns a code object instead of appending to a shared global instruction vector.
- `compile-system`: Output is a code-object archive; the "multi-space .ecec bundle" shape retires.
- `procedure-disassembler`: Accepts code-object values directly; reachability-walk requirement removed.
- `procedure-name-table`: Name is a metadata field on the code object, not a side table keyed on `(space-id . local-pc)`.
- `symbol-space-id`: Runtime space-id identity retires entirely (all four existing requirements removed).

The following capabilities change in implementation only — their requirements survive this change unchanged, so no delta spec is included: `compiler-core`, `instruction-executor`, `compile-and-go`, `operations-manifest`, `bootstrap-compilation`, `image-disassembler`, `compiled-zone-splitting`. Delta specs for these will be added if and when requirement-level changes surface during implementation.

## Impact

- **Code**: `src/compiler.scm`, `src/assembler.scm`, `src/compilation-unit.scm`, `src/disassemble.scm`, `src/primitives.scm`, `src/runtime.lisp`, `bootstrap/*`, `wasm/runtime.wat`, `primitives.def`.
- **File format**: `.ecec` is **BREAKING**. All checked-in `.ecec` files under `bootstrap/` and `share/ece/` must be regenerated. No automatic migration — regeneration via `make bootstrap` is required. Old `.ecec` files become unloadable after this lands.
- **User-visible API**: The Scheme surface is unchanged. `disassemble` still takes a procedure or a symbol. `(compile expr)` if exposed to users returns a code object; today it's not a user API.
- **Performance**: Same-procedure calls are unchanged. Intra-file helper calls shift from same-space to cross-space dispatch (~50–80ns extra per call). Bootstrap startup has a one-time ~100–500ms cost from many small code-object inits. Hot paths that dominate real programs (self-recursion, higher-order, cross-file calls) are unaffected.
- **Dependencies**: None new.
- **Migration**: Two-pass bootstrap (new primitives first, then regenerate under new format). Documented in CLAUDE.md's existing "two-pass bootstrap for primitive migration" convention.
