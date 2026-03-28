## 1. Node.js Test Runner

- [x] 1.1 Create `wasm/test.js` — loads WASM, boots bootstrap, runs test .ececb, parses "N passed, M failed", exits with code
- [x] 1.2 Test runner uses `glue.js` module, Map-based storage fallback

## 2. Makefile Targets

- [x] 2.1 Add `test-wasm` target: concatenates test .scm files, compiles to .ececb via CL, runs `node wasm/test.js`
- [x] 2.2 `make test-wasm` passes locally (329 passed, 0 failed)

## 3. GitHub Actions Workflow

- [x] 3.1 Add `make test-ece` step after rove tests
- [x] 3.2 Add binaryen install step
- [x] 3.3 Add Node.js setup step (actions/setup-node@v4, node 22)
- [x] 3.4 Add `make wasm` step
- [x] 3.5 Add `make test-wasm` step

## 4. Validation

- [x] 4.1 `make test-wasm` passes locally: 329 passed, 0 failed
- [x] 4.2 `make test-ece` passes locally: 496 passed, 0 failed
- [x] 4.3 CI workflow syntax valid
