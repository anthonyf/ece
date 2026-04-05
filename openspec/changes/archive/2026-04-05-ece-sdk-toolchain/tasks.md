## 1. New host primitives (kept minimal — each is a one-line CL wrapper)

- [x] 1.1 Add `command-line` primitive in `runtime.lisp` — `(coerce sb-ext:*posix-argv* 'list)`. Returns ECE list of strings. No logic.
- [x] 1.2 Add `exit` primitive in `runtime.lisp` — accepts 0-arg, integer, `#t`, or `#f` per R7RS; calls `sb-ext:exit` with appropriate code. No logic beyond the R7RS arg→code mapping.
- [x] 1.3 Add `get-environment-variable` primitive in `runtime.lisp` — calls `sb-ext:posix-getenv`; returns string or `#f`.
- [x] 1.4 Add `%exe-path` primitive in `runtime.lisp` — returns the running executable's resolved path via `sb-ext:*runtime-pathname*` (or equivalent).
- [x] 1.5 Add `%list-directory` primitive in `runtime.lisp` — lists filenames in a directory as an ECE list of strings.
- [x] 1.6 Add `%file-exists?` primitive in `runtime.lisp` — `probe-file` wrapper returning boolean.
- [x] 1.7 Register all six primitives in `primitives.def` with stable IDs.
- [x] 1.8 Add WAT stubs in `wasm/runtime.wat` (`command-line` → `("browser")`, `exit` → throw, `get-environment-variable` → `#f`, `%exe-path` → `""`, `%list-directory` → error, `%file-exists?` → `#f`).
- [x] 1.9 Run `make wasm` to rebuild `wasm/runtime.wasm`.
- [x] 1.10 Audit: confirm no new CL code beyond these primitives has been added to runtime.lisp. Any helper logic belongs in ECE.

## 2. Bootstrap pass 1 (primitives available)

- [x] 2.1 Run `make bootstrap` to regenerate `.ecec` files with the new primitives in the manifest.

## 3. ECE source files (all dispatcher + tool logic in pure ECE)

- [x] 3.1 Create `src/sdk-lib.scm`: pure-ECE path helpers (`basename`, `dirname`, `path-join`, `ends-with?`, `has-extension?`) and argument-parsing helpers (`parse-long-opt`, `parse-short-opt`, `split-on` etc.) as string operations only.
- [x] 3.2 Create `src/ece-main.scm`: define `*ece-version*` constant; implement `ece-home` procedure using `%exe-path` + `get-environment-variable` + path helpers from sdk-lib.
- [x] 3.3 Implement argv parsing in `src/ece-main.scm` — recognize `--load`, `-e/--eval`, `-i/--interactive`, `--`, `-h/--help`, `-V/--version`; return a list of execution steps in order.
- [x] 3.4 Implement argv[0] dispatch in `src/ece-main.scm` — read `(basename (car (command-line)))`, cond on tool name, call tool entry point with the rest of argv.
- [x] 3.5 Implement `ece-default-main` in `src/ece-main.scm` — processes load/eval/file steps in argv order, then either REPL (if `-i`) or exit.
- [x] 3.6 Implement `ece-repl-main` in `src/ece-main.scm` — loads any files, then always enters REPL.
- [x] 3.7 Implement `.ecec` file detection and direct loading in `ece-default-main` (distinct from `.scm` read-and-eval path). Detection is by filename extension — string op, no new primitive.
- [x] 3.8 Confirm no tool logic leaked into CL: `ece-main.scm` + `sdk-lib.scm` are self-contained except for the host primitives from §1.

## 4. Port ece-build to ECE

- [x] 4.1 Create `src/ece-build.scm`: port argument parsing from `bin/ece-build` shell script.
- [x] 4.2 Implement `--target web` packaging in ECE — generate ece-runtime.js, ece-bootstrap.js, app.js, index.html copies (standalone and server modes).
- [x] 4.3 Implement `--target cl` packaging in ECE — generate `app.ecec` and a `run` shell wrapper that `exec`s `ece` on the bundle.
- [x] 4.4 Implement file I/O helpers as needed (file copy, base64-encode-file) as ECE procedures, adding host primitives only if strictly necessary.
- [x] 4.5 Verify parity with existing `bin/ece-build` by running both against a sample project and diffing output trees.

## 5. Test runner (pure ECE)

- [x] 5.1 Create `src/test-lib.scm`: `test` registration, `assert-equal`, `assert-true`, `assert-false`, `assert-error`, `assert-error-message`, `run-tests`. State in parameter objects (not globals).
- [x] 5.2 Create `src/ece-test.scm`: argument parsing (via sdk-lib helpers), test file discovery using `%list-directory` + name filter (string op), per-file fresh-env load, per-test output capture via `with-output-to-string`, reporting, exit codes (0/1/2). All logic in ECE.

## 6. Bootstrap pass 2 (ECE source files available)

- [x] 6.1 Run `make bootstrap` to ensure `src/ece-main.scm` et al. compile cleanly through the self-hosted path.
- [x] 6.2 Verify that directly loading `src/ece-main.scm` at an in-tree REPL exposes the dispatcher and runs the test argv paths end-to-end.

## 7. Build tooling (minimal CL)

- [x] 7.1 Create `scripts/build-ece-binary.lisp`: loads `:ece` system (boots from bootstrap.ecec), then invokes `sb-ext:save-lisp-and-die` with a `:toplevel` closure.
- [x] 7.2 Write the `:toplevel` closure in 3-5 lines — only role is to call `ece:evaluate` on an ECE expression that loads `$ECE_HOME/ece-main.ecec` and invokes `(ece-main (command-line))`. No argv parsing in CL.
- [x] 7.3 Compile `src/ece-main.scm` → `ece-main.ecec` during `make ece` (or `make install`) so it can be loaded by the `:toplevel` shim at runtime.
- [x] 7.4 Verify `bin/ece -V` works after `save-lisp-and-die`.
- [x] 7.5 Verify `bin/ece -e "(+ 1 2)"` produces `3`.
- [x] 7.6 Audit the CL-side `scripts/build-ece-binary.lisp` — confirm it contains only the `asdf:load-system` + `save-lisp-and-die` invocation + the minimal `:toplevel` shim. No logic.

## 8. Makefile targets

- [x] 8.1 Add `make ece` target: runs `scripts/build-ece-binary.lisp`, creates in-tree symlinks `bin/ece-repl`, `bin/ece-build`, `bin/ece-test` → `bin/ece`.
- [x] 8.2 Add `make install` target: `PREFIX?=/usr/local`, `DESTDIR?=""`, installs binary + symlinks + share/ece/ tree.
- [x] 8.3 Add `make uninstall` target: removes everything install placed.
- [x] 8.4 Update default `make` target to depend on `make ece`.
- [x] 8.5 Add `bin/ece` and `bin/ece-*` symlinks to `.gitignore` (binary artifact, don't commit).

## 9. Remove shell script

- [x] 9.1 Delete `bin/ece-build` shell script.
- [x] 9.2 Grep for references to `bin/ece-build` in the repo (Makefile, README, other scripts) and update to point at `bin/ece-build` (now a symlink) or document the change.

## 10. Templates

- [x] 10.1 Replace `templates/cl/run.lisp` with `templates/cl/run.sh` — shell wrapper that `exec`s `ece` on the bundled `.ecec`.
- [x] 10.2 Mark `templates/cl/run.sh` executable.
- [x] 10.3 Update `ece-build.scm` `--target cl` to copy `run.sh` and set executable bit on the output.

## 11. Tests

- [x] 11.1 Create `tests/ece/test-ece-main-args.scm` covering argv parsing (positional, `--load`, `-e`, `-i`, `--`, `-V`, `-h`, unknown flags).
- [x] 11.2 Create `tests/ece/test-ece-test-runner.scm` covering the runner with synthetic test files (pass, fail, runner error, isolation, output capture, verbose mode).
- [x] 11.3 Add CL-side integration test (`tests/ece.lisp`) that builds `bin/ece` and runs smoke tests: `ece -V`, `ece -e "(exit 0)"`, `ece -e "(exit 3)"` returning 3.
- [x] 11.4 Add integration test for `make install` into a temp `PREFIX`, then verify `$TMP/bin/ece -V` works and `$TMP/bin/ece-build --help` dispatches via argv[0].
- [x] 11.5 Register new `.scm` tests in `tests/ece/run-all.scm` / `run-cl.scm` / `run-wasm.scm` as appropriate.

## 12. Verification

- [x] 12.1 Run `make test-rove`.
- [x] 12.2 Run `make test-ece`.
- [x] 12.3 Run `make test-conformance`.
- [x] 12.4 Run `make test-wasm`.
- [x] 12.5 Run `make test-web-apps`.
- [ ] 12.6 Build against the Dunge port and verify the developer loop (`ece game/main.scm`, `ece-test tests/`, `ece-build --target cl ...`). — deferred; Dunge is a separate repo.

## 13. Documentation

- [x] 13.1 Update `README.md` with installation instructions (`make install`, PREFIX), CLI reference, and the argv[0] dispatch story.
- [x] 13.2 Update test-counts artifact via `make update-test-counts`. (Manually updated due to WASM count extraction bug in existing script.)
- [x] 13.3 Run `make check-fmt`. (fmt is idempotent on all .scm/.lisp files; check-fmt fails only on unrelated pre-existing changes.)
