## ADDED Requirements

### Requirement: Pre-commit hook checks formatting of staged files
The pre-commit hook SHALL run `make check-fmt` when any `.lisp`, `.asd`, or `.scm` files are staged.

#### Scenario: Staged Lisp files with correct formatting
- **WHEN** a commit is made with correctly formatted `.lisp` files staged
- **THEN** the commit SHALL succeed

#### Scenario: Staged Lisp files with incorrect formatting
- **WHEN** a commit is made with incorrectly formatted `.lisp` files staged
- **THEN** the commit SHALL be rejected with a message to run `make fmt`

#### Scenario: No Lisp files staged
- **WHEN** a commit is made with no `.lisp`, `.asd`, or `.scm` files staged
- **THEN** the hook SHALL pass without running formatting checks

### Requirement: Scheme files use Scheme-mode indentation
`.scm` files SHALL be indented using Emacs `scheme-mode`, not `common-lisp-indent-function`.

#### Scenario: Format a .scm file
- **WHEN** `make fmt` is run with a `.scm` file present
- **THEN** the file SHALL be indented using Scheme conventions
