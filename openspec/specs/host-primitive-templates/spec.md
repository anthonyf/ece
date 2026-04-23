## ADDED Requirements

### Requirement: Template definition form

ECE SHALL provide a `define-host-primitive` form in `src/primitives.scm` for declaring primitive implementations as multi-target templates. Each form SHALL have the shape `(define-host-primitive (NAME . PARAMS) KEY TEMPLATE ...)` where `NAME` is the primitive's ECE name, `PARAMS` is a fixed-arity or dotted parameter list matching the primitive's arity in `primitives.def`, and each `KEY TEMPLATE` pair associates a target host (`:cl`, `:wat`, `:js`) with a quasiquoted template body.

#### Scenario: Fixed-arity primitive
- **WHEN** `(define-host-primitive (car p) :cl \`(cl:car ,p))` appears in `src/primitives.scm`
- **THEN** the template system SHALL register `car` with parameter list `(p)` and a `:cl` template of `` `(cl:car ,p) ``

#### Scenario: Variadic primitive
- **WHEN** `(define-host-primitive (+ . args) :cl \`(cl:apply #'cl:+ ,args))` appears
- **THEN** the template system SHALL register `+` with a variadic parameter list and treat `args` as a single parameter bound to the rest list

#### Scenario: Multi-target primitive
- **WHEN** a `define-host-primitive` form carries both `:cl` and `:wat` keys
- **THEN** both templates SHALL be stored under the primitive's entry
- **AND** the Stage 0 codegen SHALL consume only the `:cl` template
- **AND** the `:wat` template SHALL be stored for future consumption by later codegen stages

### Requirement: Template body syntax

Template bodies SHALL be ECE quasiquoted s-expressions. Parameter substitution SHALL be expressed via `(unquote NAME)` (written as `,NAME` in source) where `NAME` matches a parameter in the enclosing `define-host-primitive` form.

#### Scenario: Single placeholder
- **WHEN** a template body is `` `(cl:car ,p) ``
- **AND** `p` is a parameter of the enclosing primitive
- **THEN** the expander SHALL substitute `p` at the `(unquote p)` position

#### Scenario: Multiple placeholders
- **WHEN** a template body is `` `(cl:cons ,a ,d) ``
- **THEN** the expander SHALL substitute `a` and `d` independently at their respective positions

#### Scenario: Unquote-splicing is forbidden
- **WHEN** a template body contains `(unquote-splicing NAME)` (written `,@NAME`)
- **THEN** the codegen SHALL signal an error naming the primitive and the offending form
- **AND** SHALL NOT emit the output file

#### Scenario: Nested quasiquote is forbidden
- **WHEN** a template body contains a nested `(quasiquote ...)` inside its outer template
- **THEN** the codegen SHALL signal an error naming the primitive
- **AND** SHALL NOT emit the output file

#### Scenario: Unknown placeholder is rejected
- **WHEN** a template body contains `(unquote x)` but `x` is not a parameter of the enclosing primitive
- **THEN** the codegen SHALL signal an error naming the primitive and the unbound placeholder name
- **AND** SHALL NOT emit the output file

### Requirement: Template expander semantics

The template expander SHALL walk a quasiquoted template body and produce a substituted s-expression. The substitution behaviour depends on the caller's bindings argument:

- For the Stage 0 defun-emission path (bindings = #f), each `(unquote NAME)` SHALL be replaced with the bare `NAME` symbol so it lines up with the surrounding `defun`'s parameter list.
- For the Stage 1+ inline-substitution path (bindings = an alist of `(name . cl-form)` pairs), each `(unquote NAME)` SHALL be replaced with the associated CL form so the expanded body can be spliced inline at a primitive call site.

In both modes the expander SHALL leave all other forms untouched, including atoms, pairs, strings, numbers, and quoted data.

#### Scenario: Tree walk preserves structure
- **WHEN** a template body is `(cl:progn (cl:setf (cl:aref ,vec ,idx) ,val) ,val)`
- **THEN** the expander SHALL produce `(cl:progn (cl:setf (cl:aref vec idx) val) val)` after substitution

#### Scenario: Literal symbols pass through
- **WHEN** a template body contains `'|continuation|`
- **THEN** the expander SHALL leave the pipe-escaped symbol unchanged in the output

#### Scenario: Atoms pass through
- **WHEN** a template body contains string literals, numbers, or `t`/`nil`
- **THEN** the expander SHALL emit them verbatim

### Requirement: Package conventions in templates

Symbols inside template bodies SHALL follow a package convention that unambiguously distinguishes Common Lisp symbols from ECE-package helpers.

#### Scenario: CL built-ins are prefixed
- **WHEN** a template references a Common Lisp function (`car`, `cons`, `apply`, `equal`, etc.)
- **THEN** it SHALL use the `cl:` prefix (e.g., `cl:car`, `cl:equal`)

#### Scenario: ECE helpers are bare
- **WHEN** a template references an ECE-package helper (`scheme-bool`, `hash-frame-p`, `cl-winding-stack`, `compiled-procedure-p`, `*executing-code-obj*`, `*global-env*`)
- **THEN** it SHALL use the bare name without a package prefix

#### Scenario: Generated file resolves bare names in ECE package
- **WHEN** `bootstrap/primitives-auto.lisp` is loaded
- **THEN** its header SHALL contain `(in-package :ece)` so that bare symbols resolve to the `:ece` package

### Requirement: Codegen tool

ECE SHALL provide `src/codegen-cl.scm`, an ECE program that joins `primitives.def` with `src/primitives.scm` and writes `bootstrap/primitives-auto.lisp`. The codegen SHALL be invokable at build time via the `make bootstrap` pipeline.

#### Scenario: Read both inputs
- **WHEN** `codegen-cl.scm` runs
- **THEN** it SHALL parse `primitives.def` into a name→metadata table containing all 215 entries
- **AND** it SHALL load `src/primitives.scm` so that every `define-host-primitive` form registers in `*host-primitives*`

#### Scenario: Join and emit
- **WHEN** every `core` or `cl` primitive in the manifest has a matching template
- **THEN** the codegen SHALL emit one `(defun ece-NAME ...)` per primitive to `bootstrap/primitives-auto.lisp`
- **AND** the emitted defun parameter list SHALL match the primitive's arity from `primitives.def`
- **AND** the emitted defun body SHALL be the expansion of the primitive's `:cl` template

#### Scenario: ECE-platform primitives are skipped
- **WHEN** a primitive in `primitives.def` has platform tag `ece`
- **THEN** the codegen SHALL NOT emit a defun for it
- **AND** the codegen SHALL error if an `ece`-platform primitive has an entry in `src/primitives.scm`

#### Scenario: Browser-platform primitives skip `:cl` emission
- **WHEN** a primitive has platform tag `browser`
- **THEN** the codegen SHALL NOT require a `:cl` template
- **AND** the codegen SHALL preserve any existing error-stub behavior for browser primitives

### Requirement: Validation before emission

The codegen SHALL validate inputs exhaustively before writing any output. Any validation failure SHALL abort emission without producing a partial or corrupt output file.

#### Scenario: Missing required template
- **WHEN** a `core` or `cl` primitive in `primitives.def` has no matching `define-host-primitive` entry in `src/primitives.scm`
- **THEN** the codegen SHALL signal an error naming the primitive
- **AND** SHALL NOT write `bootstrap/primitives-auto.lisp`

#### Scenario: Orphan template
- **WHEN** `src/primitives.scm` contains a `define-host-primitive` for a primitive not listed in `primitives.def`
- **THEN** the codegen SHALL signal an error naming the primitive

#### Scenario: Arity mismatch
- **WHEN** a template's parameter list does not match the primitive's arity from `primitives.def`
- **THEN** the codegen SHALL signal an error naming the primitive and both arities

#### Scenario: Duplicate template
- **WHEN** `src/primitives.scm` contains two `define-host-primitive` forms for the same primitive name
- **THEN** the codegen SHALL signal an error naming the duplicated primitive

### Requirement: Output file format

`bootstrap/primitives-auto.lisp` SHALL be a valid Common Lisp source file that begins with a generated-file header, establishes the `:ece` package, and contains one `defun` per `core` or `cl` primitive.

#### Scenario: Header
- **WHEN** `bootstrap/primitives-auto.lisp` is inspected
- **THEN** its first lines SHALL identify it as automatically generated
- **AND** SHALL name the source files (`primitives.def`, `src/primitives.scm`)
- **AND** SHALL document the regeneration command (`make bootstrap`)

#### Scenario: Package form
- **WHEN** `bootstrap/primitives-auto.lisp` loads
- **THEN** it SHALL contain `(in-package :ece)` before any `defun`

#### Scenario: Deterministic ordering
- **WHEN** the codegen emits defuns
- **THEN** they SHALL appear in a stable order (alphabetical by primitive name)
- **AND** regenerating the file with unchanged inputs SHALL produce byte-identical output

#### Scenario: Generated defun per core/cl primitive
- **WHEN** the codegen joins manifest and templates
- **THEN** every `core` and `cl` entry SHALL produce exactly one `(defun ece-NAME PARAMS BODY)` in the output

### Requirement: Runtime loads generated file

`src/runtime.lisp` SHALL load `bootstrap/primitives-auto.lisp` at boot time after all referenced helper functions and special variables are defined, and before `init-primitive-dispatch-tables` runs.

#### Scenario: Load position
- **WHEN** CL boots and processes `src/runtime.lisp`
- **THEN** the `(load "bootstrap/primitives-auto.lisp")` call SHALL occur after `scheme-bool`, `hash-frame-p`, `cl-winding-stack`, `*executing-code-obj*`, `*global-env*`, and the `code-object` struct are defined
- **AND** SHALL occur before `(init-primitive-dispatch-tables)` is called

#### Scenario: Dispatch resolution unchanged
- **WHEN** `init-primitive-dispatch-tables` runs after the load
- **THEN** `resolve-cl-primitive` SHALL find every `ece-NAME` via Convention 1 (`ece-<NAME>` in the `:ece` package)
- **AND** the dispatch table SHALL be populated identically to the pre-migration state

### Requirement: Bootstrap integration

The `make bootstrap` target SHALL regenerate `bootstrap/primitives-auto.lisp` from `primitives.def`, `src/primitives.scm`, and `src/codegen-cl.scm`. The generated file SHALL be committed to version control.

#### Scenario: Regeneration
- **WHEN** `make bootstrap` runs after any of `primitives.def`, `src/primitives.scm`, or `src/codegen-cl.scm` has changed
- **THEN** `bootstrap/primitives-auto.lisp` SHALL be regenerated
- **AND** the regenerated file SHALL reflect the latest template definitions

#### Scenario: Idempotent regeneration
- **WHEN** `make bootstrap` runs twice with unchanged inputs
- **THEN** the second run SHALL produce a byte-identical `bootstrap/primitives-auto.lisp`

#### Scenario: Rollback path
- **WHEN** a regenerated `bootstrap/primitives-auto.lisp` is broken
- **THEN** `git checkout bootstrap/primitives-auto.lisp` SHALL restore the previous working version
- **AND** the runtime SHALL boot cleanly from the restored file

### Requirement: Behavioral parity with pre-migration runtime

After migration, every `ece-NAME` function generated from a template SHALL have behavior indistinguishable from its pre-migration handwritten counterpart.

#### Scenario: Test suite passes unchanged
- **WHEN** the full test suite (rove, ECE self-hosted tests, conformance, WASM) runs after migration
- **THEN** every test SHALL pass with zero failures
- **AND** no test SHALL require modification to accommodate the migration

#### Scenario: Call/cc round-trips
- **WHEN** a test invokes `call/cc` and later resumes the captured continuation
- **THEN** the behavior SHALL match the pre-migration interpreter exactly
- **AND** the `capture-continuation` auto-stub SHALL produce continuation objects structurally equivalent to pre-migration output

#### Scenario: Serialization round-trips
- **WHEN** a continuation is serialized and reconstructed
- **THEN** the reconstructed continuation SHALL behave identically to pre-migration

#### Scenario: Error bridging unchanged
- **WHEN** a primitive returns an error sentinel
- **THEN** `execute-instructions` SHALL dispatch to the Scheme `error` procedure as it does today
