## Approach

### 1. Extend `$continuation` struct

```wat
;; Current
(type $continuation (struct
  (field $stack (ref null eq))
  (field $conts (ref null eq))))

;; After
(type $continuation (struct
  (field $stack (ref null eq))
  (field $conts (ref null eq))
  (field $winds (ref null eq))))  ;; captured *winding-stack*
```

### 2. Capture winding stack

In `capture-continuation` (op 21), pass `*winding-stack*` as the third argument. The `%raw-call/cc` compiled code already passes `(reg stack)` and `(reg continue)`. We need to also read `*winding-stack*` (a global variable) and pass it.

Option A: Add a third operand to capture-continuation that reads `*winding-stack*` via `lookup-variable-value`.

Option B: Store `*winding-stack*` in a WASM global (like `$global-env`) and read it directly in the capture-continuation handler. This avoids the overhead of a variable lookup.

**Recommended: Option B.** Add a `$winding-stack` global in WAT. The `dynamic-wind` function in the prelude updates it (already sets `*winding-stack*`). We add a primitive `%set-winding-stack!` that syncs the WAT global. Or, simpler: have the capture-continuation op look up `*winding-stack*` via the env.

Actually simplest: **Option A** — the compiler already knows how to compile `%raw-call/cc`. The `capture-continuation` operation takes `(stack, continue)`. We add `*winding-stack*` as a third operand by modifying the `%raw-call/cc` compilation to pass it.

But `%raw-call/cc` is a special form compiled by `mc-compile-callcc`. Let me check what it emits... Actually, the cleanest approach: store `*winding-stack*` in a WAT global alongside `$global-env`. The prelude's `dynamic-wind` function updates the ECE variable; we also sync the WAT global via a new primitive. Then `capture-continuation` reads the global directly.

### 3. Invoke handler: call `do-winds!`

The executor's continuation handler currently:
```
assign val (op car) (reg argl)        ;; val = argument
assign stack (op continuation-stack)  ;; stack = saved stack
assign cont (op continuation-conts)   ;; cont = saved return address
goto (reg cont)                       ;; resume
```

After: before restoring stack/cont, check if winding needs to happen:
```
assign val (op car) (reg argl)
;; If continuation's winds ≠ current *winding-stack*, call do-winds!
;; This is a perform that calls do-winds! as an ECE function
perform (op do-winds-for-continuation)  ;; transitions winding state
assign stack (op continuation-stack)
assign cont (op continuation-conts)
goto (reg cont)
```

The `do-winds-for-continuation` operation:
1. Read the continuation's `$winds` field
2. Compare with current `*winding-stack*` (from WAT global)
3. If equal, no-op
4. If different, invoke `do-winds!` via a nested `$execute` call (similar to `execute-from-pc`)

### 4. Simplify `call/cc`

```scheme
;; Before: wrapper lambda
(define-macro (call/cc receiver)
  (let ((saved (gensym)) (raw-k (gensym)) (val (gensym)))
    `(let ((,saved *winding-stack*))
       (%raw-call/cc (lambda (,raw-k)
                       (,receiver (lambda (,val)
                                    (do-winds! *winding-stack* ,saved)
                                    (,raw-k ,val))))))))

;; After: direct
(define-macro (call/cc receiver)
  `(%raw-call/cc ,receiver))
```

### 5. Serialization

Update `%ser/continuation` to include the winds field:
```
(%ser/continuation <stack> <conts> <winds>)
```

The winds field is a list of `(before . after)` pairs — these are compiled procedures. The env-frame serialization (PR #48) handles them.

## Key Decisions

- `do-winds!` at invoke time is a nested ECE function call. This adds slight overhead but only when winding is needed (common case: both stacks empty, identity check, skip).
- The `$winds` field serializes correctly because it's a list of pairs of compiled procedures — already handled by the serializer.
- CL runtime needs matching changes to the continuation struct.

## Risks

- Calling `do-winds!` from the executor's continuation handler requires a nested `$execute`. This is similar to `call_ece_proc` but happens mid-instruction. Need to ensure registers are properly saved/restored around it.
- The `*winding-stack*` sync between ECE variable and WAT global must be consistent. Every mutation of `*winding-stack*` in ECE code must also update the WAT global.
