## Context

The `"ece"` ASDF system currently loads three CL files: `runtime.lisp`, `readtable.lisp`, and `boot.lisp`. The readtable provides `*ece-readtable*` — a customized CL readtable with ECE syntax (`#t`/`#f`, quasiquote, `{}`, `$"..."`) — but this is never used at runtime. The ECE reader (`reader.scm`) in the image handles all user-facing reading. The only consumer is the test suite's `ece-eval-string` helper. `boot.lisp` is 49 lines that load the image and define `evaluate`/`repl`.

## Goals / Non-Goals

**Goals:**
- Reduce the `"ece"` ASDF system to a single CL file: `runtime.lisp` (which loads the image)
- Eliminate the test suite's dependency on `*ece-readtable*`
- Keep `readtable.lisp` and `compiler.lisp` available in `"ece/cold"` for cold bootstrap

**Non-Goals:**
- Changing the cold boot path (`ece/cold`)
- Rewriting the test suite beyond what's needed to drop the readtable dependency
- Modifying the ECE reader or compiler

## Decisions

**Decision 1: Route `ece-eval-string` through `mc-eval` calling the ECE reader**

The new `ece-eval-string` will call `mc-eval` with an expression that uses the ECE reader to parse the source string:

```lisp
(defun ece-eval-string (source)
  (mc-eval (list 'eval
                 (list 'read (list 'open-input-string source)))))
```

This calls `mc-eval` (already in runtime.lisp) which invokes `mc-compile-and-go` in the image. The expression `(eval (read (open-input-string source)))` uses the ECE reader to parse and ECE eval to execute.

*Alternative considered*: Exposing a dedicated CL-callable `ece-read-from-string` primitive. Rejected — adds a new primitive to the kernel when we're trying to shrink it.

**Decision 2: Convert `#f`/`#t` tests to string-based**

Tests that use `(evaluate '#f)` or `#f` in quoted s-expressions will be converted to `(ece-eval-string "#f")`. CL's reader doesn't know `#f`, so these tests only worked because the readtable was loaded. Converting to strings makes the dependency explicit and routes through the ECE reader.

**Decision 3: Merge boot.lisp into runtime.lisp**

The image load call and `evaluate`/`ece-try-eval`/`repl` definitions move to the bottom of `runtime.lisp`, after all primitive definitions. This is a direct cut-paste — no logic changes.

**Decision 4: `ece-eval-string` lives in tests, not runtime**

The `ece-eval-string` helper is a test utility, not a runtime function. It stays in `tests/ece.lisp`. The runtime provides `mc-eval` which is the general-purpose entry point.

## Risks / Trade-offs

**Risk: ECE reader differs from CL readtable in edge cases** — Some tests may behave differently if the ECE reader parses syntax slightly differently than the CL readtable did. Mitigation: Run the full test suite after migration; any differences are bugs in the ECE reader that should be fixed regardless.

**Risk: `mc-eval` not available before image load** — `ece-eval-string` depends on the image being loaded. Mitigation: This is already the case — `evaluate` also depends on the image. Tests run after `(asdf:load-system :ece)` which loads the image.

**Trade-off: String-based tests are slightly less ergonomic** — `(ece-eval-string "(+ 1 2)")` is more verbose than `(evaluate '(+ 1 2))`. Accepted — only tests needing ECE-specific syntax use it; the majority stay as quoted s-expressions.
