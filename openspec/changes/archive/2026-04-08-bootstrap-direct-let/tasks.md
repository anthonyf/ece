## 1. Fix mc-compile-let stack corruption

- [x] 1.1 Write minimal reproducer: `(define (f s p) (let ((a (string-length s)) (b (string-length p))) (+ a b)))` — confirm "Unbound variable: string-length" with new compiler active.
- [x] 1.2 Replace custom `eval-and-save` + `build-argl` in `mc-compile-let` with `mc-construct-arglist` call. Use `preserving '(env)` between arglist-code and extend-code.
- [x] 1.3 Verify reproducer passes after fix.
- [x] 1.4 Test let with 1, 2, 3+ bindings (mix of simple values and function calls).

## 2. Fix non-tail let/let* env chain breakage

- [x] 2.1 Build minimal reproducer for "NIL is not of type SIMPLE-VECTOR" — nested non-tail let/let* with function calls in body.
- [x] 2.2 Trace env register through compiled instructions: check extend-environment creates correct frame, enclosing-environment returns correct parent.
- [x] 2.3 Check if issue is in mc-compile-let* `append-instruction-sequences` accumulation (needs/modifies tracking).
- [x] 2.4 Check if issue is in non-tail env restore interacting with the global hash-frame terminator.
- [x] 2.5 Fix the root cause and verify reproducer passes.
- [x] 2.6 Test deeply nested let/let* (3+ levels) with function calls at each level.

## 3. Update boot-env.scm asm symbols

- [x] 3.1 Add `(%store-asm-sym 44 'enclosing-environment)` to `src/boot-env.scm`.
- [x] 3.2 Update `(%init-asm-syms 44)` to `(%init-asm-syms 45)`.

## 4. Bootstrap regeneration

- [x] 4.1 Pass 1: `make bootstrap` from old bootstrap.ecec — generates new .ecec with fixed compiler.
- [x] 4.2 Pass 2: `make bootstrap` from pass-1 .ecec — new compiler compiles itself.
- [x] 4.3 Verify pass-2 .ecec boots cleanly and all tests pass.
- [x] 4.4 Run full test suite: rove, ECE self-hosted, conformance, WASM.

## 5. Verification

- [x] 5.1 Verify the 2 previously-expected test failures (define-at-top enforcement) now pass with the new bootstrap compiler.
- [x] 5.2 Run sandbox game-loop program, verify improved FPS (let* no longer creates lambda overhead).
