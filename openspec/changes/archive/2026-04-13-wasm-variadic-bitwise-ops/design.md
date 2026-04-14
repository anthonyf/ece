## Context

The WASM primitive dispatch lives in `$apply-primitive` in `wasm/runtime.wat`. After PR #150, the dispatch arms for 76-80 look like this:

```wat
;; 76 = bitwise-and
(if (i32.eq (local.get $id) (i32.const 76))
  (then (return (call $make-fixnum-or-float (i32.and
    (call $trunc-to-i32-wrap (call $to-f64 (call $arg1 (local.get $args))))
    (call $trunc-to-i32-wrap (call $to-f64 (call $arg2 (local.get $args)))))))))
```

Two explicit reads (`$arg1`, `$arg2`), one i32 op, boxed via `$make-fixnum-or-float`. No iteration over `$args`. If a caller passes three values, the third is in the args list but never read.

Contrast with `$fold-add`, the existing variadic iterator for `+`:

```wat
(func $fold-add (param $args (ref null eq)) (result (ref null eq))
  (local $acc f64)
  (local $cur (ref null eq))
  ...
  (block $done
    (loop $loop
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      (local.set $acc (f64.add (local.get $acc)
        (call $to-f64 (call $xcar (local.get $cur)))))
      (local.set $cur (call $xcdr (local.get $cur)))
      (br $loop)))
  ...)
```

It walks the args pair list via `$xcar`/`$xcdr`, handles the empty-list case (the loop exit), and returns a wrapped result. The bitwise fold helpers should follow exactly the same shape, with two differences:
1. The accumulator is `i32` (not `f64`), since bitwise ops produce i32 results.
2. The starting value is the identity element (different for AND vs OR/XOR).

## Goals / Non-Goals

**Goals:**
- `bitwise-and`, `bitwise-or`, `bitwise-xor` behave identically on CL and WASM for any argument count from 0 to the configurable `$apply-primitive`-arg-list-length maximum.
- A regression test in `tests/ece/common/` exercises 0, 1, 2, 3, 4, and 5 argument counts for each primitive, on both runtimes, catching future regressions.
- `src/sha1.scm`'s 3- and 4-way XOR/OR call sites go back to the natural variadic form — the nested-binary workaround from PR #150 is lifted.
- No change to the CL side; the CL primitives are already variadic.

**Non-Goals:**
- No change to `bitwise-not` (primitive 79, unary) or `arithmetic-shift` (primitive 80, strictly binary). Both are the right arity by construction.
- No reworking of how `$apply-primitive` receives its args list. The existing dispatch already passes `$args` to every arm uniformly; we're just iterating it now.
- No performance tuning. The fold helpers are the obvious shape, and the 2-arg hot path gets one extra function call compared to the inlined dispatch — measurable if we profile, but nowhere near the critical path of real ECE workloads.
- No change to type error reporting. If a caller passes a non-number to a bitwise op, the fold helper still gets a runtime trap from `$to-f64`'s `ref.cast`. That matches the existing 2-arg behaviour; improving it is a separate concern.

## Decisions

### 1. Three separate helpers, not a generic one with an operator parameter

**Choice:** Write `$fold-bitwise-and`, `$fold-bitwise-or`, and `$fold-bitwise-xor` as three distinct functions. Each is ~25 lines. The bodies differ only in (a) the accumulator's initial value and (b) which i32 op is used inside the loop.

**Rationale:** WASM doesn't have function-pointer-as-parameter semantics in a form that would let us pass `i32.and` as a value to a generic helper. The alternatives would be:
- A single function with a runtime switch on an enum parameter. Adds one extra conditional per loop iteration. Clutters the code.
- Three thin wrappers around a shared inner loop passed as a host function via `call_indirect`. Possible but requires adding the three helpers to a table. Overkill.

Three explicit functions are the cleanest WAT-idiomatic choice, and the code duplication is small (the loop shell is ~8 lines, the differing parts are 2 lines each).

### 2. Accumulator is `i32`, not `f64`

**Choice:** The fold accumulator is an i32 initialized to the identity element (`-1` for AND, `0` for OR/XOR). Each iteration reads the current arg via `$to-f64` (which handles both fixnum and float-box), wraps it to i32 via `$trunc-to-i32-wrap` (PR #150's helper — preserves the low 32 bits without trapping on large unsigned values), and combines into the accumulator.

**Rationale:** Bitwise operations are inherently integer operations. `$fold-add` uses f64 because add is inherently real-valued and may escalate to float if any input is a float. Bitwise doesn't have that — all inputs are coerced to integer semantics regardless. Using f64 would just require converting at every loop iteration.

**Alternative considered:** Keep the f64-based pattern for consistency with `$fold-add`, converting to i32 only at the end. Rejected — f64 has enough precision (2^53) that accumulating XOR through f64 would be lossless in practice, but the conceptual mismatch (storing bitwise results as floats) makes the code confusing. The i32 accumulator is both correct and readable.

### 3. Identity elements match CL

**Choice:** The fold helpers start from these identity values:
- `$fold-bitwise-and`: `-1` (all bits set — AND with everything preserves the argument)
- `$fold-bitwise-or`: `0` (no bits set — OR with anything preserves the argument)
- `$fold-bitwise-xor`: `0` (XOR with 0 is identity)

These match `(logand)`, `(logior)`, and `(logxor)` in Common Lisp, which is what the ECE CL side already delegates to. Scheme standards don't universally define these zero-arg cases, but since ECE's CL side accepts them, the WASM side must too for cross-runtime parity.

**Scenario:** `(bitwise-and)` with zero arguments must return `-1` on both runtimes. Same with `(bitwise-or)` and `(bitwise-xor)` returning `0`.

### 4. Revert SHA-1's nested-binary workaround

**Choice:** In the same PR as the runtime fix, revert `src/sha1.scm`'s `sha1/f` (rounds 20-39 and 60-79) and `sha1/extend-words!` back to the natural variadic form. Drop the apologetic comments explaining the workaround.

**Rationale:** Landing the runtime fix without reverting the workaround leaves ECE source code "half fixed": the underlying bug is gone but the cosmetic fallout remains. It also makes the fix easier to verify — SHA-1 passing after the revert proves the variadic dispatch works end-to-end on real code, not just on synthetic test cases.

**Alternative considered:** Ship the runtime fix alone, leave sha1.scm as-is, let a future reader revert the workaround when they notice it. Rejected — the workaround is only there because of this bug. Leaving it behind creates archaeological cruft.

## Risks / Trade-offs

- **Slightly slower 2-arg dispatch.** The common case (`(bitwise-or a b)`) now goes through `$fold-bitwise-or` instead of inline `i32.or`. That's one extra function call per bitwise op. For SHA-1, which is allocation-dominated anyway, this is noise. For any future hot path we'd measure and inline — but there's no evidence any current caller is bottlenecked on bitwise dispatch overhead.
- **Bitwise on non-numbers still traps rather than producing a nice error.** Same as before — out of scope.
- **No type check on zero-arg case.** `(bitwise-and)` with zero args returns `-1` as a fixnum. If a caller was relying on a "must have at least one arg" runtime check, they don't get one. The CL side doesn't enforce arity either (it silently accepts zero args and returns the identity), so we match that. Documented in the spec's zero-arg scenarios.

## Migration Plan

Not applicable — this is a pure correctness fix. No ECE code was relying on the old (buggy) silent-arg-drop behaviour, and if someone wrote code that worked on WASM by accident because they only ever tested with 2 args, it will continue to work for those 2 args and start working correctly for 3+.

The one in-tree caller of the variadic form was SHA-1 via the nested-binary workaround. The revert to variadic form in the same PR exercises the new path end-to-end.

## Open Questions

- **Should `$fold-bitwise-xor` also support a generic fold shape to allow future user-defined bitwise reductions?** No — ECE doesn't expose fold-over-bits primitives at the user level. If a need arises, add it then.
- **Is the accumulator type (i32) the right choice if we someday add BigInt-style arbitrary-precision integers to ECE?** BigInts would require a new primitive representation anyway, at which point the fold helpers would be rewritten. The i32 choice is correct for the current 32-bit bitwise semantics and doesn't block a future BigInt path.
