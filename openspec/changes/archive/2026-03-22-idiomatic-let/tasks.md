## 1. Small files (build confidence)

- [x] 1.1 Convert assembler.scm: 6 scattered bindings → `let*`
- [x] 1.2 Convert ecec-to-binary.scm: 3 named helper loops → named `let`
- [x] 1.3 Run `make test` to verify

## 2. Compiler

- [x] 2.1 Convert compiler.scm: 3 named helper loops → named `let`
- [x] 2.2 Run `make test` to verify

## 3. Compilation unit

- [x] 3.1 Convert compilation-unit.scm: scattered bindings → `let*`, named loops → named `let`
- [x] 3.2 Run `make test` to verify

## 4. Prelude (largest, post-let-macro only)

- [x] 4.1 Convert prelude.scm named helper loops (post line 173) → named `let`
- [x] 4.2 Convert prelude.scm scattered local bindings (post line 173) → `let`/`let*`
- [x] 4.3 Skip: early prelude (lines 1-172), macro template bodies, multi-function blocks (serialize-value, do-winds!, etc.)
- [x] 4.4 Run `make test` to verify

## 5. Rebuild and final check

- [x] 5.1 Rebuild bootstrap (`make bootstrap`)
- [x] 5.2 Run `make test` and `make test-wasm` to verify everything passes
