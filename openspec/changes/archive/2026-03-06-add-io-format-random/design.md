## Context

ECE currently supports `read` (s-expression input), `display`/`newline` (output), and string operations. It lacks raw text input, value-to-string conversion, bitwise arithmetic, and randomness — all needed for interactive fiction and general-purpose programming.

Primitives are stored by symbol name (`(primitive SYMBOL)`) and resolved via `symbol-function` at call time. New CL-side primitives follow the existing pattern: wrapper functions registered via `dolist` with `define-variable!`.

Macros are installed via `evaluate` on `define-macro` forms during package initialization.

## Goals / Non-Goals

**Goals:**
- Add `read-line` for raw text input (returns string, not parsed s-expr)
- Add `write-to-string` for converting any ECE value to its string representation
- Add bitwise primitives usable from ECE code
- Implement xorshift32 PRNG as ECE-level code using the bitwise primitives
- Add `fmt` and `print-text` as `define-macro` forms for string interpolation
- Keep all new features serializable (no opaque CL objects in continuations)

**Non-Goals:**
- Full R7RS `format` (CL-style format strings) — too complex, `fmt` macro is simpler
- Cryptographic randomness — xorshift32 is fine for games
- File I/O beyond `load` — not needed yet

## Decisions

### 1. `read-line` as a CL wrapper
`ece-read-line` calls CL's `read-line`. Returns the string. No prompt argument — the game should `display` the prompt first, then call `read-line`.

### 2. `write-to-string` via `princ-to-string`
Use CL's `princ-to-string` which prints without escape characters (human-readable). This means strings print without quotes, symbols print as lowercase names. This matches Scheme's `display` semantics and is what IF authors want for narrative text.

### 3. Bitwise primitives mapped directly to CL
| ECE name | CL function |
|----------|-------------|
| `bitwise-and` | `logand` |
| `bitwise-or` | `logior` |
| `bitwise-xor` | `logxor` |
| `bitwise-not` | `lognot` |
| `arithmetic-shift` | `ash` |

These go in the primitive alist (direct CL mappings, no wrappers needed). CL's `logand`/`logior` accept variable args, matching Scheme's variadic bitwise ops.

### 4. xorshift32 PRNG in ECE
The PRNG is implemented as ECE code evaluated at startup:

```scheme
(define *random-state* 12345)

(define (random-seed! seed)
  (set! *random-state* seed))

(define (xorshift32 state)
  (let* ((s1 (bitwise-xor state (arithmetic-shift state 13)))
         (s2 (bitwise-xor s1 (arithmetic-shift s1 -17)))
         (s3 (bitwise-xor s2 (arithmetic-shift s2 5))))
    (bitwise-and s3 4294967295)))

(define (random n)
  (set! *random-state* (xorshift32 *random-state*))
  (modulo *random-state* n))
```

This keeps state as a plain number in the global env — fully serializable with continuations.

### 5. `fmt` and `print-text` as `define-macro`
```scheme
(define-macro (fmt . args)
  `(string-append ,@(map (lambda (a)
                           `(if (string? ,a) ,a (write-to-string ,a)))
                         args)))

(define-macro (print-text . args)
  `(display (fmt ,@args)))
```

These are installed via `evaluate` during initialization, like `cond`, `let`, etc.

**Alternative considered**: Making `fmt` a regular function. Rejected because a macro avoids creating a list of args at runtime and enables compile-time type conversion insertion.

### 6. Masking to 32-bit in xorshift32
CL integers are arbitrary precision. The xorshift32 algorithm needs 32-bit wrapping. We use `(bitwise-and result #xFFFFFFFF)` after each xorshift step to mask to 32 bits. This is applied once at the end of the xorshift32 function.

## Risks / Trade-offs

- **xorshift32 quality**: Not the strongest PRNG, but sufficient for game use. Period of 2^32-1. → Acceptable for IF; upgrade later if needed.
- **`fmt` macro evaluates args multiple times**: Each arg appears once in the expansion, so this is safe. No double-evaluation risk.
- **`read-line` blocks**: Like `read`, it blocks waiting for input. → Expected for terminal IF. Async would be needed for HTML target but that's a future concern.
- **Bitwise ops on negative numbers**: CL's `logand`/`logxor` work on all integers (two's complement). The 32-bit masking in xorshift32 ensures positive results. → No special handling needed.
