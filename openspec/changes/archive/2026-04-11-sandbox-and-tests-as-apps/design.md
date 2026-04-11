## Context

The sandbox is built by `scripts/build-sandbox.sh` (~65 lines) which manually generates three JS files: `ece-runtime.js` (WASM + glue), `ece-bootstrap.js` (bootstrap .ecec as base64), and `ece-compiled.js` (pre-compiled "Hello World"). The WASM test suite is built by `make test-wasm` which concatenates all test .scm files into one blob, compiles it as a single space, and runs it with `node wasm/test.js`.

Both duplicate packaging logic that `ece-build --target web` now provides. The sandbox has additional handwritten files (`sandbox.js`, `index.html`, `ece-programs.js`) that provide the IDE UI — these must be preserved.

## Goals / Non-Goals

**Goals:**
- Sandbox `make sandbox` target uses `ece-build` for runtime/bootstrap packaging
- WASM tests `make test-wasm` target uses `compile-system` for multi-space test bundles
- `scripts/build-sandbox.sh` is removed
- Sandbox and test output is identical in behavior

**Non-Goals:**
- Changing the sandbox UI or adding features
- Changing which tests are included in the WASM suite
- Making `ece-build` aware of sandbox-specific overlays (keep it simple — Makefile copies files)

## Decisions

### 1. Sandbox build: `ece-build` + Makefile overlay

**Choice:** The Makefile `sandbox` target calls `ece-build --target web -o sandbox/` to generate `ece-runtime.js` and `ece-bootstrap.js`, then copies sandbox-specific files (`index.html`, `sandbox.js`, `ece-programs.js`) into the output. Pre-compiled canned programs are compiled separately using `compile-system`.

**Why not extend `ece-build` with overlay support?** Adding `--overlay` or `--template` flags to `ece-build` would couple it to the sandbox's specific needs. The Makefile is the right place for project-specific build orchestration. `ece-build` stays generic.

**Why not keep `build-sandbox.sh`?** It duplicates `ece-build`'s runtime packaging logic line-for-line. One implementation to maintain is better than two.

### 2. Sandbox canned programs: compile individually, embed as separate entries

**Choice:** Each canned program's .scm source remains in `sandbox/ece-programs.js` as source strings (for the editor). For pre-compilation, the Makefile writes each program to a temp .scm file, compiles it with `compile-file`, and embeds the .ecec as base64 in `ece-compiled.js` — same as today. Only "Hello World" is currently pre-compiled; the rest are compiled on-the-fly.

**Why not use compile-system for canned programs?** Each program is independent — they don't share definitions. A multi-space bundle implies sequential loading, which doesn't match the "pick one to run" model. Individual .ecec files keyed by name in `ECE_COMPILED` is the right shape.

### 3. WASM tests: compile-system multi-space bundle

**Choice:** Replace the concatenation approach with `compile-system`. The Makefile passes the test files (extracted from `run-common.scm`) plus `wasm-test-runner.scm` to `compile-system`, producing a single multi-space `.ecec` bundle. `wasm/test.js` uses `loadEcecBundleText` to load and execute all spaces.

**Why compile-system over concatenation?** Compile-system preserves per-file spaces and source-maps. It also proves the multi-space bundle works for a real multi-file project. Macros from `test-framework.scm` persist in the compile-time environment across files, so `check` is available to all test files.

**Concern: test file ordering.** The test framework must be compiled first so its macros (`check`, `test-group`, etc.) are available. The current ordering from `run-common.scm` already ensures this — `test-framework.scm` is loaded first.

### 4. WASM test runner: loadEcecBundleText

**Choice:** `wasm/test.js` switches from `ECE.loadEcecText(text)` + `w.run(spaceId, 0, env)` to `ECE.loadEcecBundleText(text)` which loads and executes all sections in sequence. The integration tests (op-id validation, bootstrap checks) remain unchanged.

**Why loadEcecBundleText instead of a loop?** `loadEcecBundleText` already handles the load-execute-continue loop internally. One call replaces the single-space load+run.

## Risks / Trade-offs

**[Macro persistence across compile-system files]** Compile-system compiles files sequentially with a shared compile-time macro environment. If test-framework.scm defines macros, they're available to later files. If this assumption breaks (e.g., a future change resets macros between files), tests would fail to compile. → The behavior is by design and tested; the bootstrap already relies on it.

**[Sandbox ece-build output overwrites handwritten files]** If `ece-build --target web -o sandbox/` writes `index.html`, it would clobber the handwritten sandbox `index.html`. → The Makefile must either: (a) build to a temp dir and copy only the generated files, or (b) run `ece-build` to a temp dir, then cherry-pick outputs. Option (a) is cleanest.

**[No .scm app source for sandbox]** The sandbox has no user .scm to compile — it's an IDE that compiles code at runtime. `ece-build` requires at least one .scm file. → Create a minimal `sandbox/init.scm` stub (e.g., `(void)`) or use `ece-build` only for runtime/bootstrap packaging and skip the app bundle step. The Makefile can call the internal packaging steps directly without going through `ece-build`.
