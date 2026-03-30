## Context

ECE has two remaining core primitives that are algorithmically expressible in ECE:

- `boolean?` (19): Already implemented in `prelude.scm` line 95 as `(if (eq? x #t) #t (if (eq? x #f) #t #f))`. Host implementations still exist in CL (`ece-boolean-p`) and WASM (`$is-boolean` dispatch). This is purely a removal task.
- `string->number` (29): CL implementation is a ~30-line parser supporting sign, integers, and decimal floats. WASM uses `$prim-string-to-number` (integer part) + `$parse-float-after-dot` (fractional part). Can be expressed in ECE using `string-ref`, `string-length`, `char->integer`, and arithmetic.

WAT internal callers:
- `$is-boolean` is called by `$prim-write` (line 2892) and `$prim-equal` (line 3359) — must be kept
- `$prim-string-to-number` and `$parse-float-after-dot` have no internal callers beyond dispatch — can be fully removed

## Goals / Non-Goals

**Goals:**
- Remove `boolean?` from both host runtimes (ECE implementation already exists)
- Implement `string->number` in ECE prelude
- Follow two-pass bootstrap migration pattern
- Support the same input formats as the current CL/WASM implementations: integers, negative integers, decimal floats

**Non-Goals:**
- Supporting radix prefixes (`#b`, `#o`, `#x`) — not supported by current implementations
- Supporting scientific notation (`1e5`) — not supported by current implementations
- Migrating `write-to-string` or `write-to-string-flat` (separate, more complex change)

## Decisions

### Decision 1: boolean? — removal only

**Choice**: No new code needed. `boolean?` is already in `prelude.scm` line 95. Simply remove from CL and WASM host dispatch.

**Rationale**: The ECE implementation was added during the `equal?`/`eqv?` migration batch but the host entries were not removed at that time.

### Decision 2: string->number placement

**Choice**: Place `string->number` in the "Derived predicates" section of `prelude.scm`, after `number->string` and `boolean?`. It depends on `char->integer`, `string-ref`, `string-length`, arithmetic, and comparison operators — all available by that point.

**Rationale**: Logical pairing with `number->string` (its inverse). All dependencies are core primitives available from line 1.

### Decision 3: string->number algorithm

**Choice**: Character-by-character parsing using `string-ref` and `char->integer`:

```scheme
(define (string->number s)
  (let ((len (string-length s)))
    (if (= len 0) #f
        (let* ((start (if (or (char=? (string-ref s 0) #\-)
                              (char=? (string-ref s 0) #\+))
                          1 0))
               (neg (char=? (string-ref s 0) #\-)))
          (if (= start len) #f
              (%parse-digits s start len neg))))))

(define (%parse-digits s start len neg)
  (let loop ((i start) (acc 0))
    (if (= i len)
        (if neg (- 0 acc) acc)
        (let ((ch (string-ref s i)))
          (if (char=? ch #\.)
              (%parse-frac s (+ i 1) len acc neg)
              (let ((d (- (char->integer ch) 48)))
                (if (or (< d 0) (> d 9))
                    #f
                    (loop (+ i 1) (+ (* acc 10) d)))))))))

(define (%parse-frac s start len int-part neg)
  (if (= start len) #f
      (let loop ((i start) (frac 0) (divisor 1))
        (if (= i len)
            (let ((result (+ int-part (/ frac divisor))))
              (if neg (- 0 result) result))
            (let ((d (- (char->integer (string-ref s i)) 48)))
              (if (or (< d 0) (> d 9))
                  #f
                  (loop (+ i 1) (+ (* frac 10) d) (* divisor 10))))))))
```

**Rationale**: Mirrors the structure of the CL and WASM implementations. Three-phase: sign detection → integer digits → optional fractional digits after `.`. Returns `#f` on any invalid character. Helper functions prefixed with `%` to indicate internal use.

### Decision 4: Edge cases matching current behavior

**Choice**: Match CL/WASM behavior exactly:
- Empty string → `#f`
- Sign only (`"-"`, `"+"`) → `#f`
- Trailing dot (`"42."`) → valid float (42.0) — CL allows this
- Leading dot (`".5"`) → valid float (0.5) — CL allows this
- Dot only (`"."`) → `#f`
- Whitespace → `#f` (no trimming — CL trims but WASM doesn't, go with strict)

**Rationale**: Consistent behavior across runtimes. The reader already handles whitespace before calling `string->number`.

### Decision 5: Remove WASM functions entirely

**Choice**: Remove `$prim-string-to-number` and `$parse-float-after-dot` from `runtime.wat`. Keep `$is-boolean` as internal helper.

**Rationale**: `$prim-string-to-number` has no internal callers beyond dispatch. `$is-boolean` is called by `$prim-write` and `$prim-equal`.

## Risks / Trade-offs

**[Low] Performance regression for string->number** → ECE `string->number` does per-character dispatch through primitive calls (string-ref, char->integer) vs a tight WAT loop. The function is not hot-path — it's called during `(read)` for number literals and by user code. The reader's own number parsing happens in the reader (WAT or compiled ECE), not via this primitive.

**[None] boolean? regression** → ECE implementation has been in the prelude and tested since the equality migration. This is pure host cleanup.

**[Low] Edge case divergence** → CL `ece-string->number` trims whitespace; WASM does not. Choosing strict (no trimming) is safer and simpler. If trimming is needed, callers can use `string-trim`.
