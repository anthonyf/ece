## Context

`%global-ref` is the compiler special form used by syntax-rules to protect free template variables from lexical shadowing. When a syntax-rules template contains `(+ e 1)`, the expander wraps `+` as `(%global-ref +)` so that even if `+` is rebound locally, the global `+` is used.

Currently, the compiler emits `(assign target (op lookup-variable-value) (const name) (reg env))` for `%global-ref`. This happens to work on CL because compiled `let`/`lambda` creates vector frames which `lookup-variable-value` skips (line 392-393 of runtime.lisp: `((vectorp frame) (env-loop (cdr env)))`). On WASM, all frames are `$env-frame` structs, so `lookup-variable-value` searches every frame and finds the local shadowed binding first.

The current op-id range is 0-22. The new operation will use op-id 23.

## Goals / Non-Goals

**Goals:**
- Make `%global-ref` correctly bypass lexical frames on all runtimes
- Add `lookup-global-variable` as a new register machine operation (op-id 23)
- Fix WASM syntax-rules hygiene tests

**Non-Goals:**
- Changing how CL's `lookup-variable-value` handles vector frames (the skip behavior is useful for other purposes)
- Adding `inexact->exact` or other number-system changes
- Fixing other WASM test failures unrelated to hygiene

## Decisions

### Decision 1: New operation vs. modifying existing

**Choice**: Add a new operation `lookup-global-variable` rather than modifying `lookup-variable-value`.

**Rationale**: `lookup-variable-value` is used extensively for normal variable access. Adding a separate operation keeps the semantics clean — `lookup-variable-value` searches from a given env, `lookup-global-variable` always searches from the global env. The compiler already distinguishes the two cases (`%global-ref` vs normal variable).

### Decision 2: Implementation approach

**Choice**: `lookup-global-variable` takes one argument (the variable name) and internally accesses the global environment.

On CL: `(defun lookup-global-variable (var) (lookup-variable-value var *global-env*))`.
On WASM: `(call $lookup-variable-value (local.get $name) (global.get $global-env))`.

**Rationale**: The global environment is already accessible — CL has `*global-env*`, WASM has `$global-env`. Wrapping the existing lookup with the global env is minimal code and reuses the proven lookup logic.

### Decision 3: Compiler instruction format

**Choice**: Change `mc-compile-global-ref` to emit `(assign target (op lookup-global-variable) (const name))` — no `(reg env)` argument.

**Rationale**: The operation internally accesses the global env, so no env argument is needed. This also makes the intent explicit in the instruction stream.

### Decision 4: Op-id assignment

**Choice**: Op-id 23, following the existing sequence (0-22).

**Rationale**: Op-ids are assigned sequentially by first-use order in compiled code. Since `lookup-global-variable` is new, it gets the next available id. The WASM executor, the CL `resolve-operation-index`, and `wasm/test.js` op-id validation test all need updating.

## Risks / Trade-offs

**[None] CL behavior change**: CL already works correctly due to the vector-frame skip. The new operation makes it work "for the right reason" instead of "by accident." Behavior is identical.

**[Low] Bootstrap**: The compiler change means old .ecec files use `(op lookup-variable-value)` for `%global-ref` while new ones use `(op lookup-global-variable)`. Two-pass bootstrap handles this — the first pass compiles with the new compiler (using old .ecec), the second pass recompiles from the new .ecec files.

**[Low] Op-id ordering**: Adding op-id 23 requires updating the WASM executor and `test.js` op-id validation. This is mechanical.
