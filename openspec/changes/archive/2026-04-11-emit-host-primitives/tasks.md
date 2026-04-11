## 1. Template Infrastructure

- [x] 1.1 Create `src/primitives.scm` as an empty file with a header comment describing its role as the source of truth for primitive implementations
- [x] 1.2 Define the `define-host-primitive` macro that registers templates in a `*host-primitives*` hash table, keyed by primitive name, storing params list and an alist of `(target . template)` pairs
- [x] 1.3 Implement `register-host-primitive!` as the macro's runtime expansion target — adds entries to `*host-primitives*` and errors on duplicate names
- [x] 1.4 Write the template expander: walk a `(quasiquote BODY)` form, recognize `(unquote NAME)` as a substitution slot, error on `(unquote-splicing ...)` and nested `(quasiquote ...)`, leave all other forms untouched
- [x] 1.5 Write a validation helper that checks a template for forbidden constructs (unquote-splicing, nested quasiquote) and unbound placeholders before expansion

## 2. Codegen Tool

- [x] 2.1 Create `src/codegen-cl.scm` with a top-level `(generate-primitives-auto-lisp!)` entry point
- [x] 2.2 Implement a parser for `primitives.def` that reads each entry and builds a hash table keyed by name with values `(id arity platform description)`
- [x] 2.3 Implement the join step: for each manifest entry, look up the primitive in `*host-primitives*` and validate presence/absence based on platform tag
- [x] 2.4 Implement arity matching: verify that each template's parameter list length or variadic shape matches the primitive's declared arity from `primitives.def`
- [x] 2.5 Implement the output formatter that builds a `(defun ece-NAME PARAMS EXPANDED-BODY)` form from a primitive's metadata and expanded template
- [x] 2.6 Implement a CL param-list builder that converts a primitive's ECE arity into the correct CL `defun` param list (fixed arity → `(p1 p2 ...)`, variadic → `(&rest args)`, dotted-tail → `(p1 p2 &rest rest)`)
- [x] 2.7 Implement file emission: write the header comment, `(in-package :ece)`, then all defuns in alphabetical order, with deterministic whitespace
- [x] 2.8 Implement exhaustive pre-emission validation that aborts before writing any output on: missing required templates, orphan templates, arity mismatches, duplicate templates, forbidden constructs
- [x] 2.9 Ensure error messages name the offending primitive and the specific issue so failures are debuggable

## 3. Proof-of-Concept Migration

- [x] 3.1 Write templates for 5 trivial primitives in `src/primitives.scm`: `car`, `cons`, `+`, `string-append`, `vector-ref`
- [x] 3.2 Write templates for 2 medium-complexity primitives (substituted: `null?`, `extend-environment` — `lookup-variable-value` is an operation, not a primitive)
- [x] 3.3 Write templates for 2 machine-touching primitives: `%make-compiled-procedure`, `%make-continuation` (use literal `|continuation|`/`|compiled-procedure|` symbols)
- [x] 3.4 Run `codegen-cl.scm` on this minimal primitives.scm to generate a partial `primitives-auto.lisp`
- [x] 3.5 Diff the 9 generated defuns against the current handwritten versions in `src/runtime.lisp` — clearly-equivalent (uses `cl:` qualifier where handwritten relies on package inheritance; same operations)
- [x] 3.6 Load the partial `primitives-auto.lisp` in an SBCL image and verify the 9 functions are `fboundp` and callable
- [x] 3.7 Iterate on template syntax, expander behavior, or package conventions if the diff reveals issues (added pipe-passthrough for already-escaped symbols)

## 4. Full Template Authoring

- [x] 4.1 Write templates for all `core` primitives currently backed by CL fallthrough (~50 primitives)
- [x] 4.2 Write templates for all `core` primitives currently backed by override-table entries (13 primitives)
- [x] 4.3 Write templates for all `core`/`cl` primitives with existing `ece-` wrapper defuns that are one-line bodies
- [x] 4.4 Write templates for all `core`/`cl` primitives with multi-clause `ece-` wrapper defuns (`extend-environment`, `trace`, `untrace`, %list-directory, etc.)
- [x] 4.5 Write templates for all machine-touching primitives (`%make-compiled-procedure`, `%make-continuation`, `%global-env-frame`, `execute-from-pc`, `apply-compiled-procedure`, etc.)
- [ ] 4.6 Write `:wat` templates for every primitive where a straightforward WAT translation exists (DEFERRED — Stage 0 only consumes `:cl`; authoring `:wat`/`:js` for 172 primitives is out of scope and would balloon the diff. The infrastructure supports them when codegen backends are added.)
- [ ] 4.7 Write `:js` templates for every primitive where a straightforward JS translation exists (DEFERRED — same rationale)
- [x] 4.8 Verify every `core` and `cl` entry in `primitives.def` has a matching entry in `src/primitives.scm` (codegen strict-validation passes with all 172 templates)

## 5. Runtime Integration

- [x] 5.1 Run `codegen-cl.scm` on the complete `primitives.scm` to regenerate `bootstrap/primitives-auto.lisp` with all ~172 defuns
- [x] 5.2 Inspect the generated file for any anomalies: unexpected symbols, missing defuns, malformed arity lists, broken pipe-escaped symbols
- [x] 5.3 Add `(load "bootstrap/primitives-auto.lisp")` to `src/runtime.lisp` immediately before `init-primitive-dispatch-tables`
- [x] 5.4 Verify load order — load form is positioned after all helpers, specials, structs, and `apply-primitive-procedure`, before `init-primitive-dispatch-tables`
- [x] 5.5 Delete all handwritten `ece-NAME` defuns from `src/runtime.lisp` (146 functions deleted, 21 helpers retained — file shrank from 2469 to 1854 lines)
- [x] 5.6 Delete the `*primitive-cl-overrides*` table from `src/runtime.lisp` since every override primitive now has a direct template
- [x] 5.7 Delete Convention 2 / Convention 3 fallthrough logic from `resolve-cl-primitive` — every primitive resolves via Convention 1 now
- [x] 5.8 Confirm `src/runtime.lisp` builds and loads cleanly with `qlot exec sbcl` after deletions (583 ECE tests pass)

## 6. Bootstrap Integration

- [x] 6.1 Add a Makefile rule so `bootstrap/primitives-auto.lisp` depends on `primitives.def`, `src/primitives.scm`, and `src/codegen-cl.scm`
- [x] 6.2 Wire the regeneration step into `make bootstrap` so regenerating the `.ecec` files also regenerates `primitives-auto.lisp`
- [x] 6.3 Verify two-pass bootstrap works: regeneration is byte-deterministic (verified)
- [x] 6.4 Document the regeneration command in a comment at the top of `src/primitives.scm` and `bootstrap/primitives-auto.lisp`

## 7. Validation

- [x] 7.1 Run rove suite — 124 tests passed, 0 failed
- [x] 7.2 Run ECE self-hosted test suite — 755 tests passed, 0 failed (435 collected + 755 assertions across common + cl-only)
- [x] 7.3 Run conformance test suite — 162 tests passed, 0 failed
- [x] 7.4 Run WASM test suite — 614 tests passed, 0 failed (575 ECE + 39 integration)
- [x] 7.5 Smoke test: `test-primitives-auto-fboundp` walks `primitives.def` and asserts every core/cl primitive has a `fboundp` `ece-NAME` defun (added to `tests/ece.lisp`)
- [x] 7.6 Determinism: confirmed via Makefile test — touched `primitives.scm`, regenerated, compared byte-identical against prior. Smoke test in rove confirms file exists and is non-empty.
- [x] 7.7 Validation behavior is exercised by `collect-emit-list` whenever a primitive lacks a template — `*partial-codegen?*` flag controls strict vs partial mode. Hard-error path validated during PoC iteration.
- [x] 7.8 Call/cc, continuation serialization, dynamic-wind, tracing all pass via the existing test suites listed above (these tests exercise the machine-touching primitives end to end).
- [x] 7.9 `make bootstrap` rebuilt `bootstrap.ecec` cleanly with the auto-generated `primitives-auto.lisp` already in place; the dependency rule auto-regenerates `primitives-auto.lisp` whenever its inputs change.

## 8. Cleanup and Documentation

- [x] 8.1 Final `src/runtime.lisp` is 1857 lines (down from 2469). The ~800-line target in the spec was aspirational; the remaining code is helpers, executor, operations dispatch, error wrappers, and boot infrastructure — all out of scope for Stage 0.
- [x] 8.2 Added a header comment at the top of the RUNTIME section explaining the migration and what stays vs moves to templates.
- [x] 8.3 `bootstrap/primitives-auto.lisp` header clearly identifies the file as automatically generated, names the source files, and documents `make bootstrap` as the regeneration command.
- [x] 8.4 Stale `ece-NAME` references searched: only test code referencing removed `ece-save-image`/`ece-load-image` (image machinery removed in earlier change; tests already gated on `(image-available-p)`). No new stale references introduced.
- [x] 8.5 No `.gitignore` changes needed — `bootstrap/primitives-auto.lisp` is a regular generated file alongside `bootstrap/bootstrap.ecec`.
