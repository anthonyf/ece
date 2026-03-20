## 1. Compiler

- [x] 1.1 Change `mc-assignment?` in `compiler.scm` to accept both `set!` and `set` (backward compat)
- [x] 1.2 Add `set!` to `*mc-special-forms*` list (keep `set` for transition)

## 2. Source Files

- [x] 2.1 Replace all `(set var val)` with `(set! var val)` in `prelude.scm`
- [x] 2.2 Replace all `(set var val)` with `(set! var val)` in `reader.scm`
- [x] 2.3 Replace `(set mc-label-counter ...)` with `(set! ...)` in `compiler.scm`
- [x] 2.4 Update `letrec` macro expansion in `prelude.scm` to emit `set!`

## 3. Tests

- [x] 3.1 Update CL-side tests that use `(set var val)` to `(set! var val)`
- [x] 3.2 Update all ECE native test files that use `(set var val)`

## 4. Runtime & Bootstrap

- [x] 4.1 Export `set!` from `:ece` package
- [x] 4.2 Two-pass bootstrap: pass 1 with `set` source, pass 2 with `set!` source
- [x] 4.3 Run full test suite (492 native + CL-side all pass)
