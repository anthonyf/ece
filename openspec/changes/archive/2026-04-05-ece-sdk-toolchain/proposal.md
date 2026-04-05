## Why

ECE currently requires a git checkout plus `qlot`/`sbcl` to do anything — run a program, build an app, run tests. This blocks any user (including the Dunge port) from treating ECE as a standalone language. There is no `ece` binary, no `make install`, no test runner installable in `$PATH`. The existing `bin/ece-build` shell script hard-codes `ECE_HOME` to its own directory and shells out to `qlot exec sbcl` on every invocation, making it in-tree-only and slow.

This change turns ECE into an installable toolchain: a single native SBCL image exposed via `argv[0]` dispatch as `ece`, `ece-repl`, `ece-build`, and `ece-test`. No `qlot` or `sbcl` is required at runtime. ECE's own build and test tools are rewritten in ECE, so the language becomes self-hosting for its developer experience.

## What Changes

- **New native binary `bin/ece`** built via `sb-ext:save-lisp-and-die` with bootstrap bundle embedded; boots in milliseconds.
- **argv[0] dispatch:** `ece-repl`, `ece-build`, `ece-test` are symlinks to `ece`; behavior is selected by the basename of `argv[0]`. Unknown argv[0] falls through to `ece` semantics.
- **CLI surface for `ece`:** `ece [OPTIONS] [FILE...]` where OPTIONS include `--load FILE`, `-e/--eval EXPR`, `-i/--interactive`, `--`, `-h/--help`, `-V/--version`. Multiple `--load`, `--eval`, and positional FILE args execute in the order given. With no files or evals, drops into a REPL (standard interpreter convention). `--` ends option processing; remaining args become `(command-line)` tail.
- **New host primitives — minimal, host-only capabilities:** `(command-line)`, `(exit n)`, `(get-environment-variable name)`, `%exe-path`, `%list-directory`, `%file-exists?`. All other tool logic (argv parsing, argv[0] dispatch, path resolution, file I/O composition, output formatting) is implemented in ECE per the kernel-minimization principle.
- **New ECE files (all tool logic lives here):** `src/ece-main.scm` (argv parser + dispatcher, called by the saved image), `src/ece-build.scm` (port of the shell script to ECE), `src/ece-test.scm` (test runner), `src/test-lib.scm` (assertion library for user tests), `src/sdk-lib.scm` (shared path/arg-parse helpers in pure ECE). The CL-side `:toplevel` shim is 3-5 lines whose only job is to invoke the ECE entry point with argv.
- **BREAKING: `bin/ece-build` shell script is removed.** Replaced by the symlink `bin/ece-build → bin/ece` created by `make install` (and mirrored in-tree by `make ece`).
- **`make install`** with `PREFIX`/`DESTDIR` support lays out `$PREFIX/bin/` (binary + symlinks) and `$PREFIX/share/ece/` (ECE source files, bootstrap, templates, wasm runtime).
- **ECE_HOME resolution:** checked as (1) `$ECE_HOME` env var if set; (2) `$(dirname argv[0])/../share/ece/`; (3) built-in default. Relocatable installs work.
- **`ece-test` runner:** discovers `test-*.scm` files, loads each in a fresh env, captures output, reports pass/fail with file:line context, exits with code 0 on success, 1 on any failure.
- **Version constant** hardcoded in `src/ece-main.scm` (CI-driven bump deferred).

## Capabilities

### New Capabilities

- `ece-cli`: The `ece` native binary, its argv dispatch, and its CLI options (`--load`, `--eval`, `-i`, etc.).
- `ece-sdk-install`: The `make install` target, `$PREFIX`/`$DESTDIR` handling, and the install-layout contract (`bin/`, `share/ece/`, symlinks).
- `ece-test-runner`: The `ece-test` tool behavior — discovery, per-file isolation, output capture, reporting, exit codes — and the `test-lib.scm` assertion API it provides to user tests.
- `process-environment`: ECE-level access to command-line arguments, process exit, and environment variables (`command-line`, `exit`, `get-environment-variable`).

### Modified Capabilities

- `app-packaging`: `ece-build` changes from a shell script at `bin/ece-build` to an ECE program dispatched via `argv[0]` from the `ece` binary. CLI surface is unchanged. `--target cl` output no longer requires a separate `sbcl --load run.lisp` step when `ece` is in `$PATH` — the generated wrapper `exec ece` on the bundled `.ecec` file instead.
- `makefile`: Adds `make ece` (build native binary via `save-lisp-and-die`) and `make install` targets. `make ece` also refreshes in-tree `bin/ece-*` symlinks so dev workflow mirrors installed layout.

## Impact

- **Affected code:**
  - New: `src/ece-main.scm`, `src/ece-build.scm`, `src/ece-test.scm`, `src/test-lib.scm`.
  - New: `scripts/build-ece-binary.lisp` (invokes `save-lisp-and-die`).
  - New: `runtime.lisp` primitives — `command-line`, `exit`, `get-environment-variable`, `%exe-path`, `%list-directory`, `%file-exists?`. Each is a thin one-line wrapper around an `sb-ext:` or standard CL call; no logic lives in CL beyond the host boundary.
  - New: `primitives.def` entries for those primitives.
  - New: WAT stubs in `wasm/runtime.wat` for the new primitives (no-ops where meaningless in WASM, or host-callbacks for the browser shell).
  - Modified: `Makefile` — add `ece`, `install`, and in-tree-symlink targets.
  - Modified: `bin/ece-build` — removed (replaced by symlink).
  - Modified: `templates/cl/run.lisp` — generated wrapper becomes a thin shell script / .sh that `exec ece app.ecec` (simpler, smaller, no ASDF dance).
- **Dependencies:** none new. Build still needs `qlot`/`sbcl`; runtime does not.
- **Dev workflow:** After the change, contributors run `make ece` once (or `make` as default target) to build `bin/ece`. After that, `bin/ece-build --target …` works as it does today. Existing Makefile targets that shell to `qlot exec sbcl` directly (`make repl`, `make test`) continue to work unchanged.
- **Size:** `bin/ece` is ~60-80MB (SBCL image). Not committed to the repo (in `.gitignore`). Shipped as part of the installed SDK.
- **Prerequisite:** this change depends on `move-ports-into-ece` having landed — `ece-test-runner`'s per-test output capture uses `with-output-to-string`.
- **Tests:** new `tests/ece/test-ece-main.scm` covers argv parsing; `tests/ece/test-ece-test.scm` covers the test runner's behavior on synthetic test files; integration test drives `$PREFIX/bin/ece` directly to verify the install layout.
