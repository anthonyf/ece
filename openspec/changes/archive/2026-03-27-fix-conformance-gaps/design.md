## Context

Five conformance test failures remain. Three have clear fixes, one needs investigation, one is deferred.

## Goals / Non-Goals

**Goals:**
- Fix named let init evaluation scope (test 8.1)
- Fix special form shadowing by lexical bindings (test 4.2)
- Fix `procedure?` for continuations (Chibi test)
- Investigate `symbol? 'nil` failure (Chibi test)

**Non-Goals:**
- Fix letrec + call/cc init semantics (test 1.1) — deep semantic issue, deferred

## Decisions

### 1. Named let expansion: evaluate inits outside letrec scope

Current (wrong):
```scheme
(letrec ((name (lambda (vars) body)))
  (name inits...))            ;; inits evaluated inside letrec — name shadows outer bindings
```

Correct R5RS expansion:
```scheme
((letrec ((name (lambda (vars) body)))
   name)
 inits...)                    ;; inits evaluated outside letrec
```

One-line change in `prelude.scm`.

### 2. Lexical bindings shadow special forms

The compiler dispatches special forms (`begin`, `if`, `define`, `set!`, `apply`, `quote`, `quasiquote`, `lambda`, `define-macro`) before checking lexical scope. R5RS requires that lexical bindings shadow everything.

Fix: add an early check in `mc-compile` — if the car of a pair expression is a lexically-bound symbol, skip all special form checks and compile as a regular application.

```scheme
;; After mc-variable? check, before special form dispatch:
((and (pair? expr) (symbol? (car expr))
      (mc-find-variable (car expr) (*mc-compile-lexical-env*)))
 (mc-compile-application expr target linkage))
```

This is safe because:
- Only triggers when the symbol has a lexical binding (lambda param, let var, etc.)
- Falls through to `mc-compile-application` which correctly compiles variable lookup + function call
- Consistent with existing macro shadowing behavior

### 3. Continuation recognition in procedure? shim

Continuations are `(continuation ...)` pairs. Extract the tag from a known continuation and add it to the `procedure?` check in the conformance test shim.

### 4. Investigate symbol?/nil

Check whether ECE's reader maps `nil` to CL's `NIL` or to `ECE::|nil|`, and why the test comparison fails.

## Risks / Trade-offs

**[Special form shadowing is unusual]** → No real code shadows `begin` or `if`. The change only affects behavior when a special form name appears in the lexical environment, which is rare. All existing tests should be unaffected.
