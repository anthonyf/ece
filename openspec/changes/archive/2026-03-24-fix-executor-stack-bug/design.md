## Context

The WASM executor's save/restore mechanism uses a cons-based stack (same as CL). Save pushes a register value onto the stack; restore pops it. The compiler's `preserving` function generates save/restore pairs to protect registers across sub-expression evaluation. For complex nested arguments like `(string-append A B (loop (cdr xs) #f))`, multiple nested save/restore sequences are generated.

The CL executor handles these correctly. The WASM executor crashes on the same instructions. The instructions are confirmed identical (zero diffs via comparison tool).

## Goals / Non-Goals

**Goals:**
- Find the exact save/restore divergence between WASM and CL executors
- Fix the WASM executor bug
- Revert the ser-pair workaround to confirm the fix
- Add regression test for the pattern

**Non-Goals:**
- Changing the compiler's code generation
- Changing the save/restore model (cons-based stack is correct per SICP)
- Permanent trace infrastructure (remove after fix, or keep behind flag)

## Decisions

### 1. WASM trace: JS import callback

Add a `trace_save_restore` import to the WASM module:
```wat
(import "io" "trace_save_restore"
  (func $js-trace-sr (param i32 i32 i32 i32 i32 i32)))
  ;; params: pc, space-id, is-save(0/1), register-id, value-type, stack-depth
```

In the save handler (opcode 4), before/after the cons:
```wat
(call $js-trace-sr (local.get $pc) (local.get $space-id)
  (i32.const 1)  ;; is-save
  (struct.get $instr $a (local.get $instr))  ;; register-id
  (call $type-id-of (call $get-reg ...))  ;; value type
  (call $stack-depth (local.get $stack)))  ;; depth
```

Similarly for restore (opcode 5).

Guard with a global flag `$trace-sr-enabled` (set from JS). When flag is 0, skip the trace call entirely. V8 will optimize the branch away when the flag is constant 0.

### 2. CL trace: print-based

Add matching trace output in the CL executor's save/restore handlers:
```lisp
(|save|
  (when *trace-save-restore*
    (format t "SR ~A:~A save ~A type=~A depth=~A~%"
            space-id pc (cadr instr) (type-of (get-reg (cadr instr))) (length stack)))
  (push (get-reg (cadr instr)) stack))
```

### 3. Comparison approach

1. Run `serialize-value` on `(cons 1 ())` with CL trace → capture save/restore log
2. Run same with WASM trace → capture save/restore log
3. Diff the two logs — find first divergence
4. The divergence point reveals which save/restore is unbalanced or returns the wrong value

### 4. Stack depth helper

Add `$stack-depth` WAT function that walks the cons-list stack and counts pairs:
```wat
(func $stack-depth (param $s (ref null eq)) (result i32)
  (local $d i32)
  (block $done (loop $count
    (br_if $done (call $is-null (local.get $s)))
    (br_if $done (ref.is_null (local.get $s)))
    (local.set $s (call $cdr (ref.cast (ref $pair) (local.get $s))))
    (local.set $d (i32.add (local.get $d) (i32.const 1)))
    (br $count)))
  (local.get $d))
```

This is O(n) per call but only runs during tracing. Stack depth should never exceed ~50 for normal programs.

### 5. After the fix

- Revert the ser-pair workaround in prelude.scm (restore original `(string-append A B (loop ...))` pattern)
- Rebuild bootstrap
- Verify serialization tests still pass
- Add test for the specific pattern: `(string-append A B (recursive-call ...))` from prelude-compiled code

## Risks / Trade-offs

- **Trace overhead**: The JS callback per save/restore is expensive. But it's behind a flag and only used for debugging. Production builds have zero cost.
- **CL/WASM trace format matching**: The two executors have different internal representations (CL uses symbols for register names, WASM uses integers). The comparison script normalizes both formats.
- **Root cause might be subtle**: The bug might be in space-switching, handle management, or V8 GC interaction rather than save/restore itself. The trace might need to be expanded to cover more operations. Start with save/restore since that's the most likely culprit.
