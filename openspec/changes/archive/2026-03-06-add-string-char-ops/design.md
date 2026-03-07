## Context

ECE uses CL's reader, which already handles `#\a`, `#\space`, `#\newline` etc. Characters are CL character objects. Strings are CL strings. Both types exist in the runtime but the evaluator doesn't fully support them.

## Goals / Non-Goals

**Goals:**
- Characters as self-evaluating values
- Character predicates and comparisons
- String access and manipulation primitives
- Conversions between strings, numbers, symbols, and characters

**Non-Goals:**
- Unicode-aware string operations (CL handles this natively)
- Mutable strings (`string-set!`) — keep strings immutable for now
- Regular expressions

## Decisions

### Decision: Characters are self-evaluating
Add `characterp` to the `self-evaluating-p` check. This means `#\a` evaluates to itself, just like numbers and strings.

### Decision: All operations are primitives wrapping CL functions
Every operation maps directly to a CL function:

| ECE | CL |
|-----|-----|
| `char?` | `characterp` |
| `char=?` | `char=` |
| `char<?` | `char<` |
| `char->integer` | `char-code` |
| `integer->char` | `code-char` |
| `string-length` | `length` |
| `string-ref` | `char` (CL's string accessor) |
| `string-append` | `(lambda (&rest args) (apply #'concatenate 'string args))` |
| `substring` | `subseq` |
| `string->number` | Custom wrapper using `parse-integer` / `read-from-string` |
| `number->string` | `write-to-string` |
| `string->symbol` | `intern` |
| `symbol->string` | `symbol-name` — returns uppercase; wrap with `string-downcase` |

### Decision: symbol->string returns lowercase
CL interns symbols in uppercase. Since ECE code uses lowercase, `symbol->string` should return lowercase to match user expectations.

## Risks / Trade-offs

- [`string-ref` returns a character, not a string] → Consistent with R5RS. Users need `char->integer` or `string` to convert if needed.
- [`string->number` needs to handle both integers and floats] → Use `read-from-string` with safety checks.
- [`string-append` needs variadic support] → CL's `concatenate` handles this. Register as a custom primitive that takes a list.
