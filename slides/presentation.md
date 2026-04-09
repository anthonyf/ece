---
marp: true
theme: default
paginate: true
style: |
  section {
    font-family: 'Menlo', 'Consolas', 'Monaco', monospace;
    background: #000080;
    color: #00ffff;
    font-size: 22px;
  }
  h1 { color: #ffffff; }
  h2 { color: #ffff00; }
  code { background: #000050; color: #00ffff; padding: 2px 6px; }
  pre { background: #000050 !important; color: #00ffff; border: 2px solid #00aaaa; }
  a { color: #ffff00; }
  strong { color: #ffffff; }
  em { color: #ffff00; font-style: normal; }
  table { color: #00ffff; }
  table th { background: #00aaaa; color: #000080; border: 2px solid #00aaaa; }
  table td { background: #000080; color: #00ffff; border: 2px solid #00aaaa; }
  table td strong { color: #ffffff; }
  pre strong, code strong { color: #ffffff; }
  pre em, code em { color: #ffff00; font-style: normal; }
  pre code span.hljs-keyword { color: #ffffff; }
  pre code span.hljs-built_in { color: #ffff00; }
  pre code span.hljs-string { color: #ffff00; }
  pre code span.hljs-comment { color: #00aaaa; }
  pre code span.hljs-number { color: #ffffff; }
  pre code span.hljs-literal { color: #ffffff; }
  pre code span.hljs-symbol { color: #00ffff; }
  pre code span.hljs-name { color: #55ffff; }
  pre code span.hljs-title { color: #55ffff; }
  pre code span.hljs-params { color: #00ffff; }
  li { margin-bottom: 0.3em; }
  section::after { color: #00aaaa; }
---

# How to Evolve a Language

Building a Scheme from scratch — from evaluator to compiler
to self-hosting to WebAssembly

---

# The Goal

I wanted to build **interactive fiction** games that run in the **browser**.

I needed:
- **Save/restore** anywhere in the story (not just at checkpoints)
- **Infinite game loops** without crashing
- A language I could **understand completely** — no black boxes

So I built one.

---

# Why Scheme?

Scheme is a **minimal Lisp** — a tiny core that's surprisingly powerful.

| Feature | Why it matters |
|---|---|
| **call/cc** | Save the entire program state as a value |
| **Tail Call Optimization** | Infinite loops via recursion, no stack overflow |
| **Macros** | Extend the language in the language |
| **SICP** | A textbook that shows you exactly how to build it |

**ECE** = **E**xplicit **C**ontrol **E**valuator (from SICP Chapter 5)

<!-- SICP book image would go here -->

---

# What is Tail Call Optimization?

Most languages **grow the stack** on every function call:

```
 (define (countdown n)              Stack for countdown(5):
   (if (= n 0) "done"               ┌────────────────┐
       (begin                       │ countdown(0)   │
         (countdown (- n 1))        │ countdown(1)   │
         "not tail")))              │ countdown(2)   │
                                    │ countdown(3)   │
   The call is NOT the last thing   │ countdown(4)   │
   — "not tail" comes after it.     │ countdown(5)   │
   Stack grows with every call.     └────────────────┘
                                    Stack overflow at ~10,000
```

---

# What is Tail Call Optimization?

With TCO, if a call is the **last thing** a function does, **reuse the frame**:

```
 (define (countdown n)              Stack (always):
   (if (= n 0) "done"               ┌────────────────┐
       (countdown (- n 1))))        │ countdown(n)   │ ← reused
                                    └────────────────┘
   The call IS the last thing.
   Nothing left to do after it.     Works for n = 1,000,000
   So: jump, don't push.           No stack overflow. Ever.
```

**Recursion becomes as efficient as a `while` loop.**
A game loop that runs forever? Just a tail-recursive function.

---

# What is call/cc?

**call/cc** = call with current continuation

A **continuation** is "everything the program is about to do next."

```
  (+ 1 (call/cc (lambda (k) ...)))
           │
           └── k = "take a value, add 1 to it, and continue
                     with whatever was going to happen after"
```

`call/cc` captures that "what happens next" as a **function you can call**.

Think: **save states in an emulator**, but built into the language.

---

# call/cc in Action

```scheme
(define saved #f)

(define (adventure)
  (display "You enter a dark cave.\n")
  (call/cc (lambda (k)
             (set! saved k)))       ; snapshot!
  (display "A dragon appears!\n")
  (display "You are eaten.\n"))

(adventure)
; You enter a dark cave.
; A dragon appears!
; You are eaten.

(saved #f)                          ; restore!
; A dragon appears!
; You are eaten.
; (resumed mid-function — skipped the cave entrance)
```

---

# Picking a Host Language

I need a language to **build my language in**.

**Common Lisp** is the right choice:

| What I need | What CL gives me for free |
|---|---|
| S-expression reader | `read` — parses Lisp syntax |
| Garbage collector | Decades-mature GC |
| Big numbers | Arbitrary precision built in |
| REPL | Interactive development |
| Fast execution | SBCL compiles to native code |

*"Lisp isn't a language, it's a building material."* — Alan Kay

---

# Stage 1: The Evaluator

```
 ┌──────────┐      ┌──────────────────────────┐      ┌──────────┐
 │          │      │     Evaluator (CL)       │      │          │
 │  .scm    │─────▶│                          │─────▶│  Output  │
 │  source  │      │  eval/apply loop         │      │          │
 │          │      │  CL reader       (free)  │      └──────────┘
 └──────────┘      │  CL GC           (free)  │
                   │  CL bignums      (free)  │
                   └──────────────────────────┘
```

The evaluator walks the source tree directly — no bytecode yet.
It implements SICP's explicit control evaluator: **eval** and **apply**
with an explicit stack instead of host recursion.

---

# Stage 2: Building the Language in Itself

With the evaluator running, I write **prelude.scm** — in ECE itself:

```scheme
;; map — written in ECE, runs on the evaluator
(define (map f lst)
  (if (null? lst) '()
      (cons (f (car lst))
            (map f (cdr lst)))))

;; let — a macro that expands to lambda
(define-macro (let bindings . body)
  `((lambda ,(map car bindings) ,@body)
    ,@(map cadr bindings)))
```

**1,365 lines** of Scheme building up: `let`, `cond`, `map`, `filter`,
`define-macro`, quasiquote, `syntax-rules` ...

The language **grows itself**.

---

# Stage 3: The Compiler

Now the big leap: write a **compiler** — in ECE — that translates
source code to register machine bytecode.

```
 ┌──────────┐     ┌────────────────────┐     ┌───────────────────┐
 │          │     │  Compiler (ECE)    │     │ Register Machine  │
 │  .scm    │────▶│                    │────▶│ (in CL)           │
 │  source  │     │  SICP 5.5          │     │                   │
 │          │     │  752 lines of      │     │ val, env, proc,   │
 └──────────┘     │  Scheme            │     │ argl, continue,   │
                  └────────────────────┘     │ stack             │
                                             └───────────────────┘
```

The compiler is **ECE code**. The register machine (the VM) is in CL.
This is the pivot point — ECE is now compiling *itself*.

---

# Stage 4: The Bootstrap

The evaluator compiles the compiler **once**. After that, it's self-sustaining.

```
 ONE TIME ONLY:
 ════════════════════════════════════════════════════════

 ┌───────────────┐     ┌────────────┐     ┌──────────┐
 │ compiler.scm  │────▶│ Evaluator  │────▶│ .ecec    │
 │ reader.scm    │     │ (CL)       │     │ files    │
 │ prelude.scm   │     └────────────┘     └────┬─────┘
 └───────────────┘                              │
                                                │
 FROM NOW ON:                                   │
 ═══════════════════════════════════════════════╤═══════
                                                │
 ┌───────────────┐     ┌────────────┐     ┌─────▼────┐
 │ compiler.scm  │────▶│ Compiled   │────▶│ .ecec    │
 │ reader.scm    │     │ compiler   │     │ (new)    │
 │ prelude.scm   │     │ (.ecec)    │     └────┬─────┘
 └───────────────┘     └────────────┘          │
                            ▲                  │
                            └──────────────────┘
                             the compiler compiles itself
```

**The evaluator is gone.** The compiler bootstraps itself.

---

# Stage 5: Self-Hosting

Move everything possible from CL into ECE:

```
 BEFORE:                           AFTER:
 ┌────────────────────┐            ┌────────────────────┐
 │    Common Lisp     │            │    Common Lisp     │
 │  ┌──────────────┐  │            │  ┌──────────────┐  │
 │  │ Evaluator    │  │            │  │ Runtime      │  │
 │  │ Compiler     │  │            │  │ ~2,500 lines │  │
 │  │ Reader       │  │   ──────▶  │  └──────────────┘  │
 │  │ Assembler    │  │            │                    │
 │  │ Primitives   │  │            │  Everything else   │
 │  │ Runtime      │  │            │  is ECE:           │
 │  └──────────────┘  │            │  compiler     752  │
 └────────────────────┘            │  reader       414  │
                                   │  assembler     54  │
                                   │  prelude    1,365  │
                                   │  syntax       434  │
                                   │  + more    ~1,800  │
                                   │           ───────  │
                                   │   total    ~4,800  │
                                   └────────────────────┘
```

Also: **hygienic macros** (`syntax-rules`), **error handling**
with stack traces and source locations.

---

# Stage 6: A New Host — WebAssembly

The payoff: supporting a new host is **just the runtime + primitives**.

```
 ┌─────────────────────────────────────────────────────────┐
 │                      ECE (.ecec)                        │
 │   compiler · reader · assembler · prelude · your app    │
 │                    ~4,800 lines                         │
 │                UNCHANGED across hosts                   │
 └────────────────────────────┬────────────────────────────┘
                              │
                   ┌──────────┴──────────┐
                   ▼                     ▼
 ┌───────────────────────┐  ┌───────────────────────┐
 │ CL Runtime            │  │ WASM Runtime          │
 │ 2,476 lines           │  │ 6,749 lines           │
 │                       │  │ (hand-coded WAT)      │
 │ terminal I/O          │  │ DOM + Canvas          │
 │ file system           │  │ browser APIs          │
 └───────────────────────┘  └───────────────────────┘
```

Same compiler. Same bytecode. Same prelude. **Different host.**

---

# Cooperative Multitasking — for Free

How do you run a game loop in the browser without blocking the page?

JavaScript needs `async/await`, callbacks, or generators.
ECE needs **4 lines of Scheme**:

```scheme
(define (yield)
  (call/cc (lambda (k) (%yield! k))))
```

```
 ECE Program              WASM Runtime              Browser
 ───────────              ────────────              ───────

 (game-loop)
   draw frame...
   (yield)          ──▶  save continuation k
                         set yield flag
                         exit VM loop       ──▶  requestAnimationFrame
                                                  ─── browser renders ───
                                                  ─── 16ms pass ────────
                                             ◀──  next frame fires
                         resume k            ◀──
   (game-loop)      ◀──  continues exactly
   draw next frame       where it left off
```

**No callbacks. No promises. No async/await.** Just call/cc.

---

# The Numbers

| | Common Lisp | ECE (Scheme) | WebAssembly |
|---|---|---|---|
| **Runtime** | 2,476 lines | — | 6,749 lines |
| **Compiler** | — | 752 lines | — |
| **Reader** | — | 414 lines | — |
| **Prelude** | — | 1,365 lines | — |
| **Total** | **2,476** | **~4,800** | **6,749** |

The language is **mostly written in itself**.
Two thin runtimes. One set of `.ecec` bytecode files.
339 commits over the course of the project.

---

# Demo Time

1. **CL REPL** — basics, TCO, call/cc
2. **Browser Sandbox** — the same language, running on WASM

---

# What's Next

- Interactive fiction game running in the browser
- Compile-to-host: native WASM codegen (skip the interpreter for hot code)
- Packaging: single-file HTML bundles, no server needed
- Your game is a URL you can text to someone

---

# Questions?

**github.com/anthonyf/ece**

