## 1. Assembler Primitives

- [x] 1.1 Add CL primitives for assembler access: `%instruction-vector-length`, `%instruction-vector-push!`, `%label-table-set!`, `%procedure-name-set!`, `%resolve-operation`
- [x] 1.2 Register and export the new assembler primitives

## 2. ECE Assembler

- [x] 2.1 Create `src/assembler.scm` — implement `ece-assemble-into-global` that walks instruction list, registers labels, resolves operations, appends instructions, returns start PC
- [x] 2.2 Wire assembler into `mc-compile-and-go` in `compiler.scm` to use `ece-assemble-into-global`

## 3. Reader Core

- [x] 3.1 Create `src/reader.scm` — implement `skip-whitespace-and-comments` helper (skip spaces, tabs, newlines, `;` comments)
- [x] 3.2 Implement `read-symbol` — read identifier characters, upcase, intern via `string->symbol`
- [x] 3.3 Implement `read-number` — read digits with optional leading sign and decimal point, parse via `string->number`
- [x] 3.4 Implement `read-string` — read double-quoted string with `\n`, `\t`, `\\`, `\"` escapes
- [x] 3.5 Implement string interpolation in `read-string` — `$var`, `$(expr)`, `$$`, producing `(fmt ...)` forms
- [x] 3.6 Implement `read-list` — read `(` delimited list with dotted pair support, handle `)`
- [x] 3.7 Implement `read-hash-dispatch` — `#\` characters (including named: space, newline, tab), `#(` vectors, `#t`/`#f` booleans
- [x] 3.8 Implement `read-hash-table-literal` — read `{k v ...}` producing `(:HASH-TABLE (k . v) ...)`

## 4. Reader Main Dispatch

- [x] 4.1 Implement `ece-scheme-read` — main dispatch: peek char, route to appropriate sub-parser, handle quote/quasiquote/unquote/unquote-splicing shorthands, EOF
- [x] 4.2 Add `ece-scheme-read` as a registered primitive so ECE code can call it

## 5. Bootstrap Wiring

- [x] 5.1 Update bootstrap sequence in `compiler.lisp` to load `reader.scm` and `assembler.scm` after `compiler.scm`
- [x] 5.2 Add switchover: after assembler.scm loads, rebind `read` in global env to use ECE reader, and update `compile-and-go` / `compile-file-ece` to use ECE assembler
- [x] 5.3 Update `ece-load` to use ECE reader (open file as port, read in loop with ECE reader)

## 6. Tests

- [x] 6.1 Test reader: integers, floats, negative numbers
- [x] 6.2 Test reader: symbols (upcasing, special chars like `?`, `!`, `->`)
- [x] 6.3 Test reader: strings with escape sequences
- [x] 6.4 Test reader: string interpolation (`$var`, `$(expr)`, `$$`)
- [x] 6.5 Test reader: lists, nested lists, dotted pairs, empty list
- [x] 6.6 Test reader: quote, quasiquote, unquote, unquote-splicing
- [x] 6.7 Test reader: character literals (`#\a`, `#\space`, `#\newline`, `#\tab`)
- [x] 6.8 Test reader: vectors, hash table literals, booleans (`#t`, `#f`)
- [x] 6.9 Test reader: comments, EOF behavior
- [x] 6.10 Test assembler: assemble instructions, verify execution produces correct results
- [x] 6.11 Test round-trip: compile with ECE compiler, assemble with ECE assembler, execute — verify same result as CL pipeline
