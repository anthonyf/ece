## Why

ECE's primitive implementations currently live as ~1500 lines of handwritten Common Lisp inside `src/runtime.lisp`. This ties every primitive to a single host language and means adding a new backend (WASM, JS) requires rewriting every primitive in the new host's native syntax. As a first step toward host-code minimization and multi-target codegen, primitive implementations should move to ECE-side templates that carry host-language bodies for each supported target. The CL runtime becomes a pre-generated derivative of ECE source — analogous to how `bootstrap/bootstrap.ecec` is already a derivative of `src/prelude.scm`.

This is Stage 0 of a multi-stage self-hosting roadmap. Stages 1-3 (per-space native codegen, porting `execute-instructions` to ECE, WASM backend) all depend on having primitives defined as ECE templates. Stage 0 ships value standalone: primitives become ECE-maintained, `runtime.lisp` drops from ~2460 to ~800 lines, and future host backends consume the `:wat` / `:js` templates already present on every primitive.

## What Changes

- **NEW** `src/primitives.scm` — source of truth for primitive implementations. Contains one `(define-host-primitive ...)` form per host-implemented primitive, with multi-target template bodies (`:cl`, `:wat`, `:js`). Template bodies use ECE's native quasiquote/unquote syntax (e.g., `` `(cl:car ,p) ``) with `(unquote NAME)` forms as parameter substitution points.
- **NEW** `src/codegen-cl.scm` — ECE program that joins `primitives.def` metadata with `primitives.scm` templates, expands the `:cl` template for each primitive into a `(defun ece-NAME ...)` body, and writes `bootstrap/primitives-auto.lisp`.
- **NEW** `bootstrap/primitives-auto.lisp` — checked-in, pre-generated CL file containing `~172` `defun` forms (one per `core`/`cl` primitive) plus `~19` error stubs for `browser` primitives. Loaded by `runtime.lisp` at boot in place of the deleted handwritten primitive defuns. Regenerated via `make bootstrap`.
- **NEW** `make bootstrap` wires `primitives-auto.lisp` generation into the existing bootstrap pipeline. Regeneration is deterministic: identical input produces byte-identical output. Two-pass bootstrap handles self-reference exactly like `.ecec` regeneration today.
- **MODIFIED** `src/runtime.lisp` — deletes the ~167 handwritten `ece-NAME` defuns, the 13-entry `*primitive-cl-overrides*` table, and adds a single `(load "bootstrap/primitives-auto.lisp")` call before `init-primitive-dispatch-tables`. Net reduction: ~1500 lines. Everything else in `runtime.lisp` is unchanged: `execute-instructions`, `compilation-space`, `.ecec` boot, helper functions (`scheme-bool`, `hash-frame-p`, `cl-winding-stack`, etc.), specials (`*executing-space-id*`, `*global-env*`), trace globals, `defpackage` form.
- **UNCHANGED** `primitives.def` — metadata registry stays as-is. Still parsed by `parse-primitives-manifest` at boot. Remains the authoritative source for primitive IDs, arities, platforms.
- **UNCHANGED** `src/prelude.scm` — the 24 `ece`-platform primitives (`modulo`, `equal?`, `gensym`, `string=?`, etc.) continue to live here as plain `(define ...)` forms. They are not templated because they have no host implementation.
- **UNCHANGED** `execute-instructions` — no register struct, no new specials, no interpreter refactor. The ~10 machine-touching primitives reference the existing `*executing-space-id*` and `*global-env*` specials in their templates, mirroring the current handwritten code.

## Capabilities

### New Capabilities
- `host-primitive-templates`: Covers the template definition form (`define-host-primitive` with quasiquote/unquote syntax and multi-target keyword fields), the template expander (walks quasiquoted body and substitutes `(unquote NAME)` placeholders), the codegen tool that joins `primitives.def` with `primitives.scm` and emits `bootstrap/primitives-auto.lisp`, validation rules (forbidden constructs, missing-template errors, arity matching), and the bootstrap integration that makes `primitives-auto.lisp` a checked-in derivative regenerated via `make bootstrap`.

### Modified Capabilities

None. `primitive-manifest`'s requirements (manifest format, ID stability, boot-time validation) are preserved exactly. `instruction-executor`, `portable-primitive-dispatch`, and all other existing capabilities are untouched.

## Impact

- **Affected code**: `src/runtime.lisp` (~1500 lines deleted, 1 load form added), `src/primitives.scm` (new, ~172 template entries), `src/codegen-cl.scm` (new, template expander + emitter), `bootstrap/primitives-auto.lisp` (new, generated), `Makefile` (new dependency edge for `primitives-auto.lisp`).
- **No runtime behavior change**: the generated `ece-NAME` defuns are byte-equivalent or semantically equivalent to the pre-migration handwritten versions. The existing test suite (rove, ECE self-hosted, conformance, WASM) must stay green with zero failures.
- **No API changes**: primitive dispatch, `resolve-cl-primitive`, `init-primitive-dispatch-tables`, `*global-env*` construction are all unchanged. The load order in `runtime.lisp` ensures helpers are defined before templates reference them.
- **Future-enabling**: Stages 1-3 of the self-hosting roadmap (per-space native codegen, interpreter-in-ECE, WASM backend) all depend on having primitives defined as templates. This change is a prerequisite but does not commit to any later stage.
- **Rollback**: if regeneration produces a broken `primitives-auto.lisp`, `git checkout` the previous version — same recovery path as any `.ecec` rollback.
