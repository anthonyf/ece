## Tasks

- [x] Replace existing type-only serialization tests in `wasm/test.js` with semantic round-trip tests using `equal?`
- [x] Add in-memory round-trip tests for: fixnum, string, symbol, #t, #f, nil, dotted pair, proper list, nested list, vector
- [x] Add file-based `save-continuation!` / `load-continuation` round-trip tests for list and nested structure
- [x] Add shared-structure round-trip test (value appearing multiple times in a tree)
- [x] Add compiled-procedure round-trip test (serialize lambda, deserialize, verify callable)
- [x] Add continuation round-trip test (capture with call/cc, save, load, invoke) — mark as skip if not yet working
- [x] Run full test suite (`make test-wasm`) and verify all tests pass
