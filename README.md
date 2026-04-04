# ECE

[![Tests](https://github.com/anthonyf/ece/actions/workflows/test.yml/badge.svg)](https://github.com/anthonyf/ece/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/anthonyf/ece/blob/main/LICENSE)

**Try it:** [Sandbox & REPL](https://anthonyf.github.io/ece/sandbox/) | [Test Suite](https://anthonyf.github.io/ece/tests/)

A Scheme-like language with two runtimes: Common Lisp and WebAssembly. Inspired by SICP Section 5.5, ECE compiles expressions to register machine instructions and executes them with an explicit stack — no reliance on the host language's call stack.

## Key Features

- **Dual runtime** — runs on Common Lisp (desktop) and WebAssembly (browser), sharing the same compiler, reader, and standard library
- **Full tail call optimization** — all tail positions (if, begin, cond, let, let*, when, unless, and, or, case, do) run in constant stack space
- **First-class continuations** — `call/cc` captures the full continuation stack; `yield` enables cooperative multitasking for game loops and animations
- **Hygienic-ish macros** — `define-macro` with quasiquote, unquote, and unquote-splicing
- **Record system** — `define-record` generates constructors, predicates, accessors, mutators, and copy functions
- **Hash tables** — with `{}` literal syntax and functional update via `hash-set`
- **Canvas 2D drawing** — `canvas-clear`, `canvas-fill-rect`, `canvas-fill-circle`, `canvas-draw-text` (WASM/browser)
- **Self-hosting** — compiler, reader, assembler, and standard library are all written in ECE
- **Per-file compiled boot** — bootstraps from `.ececb` files (pre-compiled binary instruction units), not a monolithic image

## Architecture

ECE has two runtimes that execute the same register machine instruction set. The compiler, reader, assembler, and standard library are written in ECE itself and shared between both runtimes via pre-compiled `.ececb` bootstrap files.

### CL Runtime

The Common Lisp runtime (~2,100 lines) provides the register machine executor, environment, and primitives. It's the development host — used for compiling ECE source, running tests, and bootstrapping.

### WASM Runtime

The WebAssembly runtime (~4,500 lines of hand-written WAT) uses WasmGC for memory management. It runs in the browser with a thin JS glue layer for I/O, canvas, and file storage (localStorage). The self-hosted compiler works on WASM, enabling runtime compilation in the browser REPL.

### Shared ECE Modules

| Module | Role |
|--------|------|
| `src/prelude.scm` | Standard library, macros, hash tables, parameters, error handling, dynamic-wind |
| `src/compiler.scm` | SICP 5.5 compiler with lexical addressing |
| `src/reader.scm` | S-expression reader with string interpolation |
| `src/assembler.scm` | Instruction assembler, `load` function |
| `src/compilation-unit.scm` | `compile-file`, multi-unit compilation |

## Language Overview

### Core Forms

`lambda`, `if`, `begin`, `define`, `set!`, `quote`, `call/cc`, `define-macro`, `apply`

### Derived Forms (via macros)

`let`, `let*`, `letrec`, `cond`, `case`, `when`, `unless`, `and`, `or`, `do`, `loop`, `collect`, `assert`, `parameterize`, `guard`

### Data Types

Numbers (integer, float), strings, characters, booleans (`#t`/`#f`), symbols, pairs/lists, vectors, hash tables, records, continuations, parameters, ports

### Standard Library

`map`, `filter`, `reduce`, `for-each`, `any`, `every`, `range`, `reverse`, `assoc`, `member`, `list-ref`, `list-tail`, `append`, `apply`, `compose`, `identity`, `fmt`, `lines`, `random`, `define-record`, `dynamic-wind`, `with-exception-handler`, `guard`

### I/O

`display`, `print`, `newline`, `read`, `read-line`, `read-char`, `peek-char`, `write-char`, `load`, `write-to-string`, `open-input-file`, `open-output-file`, `open-input-string`, `current-input-port`, `current-output-port`

### Strings & Characters

`string-append`, `substring`, `string-length`, `string-ref`, `string-split`, `string-join`, `string-contains?`, `string-upcase`, `string-downcase`, `string-trim`, `string->number`, `number->string`, `string->symbol`, `symbol->string`, `string=?`, `string<?`, `string>?`, `char?`, `char=?`, `char<?`, `char-whitespace?`, `char-alphabetic?`, `char-numeric?`, `char->integer`, `integer->char`

String interpolation is supported at the reader level: `"Hello $name, you are $(+ age 1) years old"`. Use `$$` for a literal `$`.

### Vectors

`vector`, `make-vector`, `vector-ref`, `vector-set!`, `vector-length`, `vector->list`, `list->vector`

### Hash Tables

`hash-table`, `hash-ref`, `hash-set!`, `hash-set`, `hash-remove!`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-table?`

Literal syntax: `{name "Alice" age 30}`

### Parameters (R7RS)

`make-parameter`, `parameterize`

### Bitwise Operations

`bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`

### Canvas (WASM/browser)

`canvas-clear`, `canvas-set-fill-color`, `canvas-fill-rect`, `canvas-fill-circle`, `canvas-draw-text`, `canvas-width`, `canvas-height`

## Continuations and Cooperative Multitasking

ECE's first-class continuations support save/restore, cooperative multitasking, and complex control flow.

### yield

The `yield` function pauses execution and returns control to the browser. On the next animation frame, execution resumes where it left off:

```scheme
(define (game-loop)
  (canvas-clear)
  (canvas-set-fill-color 50 200 100)
  (canvas-fill-circle x y 15)
  (yield)         ;; pause until next frame
  (game-loop))
```

### Serializable Continuations

Continuations can be saved to disk and restored later with `save-continuation!` / `load-continuation`. This enables save/restore for games and persistent workflows.

```scheme
(define (run-game)
  (define room (make-parameter "kitchen"))
  (define hp (make-parameter 100))

  ;; Save: captures room, hp automatically
  (save-continuation! "save.dat"
    (call/cc (lambda (k) k)))

  (display (room))
  (newline))

;; Later: restore
(define k (load-continuation "save.dat"))
(k 'resume)  ;; resumes inside run-game
```

**Why lexical scope works for saves:** `call/cc` captures the lexical environment — everything defined inside the function. Parameters and closures are included. Global bindings (compiler, reader, prelude) are always available after boot and don't need to be serialized.

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

Or try the [browser REPL](https://anthonyf.github.io/ece/sandbox/) — no install needed.

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
make test       # CL + ECE self-hosted tests
make test-wasm  # WASM tests (requires binaryen + Node.js)
```

### Building a Web App

Use `ece-build` to compile ECE source files into a self-contained web app that runs in the browser:

```sh
bin/ece-build --target web -o dist/ my-app.scm
```

This produces a `dist/` directory with everything needed to run:

```
dist/
  index.html          # page with canvas + text output
  ece-runtime.js      # WASM runtime and JS glue
  ece-bootstrap.js    # standard library, compiler, reader, assembler
  app.js              # your compiled application
```

Open `dist/index.html` in a browser — no server required (works from `file://`).

Multiple source files are compiled in order, so earlier files can define macros and functions used by later ones:

```sh
bin/ece-build --target web -o dist/ lib/utils.scm lib/drawing.scm main.scm
```

To use your own HTML instead of the generated `index.html`, load the three JS files and boot the runtime:

```html
<script src="ece-runtime.js"></script>
<script src="ece-bootstrap.js"></script>
<script src="app.js"></script>

<script>
  (async function() {
    // Instantiate WASM
    const wasmBytes = Uint8Array.from(atob(ECE_WASM_BASE64), c => c.charCodeAt(0));
    const imports = {
      io: ECE.io, loader: ECE.loader, storage: ECE.storage,
      canvas: ECE.canvas, timing: ECE.timing, math: ECE.math, ffi: ECE.ffi
    };
    const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
    ECE.wasm = instance.exports;
    ECE.buildGlobalEnv();

    // Boot standard library
    for (const name of ["prelude", "compiler", "reader", "assembler", "compilation-unit", "browser-lib"]) {
      if (ECE_BOOTSTRAP[name]) {
        const spaceId = ECE.loadEcecText(atob(ECE_BOOTSTRAP[name]));
        ECE.wasm.run(spaceId, 0, ECE.globalEnvHandle);
      }
    }
    ECE.wasm.mark_handles();

    // Run your app
    ECE.loadEcecBundleText(atob(ECE_APP_BUNDLE));
  })();
</script>
```

You can customize I/O by overriding `ECE.io.display_string`, `ECE.io.display_number`, and `ECE.io.newline` before booting. The default template writes to a `<canvas>` and `<pre>` element — see `templates/web/index.html` for the full example.

**Prerequisites:** SBCL, qlot, binaryen (`wasm-as`), and a built WASM runtime (`make wasm`).

### Building the WASM Sandbox

```sh
make sandbox    # builds sandbox/ with embedded WASM + bootstrap
make site       # builds full site with sandbox + test runner
```

### Rebuilding Bootstrap

If you modify the ECE source files (`src/*.scm`), rebuild the bootstrap `.ecec` files:

```sh
make bootstrap
```

This boots from the existing `.ecec` files, recompiles all sources, and replaces the bootstrap files.
