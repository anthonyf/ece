## Tasks

- [x] Change named-let macro in `src/prelude.scm` to expand to `(letrec ((name (lambda (vars...) body...))) (name inits...))` instead of `(begin (define (name vars...) body...) (name inits...))`
- [x] Verify the letrec expansion doesn't re-trigger the named-let path (letrec uses regular let with a binding list, not a symbol)
- [x] Regenerate bootstrap: `make bootstrap`
- [x] Run CL tests: `qlot exec sbcl --eval '(asdf:test-system :ece)' --quit`
- [x] Run WASM tests: `make test-wasm`
- [x] Add ECE test: named-let as argument to function call (the pattern that crashed before)
- [x] Add ECE test: named-let with hoisted define in enclosing scope
- [x] Note: Bug 3 (late top-level define crash) is a separate frame-append/global-env issue, not named-let related — filed as known limitation
