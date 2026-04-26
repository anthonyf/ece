# ECE Language and VM Architecture Review

This review is based on the factual model in [`language-and-vm.md`](language-and-vm.md) and the current source tree. It compares ECE against three reference points:

- SICP 5.4 and 5.5: explicit-control evaluator and compiler lineage ([5.4](https://sicp.sourceacademy.org/chapters/5.4.html), [5.5](https://sicp.sourceacademy.org/chapters/5.5.html)).
- Racket: linklets, compiled forms, modules, bytecode/native compilation, and continuation/runtime expectations ([linklets](https://docs.racket-lang.org/reference/linklets.html), [compilation modes](https://docs.racket-lang.org/reference/compiler.html), [performance/JIT overview](https://docs.racket-lang.org/guide/performance.html), [continuations](https://docs.racket-lang.org/reference/cont.html)).
- CHICKEN: Scheme-to-C through CPS conversion, optimization, closure conversion, and Cheney-on-the-MTA continuation strategy ([compiler internals](https://wiki.call-cc.org/chicken-internal-structure), [compilation process](https://wiki.call-cc.org/chicken-compilation-process), [getting started](https://wiki.call-cc.org/man/6/Getting%20started)).

## Intentional SICP-Inspired Choices

ECE's strongest architectural through-line is SICP 5.5. The compiler keeps the SICP instruction-sequence shape, explicit register needs/modifies metadata, `preserving`, linkage values, and register conventions. This is not accidental imitation; it is the central implementation strategy.

The VM also follows the explicit-control evaluator idea from SICP 5.4. Runtime state is held in ECE-managed registers, an explicit stack, environments, and code objects instead of relying on recursive host calls. That makes tail calls and continuations properties of the ECE machine rather than whatever the host runtime happens to provide.

Lexical addressing is also in the SICP lineage. Compile-time environments map local variables to `(depth . offset)`, and runtime vector frames make lexical access O(1) after traversing the environment chain. Named lookup remains for globals and dynamically compiled top-level code.

Tail-call behavior is implemented in the generated machine code: a tail-position compiled procedure call jumps to the callee entry using the caller's `continue`, and tail-position `call/cc` avoids an extra return trampoline. This is consistent with the register-machine model and is a reasonable design for a Scheme implementation that must run on CL and browser WASM.

The assembler is deliberately close to SICP's machine model. Labels are local PC entries; instruction operands are constants, registers, labels, and operations; execution is a simple fetch/decode/dispatch loop.

## Atypical but Defensible Scheme Choices

ECE uses per-procedure code objects instead of a single module bytecode object or a raw label stream. This is more object-like than SICP's textbook compiler, but it is defensible. It gives closures a stable identity, makes archive serialization practical, gives native zones a natural attachment point, and avoids older shared-space mutation issues.

The `.ecec` archive format is a readable S-expression format instead of a compact bytecode file. Compared with Racket's marshaled linklet bundles or CHICKEN's C output, this is slow and verbose, but it is easy to inspect, regenerate, diff, and load from both CL and WAT. For a small self-hosting implementation, that is a rational early-stage tradeoff.

The dual runtime model is also defensible. CL is an effective development and bootstrap host; WASM provides browser reach. Keeping the compiler/reader/prelude in ECE source reduces duplication, while `primitives.def` and `operations.def` create stable contracts between the self-hosted layer and the two kernels.

The continuation strategy is pragmatic. ECE does not use CHICKEN's whole-program CPS conversion or Racket's host-integrated continuation machinery. It captures the explicit ECE stack and continuation address. That is simpler to reason about across CL/WASM and fits the register-machine design.

Native zones are an incremental acceleration layer rather than a second semantic backend. They share the same registers, stack, environment, primitive dispatch, and code-object identity. This is less ambitious than Racket CS machine-code compilation or CHICKEN's C backend, but it lowers the risk of semantic divergence because the interpreter remains the fallback.

`define-macro` and `syntax-rules` coexist. This is less principled than a pure hygienic macro system, but it is useful for bootstrapping and user convenience. Implementing `syntax-rules` on top of ordinary ECE procedures keeps the self-hosted story small.

Hash-table literals, string interpolation, and record generation are nonstandard Scheme conveniences. They are acceptable as language extensions as long as the project remains explicit that ECE is Scheme-like, not a strict R5RS/R7RS implementation.

## Atypical Choices with Risk

**Archive format documentation drift.** [`bootstrap/README.md`](../../bootstrap/README.md) says the archive uses plain field tags such as `version` and `entries`, while the current writer emits keyword-style tags such as `:version` and `:entries`. The loaders intentionally accept both. That compatibility path is good, but the stale reference document is risky because archive format mistakes affect CL boot, WASM boot, native zones, and serialized code-object references.

**No real module/linklet boundary.** Racket's linklet architecture gives modules explicit imports, exports, phases, and compiled-form boundaries. ECE bundles are ordered top-level side effects into one mutable global environment. This keeps boot simple, but it makes dependency boundaries, recompilation, global mutation, and separate compilation fragile as the library surface grows.

**Macro expansion has weak phase separation.** Macro transformers are compiled ECE procedures installed in a runtime macro table. `define-syntax` is rewritten into `define-macro` machinery. This is compact, but it means compile-time state, runtime state, and load-time state are easy to couple accidentally. Racket's phase-separated syntax objects solve a harder problem than ECE currently attempts.

**Hygiene is partial.** The `syntax-rules` implementation renames introduced bindings and wraps free operator-position identifiers with `%global-ref`. That covers important cases in the tests, but it is not the same as lexical-context-carrying syntax objects. Free identifiers in non-operator positions, macro-introduced references to mutable globals, nested macro scopes, and phase interactions should be treated as possible edge areas.

**Top-level mutation is semantically broad.** `define-variable!` and `set-variable-value!` target hash-backed global frames by name. This works well for a REPL and boot image, but it makes accidental binding replacement cheap. Native-zone assumptions, serialized closures, and long-running browser sessions can all observe changed globals after code was compiled.

**CL/WASM parity depends on discipline.** The runtimes share the instruction model, but implementation paths differ significantly: CL has generated primitive defuns and optional native zones; WASM has a hand-written primitive dispatcher and no native-zone loader. WASM also stubs raw instruction-vector introspection. Every primitive or code-object contract needs cross-runtime tests, or drift will be easy.

**The WAT runtime is large and manually maintained.** A hand-written WAT runtime is portable to browsers and avoids a separate compiler dependency, but it is expensive to evolve. Changes to code-object layout, archive parsing, primitive IDs, error bridging, or continuation shape must be mirrored precisely.

**Native zones add stale-artifact failure modes.** Zone files are generated from `bootstrap.ecec`, loaded before archives, then attached by `(file-stem . index)`. This is a good design for fast lookup, but stale zone files can be semantically dangerous. The code has checks and regeneration hints, but the architecture still depends on build recipes keeping archive traversal and zone traversal in lockstep.

**Continuation serialization depends on archive registry state.** Code objects can serialize by reference as `(stem . index)`. This is compact, but deserialization requires the relevant archive to already be loaded. That coupling is acceptable for a controlled app bundle, but it needs user-facing failure handling for save files, especially when code changes between save and restore.

**Continuation serialization now rejects non-serializable wind frames.** The serializer preserves `dynamic-wind` frames when their before/after closures and captured environments are serializable, and raises a typed error for host-only state such as ports. That removes the silent semantic change from stripped frames, but it leaves a product decision for future work: whether ECE should add explicit serialization policies for string/file ports or a manager/reference system for native resources.

**Source-location support is transitional.** The reader records source locations and older flat compilation code can extract source maps, but archive compilation intentionally does not stamp per-code-object source locations in the same way. Error reporting and disassembly will remain uneven until archive-era source maps are restored.

**Readable archive format has performance and compatibility costs.** S-expression archives are easy to debug, but parsing large boot bundles in WAT and CL is not free. Keyword/plain-symbol compatibility and ECE-vs-CL reader behavior are already a source of complexity. A binary or canonicalized archive format may eventually be needed for startup time and long-term compatibility.

## Comparison Notes

Compared with SICP, ECE is a productionized explicit-control compiler: code objects, archives, primitive manifests, WASM value representation, CL native zones, error objects, ports, and serialization are all outside the textbook scope. The SICP design remains visible and coherent, but ECE now has enough runtime machinery that its invariants should be documented and tested as a VM, not just as a compiler exercise.

Compared with Racket, ECE is much smaller and less phase-structured. Racket modules compile to linklet bundles/directories with explicit import/export and phase organization; ECE source files execute into one global environment. Racket has a mature compilation stack with machine-independent and machine/native modes; ECE has portable register-machine instructions plus CL-only native zones. ECE should not copy Racket's full architecture, but it should learn from Racket's explicit module and phase boundaries if ECE libraries grow.

Compared with CHICKEN, ECE chooses explicit register-machine interpretation over whole-program CPS-to-C. CHICKEN's CPS conversion makes continuations fundamental and emits portable C, but it also commits the whole compiler pipeline to CPS, closure conversion, and C backend constraints. ECE's approach is simpler and browser-friendly, but it pays interpreter overhead unless native zones are available, and it must explicitly maintain stack/continuation structures.

## Suggested Follow-Up Investigations

1. Update [`bootstrap/README.md`](../../bootstrap/README.md) to match the current keyword-style archive writer and legacy fallback behavior.
2. Add an archive-format golden test that asserts the exact current top-level tags and entry tags emitted by `code-object->archive-sexp`.
3. Write a short module/loading design note: keep global-load semantics, or introduce explicit imports/exports for compiled bundles.
4. Audit `syntax-rules` hygiene against R7RS examples that exercise free identifiers outside operator position, nested syntax-rules, and local macro scopes.
5. Add a parity matrix for CL and WASM primitives, especially code-object introspection, filesystem/process behavior, and error bridging.
6. Add a native-zone stale-artifact test that intentionally mismatches archive/zone keys and verifies the failure mode is loud.
7. Specify a broader save/restore compatibility policy: archive stem/index requirements, code-version changes, and whether host resources such as ports should ever be restored by value or by external reference.
8. Restore or redesign archive-era source maps so code-object errors can report file/line/column consistently on CL and WASM.
9. Measure bootstrap archive parse time on CL and WASM before deciding whether a binary archive format is warranted.
