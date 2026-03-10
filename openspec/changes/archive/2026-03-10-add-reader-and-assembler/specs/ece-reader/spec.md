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
The ECE reader SHALL parse identifiers as symbols, upcasing all alphabetic characters to match CL convention.

#### Scenario: Simple symbol
- **WHEN** `(read (open-input-string "hello"))` is evaluated
- **THEN** the result SHALL be the symbol `HELLO`

#### Scenario: Symbol with special characters
- **WHEN** `(read (open-input-string "list->vector"))` is evaluated
- **THEN** the result SHALL be the symbol `LIST->VECTOR`

#### Scenario: Symbol with question mark
- **WHEN** `(read (open-input-string "null?"))` is evaluated
- **THEN** the result SHALL be the symbol `NULL?`

#### Scenario: Symbol with exclamation mark
- **WHEN** `(read (open-input-string "set!"))` is evaluated
- **THEN** the result SHALL be the symbol `SET!`

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
The ECE reader SHALL parse `$var` as variable interpolation and `$(expr)` as expression interpolation within strings, producing `(fmt ...)` forms. `$$` SHALL produce a literal `$`. Strings without `$` SHALL be returned as plain strings.

#### Scenario: Variable interpolation
- **WHEN** `(read (open-input-string "\"hello $name\""))` is evaluated
- **THEN** the result SHALL be `(FMT "hello " NAME)`

#### Scenario: Expression interpolation
- **WHEN** `(read (open-input-string "\"val: $(+ 1 2)\""))` is evaluated
- **THEN** the result SHALL be `(FMT "val: " (+ 1 2))`

#### Scenario: Escaped dollar
- **WHEN** `(read (open-input-string "\"costs $$5\""))` is evaluated
- **THEN** the result SHALL be the plain string `"costs $5"`

#### Scenario: No interpolation
- **WHEN** `(read (open-input-string "\"plain\""))` is evaluated
- **THEN** the result SHALL be the plain string `"plain"`

### Requirement: read parses lists
The ECE reader SHALL parse parenthesized sequences as proper lists. It SHALL support dotted pair notation.

#### Scenario: Simple list
- **WHEN** `(read (open-input-string "(a b c)"))` is evaluated
- **THEN** the result SHALL be the list `(A B C)`

#### Scenario: Nested list
- **WHEN** `(read (open-input-string "(a (b c) d)"))` is evaluated
- **THEN** the result SHALL be the list `(A (B C) D)`

#### Scenario: Dotted pair
- **WHEN** `(read (open-input-string "(a . b)"))` is evaluated
- **THEN** the result SHALL be the dotted pair `(A . B)`

#### Scenario: Empty list
- **WHEN** `(read (open-input-string "()"))` is evaluated
- **THEN** the result SHALL be the empty list `()`

### Requirement: read parses quote shorthand
The ECE reader SHALL parse `'expr` as `(quote expr)`.

#### Scenario: Quoted symbol
- **WHEN** `(read (open-input-string "'foo"))` is evaluated
- **THEN** the result SHALL be `(QUOTE FOO)`

#### Scenario: Quoted list
- **WHEN** `(read (open-input-string "'(1 2 3)"))` is evaluated
- **THEN** the result SHALL be `(QUOTE (1 2 3))`

### Requirement: read parses quasiquote, unquote, and unquote-splicing
The ECE reader SHALL parse backtick as `quasiquote`, comma as `unquote`, and comma-at as `unquote-splicing`.

#### Scenario: Quasiquote with unquote
- **WHEN** `` (read (open-input-string "`(a ,b)")) `` is evaluated
- **THEN** the result SHALL be `(QUASIQUOTE (A (UNQUOTE B)))`

#### Scenario: Unquote-splicing
- **WHEN** `` (read (open-input-string "`(a ,@b)")) `` is evaluated
- **THEN** the result SHALL be `(QUASIQUOTE (A (UNQUOTE-SPLICING B)))`

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
The ECE reader SHALL parse `{k1 v1 k2 v2 ...}` as a hash table literal, producing `(:HASH-TABLE (k1 . v1) (k2 . v2) ...)`.

#### Scenario: Hash table literal
- **WHEN** `(read (open-input-string "{a 1 b 2}"))` is evaluated
- **THEN** the result SHALL be `(:HASH-TABLE (A . 1) (B . 2))`

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
