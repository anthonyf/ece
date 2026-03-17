## Context

ECE compiles Scheme to register machine instructions and appends them to a single global instruction vector (`*global-instruction-vector*`). Procedure entry points, continuation return addresses, and branch targets are all absolute offsets into this vector. The vector currently holds ~62K instructions after a full image build.

The `compile-to-host-cl` change demonstrated that compiling these instructions to native CL code works — the codegen produces correct `tagbody/go` code with chunked functions. However, the monolithic vector creates a scaling problem: SBCL cannot compile or even load the 28MB, 606K-line generated file. The chunking workaround (splitting at arbitrary 4000-instruction boundaries) treats the symptom, not the cause.

The root issue is that the instruction vector has no internal structure. Every `(load ...)` appends to the same array, making PCs fragile (one file's recompilation shifts all subsequent PCs) and preventing independent compilation of subsets.

Prior art from Erlang/BEAM (per-module code with hot reload), Chez Scheme (per-file `.so` objects), and the JVM (per-class bytecode with symbolic linking) shows that per-file compilation units with dynamic cross-unit dispatch is a proven, flexible architecture.

## Goals / Non-Goals

**Goals:**
- Split the global instruction vector into per-file spaces with local PCs
- Enable independent codegen per space (one host file per space, each independently compilable)
- Enable incremental recompilation (recompile one space without affecting others)
- Preserve `call/cc`, TCO, and all register machine semantics
- Redefine the image as a collection of compiled spaces + environment state
- Establish the architecture that maps directly to WASM modules for the browser port

**Non-Goals:**
- Module system with explicit imports/exports or namespaces (the environment stays global and flat)
- WASM or JS backends (Phase 2 — but the architecture supports them)
- Optimizing cross-space call performance (correctness first)
- Changing the ECE compiler's instruction output (the compiler is unaware of spaces)

## Decisions

### 1. Space-qualified addresses: `(space-id . local-pc)` pairs

**Choice:** Procedure entry points and continuation return addresses become cons pairs of `(space-id . local-pc)` instead of bare integers. `space-id` is a small integer index into the space registry.

```lisp
;; Today
(make-compiled-procedure 4523 env)
(compiled-procedure-entry proc) → 4523

;; With spaces
(make-compiled-procedure (cons 2 523) env)
(compiled-procedure-entry proc) → (2 . 523)
```

**Why:** This is the minimal change to the address representation. A cons pair is cheap to allocate and destructure. The space-id is a fixnum index, and the local-pc is a fixnum offset — both fit in a cons without boxing overhead. All address comparisons and jumps go through `compiled-procedure-entry` and the executor, so the change is localized.

**Alternative considered:** Tagged integers (high bits = space, low bits = PC). Rejected — bit manipulation obscures the semantics, and CL fixnums would limit the address space unnecessarily. A cons pair is clearer and has no practical size limit.

**Alternative considered:** Keep bare integers with a global-to-local translation table. Rejected — this preserves the fragile global addressing that caused the problem.

### 2. Space registry: a vector of space records

**Choice:** The runtime maintains `*space-registry*`, a vector of space records. Each space record holds:
- `instructions`: the instruction array (source form) for this space
- `resolved-instructions`: the resolved instruction array (with `op-fn` pointers)
- `label-table`: local label → local-PC hash table
- `name`: source identifier (filename or gensym for REPL)
- `compiled-fn`: the compiled host function for this space (nil if interpreted)

```lisp
(defstruct space
  name
  instructions          ; source instructions (adjustable vector)
  resolved-instructions ; resolved instructions (adjustable vector)
  label-table           ; symbol → local-pc
  compiled-fn)          ; host function or nil
```

**Why:** A struct gives named access to space components. The registry is a simple vector indexed by space-id, making lookup O(1). The separation of source and resolved instructions mirrors the existing `*global-instruction-source*` / `*global-instruction-vector*` split.

### 3. Assembler targets a space, not the global vector

**Choice:** `assemble-into-global` becomes `assemble-into-space`. It takes a space-id (or creates a new space) and appends instructions to that space's arrays. Labels are registered in the space's local label table with local PCs.

```scheme
;; Today
(define (ece-assemble-into-global instruction-list)
  (define start-pc (%instruction-vector-length))
  ...)

;; With spaces
(define (ece-assemble-into-space instruction-list space-id)
  (define start-pc (%space-instruction-length space-id))
  ...)
```

`(load "file.scm")` creates a new space named after the file, assembles all forms into it, and registers it. The REPL uses a persistent "repl" space for interactive expressions.

**Why:** This is the natural boundary — each file is independently assembled. The compiler doesn't change; it still produces instruction lists. Only the assembler's target changes.

### 4. Single-loop executor with space-id local variable

**Choice:** One `execute-instructions` function, one `tagbody` loop. The current space-id and instruction array are local variables. Cross-space jumps update these locals and `(go loop-start)` — no throw/catch, no dispatcher function, no struct allocation.

```lisp
(defun execute-instructions (initial-space-id initial-pc initial-env ...)
  (let ((space-id initial-space-id)
        (instrs (compilation-space-resolved-instructions
                  (aref *space-registry* initial-space-id)))
        (ltab (compilation-space-label-table
                (aref *space-registry* initial-space-id)))
        (pc initial-pc)
        ...)
    (tagbody
     loop-start
       (let ((instr (aref instrs pc)))
         ;; ... dispatch as today ...
         ))))
```

On a cross-space jump (goto reg, apply-compiled-procedure):

```lisp
;; Instead of: (throw 'space-exit (make-space-exit-request ...))
;; Just:
(let ((target-space (car addr))
      (target-pc (cdr addr)))
  (unless (eql target-space space-id)
    (setf space-id target-space)
    (let ((cs (aref *space-registry* target-space)))
      (setf instrs (compilation-space-resolved-instructions cs))
      (setf ltab (compilation-space-label-table cs))))
  (setf pc target-pc)
  (go loop-start))
```

**Why:** The original design used `throw`/`catch` to exit one executor and re-enter another through a dispatcher. This caused heap exhaustion during image builds — every cross-space return (which happens constantly when prelude functions are called from other files) allocated a `space-exit-request` struct and unwound the tagbody + handler-bind. Spaces are a codegen/compilation concept, not an execution concept. The executor doesn't need separate functions per space — it just needs to know which instruction array to fetch from. A cross-space jump becomes 2 `setf`s + 1 `aref`, with zero allocation and zero unwinding.

**Deleted:** `space-exit-request` struct, `execute-space-dispatch` function. These are no longer needed.

### 5. Cross-space jumps: inline space switch

**Choice:** Within a space, `goto (label X)` and `branch (label X)` are direct jumps (same as today). `goto (reg continue)` and apply-compiled-procedure extract the space-id from the qualified address. If it differs from the current space, update the `space-id`, `instrs`, and `ltab` locals. Then set `pc` and `(go loop-start)`. Same-space jumps skip the space switch — just a fixnum comparison.

```lisp
;; goto (reg continue) — unified, no throw/catch:
(let ((addr (get-reg (cadr dest))))
  (cond
    ((consp addr)
     (let ((target-space (car addr))
           (target-pc (cdr addr)))
       (unless (eql target-space space-id)
         (setf space-id target-space)
         (let ((cs (aref *space-registry* target-space)))
           (setf instrs (compilation-space-resolved-instructions cs))
           (setf ltab (compilation-space-label-table cs))))
       (setf pc target-pc)))
    ((numberp addr) (setf pc addr))     ; backward compat
    (t (setf pc (resolve-label addr)))) ; symbol label
  (go loop-start))
```

In compiled host code, the codegen still emits per-space functions. Cross-space jumps return to a thin outer dispatch loop (just a `funcall` loop, not throw/catch):

```lisp
;; Generated for goto (reg continue):
(let ((target-space (car continue))
      (target-pc (cdr continue)))
  (if (eql target-space +this-space-id+)
      (progn (setf pc target-pc) (go --entry-dispatch--))
      (return-from this-space
        (values target-space target-pc val env proc argl continue stack))))
```

**Why:** Most jumps are within the same space (a function returning to its caller in the same file). The common case is one fixnum comparison. Cross-space jumps add one `aref` to swap the instruction array reference. No allocation, no unwinding, no function call overhead.

### 6. `call/cc` with space-qualified addresses

**Choice:** `call/cc` captures the same state as today — all six registers plus the stack. The `continue` register already contains a space-qualified address, so continuations automatically capture cross-space return points. Restoring a continuation sets `continue` to the captured value, and the dispatcher routes to the correct space.

**Why:** No special handling needed. The key insight is that `call/cc` doesn't know or care about spaces — it captures registers, and the address representation flows through naturally. A continuation captured in space 2 with `continue = (0 . 4523)` will resume in space 0 at PC 4523 when invoked, because the dispatcher reads the space-id from `continue`.

### 7. Codegen emits one file per space

**Choice:** The codegen iterates the space registry and emits one CL source file per space. Each file contains:
1. A `defun` with a `tagbody` for that space's instructions
2. Entry dispatch for the space's local PCs
3. Cross-space exit via `return-from` when a jump targets a different space

No chunking needed — individual spaces are small enough for SBCL to compile (the largest space, the prelude, has ~5000 instructions, well within SBCL's limits).

```lisp
;; Generated: space-002-stdlib.lisp
(defun ece-space-2 (pc val env proc argl continue stack)
  (declare (optimize (speed 3) (safety 1)))
  (let ((flag nil))
    (block ece-space-2
      (tagbody
       --entry-dispatch--
        (case pc (0 (go L0)) (1 (go L1)) ... (N (go LN))
          (t (return-from ece-space-2 ...)))
       L0 ...
       ...))))
```

**Why:** This is what the chunking in `compile-to-host-cl` was trying to achieve — independently compilable units. Spaces provide the natural boundaries. No arbitrary splitting needed.

### 8. Image as a collection of space files

**Choice:** The "image" is a manifest file listing the spaces in load order, plus one host file per space, plus an environment reconstruction file.

```
image/
  manifest.lisp         ;; load order, space metadata
  space-000-prelude.lisp
  space-001-stdlib.lisp
  space-002-game.lisp
  env.lisp              ;; (define-variable! ...) calls to rebuild *global-env*
```

`save-image!` emits this directory. `load-image!` loads the files in manifest order. For CL, each `.lisp` is compiled to a FASL for fast loading. For browser targets, each space becomes a `.wasm` module.

**Why:** The image is no longer a binary blob — it's human-readable host source. Each space can be inspected, diffed, and recompiled independently. The binary image format (`save-image!` / `load-image!` in runtime.lisp) remains available as a fast-path for CL development but is no longer required.

### 9. REPL space: interpreted, ephemeral

**Choice:** The REPL uses a dedicated space (space-id 0 or a well-known ID) for interactive expressions. This space is always interpreted (never compiled to host code). REPL-defined functions are procedures whose entry points reference the REPL space.

When the user defines a function at the REPL, it goes into the REPL space. When compiled code calls it via `lookup-variable-value`, the dispatcher routes to the REPL space's interpreter. This replaces the "dual-zone" concept with a per-space property.

**Why:** The REPL needs to execute dynamically compiled code without a codegen step. Making it a space (rather than a special zone) unifies the architecture — every space is either compiled or interpreted, and the dispatcher handles both uniformly.

### 10. Migration from global vector

**Choice:** Implement spaces alongside the existing global vector, with a compatibility layer that makes the global vector behave as "space 0." Migrate incrementally:
1. Add space infrastructure (registry, qualified addresses, dispatcher)
2. Make the existing global vector the initial space (space 0)
3. Modify `(load ...)` to create new spaces
4. Update codegen to emit per-space files
5. Remove the global vector once all code uses spaces

**Why:** Big-bang migration risks breaking everything at once. The compatibility approach lets us validate each step against the existing test suite.

## Risks / Trade-offs

**[Address representation overhead]** Every procedure entry and continuation address becomes a cons pair instead of a fixnum. This adds allocation pressure. Mitigation: cons pairs are cheap in CL (two words), and the number of `make-compiled-procedure` and continuation captures is small relative to total instruction execution. Profile after implementation.

**[Cross-space call cost]** Calls between spaces go through the dispatcher (vector lookup + funcall). Mitigation: most calls are within a space (same file). Cross-file calls are relatively rare in a typical program. The dispatcher is O(1) — one `aref` on the space registry.

**[Space explosion]** Many small files could create many spaces. Mitigation: spaces are lightweight (a vector of instructions + a hash table). Hundreds of spaces would be fine. The REPL generates one space, not one per expression.

**[Backward compatibility]** Existing binary images use bare integer PCs. Mitigation: the migration path (Decision 10) keeps the global vector as space 0 initially. Binary image load/save can be adapted to the space model or retained as a legacy path.

**[`call/cc` across spaces]** A continuation captured in one space and invoked from another must correctly route through the dispatcher. Mitigation: this works by construction — `continue` holds a qualified address, and the dispatcher reads it. Test explicitly with cross-space continuation tests.

**[Prelude size]** The prelude may still be large enough (~5000 instructions) to push SBCL's limits as a single `tagbody`. Mitigation: 5000 labels is well within SBCL's capacity (the problem was 62K). If needed, the prelude can be split into multiple files (it already has logical sections).
