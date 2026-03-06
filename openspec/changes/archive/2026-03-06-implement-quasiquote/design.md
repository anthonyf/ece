## Context

The evaluator now supports `define-macro` for CL-style unhygienic macros. Macro bodies construct output forms using `(list ...)`, `(cons ...)`, and `(quote ...)`, which is verbose and hard to read. Quasiquote is the standard Lisp mechanism for template-based code construction — it dramatically simplifies macro writing.

The challenge: ECE code is read as CL s-expressions. CL's backtick reader macro produces implementation-specific internal forms (e.g., SBCL uses `SB-IMPL::BACKQ-*` functions) that the ECE evaluator doesn't understand. We need our own quasiquote handling at both the reader and evaluator levels.

## Goals / Non-Goals

**Goals:**
- `quasiquote` special form that transforms templates into list-construction expressions and re-dispatches
- `unquote` (`,`) inserts an evaluated value into the template
- `unquote-splicing` (`,@`) splices a list into the template
- Custom readtable for `ece-read` so `` ` ``, `,`, `,@` work in the REPL

**Non-Goals:**
- Nested quasiquote (`` `(a `(b ,,c)) ``) — not needed since nested `define-macro` is not supported
- Rewriting existing standard macros to use quasiquote — they work fine with `list`/`cons` and source-code definitions can't use backtick syntax anyway (CL reader intercepts it)

## Decisions

**Transform-and-redispatch via `qq-expand`**: Rather than adding continuation handlers for quasiquote evaluation, the `ev-quasiquote` handler calls a pure CL function `qq-expand` that walks the template and produces a list-construction expression using `cons`/`append`/`quote`. The result is set as `expr` and re-dispatched. This requires zero new continuation handlers — the existing evaluator machinery handles the construction expression.

The transformation rules:
- `(quasiquote atom)` → `(quote atom)`
- `(quasiquote (unquote expr))` → `expr`
- `(quasiquote (a ... (unquote-splicing expr) ...))` → uses `append` to splice
- `(quasiquote (a b c))` → nested `cons` calls with recursive `qq-expand` on each element

Example: `(quasiquote (if (unquote test) (begin (unquote-splicing body))))` transforms to `(cons (quote if) (cons test (cons (cons (quote begin) body) (quote ()))))`.

**Custom readtable for ECE reading**: Create `*ece-readtable*` by copying CL's readtable and overriding the `` ` `` and `,` reader macros to produce `(quasiquote ...)`, `(unquote ...)`, and `(unquote-splicing ...)` forms using ECE package symbols. Bind `*readtable*` to `*ece-readtable*` inside `ece-read`. This gives REPL users backtick syntax without affecting CL's own reader.

**`unquote`/`unquote-splicing` are not special forms**: These symbols are only meaningful inside a `quasiquote` template — they're recognized by `qq-expand` during template walking, not by the evaluator's dispatch. If used outside quasiquote, they'd be treated as variable lookups (and error with "Unbound variable"), which is the correct behavior.

## Risks / Trade-offs

- [No nested quasiquote] → Acceptable; nested `define-macro` is already a non-goal, so deeply nested quasiquotes aren't needed
- [Backtick only works in REPL, not in CL source `(evaluate '...)` forms] → Users writing ECE source in CL must use explicit `(quasiquote (unquote ...))` or stick with `(list ...)`; this is inherent to CL's reader processing quotes before our code runs
- [`qq-expand` produces potentially deep `cons` chains] → Fine for macro-scale templates; a future optimization could detect all-constant tails and emit `(quote ...)` directly
