## Why

The JS glue layer (`glue.js`) contains ~100 lines of initialization logic — primitive registration, assembler symbol table setup, env bindings — that is really ECE's job. `initAssemblerSymbols()` is a hand-maintained copy of `operations.def`, creating a second source of truth. `primitives.json` is an unnecessary intermediate format: a shell script converts s-expressions to JSON so JS can read what ECE reads natively. Demo programs are stored as JS string literals wrapping Scheme source code. Every non-ECE source file is tech debt against the WASM port goal. Anything that CAN be ECE SHOULD be ECE.

## What Changes

- **Move primitive registration from JS to ECE boot code.** A new `boot-env.scm` reads `primitives.def` at compile time and calls registration primitives to bind all primitives in the global environment.
- **Move assembler symbol table setup from JS to ECE boot code.** The hand-maintained JS array in `initAssemblerSymbols()` is replaced by ECE code that reads `operations.def` at compile time.
- **Move continuation/error symbol caching and REPL space creation to ECE boot code.** These are environment setup concerns, not JS bridge concerns.
- **Add WAT registration primitives.** Thin WASM-exported functions (`%register-primitive!`, `%init-asm-syms`, `%store-asm-sym`, etc.) that ECE boot code calls instead of JS.
- **Extract sandbox demo programs to `.scm` files.** Each demo program becomes its own `.scm` file with an s-expression manifest, replacing `ece-programs.js`.
- **Eliminate `primitives.json`, `gen-primitives-json.sh`, and `transform-glue-js`.** The JSON intermediate format, the shell script that generates it, and the ece-build string surgery that patches it into glue.js all become unnecessary.
- **Move `build-test-page.sh` into `ece-build`.** The shell script orchestration becomes an ECE build target, using capabilities ece-build already has (compile, base64-encode, template).
- **Fix duplicate primitive ID 165 in `primitives.def`.** Found during exploration — `%make-primitive` appears twice.

## Capabilities

### New Capabilities
- `ece-boot-env`: ECE boot file that registers primitives, operations, and env bindings at boot time via compiled .ecec code — replacing JS initialization logic
- `wat-registration-primitives`: WAT-exported primitives for environment and assembler symbol registration, callable from ECE boot code
- `sandbox-program-manifest`: Demo programs stored as individual .scm files with an s-expression manifest, replacing JS string literals

### Modified Capabilities
- `primitive-manifest`: Fix duplicate ID 165 for `%make-primitive`
- `app-packaging`: Remove `transform-glue-js` hack and `primitives.json` dependency from ece-build; add `--target test-page` build target

## Impact

- **wasm/runtime.wat** — ~6 new exported primitives for registration
- **wasm/glue.js** — `buildGlobalEnv()` shrinks to ~15 lines; `initAssemblerSymbols()` removed entirely
- **src/boot-env.scm** (new) — ECE boot file, compiles to .ecec in bootstrap sequence
- **src/ece-build.scm** — simplified `generate-runtime-js`, new test-page target
- **sandbox/programs/*.scm** (new) — individual demo program files
- **Deleted files**: `wasm/primitives.json`, `scripts/gen-primitives-json.sh`, `sandbox/ece-programs.js`, `scripts/build-test-page.sh`
- **Makefile** — updated bootstrap sequence (boot-env.ecec before prelude), removed gen-primitives-json step
- **Bootstrap .ecec files** — regenerated with boot-env.ecec in sequence
- **CL runtime** — needs matching primitives for `%register-primitive!` etc. during two-pass bootstrap
