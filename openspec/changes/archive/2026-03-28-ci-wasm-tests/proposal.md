## Why

CI only runs CL rove tests (~20 tests). Two larger test suites — ECE self-hosted (496 tests) and WASM (329+ tests) — have no CI coverage. PRs can break either without detection.

## What Changes

- GitHub Actions workflow gains ECE self-hosted tests (`make test-ece`) and WASM tests (`make test-wasm`)
- New `wasm/test.js` Node.js test runner script
- New `make test-wasm` Makefile target (compiles tests to .ececb, runs via Node.js)
- CI installs binaryen and Node.js for WASM steps

## Capabilities

### New Capabilities
- `ci-wasm-tests`: WASM test suite runs in GitHub Actions CI
- `ci-ece-tests`: ECE self-hosted test suite runs in GitHub Actions CI

### Modified Capabilities
- `ci-test-exit-code`: Workflow expanded from 1 test job to 3 test suites

## Impact

- **.github/workflows/test.yml**: additional steps for binaryen, Node.js, test-ece, test-wasm
- **wasm/test.js**: new ~80 line Node.js test runner
- **Makefile**: new `test-wasm` target
- **No code changes to runtime or prelude**
