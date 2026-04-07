## 1. Add Prelude Functions

- [x] 1.1 Add `memq` to `src/prelude.scm` next to `member` — uses `eq?` instead of `equal?`
- [x] 1.2 Add `assq` to `src/prelude.scm` next to `assoc` — uses `eq?` instead of `equal?`
- [x] 1.3 Add `list?` to `src/prelude.scm` near the list functions — recursive null/pair check using nested `if` (not `cond`)

## 2. Add `procedure?` Primitive

- [x] 2.1 Add `ece-procedure?` to `src/runtime.lisp` — `(scheme-bool (or (compiled-procedure-p x) (primitive-procedure-p x) (continuation-p x)))`
- [x] 2.2 Register `procedure?` primitive in `src/boot-env.scm`

## 3. Remove Test Shims

- [x] 3.1 Remove `memq`, `list?`, `assq`, `procedure?` shim definitions and tag extraction from `tests/conformance/chibi-r5rs.scm`
- [x] 3.2 Remove `procedure?` shim and tag extraction from `tests/conformance/r5rs-pitfall.scm`

## 4. Bootstrap and Verify

- [x] 4.1 Run `make bootstrap` to regenerate `.ecec` files with new prelude functions
- [x] 4.2 Run `make test` — all suites pass (rove, ECE self-hosted, golden, conformance)
