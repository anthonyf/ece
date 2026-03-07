## Why

ECE has hash tables for structured data, but creating typed records requires manual boilerplate: writing a constructor, predicate, accessors, and mutators for each record type. A `define-record` macro eliminates this boilerplate and provides a conventional, Scheme-like record system built on the existing hash table infrastructure.

## What Changes

- Add a `define-record` macro to ECE's stdlib that generates:
  - Constructor function (`make-<name>`)
  - Type predicate (`<name>?`)
  - Field accessors (`<name>-<field>`)
  - Field mutators (`set-<name>-<field>!`)
  - Functional update accessors (`<name>-with-<field>`) returning a new copy
  - Copy function (`copy-<name>`)
- Records are represented as hash tables with a `type` key for discrimination

## Capabilities

### New Capabilities
- `define-record`: Macro that generates record type definitions with constructor, predicate, accessors, mutators, functional update accessors, and copy function, backed by hash tables

### Modified Capabilities

None — this is purely additive.

## Impact

- `src/ece.lisp`: New macro definition in the stdlib section (no CL-side changes needed)
- `tests/ece.lisp`: New test suite for record functionality
