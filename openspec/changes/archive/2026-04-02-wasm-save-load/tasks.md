## Completed (already on main)

- [x] 1.1-1.4 Type predicate primitives (155-157)
- [x] 2.1-2.4 Type accessor primitives (158-162)
- [x] 3.1-3.4 Reconstruction primitives (163-165)
- [x] 4.1-4.3 Identity hash tables on WASM (116-118)
- [x] 5.1-5.3 Helper primitives (121, 138-140)
- [x] 6.1-6.3 Serializer/deserializer updated in prelude.scm
- [x] 8.1-8.2 Tests pass on CL and WASM

## 7. Add standard Scheme save/load API

- [x] 7.1 Add `(save filename obj)` — serialize obj to file via call-with-output-file
- [x] 7.2 Add `(load-saved filename)` — deserialize from file via call-with-input-file
- [x] 7.3 Add `(save-continuation! filename)` — capture current continuation and save it
- [x] 7.4 Verify round-trip on CL: save + load-saved for atoms, lists, vectors, lambdas
- [x] 7.5 Verify round-trip on WASM: atoms, lists, vectors, lambdas all pass
- [x] 7.6 Run `make bootstrap` and full test suites — CL all pass, WASM 33/0
- [x] 7.7 Fix continuation deserialization on WASM — added missing `cdddr`/`cadddr` to prelude, fixed `%ser/primitive` numeric ID handling
- [x] 7.8 Fix CL I/O wrappers (display, write, newline) to accept optional port argument (R7RS)
