## Context

ECE has a compiler (SICP 5.5) that translates Scheme to register machine instructions. Compiled procedures are called via `goto` to their entry PC — there's no CL-level function call to intercept. Primitives go through `apply-primitive-procedure` which calls `(apply (symbol-function name) argl)`.

We now have error context (Thread 1) and procedure name tables (Thread 2). Tracing is the next debugging tool — it lets developers observe procedure call flow without modifying source code.

## Goals / Non-Goals

**Goals:**
- `(trace foo)` enables tracing: logs entry with arguments and return value for each call
- `(untrace foo)` disables tracing and restores the original procedure
- Depth-indented output so nested calls are visually clear
- Works for both compiled procedures and primitives
- Zero overhead when no procedures are traced

**Non-Goals:**
- Conditional tracing (trace only when predicate holds) — future enhancement
- Tracing anonymous lambdas — no name to reference
- Trace output to ports other than stdout — future enhancement
- Integration with stepping (Thread 6) — separate change

## Decisions

### Decision 1: Primitive wrapper approach (over instruction-level hooks)

**Choice**: When `(trace foo)` is called, replace `foo`'s binding in `*global-env*` with a primitive wrapper that logs entry, delegates to the original, and logs exit.

**Alternatives considered**:
- **Instruction-level hooks**: Insert trace instructions into the instruction vector around call sites. Rejected — extremely complex (flat array splicing), can't easily detect returns, modifies shared instruction vector.
- **Executor-level hook**: Check a `*traced-procedures*` set on every compiled call dispatch. Rejected — adds overhead to every call even when nothing is traced.

**Rationale**: The wrapper approach has zero overhead when not tracing (no hot-path checks), is simple to implement (~60-80 lines), and uses the existing primitive dispatch path cleanly.

### Decision 2: `execute-compiled-call` helper for re-entering executor

**Choice**: Add `execute-compiled-call` that enters `execute-instructions` with `proc` and `argl` pre-loaded, starting at the compiled procedure's entry PC.

**Rationale**: A tracing wrapper is a CL primitive. When it needs to call the original compiled procedure, it must re-enter the executor. The compiled code at entry-pc expects `proc` in the proc register (to extract its env) and `argl` in argl (for `extend-environment`). Adding keyword args `:initial-proc` and `:initial-argl` to `execute-instructions` is the cleanest way to support this.

### Decision 3: `trace`/`untrace` as primitives (not special forms)

**Choice**: Implement `trace` and `untrace` as primitives that take a symbol name and operate on `*global-env*`.

**Rationale**: They don't need special compilation — they just look up and swap bindings at runtime. Making them primitives keeps the compiler untouched. The symbol argument tells them which variable to look up in `*global-env*`.

### Decision 4: Store originals in a CL-side hash table

**Choice**: `*traced-procedures*` hash table maps symbol → original procedure value. This lives on the CL side, not in the ECE environment.

**Rationale**: Clean separation — the ECE environment sees only the wrapper, while the CL side tracks what's being traced and holds the originals for restoration.

## Risks / Trade-offs

- **Tail calls become non-tail**: The wrapper needs the return value to log it, so tail calls through traced procedures become non-tail (extra stack frame). This is acceptable for a debugging tool — tracing inherently needs to observe returns.
- **Recursive executor entry**: Each traced compiled call re-enters `execute-instructions`. Deep traced recursion could hit CL stack limits. Mitigation: this is a debugging tool, not for production. Could add a `*trace-max-depth*` limit later.
- **Only global bindings**: `trace`/`untrace` operate on `*global-env*`. Locally-bound procedures (e.g., from `let`) can't be traced this way. This matches the standard Scheme `trace` facility behavior.
