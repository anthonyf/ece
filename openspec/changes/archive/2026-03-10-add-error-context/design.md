## Context

ECE's register machine executes compiled instructions via a `tagbody` loop in `execute-instructions`. When a CL error occurs (unbound variable, wrong argument count, type error), it propagates as a raw CL condition with no ECE-level context. The register machine has all the information needed to produce useful diagnostics — the current instruction, environment bindings, procedure register, argument list, and a stack of saved registers — but none of this is surfaced in errors.

## Goals / Non-Goals

**Goals:**
- Catch CL errors during instruction execution and wrap them with register machine state
- Provide the current procedure name and arguments in error messages
- Extract a basic call stack from the register stack (saved continue registers → procedure names)
- Show accessible variable bindings from the current environment frame
- Keep the error context mechanism zero-cost when no errors occur

**Non-Goals:**
- Full ECE condition system (define-condition, with-handler) — future work
- Source location tracking or line numbers — requires compiler changes
- Step-by-step debugger or REPL inspector
- Tracing/profiling infrastructure

## Decisions

### 1. Use `handler-bind` around the tagbody loop

**Decision**: Wrap the existing `tagbody` loop body in a `handler-bind` for `error` conditions. On error, collect register state and signal a new `ece-runtime-error` condition that carries both the original error and the context.

**Alternatives considered**:
- **handler-case**: Would unwind the stack before we can inspect it. `handler-bind` runs the handler *before* unwinding, so we can read registers and stack in-place.
- **Per-instruction try/catch**: Too much overhead. A single handler around the loop is sufficient since we just need the state at error time.

### 2. Define an `ece-runtime-error` CL condition

**Decision**: Define a CL condition class `ece-runtime-error` (subclass of `error`) that carries:
- `original-error`: The underlying CL condition
- `ece-procedure`: The procedure being applied (from `proc` register)
- `ece-arguments`: The argument list (from `argl` register)
- `ece-environment`: The current environment (from `env` register)
- `ece-instruction`: The instruction that was executing
- `ece-backtrace`: List of `(procedure . pc)` pairs extracted from the stack

**Rationale**: A proper CL condition lets callers inspect fields programmatically, and the `report` method provides the formatted output.

### 3. Extract backtrace from the stack

**Decision**: Walk the stack list looking for saved continuation values (integers = PCs). For each saved PC, look backward in the stack for the most recent saved `proc` value to associate the return address with a procedure name. Limit to 10 frames.

**Rationale**: The stack interleaves saved registers (`(save env)`, `(save continue)`, `(save proc)`, etc.). Saved `continue` values are integers (PCs) that represent return addresses. This gives a basic call chain without any new bookkeeping.

### 4. Format environment as visible bindings

**Decision**: Show only the first (innermost) frame of the current environment to avoid overwhelming output. Display as `variable = value` pairs, truncating long values.

**Rationale**: The innermost frame contains the most relevant local bindings. Showing all frames would be noisy and usually unhelpful.

## Risks / Trade-offs

- **[Performance]** `handler-bind` has negligible overhead when no error occurs — it just establishes the handler frame. No risk to normal execution speed. → No mitigation needed.
- **[Stack inspection heuristic]** The backtrace extraction is best-effort since the stack doesn't have explicit frame markers. It may occasionally associate a PC with the wrong procedure. → Acceptable for a first version; future work can add explicit frame markers.
- **[Nested errors]** If the error handler itself errors (e.g., corrupt environment), we could get confusing double errors. → Guard the handler body with `ignore-errors` and fall back to the original error.
