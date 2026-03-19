## Context

ECE's register machine executes instructions via `execute-instructions` — a `tagbody/go` loop that reads each instruction from the global instruction vector, dispatches on its type (`assign`, `test`, `branch`, `goto`, `save`, `restore`, `perform`), evaluates operands, and advances the PC. This works but pays a per-instruction cost: array access, `case` dispatch, operand list traversal, and `call-op` function application. The operation functions themselves (`op-fn` slots) are already pre-resolved at assembly time, but the instruction envelope around them is interpreted every time.

A codegen tool eliminates this overhead by translating the instruction vector into CL code where each instruction becomes direct CL — `setf` for assigns, direct `funcall` for operations, `go` for branches. More significantly, the codegen output serves as an **alternative image format**: the generated file includes both compiled code and environment setup, making it a self-contained executable image. For browser targets (Phase 2), this means the generated file IS the image — no binary serializer, no deserializer, no interpreter needed for shipped games.

The register machine is preserved — it's what gives ECE `call/cc`, TCO, and continuations. The codegen doesn't replace the register machine; it compiles register machine instructions to native host operations. The six registers (`val`, `env`, `proc`, `argl`, `continue`, `stack`) remain explicit local variables. `goto (reg continue)` becomes a host-level jump. `save`/`restore` become push/pop on the stack variable.

This is the first phase of the compile-to-host strategy that will later target WASM and JS. The CL backend validates the architecture on a platform where we already have a working test suite and REPL.

## Goals / Non-Goals

**Goals:**
- Build a codegen tool that translates an instruction vector into chunked CL `defun`s with `tagbody/go`
- Produce a self-contained output file that serves as an image (compiled code + environment setup)
- Support a dual-zone executor: compiled zone (generated CL) + interpreter zone (existing `execute-instructions`)
- Cross-zone calls and returns via `goto (reg continue)` — just PC values, no special bridging
- `call/cc` works transparently across zones (same registers, same stack)
- REPL-compiled code runs on the interpreter; pre-compiled game code runs on native CL
- Measure the speedup over the interpreted executor
- Establish a codegen architecture reusable for WASM and JS backends

**Non-Goals:**
- WASM or JS backends (Phase 2)
- Browser runtime, DOM, canvas (Phase 2/3)
- FFI for external libraries (separate proposal)
- Modifying the compiler — the codegen operates on the output of the existing compiler/assembler
- JIT compilation at runtime — the codegen is a build-time tool

## Decisions

### 1. Codegen output: chunked `tagbody` functions

**Choice:** Generate multiple CL functions (`ece-compiled-chunk-N`), each containing a `tagbody` with labels for a range of ~4000 instructions. An outer dispatch function (`ece-compiled-zone`) routes to the correct chunk based on PC.

```lisp
;; Generated chunk function (one of ~16 for a 62K instruction image)
(defun ece-compiled-chunk-0 (pc val env proc argl continue stack)
  (declare (optimize (speed 3) (safety 1)))
  (let ((flag nil))
    (block ece-compiled-zone
      (tagbody
       --entry-dispatch--
        (case pc
          (0 (go L0)) (1 (go L1)) ... (3999 (go L3999))
          (t (return-from ece-compiled-zone
               (values pc val env proc argl continue stack))))
       L0 (setf val 42)
       L1 ...
       ;; Fall through exits chunk
       (setf pc 4000)
       (return-from ece-compiled-zone
         (values pc val env proc argl continue stack))))))

;; Outer dispatch loop
(defun ece-compiled-zone (pc val env proc argl continue stack)
  (loop
    (if (>= pc limit) (return (values pc val env proc argl continue stack)))
    (let ((chunk (floor pc chunk-size)))
      (multiple-value-setq (pc val env proc argl continue stack)
        (case chunk
          (0 (ece-compiled-chunk-0 pc val env proc argl continue stack))
          (1 (ece-compiled-chunk-1 pc val env proc argl continue stack))
          ...
          (t (return (values pc val env proc argl continue stack))))))
    (when (>= pc limit)
      (return (values pc val env proc argl continue stack)))))
```

**Why:** A single `tagbody` with 62K labels causes SBCL's compiler to overflow its stack. Splitting into chunks keeps each function compilable while preserving the same execution semantics. Jumps within a chunk use direct `go`; jumps across chunks exit via `return-from` and re-enter through the outer dispatch loop.

**Chunk boundary handling:** Each instruction knows its chunk range (`chunk-start`, `chunk-end`). Intra-chunk jumps use `(go LN)`. Cross-chunk jumps set `pc` and `return-from`, letting the outer loop re-dispatch. This adds one `case` dispatch per cross-chunk jump — minimal overhead since most jumps are within-chunk.

### 2. Codegen output as image format

**Choice:** The generated CL file is a self-contained image. It includes:
1. Operation table initialization (mapping operation names to CL functions)
2. Chunked compiled zone functions (the compiled instructions)
3. Outer dispatch function
4. Zone limit and function pointer setup

For Phase 2 (browser targets), the codegen will also emit environment reconstruction code, making the output file the complete image — no binary serializer or deserializer needed.

**Why:** Eliminates ~550 lines of binary image serialization code from the browser porting surface. The codegen output IS the deployable artifact. For CL development, the existing binary image format remains available (faster to load than re-evaluating generated source).

### 3. Dual-zone boundary: PC range check

**Choice:** The compiled zone covers PCs 0 through `compiled-limit`. Any PC >= `compiled-limit` falls to the interpreter. The executor checks once per zone transition, not per instruction.

```lisp
(defun ece-dual-zone-execute (start-pc env ...)
  (loop
    (if (< pc compiled-limit)
        ;; Compiled zone — returns when PC exits range
        (multiple-value-setq (pc val env proc argl continue stack)
          (ece-compiled-zone pc val env proc argl continue stack))
        ;; Interpreter zone — returns when PC exits range
        (multiple-value-setq (pc val env proc argl continue stack)
          (execute-instructions-dynamic pc val env proc argl continue stack))
        )))
```

When the compiled zone executes a `goto (reg continue)` and the target PC is >= `compiled-limit`, it returns control to the outer loop, which dispatches to the interpreter. Vice versa — the interpreter returns when PC drops below `compiled-limit`.

**Why:** Zero overhead within a zone. The boundary check happens only on zone transitions (procedure calls/returns that cross the boundary). Most execution stays within one zone for extended periods.

### 4. Register passing between zones: multiple values

**Choice:** Zones communicate via CL `multiple-value-return` of all registers. When a zone exits (PC moves to the other zone), it returns `(values pc val env proc argl continue stack)`. The outer loop receives these and passes them to the next zone.

**Why:** No shared mutable state besides the function arguments. Each zone owns its registers as local variables (just like `execute-instructions` today). Clean, functional boundary.

### 5. Operation table: name-based index via source instructions

**Choice:** The codegen reads from the **source** instruction vector (`*global-instruction-source*`), which contains `(op name)` forms rather than resolved `(op-fn #'function)` objects. Operations are referenced via a name-indexed table: `(aref *compiled-zone-op-table* N)`.

```lisp
;; Generated: operation table initialization
(build-compiled-zone-op-table '(COMPILED-PROCEDURE-ENV EXTEND-ENVIRONMENT
                                 LOOKUP-VARIABLE-VALUE LEXICAL-REF LIST ...))

;; Generated: operation call
L42 (setf val (funcall (aref *compiled-zone-op-table* 2) 'X env))
```

The `build-compiled-zone-op-table` function resolves operation names to CL function objects at load time, using the same resolution pipeline as the interpreter. The current image has 19 unique operations.

**Why:** CL function objects cannot be serialized as source literals. Using the source instruction vector with symbolic operation names allows the generated code to be a plain text file that rebuilds the operation table at load time. This also directly supports cross-platform codegen — WASM/JS backends will use the same name-based approach to emit their own operation lookups.

### 6. Entry dispatch: `case` per chunk

**Choice:** Each chunk function starts with a `case` on the initial PC to jump to the right label within that chunk. The outer `ece-compiled-zone` function has a `case` on the chunk index.

**Why:** CL `tagbody` doesn't support computed goto. The `case` is the standard CL idiom. With chunking, each chunk's `case` has ~4000 entries (not 62K), keeping it within SBCL's optimization limits. The outer dispatch `case` has ~16 entries.

### 7. `goto (reg continue)` — chunk-aware zone exit

**Choice:** Every `goto (reg continue)` in a chunk checks if the target PC is within the current chunk. If yes, `go` to the label via the chunk's entry dispatch. If no, return to the outer loop.

```lisp
;; Generated for: (goto (reg continue))
L99 (setf pc continue)
    (if (and (>= pc chunk-start) (< pc chunk-end))
        (go --entry-dispatch--)
        (return-from ece-compiled-zone
          (values pc val env proc argl continue stack)))
```

The outer `ece-compiled-zone` loop then either re-dispatches to the correct chunk (if still in compiled range) or exits to the interpreter zone.

**Why:** Most returns go back to a PC within the same chunk (procedure-local returns). The two-level dispatch (chunk-local then zone-level) keeps the common case fast.

### 8. Label inference for compacted images

**Choice:** After image compaction, some labels may be stripped from the global label table. The codegen builds its own comprehensive label map by: (a) copying the global label table, then (b) scanning instructions for label references not in the table and inferring their target PCs from instruction context.

For example, `MC-AFTER-CALL-N` labels (continuation return points) point to the first instruction after a call sequence. The codegen looks forward past `assign`/`goto` instructions to find the return point.

**Why:** Image compaction removes unreferenced labels to save space. The codegen needs all labels referenced by any instruction. Rather than preventing compaction from removing labels (which would enlarge the image), the codegen infers missing labels on demand. In practice, only ~1 of ~9872 label references was missing after compaction.

### 9. Error sentinel handling in operations

**Choice:** Every `(assign reg (op ...))` instruction in the compiled zone wraps the operation call with error sentinel checking. If an operation returns an error sentinel, the generated code attempts to invoke the Scheme `error` procedure (if defined as a compiled procedure) by setting up the registers and jumping to its entry point.

```lisp
(let ((--result-- (funcall (aref *compiled-zone-op-table* N) ...)))
  (if (ece-error-sentinel-p --result--)
      (let ((error-fn (ignore-errors (lookup-variable-value 'error *global-env*))))
        (if (and error-fn (compiled-procedure-p error-fn))
            (progn
              (setf proc error-fn)
              (setf argl (cons (ece-error-sentinel-message --result--)
                               (ece-error-sentinel-irritants --result--)))
              (setf pc (compiled-procedure-entry error-fn))
              (cond ((and (>= pc chunk-start) (< pc chunk-end))
                     (go --entry-dispatch--))
                    (t (return-from ece-compiled-zone
                         (values pc val env proc argl continue stack)))))
            (error "~A" (ece-error-sentinel-message --result--))))
      (setf reg --result--)))
```

**Why:** This mirrors the interpreter's error handling. Operations return error sentinels rather than signaling CL conditions, allowing the Scheme-level error handler to process them. The compiled zone must handle these identically to maintain behavioral equivalence.

## Risks / Trade-offs

**[Large generated file]** The current image (~62K instructions) generates a ~28MB, ~606K-line CL source file. **SBCL cannot currently load this file** — it overflows the parser/compiler stack even with the chunked approach. This is the primary technical blocker. Potential mitigations:
- Reduce chunk size further (e.g., 1000 instructions per chunk)
- Use `compile-file` (FASL) instead of `load` on source
- Replace entry-dispatch `case` forms with vector-of-closures dispatch
- Binary search dispatch instead of linear `case`
- Split into multiple files loaded sequentially

**[Entry dispatch table size]** Each chunk's `case` form has ~4000 entries. The outer dispatch `case` has ~16 entries. If SBCL still struggles with 4000-entry `case` forms, the fallback is a vector of closures: `(funcall (aref dispatch-table pc))` where each closure is `(lambda () (go LN))`.

**[Operation table stability]** Operation names must match between codegen time and load time. If the runtime renames or removes an operation, the generated code breaks. Mitigation: operation names are stable — they map 1:1 to CL functions defined in `runtime.lisp`.

**[Debugging compiled zone]** Stack traces in the compiled zone show CL labels (L42) instead of ECE procedure names. Mitigation: The `*procedure-name-table*` maps PCs to ECE names. A wrapper can translate. Not critical for Phase 1.

**[Dual-zone complexity]** Two code paths for execution. Risk of subtle behavioral differences. Mitigation: The compiled zone is a mechanical translation of the same instructions the interpreter runs. The test suite validates both paths produce identical results. Run the full suite in dual-zone mode.
