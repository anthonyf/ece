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

ECE SHALL provide a `geiser:eval` procedure in `src/geiser-ece.scm` that takes a module identifier (ignored in day 1) and an expression. The procedure SHALL evaluate the expression, capture any output written during evaluation, catch any error raised, and return a structured alist response of the form `((result "<written-value>") (output "<captured-output>") (error <#f-or-string>))`.

#### Scenario: Simple successful eval

- **WHEN** `(geiser:eval #f '(+ 1 2))` is called
- **THEN** it SHALL return an alist with `result` equal to the string representation of `3`, `output` equal to the empty string, and `error` equal to `#f`

#### Scenario: Eval with side-effect output

- **WHEN** `(geiser:eval #f '(begin (display "hi") 42))` is called
- **THEN** the returned alist SHALL have `result` equal to the string `"42"`, `output` equal to `"hi"`, and `error` equal to `#f`

#### Scenario: Eval of an error-raising expression

- **WHEN** `(geiser:eval #f '(error "boom"))` is called
- **THEN** the returned alist SHALL have `error` equal to a non-`#f` string describing the error
- **AND** the REPL state SHALL remain usable — a subsequent call like `(geiser:eval #f '(+ 1 2))` SHALL succeed with `result` `"3"`

### Requirement: Scheme-side geiser:load-file handler

ECE SHALL provide a `geiser:load-file` procedure in `src/geiser-ece.scm` that takes a filesystem path, loads the file via ECE's existing `load`, captures output, catches errors, and returns a structured alist response matching `geiser:eval`'s shape.

#### Scenario: Load of a simple file

- **WHEN** `(geiser:load-file "<path-to-fixture.scm>")` is called on a fixture containing `(define x 42)`
- **THEN** it SHALL return an alist with `error` equal to `#f`
- **AND** a subsequent `(geiser:eval #f 'x)` SHALL return `result` `"42"`

#### Scenario: Load of a file with a syntax error

- **WHEN** `(geiser:load-file "<path-to-broken.scm>")` is called on a fixture with an unbalanced parenthesis
- **THEN** the returned alist SHALL have `error` set to a non-`#f` string
- **AND** the REPL state SHALL remain usable for subsequent `geiser:eval` calls

### Requirement: Scheme-side metadata handlers

ECE SHALL provide `(geiser:version)` and `(geiser:no-values)` procedures in `src/geiser-ece.scm` for Geiser's version-detection and no-values-return protocol contracts.

#### Scenario: Version returns a string

- **WHEN** `(geiser:version)` is called
- **THEN** it SHALL return a non-empty string identifying the ECE version

#### Scenario: No-values returns the no-values marker

- **WHEN** `(geiser:no-values)` is called
- **THEN** it SHALL return a value Geiser recognizes as "no values to display"

### Requirement: Wire protocol — structured responses on stdout

When `bin/ece-repl --geiser` is running, every REPL response SHALL be emitted as a single line prefixed with a unique sentinel marker, followed by the S-expression alist response. Free-form output written by the user's code SHALL remain on separate lines without the sentinel so the Geiser elisp side can distinguish structured responses from code-generated output.

#### Scenario: Eval result is wrapped in a sentinel-prefixed alist

- **WHEN** `bin/ece-repl --geiser` receives `(+ 1 2)` on stdin
- **THEN** it SHALL emit a single line starting with the sentinel marker, followed by an alist whose `result` field parses to the string `"3"`

#### Scenario: User-code output is not wrapped

- **WHEN** `bin/ece-repl --geiser` receives `(display "hi")`
- **THEN** the user-written `hi` SHALL appear in the captured `output` field of the structured response
- **AND** it SHALL NOT appear as an unwrapped line mixed with protocol output

### Requirement: End-to-end subprocess integration tests

ECE SHALL ship automated tests (CL-only Rove tests under `tests/ece.lisp` and unit tests under `tests/ece/cl-only/test-geiser-ece.scm`) that verify the Geiser wire protocol without requiring a running emacs. The tests SHALL spawn `bin/ece-repl --geiser` as a subprocess, send requests via stdin, read responses from stdout, and assert the structured alist shape.

#### Scenario: End-to-end eval request via subprocess

- **WHEN** a test spawns `bin/ece-repl --geiser`, writes `(+ 1 2)` plus newline to its stdin, reads one response line, and parses the alist
- **THEN** the parsed alist SHALL have `result` `"3"`, `output` `""`, and `error` `#f`

#### Scenario: End-to-end error recovery via subprocess

- **WHEN** a test spawns `bin/ece-repl --geiser`, sends an error-raising form, reads the response, then sends a successful form
- **THEN** the first response SHALL have `error` non-`#f`
- **AND** the second response SHALL have `error` `#f` and the expected `result`

### Requirement: Day 1 scope bounds

The geiser-backend capability SHALL explicitly NOT provide completions, autodoc / arglist hints, jump-to-definition, symbol documentation, macro expansion, module browser, inspector, debugger, or tracing in day 1. When Geiser requests any of these, the backend SHALL respond with a graceful "not supported" response rather than crashing or hanging.

#### Scenario: Completion request returns empty list gracefully

- **WHEN** Geiser sends a `geiser:completions` request to the day-1 backend
- **THEN** the backend SHALL respond with an empty completion list and `error` `#f`

#### Scenario: Autodoc request returns empty gracefully

- **WHEN** Geiser sends a `geiser:autodoc` request to the day-1 backend
- **THEN** the backend SHALL respond with an empty autodoc response and `error` `#f`

### Requirement: CL host only for day 1

The geiser-backend capability SHALL support only the CL-hosted ECE runtime in day 1. The WASM runtime SHALL not be exposed via Geiser in day 1; that integration is deferred to a subsequent change.

#### Scenario: CL host works

- **WHEN** the user runs `bin/ece-repl --geiser` on a CL-hosted ECE build
- **THEN** the Geiser backend SHALL function end-to-end

#### Scenario: WASM host is out of scope

- **WHEN** a developer asks "does Geiser work against the WASM runtime?"
- **THEN** the day-1 answer SHALL be "not yet — planned for a later phase"
