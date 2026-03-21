## Context

The CI workflow runs on Ubuntu with SBCL + qlot. Adding WASM tests requires binaryen (`wasm-as`) and Node.js. Both are easily installable via apt/actions.

## Goals / Non-Goals

**Goals:**
- All 3 test suites run in CI on every PR
- Clear pass/fail reporting with exit codes
- Fast enough for PR feedback (<5 minutes total)

**Non-Goals:**
- Browser-based WASM testing (Node.js is sufficient)
- Performance benchmarks in CI

## Decisions

### 1. Compile tests at CI time (not pre-compiled)

CI compiles the test `.scm` files to `.ececb` using the CL host, then runs them on the WASM host. This ensures tests are always compiled against the current compiler and converter. No stale artifacts.

### 2. Single workflow with sequential steps

All three test suites run in the same job sequentially. This avoids duplicating SBCL/qlot setup. The WASM tests add ~30 seconds (compile + run), well within budget.

```
CI Pipeline:
  1. Install SBCL + qlot + binaryen + Node.js
  2. qlot install
  3. Run CL rove tests              (~10s)
  4. Run ECE self-hosted tests       (~60s)
  5. make wasm                       (~1s)
  6. make test-wasm                  (~30s)
     a. Compile wasm-tests.scm → .ececb
     b. node wasm/test.js
```

### 3. wasm/test.js — standalone Node.js runner

A self-contained script that:
- Loads `wasm/runtime.wasm`
- Boots all 5 bootstrap `.ececb` files
- Loads the test `.ececb`
- Captures output, parses "N passed, M failed"
- Exits with code 0 on success, 1 on failure

This script reuses the `glue.js` module but adds test-specific orchestration.

### 4. make test-wasm target

```makefile
test-wasm: wasm
	# Concatenate common tests + wasm runner into one file
	# Compile to .ececb via CL host
	# Run via Node.js
```

The Makefile target handles the full pipeline so developers can run `make test-wasm` locally too.

### 5. Wasm test file

A `wasm/wasm-tests.scm` file that concatenates the test framework + all common test files + the direct-thunk runner. This is compiled to `.ececb` at test time.
