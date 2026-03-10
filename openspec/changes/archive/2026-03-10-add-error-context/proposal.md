## Why

Runtime errors in ECE currently surface as bare CL conditions with no context about what the ECE program was doing. An "Unbound variable: x" error gives no indication of which procedure was executing, what arguments were passed, or how execution reached that point. This makes debugging non-trivial ECE programs frustrating and slow.

## What Changes

- Wrap the `execute-instructions` tagbody loop with `handler-bind` to intercept CL errors and enrich them with register machine state (current instruction, env, proc, argl, stack)
- Add a structured ECE error condition type that carries register context
- Extract a basic backtrace from the stack (saved continuation addresses mapped to procedure names)
- Format error messages to show: the error, the current procedure, visible variables, and a call stack

## Capabilities

### New Capabilities
- `error-context`: Enriching runtime errors with register machine state (current instruction, environment bindings, procedure, arguments, and stack-based backtrace)

### Modified Capabilities

## Impact

- `src/runtime.lisp`: Modify `execute-instructions` to wrap the tagbody loop with error interception; add ECE condition type, backtrace extraction, and error formatting utilities
- No API changes — existing `ece-eval-string` and `compile-and-go` callers get better errors automatically
- No breaking changes
