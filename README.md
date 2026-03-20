# ECE

[![Tests](https://github.com/anthonyf/ece/actions/workflows/test.yml/badge.svg)](https://github.com/anthonyf/ece/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/anthonyf/ece/blob/main/LICENSE)

A Scheme-like language implemented in Common Lisp. Inspired by SICP Section 5.5, ECE compiles expressions to register machine instructions and executes them with an explicit stack — no reliance on the host language's call stack. Zero external dependencies.

## Key Features

- **Full tail call optimization** — all tail positions (if, begin, cond, let, let*, when, unless, and, or, case, do) run in constant stack space
- **First-class continuations** — `call/cc` captures the full continuation stack
- **Hygienic-ish macros** — `define-macro` with quasiquote, unquote, and unquote-splicing
- **Record system** — `define-record` generates constructors, predicates, accessors, mutators, and copy functions
- **Hash tables** — with `{}` literal syntax and functional update via `hash-set`
- **Self-hosting** — compiler, reader, assembler, and standard library are all written in ECE
- **Per-file compiled boot** — bootstraps from `.ecec` files (pre-compiled s-expression instruction units), not a monolithic image

## Architecture

ECE has a small CL runtime (~1,900 lines) that provides the register machine executor, environment, and primitives. Everything else is written in ECE itself and loaded at boot from pre-compiled `.ecec` files:

| Module | Language | Role |
|--------|----------|------|
| `src/runtime.lisp` | CL | Executor, environment, primitives, boot loader |
| `src/prelude.scm` | ECE | Standard library, macros, hash tables, error handling |
| `src/compiler.scm` | ECE | SICP 5.5 compiler with lexical addressing |
| `src/reader.scm` | ECE | S-expression reader |
| `src/assembler.scm` | ECE | Instruction assembler, `load` function |
| `src/compilation-unit.scm` | ECE | `compile-file`, `load-compiled` |

## Language Overview

### Core Forms

`lambda`, `if`, `begin`, `define`, `set`, `quote`, `call/cc`, `define-macro`

### Derived Forms (via macros)

`let`, `let*`, `letrec`, `cond`, `case`, `when`, `unless`, `and`, `or`, `do`, `assert`

### Data Types

Numbers, strings, characters, booleans (`#t`/`#f`), symbols, pairs/lists, vectors, hash tables, records, continuations

### Standard Library

`map`, `filter`, `reduce`, `for-each`, `any`, `every`, `range`, `reverse`, `assoc`, `member`, `list-ref`, `list-tail`, `append`, `apply`, `compose`, `identity`, `fmt`, `lines`, `random`, `define-record`

### I/O

`display`, `print`, `newline`, `read`, `read-line`, `load`, `write-to-string`

### Strings & Characters

`string-append`, `substring`, `string-length`, `string-ref`, `string-split`, `string-join`, `string-contains?`, `string-upcase`, `string-downcase`, `string->number`, `number->string`, `string->symbol`, `symbol->string`, `string=?`, `string<?`, `string>?`, `char?`, `char=?`, `char<?`, `char->integer`, `integer->char`

String interpolation is supported at the reader level: `"Hello $name, you are $(+ age 1) years old"`. Use `$$` for a literal `$`.

### Vectors

`vector`, `make-vector`, `vector-ref`, `vector-set!`, `vector-length`, `vector->list`, `list->vector`

### Hash Tables

`hash-table`, `hash-ref`, `hash-set!`, `hash-set`, `hash-remove!`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-table?`

### Bitwise Operations

`bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`

## Serializable Continuations

ECE continuations can be saved to disk and restored later with `save-continuation!` / `load-continuation`. This enables save/restore for games, browser page refresh survival, and persistent workflows.

### The Lexical State Pattern

For reliable serialization, keep mutable state in **lexical scope** (inside a function), not in global `define`:

```scheme
;; Game logic — pure functions at the top level
(define (describe-room room hp)
  (string-append "You are in " room " with " (number->string hp) " hp"))

(define (damage hp amount)
  (- hp amount))

;; Game state — all inside run-game's scope
(define (run-game)
  (define room (make-parameter "kitchen"))
  (define hp (make-parameter 100))
  (define inventory (make-parameter '()))

  ;; Mutate state through gameplay
  (room "dungeon")
  (hp (damage (hp) 30))

  ;; Save: captures room, hp, inventory automatically
  (save-continuation! "save.dat"
    (call/cc (lambda (k) k)))

  ;; External functions work — pass values, not parameters
  (display (describe-room (room) (hp)))
  (newline))

(run-game)
```

**Why this works:** `call/cc` captures the lexical environment — everything defined inside `run-game`. Parameters, local variables, and closures are all included. External functions (`describe-room`, `damage`) live in the global scope and are always available after boot — they don't need to be serialized.

**Why global `define` doesn't work for saved state:** The global environment is shared with the runtime (300+ bindings for the compiler, reader, prelude). The serializer uses a sentinel to skip it, so global state is not captured. This is the same limitation [Racket's stateless servlets](https://docs.racket-lang.org/web-server/stateless.html) have — "the store is not serialized."

### Restoring a Save

```scheme
;; Load the saved continuation and invoke it
(define k (load-continuation "save.dat"))
(k 'resume)  ;; resumes inside run-game with room="dungeon", hp=70
```

### Browser / Page Refresh Pattern

For single-page apps, save the continuation to localStorage after every user action:

```scheme
(define (game-loop)
  (define state (make-parameter {room "start" hp 100}))

  (let loop ()
    ;; Save checkpoint after every choice
    (save-continuation! "autosave"
      (call/cc (lambda (k) k)))

    ;; Present choices, get input, update state...
    (loop)))
```

On page load, check for an autosave and restore it instead of starting fresh.

## Use Cases

ECE's first-class continuations make it well-suited for applications that need complex control flow — such as interactive fiction engines, where save/restore and goto/gosub map naturally to `call/cc`.

[Dunge](https://github.com/anthonyf/dunge) is a choice-based interactive fiction game being built with ECE.

## Getting Started

### Prerequisites

- [SBCL](http://www.sbcl.org/)
- [qlot](https://github.com/fukamachi/qlot)

### Setup

```sh
qlot install
```

### REPL

```sh
make repl
```

```
ece> (define (factorial n) (if (= n 0) 1 (* n (factorial (- n 1)))))
ece> (factorial 5)
120
ece> (define-record point x y)
ece> (point-x (make-point 10 20))
10
ece> (map (lambda (x) (* x x)) (list 1 2 3 4 5))
(1 4 9 16 25)
```

### Embedding

```sh
qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)'
```

```lisp
;; Evaluate expressions
(ece:evaluate '(+ 1 2))               ;; => 3
(ece:evaluate '(map (lambda (x) (* x x)) (list 1 2 3)))  ;; => (1 4 9)

;; Load ECE source files
(ece:evaluate '(load "my-program.scm"))
```

### Testing

```sh
make test
```

### Rebuilding Bootstrap

If you modify the ECE source files (`src/*.scm`), rebuild the bootstrap `.ecec` files:

```sh
make bootstrap
```

This boots from the existing `.ecec` files, recompiles all sources, and replaces the bootstrap files.
