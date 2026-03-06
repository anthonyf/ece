## 1. Add environment operation

- [x] 1.1 Add `set-variable-value!` function that scans all frames to update an existing binding, signaling an error if unbound

## 2. Implement set continuation handlers

- [x] 2.1 Add dispatch clause for `set` in `ev-dispatch` (using existing `assignment-p`)
- [x] 2.2 Implement `ev-assignment` handler: save variable name, env, and conts on stack, evaluate value expression
- [x] 2.3 Implement `ev-assignment-assign` handler: restore state, call `set-variable-value!`, set `val`

## 3. Tests

- [x] 3.1 Add tests for set: update defined variable, computed value, return value, unbound error, enclosing scope update, closure mutation counter pattern
