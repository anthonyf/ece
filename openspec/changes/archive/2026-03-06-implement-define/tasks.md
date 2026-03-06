## 1. Refactor environment to frame-based representation

- [x] 1.1 Add frame helper functions: `make-frame`, `extend-environment`, `lookup-variable-value`, `define-variable!`
- [x] 1.2 Restructure `*global-env*` as a single frame containing primitives
- [x] 1.3 Replace `env-lookup` calls with `lookup-variable-value` in evaluator dispatch
- [x] 1.4 Update `compound-apply` to use `extend-environment` instead of `append`/`mapcar`
- [x] 1.5 Update `make-procedure` and procedure field accessors if needed for new env structure
- [x] 1.6 Update all tests to pass frame-based environments where explicit envs are used
- [x] 1.7 Run tests to verify refactor is green

## 2. Implement define special form

- [x] 2.1 Add `define-p` predicate, add `define` to `*special-forms*` and package exports
- [x] 2.2 Add dispatch clause for `define` in `ev-dispatch`
- [x] 2.3 Implement `ev-define` handler: detect function shorthand vs value form, save variable name and env/conts on stack, evaluate value expression
- [x] 2.4 Implement `ev-define-assign` handler: restore env/conts, call `define-variable!` on first frame, set `val`

## 3. Tests for define

- [x] 3.1 Add tests for simple value binding, expression binding, function shorthand (single/multi-param, multi-body), redefining, and named recursion (including deep tail recursion)

## 4. Documentation

- [x] 4.1 Update README.md to include `define` in supported features and add usage examples
