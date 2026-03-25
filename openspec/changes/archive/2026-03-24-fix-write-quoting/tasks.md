## Tasks

- [x] Add `$write-mode` global flag (0=display, 1=write) to control string quoting in `$write-to-string-impl`
- [x] Change `$write-to-string-impl` string branch to check `$write-mode` and call `$wts-string` when enabled
- [x] Change `write` (prim 58) to set `$write-mode=1` before converting, reset after
- [x] Change `write-to-string-flat` (prim 136) to use `$write-mode` flag instead of inline string check
- [x] Add ECE test: `write-to-string-flat` quotes strings in lists
- [x] Verify existing tests: `write-to-string` (prim 67) still returns unquoted strings
- [x] Run full test suite: 442 passed, 0 failed (410 ECE + 32 integration); CL all passed
