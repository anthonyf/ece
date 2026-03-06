# ECE

An **Explicit Control Evaluator** for a small Lisp, written in Common Lisp. Inspired by the register machine evaluator from SICP, ECE uses an explicit continuation stack rather than relying on the host language's call stack.

## Supported Language Features

- **Self-evaluating expressions**: numbers, strings
- **Variables**: symbol lookup in the environment
- **`quote`**: `(quote expr)` returns `expr` unevaluated
- **`lambda`**: `(lambda (params...) body...)` with lexical scoping and multi-body support
- **`if`**: `(if predicate consequent alternative?)` with optional alternative
- **`begin`**: `(begin expr...)` evaluates sequentially, returns last value
- **`call/cc`**: `(call/cc receiver)` captures the current continuation
- **Primitives**: `+`, `-`, `*`, `/`, `=`, `<`, `>`, `<=`, `>=`, `car`, `cdr`, `cons`, `list`, `null?`, `not`

## Prerequisites

- [SBCL](http://www.sbcl.org/)
- [qlot](https://github.com/fukamachi/qlot)

## Setup

```sh
qlot install
```

## Usage

```sh
qlot exec sbcl --load ece.asd --eval '(ql:quickload :ece)'
```

Then in the SBCL REPL:

```lisp
(ece:evaluate '(+ 1 2))
;; => 3

(ece:evaluate '((lambda (x) (* x x)) 5))
;; => 25

(ece:evaluate '(if (< 1 2) 10 20))
;; => 10

(ece:evaluate '(begin 1 2 3))
;; => 3

(ece:evaluate '(+ 1 (call/cc (lambda (k) (k 10)))))
;; => 11
```

## Testing

```sh
qlot exec sbcl --eval '(asdf:test-system :ece)' --quit
```
