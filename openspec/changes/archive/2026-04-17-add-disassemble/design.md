## Context

ECE compiles Scheme source to register-machine instructions and groups the instructions by compilation space. A compiled procedure is the tagged list `(compiled-procedure ENTRY ENV)` where `ENTRY` is `(space-id . local-pc)`. Every procedure in a given `.scm` file lives concatenated in that file's single instruction vector; there is no per-procedure terminator.

All the state a disassembler needs is already reachable from ECE: source instructions (`%space-source-ref`), instruction count (`%space-instruction-length`), label table entries (`%space-label-entries`), space name (`%space-name`), and procedure name (currently only `%procedure-name-set!` exists — a getter is needed). The entire kernel delta for this change is one new primitive; everything else is self-hosted.

The compiler already preserves symbolic source forms in `compilation-space-instructions` (the resolved operation-pointer form lives in a parallel vector and is not used by this feature). Pulling from the source vector gives us human-readable `(op name ...)` output for free — no need to un-resolve anything.

There is an existing `image-disassembler` capability (`ece-disassemble-image`) that dumps full `.ecec` files from the CLI. That is a distinct tool — it reads from disk and produces a whole-file listing. This change is a live, per-procedure disassembler invoked from the REPL. The two share conventions (PC prefixes, symbolic form) but not code.

## Goals / Non-Goals

**Goals:**
- `disassemble` takes a compiled procedure or a symbol and prints its bytecode.
- Output is the procedure's reachable instructions only — not the whole space, not inner lambdas.
- Output is readable by humans who know the register-machine model (assigns, branches, gotos, save/restore, perform).
- Branch/goto target labels are annotated with their resolved PC so the reader can navigate.
- Error messages on non-procedure inputs are clear and actionable.
- Implementation is self-hosted in ECE. CL kernel changes: one new primitive only.

**Non-Goals:**
- Source-location mapping (thread 5 of diagnostics roadmap).
- Environment display, closed-over bindings, or sub-REPL interaction (thread 4).
- Step-through execution (thread 6).
- Disassembling continuations or inspecting stack frames.
- Cross-space jumps (none exist today; v1 panics clearly if it encounters one).
- Pretty-printing the compiled-zone CL form when a space has `compiled-fn` set.

## Decisions

### Decision: Reachability walk over scan-until-next-name

**What:** Determine function extent by starting at the entry PC and walking successors (fall-through + all labeled jump targets inside this space) to a fixed point. Only instructions in the reached set are printed.

**Why not the simpler "scan until next procedure-name label" approach?** The simple scan includes inner lambdas whose bodies were lifted into the enclosing procedure's space immediately following the outer body. For a procedure that contains `(lambda (x) ...)` inside a `let`, scan-until-next-name would dump the inner lambda's entire body as if it were part of the outer function. Reachability excludes it correctly: the outer procedure references the inner lambda's entry label only inside an `(op make-compiled-procedure)` argument — not as a control-flow target — so reachability never reaches the inner body.

**Why not fixed window?** Useless for anything real.

**Cost:** The walk is small — a worklist plus a `case` on instruction head (`goto`, `branch`, fall-through on everything else except `goto` which doesn't fall through). Maybe 40 lines in ECE.

### Decision: Pull from source vector, not resolved vector

**What:** Read instructions via `%space-source-ref`, which returns the symbolic form like `(assign val (const 5))` or `(assign proc (op compiled-procedure-env) (reg proc))`.

**Why:** The resolved vector contains `(op-fn #'<function>)` references — uselessly opaque, and would need the disassembler to reverse the resolution to get back readable names. Source form is already what we want.

### Decision: Symbol input resolves in `*global-env*` only

**What:** `(disassemble 'foo)` calls `(lookup-variable-value 'foo *global-env*)`. Lexical `foo` in a surrounding `let` is **not** considered.

**Why:** Matches CL's `disassemble`-accepts-a-symbol semantics (fdefinition lookup is global). Reaching lexical bindings would require either the caller passing an environment explicitly, or `disassemble` being a special form that captures the caller's environment. Neither pays its way for v1: the REPL use case is always "disassemble this top-level thing."

**Mechanism:** Use the existing global-env lookup path. If the binding is unbound, produce "no binding for `foo`" and return; if bound but not a compiled procedure, route to the standard non-procedure error.

### Decision: One-line-per-instruction format with inline labels

**What:**
```
; disassembly of `map` at prelude:142
;
 142:  (label entry1)
       (assign val (const ()))
 143:  (test (op null?) (reg argl))
 144:  (branch (label after-if1))                  ; → pc 158
 145:  (save continue)
 ...
 158:  (label after-if1)
       (goto (reg continue))
```

**Why:**
- Labels inline (printed on their own sub-line) keep the PC column tidy for navigation.
- Annotating branch/goto with `; → pc N` lets the reader jump without cross-referencing the label table.
- Using ECE's existing `write-to-string-flat` on the instruction makes constants display correctly and preserves lowercase symbols (no CL pipe escaping — see CLAUDE.md).

### Decision: Output to current output port, return unspecified

**What:** `disassemble` prints via `display` / `newline`, returning `#f` / `(void)` / similar.

**Why:** Matches CL convention and the `ece-disassemble-image` existing style (it writes to a stream). Returning a string would bloat memory for large procedures and break composition with the REPL's normal printing.

### Decision: Kernel delta is exactly one primitive

**What:** Add `%procedure-name-ref` next to `%procedure-name-set!` in `src/primitives.scm`. Body: `(cl:gethash ,pc-or-qualified *procedure-name-table*)`. That's it.

**Why:** Every other piece of state is already reachable via existing space primitives. Adding `%procedure-name-ref` costs ~4 lines and completes the symmetric pair.

**Bootstrap consequence:** Two-pass bootstrap (per CLAUDE.md). Pass 1: add the primitive in the kernel while the `.ecec` files still boot without it; `make bootstrap` regenerates `.ecec` with the primitive now available. Pass 2: wire `disassemble.scm` in, `make bootstrap` again. In practice this is the normal primitive-migration dance.

### Decision: Compiled-zone procedures still disassemble

**What:** When a procedure's space has a `compiled-fn` set (CL codegen), still dump the source instruction vector. Add a one-line note to the header: `; note: this space is compiled to host; instructions shown are the source the host code was generated from`.

**Why:** The source instructions are still present in the space (codegen reads them, it doesn't consume them). Users looking at a compiled-zone procedure still want to understand the bytecode — the note just clarifies what they're looking at.

### Decision: Clear errors, not crashes, for non-procedure inputs

Four cases:
- **Primitive** (tagged `primitive`): "`<name>` is a host primitive; no bytecode available."
- **Continuation** (tagged `continuation`): "`<value>` is a continuation; disassembling continuations is not supported."
- **Symbol with no global binding**: "`<sym>` has no global binding."
- **Anything else**: "`<value>` is not a compiled procedure."

Each prints to current output port and returns unspecified. No condition system involvement.

## Risks / Trade-offs

- **Risk: reachability misses code the user expects to see** (e.g., a `cond` arm that's unreachable from entry because of how the compiler structured it) → Mitigation: label table entries inside the space that point to PCs *between* the reached set are surfaced in the header as "unreached labels" so the user at least knows they exist. Cheap, requires only one extra pass over `%space-label-entries`.

- **Risk: reachability over-includes shared tail code** (two procedures in the same space tail-call through a shared landing pad) → This would be a compiler output not seen today, but if it happened the disassembly would include the shared code. Acceptable and arguably correct; called out in the design so a future reader knows why.

- **Risk: symbol lookup diverges from what the user expects** (they have `foo` as a local but also `foo` globally — disassembler shows the global) → Mitigation: document the global-only behavior clearly in the docstring. Matches CL.

- **Risk: bootstrap breaks mid-change** (primitive added before .ecec regenerated, or vice versa) → Mitigation: follow the documented two-pass dance. Add tasks that enforce the order.

- **Trade-off: not showing the compiled-zone host code** means a user reading CL-compiled output doesn't see the actual runtime form. Acceptable — the source form is still the right mental model, and WASM/JS backends will add more host forms we don't want to chase.

- **Trade-off: no source-location info** means disassembly can't cross-reference the `.scm` source. Waits on thread 5; noted in proposal as deferred.

- **Trade-off: CL-only at the function level.** `disassemble` reaches global-env via `(cdr (%global-env-frame))` (CL lays out the first frame as `(:hash-frame . ht)`) and uses `%eq-hash-has-key?` / `%eq-hash-keys` (both CL-only). The `%procedure-name-ref` primitive itself is portable (WASM stub returns `#f`), but the self-hosted function body is not runnable on WASM without either a portable `%global-lookup` primitive or a WASM hash-frame layout change. Tests live under `tests/ece/cl-only/` accordingly. Porting is a follow-up when a WASM disassembler consumer exists.

## Migration Plan

No user migration needed — this is a pure addition. Rollback = revert the commit. The new primitive is unused by anything except the new `disassemble` function, so removing both is clean.

## Open Questions

- **Should `disassemble` accept a lambda expression (source) like CL does?** CL allows `(disassemble '(lambda (x) (+ x 1)))`. That requires compiling on the fly. Probably worth a follow-up change; called out here so we don't paint ourselves into a corner (no API shape this design uses would block adding it).
- **Header format for multi-named entry points:** if the same PC has multiple names in `*procedure-name-table*`, how do we render? Likely pick the most recent. Deferred until we see an example in the wild.
