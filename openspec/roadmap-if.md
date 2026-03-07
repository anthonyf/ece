# ECE Interactive Fiction Roadmap

## Vision

ECE is designed as a language for choice-based interactive fiction, inspired by SugarCube/Twine. The key insight: `call/cc` enables navigation patterns (goto, gosub, save/restore) that stack-based IF languages struggle with.

## Output Targets

- Terminal/REPL (first)
- HTML via JSCL (future)
- Choice presentation may differ per UI

## Architecture: ECE Core + IF Library

ECE stays general-purpose. The IF framework is a loadable library (`(load "if-lib.scm")`) that defines `choose`, `room`, etc. using macros and functions.

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
| Lists + search | `assoc`, `member`, `list-ref`, `list-tail` |
| Text output | `display`, `newline`, `print-text`, `fmt` |
| Raw text input | `read-line` |
| S-expression input | `read` |
| Value to string | `write-to-string` |
| String operations | `string-append`, `substring`, `string->number`, etc. |
| Randomness | `random`, `random-seed!` (xorshift32 PRNG) |
| Save state (in-memory) | `call/cc` |
| Load game files | `load` |
| Macros | `define-macro` + quasiquote |
| Loops | `do`, named `let` |
| Error handling | `error` + `try-eval` |
| Vectors | `vector`, `make-vector`, `vector-ref`, `vector-set!` |
| Bitwise ops | `bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift` |

## Implementation Progress

### Priority 1: IF Library + Sample Game ← CURRENT
- [x] Add `read-line`, `random`, `fmt`/`print-text`, `write-to-string`, bitwise primitives
- [ ] Build `room` and `choose` macros in `if-lib.scm`
- [ ] Write a sample game (`simple-game.scm`) to validate the design

### Priority 2: Quality-of-Life Core Additions
- [ ] Hash tables (game state gets unwieldy with alists)
- [ ] `sleep` (dramatic pacing)
- [ ] `clear-screen` (room transitions)
- [ ] `string-downcase` / `string-split` (input handling)

### Priority 3: Save/Load
- [ ] Continuation serialization to disk (`write`/`read` with `*print-circle*`)

### Priority 4: Polish & Game State
- [ ] ANSI text styling helpers (bold, color)
- [ ] `visited?` room tracking
- [ ] Inventory helpers (`has-item?`, `add-item!`, `remove-item!`)
- [ ] More string utilities

### Priority 5: HTML Target
- [ ] Port to HTML/JSCL
