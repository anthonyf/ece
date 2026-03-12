## 1. Add ECE definitions to prelude.scm

- [x] 1.1 Add list accessors at top of prelude: `cadr`, `caddr`, `caar`, `cddr`, `list-ref`, `list-tail`
- [x] 1.2 Add core list functions before `map`: `reverse`, `length`, `append`, `member`, `assoc`
- [x] 1.3 Add derived predicates: `not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, `>=`
- [x] 1.4 Move existing `map`, `reduce`, `filter`, `for-each` below the new definitions (they depend on `reverse`)
- [x] 1.5 Add math helpers after `reduce`: `abs`, `min` (variadic), `max` (variadic)
- [x] 1.6 Add hash table operations before `define-record`: `hash-table`, `hash-table?`, `hash-ref`, `hash-set!`, `hash-set`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-remove!`

## 2. Remove CL primitives from runtime.lisp

- [x] 2.1 Remove list accessors from `*primitive-procedures*`: `cadr`, `caddr`, `caar`, `cddr`, `reverse`, `length`, `append`, `member`, `assoc`
- [x] 2.2 Remove list wrappers from `*wrapper-primitives*`: `list-ref`, `list-tail`
- [x] 2.3 Delete CL wrapper functions: `ece-list-ref`, `ece-list-tail`
- [x] 2.4 Remove derived predicates from `*primitive-procedures*`: `not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, `>=`
- [x] 2.5 Remove math helpers from `*primitive-procedures*`: `abs`, `min`, `max`
- [x] 2.6 Remove hash table entries from `*wrapper-primitives*`: all 10 hash-table ops
- [x] 2.7 Delete CL hash table wrapper functions: `ece-hash-table`, `ece-hash-table-p`, `ece-hash-ref`, `ece-hash-has-key-p`, `ece-hash-keys`, `ece-hash-values`, `ece-hash-count`, `ece-hash-set!`, `ece-hash-set`, `ece-hash-remove!`
- [x] 2.8 Remove `boolean?` wrapper function and entry (reimplemented in ECE prelude)

## 3. Verify

- [x] 3.1 Clear FASL cache and regenerate bootstrap image (`make image`)
- [x] 3.2 Run `make test` — all 630 assertions pass, 0 failures
- [x] 3.3 Count runtime.lisp lines — 1489 → 1411 (78 lines removed)
