## Context

`src/runtime.lisp` currently contains ~2460 lines of Common Lisp, of which roughly 1500 are handwritten primitive implementations (`defun ece-car`, `defun ece-string-append`, etc.). These implementations are coupled to the CL host: adding a WASM or JS backend requires rewriting each primitive in the new target's native syntax. The codebase already has a metadata-driven primitive system — `primitives.def` lists all 215 primitives with stable IDs, arities, and platform tags (`core`, `ece`, `cl`, `browser`) — but the *implementations* remain tied to CL.

Primitive dispatch is convention-based via `resolve-cl-primitive` (`src/runtime.lisp:531`). It resolves an ECE name to a CL function by checking an override table, then `ece-<NAME>` in the ECE package, then `<NAME>` in the CL package, then `<NAME>` in the ECE package. This means some primitives (`car`, `cdr`, `cons`, `+`, `-`, `*`, `/`, `list`) have no handwritten wrapper at all — they fall through directly to `cl:car`, `cl:cons`, etc. Others have thin `ece-NAME` wrappers with one-line bodies like `(scheme-bool (cl:stringp x))`. A minority (~15) have multi-clause logic (environment lookup, hash-frame construction). A handful (~10) reach into register-machine state to implement `call/cc`, tracing, and continuation plumbing.

This change moves the *implementation* of primitives (but not their metadata) from handwritten CL to ECE-side templates. The templates carry multi-target bodies (`:cl`, `:wat`, `:js`) so future codegen passes can target additional hosts without rewriting primitive logic.

Investigation during the exploration session established two load-bearing facts:

1. **Only ~10 primitives touch machine state**, and they reach exactly two existing CL specials: `*executing-space-id*` and `*global-env*`. The hot-path registers (`val`, `env`, `proc`, `argl`, `continue`) are strictly internal to `execute-instructions` — no primitive reads or writes them. This means Stage 0 needs NO register struct rewrite, NO new specials, and NO interpreter refactor.

2. **Primitives are naturally categorized into four implementation patterns** — override table (~13), CL fallthrough (~50), `ece-` wrapper defun (~100), ECE-platform in prelude.scm (24). All but the last category need templates.

The bootstrap pattern for regenerated CL files mirrors the existing `.ecec` pattern exactly: source of truth is `src/primitives.scm`; checked-in derivative is `bootstrap/primitives-auto.lisp`; `make bootstrap` regenerates. Runtime just `(load ...)`s the file — no template expansion at runtime, no `eval`, no overhead.

## Goals / Non-Goals

**Goals:**

- Move the implementation of `core` and `cl` primitives from `src/runtime.lisp` to a new `src/primitives.scm` using ECE quasiquote/unquote as the template syntax.
- Build an ECE-side codegen (`src/codegen-cl.scm`) that expands templates into `(defun ece-NAME ...)` forms and writes `bootstrap/primitives-auto.lisp`.
- Multi-target templates from day one: every primitive carries `:cl`, `:wat`, `:js` keys (browser-only primitives may carry only `:wat` / `:js`).
- Shrink `src/runtime.lisp` to ~800 lines by deleting the ~167 handwritten `ece-NAME` defuns and the 13-entry `*primitive-cl-overrides*` table.
- Preserve behavioral parity: the existing test suite (rove, ECE self-hosted, conformance, WASM) must pass with zero failures after migration.
- Establish the build-time codegen pipeline that Stages 1-3 (inline codegen, interpreter port, WASM backend) will extend.
- Deterministic regeneration: identical input produces byte-identical output, so `make bootstrap` is idempotent and git diffs of `primitives-auto.lisp` are meaningful.

**Non-Goals:**

- Per-space native codegen with inline substitution at call sites — this is Stage 1. Stage 0 only generates auto-stub `defun`s.
- Porting `execute-instructions` itself to ECE — Stage 2.
- Consuming `:wat` or `:js` templates at build time — Stage 3. The `:wat` / `:js` keys are written in Stage 0 but no codegen reads them yet.
- Merging `primitives.def` and `primitives.scm` into a single file — possible future cleanup, not this change.
- Register struct rewrite, new specials, or any modification to `execute-instructions`. The interpreter is untouched.
- Migrating the 24 `ece`-platform primitives (`modulo`, `equal?`, `gensym`, etc.) — they already self-host in `src/prelude.scm`.
- Changing primitive dispatch, the operation table, or `resolve-cl-primitive` — they all keep working unchanged.
- Changing how `primitives.def` is parsed by CL at boot — `parse-primitives-manifest` stays as-is.

## Decisions

### 1. Template syntax: quasiquote/unquote

**Choice**: Templates use ECE's native quasiquote (`` ` ``) and unquote (`,`) reader syntax. The template body is a quasiquoted s-expression; `(unquote NAME)` forms mark parameter substitution points. Unquote-splicing (`,@`) and nested quasiquote are forbidden in Stage 0.

```scheme
(define-host-primitive (car p)
  :cl  `(cl:car ,p)
  :wat `(call $car (local.get ,p)))

(define-host-primitive (+ . args)
  :cl `(cl:apply #'cl:+ ,args))
```

**Rationale**: Quasiquote/unquote is already handled by the ECE reader with no new syntax to invent. Semantically it matches exactly: "this is a template with substitution points." The template body is never evaluated by ECE — it is stored as opaque s-expression data, walked by the codegen, and substituted values are inlined. The walker recognizes `(unquote NAME)` at the data level exactly as a quasiquote expander would.

**Alternatives considered**: Printf-style strings (`"(cl:car ~A)"`), curly-brace placeholders (`{p}`), dollar-sign prefixes (`$p`), angle brackets (`<p>`), percent prefixes (`%p`). All would require new reader support or string-parsing logic. Quasiquote is free — the reader already handles it — and gives us s-expression validation for free (the template must parse as valid s-expressions).

### 2. File organization: separate `primitives.def` and `primitives.scm`

**Choice**: `primitives.def` stays as-is (line-oriented metadata registry, unchanged format, unchanged CL-side parser). `src/primitives.scm` is a NEW file containing only `(define-host-primitive ...)` forms, keyed by primitive name. The codegen joins the two at build time.

**Rationale**: Metadata is universal (all 215 primitives have stable IDs, arities, platform tags). Implementation is host-specific and missing for some entries (24 `ece`-platform primitives have no host template; 19 `browser` primitives have no `:cl` template). Forcing everything into one file creates weak invariants ("entries may or may not have template fields") and breaks line-oriented tooling. Separating the files:
- Keeps `primitives.def` cat-friendly and grep-friendly
- Leaves `parse-primitives-manifest` unchanged (zero CL-side risk)
- Creates a clean "implementation source of truth" in `primitives.scm` that only contains entries that actually have host implementations
- Allows the codegen to report missing templates as errors (if a `core` primitive in `primitives.def` has no entry in `primitives.scm`, boot fails)

**Alternatives considered**:
- **Merge into `primitives.def`**: would require extending the parser to accept optional trailing template fields, adds multi-line entries that break line-oriented format, and mixes metadata with implementation. Rejected: too much churn for aesthetic gain.
- **Merge into `primitives.scm`**: would require rewriting `parse-primitives-manifest` to read from an ECE file at CL boot, creating a chicken-and-egg on the ECE reader. Rejected: bigger blast radius.

A later cleanup proposal can merge if desired — Stage 0 does not close the door.

### 3. Register representation: existing specials only

**Choice**: The ~10 machine-touching primitives reference `*executing-space-id*` and `*global-env*` (both already CL specials) directly in their `:cl` template body. No new specials. No register struct. No modification to `execute-instructions`.

**Rationale**: Investigation confirmed that the hot-path registers (`val`, `env`, `proc`, `argl`, `continue`, `pc`, `flag`) are internal to `execute-instructions` and never referenced by any primitive. The only register state that primitives actually read/write is `*executing-space-id*` (used by `capture-continuation` to qualify continuation addresses) and `*global-env*` (used by several entry-point primitives and `ece-trace` / `ece-untrace`). Both are already CL specials — no new representation is needed.

This is the crucial insight that keeps Stage 0's scope narrow. The register struct question becomes a Stage 1 concern, orthogonal to primitive migration.

**Alternatives considered**:
- **Register struct**: would require rewriting `execute-instructions` to thread the struct, updating every primitive template to take an implicit machine arg, and changing the calling convention. Rejected: not needed for Stage 0 and significantly expands scope.
- **New specials for `val`, `env`, etc.**: would slow the interpreter's hot path (CL special access is ~3x slower than lexical access) with no benefit, since no primitive needs these registers. Rejected: pure cost.

### 4. Multi-target templates from day one

**Choice**: Every `(define-host-primitive ...)` form accepts `:cl`, `:wat`, and `:js` keyword fields. Stage 0 only consumes `:cl`, but `:wat` and `:js` are authored alongside from the start.

**Rationale**: Retrofitting multi-target later would require touching every primitive again. Writing the WAT and JS templates now, while the translator has the handwritten CL version in context, is cheaper than revisiting each primitive months later. The validation rule for Stage 0 is simply "`:cl` must be present for `core`/`cl` platform primitives; other keys are optional and unused."

**Alternatives considered**: CL-only initially, retrofit later. Rejected: future churn.

### 5. Codegen in ECE (`src/codegen-cl.scm`)

**Choice**: The codegen is an ECE program, not a CL program. It runs through the existing ECE interpreter at build time, reads `primitives.def` and `primitives.scm`, and writes `bootstrap/primitives-auto.lisp`.

**Rationale**: The project's goals emphasize self-hosting (per the `feedback_prefer_ece_over_host.md` memory). Writing the codegen in ECE keeps build tooling on the right side of the language boundary and positions the same tool for eventual native compilation in Stage 1. A prior `compile-to-host-cl` change (archived without finishing) considered a CL-side codegen; it ran into size issues with monolithic output. The per-primitive codegen here sidesteps that problem entirely (each primitive is a small defun, not a 28MB monolith).

**Alternatives considered**:
- **CL codegen**: faster iteration loop initially, but later needs to be rewritten in ECE for Stages 1-3. Rejected: avoidable churn.
- **Python/shell script**: host-agnostic but ties build to a third toolchain. Rejected: violates prefer-ECE-over-host preference.

### 6. Codegen output: auto-stub `defun`s, not inline substitution

**Choice**: The codegen generates a `(defun ece-NAME ...)` for each primitive, with the template body substituted into the defun body. Callers of primitives still go through the primitive dispatch table exactly as today. There is no inline substitution at call sites.

**Rationale**: Inline substitution at call sites requires walking the instruction vector and integrating with the native-compiled zone, which is Stage 1 work. Stage 0 only changes the *source of truth* for primitive implementations — it does not change how primitives are called at runtime. The resulting auto-stubs are functionally equivalent to the current handwritten defuns, which is what enables the migration to be a mechanical, behavior-preserving rewrite.

**Alternatives considered**:
- **Inline substitution now**: would couple Stage 0 to Stage 1's codegen work and delay shipping. Rejected.
- **Do nothing; wait for Stage 1**: leaves primitives in handwritten CL and blocks multi-target codegen. Rejected.

### 7. Uniform coverage: emit defuns even for CL-fallthrough primitives

**Choice**: `car`, `cdr`, `cons`, `+`, `-`, `*`, `/`, `list`, `null`, and other primitives that currently have no `ece-NAME` wrapper (they fall through to `cl:car` etc. via `resolve-cl-primitive`'s Convention 2) get explicit one-line templates and generated `ece-NAME` defuns.

**Rationale**: The invariant "every `core`/`cl` primitive in `primitives.def` has a matching entry in `primitives.scm`" is stronger and easier to reason about than "some are templated, some fall through to convention." It also means the `*primitive-cl-overrides*` table and Convention 2 fallthrough become dead code that can be deleted, simplifying `resolve-cl-primitive`. The cost is ~50 extra one-line `defun`s in the generated file — negligible.

**Alternatives considered**: Skip fallthrough primitives, rely on Convention 2. Rejected: weaker invariant, leaves the override table in place, complicates the "source of truth" story.

### 8. Package convention in templates

**Choice**: Adopt four symbol-prefix conventions inside template bodies:
- `cl:foo` — Common Lisp built-in, resolves to `common-lisp:foo` at SBCL load time
- `foo` (bare) — ECE-package helper or special var (`scheme-bool`, `hash-frame-p`, `*executing-space-id*`, etc.)
- `,name` — parameter substitution via template expansion
- `'|name|` — literal lowercase symbol (e.g., `'|continuation|`)

**Rationale**: Every primitive template must unambiguously distinguish CL built-ins (which live in the `common-lisp` package) from ECE-package helpers. Using `cl:` prefix explicitly marks the former; leaving everything else bare relies on the generated file's `(in-package :ece)` form to resolve unqualified symbols in the ECE package. This works because ECE's `write-to-string-flat` uses `:preserve` readtable-case, so lowercase symbols print without pipe-escaping.

### 9. Bootstrap pattern: checked-in derivative

**Choice**: `bootstrap/primitives-auto.lisp` is a checked-in, pre-generated artifact analogous to `bootstrap/bootstrap.ecec`. It is regenerated by `make bootstrap` running `codegen-cl.scm` through the ECE interpreter. At runtime, CL simply `(load ...)`s the file — no template expansion, no `eval`, no runtime template infrastructure.

**Rationale**: Matches the existing build system pattern the user is already fluent with. If the regenerated file is broken, `git checkout bootstrap/primitives-auto.lisp` recovers exactly like any `.ecec` rollback. Two-pass bootstrap handles self-reference: old codegen + old `primitives-auto.lisp` generate new `primitives-auto.lisp` from new `primitives.scm`, then the new artifact runs its own codegen to validate fixed-point.

### 10. Validation strategy

**Choice**: The codegen validates exhaustively before emitting output:
1. Every `core` and `cl` primitive in `primitives.def` has a template entry in `primitives.scm` (missing → error with primitive name)
2. Every template entry in `primitives.scm` corresponds to a primitive in `primitives.def` (orphaned → error)
3. Every template's parameter list matches the primitive's declared arity
4. No template uses forbidden constructs (nested quasiquote, unquote-splicing)
5. No template references an unbound placeholder (unquote of an unknown name)
6. No duplicate `define-host-primitive` forms for the same name

Any failure aborts emission — no partial file is written. The existing test suite is the runtime correctness validation: after regeneration, rove + ECE self-hosted tests + conformance + WASM must all pass unchanged.

Additional proof-of-concept validation: before migrating all 172 primitives, write templates for 5 trivial + 2 medium + 2 machine-touching cases, expand them, and diff the output against the corresponding current handwritten defuns. If the diff is empty or behaviorally equivalent, the wholesale migration is low-risk.

## Risks / Trade-offs

- **[172 primitives to migrate, mechanical but tedious]** → The migration is mechanical (template body = existing defun body with parameter substitution), so review is catch-the-typo rather than catch-the-logic-error. Mitigation: PoC on ~9 representative primitives first; require byte-level diff or clear semantic equivalence before proceeding; full test suite must pass.

- **[Machine-touching primitive templates must correctly reference existing specials]** → `capture-continuation`, `do-continuation-winds`, `ece-trace`, and friends reference `*executing-space-id*` and `*global-env*` in their bodies. Templates must preserve these references exactly. Mitigation: PoC includes at least 2 machine-touching primitives; test suite covers call/cc, serialization, and tracing.

- **[Generated file load order matters]** → `primitives-auto.lisp` must load after helper functions (`scheme-bool`, `hash-frame-p`, `cl-winding-stack`, specials) are defined but before `init-primitive-dispatch-tables` runs. Mitigation: place the `(load ...)` form at the exact position the current handwritten defuns occupy in `runtime.lisp`.

- **[Deterministic output is critical for meaningful git diffs]** → Codegen must emit defuns in a stable order (alphabetical by primitive name) and format consistently. Mitigation: explicit sort step before emission; the codegen's golden-output test fixture validates idempotence.

- **[Helper functions referenced by templates stay handwritten]** → `scheme-bool`, `hash-frame-p`, `format-ece-proc`, `cl-winding-stack`, etc. are not primitives; they are internal helpers. They remain in `runtime.lisp` and are referenced bare by templates. Risk: if someone renames a helper without updating templates, codegen still succeeds but the generated file fails to load. Mitigation: add a CL-side smoke test that loads `primitives-auto.lisp` and asserts every generated `ece-NAME` is `fboundp`.

- **[Symbol printing must preserve lowercase]** → Templates contain symbols like `'|continuation|` that must round-trip through the writer without case mangling. Mitigation: use the existing `write-to-string-flat` which already handles `:preserve` readtable-case. Golden-output test confirms round-trip.

- **[The 24 `ece`-platform primitives stay in prelude.scm]** → They must not accidentally get entries in `primitives.scm`. Mitigation: codegen's validation pass errors if an `ece`-platform primitive appears in `primitives.scm`.

- **[Two-pass bootstrap edge case]** → If `primitives.scm` changes in a way that affects the codegen itself (e.g., a primitive the codegen uses during expansion), the first pass runs with the old codegen on new source. Mitigation: the codegen is small (~150 lines) and should not depend on primitives that are in flux; existing bootstrap recovery procedures apply.

## Migration Plan

1. **PoC phase**: write templates for 9 representative primitives (5 trivial: `car`, `cons`, `+`, `string-append`, `vector-ref`; 2 medium: `lookup-variable-value`, `extend-environment`; 2 machine-touching: `capture-continuation`, `ece-trace`). Hand-write the expected `primitives-auto.lisp` slice. Implement `codegen-cl.scm`. Verify the expansion matches the hand-written expectation byte-for-byte or semantically.

2. **Full migration**: write the remaining ~163 templates. Run codegen. Check that `primitives-auto.lisp` now contains all ~172 auto-stubs. Add `(load "bootstrap/primitives-auto.lisp")` to `runtime.lisp` at the correct position. Delete the handwritten `ece-NAME` defuns and the `*primitive-cl-overrides*` table from `runtime.lisp`.

3. **Validation**: run the full test suite (rove, ECE self-hosted, conformance, WASM). Zero failures required. Any failure gets triaged — most likely causes are typos in a template, a helper function reference that drifted, or a missed arity match.

4. **Bootstrap integration**: add a `Makefile` rule so `bootstrap/primitives-auto.lisp` depends on `primitives.def`, `primitives.scm`, and `codegen-cl.scm`. `make bootstrap` runs the codegen as part of the existing bootstrap flow.

5. **Rollback**: if the migration lands and a downstream issue appears, `git revert` the PR. The change is self-contained — all new files can be deleted, the reverted `runtime.lisp` brings back handwritten defuns, and the system returns to its pre-migration state.

## Open Questions

- **Should codegen-cl.scm live in `src/` or `tools/`?** It's a build-time tool, not runtime code. Preference TBD — `src/` keeps it under the same ASDF system; `tools/` separates build concerns. Defer to implementation.
- **Format of the generated file header**: what exact text marks the file as generated? Suggestion: `;;;; AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND` plus a line noting the source files and regeneration command.
- **Should browser-platform primitives get explicit error-stub defuns, or should the current stub-lambda in `init-primitive-dispatch-tables` stay?** Static defuns are cleaner but touching that init path is out-of-scope churn. Likely leave the init-path stubs alone and only emit defuns for `core` and `cl` primitives.
