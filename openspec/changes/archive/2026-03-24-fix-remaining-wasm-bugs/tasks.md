## Tasks

### Bug 2: String quoting in write-to-string
- [x] Add `$wts-string` helper in runtime.wat that wraps a string in quotes with `\` and `"` escaping
- [x] Change `write-to-string-flat` (prim 136) to call `$wts-string` for strings; `write-to-string` (prim 67) keeps display semantics (no quoting)
- [x] Add ECE test: `write-to-string-flat` quotes strings
- [x] Add ECE test: `write-to-string` does NOT quote strings (used by interpolation)

### Bug 3: Vector equal?
- [x] Add vector case to `$prim-equal` in runtime.wat: check both vectors, compare lengths, recurse on elements
- [x] Add ECE tests: equal vectors, unequal elements, unequal lengths, nested vectors

### Bug 1: Late top-level define crash
- [ ] Investigate and fix (deferred — requires deeper analysis of global env frame growth)

### Final
- [x] Run full test suite: WASM 436 passed, 0 failed; CL all passed
