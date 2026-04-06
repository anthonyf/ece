## 1. Fix duplicate primitive ID

- [x] 1.1 Remove duplicate `%make-primitive` entry (ID 165) from `primitives.def`

## 2. WAT registration primitives

- [x] 2.1 Add `%register-primitive!` WAT primitive: accept symbol + fixnum ID, create primitive, define in global env
- [x] 2.2 Add `%init-asm-syms` WAT primitive: accept fixnum count, allocate assembler symbol ID array
- [x] 2.3 Add `%store-asm-sym` WAT primitive: accept fixnum slot + symbol, store symbol ID at slot
- [x] 2.4 Add `%set-continuation-syms!` WAT primitive: accept two symbols, cache for winding support
- [x] 2.5 Add `%set-error-sym!` WAT primitive: accept symbol, cache for type-error bridging
- [x] 2.6 Add `%create-repl-space!` WAT primitive: accept symbol + fixnum size, create and set current space
- [x] 2.7 Add entries for all new primitives to `primitives.def` with platform `core`

## 3. CL no-op primitives

- [x] 3.1 Add CL implementations of `%register-primitive!`, `%init-asm-syms`, `%store-asm-sym`, `%set-continuation-syms!`, `%set-error-sym!`, `%create-repl-space!` as no-ops returning void

## 4. boot-env.scm

- [x] 4.1 Create `src/boot-env.scm` with `%register-primitive!` calls for every core/browser entry in `primitives.def`
- [x] 4.2 Add `%init-asm-syms` and `%store-asm-sym` calls for all assembler symbols (instruction types, register names, source types, operations from `operations.def`)
- [x] 4.3 Add `%set-continuation-syms!` and `%set-error-sym!` calls
- [x] 4.4 Add `%create-repl-space!` call
- [x] 4.5 Add `#t` and `#f` variable definitions
- [x] 4.6 Verify boot-env.scm uses only primitive forms (no macros, no prelude dependencies)

## 5. Bootstrap sequence update

- [x] 5.1 Update `BOOTSTRAP_SRCS` in Makefile to include `src/boot-env.scm` as first file
- [x] 5.2 Run two-pass bootstrap: first pass with old .ecec + new CL primitives, second pass with boot-env.ecec in bundle
- [x] 5.3 Verify CL runtime boots correctly with boot-env.ecec executing (no-op primitives)

## 6. Strip glue.js

- [x] 6.1 Remove primitive registration loop (`require("./primitives.json")` and for-loop) from `buildGlobalEnv()`
- [x] 6.2 Remove `initAssemblerSymbols()` function and its call from `buildGlobalEnv()`
- [x] 6.3 Remove continuation/error symbol caching (`set_do_winds_sym`, `set_winding_stack_sym`, `set_error_sym`) from `buildGlobalEnv()`
- [x] 6.4 Remove REPL space creation (`create_space`, `set_current_space`) from `buildGlobalEnv()`
- [x] 6.5 Remove `#t`/`#f` env defines from `buildGlobalEnv()`
- [x] 6.6 Keep `module.exports` (test harnesses still require glue.js via CommonJS)
- [x] 6.7 Update `buildGlobalEnv()` to pass `0` to `build_global_env` (no pre-allocated primitive slots needed — boot-env handles it)

## 7. Eliminate JSON/shell intermediaries

- [x] 7.1 Delete `wasm/primitives.json`
- [x] 7.2 Delete `scripts/gen-primitives-json.sh`
- [x] 7.3 Remove `primitives.json` references from Makefile (copy to share/ece, install target)
- [x] 7.4 Remove `transform-glue-js` function from `src/ece-build.scm`
- [x] 7.5 Simplify `generate-runtime-js` in ece-build.scm to not read/inline primitives.json

## 8. Demo programs as .scm files

- [x] 8.1 Create `sandbox/programs/` directory
- [x] 8.2 Extract each demo program from `ece-programs.js` into individual `.scm` files
- [x] 8.3 Create `sandbox/programs/manifest.sexp` listing all programs
- [x] 8.4 Update sandbox build step in Makefile to generate ece-programs.js from .scm files
- [x] 8.5 Delete `sandbox/ece-programs.js` (now auto-generated, added to .gitignore)
- [x] 8.6 sandbox/index.html unchanged — still loads ece-programs.js, now auto-generated

## 9. build-test-page as ece-build target

- [x] 9.1 Create HTML template at `templates/web/test-page.html` (test runner UI with JS)
- [x] 9.2 Add `--target test-page` handling to `ece-build-main` in ece-build.scm
- [x] 9.3 Implement test page build: compile test .scm files, base64-encode, inline into template
- [x] 9.4 Update Makefile `site` target to use `ece-build --target test-page` instead of `bash scripts/build-test-page.sh`
- [x] 9.5 Delete `scripts/build-test-page.sh`

## 10. Validation

- [x] 10.1 Run CL test suite (`make test-rove test-ece`) — 753 passed, 0 failed
- [x] 10.2 Run WASM test suite (`make test-wasm`) — 609 passed, 0 failed
- [x] 10.3 Run conformance tests (`make test-conformance`) — 162 passed, 0 failed
- [x] 10.4 Run web app tests (`make test-web-apps test-web-server`) — all pass
- [x] 10.5 Build and test sandbox (`make sandbox`) — programs generated from .scm files
- [x] 10.6 Build and test site (`make site`) — test page built via ece-build
- [x] 10.7 Verify `make bootstrap` two-pass works cleanly
