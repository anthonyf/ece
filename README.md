# ECE

[![Tests](https://github.com/anthonyf/ece/actions/workflows/test.yml/badge.svg)](https://github.com/anthonyf/ece/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/anthonyf/ece/blob/main/LICENSE)

**Try it:** [Sandbox & REPL](https://anthonyf.github.io/ece/sandbox/) | [Test Suite](https://anthonyf.github.io/ece/tests/)

A Scheme-like language with two runtimes: Common Lisp and WebAssembly. Inspired by SICP Section 5.5, ECE compiles expressions to register machine instructions and executes them with an explicit stack — no reliance on the host language's call stack.

## Key Features

- **Dual runtime** — runs on Common Lisp (desktop) and WebAssembly (browser), sharing the same compiler, reader, and standard library
- **Full tail call optimization** — all tail positions (if, begin, cond, let, let*, when, unless, and, or, case, do) run in constant stack space
- **First-class continuations** — `call/cc` captures the full continuation stack; `yield` enables cooperative multitasking for game loops and animations
- **Two macro systems** — `define-macro` (CL-style unhygienic with quasiquote) and `define-syntax` / `syntax-rules` (R7RS hygienic pattern-matching)
- **Record system** — `define-record` generates constructors, predicates, accessors, mutators, and copy functions
- **Hash tables** — with `{}` literal syntax and functional update via `hash-set`
- **Canvas 2D drawing** — `canvas-clear`, `canvas-fill-rect`, `canvas-fill-circle`, `canvas-draw-text` (WASM/browser)
- **Self-hosting** — compiler, reader, assembler, and standard library are all written in ECE
- **Single-bundle bootstrap** — bootstraps from `.ecec` files (pre-compiled instruction units), not a monolithic image

## Architecture

ECE has two runtimes that execute the same register machine instruction set. The compiler, reader, assembler, and standard library are written in ECE itself and shared between both runtimes via pre-compiled `.ecec` bootstrap files.

### CL Runtime

The Common Lisp runtime (~2,300 lines) provides the register machine executor, environment, and primitives. It's the development host — used for compiling ECE source, running tests, and bootstrapping.

### WASM Runtime

The WebAssembly runtime (~6,500 lines of hand-written WAT) uses WasmGC for memory management. It runs in the browser with a thin JS glue layer for I/O, canvas, and file storage (localStorage). The self-hosted compiler works on WASM, enabling runtime compilation in the browser REPL.

### What Makes ECE Different

ECE compiles to a register machine with an explicit stack — it never uses the host language's call stack. This single architectural choice enables several features that are difficult or impossible in hosted Scheme implementations:

**First-class continuations.** Because the entire machine state (stack, environment, program counter) lives in ECE-managed data structures, `call/cc` captures a complete snapshot of the computation. There's no need to copy host stack frames or use platform-specific tricks — the continuation is just an ECE value.

**Full tail call optimization.** All tail positions — including `if`, `begin`, `cond`, `let`, `let*`, `when`, `unless`, `and`, `or`, `case`, and `do` — execute in constant stack space. The explicit stack means TCO is a property of the instruction set, not a compiler optimization that the host may or may not support.

**Serializable continuations.** Since the machine state is ECE data structures (not opaque host stack frames), continuations can be serialized to disk and restored later. This enables save/restore for games, persistent workflows, and checkpointing long-running computations.

**Dual runtime, small kernel.** The same `.ecec` bootstrap files run unmodified on both the CL and WASM runtimes. The CL kernel is ~2,300 lines; everything else — compiler, reader, assembler, standard library — is written in ECE. Porting ECE to a new host means reimplementing only the kernel.

### Shared ECE Modules

| Module | Role |
|--------|------|
| `src/prelude.scm` | Standard library, macros, hash tables, parameters, error handling, dynamic-wind |
| `src/compiler.scm` | SICP 5.5 compiler with lexical addressing |
| `src/reader.scm` | S-expression reader with string interpolation |
| `src/assembler.scm` | Instruction assembler, `load` function |
| `src/compilation-unit.scm` | `compile-file`, multi-unit compilation |
| `src/syntax-rules.scm` | R7RS `define-syntax` / `syntax-rules` hygienic pattern-matching macros |
| `src/browser-lib.scm` | Browser DOM access, event handling, and CSS helpers (WASM/browser) |

## Language Overview

### Core Forms

`lambda`, `if`, `begin`, `define`, `set!`, `quote`, `call/cc`, `define-macro`, `define-syntax`, `apply`

### Derived Forms (via macros)

`let`, `let*`, `letrec`, `cond`, `case`, `when`, `unless`, `and`, `or`, `do`, `loop`, `collect`, `assert`, `parameterize`, `guard`

### Data Types

Numbers (integer, float), strings, characters, booleans (`#t`/`#f`), symbols, pairs/lists, vectors, hash tables, records, continuations, parameters, ports

### Standard Library

`map`, `filter`, `reduce`, `for-each`, `any`, `every`, `range`, `reverse`, `assoc`, `member`, `list-ref`, `list-tail`, `append`, `apply`, `compose`, `identity`, `random`, `define-record`, `dynamic-wind`, `with-exception-handler`, `guard`

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

Continuations can be saved to disk and restored later with `save-continuation!` / `load-saved`. This enables save/restore for games and persistent workflows.

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
(define k (load-saved "save.dat"))
(k 'resume)  ;; resumes inside run-game
```

**Why lexical scope works for saves:** `call/cc` captures the lexical environment — everything defined inside the function. Parameters and closures are included. Global bindings (compiler, reader, prelude) are always available after boot and don't need to be serialized.

## Use Cases

ECE's first-class continuations make it well-suited for applications that need complex control flow — such as interactive fiction engines, where save/restore and goto/gosub map naturally to `call/cc`.

[Dunge](https://github.com/anthonyf/dunge) is a choice-based interactive fiction game being built with ECE.

## Getting Started

### Install ECE

**Prerequisites (build-time only):**
- [SBCL](http://www.sbcl.org/)
- [qlot](https://github.com/fukamachi/qlot)
- [binaryen](https://github.com/WebAssembly/binaryen) (`wasm-as`) — for WASM builds

Once installed, `ece` runs without SBCL, qlot, or any other runtime dependency.

```sh
git clone https://github.com/anthonyf/ece.git
cd ece
qlot install     # fetches CL dependencies
make             # builds bin/ece + staged share/ece/ tree
make install     # installs to /usr/local
```

Install to a user-local prefix:

```sh
make install PREFIX=$HOME/.local
export PATH=$HOME/.local/bin:$PATH
```

Uninstall with `make uninstall` (same `PREFIX`).

The install lays out a relocatable SDK tree:

```
$PREFIX/bin/
  ece               # ~64MB native SBCL image
  ece-repl          # symlink → ece  (argv[0] = REPL entry point)
  ece-build         # symlink → ece  (argv[0] = build tool)
  ece-test          # symlink → ece  (argv[0] = test runner)
$PREFIX/share/ece/
  bootstrap.ecec    # core language + compiler
  ece-main.ecec     # tool dispatcher + ece-build/test logic
  runtime.wasm      # WASM runtime (for --target web)
  glue.js
  primitives.json
  templates/
    web/            # standalone.html + index.html
    cl/             # run.sh template
```

### Using the `ece` binary

```sh
ece                                  # drop into REPL
ece -V                               # print version
ece -e "(display (+ 1 2))"           # evaluate expression → 3
ece main.scm                         # load and run a script
ece --load lib.scm -e "(lib-fn 42)"  # chain loads and evals
ece app.ecec                         # run a compiled bundle
ece --module '(app main)' --entry main app.ecec  # run a module export
ece -i main.scm                      # run script, then drop into REPL
ece main.scm -- arg1 arg2            # pass args via (command-line)
```

**CLI reference:**

```
ece [OPTIONS] [FILE...]

Options:
  --load FILE           Load and execute FILE (.scm or .ecec)
  -e EXPR, --eval EXPR  Read and evaluate EXPR
  --module MODULE       Select module entry point, e.g. '(app main)'
  --entry SYMBOL        Run exported procedure from --module
  -i, --interactive     Enter REPL after processing files
  --                    Stop option parsing; pass rest via (command-line)
  -h, --help            Show help and exit
  -V, --version         Show version and exit
```

Positional FILE args, `--load`, and `--eval` steps execute in the order they appear. With no work (no files, no `-e`), `ece` drops into the REPL.

**argv[0] dispatch.** All four tools are the same binary; the tool is selected by `basename(argv[0])`:

| Name | Behavior |
|------|----------|
| `ece` | Run files/exprs, drop into REPL if no work (shown above) |
| `ece-repl` | Always enter REPL, even after loading files |
| `ece-build` | Compile and package a project (see [Build your own apps](#build-your-own-apps)) |
| `ece-test` | Discover and run `test-*.scm` files (see [Testing your code](#testing-your-code)) |

Unrecognized names (e.g. adding your own symlink) fall through to `ece` behavior.

**Accessing process state from ECE code:**

```scheme
(command-line)                  ;; => ("ece" "main.scm" "--" "arg1")
(get-environment-variable "HOME") ;; => "/Users/you"  (or #f)
(exit 3)                        ;; terminate with code 3
```

### REPL

```sh
ece
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

## Build your own apps

The `ece-build` tool compiles one or more `.scm` source files into a deployable bundle for a chosen target.

```
ece-build --target web|cl -o <dir> [--standalone] <source.scm> ...
```

Source files are compiled in dependency order, so earlier files can define macros and functions used by later ones.

### Web target

The default **server mode** produces raw files for HTTP serving:

```sh
ece-build --target web -o dist/ main.scm
```

```
dist/
  index.html          # uses fetch() + WebAssembly.instantiateStreaming()
  ece-runtime.js      # JS glue (no embedded WASM)
  runtime.wasm        # WASM binary
  bootstrap.ecec      # standard library
  app.ecec            # your compiled application
```

Serve it over HTTP:

```sh
python3 -m http.server -d dist/ 8000
# Open http://localhost:8000
```

**Standalone mode** (`--standalone`) base64-encodes every asset into JS files so the app opens from `file://` with no server:

```sh
ece-build --target web --standalone -o dist/ main.scm
# Open dist/index.html directly in a browser
```

```
dist/
  index.html          # self-contained
  ece-runtime.js      # WASM runtime + JS glue (base64-encoded WASM)
  ece-bootstrap.js    # standard library (base64-encoded)
  app.js              # your app (base64-encoded)
```

Customize I/O by overriding `ECE.io.display_string`, `ECE.io.display_number`, and `ECE.io.newline` before booting. See `$PREFIX/share/ece/templates/web/` for reference.

### Live browser development from Emacs

`ece-serve` serves a web build, watches the source files, and accepts dev
commands from an editor. From Emacs, load `emacs/geiser-ece.el`, open your app
entry file, then run the one-command startup:

```elisp
M-x geiser-ece-dev-jack-in
```

That treats the current `.scm` buffer as the app entry file, starts `ece-serve`,
opens the served page, and opens an `ece-dev>` REPL that evaluates in the
browser runtime.

You can also start the pieces separately:

```elisp
M-x geiser-ece-dev-mode
M-x geiser-ece-dev-start
```

`geiser-ece-dev-start` starts `ece-serve`, parses the printed URL and dev token,
and configures the Emacs dev commands. Open the browser with:

```elisp
M-x geiser-ece-dev-open-browser
```

For a Figwheel-style workflow that starts the server, opens the browser, and
opens a REPL buffer that evaluates in the browser runtime, use:

```elisp
M-x geiser-ece-dev-start-repl
```

Create a minimal app-local web skeleton:

```sh
ece init web test-game
cd test-game
ece-serve main.scm --port 8080
```

The generated `index.html` is intentionally small: it contains the runtime boot
script, an `#app-root` node, and an `#output` log node. The generated
`main.scm` is an `(app main)` module that imports the browser DOM/HTML modules,
renders the app shell from ECE code, exports `start` and `tick`, and calls
`start` when the bundle loads.

The browser sandbox demos follow the same direction: canvas demos are ordinary
ECE modules that import `(ece browser canvas)`, export `start`, and auto-start
when loaded.

Open the served page in a browser, then use `M-x geiser-ece-dev-connect-repl`.
Press RET for the default `127.0.0.1:8080`, or enter another `host:port` / URL.
Emacs asks `ece-serve` for local session metadata, then reads the protected
session file for the token so you do not need to paste it. The REPL prompt is
`ece-dev>` and each form is evaluated in the connected browser runtime.

You can also run `M-x geiser-ece-dev-connect` when you only want the editor
commands without opening the REPL. In
`geiser-ece-dev-mode`, the `C-c C-z` prefix sends code to the running browser:

| Key | Command |
| --- | --- |
| `C-c C-z S` | Start `ece-serve` for an entry file and capture URL/token |
| `C-c C-z R` | Start `ece-serve`, open the browser, and open the browser REPL |
| `C-c C-z J` | Start `ece-serve` from the current file, open browser, open REPL |
| `C-c C-z K` | Stop the managed `ece-serve` process |
| `C-c C-z a` | Attach to an existing `ece-serve` session file |
| `C-c C-z c` | Connect to `ece-serve` by host and port |
| `C-c C-z C` | Connect to `ece-serve` by host and port, then open the browser REPL |
| `C-c C-z o` | Open the configured browser URL |
| `C-c C-z ?` | Show the configured URL and token status |
| `C-c C-z z` | Open the browser REPL for the current dev connection |
| `C-c C-z e` | Evaluate the expression before point in the browser |
| `C-c C-z d` | Evaluate the current definition in the browser |
| `C-c C-z r` | Evaluate the active region in the browser |
| `C-c C-z b` | Evaluate the whole buffer in the browser |
| `C-c C-z l` | Send the current file contents to the browser |
| `C-c C-z k` | Save and force an entry rebuild/reload through `ece-serve` |
| `C-c C-z s` | Save the file; the `ece-serve` watcher rebuilds and reloads |

Snippet evals return the browser result or error to Emacs. Saving a source file
uses the normal watcher path, so the browser reloads the rebuilt `.ecec` bundle
and native WASM zone artifacts when they change.

While `geiser-ece-dev-mode` is active, common Geiser commands are remapped to
the browser-dev loop. `C-x C-e`, `C-c C-r`, and `C-c C-b` evaluate in the
browser; `C-c C-k` / `geiser-compile-current-buffer` and
`geiser-load-current-buffer` save and force an `ece-serve` entry rebuild/reload.

### CL target

Produces a tiny bundle that runs via the installed `ece` binary:

```sh
ece-build --target cl -o dist/ main.scm
```

```
dist/
  app.ecec            # compiled bundle
  run                 # shell wrapper: exec ece app.ecec
```

```sh
./dist/run             # requires `ece` in $PATH
./dist/run foo bar     # args are visible to main.scm via (command-line)
```

For a module bundle, ask the wrapper to invoke an exported procedure:

```sh
ece-build --target cl -o dist/ --module '(app main)' --entry main app/main.scm
./dist/run
```

The selected export must be a procedure. The build still writes `app.ecec`; the
generated `run` script invokes `ece --module ... --entry ... app.ecec`.

### Multi-file builds

List sources in dependency order:

```sh
ece-build --target web -o dist/ lib/utils.scm lib/drawing.scm main.scm
```

## Testing your code

The `ece-test` tool discovers `test-*.scm` files, loads each one in a fresh environment, and reports pass/fail.

Write a test file:

```scheme
;; tests/test-math.scm
(test "addition" (lambda () (assert-equal (+ 1 2) 3)))
(test "multiplication" (lambda () (assert-equal (* 4 5) 20)))
(test "error handling" (lambda () (assert-error (/ 1 0))))
```

Run your test suite:

```sh
ece-test tests/
# tests/test-math.scm: 3 collected, 3 ran, 3 passed, 0 failed
# Total: 3 collected, 3 ran, 3 passed, 0 failed
```

Options:
- `ece-test file.scm` — run exactly this file (no discovery)
- `ece-test tests/ integration/` — discover across multiple directories
- `ece-test -v tests/` — verbose: print per-test output even on success
- `ece-test --filter PATTERN tests/` — run only tests whose name contains PATTERN (substring, case-sensitive; repeatable with OR semantics)

**Exit codes:** `0` if all pass, `1` if any fail, `2` on runner error (bad path, zero tests collected, etc.).

**Assertion API** (in `ece-unit.scm`, auto-loaded):

| Form | Checks |
|------|--------|
| `(assert-equal actual expected)` | `equal?` equality |
| `(assert-true x)` | x is truthy |
| `(assert-false x)` | x is `#f` |
| `(assert-error expr)` | expr raises |
| `(assert-error-message expr msg)` | expr raises with specific message |

Per-test output is captured; captured output is printed only for failing tests (or always under `-v`).

## For contributors

### Embedding ECE in a Common Lisp program

```sh
qlot exec sbcl --load ece.asd --eval '(asdf:load-system :ece)'
```

```lisp
(ece:evaluate '(+ 1 2))               ;; => 3
(ece:evaluate '(map (lambda (x) (* x x)) (list 1 2 3)))  ;; => (1 4 9)
(ece:evaluate '(load "my-program.scm"))
```

### Running ECE's own tests

```sh
make test              # full suite: rove, ECE self-hosted, WASM, conformance, golden
make test-rove         # CL-side rove tests (inc. integration tests for bin/ece)
make test-ece          # ECE self-hosted tests (via bin/ece-test)
make test-wasm         # WASM runtime tests (requires node)
make test-conformance  # R5RS/R7RS conformance suite
make test-golden       # compiler output regression tests
```

ECE's own tests live in `tests/ece/`, split by runtime eligibility:
- `tests/ece/common/` — pure-ECE tests (run on CL and WASM)
- `tests/ece/cl-only/` — tests requiring CL-specific primitives (compilation units, serialization, source locations, SDK integration)

`make test-ece` runs `bin/ece-test tests/ece/common tests/ece/cl-only`. For a single file: `bin/ece-test tests/ece/common/test-strings.scm`. For a subset: `bin/ece-test --filter string tests/ece/common`.

### Building the WASM Sandbox

```sh
make sandbox    # builds sandbox/ with embedded WASM + bootstrap
make site       # builds full site with sandbox + test runner
```

### Rebuilding Bootstrap

If you modify the ECE source files (`src/*.scm`), rebuild the bootstrap bundle:

```sh
make bootstrap
```

This boots from the existing `bootstrap/bootstrap.ecec`, recompiles all sources via `compile-system`, and regenerates the single bootstrap bundle.
