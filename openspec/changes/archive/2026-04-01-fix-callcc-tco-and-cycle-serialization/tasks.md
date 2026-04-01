## 1. Tail-position call/cc TCO fix

- [x] 1.1 Add tail-position code path to `mc-compile-callcc` in `compiler.scm`: when `linkage = 'return` and `target = 'val`, emit code that captures the continuation using the caller's `continue` directly, with three-way dispatch (compiled/primitive/continuation) as true tail calls — no return-label, no save/restore
- [x] 1.2 Add test: tail-recursive call/cc loop at 10,000 iterations completes without stack overflow
- [x] 1.3 Add test: captured continuation is invocable after tail-recursive loop
- [x] 1.4 Add test: non-tail call/cc behavior is unchanged (existing tests still pass)
- [x] 1.5 Run `make bootstrap` (two-pass) to regenerate .ecec files with new compiler output

## 2. Cyclic deserialization fix

- [x] 2.1 Modify `deser` in `deserialize-value` (prelude.scm) to pre-allocate a `(cons #f #f)` placeholder for `%ser/def` bodies that are pairs, store it in ref-table before recursing, then patch via `set-car!`/`set-cdr!` after
- [x] 2.2 Add test: round-trip a `letrec` self-referencing closure (e.g., factorial), call the deserialized closure and verify correct result
- [x] 2.3 Add test: round-trip mutually recursive closures (even?/odd? via letrec), call both and verify
- [x] 2.4 Add test: round-trip a recursive `define` inside a `let` body captured by `call/cc`
- [x] 2.5 Add test: non-cyclic shared structure round-trip still works (existing serialization tests pass)
- [x] 2.6 Run `make bootstrap` to regenerate .ecec files with new prelude

## 3. Integration verification

- [x] 3.1 Run full test suite (`make test`) — all existing tests pass
- [x] 3.2 Verify combined scenario: tail-recursive call/cc loop that captures a continuation containing a letrec closure, serialize and deserialize, invoke the loaded continuation
