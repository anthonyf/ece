## 1. Add comint output filter

- [x] 1.1 In `emacs/geiser-ece.el`, add `geiser-ece--output-filter` to `comint-preoutput-filter-functions`.
- [x] 1.2 The filter should attempt to parse each output chunk as an alist with `read-from-string`.
- [x] 1.3 If parsed successfully and has `result`/`output` keys: extract and reformat.
- [x] 1.4 If `output` field is non-empty, prepend it before the result.
- [x] 1.5 If result is empty string, display nothing (void return like `define`).
- [x] 1.6 If parse fails, pass through raw output unchanged.
- [x] 1.7 Register the filter in `geiser-ece--startup` (REPL startup hook).

## 2. Test in emacs (user-driven)

- [x] 2.1 User reloads `geiser-ece.el`, restarts Geiser REPL.
- [x] 2.2 `(+ 1 2)` shows `3` in REPL.
- [x] 2.3 `(begin (display "hello") 42)` shows `hello` then `42`.
- [x] 2.4 `(define (square x) (* x x))` shows clean output.
- [x] 2.5 Completions (`C-M-i`) still work after filter is added.
- [x] 2.6 Verify `C-x C-e` still works from `.scm` buffers.

## 3. Commit and PR

- [ ] 3.1 Code-reviewer subagent pass.
- [ ] 3.2 Archive the change.
- [ ] 3.3 Commit and open PR.
