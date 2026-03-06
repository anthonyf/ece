## Context

The evaluator uses an explicit continuation-passing style with a continuation stack (`conts`). The `if` special form already has four stubbed continuations: `:ev-if`, `:ev-if-decide`, `:ev-if-consequent`, and `:ev-if-alternative`. The dispatch in `:ev-dispatch` does not yet route to `:ev-if` because there is no `if-p` predicate — `if` is in `*special-forms*` so it's excluded from `application-p`, but nothing catches it, causing an "Unknown expression type" error.

## Goals / Non-Goals

**Goals:**
- Implement `(if predicate consequent alternative)` with standard Lisp truthiness (only `nil` is false)
- Support optional alternative (omitted alternative defaults to `nil`)
- Follow the existing continuation-based pattern used by `begin` and `lambda`

**Non-Goals:**
- `cond` or other conditional forms
- Short-circuit boolean operators (`and`, `or`)

## Decisions

**Add `if-p` predicate and dispatch**: Add an `if-p` function matching the pattern of `begin-p`, `lambda-p`, etc. Add a dispatch clause in `:ev-dispatch` before the `application-p` check (alongside `begin-p`).

**Truthiness**: Follow standard Lisp convention — only `nil` is falsy, everything else (including `0`, `""`, empty list represented as `nil`) is truthy. This matches CL's behavior directly so no special truthiness function is needed.

**Optional alternative**: `(if pred conseq)` with no alternative returns `nil` when predicate is false. Implementation: `(if-alternative expr)` returns `(cadddr expr)`, which is `nil` when absent.

**Continuation flow**: Following the SICP register machine pattern already commented in the stubs:
1. `:ev-if` — save `expr`, `env`, push `:ev-if-decide`, evaluate predicate
2. `:ev-if-decide` — restore `expr`, `env`, check `val` (predicate result), branch to consequent or alternative
3. `:ev-if-consequent` — extract consequent, dispatch to evaluate it
4. `:ev-if-alternative` — extract alternative, dispatch to evaluate it

## Risks / Trade-offs

- [No tail-call optimization for if] → Acceptable for now; TCO would be a separate change
- [nil vs false ambiguity] → Using CL's native truthiness keeps things simple and consistent
