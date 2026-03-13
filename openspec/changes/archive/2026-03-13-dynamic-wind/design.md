## Context

ECE is a compiled Scheme with `call/cc` implemented as a special form. Continuations capture the register machine stack and program counter. The compiler recognizes `call/cc` by name in `*special-forms*` and emits `capture-continuation` / stack-restore instructions directly.

There is no `dynamic-wind`, no exception handler system, and no inspectable error objects. The CL-side `ece-runtime-error` condition wraps errors with debugging context, but ECE code cannot access this. The test framework's `assert-error` uses `try-eval` (a CL escape hatch) that only reports whether an error occurred, discarding the message.

## Goals / Non-Goals

**Goals:**
- R7RS-compliant `dynamic-wind` with proper continuation interaction
- R7RS `guard`, `raise`, `with-exception-handler`
- Inspectable error objects with message and irritants
- `assert-error-message` in the test framework for error content verification
- Almost entirely self-hosted — minimal CL kernel change

**Non-Goals:**
- `raise-continuable` (can be added later as an incremental extension)
- Full R6RS condition type hierarchy (records are sufficient)
- `dynamic-wind` / `parameterize` interaction (parameterize already works independently)
- Performance optimization of the winding path (correctness first)

## Decisions

### 1. Rename `call/cc` special form to `%raw-call/cc`

**Choice**: Rename the compiler-recognized special form; redefine `call/cc` as an ECE macro.

**Rationale**: `call/cc` must wrap raw continuations with winding logic. Since the compiler checks special forms by name before macro expansion, we need a different name for the raw mechanism. A `%`-prefixed name signals "internal, don't use directly."

**Alternatives considered**:
- *Add `%raw-call/cc` as a second special form alongside `call/cc`*: Leaves ambiguity — which should users call? The compiler would still compile `call/cc` as the raw form, ignoring any ECE redefinition.
- *Make `call/cc` a function instead of macro*: Adds an extra stack frame to every continuation capture. The macro approach inlines the winding wrapper at the call site with zero overhead.
- *CL-side `dynamic-wind` implementation*: ~60 lines of CL. Contradicts the kernel minimization goal. The winding logic only manipulates ECE data structures and should be self-hosted.

### 2. `call/cc` as macro, `call-with-current-continuation` as function

**Choice**: `call/cc` is a `define-macro` expanding to `%raw-call/cc` + winding wrapper. `call-with-current-continuation` is a function that uses the macro internally.

**Rationale**: The macro inlines the winding capture at each call site — no extra function call, no extra stack frame. The continuation captured by `%raw-call/cc` is at the actual usage site. `call-with-current-continuation` provides a first-class procedure for cases where `call/cc` must be passed as a value (macros aren't first-class).

**Expansion sketch**:
```scheme
(call/cc receiver)
;; expands to:
(let ((<saved> *winding-stack*))
  (%raw-call/cc (lambda (<raw-k>)
    (receiver (lambda (<val>)
      (do-winds! *winding-stack* <saved>)
      (<raw-k> <val>))))))
```

### 3. Error objects as records

**Choice**: `(define-record error-object (message irritants))` using the existing record system.

**Rationale**: Records already provide constructor, predicate, and field accessors. No new mechanism needed. Error objects are plain ECE data — they can be pattern-matched in `guard` clauses, stored, serialized.

**Alternatives considered**:
- *Tagged lists `(error-obj msg irritants)`*: Less structured, no type predicate, easy to confuse with regular data.
- *CL condition mapping*: Would require CL-side accessors to extract from `ece-runtime-error`. Ties error handling to CL internals.

### 4. `error` redefined to construct and raise

**Choice**: Redefine `error` in the prelude to create an `error-object` and call `raise`.

**Rationale**: Standard R7RS behavior — `(error "msg" irritant ...)` creates an error object and raises it. The CL primitive `error` is no longer called directly; instead `raise` bridges to CL when no handler is installed.

**Bridge behavior**: When `raise` has no ECE exception handler, it falls through to CL's `error` with a formatted message from the error object. This preserves the existing REPL/debugger experience.

### 5. Handler stack via parameter

**Choice**: `*current-exception-handler*` as a `make-parameter` with `dynamic-wind` for installation.

**Rationale**: `with-exception-handler` uses `dynamic-wind` to install/remove handlers. This means continuation jumps that cross handler boundaries automatically trigger the wind/unwind logic, correctly maintaining the handler stack. Using `parameterize` alone would NOT work because `parameterize` doesn't interact with `dynamic-wind` in ECE.

### 6. `guard` implementation strategy

**Choice**: `guard` uses `call/cc` to capture the guard continuation, installs an exception handler, evaluates the body. The handler jumps back to the guard continuation to evaluate clauses.

**Rationale**: This is the R7RS-specified behavior. Clauses are evaluated in the continuation of the `guard` expression (not in the handler's dynamic extent), which matters for re-raising and for the guard expression's return value. The `call/cc`-based approach handles this correctly.

## Risks / Trade-offs

**[Every `call/cc` allocates a wrapper lambda]** → When `*winding-stack*` is empty (common case), the wrapper still allocates. This is unavoidable with the macro approach unless we add a fast-path check. For now, accept the allocation — it's one cons cell per `call/cc`. If benchmarks show impact, `%raw-call/cc` is available as an escape hatch for hot paths like `loop`/`break`.

**[CL-originated errors need bridging]** → Type errors, arithmetic errors, etc. originate from CL, not from ECE `raise`. These won't produce `error-object` records automatically. The `guard` handler will receive whatever CL signals. → Mitigation: In `execute-instructions`'s existing `handler-bind`, wrap CL errors into ECE `error-object` records before re-signaling. This is a small addition to the existing error-wrapping code.

**[`loop` macro uses `call/cc` directly]** → After the rename, the `loop` macro's `call/cc` becomes the winding-aware macro version. This is correct behavior but adds minimal overhead to tight loops. → Acceptable: `loop` already allocates a closure for `break`. One extra `let` binding is negligible.

**[Self-hosted compiler must also be updated]** → `compiler.scm` has its own `*special-forms*` list and `mc-callcc?` predicate. Must rename there too, and the metacircular compiler must handle `%raw-call/cc` the same way. → Low risk: it's a mechanical rename.
