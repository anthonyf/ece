## Why

The sandbox example programs use `(define ...)` inside function bodies interleaved with side effects, where idiomatic Scheme uses `let`/`let*`. These examples serve as reference code for users building ECE apps, so they should model good Scheme style. Issue #109.

## What Changes

- **Refactor `analog-clock.scm`**: Replace internal `define`s in `draw-clock`, `marks`, and `hand` with `let`/`let*` bindings
- **Refactor `game-loop.scm`**: Replace internal `define`s in `game-loop` with `let`/`let*`
- **Refactor `sierpinski-triangle.scm`**: Replace internal `define`s in `go` with `let*`
- **Refactor `starfield.scm`**: Replace internal `define`s in `update` with `let*`
- **No changes to `hello-world.scm`** — already idiomatic

## Capabilities

### New Capabilities

_None._ This is a code style cleanup with no behavioral changes.

### Modified Capabilities

_None._ No requirement-level changes.

## Impact

- **sandbox/programs/*.scm**: Four files refactored for idiomatic style
- **No behavioral changes** — all programs render identically
- **No API or dependency changes**
