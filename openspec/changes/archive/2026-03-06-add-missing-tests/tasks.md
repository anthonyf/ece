## 1. Begin Tests

- [x] 1.1 Add `test-begin-eval` deftest with scenarios: single expression, multiple expressions, and expressions with computation

## 2. String Self-Evaluation Tests

- [x] 2.1 Add `test-string-self-eval` deftest verifying strings like `"hello"` and `""` evaluate to themselves

## 3. Primitive Procedure Tests

- [x] 3.1 Add `test-division` deftest verifying `(/ 10 2)` evaluates to `5`
- [x] 3.2 Add `test-comparison-primitives` deftest verifying `=`, `<`, `>`, `<=`, `>=`
- [x] 3.3 Add `test-list-primitives` deftest verifying `cons`, `car`, `cdr`, `list`, `null?`, `not`

## 4. Advanced Lambda Tests

- [x] 4.1 Add `test-multi-body-lambda` deftest verifying lambda with multiple body expressions returns the last value
- [x] 4.2 Add `test-nested-application` deftest verifying nested function calls like `(+ (* 2 3) (- 10 4))`

## 5. Error Case Tests

- [x] 5.1 Add `test-zero-arg-application` deftest verifying `(list)` returns `nil`
- [x] 5.2 Add `test-unknown-expression-error` deftest verifying that unrecognized expression types signal an error
