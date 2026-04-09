## Context

ECE's compiler (SICP 5.5) currently handles `let`/`let*` via macro expansion to nested lambda applications. The `let` and `let*` macros in `prelude.scm` expand to `((lambda (vars...) body) inits...)`. The compiler never sees `let` — it compiles the resulting lambda application through the standard `mc-compile-application` → `mc-compile-lambda` → `mc-compile-proc-appl` path.

Internal `define` has a dedicated optimization in `mc-compile-lambda-body`: `mc-extract-define-names` scans the body, pre-allocates slots in the function's frame, and `mc-compile-define` uses O(1) `lexical-set!`. This creates a performance gap — `define` is zero-overhead while `let*` with N bindings creates N procedure objects, N call dispatches, and N `extend-environment` calls.

The compiler dispatch (`mc-compile`, line 684) routes expressions through a `cond` chain. `let`/`let*` are not recognized and fall through to macro expansion at line 703-711.

Environment representation:
- **CL**: cons chain of simple-vectors — `(cons #(val1 val2 ...) base-env)`. Enclosing = `cdr`.
- **WASM**: `$env-frame` struct with `$names`, `$vals` (array), `$enclosing` fields. Enclosing = `struct.get $env-frame $enclosing`.

## Goals / Non-Goals

**Goals:**
- Compile `let` and `let*` directly, eliminating lambda application overhead
- Correct `let*` sequential scoping (not `letrec*` — each binding visible only to subsequent inits)
- Correct `let` parallel binding (no init sees any of the let-bound names)
- Proper TCO when `let`/`let*` is in tail position
- Enforce internal `define` at beginning of body only (Racket-style)
- Both CL and WASM runtimes support the new `enclosing-environment` operation

**Non-Goals:**
- Optimizing named `let` (stays as `letrec` + lambda — correct and uncommon in tight loops)
- Folding `let` bindings into the enclosing function's frame (Level 2 optimization — deferred)
- Adding `#<undefined>` sentinel for uninitialized pre-allocated define slots
- Optimizing `letrec`/`letrec*` compilation (separate concern)

## Decisions

### 1. Compiler intercepts `let`/`let*` before macro expansion

Add `mc-compile-let` and `mc-compile-let*` to the compiler dispatch in `mc-compile` (around line 700), BEFORE the macro expansion fallthrough. Named `let` (`(let name ...)`) is detected and falls through to the existing macro path.

**Rationale:** The macros remain in `prelude.scm` for any non-compiled context, but the compiler bypasses them. This is the same pattern used for `define`, `if`, `begin`, etc. — they could be macros but the compiler handles them directly for performance.

**Insertion point:** After `mc-begin?` (line 701), before `mc-global-ref?` (line 702). The new predicates `mc-let?` and `mc-let*?` check for `(let ...)` and `(let* ...)` forms. Named let is detected by checking if the second element is a symbol.

### 2. `let*` compilation: single frame, progressive scoping

```
(let* ((x e1) (y e2) (z e3)) body)
```

Compiled instruction sequence:
```
;; Extend env with one frame containing 3 empty slots
assign env = (op extend-environment) '() '() env 3

;; Binding 1: compile e1 with OUTER lexical env (x,y,z not visible)
<compile e1> → val
perform (op lexical-set!) 0 0 val env

;; Binding 2: compile e2 with x visible at (0,0), y,z not visible
<compile e2> → val
perform (op lexical-set!) 0 1 val env

;; Binding 3: compile e3 with x at (0,0) and y at (0,1) visible
<compile e3> → val
perform (op lexical-set!) 0 2 val env

;; Body: all three visible
<compile body with target/linkage>

;; Env restore (non-tail only)
assign env = (op enclosing-environment) env
```

**Progressive scoping implementation:** The compiler builds the lexical env incrementally using `parameterize` on `*mc-compile-lexical-env*`. Before compiling each init, the frame in the lexical env contains only the names bound so far. After each `lexical-set!`, the next name is added. This is a compile-time-only operation — the runtime frame has all slots from the start.

**Alternatives considered:**
- N separate frames (current behavior) — correct but slow
- Pre-allocate all names in lexical env (like `define`) — incorrect `let*` semantics; forward references would silently return null instead of being unbound

### 3. `let` compilation: parallel binding via stack

```
(let ((x e1) (y e2)) body)
```

Compiled instruction sequence:
```
;; Compile all inits with outer env (no let-bound names visible)
<compile e1> → val
save val on stack
<compile e2> → val
save val on stack

;; Build argl and extend env
;; Pop values in reverse, construct argl
restore val → assign argl = (op list) val
restore val → assign argl = (op cons) val argl
assign env = (op extend-environment) '(x y) argl env 0

;; Body with all names visible
<compile body with target/linkage>

;; Env restore (non-tail only)
assign env = (op enclosing-environment) env
```

**Alternative considered:** Use empty frame + `lexical-set!` like `let*` but compile all inits first. This works but requires more instructions. Using `extend-environment` with a populated argl is simpler and reuses existing infrastructure.

### 4. TCO: linkage threading

When a `let`/`let*` is in tail position (linkage = `'return`), the body is compiled with `'return` linkage directly. No env restoration is emitted — the tail call abandons the let frame.

When not in tail position, the body is compiled with `'next` linkage, followed by env restoration and the outer linkage.

```scheme
(if (eq? linkage 'return)
    ;; Tail: body gets 'return, no restore
    (append env-extension
            (compile-body 'return))
    ;; Non-tail: body gets 'next, then restore env, then linkage
    (let ((after-let (mc-make-label 'after-let)))
      (append env-extension
              (compile-body 'next)
              restore-env
              (end-with-linkage linkage ...))))
```

This follows the same pattern as `mc-compile-proc-appl` (line 304-328) which handles tail/non-tail compiled procedure calls.

### 5. `enclosing-environment` operation

**CL runtime:** Add `enclosing-environment` function to `runtime.lisp` — simply `cdr` of the env (cons chain). Register in the operations hash table alongside `extend-environment`.

**WASM runtime:** Add to the operations dispatch in `runtime.wat` — `struct.get $env-frame $enclosing`. Register in the resolve-operations table.

Both are O(1) pointer reads.

### 6. Define-at-top enforcement

Add a validation pass in `mc-compile-lambda-body` after extracting define names. Walk the body forms: once a non-define, non-begin form is encountered, flag that expressions have started. If a subsequent `define` is found, signal a compile-time error.

`begin` at the top level of a body is transparent (its contents are spliced), consistent with R7RS.

**What counts as "beginning of body":**
- `(define ...)` forms
- `(begin ...)` forms whose contents are recursively checked
- `(define-macro ...)` forms (ECE extension, treated like define)

**What triggers "expressions have started":**
- Any other form (including `if`, `set!`, function calls, etc.)

### 7. Macro shadowing interaction

The existing macro-shadowing system (`*mc-compile-lexical-env*` + `mc-lexically-shadows-macro?`) works naturally with the new `let`/`let*` compilation. The names added to the lexical env during progressive scoping will shadow any macros with the same name, just as they do for internal `define`.

## Risks / Trade-offs

**[Risk] Existing code uses `define` after expressions** → Some ECE source files or tests may rely on the current permissive behavior. Mitigation: audit all `.scm` files for non-top defines before enabling enforcement. Fix or rewrite any violations. Can be done as a separate commit.

**[Risk] Bootstrap compatibility** → Old `.ecec` files use the macro-expanded `let` compilation. New compiler generates different instruction sequences. Mitigation: standard two-pass bootstrap (`make bootstrap`). First pass: boot from old `.ecec`, recompile all `.scm` → new `.ecec`. Second pass: boot from new `.ecec`, verify by recompiling again.

**[Risk] `env` register clobbering in `let` init compilation** → When compiling init expressions for `let`, the env register must remain stable (pointing to the outer env). The `preserving` mechanism already handles this for lambda compilation; verify it works for the new inline code path.

**[Trade-off] `let`/`let*` still creates one frame per binding group** → Unlike internal `define` (zero extra frames), `let`/`let*` creates one new frame. This is the correct trade-off: `define` has `letrec*` semantics (share function frame), while `let` creates a new scope. The Level 2 optimization (folding into enclosing frame) is deferred as a future enhancement.

**[Trade-off] Named `let` not optimized** → Named `let` continues through the macro path (`letrec` + lambda). This is acceptable because named `let` creates a recursive binding, which genuinely needs a closure.
