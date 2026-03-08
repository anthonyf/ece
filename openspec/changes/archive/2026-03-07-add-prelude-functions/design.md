## Context

The prelude contains higher-order functions (`map`, `filter`, `reduce`, `for-each`), derived forms, PRNG, formatting, records, and `assert`. Missing are list predicate functions, function composition, and list generation.

## Goals / Non-Goals

**Goals:**
- Add `any`, `every`, `compose`, `identity`, `range` to the prelude
- All implemented as pure ECE functions

**Non-Goals:**
- Multi-list variants (e.g., `(any pred list1 list2)`)
- Negative or stepped ranges

## Decisions

### 1. All pure functions in prelude

No CL-side changes. All five are simple ECE functions using existing primitives.

### 2. Placement after existing higher-order functions

Add these after `filter` and before the derived forms section, since they're in the same category (list/function utilities).

### 3. `range` returns ascending list from 0

`(range n)` returns `(0 1 2 ... n-1)`. Single-argument form only — no start/step variants.

### 4. `any`/`every` short-circuit

`any` stops on the first truthy result. `every` stops on the first falsy result. Both are tail-recursive.

## Risks / Trade-offs

None — trivial additions with no impact on existing code.
