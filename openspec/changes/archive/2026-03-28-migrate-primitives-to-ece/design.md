## Context

ECE has two host runtimes (CL and WASM) that implement a shared set of primitives defined in `primitives.def`. Some primitives are pure algorithmic operations that can be expressed entirely in ECE using other primitives. The WASM runtime already moved string operations and `print` to `prelude.scm`; CL still implements them natively.

Port representations differ between runtimes: CL uses `(input-port stream)` cons cells, WASM uses `$port` GC structs. This means port predicates require host-level type checks on WASM and cannot be moved to ECE.

## Goals / Non-Goals

**Goals:**
- Move all purely algorithmic primitives to ECE prelude
- Make CL and WASM runtimes match on which primitives are host-level vs ECE-level
- Shrink both host runtimes

**Non-Goals:**
- Moving primitives that require host-level type tests (`port?`, `input-port?`, `output-port?` — different port representations per runtime)
- Moving I/O, arithmetic, or type-tag primitives
- Changing `primitives.def` ID assignments (IDs are permanent)
- Performance optimization (ECE implementations may be slightly slower than host-native; acceptable for these operations)

## Decisions

### 1. Port predicates stay host-level

WASM ports are `$port` structs (checked via `ref.test`). CL ports are `(input-port stream)` cons cells (checked via `eq (car x) 'input-port`). These are fundamentally different representations — ECE code can't portably test "is this a port?" without knowing the host's representation. Port predicates remain host primitives.

### 2. Implement in prelude.scm, not a new file

All migrated primitives go in `prelude.scm` alongside the existing string operations. The prelude loads before everything else, so these definitions are available to the compiler, reader, etc.

### 3. Remove from both host dispatch tables

After adding ECE implementations to prelude, remove the corresponding entries from:
- CL: `*wrapper-primitives*` and `*primitive-procedures*` in `runtime.lisp`
- WASM: `apply-primitive` dispatch chain in `runtime.wat`

The primitives keep their IDs in `primitives.def` but get a new platform annotation (`ece` instead of `core`) to document the migration.

### 4. gensym uses interning (matching current behavior)

Both runtimes currently intern gensym symbols (WASM calls `$intern`, CL's `gensym` is wrapped). The ECE implementation uses `string->symbol` which also interns. Uninterned symbols are not needed since gensym is primarily used for compiler label names.

### 5. Migration order: CL-only removals first, then shared moves

Phase 1: Remove CL host implementations for primitives WASM already handles in prelude (strings 36-41, print 66). This is pure removal — prelude.scm already has the implementations.

Phase 2: Add new ECE implementations to prelude and remove from both hosts (char classification, equal?, eqv?, gensym).

## Risks / Trade-offs

- **[Low] Performance regression for equal?/eqv?** — ECE equal? is recursive Scheme code vs host-native `equal`/`eql`. For deeply nested structures this is slower. Acceptable: equal? is rarely in hot paths, and the kernel-minimization goal outweighs micro-optimization.
- **[Low] Bootstrap ordering** — Migrated primitives must be defined before any prelude code that uses them. `char-whitespace?` is used by `string-trim`; `equal?` may be used by test infrastructure. Placement in prelude.scm must respect these dependencies.
- **[Low] gensym counter reset** — ECE gensym uses a top-level `define` + `set!` counter. Counter resets on fresh boot, matching current behavior.
