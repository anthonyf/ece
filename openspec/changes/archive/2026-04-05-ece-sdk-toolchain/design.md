## Context

ECE today is a git repo you clone and build from source. There is no installable toolchain:

- No `ece` binary — you run ECE via `qlot exec sbcl --eval '(asdf:load-system :ece)' --eval ...` or `make repl`.
- `bin/ece-build` is a shell script that shells out to `qlot exec sbcl` on every invocation (~3s of boot overhead).
- There is no test runner installable in `$PATH`. Self-hosted tests are run via `make test-ece`, which again requires the full source tree.
- `ECE_HOME` is resolved as `$(dirname script)/..`, which only works in-tree.

Dunge (and any future ECE application) needs `ece` to be an installable CLI that runs on any machine that has a POSIX shell and nothing else. No qlot, no sbcl, no ASDF. This is the gate condition for treating ECE as a standalone language.

SBCL supports `sb-ext:save-lisp-and-die` — it produces a single native executable combining the SBCL runtime and any loaded code. An ECE image produced this way boots in ~30ms (vs. ~3000ms for `sbcl --load`), and has no external runtime dependencies. This is the foundation.

The `move-ports-into-ece` change (Proposal 1, prerequisite) provides `with-output-to-string`, needed by the test runner's per-test output capture.

## Goals / Non-Goals

**Goals:**
- A single `ece` binary invokable from `$PATH` with no dependencies other than the OS.
- `ece`, `ece-repl`, `ece-build`, `ece-test` behaviors dispatched via `argv[0]` from the same binary.
- `make install` / `make uninstall` with `PREFIX`/`DESTDIR`, following GNU install conventions.
- ECE-level access to argv, env vars, and exit codes so tooling can be written in ECE.
- `ece-build` and `ece-test` implemented as ECE programs in `src/*.scm`, eating our own dog food.
- Relocatable install layout: the SDK tree can be copied and still work.
- Dev workflow unchanged: `make repl` / `make test` keep working via qlot.

**Non-Goals:**
- Cross-platform binary distribution (macOS/Linux build works; Windows deferred).
- Multi-arch fat binaries or universal builds.
- CI-driven version bumping (hardcoded version constant for now).
- Codesigning / notarization for macOS.
- Package-manager integration (brew, apt, dnf — deferred).
- `ece-repl`-to-ece-repl history / readline enhancements beyond what SBCL provides.

## Decisions

### D0. Keep the CL surface area to the absolute minimum

This is a framing constraint for every other decision. ECE's kernel-minimization goal means:
- **CL owns only what the host uniquely knows:** argv, env vars, exit(), the executable path, and filesystem syscalls. Each such capability is exposed as exactly one primitive and nothing more.
- **All logic — argument parsing, argv[0] dispatch, tool behavior, file layout, path resolution, option-flag interpretation, output formatting, error reporting — lives in `.scm` files.**
- **The CL "shim" that runs after `save-lisp-and-die` is 3-5 lines** whose only job is to transfer control into ECE and pass it argv.
- **No new CL helper functions** for tool logic. If you need a helper, write it in ECE.

This constraint is explicit because it's easy to drift: you reach for CL "because it's faster to write," and over time the shim grows. Don't.

### D1. `save-lisp-and-die` image with minimal `:toplevel` ECE shim

`scripts/build-ece-binary.lisp` loads `:ece` (which boots the VM from `bootstrap.ecec`), then invokes `sb-ext:save-lisp-and-die`. The `:toplevel` function is a 3-line CL closure whose only job is to invoke ECE:

```lisp
(sb-ext:save-lisp-and-die "bin/ece"
    :executable t
    :toplevel (lambda ()
                (ece:evaluate
                  `(begin
                     (load (string-append (ece-home) "/ece-main.ecec"))
                     (ece-main (command-line)))))
    :compression nil)
```

That's it. The shim does not parse argv, does not resolve paths, does not know about tools or subcommands. Everything it touches is an ECE expression. Even `ece-home` — the path to the installed `share/ece/` — is an ECE procedure (D4) backed by a `%exe-path` primitive.

**Why this works:** `ece:evaluate` is already the public entry point for running ECE expressions from CL. `command-line`, `ece-home`, `load` are all ECE-level names the image exposes after bootstrap. The shim just routes control.

**Sub-decision: `ece-main.scm` is pre-compiled to `ece-main.ecec` at install time**, not baked into the image. Two reasons:
1. Keeps the image build deterministic — the image contains only the VM, compiler, and prelude. Tools are data.
2. Lets contributors edit `ece-main.scm`, recompile `ece-main.ecec` (via ece-build itself, recursively), and re-run without invoking `save-lisp-and-die`. Fast iteration.

**Alternative considered:** parse argv in CL, dispatch to ECE functions based on subcommand. Rejected — splits the dispatcher across two languages, adds CL code that is pure logic (no host-specific knowledge), violates D0.

**Alternative considered:** embed `ece-main.scm` in the image at save time. Rejected — means every dispatcher tweak requires a 10-second `save-lisp-and-die` rebuild, and makes the image responsible for tool code that should be shipped as installable data.

### D2. argv[0] dispatch via symlinks

Inside ECE, `ece-main.scm` inspects `(basename (car (command-line)))`:

```scheme
(define (ece-main argv)
  (let ((tool (basename (car argv)))
        (rest (cdr argv)))
    (cond
      ((string=? tool "ece-repl")  (ece-repl-main rest))
      ((string=? tool "ece-build") (ece-build-main rest))
      ((string=? tool "ece-test")  (ece-test-main rest))
      (else                        (ece-default-main rest))))) ; ece + fallback
```

Install layout uses symlinks:
```
$PREFIX/bin/
  ece                   (regular file, the image)
  ece-repl  → ece       (symlink)
  ece-build → ece       (symlink)
  ece-test  → ece       (symlink)
```

Dev layout mirrors it: `make ece` creates `bin/ece` and updates in-tree symlinks.

**Alternative considered:** shell script wrappers (one `.sh` per tool, each `exec`s `ece` with a fixed initial arg). Rejected — splits behavior across sh+ECE, adds exec overhead, and the user already signed off on argv[0] dispatch.

### D3. `bin/ece-build` shell script removed entirely

The current `bin/ece-build` shell script is deleted. Its function is replaced by `src/ece-build.scm` invoked via `ece-build` (the argv[0]-dispatched entry point). This means:
- Contributors must run `make ece` once before `bin/ece-build` works in-tree.
- `make` (the default target) should build `ece` so the common-case developer gets it.
- CI builds `ece` as part of its `test` prerequisite.

**Alternative considered:** keep the shell script as a fallback for environments without `bin/ece`. Rejected by user preference (clean break: "ECE itself should use its own tooling").

### D4. ECE_HOME resolution — implemented entirely in ECE

The ECE-level procedure `(ece-home)` resolves the `share/ece/` path using only one primitive (`%exe-path`) and string manipulation:

```scheme
(define (ece-home)
  (let ((env (get-environment-variable "ECE_HOME")))
    (cond
      ((and env (> (string-length env) 0)) env)
      (else
        (path-join (dirname (dirname (%exe-path)))
                   "share" "ece")))))
```

`%exe-path` returns the actual path of the running executable (already symlink-resolved by the host — `sb-ext:*runtime-pathname*` does this on SBCL), so for an `ece-build` invocation that symlinks to `ece`, we still get the correct binary path. The `dirname`, `path-join` helpers are pure ECE (string ops).

**Alternative considered:** bake the install prefix into the binary at build time. Rejected — breaks relocatable installs.

**Alternative considered:** resolve `argv[0]` manually with `%realpath`. Rejected — `%exe-path` is what the host already knows; no symlink-chasing logic needed in ECE or in a new primitive.

### D5. `ece-build.scm` is ported from the shell script

The existing `bin/ece-build` logic (argument parsing, input validation, compile step, target packaging) becomes `src/ece-build.scm`. It uses:
- `(command-line)` for args
- File I/O primitives for reading templates, writing output
- `compile-system` to produce the `.ecec` bundle (already exists, already callable from ECE)
- `%file-copy` or `call-with-input/output-file` for copying assets

The `--target cl` path generates a shell wrapper instead of `run.lisp`:
```sh
#!/bin/sh
exec ece "$(dirname "$0")/app.ecec" -- "$@"
```

**Trade-off:** `--target cl` now requires the user to have `ece` in `$PATH`. This is the intended outcome — the old `sbcl --load run.lisp` path embedded the full ECE source tree, which no installed user would have. For `--target cl --standalone` (deferred, not in this change), we'd produce a per-app `save-lisp-and-die` image. For now, simple wrapper that calls the installed `ece`.

### D6. `ece-test.scm` uses `with-output-to-string` for capture

Per-test isolation:
```scheme
(define (run-one-test test)
  (let* ((name (test-name test))
         (thunk (test-thunk test))
         (captured (open-output-string))
         (result
           (guard (e (#t `(error ,e)))
             (parameterize ((current-output-port captured))
               (thunk))
             'ok)))
    (record-result! name result (get-output-string captured))))
```

This depends directly on `move-ports-into-ece` having shipped `(parameterize ((current-output-port p)) ...)`. Without it, captured output goes nowhere.

`test-lib.scm` exports `test`, `assert-equal`, `assert-true`, `assert-false`, `assert-error`, `assert-error-message`, `run-tests`. These are lifted from the existing `tests/ece/test-framework.scm` with adjustments:
- state stored in parameter objects (not global mutation) so concurrent or nested runs don't collide.
- `run-tests` returns counts instead of printing, so the runner controls output.

### D7. Minimal primitive additions — host-only capabilities

Per D0, we add primitives only for capabilities the host uniquely owns. Each is a one-line wrapper around a `sb-ext:` or standard CL call, returning ECE-compatible values. No logic in the CL implementation.

| Primitive | Purpose | CL body (approx) |
|-----------|---------|-------------------|
| `command-line` | argv as ECE list of strings | `(coerce sb-ext:*posix-argv* 'list)` |
| `exit` | terminate process (0-arg / int / #t / #f per R7RS) | `(sb-ext:exit :code …)` |
| `get-environment-variable` | read env var by name → string or #f | `(or (sb-ext:posix-getenv name) scheme-false)` |
| `%exe-path` | path of the running executable (NOT argv[0]) | `(namestring sb-ext:*runtime-pathname*)` (or equivalent resolution via `/proc/self/exe` / `_NSGetExecutablePath`) |
| `%list-directory` | list names in a directory | `(mapcar #'file-namestring (directory …))` |
| `%file-exists?` | predicate on a path | `(probe-file …)` |

**What we are NOT adding as primitives** (deliberate — do in ECE):
- `basename`, `dirname`, `path-join` → pure string manipulation, ECE.
- `%realpath` → not strictly needed. `%exe-path` already resolves, and tooling paths are explicit. If symlink resolution is ever needed for user paths, ECE can chain `%exe-path`-style lookups.
- `ece-home` → ECE procedure that uses env var + `%exe-path` (see D4).
- `file-copy`, `base64-encode-file`, etc. → compose from existing file I/O primitives in ECE.

Matching WAT stubs in the browser runtime:
- `command-line` returns `'("browser")` (or a JS-provided list)
- `exit` throws a JS exception to halt execution
- `get-environment-variable` always returns `#f`
- `%exe-path` returns `""` (browser has no executable path)
- `%list-directory` errors (no filesystem in browser sandbox)
- `%file-exists?` returns `#f`

### D8. Hardcoded version constant

```scheme
;; src/ece-main.scm
(define *ece-version* "0.1.0")
```

The `-V` / `--version` flag prints `ece <*ece-version*>`. A future CI workflow can templating this from a git tag; noted as a follow-up, not this change.

### D9. Makefile targets

```makefile
ece: $(BOOTSTRAP)     # dep on bootstrap.ecec
	qlot exec sbcl --non-interactive --load scripts/build-ece-binary.lisp
	ln -sf ece bin/ece-repl
	ln -sf ece bin/ece-build
	ln -sf ece bin/ece-test

install: ece
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 bin/ece $(DESTDIR)$(PREFIX)/bin/ece
	ln -sf ece $(DESTDIR)$(PREFIX)/bin/ece-repl
	ln -sf ece $(DESTDIR)$(PREFIX)/bin/ece-build
	ln -sf ece $(DESTDIR)$(PREFIX)/bin/ece-test
	install -d $(DESTDIR)$(PREFIX)/share/ece
	# copy src/ece-main.scm, ece-build.scm, ece-test.scm, test-lib.scm
	# copy bootstrap/bootstrap.ecec → share/ece/bootstrap.ecec
	# copy wasm/runtime.wasm, glue.js, primitives.json
	# copy templates/ recursively

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/ece{,-repl,-build,-test}
	rm -rf $(DESTDIR)$(PREFIX)/share/ece
```

Default `PREFIX = /usr/local`. `DESTDIR` empty by default.

**Alternative considered:** default `PREFIX` to `~/.local` for no-sudo friendliness. Rejected — `/usr/local` is the conventional default for GNU-style `make install`; users who want `~/.local` pass it explicitly.

## Risks / Trade-offs

- **[Risk] SBCL image size (~60-80MB) feels large for "just an interpreter".** → Mitigation: accept it; this is a one-time download per machine. Compression (`:compression t`) can reduce to ~25MB at ~100ms boot-time cost — noted, not enabled by default in this change.
- **[Risk] `save-lisp-and-die` requires SBCL; so does building the image.** → Mitigation: OK — we require SBCL for the build host, not the runtime host. That matches Rust/Go/etc. distribution models.
- **[Risk] Symlinks don't work on Windows natively.** → Mitigation: out of scope for this change; when we tackle Windows we'll ship per-name `.exe` wrappers or hard copies.
- **[Risk] Removing `bin/ece-build` shell script breaks existing Makefile targets and any external tooling pointing at it.** → Mitigation: `make ece` creates the symlink in-tree; audit all callers before merging. No external users yet besides the Dunge port, which is being upgraded in parallel.
- **[Risk] `ece-build --target cl` output now depends on `ece` in `$PATH` on the runtime box.** → Mitigation: documented in the CL target help text; `--standalone` flag for self-contained builds is a follow-up.
- **[Risk] Image startup could regress silently if `ece-main.scm` grows or takes expensive actions at top level.** → Mitigation: smoke test in CI that `ece -e "(+ 1 2)"` completes under a time budget.
- **[Risk] argv[0] misread on some platforms** (e.g., via `/proc/self/exe`, symlink resolution surprises). → Mitigation: use `sb-ext:posix-argv` for argv (the actual invocation name), and a separate `%exe-path` primitive (SBCL: `sb-ext:native-namestring (sb-ext:*runtime-pathname*)`) for the resolved executable path used by ECE_HOME resolution. Document the split.
- **[Risk] Tests running in parallel share global state in `test-lib.scm`.** → Mitigation: move counters into parameter objects so each `run-tests` invocation owns its own state.
- **[Trade-off] `ece-build.scm` will have to re-implement argument parsing from scratch (no shell `getopts` equivalent built in).** → Small ECE arg-parsing helper will be written as part of this change and reused by `ece-test.scm` and `ece-main.scm`.

## Migration Plan

1. Land `move-ports-into-ece` first (prerequisite — provides output capture).
2. Implement new primitives (`command-line`, `exit`, `get-environment-variable`, `%exe-path`, `%realpath`) with a two-pass bootstrap.
3. Write `src/ece-main.scm`, `src/ece-build.scm`, `src/ece-test.scm`, `src/test-lib.scm`.
4. Write `scripts/build-ece-binary.lisp`.
5. Add `make ece`, `make install`, `make uninstall` targets.
6. Delete `bin/ece-build` shell script.
7. Port existing self-hosted tests (`tests/ece/test-*.scm`) to the new `test-lib.scm` API — or leave them on the current `test-framework.scm` if the APIs remain compatible (they will — `test-lib.scm` is a superset).
8. Add smoke tests for `ece`, `ece-build`, `ece-test`, `make install` that exercise each via a temp `PREFIX`.
9. Update `README.md` and any docs referencing `bin/ece-build` as a shell script.

## Open Questions

- **Q1.** Should `make` (default target) build `bin/ece`, or leave that to explicit `make ece`? (Lean: yes, so common `make && make test` workflow produces a working toolchain.)
- **Q2.** Does `--standalone` CL target (self-contained per-app SBCL image) belong in this change or a follow-up? (Lean: follow-up — this change is already large, and the shell-wrapper CL target is sufficient for Dunge's dev loop.)
- **Q3.** Should `ece-test` support a `--filter PATTERN` flag to run only matching test names? (Lean: not required for v1; add when needed.)
- **Q4.** Where should `ece-main.scm` etc. live — `src/` or `tools/`? (User said "src/ is fine"; going with `src/`.)
