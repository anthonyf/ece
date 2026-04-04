## 1. Multi-space .ecec bundle format

- [x] 1.1 Add `compile-system` function to `compilation-unit.scm`: takes list of .scm filenames + output path, calls compile-file logic for each, writes all sections to one file
- [x] 1.2 Add `load-bundle` function to `compilation-unit.scm`: reads .ecec file, loops loading sections until EOF
- [x] 1.3 Update CL `load-ecec-file` to support multi-space bundles (loop until EOF)
- [x] 1.4 Update WASM `load_ecec` to support multi-space bundles (caller loops, or internal loop)

## 2. ece-build shell script

- [x] 2.1 Create `bin/ece-build` shell script with argument parsing (`--target web|cl`, `-o <dir>`, source files)
- [x] 2.2 Implement ECE_HOME resolution (relative to script location)
- [x] 2.3 Implement compilation step: boot ECE via `qlot exec sbcl`, call `compile-system`
- [x] 2.4 Implement input validation (missing files, missing target, usage message)

## 3. Web target packaging

- [x] 3.1 Create `templates/web/index.html` with `<script src>` loading for runtime, bootstrap, and app
- [x] 3.2 Implement web packaging in `ece-build`: generate `ece-runtime.js` (WASM binary base64 + glue)
- [x] 3.3 Implement web packaging: generate `ece-bootstrap.js` (bootstrap .ecec as JS data)
- [x] 3.4 Implement web packaging: generate `app.js` (user .ecec bundle as JS data)
- [x] 3.5 Verify web output opens and runs in browser via `file://` protocol

## 4. CL target packaging

- [x] 4.1 Create `templates/cl/run.lisp` boot script template
- [x] 4.2 Implement CL packaging in `ece-build`: copy `runtime.lisp`, `bootstrap/`, app bundle, generate `run.lisp`
- [x] 4.3 Verify CL output runs with `sbcl --load dist/run.lisp`

## 5. Bootstrap and tests

- [x] 5.1 Two-pass bootstrap with new `compile-system` / `load-bundle` functions
- [x] 5.2 Test: compile-system produces valid multi-space bundle
- [x] 5.3 Test: load-bundle loads all spaces in order
- [x] 5.4 Test: load-bundle registers source-maps for each space
- [x] 5.5 Test: load-compiled still works for single-space files
- [x] 5.6 Test: cross-space function calls work after load-bundle
- [x] 5.7 Test: ece-build web target produces runnable output
- [x] 5.8 Test: ece-build cl target produces runnable output
- [x] 5.9 Run all existing test suites (rove, ECE, conformance, WASM) — no regressions
