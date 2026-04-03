## Context

The WASM runtime (`wasm/runtime.wat`) uses WASM GC typed structs for cons cells. The existing `$car`/`$cdr` functions take `(ref $pair)` — a typed reference — so every call site must first cast from `(ref null eq)` with `(ref.cast (ref $pair) ...)`. This cast is always required when traversing lists and adds visual noise.

Current pattern (182+ sites):
```wat
(call $car (ref.cast (ref $pair) (local.get $cur)))
```

Composed pattern (16 cadr + 4 caddr sites):
```wat
(call $car (ref.cast (ref $pair) (call $cdr (ref.cast (ref $pair) (local.get $src-pair)))))
```

## Goals / Non-Goals

**Goals:**
- Add casting helpers that accept `(ref null eq)` and do the cast internally
- Add composed `$cadr`/`$caddr` helpers
- Rewrite all call sites to use the helpers
- Preserve existing `$car`/`$cdr` for the few sites that already have a typed `(ref $pair)`

**Non-Goals:**
- Changing the `$pair` struct layout
- Changing the instruction format or execution semantics
- Adding helpers with fewer than 3 call sites (`$caar`, `$cdar`, `$cddr` have 0-1 uses each)

## Decisions

### 1. Naming: `$xcar`/`$xcdr` for casting variants

**Choice:** Name the casting variants `$xcar` and `$xcdr` (x = "extract" or "cross-cast").

```wat
(func $xcar (param $v (ref null eq)) (result (ref null eq))
  (struct.get $pair $car (ref.cast (ref $pair) (local.get $v))))

(func $xcdr (param $v (ref null eq)) (result (ref null eq))
  (struct.get $pair $cdr (ref.cast (ref $pair) (local.get $v))))
```

**Why:** Keeps existing `$car`/`$cdr` unchanged (they're used where a typed `$pair` ref is already available). Short names that are easy to type and grep for.

### 2. Composed helpers: `$cadr` and `$caddr` only

**Choice:** Add `$cadr` (16 sites) and `$caddr` (4 sites). Skip `$cddr` (0 sites), `$caar` (1 site), `$cdar` (1 site).

```wat
(func $cadr (param $v (ref null eq)) (result (ref null eq))
  (call $xcar (call $xcdr (local.get $v))))

(func $caddr (param $v (ref null eq)) (result (ref null eq))
  (call $xcar (call $xcdr (call $xcdr (local.get $v)))))
```

**Why:** Only add helpers that have 3+ call sites. The threshold avoids bloating the function table with rarely-used helpers.

### 3. Keep `$car`/`$cdr` unchanged

**Choice:** Don't modify the signatures of `$car`/`$cdr`. They remain `(ref $pair) → (ref null eq)`.

**Why:** Some call sites already have a typed `$pair` (e.g., after a local typed as `(ref $pair)`). Changing their signature would require touching those sites for no benefit. The new `$xcar`/`$xcdr` are additive.

## Risks / Trade-offs

**[Extra function call overhead]** Each `$xcar` call adds one level of indirection vs. inlining the cast. → Mitigation: WASM engines inline small functions aggressively. The assembly phase is not performance-critical (runs once at load time, not in the hot execution loop).

**[Two ways to do car/cdr]** Having both `$car` and `$xcar` means contributors must choose. → Mitigation: convention is simple — use `$xcar`/`$xcdr` unless you already have a `(ref $pair)`. The old `$car`/`$cdr` remain for typed contexts.
