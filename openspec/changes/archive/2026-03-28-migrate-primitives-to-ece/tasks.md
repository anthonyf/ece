## 1. Phase 1: CL-only removals (strings + print already in prelude)

- [x] 1.1 Remove `string-downcase`, `string-upcase`, `string-split`, `string-trim`, `string-contains?`, `string-join` from CL `*wrapper-primitives*` in `runtime.lisp`
- [x] 1.2 Remove `print` from CL `*wrapper-primitives*` in `runtime.lisp`
- [x] 1.3 Run CL test suite (`make test`) to verify prelude implementations work
- [x] 1.4 Clear FASL cache and re-test

## 2. Phase 2: Add new ECE implementations to prelude.scm

- [x] 2.1 Add `char-whitespace?` — range check for space/tab/newline/cr via `char->integer`
- [x] 2.2 Add `char-alphabetic?` — range check for A-Z/a-z via `char->integer`
- [x] 2.3 Add `char-numeric?` — range check for 0-9 via `char->integer`
- [x] 2.4 Add `eqv?` — `eq?` plus numeric `=` check
- [x] 2.5 Add `equal?` — recursive structural equality using `eq?`, `pair?`, `vector?`, `string=?`, `=`
- [x] 2.6 Add `gensym` — counter variable + `number->string` + `string-append` + `string->symbol`
- [x] 2.7 Place new definitions before any code that depends on them (e.g., `char-whitespace?` before `string-trim`)

## 3. Phase 3: Remove from host dispatch tables

- [x] 3.1 Remove char-whitespace? (47), char-alphabetic? (48), char-numeric? (49) from CL `*wrapper-primitives*`
- [x] 3.2 Remove equal? (21), eqv? (174) from CL `*wrapper-primitives*` / `*primitive-procedures*`
- [x] 3.3 Remove gensym (82) from CL `*wrapper-primitives*`
- [x] 3.4 Remove char-whitespace? (47), char-alphabetic? (48), char-numeric? (49) from WASM `apply-primitive`
- [x] 3.5 Remove equal? (21), eqv? (174) from WASM `apply-primitive` (eqv? was already absent)
- [x] 3.6 Remove gensym (82) and `$gensym-counter` / `$gensym-name` from WASM runtime

## 4. Update primitives.def

- [x] 4.1 Change platform from `core` to `ece` for all migrated primitives (IDs 21, 36-41, 47-49, 66, 82, 174)

## 5. Rebuild and test

- [x] 5.1 Run `make bootstrap` to regenerate .ecec files (two-pass: first with CL primitives to generate new .ecec, then without)
- [x] 5.2 Run CL test suite (`make test`) — all tests pass
- [x] 5.3 Rebuild `runtime.wasm` via `make wasm`
- [x] 5.4 Run WASM test suite (`make test-wasm`) — 33 passed, 0 failed
- [x] 5.5 Verify existing char/string/equality tests all pass on both platforms
