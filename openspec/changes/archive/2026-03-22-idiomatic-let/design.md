## Context

ECE's source files use three patterns for local definitions. Two of them have cleaner idiomatic equivalents:

```
Pattern A: Named helper loop              →  Named let
─────────────────────────────────         ─────────────
(begin                                    (let iter ((rest lst) (acc '()))
  (define (iter rest acc)                   (if (null? rest) acc
    (if (null? rest) acc                        (iter (cdr rest)
        (iter (cdr rest) (cons ...))))                (cons (car rest) acc))))
  (iter lst '()))

Pattern B: Scattered local binding        →  let / let*
─────────────────────────────────         ─────────────
(define port (open-input-file f))         (let* ((port (open-input-file f))
(define prev (%current-space-id))                (prev (%current-space-id))
(define new (%create-space name))                (new (%create-space name)))
...                                         ...)

Pattern C: Multi-function block           →  Leave as-is
─────────────────────────────────
(define (shared-tail a b) ...)            Acceptable R7RS style.
(define common (shared-tail from to))     letrec alternative is
(define (unwind ws) ...)                  arguably less readable.
(define (rewind ws) ...)
```

## Goals / Non-Goals

**Goals:**
- Convert Pattern A (named helper loops) to named `let` in all post-prelude code
- Convert Pattern B (scattered local bindings) to `let`/`let*`
- Preserve behavior exactly — tests must pass unchanged

**Non-Goals:**
- Touching early prelude (lines 1-172, before `let` macro is defined)
- Converting Pattern C (multi-function blocks in serialize-value, do-winds!, etc.)
- Changing macro bodies (define-record, case, do, guard) — these are template code
- Adding any new functionality

## Decisions

### 1. Use `let*` for sequential bindings, `let` for independent ones

When multiple local bindings appear in sequence and later ones depend on earlier ones, use `let*`. When they're independent, use `let`. When in doubt, prefer `let*` — it's always correct and clearer about evaluation order.

### 2. Process files from least to most complex

Start with assembler.scm (6 changes) and ecec-to-binary.scm (3 changes) to build confidence, then compiler.scm, compilation-unit.scm, and finally prelude.scm which has the most changes.

### 3. Run tests after each file

Since this is purely mechanical, the risk is low. But running `make test` after each file catches any mistakes immediately.

### 4. Skip macro template bodies

Macro definitions like `define-record`, `case`, `do`, and `guard` contain `define` in their expansion templates. These are not "internal defines in the current scope" — they're code being generated. Leave them unchanged.

## Risks / Trade-offs

- **Incorrect scoping**: A `define` at the top of a `begin` is scoped to the entire `begin` body. Converting to `let` scopes it only within the `let` body. If code after the `let` references the binding, it will break. → Mitigation: test suite catches this.
- **`set!` on `define`d variables**: If a local `define` variable is mutated with `set!`, converting to `let` is still valid (let bindings are mutable in Scheme). No issue.
- **Named let recursion**: Named `let` compiles to `define` + call internally (that's how ECE's `let` macro works). So the compiled output is equivalent. No performance change.
