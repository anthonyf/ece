## MODIFIED Requirements

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

### Requirement: read parses hash table literals
The ECE reader SHALL parse `{k1 v1 k2 v2 ...}` as a hash table literal, producing `(:hash-table (k1 . v1) (k2 . v2) ...)`.

#### Scenario: Hash table literal
- **WHEN** `(read (open-input-string "{a 1 b 2}"))` is evaluated
- **THEN** the result SHALL be `(:hash-table (a . 1) (b . 2))`
