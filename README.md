# ECE

[![Tests](https://github.com/anthonyf/ece/actions/workflows/test.yml/badge.svg)](https://github.com/anthonyf/ece/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/anthonyf/ece/blob/main/LICENSE)

A Scheme-like language implemented as an **Explicit Control Evaluator** in Common Lisp. Inspired by the register machine evaluator from SICP, ECE uses an explicit continuation stack rather than relying on the host language's call stack. Zero external dependencies.

## Key Features

- **Full tail call optimization** — all tail positions (if, begin, cond, let, let*, when, unless, and, or, case, do) run in constant stack space
- **First-class continuations** — `call/cc` captures the full continuation stack
- **Serializable continuations** — save and restore program state to disk with `save-continuation!` / `load-continuation`
- **Hygienic-ish macros** — `define-macro` with quasiquote, unquote, and unquote-splicing
- **Record system** — `define-record` generates constructors, predicates, accessors, mutators, and copy functions
- **Hash tables** — with `{}` literal syntax and functional update via `hash-set`
- **Prelude** — standard library written in ECE itself (`src/prelude.scm`)

## Language Overview

### Core Forms

`lambda`, `if`, `begin`, `define`, `set`, `quote`, `call/cc`, `define-macro`

### Derived Forms (via macros)

`let`, `let*`, `letrec`, `cond`, `case`, `when`, `unless`, `and`, `or`, `do`, `assert`

### Data Types

Numbers, strings, characters, booleans (`#t`/`#f`), symbols, pairs/lists, vectors, hash tables, records, continuations

### Standard Library

`map`, `filter`, `reduce`, `for-each`, `any`, `every`, `range`, `reverse`, `assoc`, `member`, `list-ref`, `list-tail`, `append`, `apply`, `compose`, `identity`, `fmt`, `print-text`, `random`, `define-record`

### I/O

`display`, `print`, `newline`, `read`, `read-line`, `load`, `write-to-string`

### Strings & Characters

`string-append`, `substring`, `string-length`, `string-ref`, `string-split`, `string-upcase`, `string-downcase`, `string->number`, `number->string`, `string->symbol`, `symbol->string`, `string=?`, `string<?`, `string>?`, `char?`, `char=?`, `char<?`, `char->integer`, `integer->char`

### Vectors

`vector`, `make-vector`, `vector-ref`, `vector-set!`, `vector-length`, `vector->list`, `list->vector`

### Hash Tables

`hash-table`, `hash-ref`, `hash-set!`, `hash-set`, `hash-remove!`, `hash-has-key?`, `hash-keys`, `hash-count`, `hash-table?`

### Bitwise Operations

`bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`

## Use Cases

ECE's serializable continuations make it well-suited for applications that need to capture and restore program state — such as interactive fiction engines, where save/restore and complex control flow (goto, gosub) map naturally to `call/cc`.

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
qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)' --eval '(ece:repl)'
```

```
ece> (define (factorial n) (if (= n 0) 1 (* n (factorial (- n 1)))))
ece> (factorial 5)
120
ece> (define-record point x y)
ece> (point-x (make-point 10 20))
10
ece> (define k (call/cc (lambda (cont) cont)))
ece> (save-continuation! "state.ece" k)
#t
ece> (load-continuation "state.ece")
(CONTINUATION ...)
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
qlot exec sbcl --eval '(asdf:test-system :ece)' --quit
```
