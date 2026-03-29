## Context

`number->string` (primitive ID 30) converts an integer to its decimal string representation. CL implements it as a 2-line wrapper around `write-to-string`. WASM implements it as ~60 lines of WAT doing digit extraction with `i32.rem_u`/`i32.div_u` and buffer reversal. Both implementations are purely algorithmic — no host-specific type representations needed.

The arithmetic-foundation change added `quotient` and `modulo` to ECE, which are the exact operations needed for digit extraction. `integer->char` (ID 44) and `string` (ID 42, char→string) are core primitives available on both hosts.

On WASM, `$prim-number-to-string` is called internally by `$write-to-string-impl` (line 2882) and `$display-to-port` (line 3267) as a fast path for fixnum rendering. These internal callers cannot easily invoke ECE-compiled code from within WAT.

## Goals / Non-Goals

**Goals:**
- Implement `number->string` in ECE prelude using `quotient`, `modulo`, `integer->char`, `string`, `string-append`
- Remove from CL host dispatch completely
- Remove from WASM primitive dispatch (ID 30)
- Follow the two-pass bootstrap pattern for migration

**Non-Goals:**
- Migrating `write-to-string` or `display` to ECE (separate, larger change)
- Removing `$prim-number-to-string` from WAT entirely (blocked by internal callers in `write-to-string-impl` and `display-to-port`)
- Handling non-integer numbers (floats truncate to integer — pre-existing behavior)
- Radix parameter (R7RS optional second argument — separate enhancement)

## Decisions

### Decision 1: Digit extraction via quotient/modulo, build string left-to-right with recursion

**Choice**: Recursive helper that divides until zero, then builds the string on the way back up via `string-append`.

```scheme
(define (number->string n)
  (if (< n 0)
      (string-append "-" (number->string (- 0 n)))
      (if (< n 10)
          (string (integer->char (+ n 48)))
          (string-append (number->string (quotient n 10))
                         (string (integer->char (+ (modulo n 10) 48)))))))
```

**Alternatives considered**:
- *Iterative with list accumulation*: Build a list of digit characters, then join. Requires `list->string` (not available in ECE) or manual list-to-string conversion. More code for no benefit.
- *Iterative with string-append in a loop*: Prepending via `(string-append digit-str acc)` in a loop. Works but recursive version is cleaner and the recursion depth is at most 10 (log10 of max fixnum).

**Rationale**: The recursive approach naturally produces left-to-right digit order without needing a buffer or reversal. Max recursion depth is ~10 for 30-bit fixnums — no stack overflow risk. Each call does one `quotient`, one `modulo`, one `string-append` — same work as the iterative version.

### Decision 2: Placement after modulo, before gensym

**Choice**: Insert `number->string` in the "Integer arithmetic" section (after line ~73 where `modulo` is defined), before the "Gensym" section (line ~458).

**Rationale**: `number->string` depends on `quotient` and `modulo` (defined at lines 71-73). `gensym` (line 461) depends on `number->string`. The definition must go between these two. Placing it in the integer arithmetic section is the natural location.

### Decision 3: Keep `$prim-number-to-string` in WAT as internal function

**Choice**: Rename to `$number-to-string-internal` or keep as-is but remove only the ID 30 dispatch entry from `$apply-primitive`.

**Alternatives considered**:
- *Remove entirely and refactor callers*: `$write-to-string-impl` and `$display-to-port` would need to invoke the ECE-compiled `number->string` via the register machine — extremely complex from within WAT, essentially re-entering the executor mid-execution.
- *Inline the logic into each caller*: Duplicates ~50 lines of WAT in two places. Worse than keeping one shared function.

**Rationale**: The internal WAT function is a performance optimization for `write-to-string` and `display`, which are hot paths (REPL output, error messages, serialization). Removing it requires migrating those primitives to ECE first. Keeping it as an internal helper is the pragmatic choice — it doesn't affect the ECE API surface and can be removed in a future change.

### Decision 4: Zero handled as base case

**Choice**: `(if (< n 10) ...)` covers zero naturally since `(integer->char (+ 0 48))` produces `#\0`.

**Rationale**: No special case needed for zero. The `(< n 10)` branch handles all single-digit numbers including zero. The negative check `(< n 0)` comes first, so negative zero isn't an issue (ECE doesn't have negative zero for integers).

## Risks / Trade-offs

**[Low] Performance regression** → ECE `number->string` makes ~10 primitive calls per digit (quotient, modulo, integer->char, string, string-append) vs one host function call. For the common case (small numbers in `gensym`, error messages), absolute overhead is negligible. Hot paths (`write-to-string`, `display`) still use the WAT internal function.

**[Low] String-append allocation pressure** → Each digit creates a temporary string via `string-append`. For a 10-digit number, that's ~10 intermediate strings. Acceptable for the use cases where ECE `number->string` is called (gensym counters, serialization output, user code). Not in tight rendering loops.

**[None] Bootstrap ordering** → `number->string` depends on `quotient` and `modulo` (already in prelude). `gensym` depends on `number->string` (already later in prelude). No circular dependencies.
