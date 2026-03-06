## 1. Add if-p predicate and dispatch

- [x] 1.1 Add `if-p` predicate function (matching pattern of `begin-p`, `lambda-p`)
- [x] 1.2 Add `if-p` check to `:ev-dispatch` cond clause (before `application-p`)

## 2. Implement if continuation handlers

- [x] 2.1 Implement `:ev-if` — save expr/env on stack, extract predicate, push `:ev-if-decide`, dispatch to evaluate predicate
- [x] 2.2 Implement `:ev-if-decide` — restore expr/env, check val for truthiness, branch to `:ev-if-consequent` or `:ev-if-alternative`
- [x] 2.3 Implement `:ev-if-consequent` — extract consequent (`caddr expr`), dispatch to evaluate it
- [x] 2.4 Implement `:ev-if-alternative` — extract alternative (`cadddr expr`, nil if absent), dispatch to evaluate it

## 3. Add tests

- [x] 3.1 Add `test-if-eval` deftest covering: truthy predicate takes consequent, nil predicate takes alternative, omitted alternative returns nil, computed subexpressions, and nested if
