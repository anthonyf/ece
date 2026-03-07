# ECE Interactive Fiction Roadmap

## Vision

ECE is designed as a language for choice-based interactive fiction, inspired by SugarCube/Twine. The key insight: `call/cc` enables navigation patterns (goto, gosub, save/restore) that stack-based IF languages struggle with.

## Output Targets

- Terminal/REPL (first)
- HTML via JSCL (future)
- Choice presentation may differ per UI

## Architecture: ECE Core + IF Library

ECE stays general-purpose. The IF framework is a loadable library (`(load "if-framework.scm")`) that defines `choose`, `room`, `inventory`, etc. using macros and functions.

## Navigation Model (already supported)

- **GOTO** (no stack) = tail call to room function. ECE's TCO handles this.
- **GOSUB** (returns) = regular function call to a room.
- **Save/Restore** = `call/cc` captures full game state as a continuation.
- Primitives now store symbols (not function objects), so continuations are serializable.

## What ECE Has Today (for IF)

| Feature | ECE Mechanism |
|---------|--------------|
| Room definitions | `define` functions |
| Goto (no stack) | Tail calls with TCO |
| Gosub (returns) | Regular function calls |
| Conditionals | `if`, `cond`, `case`, `when`, `unless` |
| Variables/flags | `define`, `set` |
| Inventory (basic) | Lists + `assoc`, `member` |
| Text output | `display`, `newline` |
| Input (s-expr) | `read` |
| Save state (in-memory) | `call/cc` |
| Load game files | `load` |
| Macros | `define-macro` + quasiquote |
| Loops | `do`, named `let` |
| Error handling | `error` + `try-eval` |

## Gaps: Language-Level Primitives Needed

### Must Have

| Primitive | Purpose | Implementation |
|-----------|---------|---------------|
| `read-line` | Read raw text input as string | CL `read-line` wrapper |
| `format` / `string-format` | String interpolation/formatting | CL `format` wrapper or ECE-level template |
| `random` | Dice rolls, random events | CL `random` wrapper |

### Nice to Have

| Primitive | Purpose | Implementation |
|-----------|---------|---------------|
| Hash tables | Efficient world state | CL hash-table wrappers |
| `sleep` | Pacing, dramatic pauses | CL `sleep` wrapper |
| `clear-screen` | Fresh display between rooms | ANSI escape or CL equivalent |
| Continuation serialization | Save/load to disk | `write`/`read` with `*print-circle*` |

## Gaps: IF Library (built in ECE, loaded via `load`)

### `choose` macro — the core interaction

```scheme
(choose
  ("Talk to bartender"  (bartender-talk))
  ("Check inventory"    (show-inventory) => current-room)
  ("Leave"              (town-square))
  (when (> strength 15)
    ("Arm wrestle"      (arm-wrestle))))
```

Needs to:
1. Filter choices by guards (conditional choices)
2. Display numbered menu
3. Read player's number selection
4. Dispatch to selected action
5. Support both goto (tail) and gosub (=> return) choices

### `room` macro — syntactic sugar

```scheme
(room tavern
  "You enter a dimly lit tavern."
  (choose ...))
```

Sugar for `(define (tavern) ...)` plus optional metadata (tags, visited tracking).

### Game state utilities

- `has-item?`, `add-item!`, `remove-item!` — inventory management
- `visited?` — track which rooms the player has seen
- `save-game`, `load-game` — serialize/deserialize continuations to file

## IF Author's Core Loop

```
DESCRIBE  →  Show text to the player
PRESENT   →  Offer choices (possibly conditional)
RECEIVE   →  Get the player's selection
UPDATE    →  Change world state
NAVIGATE  →  Go to next room (goto or gosub)
```

## Suggested Implementation Order

1. Add `read-line`, `random`, basic `format` primitives
2. Build minimal IF library: `choose` macro, input loop
3. Write a sample game to validate the design
4. Add save/load (continuation serialization)
5. Add polish: `visited?`, inventory helpers, `clear-screen`
6. Port to HTML/JSCL
