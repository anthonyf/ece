## Context

The sandbox programs in `sandbox/programs/` are the primary example code users see when exploring ECE's canvas/game capabilities. Four of the five programs use `(define ...)` inside function bodies interleaved with side-effectful expressions. While ECE supports internal `define`, idiomatic Scheme reserves it for the top of a body (like `letrec`) and uses `let`/`let*` for sequential bindings mixed with effects.

## Goals / Non-Goals

**Goals:**
- Replace non-idiomatic internal `define` usage with `let`/`let*`
- Preserve exact runtime behavior — no functional changes
- Model good Scheme style for users learning from examples

**Non-Goals:**
- Algorithmic improvements or feature additions to the examples
- Restructuring the sandbox directory or adding new examples
- Addressing issue #106 (`(quote ...)` vs `'`) — separate concern

## Decisions

### 1. Use `let*` for sequential bindings with dependencies

Most internal `define`s reference earlier bindings (e.g., `ms` → `sec-frac` → `sa`). `let*` is the natural fit since bindings are evaluated sequentially and each can reference previous ones.

### 2. Use `let` + named `let` for local helper functions

Internal helper functions like `marks`, `hand`, `go`, and `update` that are defined at the top of their enclosing function body can stay as internal `define`s — this is idiomatic Scheme for local procedures. However, where they contain non-idiomatic nested `define`s, those inner bindings should become `let*`.

### 3. Keep top-level `define`s and `set!` as-is

Top-level state variables (`x`, `y`, `dx`, `dy`, etc.) with `set!` mutation are the standard pattern for canvas game loops. No changes needed.

## Risks / Trade-offs

- **Risk**: `let*` changes scoping from body-wide to block-scoped.
  → **Mitigation**: Each file is small enough to verify manually. No binding is referenced outside its natural scope.
