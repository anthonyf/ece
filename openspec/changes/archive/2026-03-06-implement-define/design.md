## Context

The evaluator currently uses a flat alist for the environment, stored in `*global-env*`. Variables are looked up via `env-lookup` which scans the alist linearly. Lambda application extends the environment by prepending bindings with `append`/`mapcar`. There is no mechanism for mutating the environment, which `define` requires.

SICP's explicit control evaluator uses a frame-based environment where each frame is a mutable structure. `define-variable!` mutates the first frame of the current environment, making definitions visible to any code sharing that frame (including recursive function bodies that close over it).

## Goals / Non-Goals

**Goals:**
- Refactor the environment to use SICP's frame-based representation
- Rename `*global-env*` to `*initial-environment*`
- Add `define` as a special form following SICP's `ev-definition` pattern
- Support value syntax: `(define x 10)`
- Support function shorthand: `(define (f x) body...)` → `(define f (lambda (x) body...))`
- Definitions mutate the first frame of the current environment
- Allow redefining existing bindings

**Non-Goals:**
- `set!` / assignment (uses same frame machinery but scans all frames — can add later)
- `let` / `let*` / `letrec` forms
- Module or namespace support

## Decisions

**SICP frame-based environment**: An environment is a list of frames. Each frame is a cons cell `(cons vars vals)` where `vars` is a list of symbols and `vals` is a list of values. This follows SICP Section 4.1.3 exactly. The cons cell is mutable via `setf`, allowing `define-variable!` to add bindings to a frame in place.

Key environment operations:
- `make-frame (vars vals)` → `(cons vars vals)`
- `extend-environment (vars vals base-env)` → `(cons (make-frame vars vals) base-env)`
- `lookup-variable-value (var env)` → scan frames in order, scan vars/vals within each frame
- `define-variable! (var val env)` → scan first frame; if found update the value, if not prepend to both lists

**`*global-env*` as a single frame**: The global environment is restructured as a list containing one frame with the primitive procedure bindings. It continues to serve as the default environment for `evaluate` and accumulates `define` bindings over time.

**`define` mutates the current env's first frame**: Following SICP, `define` calls `define-variable!` on `env` (the evaluator's local variable), not on a global. Since the frame is a mutable cons cell, this mutation is visible to all closures sharing that frame. This enables recursion — a function defined with `define` closes over the frame it was defined in, and the definition is added to that same frame.

**Two-phase evaluation (SICP pattern)**: `ev-define` saves the variable name, environment, and continuation, then evaluates the value expression. `ev-define-assign` restores them, calls `define-variable!`, and sets `val`.

**Function shorthand desugaring**: `ev-define` checks if `(cadr expr)` is a list. If so, it extracts the name from `(caadr expr)` and constructs a lambda expression from the parameters and body.

## Risks / Trade-offs

- [Environment refactor scope] → Touches `env-lookup`, `compound-apply`, and all tests that pass explicit environments; manageable since the codebase is small
- [Frame mutability] → `define` inside a lambda body adds to that lambda's frame, which is correct SICP behavior but may surprise users expecting Scheme's internal-define-as-letrec semantics
- [Parallel lists vs alist] → SICP's `(vars . vals)` representation is slightly less ergonomic than an alist for debugging, but matches the reference implementation
