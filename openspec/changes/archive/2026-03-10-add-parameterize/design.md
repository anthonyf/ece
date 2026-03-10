## Approach

Implement parameter objects as CL primitives and `parameterize` as an ECE macro. Parameter objects are procedures that close over a mutable cell. `parameterize` saves the current value, sets the new one, evaluates the body, and restores — using `begin` to ensure restore happens even on normal exit. For `call/cc` safety, we use the same continuation-based approach as the rest of ECE: since ECE continuations capture the stack but not dynamic bindings, `parameterize` uses explicit save/restore which naturally works with the existing executor model.

## Design

### Parameter Objects (`make-parameter`)

A parameter object is a compiled procedure that dispatches on argument count:
- 0 args: return current value
- 1 arg: set value, return old value (with optional converter)

Implemented as a CL primitive `ece-make-parameter` that returns an ECE closure. The closure captures a mutable cons cell `(value . converter)`:

```
(make-parameter initial-value)         → parameter procedure
(make-parameter initial-value convert) → parameter procedure with converter
```

The converter function, if provided, is applied to both the initial value and any value passed to `parameterize`. This matches R7RS semantics.

Implementation in `runtime.lisp`:

```lisp
(defun ece-make-parameter (init &optional converter)
  "Create a parameter object. Returns a list (parameter cell converter)
   where cell is a cons whose car holds the current value."
  (let ((cell (cons (if converter (funcall converter init) init) nil)))
    (list 'parameter cell converter)))
```

The executor needs a new dispatch for parameter objects in procedure calls — or simpler: register a CL-level wrapper function as the primitive that handles get/set:

```lisp
;; Simpler: make-parameter returns a primitive that closes over a cell
(defun ece-make-parameter (init &optional converter)
  (let ((cell (cons (if converter
                        (apply-primitive-or-compiled converter (list init))
                        init)
                    converter)))
    ;; Return a closure-like primitive
    (let ((getter-setter-name (gensym "PARAM")))
      (setf (symbol-function getter-setter-name)
            (lambda (&optional (new-val nil supplied-p))
              (if supplied-p
                  (let ((old (car cell)))
                    (setf (car cell)
                          (if (cdr cell)
                              (apply-primitive-or-compiled (cdr cell) (list new-val))
                              new-val))
                    old)
                  (car cell))))
      (list 'primitive getter-setter-name))))
```

This approach makes parameter objects regular primitives, so they work with the existing procedure call dispatch — no executor changes needed.

### `parameterize` Macro

Defined in `prelude.scm` as a macro that expands to save/set/body/restore:

```scheme
(define-macro (parameterize bindings . body)
  (if (null? bindings)
      `(begin ,@body)
      (let ((param (car (car bindings)))
            (val (cadr (car bindings)))
            (rest (cdr bindings)))
        (let ((old (gensym)) (result (gensym)))
          `(let ((,old (,param)))
             (,param ,val)
             (let ((,result (parameterize ,rest ,@body)))
               (,param ,old)
               ,result))))))
```

This handles multiple bindings by nesting. Each binding saves the old value, sets the new one, evaluates the remaining body, then restores.

### `call/cc` Interaction

The save/restore approach means that if a continuation is captured inside `parameterize` and later invoked from outside, the parameter will have its outside-of-parameterize value (since restore already ran). This matches `fluid-let` semantics rather than full R7RS `parameterize` semantics (which would re-establish the dynamic binding on continuation re-entry).

Full R7RS semantics would require integrating parameter cells into the continuation capture/restore mechanism. This is significantly more complex and not needed for the immediate use case (MC compiler lexical env). We document this as a known limitation.

### MC Compiler Refactoring

In `compiler.scm`, change:

```scheme
;; Before
(define *mc-compile-lexical-env* '())
;; ... uses (let ((*mc-compile-lexical-env* ...)) ...)

;; After
(define *mc-compile-lexical-env* (make-parameter '()))
;; ... uses (parameterize ((*mc-compile-lexical-env* ...)) ...)
```

All reads of `*mc-compile-lexical-env*` change from bare variable references to `(*mc-compile-lexical-env*)` (call with 0 args).

## Key Decisions

- **Parameter objects as primitives**: Avoids executor changes. A parameter is just a `(primitive <gensym>)` that the existing apply dispatch handles.
- **`parameterize` as macro**: Keeps the implementation in ECE, easy to understand and modify.
- **`fluid-let` semantics for `call/cc`**: Simpler than full R7RS. Continuations don't re-establish dynamic bindings. Acceptable because ECE's primary `call/cc` use is for goto/save-restore in IF, not for coroutines that re-enter parameterized scopes.
- **Optional converter support**: Included per R7RS spec. Converters are applied at `make-parameter` time and at each `parameterize` rebinding.

## Risks

- **`call/cc` edge case**: If someone captures a continuation inside `parameterize` and re-invokes it later, the parameter won't be re-bound. This is documented as a known limitation.
- **Converter evaluation**: The converter function is called via the CL-level apply, which needs to handle both primitives and compiled procedures. Need to verify this works.
