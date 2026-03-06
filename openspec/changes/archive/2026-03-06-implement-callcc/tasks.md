## 1. Add call/cc predicate and dispatch

- [x] 1.1 Add `callcc-p` predicate function
- [x] 1.2 Add `call/cc` to `*special-forms*` list
- [x] 1.3 Add `callcc-p` check to `:ev-dispatch` cond clause
- [x] 1.4 Export `call/cc` from the `ece` package

## 2. Implement call/cc continuation handlers

- [x] 2.1 Implement `:ev-callcc` — capture continuation (copy stack + conts), push onto stack, evaluate receiver expression, push `:ev-callcc-apply`
- [x] 2.2 Implement `:ev-callcc-apply` — pop captured continuation from stack, set proc=val (receiver), argl=(continuation), push `:apply-dispatch`
- [x] 2.3 Add `continuation` type recognition in `:apply-dispatch`
- [x] 2.4 Implement `:continuation-apply` — restore stack and conts from captured continuation, set val to argument

## 3. Add tests

- [x] 3.1 Add `test-callcc-eval` deftest covering: simple return, non-local exit, call/cc in arithmetic, nested non-local exit, variable as receiver, continuation ignored
