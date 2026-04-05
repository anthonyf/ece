## ADDED Requirements

### Requirement: command-line returns argv as list of strings
`(command-line)` SHALL return a list of strings representing the command-line arguments. The first element SHALL be the script or program name (as provided by the host). Subsequent elements SHALL be arguments passed to the program. This matches R7RS.

#### Scenario: Script args are visible
- **GIVEN** `ece main.scm -- foo bar` is invoked
- **WHEN** `(command-line)` is called inside `main.scm`
- **THEN** the result SHALL include `"foo"` and `"bar"` as successive list elements after the script name

#### Scenario: REPL with no args
- **WHEN** `ece` is started with no arguments and `(command-line)` is evaluated at the REPL
- **THEN** the result SHALL be a list whose first element is a string and whose tail is empty

### Requirement: exit terminates with a given code
`(exit n)` SHALL cause the host process to terminate immediately with exit code `n`. When called with no argument, `(exit)` SHALL exit with code 0. When called with `#t`, `(exit)` SHALL exit with code 0; when called with `#f`, `(exit)` SHALL exit with a non-zero code (R7RS semantics).

#### Scenario: exit with integer code
- **WHEN** `ece -e "(exit 5)"` is invoked
- **THEN** the process exit code SHALL be 5

#### Scenario: exit with no arg
- **WHEN** `ece -e "(exit)"` is invoked
- **THEN** the process exit code SHALL be 0

#### Scenario: exit with #t
- **WHEN** `ece -e "(exit #t)"` is invoked
- **THEN** the process exit code SHALL be 0

#### Scenario: exit with #f
- **WHEN** `ece -e "(exit #f)"` is invoked
- **THEN** the process exit code SHALL be non-zero

### Requirement: get-environment-variable reads environment
`(get-environment-variable name)` SHALL return the string value of the named environment variable, or `#f` if not set. The argument SHALL be a string. This matches R7RS.

#### Scenario: Read a set environment variable
- **GIVEN** the environment contains `FOO=bar`
- **WHEN** `(get-environment-variable "FOO")` is evaluated
- **THEN** the result SHALL be `"bar"`

#### Scenario: Read an unset environment variable
- **GIVEN** the environment does NOT contain `MISSING`
- **WHEN** `(get-environment-variable "MISSING")` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: ece-home returns the resolved SDK root
`(ece-home)` SHALL return the path to the `share/ece/` directory resolved at startup (see ECE_HOME resolution). This is a string. This is an ECE-specific procedure (not R7RS), exposed so tooling `.scm` files can locate co-installed resources (templates, bootstrap bundles, etc.).

#### Scenario: ece-home is available
- **WHEN** `(ece-home)` is called
- **THEN** the result SHALL be a string ending in `share/ece` (or an absolute path thereof)
