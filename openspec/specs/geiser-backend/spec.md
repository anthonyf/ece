## ADDED Requirements

### Requirement: ECE registers as a Geiser implementation

ECE SHALL ship an elisp file at `emacs/geiser-ece.el` that registers ECE as a selectable Geiser implementation. When the user invokes `M-x run-geiser` in emacs and selects `ece`, Geiser SHALL spawn a subordinate process running `bin/ece-repl --geiser` and connect it to a comint-managed REPL buffer.

#### Scenario: run-geiser offers ece as a choice

- **WHEN** user runs `M-x run-geiser` after loading `emacs/geiser-ece.el` in their init
- **THEN** Geiser SHALL present `ece` in the list of available implementations

#### Scenario: Selecting ece spawns the REPL process

- **WHEN** user selects `ece` from Geiser's implementation prompt
- **THEN** emacs SHALL spawn `bin/ece-repl --geiser` as a subprocess
- **AND** a comint buffer SHALL display the REPL prompt `ece> ` once the process is ready

### Requirement: Scheme-side geiser:eval handler

ECE SHALL provide a `geiser:eval` procedure in `src/geiser-ece.scm` that takes a module identifier (ignored in day 1) and a form. The procedure SHALL evaluate the form, capture any output written during evaluation, catch any error raised, and return a chibi-style alist response of the form `((result "<written-value>") (output . "<captured-output>"))` where `output` is a dotted pair (not a list). When the form raises an error, the error text SHALL be prepended to the `output` field; there is no separate `error` key.

#### Scenario: Simple successful eval

- **WHEN** `(geiser:eval #f '(+ 1 2))` is called
- **THEN** it SHALL return an alist with `result` equal to the string representation of `3` and `output` equal to the empty string

#### Scenario: Eval with side-effect output

- **WHEN** `(geiser:eval #f '(begin (display "hi") 42))` is called
- **THEN** the returned alist SHALL have `result` equal to the string `"42"` and `output` equal to `"hi"`

#### Scenario: Eval of an error-raising expression

- **WHEN** `(geiser:eval #f '(error "boom"))` is called
- **THEN** the returned alist's `output` field SHALL contain a non-empty string describing the error (including the text `"boom"`)
- **AND** the REPL state SHALL remain usable — a subsequent call like `(geiser:eval #f '(+ 1 2))` SHALL succeed with `result` `"3"`

### Requirement: Scheme-side geiser:load-file handler

ECE SHALL provide a `geiser:load-file` procedure in `src/geiser-ece.scm` that takes a filesystem path, loads the file via ECE's existing `load`, captures output, catches errors, and returns a structured alist response matching `geiser:eval`'s shape: `((result "<value>") (output . "<captured>"))`.

#### Scenario: Load of a simple file

- **WHEN** `(geiser:load-file "<path-to-fixture.scm>")` is called on a fixture containing `(define x 42)`
- **THEN** it SHALL return an alist with `output` empty
- **AND** a subsequent `(geiser:eval #f 'x)` SHALL return `result` `"42"`

#### Scenario: Load of a file with a syntax error

- **WHEN** `(geiser:load-file "<path-to-broken.scm>")` is called on a fixture with an unbalanced parenthesis
- **THEN** the returned alist SHALL have `output` containing a non-empty error message
- **AND** the REPL state SHALL remain usable for subsequent `geiser:eval` calls

### Requirement: Scheme-side no-values handler

ECE SHALL provide a `(geiser:no-values)` procedure in `src/geiser-ece.scm` that returns `#f` — chibi's convention for "no values to display". Version detection SHALL be handled by the elisp `version-command` slot invoking `bin/ece-repl -V`, not by a Scheme-side handler.

#### Scenario: No-values returns the no-values marker

- **WHEN** `(geiser:no-values)` is called
- **THEN** it SHALL return `#f`

### Requirement: Wire protocol — chibi-style alist responses on stdout

When `bin/ece-repl --geiser` is running, every REPL response SHALL be emitted via `(write alist) (newline)` where the alist has the shape `((result "<value>") (output . "<captured>"))` — with `output` as a dotted pair. There SHALL NOT be a sentinel prefix; Geiser's elisp side disambiguates structured responses from user-code output by reading one s-expression per request and relying on stdout redirection during eval to keep user prints out of the wire stream.

#### Scenario: Eval result is a chibi-style alist

- **WHEN** `bin/ece-repl --geiser` receives `(+ 1 2)` on stdin
- **THEN** it SHALL emit a single `write`-formatted alist whose `result` field parses to the string `"3"`

#### Scenario: User-code output is captured, not on the wire

- **WHEN** `bin/ece-repl --geiser` receives `(display "hi")`
- **THEN** the user-written `hi` SHALL appear in the captured `output` field of the structured response
- **AND** it SHALL NOT appear as an unwrapped line mixed with protocol output

### Requirement: End-to-end subprocess integration tests

ECE SHALL ship automated tests (CL-only Rove tests under `tests/ece.lisp` and unit tests under `tests/ece/cl-only/test-geiser-ece.scm`) that verify the Geiser wire protocol without requiring a running emacs. The tests SHALL spawn `bin/ece-repl --geiser` as a subprocess, send requests via stdin, read responses from stdout, and assert the structured alist shape.

#### Scenario: End-to-end eval request via subprocess

- **WHEN** a test spawns `bin/ece-repl --geiser`, writes `(+ 1 2)` plus newline to its stdin, reads one response, and parses the alist
- **THEN** the parsed alist SHALL have `result` `"3"` and `output` empty

#### Scenario: End-to-end error recovery via subprocess

- **WHEN** a test spawns `bin/ece-repl --geiser`, sends an error-raising form, reads the response, then sends a successful form
- **THEN** the first response's `output` SHALL contain a non-empty error message
- **AND** the second response SHALL have `result` equal to the expected value and `output` empty

### Requirement: Day 1 scope bounds

The geiser-backend capability SHALL explicitly NOT provide completions, autodoc / arglist hints, jump-to-definition, symbol documentation, macro expansion, module browser, inspector, debugger, or tracing in day 1. When Geiser requests any of these, the backend SHALL respond with a graceful "not supported" response rather than crashing or hanging.

#### Scenario: Completion request returns empty list gracefully

- **WHEN** Geiser sends a `geiser:completions` request to the day-1 backend
- **THEN** the backend SHALL respond with an empty completion list wrapped in the same alist envelope

#### Scenario: Autodoc request returns empty gracefully

- **WHEN** Geiser sends a `geiser:autodoc` request to the day-1 backend
- **THEN** the backend SHALL respond with an empty autodoc response wrapped in the same alist envelope

### Requirement: CL host only for day 1

The geiser-backend capability SHALL support only the CL-hosted ECE runtime in day 1. The WASM runtime SHALL not be exposed via Geiser in day 1; that integration is deferred to a subsequent change.

#### Scenario: CL host works

- **WHEN** the user runs `bin/ece-repl --geiser` on a CL-hosted ECE build
- **THEN** the Geiser backend SHALL function end-to-end

#### Scenario: WASM host is out of scope

- **WHEN** a developer asks "does Geiser work against the WASM runtime?"
- **THEN** the day-1 answer SHALL be "not yet — planned for a later phase"
