## ADDED Requirements

### Requirement: read parses integers
The ECE reader SHALL parse sequences of digits (optionally preceded by `-` or `+`) as integer numbers.

#### Scenario: Positive integer
- **WHEN** `(read (open-input-string "42"))` is evaluated
- **THEN** the result SHALL be the integer `42`

#### Scenario: Negative integer
- **WHEN** `(read (open-input-string "-7"))` is evaluated
- **THEN** the result SHALL be the integer `-7`

#### Scenario: Explicit positive sign
- **WHEN** `(read (open-input-string "+3"))` is evaluated
- **THEN** the result SHALL be the integer `3`

### Requirement: read parses floating point numbers
The ECE reader SHALL parse numbers containing a decimal point as floating point values.

#### Scenario: Float with decimal
- **WHEN** `(read (open-input-string "3.14"))` is evaluated
- **THEN** the result SHALL be the float `3.14`

#### Scenario: Negative float
- **WHEN** `(read (open-input-string "-0.5"))` is evaluated
- **THEN** the result SHALL be the float `-0.5`

### Requirement: read parses symbols
The ECE reader SHALL parse identifiers as symbols, preserving the original case of all characters (case-sensitive, R6RS/R7RS default).

#### Scenario: Simple symbol
- **WHEN** `(read (open-input-string "hello"))` is evaluated
- **THEN** the result SHALL be the symbol `hello`

#### Scenario: Uppercase symbol
- **WHEN** `(read (open-input-string "HELLO"))` is evaluated
- **THEN** the result SHALL be the symbol `HELLO`

#### Scenario: Mixed-case symbol
- **WHEN** `(read (open-input-string "myVar"))` is evaluated
- **THEN** the result SHALL be the symbol `myVar`

#### Scenario: Symbol with special characters
- **WHEN** `(read (open-input-string "list->vector"))` is evaluated
- **THEN** the result SHALL be the symbol `list->vector`

#### Scenario: Symbol with question mark
- **WHEN** `(read (open-input-string "null?"))` is evaluated
- **THEN** the result SHALL be the symbol `null?`

#### Scenario: Symbol with exclamation mark
- **WHEN** `(read (open-input-string "set!"))` is evaluated
- **THEN** the result SHALL be the symbol `set!`

#### Scenario: Case-sensitive distinction
- **WHEN** `(read (open-input-string "foo"))` and `(read (open-input-string "FOO"))` are evaluated
- **THEN** the results SHALL be distinct symbols (not `eq?`)

### Requirement: read parses strings with escape sequences
The ECE reader SHALL parse double-quoted strings, supporting `\n`, `\t`, `\\`, and `\"` escape sequences.

#### Scenario: Simple string
- **WHEN** `(read (open-input-string "\"hello\""))` is evaluated
- **THEN** the result SHALL be the string `"hello"`

#### Scenario: String with newline escape
- **WHEN** `(read (open-input-string "\"a\\nb\""))` is evaluated
- **THEN** the result SHALL be a string with a newline between `a` and `b`

#### Scenario: String with escaped quote
- **WHEN** `(read (open-input-string "\"say \\\"hi\\\"\""))` is evaluated
- **THEN** the result SHALL be the string `say "hi"`

### Requirement: read parses string interpolation
String interpolation with `~{expr}` inside double-quoted strings SHALL expand to a `(string-append ...)` form that concatenates literal segments with `(write-to-string expr)` calls for interpolated expressions. Strings without interpolation SHALL be returned as plain strings.

#### Scenario: Single interpolation
- **WHEN** the reader encounters `"Hello ~{name}"`
- **THEN** it SHALL produce `(string-append "Hello " (write-to-string name))`

#### Scenario: Multiple interpolations
- **WHEN** the reader encounters `"~{a} and ~{b}"`
- **THEN** it SHALL produce `(string-append (write-to-string a) " and " (write-to-string b))`

#### Scenario: No interpolation
- **WHEN** the reader encounters `"plain string"`
- **THEN** it SHALL produce the string literal `"plain string"` directly

#### Scenario: Interpolation result is a string
- **WHEN** an interpolated expression evaluates to a string
- **THEN** `write-to-string` SHALL wrap it in quotes (as `write` would)
- **AND** this is acceptable — interpolation uses `write` semantics, not `display` semantics

### Requirement: read parses lists
The ECE reader SHALL parse parenthesized sequences as proper lists. It SHALL support dotted pair notation.

#### Scenario: Simple list
- **WHEN** `(read (open-input-string "(a b c)"))` is evaluated
- **THEN** the result SHALL be the list `(a b c)`

#### Scenario: Nested list
- **WHEN** `(read (open-input-string "(a (b c) d)"))` is evaluated
- **THEN** the result SHALL be the list `(a (b c) d)`

#### Scenario: Dotted pair
- **WHEN** `(read (open-input-string "(a . b)"))` is evaluated
- **THEN** the result SHALL be the dotted pair `(a . b)`

#### Scenario: Empty list
- **WHEN** `(read (open-input-string "()"))` is evaluated
- **THEN** the result SHALL be the empty list `()`

### Requirement: read parses quote shorthand
The ECE reader SHALL parse `'expr` as `(quote expr)`.

#### Scenario: Quoted symbol
- **WHEN** `(read (open-input-string "'foo"))` is evaluated
- **THEN** the result SHALL be `(quote foo)`

#### Scenario: Quoted list
- **WHEN** `(read (open-input-string "'(1 2 3)"))` is evaluated
- **THEN** the result SHALL be `(quote (1 2 3))`

### Requirement: read parses quasiquote, unquote, and unquote-splicing
The ECE reader SHALL parse backtick as `quasiquote`, comma as `unquote`, and comma-at as `unquote-splicing`.

#### Scenario: Quasiquote with unquote
- **WHEN** `` (read (open-input-string "`(a ,b)")) `` is evaluated
- **THEN** the result SHALL be `(quasiquote (a (unquote b)))`

#### Scenario: Unquote-splicing
- **WHEN** `` (read (open-input-string "`(a ,@b)")) `` is evaluated
- **THEN** the result SHALL be `(quasiquote (a (unquote-splicing b)))`

### Requirement: read parses character literals
The ECE reader SHALL parse `#\x` as a character. Named characters `#\space`, `#\newline`, and `#\tab` SHALL be supported.

#### Scenario: Simple character
- **WHEN** `(read (open-input-string "#\\a"))` is evaluated
- **THEN** the result SHALL be the character `#\a`

#### Scenario: Space character
- **WHEN** `(read (open-input-string "#\\space"))` is evaluated
- **THEN** the result SHALL be the space character

#### Scenario: Newline character
- **WHEN** `(read (open-input-string "#\\newline"))` is evaluated
- **THEN** the result SHALL be the newline character

### Requirement: read parses vector literals
The ECE reader SHALL parse `#(...)` as a vector.

#### Scenario: Vector of numbers
- **WHEN** `(read (open-input-string "#(1 2 3)"))` is evaluated
- **THEN** the result SHALL be a vector containing `1`, `2`, `3`

### Requirement: read parses hash table literals
The ECE reader SHALL parse `{k1 v1 k2 v2 ...}` as a hash table literal, producing `(:hash-table (k1 . v1) (k2 . v2) ...)`.

#### Scenario: Hash table literal
- **WHEN** `(read (open-input-string "{a 1 b 2}"))` is evaluated
- **THEN** the result SHALL be `(:hash-table (a . 1) (b . 2))`

### Requirement: read parses boolean literals
The ECE reader SHALL parse `#t` as `t` (true) and `#f` as `()` (false).

#### Scenario: True literal
- **WHEN** `(read (open-input-string "#t"))` is evaluated
- **THEN** the result SHALL be `t`

#### Scenario: False literal
- **WHEN** `(read (open-input-string "#f"))` is evaluated
- **THEN** the result SHALL be `()`

### Requirement: read skips comments
The ECE reader SHALL skip line comments starting with `;` through end of line.

#### Scenario: Comment before expression
- **WHEN** `(read (open-input-string "; comment\n42"))` is evaluated
- **THEN** the result SHALL be `42`

### Requirement: read returns EOF sentinel at end of input
The ECE reader SHALL return the EOF sentinel when there is no more input to read.

#### Scenario: EOF on empty input
- **WHEN** `(read (open-input-string ""))` is evaluated
- **THEN** the result SHALL satisfy `eof?`

#### Scenario: EOF after last expression
- **WHEN** two consecutive `read` calls are made on `(open-input-string "42")`
- **THEN** the first call SHALL return `42` and the second SHALL satisfy `eof?`

### Requirement: read rejects stray backslash in bare symbols
The ECE reader SHALL signal a read-time error when a backslash character (`\`) appears inside a bare (non-pipe-quoted, non-string, non-character) symbol token. The error message SHALL name the offending character and include source location when `*source-file-name*` is set. Character literals (`#\X`) and string escapes (`"\n"`, `"\\"`) retain their existing behavior.

#### Scenario: Stray backslash in symbol at top level
- **WHEN** `(read (open-input-string "foo\\!"))` is evaluated
- **THEN** the reader SHALL signal an error whose message mentions `"invalid character in symbol"` and the backslash character

#### Scenario: Backslash as initial character
- **WHEN** the reader encounters a token beginning with `\` in a context expecting a symbol
- **THEN** the reader SHALL signal the same error as when backslash appears mid-token

#### Scenario: Backslash in string literal still works
- **WHEN** `(read (open-input-string "\"a\\nb\""))` is evaluated
- **THEN** the result SHALL be the string `"a\nb"` (existing escape behavior preserved)

#### Scenario: Character literal still works
- **WHEN** `(read (open-input-string "#\\x"))` is evaluated
- **THEN** the result SHALL be the character `#\x` (existing character-literal behavior preserved)

#### Scenario: Source location reported when reading from a file
- **WHEN** a `.scm` file contains a symbol with a stray backslash and is loaded via `(load "file.scm")` or `compile-file`
- **THEN** the error message SHALL identify the file, line, and column of the offending symbol
