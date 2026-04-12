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
;;; Top-level entry point
;;; ─────────────────────────────────────────────────────────────────────────

(define (generate-zone-cl! space-name output-path)
  "Walk the compilation space named SPACE-NAME and write a CL source file
containing one (defun zone-NAME ...) to OUTPUT-PATH. SPACE-NAME may be a
string or a symbol. Returns OUTPUT-PATH on success; raises an error if the
space has no instructions registered."
  (let ((space-id (if (symbol? space-name)
                      space-name
                      (string->symbol space-name))))
    (let ((count (%space-instruction-length space-id)))
      (when (< count 0)
        (%raw-error
         (string-append "generate-zone-cl!: unknown space "
                        (if (symbol? space-name)
                            (symbol->string space-name)
                            space-name))))
      (let ((out (open-output-file output-path)))
        (emit-zone-header out space-name)
        (emit-zone-defun out space-name space-id count)
        (close-output-port out)
        output-path))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; File header
;;; ─────────────────────────────────────────────────────────────────────────

(define (emit-zone-header out space-name)
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
    (write-string ";;;; The CL runtime loads this file at boot and registers the defun" out) (newline out)
    (write-string ";;;; below under its space symbol in *compiled-zone-functions*." out) (newline out)
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

(define (emit-zone-defun out space-name space-id count)
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
    ;; FLAG is set by every (test ...) instruction; if a space has none we
    ;; still bind it to silence SBCL's unused-variable warning.
    (write-string "    (cl:declare (cl:ignorable flag))" out) (newline out)
    (write-string "    (cl:tagbody" out) (newline out)
    (emit-entry-dispatch out count)
    (emit-instructions out space-id count)
    (write-string "     zone-exit)" out) (newline out)
    (write-string "    (cl:values pc val env proc argl continue stack)))" out)
    (newline out)
    (newline out)
    (emit-zone-registration out name-str space-id)))

(define (emit-zone-registration out name-str space-id)
  "Emit the load-time effect that registers this zone in
*compiled-zone-functions*. Runs once per file load and is idempotent —
re-loading the file just overwrites the entry with the same function."
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

;;; ─────────────────────────────────────────────────────────────────────────
;;; Entry dispatch
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Generates:
;;;   (cl:case pc
;;;     (0 (cl:go pc-0))
;;;     (1 (cl:go pc-1))
;;;     ...
;;;     (cl:t (cl:go zone-exit)))
;;;
;;; The executor can hand off control to us at any PC (e.g. after resuming
;;; a continuation), and we pick up from there. If the PC is outside our
;;; range (e.g. from a cross-space resume), we bail through zone-exit and
;;; let the executor re-dispatch.

(define (emit-entry-dispatch out count)
  (write-string "     (cl:case pc" out) (newline out)
  (let loop ((pc 0))
    (when (< pc count)
      (write-string "       (" out)
      (write-string (number->string pc) out)
      (write-string " (cl:go pc-" out)
      (write-string (number->string pc) out)
      (write-string "))" out) (newline out)
      (loop (+ pc 1))))
  (write-string "       (cl:t (cl:go zone-exit)))" out) (newline out))

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
        (let ((instr (%space-source-ref space-id pc)))
          (write-string "     pc-" out)
          (write-string (number->string pc) out)
          (newline out)
          (emit-instruction out instr pc space-id label-map static-proc-map)
          (emit-pc-update-for-fall-through out instr pc count)
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
  (let ((label-set (label-pc-set space-id)))
    (let loop ((pc 0) (current-prim #f) (acc '()))
      (cond
       ((>= pc count) acc)
       (else
        (let* ((at-label? (member pc label-set))
               ;; Entering a labeled instruction starts a new basic block:
               ;; we can no longer trust the previous proc value.
               (current-prim (if at-label? #f current-prim))
               (instr (%space-source-ref space-id pc))
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

(define (label-pc-set space-id)
  "Return a list of PCs that have at least one label entry pointing to them.
Used to identify basic-block boundaries for the static-proc walker."
  (let loop ((entries (%space-label-entries space-id)) (acc '()))
    (cond
     ((null? entries) acc)
     (else
      (let ((pc (cdr (car entries))))
        (if (member pc acc)
            (loop (cdr entries) acc)
            (loop (cdr entries) (cons pc acc))))))))

(define (emit-pc-update-for-fall-through out instr pc count)
  "Emit `(cl:setf pc (1+ pc-i))` for instructions that fall through to the
next PC. Branch/goto/halt manage pc themselves (inside the body emitted by
emit-instruction), so they get nothing here."
  (let ((op (car instr)))
    (cond
     ((or (eq? op 'branch) (eq? op 'goto) (eq? op 'halt))
      ;; pc is already set inside the instruction body, or doesn't matter
      ;; (halt). Don't double-update.
      #t)
     (else
      (write-string "       (cl:setf pc " out)
      (write-string (number->string (+ pc 1)) out)
      (write-string ")" out) (newline out)))))

(define (build-pc-label-map space-id)
  "Return an alist of (label . pc) pairs for SPACE-ID's label table."
  (%space-label-entries space-id))

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

(define (emit-instruction out instr pc space-id label-map static-proc-map)
  (let ((op (car instr)))
    (cond
     ((eq? op 'assign)  (emit-assign out instr pc space-id label-map static-proc-map))
     ((eq? op 'test)    (emit-test out instr label-map))
     ((eq? op 'branch)  (emit-branch out instr label-map))
     ((eq? op 'goto)    (emit-goto out instr label-map pc))
     ((eq? op 'save)    (emit-save out instr))
     ((eq? op 'restore) (emit-restore out instr))
     ((eq? op 'perform) (emit-perform out instr label-map))
     ((eq? op 'halt)    (emit-halt out pc))
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
            (write-cl-quoted-ece-symbol out space-id)
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

(define (write-cl-quoted-ece-symbol out sym)
  "Emit SYM as a quoted CL form `'|name|`, preserving lowercase via the
pipe-escape syntax that CL's reader honors."
  (write-char #\' out)
  (write-char #\| out)
  (write-string (symbol->string sym) out)
  (write-char #\| out))

(define (write-cl-data-symbol out sym)
  "Emit SYM as a bare data symbol `|name|` (no leading quote), preserving
lowercase. Use this inside already-quoted lists, where the leading quote
is provided by the enclosing context."
  (write-char #\| out)
  (write-string (symbol->string sym) out)
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
ECE symbols pipe-wrapped to preserve case across CL's reader."
  (cond
   ((number? value) (write-string (number->string value) out))
   ((eq? value #t) (write-string "t" out))
   ((eq? value #f) (write-string "cl:nil" out))
   ((null? value) (write-string "cl:nil" out))
   ((string? value)
    (write-char #\" out)
    (write-string value out)
    (write-char #\" out))
   ((symbol? value)
    (write-cl-quoted-ece-symbol out value))
   ((pair? value)
    (write-char #\' out)
    (emit-quoted-datum out value))
   (else
    ;; Char and other atoms — fall through to write-cl-form which knows
    ;; how to emit them.
    (write-cl-form value out))))

(define (emit-quoted-datum out datum)
  "Emit DATUM in a quoted-data context — the leading quote has already
been written by the caller. Recursively pipe-wraps every symbol so that
the constructed CL list matches the byte-for-byte ECE-symbol shape that
the runtime expects."
  (cond
   ((null? datum) (write-string "()" out))
   ((symbol? datum) (write-cl-data-symbol out datum))
   ((number? datum) (write-string (number->string datum) out))
   ((eq? datum #t) (write-string "t" out))
   ((eq? datum #f) (write-string "cl:nil" out))
   ((string? datum)
    (write-char #\" out)
    (write-string datum out)
    (write-char #\" out))
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

(define (emit-branch out instr label-map)
  "Translate (branch (label L)) to (when flag (setf pc target) (go pc-N)).
The pc setf inside the (when ...) covers the taken branch; the not-taken
fall-through case is handled by emit-pc-update-for-fall-through."
  (let ((dest (list-ref instr 1)))
    (unless (eq? (car dest) 'label)
      (%raw-error "emit-branch: expected (label L) destination"))
    (let ((target-pc (pc-for-label (cadr dest) label-map)))
      (write-string "       (cl:when flag (cl:setf pc " out)
      (write-string (number->string target-pc) out)
      (write-string ") (cl:go pc-" out)
      (write-string (number->string target-pc) out)
      (write-string "))" out) (newline out))))

;;; ---- goto ---------------------------------------------------------------

(define (emit-goto out instr label-map pc)
  "Translate (goto DEST) where DEST is (label L) or (reg R).
Label gotos resolve to pc-N tags at emit time — same-space is just (go pc-N).
Register gotos (e.g. (goto (reg continue))) bail through zone-exit so the
executor can re-dispatch based on the runtime value of the register."
  (let ((dest (list-ref instr 1)))
    (cond
     ((eq? (car dest) 'label)
      (let ((target-pc (pc-for-label (cadr dest) label-map)))
        (write-string "       (cl:setf pc " out)
        (write-string (number->string target-pc) out)
        (write-string ") (cl:go pc-" out)
        (write-string (number->string target-pc) out)
        (write-string ")" out) (newline out)))
     ((eq? (car dest) 'reg)
      ;; Register goto — runtime-valued destination. The executor's
      ;; (goto (reg R)) logic handles space switching and PC resolution
      ;; based on the runtime value of the register. We bail through
      ;; zone-exit; the executor reads the register and re-dispatches.
      (write-string "       (cl:go zone-exit)" out) (newline out))
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

(define (emit-halt out pc)
  "Halt instructions exit the zone. We bump pc to (1+ halt-PC) so that when
the executor resumes from our returned register state, its (>= pc len)
guard fires immediately and it returns val without re-dispatching the halt
instruction. The +1 also matches the dispatch loop's natural fall-through
behaviour after the halt branch."
  (write-string "       (cl:setf pc " out)
  (write-string (number->string (+ pc 1)) out)
  (write-string ")" out) (newline out)
  (write-string "       (cl:go zone-exit)" out) (newline out))
