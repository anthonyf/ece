## 1. Runtime: enclosing-environment operation

- [x] 1.1 Add `enclosing-environment` function to CL runtime (`src/runtime.lisp`) — returns `cdr` of env cons cell. Register in operations hash table.
- [x] 1.2 Add `enclosing-environment` operation to WASM runtime (`wasm/runtime.wat`) — returns `$enclosing` field of `$env-frame`. Register in resolve-operations dispatch.
- [x] 1.3 Test `enclosing-environment` returns correct parent frame in both runtimes.

## 2. Compiler: let* direct compilation

- [x] 2.1 Add `mc-let*?` predicate to `src/compiler.scm` — detects `(let* ...)` forms.
- [x] 2.2 Implement `mc-compile-let*` — single frame with N empty slots via `(op extend-environment) '() '() env N`, progressive `lexical-set!` with incremental `*mc-compile-lexical-env*` extension after each binding.
- [x] 2.3 Handle TCO: when linkage is `'return`, compile body with `'return` (no env restore). When non-tail, compile body with `'next`, emit `(op enclosing-environment)` restore, then outer linkage.
- [x] 2.4 Handle empty `let*`: `(let* () body)` compiles body directly (no frame created).
- [x] 2.5 Add `mc-let*?` dispatch to `mc-compile` cond chain, after `mc-begin?` and before `mc-global-ref?`.

## 3. Compiler: let direct compilation

- [x] 3.1 Add `mc-let?` predicate — detects `(let ...)` but NOT named let `(let name ...)`.
- [x] 3.2 Implement `mc-compile-let` — compile all inits with outer env, save on stack, build argl, extend env with all bindings at once.
- [x] 3.3 Handle TCO: same tail/non-tail linkage threading as let*.
- [x] 3.4 Handle empty `let`: `(let () body)` compiles body directly.
- [x] 3.5 Add `mc-let?` dispatch to `mc-compile` cond chain.

## 4. Macro shadowing for let/let* bindings

- [x] 4.1 Ensure `let`/`let*` binding names are added to `*mc-compile-macro-shadows*` (or equivalent) so they shadow macros with the same name during body compilation.

## 5. Define-at-top enforcement

- [x] 5.1 Add validation in `mc-compile-lambda-body`: after extracting define names, walk body forms and error if `define` appears after a non-define/non-begin expression.
- [x] 5.2 Allow `begin` at top of body to be transparent (its contents spliced for define-position checking).
- [x] 5.3 Allow `define-macro` at top of body (treated like `define` for position checking).
- [x] 5.4 Audit existing `.scm` source files for defines after expressions — fix any violations.
- [x] 5.5 Remove `if`-branch scanning from `mc-extract-define-names` (lines 229-230) — defines inside `if` are no longer valid.

## 6. Tests: scoping correctness

- [x] 6.1 Test `let` parallel binding: `(let ((x 1) (y 2)) (+ x y))` → 3
- [x] 6.2 Test `let` parallel binding with outer shadow: `(let ((x 10)) (let ((x 1) (y x)) y))` → 10
- [x] 6.3 Test `let*` sequential reference: `(let* ((x 1) (y (+ x 1))) y)` → 2
- [x] 6.4 Test `let*` shadowing: `(let ((x 1)) (let* ((y x) (x 2)) y))` → 1
- [x] 6.5 Test nested let/let*: `(let ((a 1)) (let* ((b a) (c (+ b 1))) (let ((d (+ c 1))) d)))` → 3
- [x] 6.6 Test `let` binding shadows macro: `(let ((when 42)) when)` → 42
- [x] 6.7 Test `let*` binding shadows macro for subsequent bindings: `(let* ((when 42) (x when)) x)` → 42

## 7. Tests: TCO

- [x] 7.1 Test `let` in tail position: `(define (loop n) (let ((m (- n 1))) (if (= m 0) 'done (loop m))))` at 1,000,000 iterations.
- [x] 7.2 Test `let*` in tail position: `(define (loop n) (let* ((m (- n 1)) (k m)) (if (= k 0) 'done (loop k))))` at 1,000,000 iterations.
- [x] 7.3 Test nested `let*` in tail position at 1,000,000 iterations.
- [x] 7.4 Test non-tail `let` followed by tail call: `(define (loop n) (let ((x n)) x) (if (= n 0) 'done (loop (- n 1))))` at 1,000,000 iterations.

## 8. Tests: define-at-top enforcement

- [x] 8.1 Test defines at top of body: accepted.
- [x] 8.2 Test define after expression: compile-time error.
- [x] 8.3 Test define inside top-level begin: accepted.
- [x] 8.4 Test define-macro at top of body: accepted.
- [x] 8.5 Test define inside if: compile-time error.
- [x] 8.6 Test top-level defines (non-lambda): unrestricted, no error.

## 9. Bootstrap and integration

- [x] 9.1 Run full test suite (rove, ECE self-hosted, conformance, WASM) — fix any regressions.
- [x] 9.2 Two-pass `make bootstrap` — verify .ecec files regenerate correctly.
- [x] 9.3 Verify sandbox game-loop program runs with improved FPS (let* no longer creates lambda overhead).
