# Documentation Metadata Design

ECE should support documentation as runtime data attached to language bindings,
not as comments scraped from source. The authoring surface should feel Lispy:
definition forms carry doc values, the REPL can inspect them, modules can expose
them, and later tooling can export the same data into reference documentation.

This document describes the full design target and the intended implementation
phases. The first implementation should deliberately be smaller than the full
target so the data model can stabilize before user-facing tooling grows around
it.

## Goals

- Treat documentation text as ECE data that can be read at runtime.
- Keep a plain string as the common authoring shorthand.
- Store documentation internally as structured entries so later tooling does not
  need a migration.
- Support procedures, values, macros, syntax forms, records, modules, and module
  exports.
- Preserve documented macro behavior across REPL use, source loading, compiled
  archives, CL runtime, and WASM runtime.
- Leave room for REPL help, search, and deterministic Markdown/reference export.

## Non-Goals for the First Implementation

- No `help`, `apropos`, or Markdown export in the first implementation PR.
- No record documentation in the first implementation PR.
- No macro or syntax documentation in the first implementation PR.
- No module/export documentation behavior in the first implementation PR.

Those features are part of the full design target, but they should land after
the core registry and `define/doc` behavior are proven.

## Documentation Entries

Documentation entries are structured ECE data. A string in an authoring form is
accepted as shorthand for the entry summary, but the stored shape should be rich
enough for later tools.

The required entry fields are:

- `:name`: binding symbol or module/export name.
- `:kind`: one of the public documentation kind symbols.
- `:summary`: primary doc string.
- `:signature`: inferred or explicit signature data, or `#f`.
- `:module`: module identity when documentation is scoped to a module, otherwise
  `#f`.
- `:generated?`: `#t` for generated documentation entries, otherwise `#f`.

The design also reserves these optional fields:

- `:examples`: examples for help and reference export.
- `:see-also`: related symbols or module exports.

The public kind symbols are:

- `'procedure`
- `'value`
- `'macro`
- `'syntax`
- `'record`
- `'module`

## Core API

The core registry API should be available from ordinary ECE code:

```scheme
(set-documentation! name kind doc . options)
(documentation name . options)
(documentation-signature name . options)
(documentation-entry name . options)
```

`set-documentation!` records or replaces a documentation entry and returns
`name`. `doc` may be a string shorthand or a structured entry. The first
implementation should accept strings and construct a structured entry with
default fields. Later phases can accept richer entry values.

`documentation` returns the summary string for the matching entry, or `#f` when
no entry exists.

`documentation-signature` returns the entry signature, or `#f` when no entry or
signature exists.

`documentation-entry` returns the structured entry, or `#f` when no entry
exists.

Lookup options should eventually support explicit `:kind` and `:module`. When a
kind is omitted, lookup should search in this order:

```scheme
'(procedure syntax macro value record module)
```

The first implementation can support only the options needed by its tests, but
the registry shape should not prevent kind and module lookup.

## Authoring Forms

### `define/doc`

`define/doc` documents ordinary procedures and values.

```scheme
(define/doc (square x)
  "Return x multiplied by itself."
  (* x x))

(define/doc pi
  "Approximate pi."
  3.14159)
```

The procedure form expands to an ordinary `define` plus a documentation entry
with kind `'procedure` and signature `'(square x)`.

The value form expands to an ordinary `define` plus a documentation entry with
kind `'value` and signature `'pi`.

### `define-macro/doc`

`define-macro/doc` documents unhygienic macros.

```scheme
(define-macro/doc (unless test . body)
  "Evaluate body when test is false."
  `(if (not ,test) (begin ,@body)))
```

The expansion must preserve both compile-time and runtime macro behavior:

- the macro is available to later forms in the same compilation unit;
- compiled archives re-register the macro when loaded;
- the documentation entry is registered at runtime.

This means the implementation cannot only expand to a raw `define-macro`. It
must also arrange for the same runtime `set-macro!` registration shape that
compiled archives already use for top-level `define-macro` forms.

### `define-syntax/doc`

`define-syntax/doc` documents `syntax-rules` forms.

```scheme
(define-syntax/doc when
  "Evaluate body when test is true."
  (syntax-rules ()
    ((_ test body ...)
     (if test (begin body ...)))))
```

Only `syntax-rules` transformers are in scope for this design, matching the
current `define-syntax` implementation. The signature should be inferred from
the first pattern by replacing `_` with the syntax name, for example
`'(when test body ...)`.

The expansion must preserve the same archive/load behavior as
`define-macro/doc`: syntax transformers must be available during compilation and
must be re-registered when compiled archives load.

### `define-record/doc`

`define-record/doc` documents records and generated bindings.

```scheme
(define-record/doc point
  "A two-dimensional point."
  x y)
```

The full design should document:

- the record type, kind `'record`;
- constructor, kind `'procedure`;
- predicate, kind `'procedure`;
- accessors, kind `'procedure`;
- mutators, kind `'procedure`;
- functional update helpers, kind `'procedure`;
- copy function, kind `'procedure`.

Generated binding entries should use `:generated? #t`.

## Module Documentation

Modules are already implemented, so documentation must be designed around
module identity from the start even if module behavior lands after the first
implementation PR.

When code executes inside a module, documentation created by definition forms
should be scoped to that module identity. Two modules may export the same symbol
name with different documentation; their entries must not collide.

Module export documentation is an export metadata view over documented module
bindings:

- a definition records documentation for a local binding in a module;
- the module instance captures declared exports;
- documentation lookup for an exported name consults the documentation entry for
  that exported binding under the module identity.

Eventual module APIs should include:

```scheme
(module-documentation module export-name . options)
(module-documentation-entry module export-name . options)
```

These return the exported binding's summary or full documentation entry.

## Tooling Target

After the registry and authoring forms are stable, ECE should add user-facing
documentation tools:

- `help`: print one binding or module export's documentation.
- `apropos`: search names and summaries.
- Markdown/reference export: generate deterministic reference docs under
  `docs/reference/`.

Generated documentation must be deterministic. Any traversal over hash-table
keys should sort names before writing output.

The first tooling implementation exposes these APIs:

```scheme
(documentation-entries . options)
(help name . options)
(apropos query . options)
(documentation-reference-markdown . options)
(write-documentation-reference . options)
```

`documentation-entries` returns sorted structured entries. `help` prints a
single entry and returns it, or prints a miss and returns `#f`. `apropos` prints
matching one-line summaries and returns the sorted entries. The Markdown helpers
format or write the same sorted entry list; `write-documentation-reference`
defaults to `docs/reference/index.md`.

## Implementation Phases

### Phase 0: Design Doc

- Add this design document.
- Link it from `docs/README.md`.
- Do not change runtime behavior.

### Phase 1: Core Registry and `define/doc`

- Implement the documentation registry and core lookup APIs in
  `src/prelude.scm`.
- Store structured entries with a `:module` field present and defaulting to
  `#f`.
- Implement `define/doc` for procedure and value definitions.
- Add common tests for:
  - direct `set-documentation!`;
  - `documentation`;
  - `documentation-signature`;
  - `documentation-entry`;
  - missing docs returning `#f`;
  - procedure `define/doc` preserving callable behavior;
  - value `define/doc` preserving normal binding behavior.
- Regenerate bootstrap.

### Phase 2: Macro and Syntax Documentation

- Add `define-macro/doc` in `src/prelude.scm`.
- Add `define-syntax/doc` in `src/syntax-rules.scm`.
- Preserve same-file macro availability.
- Preserve compiled archive reload behavior by emitting runtime `set-macro!`
  registration.
- Add common tests for same-file expansion.
- Add CL-only archive/load tests for macro and syntax transformer reload.
- Regenerate bootstrap.

### Phase 3: Record Documentation

- Add `define-record/doc`.
- Document the record type and generated bindings.
- Mark generated entries with `:generated? #t`.
- Add tests for generated documentation entries and unchanged record behavior.
- Regenerate bootstrap.

### Phase 4: Module and Export Documentation

- Add current documentation module state, set during module instantiation in
  `src/compilation-unit.scm`.
- Store docs from module init under that module identity.
- Extend module instances or export metadata to expose documentation for
  declared exports.
- Add module documentation lookup APIs.
- Add tests for two modules exporting the same symbol name with different docs.
- Regenerate bootstrap.

### Phase 5: Help, Search, and Export

- Add `help`.
- Add `apropos`.
- Add deterministic Markdown/reference generation.
- Add tests for search output and generated Markdown content.
- Regenerate bootstrap if the tooling is bootstrapped.

## Validation

Any implementation phase that touches bootstrapped source should run:

```sh
make bootstrap
make test-ece
make test-wasm
make test-rove
git diff --check
```

Phase 0 is documentation-only and should at least run:

```sh
git diff --check
```
