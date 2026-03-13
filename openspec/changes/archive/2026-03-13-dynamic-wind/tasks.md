## 1. Rename call/cc to %raw-call/cc in CL Kernel

- [x] 1.1 In `src/compiler.lisp`: rename `call/cc` to `%raw-call/cc` in `*special-forms*` list, update `callcc-p` predicate (or rename to `raw-callcc-p`), update `compile-callcc` dispatch in the main `ece-compile` function
- [x] 1.2 In `src/runtime.lisp`: update `get-operation` if any call/cc references exist, update the `#:call/cc` export to `#:%raw-call/cc`
- [x] 1.3 Verify existing tests still pass with the rename (the `call/cc` macro defined in later tasks will restore the name)

## 2. Rename call/cc to %raw-call/cc in Self-Hosted Compiler

- [x] 2.1 In `src/compiler.scm`: rename `call/cc` to `%raw-call/cc` in the `*special-forms*` list, update `mc-callcc?` predicate, update `mc-compile-callcc` references
- [x] 2.2 Verify the self-hosted compiler compiles `%raw-call/cc` correctly

## 3. Implement dynamic-wind in Prelude

- [x] 3.1 Define `*winding-stack*` as a global variable (initially `'()`) in `src/prelude.scm`
- [x] 3.2 Implement `do-winds!` — compute common tail between current and target winding stacks, call `after` thunks for exited extents (innermost first), call `before` thunks for entered extents (outermost first)
- [x] 3.3 Implement `dynamic-wind` — call `before`, push `(before . after)` onto `*winding-stack*`, call `thunk`, pop stack, call `after`, return result
- [x] 3.4 Write `tests/ece/test-dynamic-wind.scm` — basic ordering, nesting, continuation exit triggers after, continuation re-entry triggers before, multiple wind levels, no-op when stacks match

## 4. Redefine call/cc as Winding-Aware Macro

- [x] 4.1 Define `call/cc` as a `define-macro` in `src/prelude.scm` that expands to `%raw-call/cc` + winding wrapper using `do-winds!` and gensym'd variables
- [x] 4.2 Define `call-with-current-continuation` as a function wrapping the `call/cc` macro
- [x] 4.3 Verify existing `call/cc` tests pass (test-callcc.scm)
- [x] 4.4 Verify `loop`/`break` macro still works (it uses `call/cc` internally)
- [x] 4.5 Add dynamic-wind + call/cc interaction tests to `test-dynamic-wind.scm`

## 5. Implement Error Objects

- [x] 5.1 Add `(define-record error-object (message irritants))` to `src/prelude.scm`
- [x] 5.2 Redefine `error` in the prelude to construct an `error-object` and call `raise` (implemented in next group). Temporarily, have `error` construct the object and signal via CL `%raw-error` until `raise` exists
- [x] 5.3 Add a `%raw-error` primitive binding for the original CL `error` function, so the bridge from ECE to CL is preserved

## 6. Implement raise and with-exception-handler

- [x] 6.1 Define `*current-exception-handler*` as a global variable (initially `#f` or `'()`) in `src/prelude.scm`
- [x] 6.2 Implement `raise` — if a handler is installed, invoke it with the exception object; if handler returns, signal a non-continuable error; if no handler, fall through to CL via `%raw-error` with a formatted message
- [x] 6.3 Implement `with-exception-handler` — use `dynamic-wind` to install/remove the handler on `*current-exception-handler*`, call `thunk`, return result
- [x] 6.4 Wire up `error` (from 5.2) to use `raise` now that it exists
- [ ] 6.5 **DEFERRED** Bridge CL-originated errors: CL errors (type errors, division by zero) are not caught by `guard` — they bypass ECE's raise/handler mechanism because the ECE continuation system doesn't span CL call frames. ECE-originated errors (via `error`/`raise`) work fully with `guard`. CL error bridging needs a deeper architectural solution (e.g., redirecting the executor's registers to call `raise` within the same executor frame).

## 7. Implement guard Macro

- [x] 7.1 Implement `guard` as a `define-macro` in `src/prelude.scm` — use `call/cc` to capture guard continuation, install handler via `with-exception-handler`, evaluate body, handler jumps to guard continuation to evaluate cond-style clauses
- [x] 7.2 Handle the re-raise case: if no clause matches and no `else`, re-raise the exception in the original dynamic environment
- [x] 7.3 Write `tests/ece/test-guard.scm` — basic catch, multiple clauses, else clause, re-raise, error-object accessors, nested guard, body returns normally, guard with continuation crossing

## 8. Enhance Test Framework

- [x] 8.1 Add `assert-error-message` macro to `tests/ece/test-framework.scm` — use `guard` to catch error, compare `error-object-message` to expected string, handle no-error and non-error-object cases
- [x] 8.2 Write `tests/ece/test-error-messages.scm` — type errors (`(+ "a" 1)`, `(car 5)`), unbound variable messages, division by zero, custom error messages, error with irritants, `assert` with custom message

## 9. Integration and Regression

- [x] 9.1 Run full test suite (`make test`) — verify all existing tests pass
- [x] 9.2 Run the new test files: test-dynamic-wind.scm, test-guard.scm, test-error-messages.scm
- [x] 9.3 Add new test files to `tests/ece/run-all.scm`
- [x] 9.4 Verify the REPL experience is preserved — errors without a handler still produce readable output with backtraces
