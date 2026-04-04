## Context

`ece-build --target web` currently base64-encodes the WASM binary, 6 bootstrap .ecec files, and the app bundle into JS files. This allows `file://` loading but adds size overhead and prevents streaming WASM instantiation. Bootstrap loading requires iterating over 6 named files on both CL and WASM.

The bootstrap sources compile to 7 .ecec files: prelude, compiler, reader, assembler, compilation-unit, syntax-rules, and browser-lib. CL loads 6 (skips browser-lib). WASM loads 6 (skips syntax-rules). Five are shared.

## Goals / Non-Goals

**Goals:**
- Single bootstrap bundle loaded with one call instead of a per-file loop
- Server mode for `ece-build --target web` producing raw .wasm/.ecec files
- `--standalone` flag preserving current base64-in-JS behavior for `file://`
- Integration test for server mode using `python3 -m http.server`

**Non-Goals:**
- Pre-compression of output files (CDN handles this)
- Changing the CL target packaging
- Universal bootstrap that works without any platform awareness

## Decisions

### 1. Single universal bootstrap bundle

**Choice:** `make bootstrap` uses `compile-system` to produce one `bootstrap/bootstrap.ecec` containing all 7 source files. The CL runtime skips the `browser-lib` section (which references WASM-only FFI primitives). WASM loads all sections — `syntax-rules` is pure ECE and works on both platforms.

**Why one file?** Simplifies loading from a named-file loop to one `loadEcecBundleText` call on WASM and one `load-ecec-file` call on CL. Fewer files to package, fewer HTTP requests in server mode.

**Why not two platform-specific bundles?** Adds build complexity for minimal benefit. The only difference is one section (browser-lib) that CL must skip. A skip-list in `boot-from-compiled` is simpler than maintaining two bundle definitions.

**CL skip mechanism:** `load-ecec-section` already reads the `(ecec-header (space <name>) ...)` before executing. Add a `:skip` parameter to `load-ecec-file` that checks the space name against a skip list. `boot-from-compiled` passes `'("browser-lib")`.

### 2. Server mode as default for `--target web`

**Choice:** `ece-build --target web` produces raw files by default:

```
dist/
  index.html        ← fetch()-based template
  ece-runtime.js    ← JS glue only (no embedded WASM)
  runtime.wasm      ← raw WASM binary
  bootstrap.ecec    ← single bundle (raw text)
  app.ecec          ← compiled app (raw text)
```

The HTML template uses `fetch()` for .wasm/.ecec and `WebAssembly.instantiateStreaming()` for the WASM binary.

**Why default to server mode?** Server deployment is the standard web target. Standalone/`file://` is the special case. Users who need `file://` opt in with `--standalone`.

### 3. Standalone mode with `--standalone` flag

**Choice:** `ece-build --target web --standalone` produces the current output: everything base64-encoded into .js files, loaded via `<script src>`. The template is the existing one (renamed to `templates/web/standalone.html`).

**Sandbox uses standalone:** `make sandbox` passes `--standalone` since the sandbox must work from `file://` for local development.

### 4. Integration test with python3 HTTP server

**Choice:** New `make test-web-server` target:
1. Compiles a hello-world .scm in server mode
2. Starts `python3 -m http.server` on port 0 (OS-assigned)
3. Runs a Node.js test script that `fetch()`es from localhost, instantiates WASM, boots bootstrap, runs app
4. Asserts "Hello, World!" appears in output
5. Kills the server

**Why python3?** Ubiquitous on macOS and Linux, pre-installed on CI runners, one-liner static file server. Node.js is already a project dependency but python3's HTTP server is simpler for this purpose.

**Why not headless browser?** Adds a heavy dependency (puppeteer/playwright). The Node.js test exercises the same fetch → instantiate → boot → run pipeline as a browser. The JS glue is the same code.

### 5. Bootstrap file ordering

**Choice:** The compile-system input order is: prelude, compiler, reader, assembler, compilation-unit, syntax-rules, browser-lib. This matches the existing dependency order. Macros defined in earlier files are available to later ones via the shared compile-time environment.

### 6. Individual .ecec files removed

**Choice:** `bootstrap/` contains only `bootstrap.ecec` after this change. The individual `prelude.ecec`, `compiler.ecec`, etc. are no longer produced. All consumers load the single bundle.

## Risks / Trade-offs

**[CL loads syntax-rules it previously skipped]** The CL runtime previously didn't load syntax-rules.ecec. Now it's in the bundle and will be loaded. syntax-rules is pure ECE and has no platform dependencies, so this should be harmless — it just makes `syntax-rules` available on CL (which is a feature, not a problem). → Verify in tests that CL boot still works.

**[WASM loads syntax-rules it previously skipped]** Same as above for WASM. → Verify test counts don't change.

**[Default behavior change for ece-build]** Existing `ece-build --target web` invocations will get server-mode output instead of standalone. The sandbox Makefile target is updated to pass `--standalone`, but external users who depend on the current behavior would need to add `--standalone`. → Document in README. This is a pre-1.0 tool with no stability guarantees.

**[python3 availability in CI]** GitHub Actions ubuntu-latest has python3 pre-installed. macOS runners also have it. → The test target should check for python3 and skip gracefully if not found.
