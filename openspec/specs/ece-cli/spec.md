## ADDED Requirements

### Requirement: ece binary is a native executable
`ece` SHALL be a native executable produced by `sb-ext:save-lisp-and-die` with the ECE runtime and bootstrap bundle preloaded. It SHALL run without requiring `qlot`, `sbcl`, `asdf`, or any `.ecec` files to be present at runtime.

#### Scenario: ece runs without SBCL in PATH
- **GIVEN** `ece` is at `$PREFIX/bin/ece` and `sbcl` is NOT in `$PATH`
- **WHEN** `$PREFIX/bin/ece -e "(display (+ 1 2))"` is run
- **THEN** the output SHALL be `3`
- **AND** the exit code SHALL be 0

#### Scenario: ece starts in under 100ms on a typical workstation
- **WHEN** `time ece -e "(exit 0)"` is run
- **THEN** real-time SHALL be under 100ms (image boot, not cold-start SBCL)

### Requirement: argv[0] determines tool identity
The binary SHALL inspect the basename of `argv[0]` to choose its entry point. Recognized names are `ece` (default), `ece-repl`, `ece-build`, `ece-test`. Any unrecognized basename SHALL dispatch as `ece`.

#### Scenario: ece-repl symlink enters REPL
- **GIVEN** `ece-repl` is a symlink to `ece`
- **WHEN** `ece-repl` is invoked with no arguments
- **THEN** the process SHALL enter an interactive REPL

#### Scenario: ece-build symlink invokes the build tool
- **GIVEN** `ece-build` is a symlink to `ece`
- **WHEN** `ece-build --target cl -o dist/ main.scm` is invoked
- **THEN** the process SHALL invoke the `ece-build.scm` entry point with the remaining args

#### Scenario: unknown argv[0] falls through to ece
- **GIVEN** `my-tool` is a symlink to `ece`
- **WHEN** `my-tool -e "(display 'ok)"` is invoked
- **THEN** the output SHALL be `ok`

### Requirement: ece command-line accepts file and eval arguments in order
`ece` SHALL execute its command-line arguments in the order they appear. `--load FILE`, `-e EXPR` / `--eval EXPR`, and positional FILE arguments are "execution steps" processed left-to-right. Each FILE argument (positional or via `--load`) SHALL be loaded (`.scm` sources are read+evaluated, `.ecec` files are loaded directly). Each EXPR is read and evaluated.

#### Scenario: Positional file is loaded
- **WHEN** `ece main.scm` is invoked where `main.scm` contains `(display "hi")`
- **THEN** the output SHALL be `hi`

#### Scenario: Multiple loads in order
- **WHEN** `ece --load a.scm --load b.scm` is invoked where `a.scm` defines `x` and `b.scm` uses `x`
- **THEN** both files SHALL be loaded with `a.scm` first

#### Scenario: Eval after load
- **WHEN** `ece --load lib.scm -e "(lib-fn)"` is invoked
- **THEN** `lib.scm` SHALL be loaded, then `(lib-fn)` SHALL be evaluated

#### Scenario: .ecec file is loaded without re-compilation
- **WHEN** `ece app.ecec` is invoked
- **THEN** the compiled bundle SHALL be loaded directly without reading as source

### Requirement: ece with no work drops into REPL
With no `--load`, no `--eval`, and no positional file arguments, `ece` SHALL enter an interactive REPL.

#### Scenario: Bare invocation is REPL
- **WHEN** `ece` is invoked with no arguments
- **THEN** an interactive REPL SHALL start

### Requirement: ece -i enters REPL after processing files
The `-i` / `--interactive` flag SHALL cause `ece` to enter a REPL after processing all `--load`, `--eval`, and positional file arguments.

#### Scenario: -i enters REPL after loading
- **WHEN** `ece -i main.scm` is invoked
- **THEN** `main.scm` SHALL be loaded, and then a REPL SHALL start
- **AND** definitions from `main.scm` SHALL be visible in the REPL

### Requirement: ece -- terminates option processing
The `--` argument SHALL end option parsing. All subsequent arguments SHALL be passed through to the program via `(command-line)`, not interpreted by `ece` as options or files.

#### Scenario: Script arguments via --
- **WHEN** `ece main.scm -- --flag value` is invoked
- **THEN** `main.scm` SHALL be loaded
- **AND** inside `main.scm`, `(command-line)` SHALL include `"--flag"` and `"value"` after the script path

### Requirement: ece exit code reflects completion status
`ece` SHALL exit with code 0 on normal completion, non-zero on error. An explicit `(exit n)` call SHALL exit with code `n`.

#### Scenario: Normal completion
- **WHEN** `ece -e "(+ 1 2)"` completes
- **THEN** exit code SHALL be 0

#### Scenario: Explicit exit code
- **WHEN** `ece -e "(exit 7)"` is invoked
- **THEN** exit code SHALL be 7

#### Scenario: Uncaught error
- **WHEN** `ece -e "(raise 'boom)"` is invoked with no handler
- **THEN** exit code SHALL be non-zero
- **AND** an error message SHALL be printed to stderr

### Requirement: ece -V prints version
The `-V` / `--version` flag SHALL print the ECE version string and exit 0 without starting a REPL or loading files.

#### Scenario: Version flag
- **WHEN** `ece -V` is invoked
- **THEN** a version string (e.g., `ece 0.1.0`) SHALL be written to stdout
- **AND** exit code SHALL be 0

### Requirement: ece -h prints usage
The `-h` / `--help` flag SHALL print usage help and exit 0 without starting a REPL or loading files.

#### Scenario: Help flag
- **WHEN** `ece -h` is invoked
- **THEN** usage text describing options SHALL be written to stdout
- **AND** exit code SHALL be 0
