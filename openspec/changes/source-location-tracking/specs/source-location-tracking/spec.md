## ADDED Requirements

### Requirement: Port line and column tracking
Ports SHALL track the current line number (1-based) and column number (0-based) during character input. Line SHALL increment and column SHALL reset to 0 when a newline character is read. Column SHALL increment by 1 for each non-newline character read.

#### Scenario: New port starts at line 1 column 0
- **WHEN** an input port is opened on any source (file or string)
- **THEN** the port's line SHALL be 1 and column SHALL be 0

#### Scenario: Column increments on non-newline read
- **WHEN** `read-char` reads a non-newline character from a port
- **THEN** the port's column SHALL increment by 1

#### Scenario: Newline resets column and increments line
- **WHEN** `read-char` reads a newline character from a port
- **THEN** the port's line SHALL increment by 1 and column SHALL reset to 0

#### Scenario: Port line/column accessible from ECE
- **WHEN** ECE code calls `(port-line port)` and `(port-col port)`
- **THEN** the current line and column numbers SHALL be returned

#### Scenario: CL runtime ports track line/column
- **WHEN** the CL runtime reads characters via `ece-read-char`
- **THEN** the port's line and column fields SHALL be updated

#### Scenario: WASM runtime ports track line/column
- **WHEN** the WASM runtime reads characters via `$port-read-char`
- **THEN** the port's `$line` and `$col` fields SHALL be updated

### Requirement: Reader records source locations for list expressions
The reader SHALL record the source file, line, and column for every list expression in a global side-table hash `*source-locations*`, keyed by the cons cell's `eq?` identity.

#### Scenario: Simple list gets source location
- **WHEN** the reader reads `(+ 1 2)` starting at line 5, column 3
- **THEN** the resulting cons cell SHALL have source location `(file 5 3)` in `*source-locations*`

#### Scenario: Nested lists each get their own location
- **WHEN** the reader reads `(define (foo x) (+ x 1))` starting at line 10
- **THEN** the outer list, the parameter list `(foo x)`, and the body `(+ x 1)` SHALL each have distinct source locations in `*source-locations*`

#### Scenario: Atoms do not get source locations
- **WHEN** the reader reads a bare symbol, number, string, or character
- **THEN** no entry SHALL be added to `*source-locations*` for that atom

#### Scenario: Source location includes filename from port
- **WHEN** reading from a file port with name "prelude.scm"
- **THEN** source locations SHALL include "prelude.scm" as the file component

### Requirement: Compiler emits source-map entries
The compiler SHALL collect `(pc line col)` triples during compilation. For each expression compiled, the compiler SHALL emit a source-map entry mapping the first instruction's PC to the expression's source location.

#### Scenario: Lambda body gets source-map entry
- **WHEN** the compiler compiles a lambda expression that has source location line 20, column 0
- **THEN** a source-map entry SHALL map the lambda's entry-point PC to `(20 0)`

#### Scenario: Function application gets source-map entry
- **WHEN** the compiler compiles a function call `(foo x)` at line 25, column 4
- **THEN** a source-map entry SHALL map the call's starting PC to `(25 4)`

#### Scenario: Macro-expanded code inherits call site location
- **WHEN** the compiler compiles `(when test body)` at line 30
- **AND** the macro expands to `(if test (begin body))`
- **THEN** the generated `if` expression SHALL have a source-map entry pointing to line 30 (the `when` call site)

#### Scenario: Original sub-expressions in macro expansion keep their location
- **WHEN** `(when (> x 0) (display "hi"))` is compiled, with `(> x 0)` at line 30 col 6 and `(display "hi")` at line 30 col 14
- **AND** the macro expands to `(if (> x 0) (begin (display "hi")))`
- **THEN** `(> x 0)` SHALL have a source-map entry for line 30 col 6
- **AND** `(display "hi")` SHALL have a source-map entry for line 30 col 14

#### Scenario: Nested macro expansion inherits correctly
- **WHEN** `(cond ((> x 0) (display "pos")) (else (display "other")))` is compiled at line 40
- **AND** `cond` expands to nested `if` forms
- **THEN** the generated `if` forms SHALL have source-map entries pointing to line 40
- **AND** the original sub-expressions SHALL keep their own source locations

### Requirement: Source map stored in .ecec header
The `.ecec` file header SHALL include an optional `source-map` field containing the source filename and a list of `(pc line col)` triples.

#### Scenario: compile-file writes source-map to header
- **WHEN** `compile-file` compiles "prelude.scm"
- **THEN** the output `prelude.ecec` header SHALL contain `(source-map "prelude.scm" (pc1 line1 col1) (pc2 line2 col2) ...)`

#### Scenario: Source map entries are sorted by PC
- **WHEN** a source-map is written to a `.ecec` file
- **THEN** the entries SHALL be in ascending PC order

#### Scenario: Old .ecec files without source-map load successfully
- **WHEN** a `.ecec` file without a `source-map` header field is loaded
- **THEN** the loader SHALL proceed normally with no source map for that space

### Requirement: Runtime resolves PC to source location
The runtime SHALL maintain a global `*source-maps*` table mapping space names to per-space hash tables. Each per-space hash table SHALL map PC values to `(file line col)` triples. The error handler SHALL use this table to resolve PCs in error messages and backtraces.

#### Scenario: Loader registers source map on boot
- **WHEN** a `.ecec` file with a `source-map` header field is loaded
- **THEN** a hash table mapping PC → `(file line col)` SHALL be registered in `*source-maps*` under the space name

#### Scenario: CL error message includes source location
- **WHEN** an error occurs at a PC that has a source-map entry in space "prelude"
- **THEN** the error message SHALL include the resolved location, e.g., `in procedure: foo (prelude.scm:42:10)`

#### Scenario: CL backtrace includes source locations
- **WHEN** a backtrace is extracted and frames have qualified addresses `(space . pc)`
- **THEN** each frame with a source-map entry SHALL display as `[N] proc-name at file:line:col` instead of `[N] proc-name at pc=N`

#### Scenario: WASM error message includes source location
- **WHEN** an error occurs in the WASM runtime at a PC with a source-map entry
- **THEN** the error message SHALL include the resolved source location

#### Scenario: Missing source-map entry falls back to PC
- **WHEN** an error occurs at a PC that has no source-map entry (e.g., REPL code or old .ecec)
- **THEN** the error message SHALL fall back to displaying `pc=N` as today

### Requirement: Source locations work correctly through all macro types
Source location tracking SHALL produce correct locations for code expanded from `define-macro`, `syntax-rules`, and `define-syntax` macros.

#### Scenario: define-macro expansion preserves locations
- **WHEN** a `define-macro` macro is called at line 50
- **AND** the expansion passes through sub-expressions from the call site
- **THEN** passed-through sub-expressions SHALL retain their original source locations
- **AND** macro-generated wrapper code SHALL report line 50

#### Scenario: syntax-rules expansion preserves locations
- **WHEN** a `syntax-rules` macro is called at line 60
- **AND** the expansion includes template-generated structure and matched sub-expressions
- **THEN** matched sub-expressions SHALL retain their original source locations
- **AND** template-generated structure SHALL inherit the call site's location (line 60)

#### Scenario: Nested macro expansion chains preserve locations
- **WHEN** macro A expands to code containing macro B at line 70
- **AND** macro B further expands
- **THEN** the innermost generated code SHALL trace back to line 70 (the outermost call site with a source location)
- **AND** any original sub-expressions at any nesting level SHALL retain their specific locations

#### Scenario: let macro preserves body locations
- **WHEN** `(let ((x 1)) (+ x 2))` is compiled at line 80 with body `(+ x 2)` at line 80 col 15
- **THEN** an error in `(+ x 2)` SHALL report line 80 col 15

#### Scenario: cond macro preserves clause locations
- **WHEN** `(cond (test1 expr1) (test2 expr2))` is compiled with `expr2` at line 90 col 20
- **THEN** an error in `expr2` SHALL report line 90 col 20

#### Scenario: and/or macro preserves operand locations
- **WHEN** `(and (foo) (bar) (baz))` is compiled with `(baz)` at line 100 col 16
- **THEN** an error in `(baz)` SHALL report line 100 col 16
