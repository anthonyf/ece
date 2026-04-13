## Implementation Outcome (added 2026-04-12)

The proposal's premise that 26 primitives could be moved to ECE turned out to be wrong for tiers 1-3. The targeted primitives (`compiled-procedure-entry`, `continuation-stack`, `port-line`, the tagged-list predicates, and the constructors) have **platform-specific representations**: tagged lists on CL, WasmGC structs on WASM. An ECE function like `(cadr p)` only works on the list representation. See the analysis in `openspec/changes/migrate-trivial-primitives-to-ece/implementation-outcome.md` (below) for the concrete evidence.

Only **tier 4** (`list`, `clear-screen`) is portable. Tier 4 was implemented and all four test suites pass. The rest of this design document reflects the original 26-primitive plan and is retained for historical context.

---

## Context

`src/primitives.scm` declares ~140 host primitives via `define-host-primitive`. Each declaration has a `:cl` template that the codegen (`src/codegen-cl.scm`) expands into a CL `defun` in `bootstrap/primitives-auto.lisp`. At runtime, these CL functions are dispatched via the primitive ID table (`*primitive-dispatch-table*`).

About 17 of these primitives have `:cl` templates that are essentially "build a list" or "call `cadr`" — they don't access host capabilities (memory, I/O, hash tables, syscalls). They only exist as primitives because before Stage 1 coverage expansion, calling an ECE function from compiled code was slow (interpreter dispatch).

After Stage 1 coverage expansion, the prelude space runs as a compiled zone — calling a prelude function from another compiled space is one CL function call (a goto into the target chunk). The performance argument for keeping these as primitives no longer holds.

The kernel minimization goal in MEMORY.md ("Anything that CAN be written in ECE SHOULD be written in ECE") motivates moving them now, both for code clarity and to reduce the WAT porting burden in Phase 2.

## Goals / Non-Goals

**Goals:**

- Move 17 trivial primitives from `src/primitives.scm` to `src/prelude.scm` as ECE functions.
- Keep the same names, parameter lists, and observable behavior.
- Each tier is a separate commit, each commit is a clean two-pass bootstrap cycle (so the repo is always buildable from `main`).
- Reduce the CL kernel surface area by ~80-100 lines.
- Validate the codegen on more code paths by exercising prelude-side definitions of these primitives.

**Non-Goals:**

- Performance optimization. We accept the small (likely unmeasurable) cost of going through the prelude's compiled zone instead of inline `:cl` templates.
- Moving primitives that have any host-capability dependency (I/O, syscalls, native hash tables, native vectors).
- Moving primitives that are heavily called in tight loops where a function-call-vs-inline difference might matter (e.g., `car`, `cdr`, `cons` — these stay).
- Changing primitive IDs in `primitives.def`. We mark removed IDs as unused (or remove the line) but do NOT renumber, so existing `.ecec` files referencing the IDs by number remain valid.
- Touching the Phase 2 WASM backend. The `:wat` templates for the migrated primitives can be removed in the same change since the primitives no longer exist; if not yet authored, nothing to do.

## Decisions

### 1. Tiered migration in commit-sized chunks

**Choice:** Four tiers (accessors, constructors, predicates, standalone) executed as separate commits.

**Rationale:** Each tier is independently testable, independently revertable, and small enough to review. The two-pass bootstrap requirement (per MEMORY.md known pitfalls) means each migration step is "add ECE def + bootstrap, then remove primitive + bootstrap again." Doing this for 17 primitives at once is hard to review and risky to revert. Per-tier commits keep blast radius small.

**Alternatives considered:**
- One big commit: rejected — too large to review, hard to bisect failures.
- Per-primitive commits: rejected — 17 commits is overkill for primitives that are this trivial. Tiered grouping balances reviewability and ceremony.

### 2. Preserve primitive IDs (don't renumber)

**Choice:** When a primitive is removed, leave its slot in `primitives.def` empty (or comment it out) rather than renumbering subsequent IDs.

**Rationale:** Primitive IDs appear in compiled `.ecec` files. Renumbering would invalidate every existing `.ecec` file in the wild (sandbox programs, test fixtures, future shipped binaries). Leaving the slot empty costs one wasted ID per removed primitive (cheap — IDs are integers, not a dense table).

**Alternatives considered:**
- Renumber: rejected — breaks `.ecec` compatibility, requires rebuilding all checked-in `.ecec` files.
- Reuse the slot for a new primitive: rejected — confusing, hides intent.

### 3. Keep tier 1 accessors as ECE wrappers, not macros

**Choice:** `(define (compiled-procedure-entry p) (cadr p))` — a normal function, not a macro that inlines `(cadr p)` at every call site.

**Rationale:** These accessors are called from compiled code. The compiled code's call site goes through the apply dispatch (look up name → proc → apply). With a function, the prelude's `compiled-procedure-entry` becomes a compiled procedure with an entry point, and calls go through `goto (reg val)` into the prelude zone. With a macro, the call site would need to inline at compile time, which only works if the symbol is recognized as a macro by `mc-compile` — adding another moving part. Functions are simpler and the cost is one function call per access.

**Alternatives considered:**
- Macros: rejected — requires teaching the compiler to recognize them, which they currently aren't (they're operations or primitives, not macros).
- Inline directly via codegen-side rewriting: rejected — that's just re-creating the `:cl` template path in a different file.

### 4. `list` becomes a one-liner ECE function

**Choice:** `(define (list . args) args)` — exploits the ECE calling convention where `args` is the argument list.

**Rationale:** `list` is the simplest primitive of all. Its `:cl` template is literally `,args`. In ECE, the rest-arg parameter is bound to the actual argl list. Returning it directly is the entire implementation.

### 5. `clear-screen` lives in prelude

**Choice:** `(define (clear-screen) (display "\x1b;[2J\x1b;[H"))`

**Rationale:** It's just two ANSI escape sequences. The CL template uses `cl:format` to write the same bytes. Moving it to ECE works because `display` is still a primitive (it does need host I/O).

## Risks / Trade-offs

- **[Boot order]** → If a primitive is removed but the prelude isn't loaded yet when something tries to use it, boot fails. Mitigation: prelude.scm is loaded very early (right after boot-env). All migrated primitives are used in user code paths or by the compiler, both of which run after prelude.scm has loaded. Verified by the existing test suite.

- **[Performance regression in hot paths]** → If a moved primitive turns out to be on a hot path and the function-call overhead matters, we might see test slowdowns. Mitigation: run all four test suites after each tier. If a regression > 5% appears, revert that tier and skip the affected primitive.

- **[Two-pass bootstrap mistakes]** → The two-pass requirement is a known footgun. Mitigation: each tier's task list spells out the exact 4-step sequence (add ECE def, bootstrap, remove host primitive, bootstrap again).

- **[Inline-substitution loss]** → The codegen's static-proc-map currently inlines `:cl` templates at primitive call sites. After migration, the call sites can no longer be inlined (because there's no `:cl` template). They become regular function calls in the prelude zone. This is a small slowdown but expected and accepted.

- **[Spec drift]** → The `prelude-functions` spec doesn't currently document these as "primitives implemented in ECE." Mitigation: update the spec in a single delta as part of tier 1, then leave it stable through the rest of the migration.

## Migration Plan

Each tier follows the same template:

1. **Pass 1 — add ECE definition**
   - Add `(define (NAME . params) BODY)` to `src/prelude.scm`
   - Leave the `define-host-primitive` form in `src/primitives.scm` (so old `.ecec` still works)
   - `make bootstrap` to regenerate `bootstrap.ecec` with the new definition
   - Run `make test-rove` for fast verification

2. **Pass 2 — remove host primitive**
   - Delete the `define-host-primitive` form from `src/primitives.scm`
   - Remove (or comment out) the corresponding line in `primitives.def` — do NOT renumber
   - Update any `:wat`/`:js` clauses if they exist (rare for these tier-1 primitives)
   - `make bootstrap` again
   - Run all four test suites: `make test-rove`, `make test-ece`, `make test-conformance`, `make test-wasm`

3. **Commit** the two-pass result with a clear message naming which primitives moved

**Rollback:** Revert the commit. The two-pass nature means each commit is internally consistent (no half-state). If a regression is found post-merge, `git revert` restores the primitive cleanly.

## Open Questions

- **Should `port-line` and `port-col` move?** They access port internal structure. The port is a CL list `(input-port stream filename line col)`, so the accessors are `cadddr`/`car of cddddr`. They're host-defined but the accessors are pure list refs. Tentatively: yes, include in tier 1.
- **Can `make-parameter` move?** Currently `(list 'parameter (cons val converter))`. This is just a constructor, no host capability. Yes, include in tier 2.
- **Is there a `:wat` template for any of these?** Need to check `primitives.scm` once more during implementation; if so, the `:wat` clause should be removed too (the WAT codegen doesn't exist yet so this is forward-looking cleanup).
