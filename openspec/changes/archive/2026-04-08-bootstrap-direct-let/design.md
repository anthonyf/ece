## Context

Commit eec191d added `mc-compile-let` and `mc-compile-let*` to the compiler, but the bootstrap.ecec still uses the old compiler (let/let* via macro expansion). Two bugs prevent the bootstrap from regenerating:

**Bug 1 — `mc-compile-let` stack corruption:** When `let` has 2+ bindings whose inits are function calls, the `preserving '(env)` in the eval-and-save loop emits `save env / <init1> / save val / restore env`. The `restore env` pops `val` (top of stack) instead of `env`. Confirmed: `(let ((a (string-length s)) (b (string-length p))) ...)` fails with "Unbound variable: string-length". Single-binding let works.

**Bug 2 — Non-tail env restoration:** When `operations.def` entry 27 (`enclosing-environment`) is present AND the new compiler is active (post-bootstrap), deeply nested non-tail let/let* produces "NIL is not of type SIMPLE-VECTOR". The env chain terminates at NIL instead of the global hash-frame. Simple cases pass; complex nesting (ece-test.scm) fails.

## Goals / Non-Goals

**Goals:**
- Fix both bugs so the new compiler can self-host
- Regenerate bootstrap.ecec with the new compiler active
- WASM asm symbol registration for `enclosing-environment`
- Verify performance improvement on sandbox game loop

**Non-Goals:**
- Further compiler optimizations (frame folding, etc.)
- WASM bootstrap regeneration (separate concern)

## Decisions

### 1. Fix mc-compile-let: replace custom eval-and-save with mc-construct-arglist

The current `eval-and-save` loop manually saves each init value on the stack and uses `preserving '(env)` around the accumulator. This breaks because `save val` inside seq1 makes `restore env` pop the wrong value.

**Fix:** Replace the custom `eval-and-save` + `build-argl` with a single call to `mc-construct-arglist`, which is the SICP compiler's existing operand evaluation mechanism. It already handles env preservation correctly across multiple operand compilations by using `preserving` between individual operands (not around the accumulator).

The current code already imports init-codes via `(map (lambda (init) (mc-compile init 'val 'next)) inits)`. These are exactly the operand-codes that `mc-construct-arglist` expects.

### 2. Debug non-tail env restoration

**Hypothesis:** The `enclosing-environment` operation (`(cdr env)`) works correctly for the immediate let frame, but when multiple non-tail lets are nested, the env restore chain may pop one frame too many or hit the global env terminator.

**Investigation approach:**
1. Build a minimal reproducer with 2-3 nested non-tail lets containing function calls
2. Trace the env register through the instruction sequence
3. Check if the issue is in the compiler (wrong instruction emission) or runtime (wrong env chain structure)

**Likely fix areas:**
- `mc-compile-let*`: The `append-instruction-sequences` accumulation (already changed from `preserving`) may still have issues with needs/modifies tracking — the combined sequence might not correctly declare that it needs `env` from the caller
- `mc-compile-let`: The `setup-code` uses `preserving '(env) arglist-code extend-code` — verify extend-code's env modification is intended to persist

### 3. Boot-env asm symbol update

Add `enclosing-environment` as asm symbol slot 44, bump count from 44 to 45. This follows the pattern of existing operation registrations (slots 17-43 = ops 0-26, so slot 44 = op 27).

### 4. Two-pass bootstrap

1. **Pass 1:** Boot from current bootstrap.ecec (old compiler) → compile all .scm (old compiler compiles them) → write new bootstrap.ecec. This new .ecec has the new compiler DEFINED but compiled by the old compiler.
2. **Pass 2:** Boot from pass-1 .ecec (new compiler active) → compile all .scm (new compiler compiles them) → write final bootstrap.ecec. This .ecec has the new compiler compiled BY the new compiler.

Both passes use `make bootstrap`. Between passes, no manual steps needed (operations.def already has entry 27).

## Risks / Trade-offs

**[Risk] Bug 2 is deeper than expected** — If the env chain issue is in the register machine's env handling (not just the compiler), the fix may require changes to `execute-instructions` or `extend-environment`. Mitigation: the minimal reproducer will isolate whether the issue is compile-time or runtime.

**[Risk] Bootstrap divergence** — If the two-pass bootstrap produces different .ecec files on subsequent runs, there may be non-determinism in the compiler. Mitigation: compare file sizes and spot-check instruction counts between passes.
