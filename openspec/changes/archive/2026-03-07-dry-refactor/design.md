## Context

The ECE evaluator in `src/main.lisp` has grown organically. Three areas have accumulated repetitive patterns:

1. **Primitive alist duplication**: Lines 174-209 define the same 40-entry alist twice — once for `*primitive-procedure-names*` and once for `*primitive-procedure-objects*`. Adding a new primitive requires updating both in lockstep.

2. **Special form predicates**: Lines 398-439 define 10 functions that all follow `(and (listp expr) (eq (car expr) 'SYMBOL))`. The `*special-forms*` list at line 466 already enumerates these symbols but isn't used to generate the predicates.

3. **Dolist registration**: Lines 358-385 register wrapper-based primitives using verbose `(cons 'name (list 'primitive 'sym))` syntax repeated 25 times.

## Goals / Non-Goals

**Goals:**
- Define each primitive alist entry exactly once
- Eliminate the 10 boilerplate special form predicate functions
- Simplify the dolist primitive registration block
- All existing tests pass without modification (pure refactor)

**Non-Goals:**
- Adding new primitives or features
- Changing the evaluator's behavior or API
- Modifying test files
- Refactoring the evaluator dispatch loop itself

## Decisions

### 1. Single `*primitive-procedures*` alist

Define one `*primitive-procedures*` alist. Derive `*primitive-procedure-names*` and `*primitive-procedure-objects*` from it using `mapcar`.

```lisp
(defparameter *primitive-procedures*
  '(+ - * / = < > ...
    (null? . null) (pair? . consp) ...))

(defparameter *primitive-procedure-names*
  (mapcar (lambda (p) (if (listp p) (car p) p))
          *primitive-procedures*))

(defparameter *primitive-procedure-objects*
  (mapcar (lambda (p) (list 'primitive (if (listp p) (cdr p) p)))
          *primitive-procedures*))
```

**Rationale**: Minimal change — keeps existing structure, just removes the duplication. The derived variables maintain the same interface for `extend-environment`.

### 2. Generate predicates from `*special-forms*` using a macro

Replace the 10 predicate functions with a `defmacro` that generates them from `*special-forms*`. The dispatch block uses a lookup into `*special-forms*` (which already exists) via the existing `application-p` function, plus a new `special-form-tag` function.

```lisp
;; Generate predicate: (define-special-form-predicate set assignment)
;; → (defun assignment-p (expr) (and (listp expr) (eq (car expr) 'set)))
(defmacro define-special-form-predicate (symbol name)
  `(defun ,(intern (format nil "~A-P" name)) (expr)
     (and (listp expr) (eq (car expr) ',symbol))))
```

Then invoke once per special form. This preserves the named functions (important for readability in the dispatch block) while eliminating the boilerplate.

**Alternative considered**: Replace predicates entirely with a single `(special-form-p expr 'set)` function. Rejected because it changes every call site in the dispatch block and reduces readability.

### 3. Simplify dolist with alist + helper

Use the same dotted-pair format as `*primitive-procedures*` for wrapper primitives, and a single loop that processes them:

```lisp
(defparameter *wrapper-primitives*
  '((read . ece-read)
    (display . ece-display)
    ...))

(dolist (entry *wrapper-primitives*)
  (define-variable! (car entry)
                    (list 'primitive (cdr entry))
                    *global-env*))
```

**Rationale**: Same alist convention as the main primitives. The verbose `(cons ... (list ...))` expressions are replaced by a simple data declaration.

## Risks / Trade-offs

- **Load order**: `*primitive-procedures*` must be defined before `*primitive-procedure-names*` and `*primitive-procedure-objects*`, which must be defined before `*global-env*`. Current ordering already satisfies this.
- **Predicate generation**: Using a macro at compile time means predicates are still visible in stack traces and `describe`, just like hand-written ones. No debuggability loss.
- **No behavior change**: This is strictly a refactor. If any test fails, it indicates a bug in the refactoring, not a design issue.
