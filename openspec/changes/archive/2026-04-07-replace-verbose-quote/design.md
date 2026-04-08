## Context

The ECE prelude and test files contain `(quote ...)` in places where `'` is the standard Scheme shorthand. The issue was filed as #106 with a pointer to `prelude.scm`. An audit found 10 safe-to-replace instances across 2 files, plus 11 intentionally explicit instances that should stay.

## Goals / Non-Goals

**Goals:**
- Replace `(quote ...)` with `'` where it's a straightforward literal quote
- Preserve exact runtime behavior

**Non-Goals:**
- Changing `(quote ...)` inside quasiquote templates, `(list 'quote ...)` calls, or syntax-rules templates — explicit form aids readability in those contexts
- Any algorithmic or structural changes to the affected functions

## Decisions

### 1. Replace only unambiguous literal uses

`(quote ())` as a standalone expression or argument is always safe to shorten to `'()`. Similarly `(quote else)` → `'else`. These are textbook shorthand cases.

### 2. Keep explicit form in code-generation contexts

Inside quasiquote templates (e.g., `` `(equal? ,k (quote ,d)) ``), the explicit `(quote ...)` makes the generated code structure clearer. Same for `(list 'quote ...)` in reader.scm and `(quote x)` in syntax-rules templates. These are intentional and conventional.

## Risks / Trade-offs

- **Risk**: Misidentifying a code-generation use as a simple literal.
  → **Mitigation**: Each instance was individually audited. The 10 replacements are all in straightforward value positions (function arguments, return values, comparisons).
