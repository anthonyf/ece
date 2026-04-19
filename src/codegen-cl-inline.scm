;;;; ECE Inline Codegen — Common Lisp backend (Stage 1).
;;;;
;;;; Walks a compilation space's instruction vector and writes a CL source
;;;; file containing one (defun zone-NAME ...) whose body is the inlined
;;;; translation of those instructions. Primitive call sites whose identity
;;;; is statically known are spliced in via the :cl template body from
;;;; src/primitives.scm (reusing host-primitive-cl-body from codegen-cl.scm);
;;;; call sites with unknown primitives fall back to
;;;; (apply-primitive-procedure proc argl) against the runtime table.
;;;;
;;;; Stage 1 of the self-hosting roadmap — the compiled zone. See
;;;; openspec/changes/stage-1-inline-primitive-codegen/ for the design.
;;;;
;;;; Regenerate via the Makefile:
;;;;   make bootstrap/<space>-zone.lisp
;;;;
;;;; The generator is itself an ECE program. It is loaded by the build:
;;;;   (load "src/codegen-cl.scm")       ;; brings in *host-primitives*
;;;;   (load "src/primitives.scm")       ;; populates them
;;;;   (load "src/codegen-cl-inline.scm") ;; this file
;;;;   (generate-zone-cl! space-name output-path)
;;;;
;;;; Calling convention for every generated zone function:
;;;;   (defun zone-NAME (initial-pc initial-val initial-env initial-proc
;;;;                     initial-argl initial-continue initial-stack) ...)
;;;;   Returns (values pc val env proc argl continue stack) on zone exit.
;;;;
;;;; Determinism: identical inputs SHALL produce a byte-identical output file.
;;;; No gensym, no hash-table iteration order — all scans are linear in
;;;; instruction order.

;;; ─────────────────────────────────────────────────────────────────────────
;;; Sub-function splitting constants
;;; ─────────────────────────────────────────────────────────────────────────

(define chunk-size 4096)

(define (needs-splitting? count)
  (> count chunk-size))

(define (chunk-ctx-start ctx) (car ctx))
(define (chunk-ctx-end ctx) (cadr ctx))
(define (chunk-ctx-total ctx) (caddr ctx))

(define (in-chunk? pc ctx)
  (and (>= pc (chunk-ctx-start ctx))
       (< pc (chunk-ctx-end ctx))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Source abstraction: accept either a space-id symbol OR a code-object.
;;; Lets the same emitter walk bootstrap spaces (legacy) or archive code-
;;; objects (post §9.2). Once the space path retires (§11), these collapse
;;; to the code-object branch.
;;; ─────────────────────────────────────────────────────────────────────────

(define (cg/source-ref src pc)
  (if (code-object? src)
      (vector-ref (code-object-instructions src) pc)
      (%space-source-ref src pc)))

(define (cg/instruction-length src)
  (if (code-object? src)
      (code-object-length src)
      (%space-instruction-length src)))

(define (cg/label-entries src)
  (if (code-object? src)
      (code-object-label-entries src)
      (%space-label-entries src)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Top-level entry point
;;; ─────────────────────────────────────────────────────────────────────────

;;; ─────────────────────────────────────────────────────────────────────────
;;; Emission-context parameters (code-object zone path)
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Threaded via `parameterize` from the code-object entry point so that
;;; deeply-nested emitters (emit-const, emit-assign's label branch, etc.)
;;; can reach the archive's file-stem and the per-archive code-object
;;; index map without dragging them through every call signature.
;;;
;;; - *emit-file-stem* — string naming the archive file-stem (no extension).
;;;   Emitted into generated CL forms as the first half of (file-stem . co-key)
;;;   lookup keys. Zero value is #f — legacy space path leaves it unset.
;;; - *emit-co-index-map* — a hash-table-or-#f mapping nested code-objects
;;;   (eq-keyed) to their co-key (either the co's name symbol or its archive
;;;   index as an integer). Populated once per archive by
;;;   generate-all-zones-from-archive!; used by emit-const to find the key
;;;   for a (const <inner-co>) operand.
;;;
;;; Legacy space path does not set these — its emit-const branch never
;;; sees a code-object value (spaces don't have per-procedure identities).

(define *emit-file-stem* (make-parameter #f))
(define *emit-co-index-map* (make-parameter #f))

(define (generate-zone-cl! space-name output-path)
  "Walk the compilation space named SPACE-NAME and write a CL source file
containing one (defun zone-NAME ...) to OUTPUT-PATH. SPACE-NAME may be a
string or a symbol. Returns OUTPUT-PATH on success; raises an error if the
space has no instructions registered."
  (let ((space-id (if (symbol? space-name)
                      space-name
                      (string->symbol space-name))))
    (let ((count (cg/instruction-length space-id)))
      (when (< count 0)
        (%raw-error
         (string-append "generate-zone-cl!: unknown space "
                        (if (symbol? space-name)
                            (symbol->string space-name)
                            space-name))))
      (let ((out (open-output-file output-path))
            (reg-mode (list 'space space-id)))
        (emit-zone-header out space-name 'space)
        (if (needs-splitting? count)
            (emit-zone-defun-split out space-name space-id count reg-mode)
            (emit-zone-defun out space-name space-id count reg-mode))
        (close-output-port out)
        output-path))))

;;; Code-object-oriented entry point. Mirrors generate-zone-cl! but takes
;;; a code-object directly (no registry lookup). Used by Phase D's archive
;;; codegen driver.
(define (generate-zone-cl-for-code-object! co zone-name output-path
                                           file-stem co-key)
  "Emit one (defun zone-NAME ...) for CO. ZONE-NAME is the string used as
the function name suffix. OUTPUT-PATH is the destination .lisp file.
FILE-STEM is the archive's base name (no extension) as a string — emitted
into the self-registration form and used for inner-co constant lookups.
CO-KEY is the CO's name symbol if it has one, or its zero-based archive
index as an integer — used as the second half of the registry key.

If *emit-co-index-map* is already bound (caller is the archive-driven
generate-all-zones-from-archive!), we reuse it so anonymous lambdas
resolve to the same key the archive loader expects. When called in
isolation (tests, ad-hoc codegen), we seed an index map via a
reachability walk from CO — keys then match a one-file archive where
CO is entry 0.

Returns OUTPUT-PATH."
  (let ((count (cg/instruction-length co)))
    (when (= count 0)
      (%raw-error
       (string-append "generate-zone-cl-for-code-object!: empty code-object "
                      zone-name)))
    (let ((local-index-map (or (*emit-co-index-map*)
                               (build-reachable-co-index-map co))))
      (parameterize ((*emit-file-stem* file-stem)
                     (*emit-co-index-map* local-index-map))
        (let ((out (open-output-file output-path))
              (reg-mode (list 'co file-stem co-key)))
          (emit-zone-header out zone-name 'code-object)
          (if (needs-splitting? count)
              (emit-zone-defun-split out zone-name co count reg-mode)
              (emit-zone-defun out zone-name co count reg-mode))
          (close-output-port out)
          output-path)))))

(define (build-reachable-co-index-map top-co)
  "Depth-first walk over TOP-CO's instruction tree, returning a hash-table
mapping each reachable code-object to a stable integer index. `assign`
recurses into each nested code-object inline the moment it is first
seen — that is DFS pre-order, not BFS. Discovery order matches
archive/collect-reachable in src/compilation-unit.scm (which is also
DFS despite its older docstring wording), so keys stay consistent
between archive-level codegen and ad-hoc single-code-object codegen.
These two walks MUST stay in lockstep: any change to traversal order
here has to be mirrored in archive/collect-reachable and vice versa."
  (let ((h (%make-hash-table))
        (next-idx 0))
    (define (assign co)
      (when (not (hash-has-key? h co))
        (hash-set! h co next-idx)
        (set! next-idx (+ next-idx 1))
        (let ((instrs (code-object-instructions co))
              (len (code-object-length co)))
          (let loop ((i 0))
            (when (< i len)
              (visit-tree (vector-ref instrs i))
              (loop (+ i 1)))))))
    (define (visit-tree tree)
      (cond
       ((null? tree) #f)
       ((not (pair? tree)) #f)
       ((and (eq? (car tree) 'const)
             (pair? (cdr tree))
             (code-object? (cadr tree)))
        (assign (cadr tree)))
       (else
        (visit-tree (car tree))
        (visit-tree (cdr tree)))))
    (assign top-co)
    h))

;;; ─────────────────────────────────────────────────────────────────────────
;;; File header
;;; ─────────────────────────────────────────────────────────────────────────

(define (emit-zone-header out space-name mode)
  "Emit the file-level banner for a zone .lisp file. MODE is either 'space
(legacy bootstrap space path — registers into *compiled-zone-functions*)
or 'code-object (archive path from Phase B — Phase C will register into
*archive-zone-fns*). The shared preamble (AUTOMATICALLY GENERATED header,
(in-package :ece)) is identical for both modes; only the registration-
semantics comment differs."
  (let ((name-str (if (symbol? space-name)
                      (symbol->string space-name)
                      space-name)))
    (write-string ";;;; bootstrap/" out)
    (write-string name-str out)
    (write-string "-zone.lisp" out) (newline out)
    (write-string ";;;;" out) (newline out)
    (write-string ";;;; AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND." out) (newline out)
    (write-string ";;;;" out) (newline out)
    (write-string ";;;; Source space: " out)
    (write-string name-str out) (newline out)
    (write-string ";;;; Generator: src/codegen-cl-inline.scm" out) (newline out)
    (write-string ";;;; Regenerate: make bootstrap/" out)
    (write-string name-str out)
    (write-string "-zone.lisp" out) (newline out)
    (write-string ";;;;" out) (newline out)
    (cond
     ((eq? mode 'code-object)
      (write-string ";;;; The CL runtime loads this file at boot and registers the defun" out) (newline out)
      (write-string ";;;; below under (file-stem . co-key) in *archive-zone-fns*; archive" out) (newline out)
      (write-string ";;;; loaders then attach it to the code-object's native-fn slot." out) (newline out))
     (else
      (write-string ";;;; The CL runtime loads this file at boot and registers the defun" out) (newline out)
      (write-string ";;;; below under its space symbol in *compiled-zone-functions*." out) (newline out)))
    (newline out)
    (write-string "(in-package :ece)" out) (newline out)
    (newline out)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Label collection (pc → label-symbol map)
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; We emit one tagbody tag per PC — pc-0, pc-1, ... — so that any goto or
;;; branch can land on any instruction. Named ECE labels (from the space's
;;; label table) are NOT emitted as tagbody tags; the codegen resolves them
;;; to PCs at emit time and jumps via pc-N instead. This keeps the tag
;;; namespace flat and eliminates label collision between spaces.

;;; ─────────────────────────────────────────────────────────────────────────
;;; Main defun emitter
;;; ─────────────────────────────────────────────────────────────────────────

(define (emit-zone-defun out space-name space-id count reg-mode)
  (let ((name-str (if (symbol? space-name)
                      (symbol->string space-name)
                      space-name)))
    (write-string "(defun zone-" out)
    (write-string name-str out)
    (write-char #\space out)
    (write-string
     "(initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)"
     out)
    (newline out)
    (write-string "  (cl:let ((pc initial-pc)" out) (newline out)
    (write-string "           (val initial-val)" out) (newline out)
    (write-string "           (env initial-env)" out) (newline out)
    (write-string "           (proc initial-proc)" out) (newline out)
    (write-string "           (argl initial-argl)" out) (newline out)
    (write-string "           (continue initial-continue)" out) (newline out)
    (write-string "           (stack initial-stack)" out) (newline out)
    (write-string "           (flag cl:nil))" out) (newline out)
    ;; PC is declared fixnum so SBCL's type-inference pass doesn't try to
    ;; compute the union of all N integer values pc can take, which causes
    ;; a recursive simplify-unions stack overflow for large spaces (~20k+ PCs).
    ;; FLAG is declared ignorable in case the space has no (test ...) instructions.
    (write-string "    (cl:declare (cl:type cl:fixnum pc) (cl:ignorable flag))" out) (newline out)
    (write-string "    (cl:tagbody" out) (newline out)
    (emit-entry-dispatch out count)
    (emit-instructions out space-id count)
    (write-string "     zone-exit)" out) (newline out)
    (write-string "    (cl:values pc val env proc argl continue stack)))" out)
    (newline out)
    (newline out)
    (emit-zone-registration out name-str reg-mode)))

(define (emit-zone-registration out name-str reg-mode)
  "Emit the load-time effect that registers this zone. REG-MODE selects
the target registry:
   (space SPACE-ID)          → *compiled-zone-functions* keyed on SPACE-ID
   (co FILE-STEM CO-KEY)     → *archive-zone-fns* keyed on
                                (cons FILE-STEM CO-KEY)
Runs once per file load and is idempotent — re-loading the file just
overwrites the entry with the same function."
  (let ((mode (car reg-mode)))
    (cond
     ((eq? mode 'space)
      (emit-zone-registration-for-space out name-str (cadr reg-mode)))
     ((eq? mode 'co)
      (emit-zone-registration-for-co out name-str
                                     (cadr reg-mode)
                                     (caddr reg-mode)))
     (else
      (%raw-error
       (string-append "emit-zone-registration: unknown reg-mode "
                      (symbol->string mode)))))))

(define (emit-zone-registration-for-space out name-str space-id)
  "Legacy path: register under *compiled-zone-functions* keyed on the
space-id symbol so execute-instructions dispatches to this zone on
entry to that space."
  (write-string ";;; Self-registration: install zone-" out)
  (write-string name-str out)
  (write-string " under the space symbol so" out) (newline out)
  (write-string ";;; execute-instructions dispatches to it on entry to this space." out) (newline out)
  (write-string "(cl:setf (cl:gethash " out)
  (write-cl-quoted-ece-symbol out space-id)
  (write-string " *compiled-zone-functions*)" out) (newline out)
  (write-string "         (cl:function zone-" out)
  (write-string name-str out)
  (write-string "))" out) (newline out))

(define (emit-zone-registration-for-co out name-str file-stem co-key)
  "Archive path: register under *archive-zone-fns* keyed on
(file-stem . co-key). FILE-STEM is a string (the archive's base name).
CO-KEY is either a symbol (the co's name) or an integer (archive
index) — emitted literally so the key round-trips through cl:read back
into the same EQUAL hash key the archive loader constructs."
  (write-string ";;; Self-registration: install zone-" out)
  (write-string name-str out)
  (write-string " under (file-stem . co-key) so the" out) (newline out)
  (write-string ";;; archive loader can attach native-fn at load time." out) (newline out)
  (write-string "(cl:setf (cl:gethash (cl:cons " out)
  (emit-file-stem-symbol out file-stem)
  (write-char #\space out)
  (cond
   ((symbol? co-key)
    (write-cl-quoted-ece-symbol out co-key))
   (else
    (write-string (number->string co-key) out)))
  (write-string ") *archive-zone-fns*)" out) (newline out)
  (write-string "         (cl:function zone-" out)
  (write-string name-str out)
  (write-string "))" out) (newline out))

(define (emit-file-stem-symbol out file-stem)
  "Emit FILE-STEM (a string) as a pipe-quoted symbol literal `'|stem|`.
The emitted bytes are bare — no package qualifier — and resolve in the
`:ece` package at file-load time because the generated zone file opens
with `(in-package :ece)` (see emit-zone-header). Pipe syntax preserves
lowercase under CL's default upcasing reader. The archive loader in
src/runtime.lisp derives its matching key via
`(intern STEM :ece)` (see archive-file-stem-symbol), so both sides
land on the same `eq` symbol and the (FILE-STEM . CO-KEY) registry key
round-trips without a runtime intern call here."
  (write-char #\' out)
  (write-char #\| out)
  (write-string file-stem out)
  (write-char #\| out))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Sub-function splitting (chunk emitters)
;;; ─────────────────────────────────────────────────────────────────────────

(define (emit-zone-defun-split out space-name space-id count reg-mode)
  "Emit a split zone: ceil(count/chunk-size) chunk functions plus a
dispatcher that routes PCs to the correct chunk. Used when a space's
instruction count exceeds chunk-size. REG-MODE selects the registry
(see emit-zone-registration)."
  (let ((name-str (if (symbol? space-name)
                      (symbol->string space-name)
                      space-name))
        (label-map (build-pc-label-map space-id))
        (static-proc-map (build-static-proc-map space-id count)))
    (let loop ((k 0) (start 0))
      (when (< start count)
        (let ((end (min (+ start chunk-size) count)))
          (emit-chunk-defun out name-str space-id count k start end label-map static-proc-map)
          (newline out)
          (loop (+ k 1) end))))
    (emit-zone-dispatcher out name-str count)
    (newline out)
    (emit-zone-registration out name-str reg-mode)))

(define (emit-chunk-defun out name-str space-id total-count chunk-k start end label-map static-proc-map)
  "Emit one chunk function covering PCs [start, end). Each chunk has the
same lambda list as the top-level zone function, plus an 8th bail return
value that the dispatcher uses to distinguish register-goto bails from
cross-chunk jumps."
  (write-string "(defun zone-" out)
  (write-string name-str out)
  (write-string "-chunk-" out)
  (write-string (number->string chunk-k) out)
  (write-char #\space out)
  (write-string
   "(initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)"
   out)
  (newline out)
  (write-string "  (cl:let ((pc initial-pc)" out) (newline out)
  (write-string "           (val initial-val)" out) (newline out)
  (write-string "           (env initial-env)" out) (newline out)
  (write-string "           (proc initial-proc)" out) (newline out)
  (write-string "           (argl initial-argl)" out) (newline out)
  (write-string "           (continue initial-continue)" out) (newline out)
  (write-string "           (stack initial-stack)" out) (newline out)
  (write-string "           (flag cl:nil)" out) (newline out)
  (write-string "           (bail cl:nil))" out) (newline out)
  (write-string "    (cl:declare (cl:type cl:fixnum pc) (cl:ignorable flag bail))" out) (newline out)
  (write-string "    (cl:tagbody" out) (newline out)
  (emit-entry-dispatch-range out start end "chunk-exit")
  (emit-chunk-instructions out space-id total-count start end label-map static-proc-map)
  (write-string "     chunk-exit)" out) (newline out)
  (write-string "    (cl:values pc val env proc argl continue stack bail)))" out)
  (newline out))

(define (emit-chunk-instructions out space-id total-count start end label-map static-proc-map)
  "Walk PCs [start, end) of a chunk, emitting tagbody tags and translated
instruction bodies with chunk-aware control flow."
  (let ((chunk-ctx (list start end total-count)))
    (let loop ((pc start))
      (when (< pc end)
        (let ((instr (cg/source-ref space-id pc)))
          (write-string "     pc-" out)
          (write-string (number->string pc) out)
          (newline out)
          (emit-instruction out instr pc space-id label-map static-proc-map chunk-ctx)
          (emit-pc-update-for-fall-through out instr pc total-count chunk-ctx)
          (loop (+ pc 1)))))))

(define (emit-zone-dispatcher out name-str total-count)
  "Emit the dispatcher function that loops: pick chunk by pc range, call it,
check halt/bail. The dispatcher has the same 7-in/7-out calling convention
as the single-function zone."
  (write-string "(defun zone-" out)
  (write-string name-str out)
  (write-char #\space out)
  (write-string
   "(initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)"
   out)
  (newline out)
  (write-string "  (cl:let ((pc initial-pc)" out) (newline out)
  (write-string "           (val initial-val)" out) (newline out)
  (write-string "           (env initial-env)" out) (newline out)
  (write-string "           (proc initial-proc)" out) (newline out)
  (write-string "           (argl initial-argl)" out) (newline out)
  (write-string "           (continue initial-continue)" out) (newline out)
  (write-string "           (stack initial-stack)" out) (newline out)
  (write-string "           (bail cl:nil))" out) (newline out)
  (write-string "    (cl:loop" out) (newline out)
  (write-string "      (cl:when (cl:or (cl:>= pc " out)
  (write-string (number->string total-count) out)
  (write-string ") (cl:< pc 0))" out) (newline out)
  (write-string "        (cl:return (cl:values pc val env proc argl continue stack)))" out) (newline out)
  (write-string "      (cl:cond" out) (newline out)
  (let loop ((k 0) (start 0))
    (cond
     ((>= start total-count)
      (write-string "        (cl:t (cl:return (cl:values pc val env proc argl continue stack))))" out) (newline out))
     (else
      (let ((end (min (+ start chunk-size) total-count)))
        (write-string "        ((cl:< pc " out)
        (write-string (number->string end) out)
        (write-string ")" out) (newline out)
        (write-string "         (cl:multiple-value-setq (pc val env proc argl continue stack bail)" out) (newline out)
        (write-string "           (zone-" out)
        (write-string name-str out)
        (write-string "-chunk-" out)
        (write-string (number->string k) out)
        (write-string " pc val env proc argl continue stack)))" out) (newline out)
        (loop (+ k 1) end)))))
  (write-string "      (cl:when bail" out) (newline out)
  (write-string "        (cl:return (cl:values pc val env proc argl continue stack))))))" out) (newline out))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Entry dispatch
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; The executor can hand off control to us at any PC (e.g. after resuming
;;; a continuation), and we pick up from there. If the PC is outside our
;;; range (e.g. from a cross-space resume), we bail through zone-exit and
;;; let the executor re-dispatch.
;;;
;;; CL's `case` macro expands into a deeply nested IF chain — one IF per
;;; clause, with no lateral fan-out — so a flat (case pc (0 ...) (1 ...)
;;; ... (N ...)) blows SBCL's IR1 conversion stack around N ≈ 4500 on
;;; macOS. To stay safe for the prelude space (~44k instructions), we
;;; bucket the dispatch: an outer cond fans out to per-bucket case forms,
;;; each with at most BUCKET-SIZE entries. With 256-PC buckets a 44k-PC
;;; space has 172 cond branches and case-arms of depth ≤ 256 — both well
;;; within SBCL's limits.

(define entry-dispatch-bucket-size 256)

(define (emit-entry-dispatch out count)
  (emit-entry-dispatch-range out 0 count "zone-exit"))

(define (emit-entry-dispatch-range out start end exit-tag)
  (let ((range (- end start)))
    (cond
     ((<= range entry-dispatch-bucket-size)
      (emit-entry-dispatch-flat out start end exit-tag))
     (else
      (emit-entry-dispatch-bucketed out start end exit-tag)))))

(define (emit-entry-dispatch-flat out start end exit-tag)
  (write-string "     (cl:case pc" out) (newline out)
  (let loop ((pc start))
    (when (< pc end)
      (write-string "       (" out)
      (write-string (number->string pc) out)
      (write-string " (cl:go pc-" out)
      (write-string (number->string pc) out)
      (write-string "))" out) (newline out)
      (loop (+ pc 1))))
  (write-string "       (cl:t (cl:go " out)
  (write-string exit-tag out)
  (write-string ")))" out) (newline out))

(define (emit-entry-dispatch-bucketed out range-start range-end exit-tag)
  (write-string "     (cl:cond" out) (newline out)
  (let loop ((start range-start))
    (cond
     ((>= start range-end)
      (write-string "       (cl:t (cl:go " out)
      (write-string exit-tag out)
      (write-string ")))" out) (newline out))
     (else
      (let ((end (let ((proposed (+ start entry-dispatch-bucket-size)))
                   (if (> proposed range-end) range-end proposed))))
        (write-string "       ((cl:< pc " out)
        (write-string (number->string end) out)
        (write-string ")" out) (newline out)
        (write-string "        " out)
        (emit-entry-dispatch-case-bucket out start end exit-tag)
        (write-string "))" out) (newline out)
        (loop end))))))

(define (emit-entry-dispatch-case-bucket out start end exit-tag)
  "Emit a (case pc ...) form covering PCs in [start, end), without its
trailing close paren — the caller in emit-entry-dispatch-bucketed adds
that close so it can also close the surrounding cond clause."
  (write-string "(cl:case pc" out) (newline out)
  (let loop ((pc start))
    (when (< pc end)
      (write-string "          (" out)
      (write-string (number->string pc) out)
      (write-string " (cl:go pc-" out)
      (write-string (number->string pc) out)
      (write-string "))" out) (newline out)
      (loop (+ pc 1))))
  (write-string "          (cl:t (cl:go " out)
  (write-string exit-tag out)
  (write-string "))" out))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Instruction walker
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Walks the space in PC order. At each PC we:
;;;   1. Emit the tagbody tag pc-N
;;;   2. Emit the translated CL forms for the instruction
;;;   3. Bump pc and fall through to the next tag (for straight-line code)
;;;
;;; Primitive call-site detection uses a one-instruction lookback:
;;; when we see (assign val (op apply-primitive-procedure) (reg proc) (reg argl)),
;;; we scan backward for the most recent (assign proc (const (primitive ID)))
;;; in the same basic block (no intervening labels). If we find one, we emit
;;; the inlined template; otherwise we emit the fallback dispatch call.

(define (emit-instructions out space-id count)
  "Walk the space's instructions in PC order. Each PC gets a tagbody tag,
the instruction body, and then pc/tagbody housekeeping that mirrors the
interpreter's hot loop:
   * fall-through instructions (assign/test/save/restore/perform) increment
     pc and let CL fall through to the next tag.
   * branch/goto set pc explicitly inside the body and either (go ...) to
     the target tag or fall through to zone-exit.
   * halt advances pc past the end of the space so that, when the executor
     resumes from the returned register state, its (>= pc len) check fires
     and it returns val immediately without re-dispatching the halt.

A pre-pass scans the instruction vector and builds a static-proc map: for
each PC, if the proc register holds a known primitive ID at that PC (i.e.
the most recent assignment to proc within the current basic block was a
const primitive), the map entry is the primitive name. Call sites that hit
in the map get inlined; the rest fall back to apply-primitive-procedure."
  (let ((label-map (build-pc-label-map space-id))
        (static-proc-map (build-static-proc-map space-id count)))
    (let loop ((pc 0))
      (when (< pc count)
        (let ((instr (cg/source-ref space-id pc)))
          (write-string "     pc-" out)
          (write-string (number->string pc) out)
          (newline out)
          (emit-instruction out instr pc space-id label-map static-proc-map #f)
          (emit-pc-update-for-fall-through out instr pc count #f)
          (loop (+ pc 1)))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Static-proc tracker (primitive call-site detection)
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; A linear pre-pass over the instruction vector that maps each PC to:
;;;   * a primitive name symbol — when, at that PC, the proc register
;;;     was most recently set to (const (primitive ID)) within the same
;;;     basic block AND that ID resolves to a registered primitive name
;;;   * #f — otherwise
;;;
;;; "Same basic block" means no labels appear between the const-assign and
;;; the call site. A label is the start of a new basic block (any goto can
;;; jump in), so we can no longer prove the proc register's value.
;;;
;;; We also reset on any (assign proc ...) that ISN'T a const primitive,
;;; on goto, on branch (the not-taken path is fine but conservatively we
;;; reset for now), and on perform/test instructions that don't touch proc.
;;; Test/perform are safe — they don't assign to registers.

(define (build-static-proc-map space-id count)
  "Walk the instruction vector once and return an alist of (pc . prim-name)
entries for every PC where the proc register is statically known. PCs not
in the alist have an unknown proc."
  (let ((label-set (label-pc-hash-set space-id)))
    (let loop ((pc 0) (current-prim #f) (acc '()))
      (cond
       ((>= pc count) acc)
       (else
        (let* (;; Entering a labeled instruction starts a new basic block:
               ;; we can no longer trust the previous proc value.
               (current-prim (if (hash-has-key? label-set pc) #f current-prim))
               (instr (cg/source-ref space-id pc))
               (op (car instr))
               (next-prim
                (cond
                 ;; (assign proc (const (primitive ID))) — record the prim
                 ((and (eq? op 'assign)
                       (eq? (cadr instr) 'proc)
                       (eq? (car (caddr instr)) 'const)
                       (let ((v (cadr (caddr instr))))
                         (and (pair? v)
                              (eq? (car v) 'primitive)
                              (number? (cadr v)))))
                  (let ((prim-id (cadr (cadr (caddr instr)))))
                    (or (%primitive-name prim-id) #f)))
                 ;; (assign proc ANYTHING-ELSE) — proc is now unknown
                 ((and (eq? op 'assign) (eq? (cadr instr) 'proc))
                  #f)
                 ;; goto / branch / restore proc / save proc don't help us
                 ((or (eq? op 'goto) (eq? op 'halt))
                  ;; Control transfer — what we know about proc only
                  ;; matters if a fall-through reaches the next pc, which
                  ;; for goto/halt it doesn't. The next basic block starts
                  ;; at a label, where we already reset above. Keep current.
                  current-prim)
                 ((and (eq? op 'restore) (eq? (cadr instr) 'proc))
                  #f)
                 (else current-prim)))
               (acc (if (and current-prim
                             (eq? op 'assign)
                             (call-site-using-proc? instr))
                        (cons (cons pc current-prim) acc)
                        acc)))
          (loop (+ pc 1) next-prim acc)))))))

(define (call-site-using-proc? instr)
  "Test whether INSTR is a primitive-procedure call site that consumes the
proc register: (assign val (op apply-primitive-procedure) (reg proc) ...)."
  (and (eq? (car instr) 'assign)
       (eq? (cadr instr) 'val)
       (let ((source (caddr instr)))
         (and (eq? (car source) 'op)
              (eq? (cadr source) 'apply-primitive-procedure)))
       (let ((args (cdddr instr)))
         (and (pair? args)
              (let ((first (car args)))
                (and (eq? (car first) 'reg)
                     (eq? (cadr first) 'proc)))))))

(define (label-pc-hash-set space-id)
  "Return a hash table keyed by PCs that have at least one label pointing to
them. Used to identify basic-block boundaries for the static-proc walker.
Hash-table lookup is O(1) per PC vs O(labels) for a list scan — critical
for large spaces where the label count × instruction count product hits
millions."
  (let ((ht (%make-hash-table)))
    (let loop ((entries (cg/label-entries space-id)))
      (cond
       ((null? entries) ht)
       (else
        (hash-set! ht (cdr (car entries)) #t)
        (loop (cdr entries)))))))

(define (emit-pc-update-for-fall-through out instr pc count chunk-ctx)
  "Emit `(cl:setf pc (1+ pc-i))` for instructions that fall through to the
next PC. Branch/goto/halt manage pc themselves (inside the body emitted by
emit-instruction), so they get nothing here.

In chunk mode, a not-taken branch at the chunk boundary (last PC) must
still set pc so the dispatcher routes to the next chunk correctly."
  (let ((op (car instr)))
    (cond
     ;; Chunk boundary: a not-taken branch at the last PC in a chunk must
     ;; update pc so falling through to chunk-exit has the correct target.
     ((and chunk-ctx
           (eq? op 'branch)
           (= pc (- (chunk-ctx-end chunk-ctx) 1)))
      (write-string "       (cl:setf pc " out)
      (write-string (number->string (+ pc 1)) out)
      (write-string ")" out) (newline out))
     ((or (eq? op 'branch) (eq? op 'goto) (eq? op 'halt))
      #t)
     (else
      (write-string "       (cl:setf pc " out)
      (write-string (number->string (+ pc 1)) out)
      (write-string ")" out) (newline out)))))

(define (build-pc-label-map space-id)
  "Return an alist of (label . pc) pairs for SPACE-ID's label table."
  (cg/label-entries space-id))

(define (pc-for-label label label-map)
  "Resolve LABEL to its PC using LABEL-MAP. Errors if not found."
  (let ((pair (assq label label-map)))
    (if pair
        (cdr pair)
        (%raw-error
         (string-append "generate-zone-cl!: unknown label "
                        (symbol->string label))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Per-instruction emitter
;;; ─────────────────────────────────────────────────────────────────────────

(define (emit-instruction out instr pc space-id label-map static-proc-map chunk-ctx)
  (let ((op (car instr)))
    (cond
     ((eq? op 'assign)  (emit-assign out instr pc space-id label-map static-proc-map))
     ((eq? op 'test)    (emit-test out instr label-map))
     ((eq? op 'branch)  (emit-branch out instr label-map chunk-ctx))
     ((eq? op 'goto)    (emit-goto out instr label-map pc chunk-ctx))
     ((eq? op 'save)    (emit-save out instr))
     ((eq? op 'restore) (emit-restore out instr))
     ((eq? op 'perform) (emit-perform out instr label-map))
     ((eq? op 'halt)    (emit-halt out pc chunk-ctx))
     (else
      (%raw-error
       (string-append "emit-instruction: unknown opcode "
                      (symbol->string op)
                      " at pc "
                      (number->string pc)))))))

;;; ---- assign ---------------------------------------------------------------

(define (emit-assign out instr pc space-id label-map static-proc-map)
  "Translate (assign TARGET SOURCE [args...]) to CL.
  SOURCE variants: (const V) | (reg R) | (label L) | (op NAME) | (op-fn F)."
  (let ((target (list-ref instr 1))
        (source (list-ref instr 2)))
    (let ((source-tag (car source)))
      (cond
       ;; (assign target (const VALUE))
       ((eq? source-tag 'const)
        (write-string "       (cl:setf " out)
        (write-cl-form target out)
        (write-char #\space out)
        (emit-const out (cadr source))
        (write-string ")" out) (newline out))
       ;; (assign target (reg R))
       ((eq? source-tag 'reg)
        (write-string "       (cl:setf " out)
        (write-cl-form target out)
        (write-char #\space out)
        (write-cl-form (cadr source) out)
        (write-string ")" out) (newline out))
       ;; (assign target (label L)) — resolve to pc-N address.
       ;; If target is 'continue, qualify with the space-id (matches the
       ;; interpreter's cross-space addressing: (space-id . local-pc)).
       ;; Otherwise emit the bare local PC.
       ((eq? source-tag 'label)
        (let ((resolved-pc (pc-for-label (cadr source) label-map)))
          (write-string "       (cl:setf " out)
          (write-cl-form target out)
          (write-char #\space out)
          (cond
           ((eq? target 'continue)
            (write-string "(cl:cons " out)
            (cond
             ((code-object? space-id)
              ;; Code-object path: at zone-fn execution time,
              ;; *executing-space-id* is dynamically bound to the CO
              ;; this zone was entered for. Reading it here produces the
              ;; same (code-object . local-pc) shape the interpreter's
              ;; eval-operand builds, so continuations captured in the
              ;; zone are portable back to the interpreter.
              (write-string "*executing-space-id*" out))
             (else
              (write-cl-quoted-ece-symbol out space-id)))
            (write-char #\space out)
            (write-string (number->string resolved-pc) out)
            (write-char #\) out))
           (else
            (write-string (number->string resolved-pc) out)))
          (write-string ")" out) (newline out)))
       ;; (assign target (op NAME) args...) — operation call
       ((eq? source-tag 'op)
        (emit-op-assign out target (cadr source) (cdddr instr) pc static-proc-map label-map))
       ;; (assign target (op-fn FN) args...) — resolved operation, we can
       ;; still look it up by name if it's a symbol, but we expect this
       ;; codegen to run against the source instructions (pre-resolve).
       (else
        (%raw-error
         (string-append "emit-assign: unsupported source "
                        (symbol->string source-tag))))))))

(define (emit-op-assign out target op-name arg-operands pc static-proc-map label-map)
  "Emit (cl:setf TARGET <op-call>) where <op-call> dispatches OP-NAME against
ARG-OPERANDS. Special-cases apply-primitive-procedure for inline primitive
substitution when the proc register holds a statically-known primitive."
  (cond
   ;; Primitive call — if inline substitution is possible, use it;
   ;; otherwise fall through to the generic op dispatch.
   ((and (eq? op-name 'apply-primitive-procedure)
         (eq? target 'val))
    (emit-apply-primitive out arg-operands pc static-proc-map label-map))
   ;; Generic op call
   (else
    (write-string "       (cl:setf " out)
    (write-cl-form target out)
    (write-char #\space out)
    (emit-op-call out op-name arg-operands label-map)
    (write-string ")" out) (newline out))))

(define (emit-apply-primitive out arg-operands pc static-proc-map label-map)
  "Emit the primitive call site. If the call site's primitive identity is
statically known (it appears in STATIC-PROC-MAP), splice the :cl template
body inline via host-primitive-cl-body. Otherwise emit the runtime fallback
(apply-primitive-procedure proc argl).

This is the load-bearing inline-substitution path that justifies Stage 1 —
proving the templates are reusable IR beyond the defun emission path."
  (let ((known (assq pc static-proc-map)))
    (cond
     (known
      (let ((prim-name (cdr known)))
        (let ((inlined (try-inline-primitive prim-name)))
          (cond
           (inlined
            (write-string "       (cl:setf val " out)
            (write-cl-form inlined out)
            (write-string ")" out) (newline out))
           (else
            (emit-fallback-primitive-call out arg-operands label-map))))))
     (else
      (emit-fallback-primitive-call out arg-operands label-map)))))

(define (try-inline-primitive prim-name)
  "Try to build the inlined :cl template body for PRIM-NAME, with each
parameter bound to a positional accessor over the runtime `argl` list at
the call site.

Returns the inlined CL form on success, or #f when the primitive has no
:cl template registered (e.g. it's an ECE-platform primitive that lives
in src/prelude.scm rather than src/primitives.scm)."
  (let ((params (host-primitive-params prim-name))
        (template (host-primitive-target prim-name ':cl)))
    (and params
         template
         (let ((bindings (build-inline-bindings params 0)))
           (expand-host-primitive-template template bindings)))))

(define (build-inline-bindings params depth)
  "Build (param . accessor) bindings for inline substitution at an
apply-primitive-procedure call site, where the runtime argument list is
already in the `argl` register.

Behaviour by parameter shape:
   ()         → ()
   (a)        → ((a . (cl:nth 0 argl)))
   (a b)      → ((a . (cl:nth 0 argl)) (b . (cl:nth 1 argl)))
   args       → ((args . argl))                  ; whole-list rest
   (a . rest) → ((a . (cl:nth 0 argl)) (rest . (cl:nthcdr 1 argl)))

This differs from build-host-primitive-bindings in codegen-cl.scm:
the defun-emission path receives one CL form per arg and wraps the rest
tail in (cl:list ...), but the inline-substitution path already has the
list in argl, so the rest tail binds to argl (or an nthcdr) directly."
  (cond
   ((null? params) '())
   ((symbol? params)
    (cond
     ((= depth 0) (list (cons params 'argl)))
     (else (list (cons params (list 'cl:nthcdr depth 'argl))))))
   ((pair? params)
    (cons (cons (car params) (list 'cl:nth depth 'argl))
          (build-inline-bindings (cdr params) (+ depth 1))))
   (else '())))

(define (emit-fallback-primitive-call out arg-operands label-map)
  "Emit the unconditional dispatch path: route through the runtime
apply-primitive-procedure for primitives whose identity isn't statically
known at this PC."
  (write-string "       (cl:setf val (apply-primitive-procedure " out)
  (emit-operand out (car arg-operands) label-map)
  (write-char #\space out)
  (emit-operand out (cadr arg-operands) label-map)
  (write-string "))" out) (newline out))

(define (emit-op-call out op-name arg-operands label-map)
  "Emit a call to the operation OP-NAME with ARG-OPERANDS evaluated as
(reg R) / (const V) / (label L). Operations are looked up via get-operation
at runtime; for Stage 1 we emit the same lookup every call site."
  (write-string "(cl:funcall (get-operation " out)
  (write-cl-quoted-ece-symbol out op-name)
  (write-char #\) out)
  (let loop ((ops arg-operands))
    (when (pair? ops)
      (write-char #\space out)
      (emit-operand out (car ops) label-map)
      (loop (cdr ops))))
  (write-char #\) out))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Case-preserving symbol emission
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; ECE symbols are lowercase (case-preserved). CL's standard reader is
;;; case-FOLDING (upcases by default), so writing a bare lowercase symbol
;;; like `list` produces `LIST` after CL reads it back — which doesn't
;;; match the operation table key `ECE::|list|`.
;;;
;;; To round-trip a lowercase ECE symbol through CL's reader without case
;;; folding, we wrap the name in pipes: `|list|` reads as the symbol whose
;;; name is exactly `list` (case preserved). All operation names, all
;;; primitive tags (`|primitive|`, `|continuation|`, ...), and any other
;;; ECE symbol that needs to round-trip must go through this helper.

(define (strip-outer-pipes name)
  "If NAME starts and ends with `|`, strip them. Used to normalize
symbols read from archive files: the ECE reader doesn't understand
R6RS pipe-escape syntax, so `|:hash-table|` parses as a 13-char symbol
whose NAME includes the pipes. Re-wrapping that with `write-char #\\|`
would double-escape and confuse CL's reader into treating `:hash-table`
as a package prefix. Strip first, then re-wrap, so the emitted bytes
are `|:hash-table|` — a single escape that CL reads as the intended
case-preserved symbol."
  (let ((len (string-length name)))
    (if (and (>= len 2)
             (char=? (string-ref name 0) #\|)
             (char=? (string-ref name (- len 1)) #\|))
        (substring name 1 (- len 1))
        name)))

(define (write-cl-quoted-ece-symbol out sym)
  "Emit SYM as a quoted CL form `'|name|`, preserving lowercase via the
pipe-escape syntax that CL's reader honors. Strips pre-existing pipes
from SYM's name so archive-read symbols (which carry pipes in their
name because the ECE reader doesn't strip them) don't double-escape."
  (write-char #\' out)
  (write-char #\| out)
  (write-string (strip-outer-pipes (symbol->string sym)) out)
  (write-char #\| out))

(define (write-cl-data-symbol out sym)
  "Emit SYM as a bare data symbol `|name|` (no leading quote), preserving
lowercase. Use this inside already-quoted lists, where the leading quote
is provided by the enclosing context. Strips pre-existing pipes (see
write-cl-quoted-ece-symbol)."
  (write-char #\| out)
  (write-string (strip-outer-pipes (symbol->string sym)) out)
  (write-char #\| out))

(define (emit-operand out operand label-map)
  "Emit an operand (reg R) / (const V) / (label L) as its CL value.
Register names are bare lowercase symbols that round-trip through CL's
reader as upcase locals — no pipes needed since the let bindings in
emit-zone-defun also use bare lowercase. Const operands of symbol type
need pipe-wrapping to preserve case. Label operands resolve to the
target's local PC at codegen time and emit as a bare integer — matching
the executor's eval-operand which does (resolve-label) to get the local
PC. The runtime then qualifies the PC via *executing-space-id* if needed
(e.g., make-compiled-procedure)."
  (let ((tag (car operand)))
    (cond
     ((eq? tag 'reg) (write-cl-form (cadr operand) out))
     ((eq? tag 'const) (emit-const out (cadr operand)))
     ((eq? tag 'label)
      (write-string (number->string (pc-for-label (cadr operand) label-map)) out))
     (else (%raw-error
            (string-append "emit-operand: unknown operand tag "
                           (symbol->string tag)))))))

(define (emit-const out value)
  "Emit a (const V) operand's VALUE as a CL form. Numbers and booleans
emit directly; symbols and lists are emitted as quoted data with all
ECE symbols pipe-wrapped to preserve case across CL's reader. String
escaping is delegated to write-cl-string in codegen-cl.scm so backslashes,
double quotes, and other special characters round-trip cleanly.

Bottom-up emission (mc-compile-lambda-as-code-object) places a nested
code-object as the const arg to make-compiled-procedure. For the archive
path (code-object zone), we emit a runtime lookup into
*archive-code-objects* so each call site dereferences the live code-
object after the archive loader has populated the registry. The file-
stem and co-key are known at codegen time (the zone file is emitted
for one specific archive) and baked into the emitted form.

If *emit-co-index-map* / *emit-file-stem* are unset (legacy space path),
emitting a code-object constant is unsupported — it shouldn't happen,
since spaces don't have per-procedure identities. We raise at codegen
time rather than emit a form that would crash at runtime."
  (cond
   ;; Integers use number->string (unambiguous decimal). Non-integer numbers
   ;; (floats) route through write-to-string-flat because ECE's number->string
   ;; truncates floats — it calls (number->string (truncate n)) in the
   ;; non-integer path, which turns 0.5 into "0". That truncation silently
   ;; corrupted constant operands in zones (round's 0.5 comparison became
   ;; 0, making it a ceiling instead of round-to-nearest).
   ((number? value)
    (if (integer? value)
        (write-string (number->string value) out)
        (write-string (write-to-string-flat value) out)))
   ((eq? value #t) (write-string "t" out))
   ((eq? value #f) (write-string "ece::*scheme-false*" out))
   ((null? value) (write-string "cl:nil" out))
   ((string? value) (write-cl-string value out))
   ((symbol? value)
    (write-cl-quoted-ece-symbol out value))
   ((code-object? value)
    (emit-inner-co-lookup out value))
   ((pair? value)
    (write-char #\' out)
    (emit-quoted-datum out value))
   (else
    ;; Char and other atoms — fall through to write-cl-form which knows
    ;; how to emit them.
    (write-cl-form value out))))

(define (emit-inner-co-lookup out co)
  "Emit a CL form that at zone-execution time resolves CO via
archive-co-lookup into the live code-object struct from
*archive-code-objects*. CO is a code-object value baked into the
instruction by bottom-up compilation; its archive identity (file-stem +
archive-index) is known at codegen time through *emit-file-stem* and
*emit-co-index-map*.

Keys are always archive indices (integers) — names are not unique
(prelude has 7 distinct `iter` code-objects), so keying on name would
make every same-named code-object route to the same zone fn. Must match
the key the archive loader derives (runtime.lisp: archive-co-key)."
  (let ((file-stem (*emit-file-stem*))
        (index-map (*emit-co-index-map*)))
    (when (not file-stem)
      (%raw-error
       "emit-inner-co-lookup: no *emit-file-stem* bound. Code-object constants are only valid in archive zones."))
    (when (not index-map)
      (%raw-error
       "emit-inner-co-lookup: no *emit-co-index-map* bound. Archive codegen must seed the index map."))
    (let ((co-key (hash-ref index-map co #f)))
      (when (not co-key)
        (%raw-error
         "emit-inner-co-lookup: code-object is not in the archive index map."))
      (write-string "(archive-co-lookup " out)
      (emit-file-stem-symbol out file-stem)
      (write-char #\space out)
      (write-string (number->string co-key) out)
      (write-char #\) out))))

(define (emit-quoted-datum out datum)
  "Emit DATUM in a quoted-data context — the leading quote has already
been written by the caller. Recursively pipe-wraps every symbol so that
the constructed CL list matches the byte-for-byte ECE-symbol shape that
the runtime expects. String values delegate to write-cl-string for
proper backslash/quote escaping."
  (cond
   ((null? datum) (write-string "()" out))
   ((symbol? datum) (write-cl-data-symbol out datum))
   ((number? datum)
    ;; See emit-const: ECE's number->string truncates floats, so route
    ;; non-integer numbers through write-to-string-flat.
    (if (integer? datum)
        (write-string (number->string datum) out)
        (write-string (write-to-string-flat datum) out)))
   ((eq? datum #t) (write-string "t" out))
   ((eq? datum #f) (write-string "ece::*scheme-false*" out))
   ((string? datum) (write-cl-string datum out))
   ;; Nested code-object inside quoted data — unreachable in compiler
   ;; output (quoted data from source never contains code-objects; nested
   ;; lambdas always come through the value-context (const <co>) path).
   ;; Emit an uninterned sentinel symbol so the reader still accepts the
   ;; file; if this path ever fires at runtime, the value will be an
   ;; opaque symbol and downstream code will fail loudly rather than
   ;; silently misbehave.
   ((code-object? datum)
    (write-string "#:code-object-in-quoted-data#" out))
   ((pair? datum)
    (write-char #\( out)
    (emit-quoted-datum out (car datum))
    (let loop ((rest (cdr datum)))
      (cond
       ((null? rest) (write-char #\) out))
       ((pair? rest)
        (write-char #\space out)
        (emit-quoted-datum out (car rest))
        (loop (cdr rest)))
       (else
        (write-string " . " out)
        (emit-quoted-datum out rest)
        (write-char #\) out)))))
   (else
    (write-cl-form datum out))))

;;; ---- test ---------------------------------------------------------------

(define (emit-test out instr label-map)
  "Translate (test (op NAME) args...) to (setf flag (op-call ...))."
  (let ((op-spec (list-ref instr 1)))
    (unless (eq? (car op-spec) 'op)
      (%raw-error "emit-test: expected (op NAME) spec"))
    (write-string "       (cl:setf flag " out)
    (emit-op-call out (cadr op-spec) (cddr instr) label-map)
    (write-string ")" out) (newline out)))

;;; ---- branch -------------------------------------------------------------

(define (emit-branch out instr label-map chunk-ctx)
  "Translate (branch (label L)) to (when flag (setf pc target) (go pc-N)).
The pc setf inside the (when ...) covers the taken branch; the not-taken
fall-through case is handled by emit-pc-update-for-fall-through.

In chunk mode, cross-chunk targets return to the dispatcher via chunk-exit
instead of jumping directly."
  (let ((dest (list-ref instr 1)))
    (unless (eq? (car dest) 'label)
      (%raw-error "emit-branch: expected (label L) destination"))
    (let ((target-pc (pc-for-label (cadr dest) label-map)))
      (cond
       ((or (not chunk-ctx) (in-chunk? target-pc chunk-ctx))
        (write-string "       (cl:when flag (cl:setf pc " out)
        (write-string (number->string target-pc) out)
        (write-string ") (cl:go pc-" out)
        (write-string (number->string target-pc) out)
        (write-string "))" out) (newline out))
       (else
        (write-string "       (cl:when flag (cl:setf pc " out)
        (write-string (number->string target-pc) out)
        (write-string ") (cl:go chunk-exit))" out) (newline out))))))

;;; ---- goto ---------------------------------------------------------------

(define (emit-goto out instr label-map pc chunk-ctx)
  "Translate (goto DEST) where DEST is (label L) or (reg R).
Label gotos resolve to pc-N tags at emit time — same-space is just (go pc-N).
Register gotos bail through zone-exit (or chunk-exit with bail flag in chunk
mode) so the executor can re-dispatch based on the runtime register value.

In chunk mode, cross-chunk label targets return to the dispatcher via
chunk-exit. Register gotos set the bail flag so the dispatcher returns to
the executor instead of looping."
  (let ((dest (list-ref instr 1)))
    (cond
     ((eq? (car dest) 'label)
      (let ((target-pc (pc-for-label (cadr dest) label-map)))
        (cond
         ((or (not chunk-ctx) (in-chunk? target-pc chunk-ctx))
          (write-string "       (cl:setf pc " out)
          (write-string (number->string target-pc) out)
          (write-string ") (cl:go pc-" out)
          (write-string (number->string target-pc) out)
          (write-string ")" out) (newline out))
         (else
          (write-string "       (cl:setf pc " out)
          (write-string (number->string target-pc) out)
          (write-string ") (cl:go chunk-exit)" out) (newline out)))))
     ((eq? (car dest) 'reg)
      (cond
       ((not chunk-ctx)
        (write-string "       (cl:go zone-exit)" out) (newline out))
       (else
        (write-string "       (cl:setf bail cl:t) (cl:go chunk-exit)" out) (newline out))))
     (else
      (%raw-error
       (string-append "emit-goto: unknown destination tag "
                      (symbol->string (car dest))))))))

;;; ---- save / restore -----------------------------------------------------

(define (emit-save out instr)
  (write-string "       (cl:push " out)
  (write-cl-form (cadr instr) out)
  (write-string " stack)" out) (newline out))

(define (emit-restore out instr)
  (write-string "       (cl:setf " out)
  (write-cl-form (cadr instr) out)
  (write-string " (cl:pop stack))" out) (newline out))

;;; ---- perform ------------------------------------------------------------

(define (emit-perform out instr label-map)
  "Translate (perform (op NAME) args...) into a discarded-value call.
Performs only run for side effects; we don't assign the result."
  (let ((op-spec (list-ref instr 1)))
    (unless (eq? (car op-spec) 'op)
      (%raw-error "emit-perform: expected (op NAME) spec"))
    (write-string "       " out)
    (emit-op-call out (cadr op-spec) (cddr instr) label-map)
    (newline out)))

;;; ---- halt ---------------------------------------------------------------

(define (emit-halt out pc chunk-ctx)
  "Halt instructions exit the zone. In non-split mode, we bump pc to
(1+ halt-PC). In chunk mode, we set pc to total-count so the dispatcher
loop exits cleanly regardless of the halt instruction's position."
  (cond
   ((not chunk-ctx)
    (write-string "       (cl:setf pc " out)
    (write-string (number->string (+ pc 1)) out)
    (write-string ")" out) (newline out)
    (write-string "       (cl:go zone-exit)" out) (newline out))
   (else
    (write-string "       (cl:setf pc " out)
    (write-string (number->string (chunk-ctx-total chunk-ctx)) out)
    (write-string ")" out) (newline out)
    (write-string "       (cl:go chunk-exit)" out) (newline out))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Batch generation
;;; ─────────────────────────────────────────────────────────────────────────

(define all-bootstrap-spaces
  '("assembler" "boot-env" "compilation-unit" "reader"
    "syntax-rules" "compiler" "prelude"))

(define (generate-all-zones! output-dir)
  "Generate compiled-zone files for all bootstrap spaces with non-zero
instruction counts. Deterministic: spaces are processed in a fixed order.
Signals an error if a bootstrap space name is unknown."
  (for-each
   (lambda (space-name)
     (let* ((space-id (string->symbol space-name))
            (count (cg/instruction-length space-id)))
       (cond
        ((< count 0)
         (%raw-error
          (string-append "generate-all-zones!: unknown compilation space: "
                         space-name)))
        ((> count 0)
         (let ((output-path (string-append output-dir "/" space-name "-zone.lisp")))
           (display (string-append "Generating " output-path " (" (number->string count) " PCs)..."))
           (newline)
           (generate-zone-cl! space-name output-path)
           (display (string-append "  Done: " output-path))
           (newline))))))
   all-bootstrap-spaces))

(define (sanitize-char-for-filename c)
  "Map one filesystem-unsafe character to an ASCII substitute. Scheme
identifiers admit `? ! * / < > | :` which collide with pathname
wildcards, shell globs, or path separators. Substitutes preserve
readability (`list?` → `listQ`, `set!` → `setB`) and are injective
per character."
  (cond ((char=? c #\?) #\Q)
        ((char=? c #\!) #\B)
        ((char=? c #\*) #\S)
        ((char=? c #\/) #\_)
        ((char=? c #\<) #\L)
        ((char=? c #\>) #\G)
        ((char=? c #\|) #\P)
        ((char=? c #\:) #\C)
        (else c)))

(define (sanitize-name-for-filename name-str)
  "Map each character in NAME-STR through sanitize-char-for-filename,
returning a filesystem-safe string. Deterministic per input; two
distinct names can collide only when they differ solely in unsafe
characters that map to the same substitute — rare in practice and
no worse than identical names."
  (let loop ((i 0) (acc '()))
    (if (>= i (string-length name-str))
        (apply string-append (reverse acc))
        (loop (+ i 1)
              (cons (string (sanitize-char-for-filename
                             (string-ref name-str i)))
                    acc)))))

(define (zone-name-for-code-object file-stem index co)
  "Compose a zone filename stem. The archive INDEX is always appended —
names are not unique within an archive (e.g., prelude has 7 distinct
`iter` code-objects, 3 distinct `pc`, 2 distinct `thunk`, etc.). Named
code-objects get a readable prefix for debugging; filenames and defun
names are still 1:1 with archive entries.

Sanitizes Scheme-legal but filesystem-unsafe characters like `?`, `!`,
and `/` so SBCL's pathname parser accepts the result."
  (let ((name (code-object-name co)))
    (cond
     ((and name (symbol? name))
      (string-append file-stem "-"
                     (sanitize-name-for-filename (symbol->string name))
                     "-" (number->string index)))
     ((and name (string? name))
      (string-append file-stem "-"
                     (sanitize-name-for-filename name)
                     "-" (number->string index)))
     (else
      (string-append file-stem "-" (number->string index))))))

(define (build-archive-co-index-map cos n)
  "Return a hash-table mapping each code-object in COS (vector of length N)
to its zero-based archive index. Used by emit-inner-co-lookup as a
fallback key for anonymous lambdas — named lambdas use their name symbol
directly and don't hit this map."
  (let ((h (%make-hash-table)))
    (let loop ((i 0))
      (when (< i n)
        (hash-set! h (vector-ref cos i) i)
        (loop (+ i 1))))
    h))

(define (co-key-for-archive-entry co index)
  "Derive the registry key for CO at archive INDEX. Always uses the
archive index — names are not unique within an archive (prelude has
7 distinct `iter` code-objects inside reverse, length, map, for-each,
min/max, range). If we keyed on name, the archive loader would silently
overwrite earlier registrations and all same-named code-objects would
share a single zone fn. Must match the key the archive loader derives
(runtime.lisp: archive-co-key). CO is unused but kept for symmetry with
the runtime side."
  co  ; unused
  index)

(define (archive-file-stem archive)
  "Derive the file-stem symbol from ARCHIVE's |file| plist field (minus
extension). Matches the key the CL archive loader uses to attach
native-fn — see archive-file-stem-symbol in src/runtime.lisp."
  (let ((file-str (archive/plist-get (cdr archive) 'file)))
    (if (string? file-str)
        (string->symbol (filename-strip-extension
                         (filename-basename file-str) ".scm"))
        (%raw-error
         "archive-file-stem: archive has no |file| field"))))

(define (generate-zones-for-archive-section! archive output-dir)
  "Emit one zone file per code-object in ARCHIVE (a single parsed
(ecec-archive ...) section) under OUTPUT-DIR. Used internally by
generate-all-zones-from-archive! which loops over concatenated archive
sections in a bundle.

File-stem comes from the archive's |file| field so the zone's registry
key matches what the CL archive loader constructs at boot time. Output
filenames are `<file-stem>-<co-name-or-index>-zone.lisp`.

Threads *emit-co-index-map* so emit-inner-co-lookup can resolve (const
<anonymous-co>) operands inside nested-lambda bodies."
  (let* ((cos (archive-sexp->code-objects archive))
         (n (vector-length cos))
         (file-stem-sym (archive-file-stem archive))
         (file-stem (symbol->string file-stem-sym))
         (index-map (build-archive-co-index-map cos n)))
    (when (= n 0)
      (%raw-error
       "generate-zones-for-archive-section!: archive has no code-objects"))
    (parameterize ((*emit-co-index-map* index-map))
      (let loop ((i 0))
        (when (< i n)
          (let* ((co (vector-ref cos i))
                 (zone-name (zone-name-for-code-object file-stem i co))
                 (co-key (co-key-for-archive-entry co i))
                 (output-path (string-append output-dir "/" zone-name "-zone.lisp")))
            (display (string-append "Generating " output-path
                                    " (" (number->string (code-object-length co))
                                    " PCs)..."))
            (newline)
            (generate-zone-cl-for-code-object! co zone-name output-path
                                               file-stem co-key)
            (display (string-append "  Done: " output-path))
            (newline))
          (loop (+ i 1)))))))

(define (generate-all-zones-from-archive! archive-path output-dir)
  "Read a bundle at ARCHIVE-PATH (a concatenation of (ecec-archive ...)
sections, one per compiled source file), iterate each section's
code-objects, and emit one zone file per code-object under OUTPUT-DIR.
Output filenames: `<file-stem>-<co-name-or-index>-zone.lisp`, where
FILE-STEM comes from each section's |file| field.

Signals an error if a section has zero entries. Deterministic: sections
are processed in bundle order; within each section entries are processed
in archive order (init first, then nested lambdas BFS)."
  (let ((port (open-input-file archive-path)))
    (let loop ()
      (let ((archive (ece-scheme-read port)))
        (cond
         ((eof? archive)
          (close-input-port port))
         ((and (pair? archive) (eq? (car archive) 'ecec-archive))
          (generate-zones-for-archive-section! archive output-dir)
          (loop))
         (else
          (close-input-port port)
          (%raw-error
           "generate-all-zones-from-archive!: expected (ecec-archive ...) section")))))))
