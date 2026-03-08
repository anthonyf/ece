## Context

ECE uses a custom readtable (`*ece-readtable*`) that already overrides backtick, comma, and `{}`. The `fmt` function accepts mixed arguments and auto-stringifies non-strings. The standard CL string reader handles `\"` and `\\` escapes.

## Goals / Non-Goals

**Goals:**
- `$var` interpolates a variable: `"Hello $name"` → `(fmt "Hello " name)`
- `$(expr)` interpolates an expression: `"age: $(+ x 1)"` → `(fmt "age: " (+ x 1))`
- `$$` produces a literal `$`
- Strings without `$` return plain strings (no `fmt` wrapper)
- `lines` function joins strings with newlines and returns a string

**Non-Goals:**
- Multi-line string dedenting
- Template literals with different delimiters
- Format specifiers (width, padding, etc.)

## Decisions

### 1. Reader-level transform on `*ece-readtable*`

Replace the standard `"` reader in the ECE readtable with a custom string reader. It reads character by character:

- Accumulates literal text into segments
- On `$` followed by `(`: reads a full s-expression via `read`, adds as segment
- On `$` followed by identifier char: reads symbol name chars, interns the symbol, adds as segment
- On `$$`: adds literal `$` to current text segment
- On `"`: done — if only one segment and it's a string, return plain string; otherwise return `(fmt seg1 seg2 ...)`

### 2. Symbol identifier chars for `$var`

After `$`, read characters that are valid in Scheme identifiers: alphanumeric, `-`, `?`, `!`, `*`, `>`, `<`, `_`, `/`. Stop at anything else (whitespace, `.`, `,`, `(`, `)`, `"`, etc.). The collected chars are upcased and interned in the ECE package (matching CL's default reader behavior).

### 3. `lines` is a pure function in the prelude

`(lines "a" "b" "c")` returns `"a\nb\nc\n"` — each argument gets a newline appended, including the last. This makes `(display (lines ...))` produce clean output with a trailing newline.

Uses `fmt` internally to auto-stringify any non-string arguments.

### 4. Standard CL escapes still work

`\"`, `\\` are handled by the custom reader the same way the standard CL reader handles them. `\$` is not special — use `$$` for literal dollar signs, keeping the escape mechanism orthogonal from CL's.

## Risks / Trade-offs

- **Existing strings with `$`**: Any ECE string containing a literal `$` followed by an identifier or `(` will now be interpreted as interpolation. This is unlikely in practice but is technically a breaking change. `$$` provides the escape hatch.
- **Reader complexity**: The custom string reader is more complex than the default. Errors in malformed interpolations (unclosed `$(...)`) will surface at read time with reader errors.
