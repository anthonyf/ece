## MODIFIED Requirements

### Requirement: WASM fixnum range covers the full i31 signed range
The WASM runtime SHALL represent fixnums as i31ref values with the identity encoding: `$make-fixnum` encodes an i32 `n` as `ref.i31 n`, `$fixnum-value` decodes via `i31.get_s`, and `$is-fixnum` is `ref.test (ref i31)`. The fixnum range is exactly the i31 signed range: `[-2^30, 2^30-1]` = `[-1073741824, 1073741823]`.

For any integer `n` in this range, `(make-fixnum-or-float n)` SHALL return a fixnum (not a float-box). For integers outside this range, `$make-fixnum-or-float` SHALL return a `$float-box` so that values remain representable even when they exceed i31 capacity.

Note: ECE does not expose `fixnum?` at the Scheme level — the fixnum/float-box distinction is runtime-internal. Scenarios below that reference a `fixnum?` predicate are describing the internal `$is-fixnum` helper.

#### Scenario: Encoding round-trip at the positive edge
- **WHEN** `(make-fixnum-or-float 1073741823)` is called (which is `2^30 - 1`)
- **THEN** the result SHALL be an i31ref fixnum (not a float-box)
- **AND** `$fixnum-value` on the result SHALL return `1073741823`
- **AND** `$is-fixnum` on the result SHALL return `#t`

#### Scenario: Encoding round-trip at the negative edge
- **WHEN** `(make-fixnum-or-float -1073741824)` is called (which is `-2^30`)
- **THEN** the result SHALL be an i31ref fixnum
- **AND** `$fixnum-value` on the result SHALL return `-1073741824`
- **AND** `$is-fixnum` on the result SHALL return `#t`

#### Scenario: Overflow one past the positive edge
- **WHEN** `(make-fixnum-or-float 1073741824)` is called
- **THEN** the result SHALL be a `$float-box` (not a fixnum)
- **AND** the float-box's f64 value SHALL equal `1073741824.0`

#### Scenario: Old 29-bit boundary values are now fixnums
- **WHEN** `(make-fixnum-or-float 536870912)` is called (old `2^29` overflow point)
- **THEN** the result SHALL be an i31ref fixnum
- **AND** `$fixnum-value` on the result SHALL return `536870912`
- **AND** previously this value would have been a float-box

#### Scenario: Arithmetic in the widened band stays fixnum
- **WHEN** `(+ 536870000 912)` is evaluated (result = `536870912`, in the old float-box band)
- **THEN** the result SHALL be a fixnum
- **AND** chained arithmetic `(+ 536870000 912 0)` SHALL also stay fixnum

### Requirement: Characters are heap-allocated $char structs with ASCII interning
Characters in the WASM runtime SHALL be instances of the `$char` struct type, which has two `i32` fields: `$codepoint` (the Unicode scalar) and `$tag` (a discriminator, always `0`). The second field exists because binaryen's `wasm-as` structurally deduplicates single-i32 struct types, and `$primitive` already occupies that shape — without the `$tag` field, `ref.test (ref $char)` and `ref.test (ref $primitive)` would be indistinguishable. Only `$codepoint` is read at runtime. The five helpers are:
- `$make-char(cp)` — for codepoints in `[0, 127]`, returns the pre-interned ASCII char; otherwise allocates a new `$char` struct with `$tag` set to `0`.
- `$char-codepoint(v)` — reads the `$codepoint` field of a `(ref $char)`.
- `$is-char(v)` — `ref.test (ref $char) v`.
- The ASCII intern table is a 128-element `(array (mut (ref $char)))` populated at module init with one `$char` struct per codepoint `0..127`. The `mut` modifier is required so the init function can populate slots via `array.set`.

`(ref.eq a b)` between two ASCII chars of the same codepoint SHALL return `#t`, because both reference the same interned struct. For non-ASCII chars, `ref.eq` SHALL NOT be assumed to imply equality — callers must use `char=?` (which compares codepoints).

#### Scenario: ASCII char interning
- **WHEN** `(make-char 97)` is called twice
- **THEN** both results SHALL be the same heap reference (the interned `#\a`)
- **AND** `(ref.eq result1 result2)` SHALL be `#t`

#### Scenario: Non-ASCII char allocation
- **WHEN** `(make-char 955)` is called (Greek lambda)
- **THEN** the result SHALL be a fresh `$char` struct with codepoint `955`
- **AND** `(char-codepoint result)` SHALL return `955`
- **AND** a second call to `(make-char 955)` MAY return a different heap reference (`ref.eq` between the two MAY be `#f`)

#### Scenario: Char codepoint round-trip
- **WHEN** a char is created with any codepoint `cp` in `[0, 0x10FFFF]`
- **THEN** `(char-codepoint (make-char cp))` SHALL return `cp`
- **AND** `(is-char (make-char cp))` SHALL return `#t`
- **AND** `(is-char (make-fixnum cp))` SHALL return `#f`

#### Scenario: char? does not report fixnums or specials
- **WHEN** `char?` is applied to any fixnum or any of the five specials (`#f`, `#t`, `'()`, `#!eof`, `void`)
- **THEN** the result SHALL be `#f`

### Requirement: Special singletons are heap-allocated struct instances
The five special singletons `#f`, `#t`, `nil`, `eof`, `void` SHALL each be represented as a unique module-level global holding a single struct instance. Each special has its own empty struct type (`$false-type`, `$true-type`, `$nil-type`, `$eof-type`, `$void-type`).

Comparison SHALL use `ref.eq` against the corresponding global. The semantics of `eq?`, `equal?`, `null?`, `eof-object?`, and boolean truthiness on these values SHALL be unchanged from prior behaviour.

#### Scenario: nil comparison
- **WHEN** `(null? '())` is evaluated
- **THEN** the result SHALL be `#t`
- **AND** internally this compiles to `ref.eq v $nil` where `$nil` is the singleton global

#### Scenario: Boolean false coercion
- **WHEN** `(if #f 1 2)` is evaluated
- **THEN** the result SHALL be `2`
- **AND** the dispatch on `#f` checks `ref.eq v $false`

#### Scenario: eof-object round-trip
- **WHEN** `(eof-object)` is called followed by `(eof-object? (eof-object))`
- **THEN** the second call SHALL return `#t`

#### Scenario: Specials are not fixnums and not chars
- **WHEN** any of the five specials is passed to `$is-fixnum` or `char?`
- **THEN** both SHALL return `#f`

### Requirement: $is-fixnum simplifies to a single ref.test
`$is-fixnum` SHALL test only that the value is an i31ref. No secondary bit-test on the payload is required, because i31ref is now used exclusively for fixnums.

#### Scenario: Fixnum type test on a fixnum
- **WHEN** `$is-fixnum` is called on the internal representation of `42`
- **THEN** the result SHALL be `#t`
- **AND** the underlying wasm check SHALL be a single `ref.test (ref i31) v`

#### Scenario: Fixnum type test on a non-fixnum
- **WHEN** `$is-fixnum` is called on a `#\a` char struct, a `$nil` singleton, or a `3.14` float-box
- **THEN** each SHALL return `#f`

### Requirement: Bootstrap regenerates on top of the new runtime
After this change lands, `make bootstrap` SHALL run twice cleanly — the second pass produces byte-identical `.ecec` files to the first pass (proving self-hosting stability under the new runtime representation). The `.ecec` serialization format is unchanged; only the in-memory representation changes.

#### Scenario: Self-hosting stability
- **WHEN** `make bootstrap` is run twice in succession after the runtime change
- **THEN** the second pass's `.ecec` outputs SHALL be byte-identical to the first pass's outputs
- **AND** `make test` SHALL pass with zero regressions on the re-bootstrapped artefacts
