# Module and Archive Plan

ECE should grow a module system by first cleaning up the archive system. The
goal is not to copy Racket's linklet implementation, but to move ECE archives
toward the same architectural shape: compiled units with explicit identity,
imports, exports, metadata, and controlled instantiation.

Racket's linklets are the closest reference point. A linklet is a primitive
compiled unit with imports, exports, definitions, and expressions. Linklet
bundles group linklets and metadata, and Racket modules are implemented on top
of that lower layer. ECE already has a lower layer of archive sections and
per-procedure code objects, so the local path is to make archive sections more
linklet-like while keeping ECE's register-machine code objects.

## Current Model

An `.ecec` bundle is a concatenation of archive sections. Each section is keyed
by `:file` and contains `:entries`.

- Entry `0` is the source file init code object.
- Entries `1..N` are nested lambda code objects reachable from the init.
- Nested code-object constants are stored as local `(co-ref N)` references.
- Loading materializes code objects, registers them by `(file-stem . index)`,
  attaches native zones, and immediately runs entry `0`.
- Running entry `0` mutates the shared global environment.

That works for bootstrap files and REPL-like loading, but it bakes file order
and global mutation into the archive format. Proper modules need a stable
semantic identity, explicit dependencies, declared exports, and instantiation
that can happen once after dependencies are available.

## Target Model

Introduce an archive unit abstraction. An archive unit is the semantic wrapper
around one group of code objects.

```scheme
(:ecec-section
  :version 3
  :kind :module
  :unit-id (module (game inventory) 0)
  :module (game inventory)
  :phase 0
  :source "game/inventory.scm"
  :imports ((ece base) (game item))
  :exports (make-inventory inventory-add inventory-has?)
  :init 0
  :entries (...))
```

For current file archives, the loader can synthesize equivalent metadata:

```scheme
:kind :file
:unit-id prelude
:source "prelude.scm"
:imports ()
:exports :all
:init 0
```

The key distinction is that `:source` is provenance, while `:unit-id` is code
identity. Native zones, archive code-object registries, and serialized
continuation references should eventually key code objects by `(unit-id . index)`
instead of `(file-stem . index)`.

## Loader Shape

Archive loading should be split into separate operations:

1. Parse archive sections into archive-unit descriptors.
2. Materialize code objects and patch local `(co-ref N)` references.
3. Register code objects under `(unit-id . index)`.
4. Attach native zones using the same unit key.
5. Instantiate units when requested.

Current file sections can still instantiate immediately to preserve existing
load behavior. Module sections should register first and instantiate only after
their imports are resolved.

## Module Instantiation

Add a module registry before adding module syntax:

```scheme
*archive-units*     ;; unit-id -> parsed/materialized archive unit
*module-instances*  ;; module name -> instantiated module record
```

A module instance records:

- module name
- imports
- exports
- private environment
- code-object vector
- archive/unit fingerprint

Instantiating a module should:

1. Return the existing instance if the module is already instantiated.
2. Resolve and instantiate imported modules first.
3. Create a private module environment.
4. Bind imported exports in that environment.
5. Execute the module init code object once.
6. Capture declared exports in the module instance.

This follows the important Racket behavior: module declaration/availability is
separate from runtime instantiation, and repeated imports use an existing
instance instead of rerunning top-level effects.

## Surface Syntax

The first module surface should stay small:

```scheme
(define-module (game inventory)
  (import (ece base)
          (game item))
  (export make-inventory
          inventory-add
          inventory-has?)

  (define (make-inventory)
    '())

  (define (inventory-add inv item)
    (cons item inv)))
```

Initial constraints:

- one module per primary source file
- static top-level `import` and `export`
- no macro exports yet
- no `import-syntax` or phase `1` units yet
- no separately compiled fragments contributing to the same module

Textual `include` inside a module can come later. That lets one semantic module
span multiple source fragments while still compiling to one archive unit.

## Phases

Phase support should be explicit but deferred.

The archive metadata should include `:phase` early, even if all initial sections
use phase `0`. When macro imports are added, ECE can introduce phase `1` units
for compile-time bindings and macro transformer availability.

Do not add Racket's full phase system in the first module pass. The immediate
goal is a reliable runtime module boundary; macro phase separation is a later
layer.

## Save/Restore

Module archive units should improve save/restore compatibility. A serialized
archive code-object reference should eventually identify module code by module
unit identity:

```scheme
(%ser/co-ref (module (game inventory) 0) 7 fingerprint)
```

This is more stable than using a source filename stem. Restore can report:

- missing module/unit
- missing code-object index
- fingerprint mismatch

That aligns with the save/restore compatibility policy and makes code changes
loud instead of silently resuming a continuation in different code.

## Native Zones

Native-zone registration should use the same archive unit key as the loader:

```scheme
((module (game inventory) 0) . 7)
```

Generated zone names can still be filename-derived for readability, but lookup
must be based on unit identity. This avoids tying accelerated code to source
layout and makes stale-zone checks line up with save/restore checks.

## Implementation Plan

### Phase 1: Archive Unit Cleanup

- Introduce helpers that derive a `unit-id` for every archive section.
- Route code-object registry keys through `(unit-id . index)` helpers.
- Preserve current `(file-stem . index)` behavior for existing archives.
- Split loader internals into parse, materialize/register, attach zones, and
  run init, while preserving current external behavior.
- Add regression tests that current `.ecec` bundles still load and register the
  same code objects.

### Phase 2: Archive Metadata Versioning

- Add optional `:kind`, `:unit-id`, `:imports`, `:exports`, and `:init` fields.
- Keep loaders tolerant of current version 2 sections.
- Add archive-format golden tests for both legacy and new metadata.
- Update documentation for the keyword-style archive format.

### Phase 3: Module Registry Without Syntax

- Add archive/module registries.
- Support hand-authored or test-generated module archive sections.
- Implement module instantiation once per module identity.
- Add loud errors for missing imports, missing exports, and import cycles.

### Phase 4: Minimal Module Compiler

- Add `define-module` parsing/compilation.
- Emit module metadata into archive sections.
- Compile module body against a private module environment with imported
  bindings installed.
- Capture and register only declared exports.

### Phase 5: Module-Aware Tooling

- Teach `compile-system` to compile a module graph.
- Allow bundles to contain multiple module sections.
- Add entry-point support for running a module export such as `(main)`.
- Add diagnostics that name module identities instead of source filenames when
  imports fail.

### Phase 6: Macro Phases

- Add explicit syntax imports only after value modules are working.
- Introduce phase `1` archive units for macro transformer availability.
- Keep phase metadata in archives so CL and WASM loaders can stay aligned.

## First PR Scope

The first implementation PR should be Phase 1 only. It should not add module
syntax. The intended output is a cleaner archive loader and registry model that
still behaves exactly like today's file-based global loader.

That makes the next steps incremental instead of forcing the module system to
fight the current file-stem/global-environment assumptions.
