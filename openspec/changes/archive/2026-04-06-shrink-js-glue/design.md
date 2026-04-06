## Context

`glue.js` serves as the JS↔WASM bridge for ECE's browser runtime. Over time it accumulated initialization logic that belongs in ECE, not JS: primitive registration (reading `primitives.json`), assembler symbol setup (hand-maintained copy of `operations.def`), continuation/error symbol caching, and REPL space creation. The CL runtime already reads `.def` files directly via `cl:read` — the WASM path should follow the same pattern, but using ECE's reader.

The bootstrap sequence today:

```
JS: init()           → instantiate WASM
JS: buildGlobalEnv() → create env frame, register primitives from JSON,
                        cache singletons, init asm symbols, set global env,
                        cache continuation/error syms, create REPL space
JS: bootstrap()      → load bootstrap.ecec bundle (prelude, compiler,
                        reader, assembler, compilation-unit, syntax-rules,
                        browser-lib)
```

The CL side has a cleaner model: `init-primitive-dispatch-tables` reads `primitives.def` at load time via `cl:read`, `build-global-env-from-manifest` creates the env, and the bootstrap `.ecec` files load afterward.

Current non-ECE source files targeted for elimination or reduction:
- `wasm/primitives.json` — generated JSON intermediate
- `scripts/gen-primitives-json.sh` — awk script generating that JSON
- `sandbox/ece-programs.js` — Scheme source stored as JS strings
- `scripts/build-test-page.sh` — shell build orchestration
- ~100 lines in `glue.js` — init logic that moves to ECE

## Goals / Non-Goals

**Goals:**
- Move primitive registration, operation/assembler symbol setup, continuation/error symbol caching, and REPL space creation from JS into ECE boot code
- Eliminate `primitives.json` as an intermediate format and `gen-primitives-json.sh` as a build step
- Eliminate hand-maintained operations array in `initAssemblerSymbols()` — single source of truth via `.def` files
- Extract sandbox demo programs from JS string literals to `.scm` files
- Move `build-test-page.sh` orchestration into `ece-build`
- Shrink `glue.js` to only irreducible JS↔WASM bridge concerns (instantiation, I/O imports, FFI, value marshalling)
- Fix duplicate primitive ID 165 in `primitives.def`

**Non-Goals:**
- Eliminating `glue.js` entirely — WASM instantiation, I/O imports, FFI bridge, and value marshalling genuinely require JS
- Eliminating `sandbox.js` — DOM/canvas interaction requires JS (future `browser-lib.scm` improvements may reduce it, but that's a separate change)
- Eliminating WASM test harnesses (`test.js`, `test-server-mode.js`, `test-web-apps.js`) — these run ECE tests from Node.js and need JS to orchestrate
- Changing how the CL runtime reads `.def` files — it already does it correctly

## Decisions

### 1. boot-env.scm reads .def files at compile time, not runtime

**Decision:** `boot-env.scm` contains literal data derived from `primitives.def` and `operations.def`, baked in at compile time when `compile-file` produces `boot-env.ecec`.

**Rationale:** WASM boot has no filesystem access to read `.def` files. The `.ecec` format already supports constant data. By reading `.def` files at compile time (via `include` or `load`-time `read`), the primitive IDs and names become instruction constants in the `.ecec`. The `.def` files remain the single source of truth — they're consumed by ECE's compiler rather than by awk.

**Alternative considered:** Have boot-env.scm `(read)` the .def files at runtime. Rejected because WASM has no filesystem in the browser, and even on CL, having the data baked into `.ecec` is simpler and faster.

**Implementation:** Use quoted literal data in boot-env.scm that mirrors the .def files. A compile-time `(include "primitives.def")` or pre-processing step reads the .def and emits the data as ECE constants. The simplest approach: boot-env.scm contains `(define *primitive-manifest* '((0 + 2 core) (1 - 2 core) ...))` generated from primitives.def. This generation happens once during bootstrap, not at runtime.

### 2. New WAT primitives for registration, not new WASM exports

**Decision:** Add ECE-callable primitives (entries in `primitives.def`) rather than raw WASM exports for the registration functions.

**Rationale:** ECE boot code calls primitives via `(apply-primitive-procedure (primitive N) args)`. The existing WASM exports (`h_primitive`, `env_define`, `init_asm_syms`, `store_asm_sym`) are handle-based JS-facing APIs. The ECE-facing primitives operate on ECE values directly (symbols, fixnums), avoiding handle allocation overhead.

New primitives:
- `%register-primitive!` (name-symbol id) → defines `(primitive id)` as `name` in the current global env
- `%init-asm-syms` (count) → allocates the assembler symbol ID array
- `%store-asm-sym` (slot name-symbol) → stores symbol ID at slot
- `%set-continuation-syms!` (do-winds-sym winding-stack-sym) → caches continuation support symbols
- `%set-error-sym!` (error-sym) → caches error symbol for primitive type-error bridging
- `%create-repl-space!` (name-symbol size) → creates and activates default compilation space

### 3. boot-env.scm loads after reader but before prelude

**Decision:** Insert `boot-env.scm` into the bootstrap sequence between `compilation-unit.scm` and `prelude.scm`.

**Rationale:** boot-env.scm needs the reader/compiler to be available (it's compiled into `.ecec`), but prelude.scm depends on primitives being registered in the environment. Current bootstrap order:

```
prelude → compiler → reader → assembler → compilation-unit → syntax-rules → browser-lib
```

New order:

```
prelude → compiler → reader → assembler → compilation-unit → boot-env → syntax-rules → browser-lib
```

Wait — prelude is first because it defines fundamental forms. But prelude itself uses primitives that must already be in the env. Today, JS registers all primitives *before* loading any bootstrap file. With this change, `boot-env.ecec` must execute *before* prelude to register primitives.

**Revised approach:** boot-env.ecec loads as the *first* unit in the bootstrap bundle, before prelude. It uses only primitive calls (no macros, no prelude functions). This is fine because it's just a series of `(%register-primitive! 'name id)` calls — no complex ECE forms needed.

```
boot-env → prelude → compiler → reader → assembler → compilation-unit → syntax-rules → browser-lib
```

On the JS side, `buildGlobalEnv()` still creates the empty env frame, caches JS-side singletons, and calls `set_global_env`. Then `bootstrap()` loads boot-env.ecec first, which populates the env with primitives before any other .ecec unit runs.

### 4. CL runtime gets matching primitives for two-pass bootstrap

**Decision:** Add CL implementations of `%register-primitive!`, `%init-asm-syms`, etc. as no-ops or thin wrappers.

**Rationale:** During `make bootstrap`, the CL runtime executes boot-env.ecec. The CL runtime already initializes primitives via `init-primitive-dispatch-tables` before loading any `.ecec`, so the registration calls in boot-env.ecec are redundant on CL — they can be no-ops. This avoids the two-pass bootstrap pitfall: old `.ecec` files don't contain these calls, so the first bootstrap pass works fine; the new `.ecec` files contain them but they're harmless on CL.

### 5. Demo programs as .scm files with sexp manifest

**Decision:** Each demo program is a standalone `.scm` file in `sandbox/programs/`. A manifest file `sandbox/programs/manifest.sexp` lists them.

**Rationale:** Scheme source code should live in `.scm` files, not JS string literals. The manifest is s-expression format because ECE reads it natively. `ece-build` (or the sandbox build step) reads the manifest, loads each `.scm` file as text, and emits whatever the sandbox needs (JS constant, inline data, etc.).

Manifest format:
```scheme
((name "Hello World" file "hello-world.scm")
 (name "Game Loop" file "game-loop.scm")
 (name "Starfield" file "starfield.scm")
 ...)
```

### 6. build-test-page becomes ece-build --target test-page

**Decision:** Extend `ece-build` with a `--target test-page` option that replaces `scripts/build-test-page.sh`.

**Rationale:** `ece-build` already has all the capabilities: compile `.scm` → `.ecec`, base64-encode files, template HTML. The shell script duplicates this logic with `cat`, `base64`, `sed`. The only extra piece is the HTML template with inline test runner JS — that becomes a template file like the existing `templates/web/standalone.html`.

## Risks / Trade-offs

**[Bootstrap ordering sensitivity]** → boot-env.ecec must be first in the bundle. Validate by running full test suite (CL + WASM + conformance) after the change. The Makefile's `BOOTSTRAP_SRCS` list controls ordering.

**[Two-pass bootstrap during migration]** → First `make bootstrap` uses old `.ecec` files (no boot-env). Second pass includes boot-env.ecec. CL no-op primitives ensure the new .ecec files work on both passes. Test both passes explicitly.

**[boot-env.scm has no macros available]** → It loads before prelude, so no `let`, `when`, `cond`, etc. Must use only primitive forms: `define`, `begin`, `if`, `set!`, lambda. This is fine for a file that's mostly `(%register-primitive! 'name id)` calls, but requires care.

**[Primitive count increase]** → ~6 new primitives in both WAT and CL. Net code reduction overall (eliminates ~100 lines JS + shell), but increases the primitive manifest slightly. These are internal bootstrapping primitives (prefixed with `%`), not user-facing.

**[Sandbox program loading changes]** → The sandbox currently loads `ece-programs.js` via `<script src>`. With `.scm` files, the build step must inline program source text. `ece-build --target web --standalone` already inlines everything — this is consistent with that approach.
