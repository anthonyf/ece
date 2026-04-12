;;;; ECE Codegen — Common Lisp backend.
;;;;
;;;; Reads templates from src/primitives.scm (via the define-host-primitive
;;;; macro), joins them with the metadata in primitives.def, and writes the
;;;; ~172 (defun ece-NAME ...) forms into bootstrap/primitives-auto.lisp.
;;;;
;;;; Stage 0 of the self-hosting roadmap. The CL runtime loads the generated
;;;; file at boot time in place of the deleted handwritten primitive defuns.
;;;;
;;;; Regeneration is invoked from the build system as:
;;;;   (load "src/codegen-cl.scm")
;;;;   (load "src/primitives.scm")
;;;;   (generate-primitives-auto-lisp! "primitives.def" "bootstrap/primitives-auto.lisp")
;;;;
;;;; Determinism: identical inputs SHALL produce a byte-identical output file.

;;; ─────────────────────────────────────────────────────────────────────────
;;; Template registry
;;; ─────────────────────────────────────────────────────────────────────────

;; Hash table keyed by primitive name symbol → template entry.
;; Each entry is a list: (params (target . template) (target . template) ...)
;;   params  — original parameter spec from (define-host-primitive (NAME . PARAMS) ...)
;;             may be a proper list, dotted, or a single rest symbol.
;;   target  — keyword-like ECE symbol with name beginning with ":" (e.g. :cl, :wat, :js)
;;   template — the original quasiquoted form, NOT yet expanded.
(define *host-primitives* (%make-hash-table))

;; Internal: store a registered template, erroring on duplicate names.
(define (register-host-primitive! spec body)
  "Macro expansion target for define-host-primitive. SPEC is (NAME . PARAMS)
or NAME (rare). BODY is an alternating list of (target template ...) pairs."
  (let ((name (if (pair? spec) (car spec) spec))
        (params (if (pair? spec) (cdr spec) '())))
    (when (hash-has-key? *host-primitives* name)
      (%raw-error
       (string-append "duplicate define-host-primitive: "
                      (symbol->string name))))
    (let ((targets (parse-target-pairs name body)))
      (validate-host-primitive name params targets)
      (hash-set! *host-primitives* name (cons params targets)))))

;; Walk the alternating (target template target template ...) list of body
;; pairs and return an alist of (target . template). Errors on malformed body.
(define (parse-target-pairs name body)
  (cond
   ((null? body) '())
   ((null? (cdr body))
    (%raw-error
     (string-append "define-host-primitive "
                    (symbol->string name)
                    ": odd number of body elements (target without template)")))
   (else
    (let ((target (car body))
          (template (cadr body))
          (rest (cddr body)))
      (unless (target-keyword? target)
        (%raw-error
         (string-append "define-host-primitive "
                        (symbol->string name)
                        ": expected target keyword, got "
                        (write-to-string target))))
      (cons (cons target template)
            (parse-target-pairs name rest))))))

(define (target-keyword? sym)
  "Test whether SYM is one of the known target keywords."
  (and (symbol? sym)
       (let ((name (symbol->string sym)))
         (or (string=? name ":cl")
             (string=? name ":wat")
             (string=? name ":js")))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Template definition macro
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Usage:
;;;   (define-host-primitive (car p) :cl `(cl:car ,p))
;;;   (define-host-primitive (+ . args) :cl `(cl:apply #'cl:+ ,args))
;;;   (define-host-primitive (cons a d)
;;;     :cl  `(cl:cons ,a ,d)
;;;     :wat `(call $cons (local.get ,a) (local.get ,d)))
;;;
;;; The template body is stored as a literal s-expression — not evaluated by
;;; ECE — so the codegen can walk it later and substitute parameters.

(define-macro (define-host-primitive spec . body)
  `(register-host-primitive! ',spec ',body))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Template validation
;;; ─────────────────────────────────────────────────────────────────────────

(define (validate-host-primitive name params targets)
  "Validate every template body for NAME under TARGETS. PARAMS is the spec's
parameter list. Errors with a primitive-naming message on the first failure."
  (let ((param-set (collect-param-names params)))
    (let loop ((entries targets))
      (if (null? entries)
          #t
          (let ((target (car (car entries)))
                (template (cdr (car entries))))
            (validate-template name target template param-set)
            (loop (cdr entries)))))))

(define (collect-param-names params)
  "Return a flat list of parameter symbols from PARAMS, treating dotted-tail
or bare-symbol forms as variadic (last symbol is the rest list)."
  (cond
   ((null? params) '())
   ((symbol? params) (list params))
   ((pair? params) (cons (car params) (collect-param-names (cdr params))))
   (else '())))

(define (validate-template name target template param-set)
  "Walk TEMPLATE looking for forbidden constructs and unbound placeholders."
  (unless (and (pair? template) (eq? (car template) 'quasiquote))
    (%raw-error
     (string-append "define-host-primitive "
                    (symbol->string name)
                    " (" (symbol->string target)
                    "): template body must be a quasiquoted form")))
  (validate-template-walk name target (cadr template) param-set #t))

(define (validate-template-walk name target node param-set in-quasi?)
  (cond
   ((null? node) #t)
   ((symbol? node) #t)
   ((pair? node)
    (cond
     ((eq? (car node) 'unquote)
      (let ((slot (cadr node)))
        (cond
         ((symbol? slot)
          (unless (member slot param-set)
            (%raw-error
             (string-append "define-host-primitive "
                            (symbol->string name)
                            " (" (symbol->string target)
                            "): unknown placeholder ,"
                            (symbol->string slot)))))
         (else #t))))
     ((eq? (car node) 'unquote-splicing)
      (%raw-error
       (string-append "define-host-primitive "
                      (symbol->string name)
                      " (" (symbol->string target)
                      "): unquote-splicing is forbidden in templates")))
     ((eq? (car node) 'quasiquote)
      (%raw-error
       (string-append "define-host-primitive "
                      (symbol->string name)
                      " (" (symbol->string target)
                      "): nested quasiquote is forbidden")))
     (else
      (validate-template-walk name target (car node) param-set in-quasi?)
      (validate-template-walk name target (cdr node) param-set in-quasi?))))
   (else #t)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Template expander
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Two consumers:
;;;   * Defun-path (Stage 0): bindings = #f, each ,NAME becomes the bare NAME
;;;     symbol so it lines up with the CL defun's parameter list.
;;;   * Inline-path (Stage 1): bindings is an alist mapping each parameter
;;;     symbol to a CL form; each ,NAME is replaced with its associated form.

(define (expand-host-primitive-template template bindings)
  "Walk a quasiquoted template body and substitute (unquote NAME) slots.

If BINDINGS is #f, each ,NAME is replaced with the bare symbol NAME — this
is the defun-emission path.

If BINDINGS is an alist of (name . cl-form) pairs, each ,NAME is replaced
with its associated CL form — this is the inline-substitution path. An
unbound slot raises an error."
  (unless (and (pair? template) (eq? (car template) 'quasiquote))
    (%raw-error "expand-host-primitive-template: not a quasiquote form"))
  (expand-host-primitive-template-walk (cadr template) bindings))

(define (expand-host-primitive-template-walk node bindings)
  (cond
   ((null? node) '())
   ((symbol? node) node)
   ((pair? node)
    (cond
     ((eq? (car node) 'unquote)
      (let ((slot (cadr node)))
        (cond
         ((not bindings) slot)
         (else
          (let ((pair (assq slot bindings)))
            (if pair
                (cdr pair)
                (%raw-error
                 (string-append "expand-host-primitive-template: unbound slot ,"
                                (symbol->string slot)))))))))
     ((eq? (car node) 'unquote-splicing)
      (%raw-error "expand-host-primitive-template-walk: stray unquote-splicing"))
     ((eq? (car node) 'quasiquote)
      (%raw-error "expand-host-primitive-template-walk: nested quasiquote"))
     (else
      (cons (expand-host-primitive-template-walk (car node) bindings)
            (expand-host-primitive-template-walk (cdr node) bindings)))))
   (else node)))

(define (expand-template template)
  "Defun-path template expansion. Thin wrapper over
expand-host-primitive-template that substitutes ,NAME with the bare NAME."
  (expand-host-primitive-template template #f))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Lookup helpers
;;; ─────────────────────────────────────────────────────────────────────────

(define (host-primitive-target name target)
  "Return the template form for NAME's TARGET, or #f if not present."
  (let ((entry (hash-ref *host-primitives* name #f)))
    (and entry
         (let ((pair (assoc target (cdr entry))))
           (and pair (cdr pair))))))

(define (host-primitive-params name)
  "Return the params spec for NAME, or #f if not registered."
  (let ((entry (hash-ref *host-primitives* name #f)))
    (and entry (car entry))))

(define (host-primitive-names)
  "Return a list of all registered primitive names."
  (hash-keys *host-primitives*))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Inline-substitution entry point
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Consumed by src/codegen-cl-inline.scm (Stage 1). Given a primitive name
;;; and a list of CL forms representing argument values at a call site,
;;; returns the :cl template body with parameters substituted.

(define (host-primitive-cl-body name arg-forms)
  "Return the inlined :cl template body for primitive NAME, with its
parameters substituted by the corresponding CL forms in ARG-FORMS.

Returns #f if NAME has no :cl template registered, or if ARG-FORMS and the
primitive's declared params are incompatible (wrong arity).

Examples:
  (host-primitive-cl-body 'car '(x))     ;; => (cl:car x)
  (host-primitive-cl-body '+ '(a b))     ;; => (cl:apply (cl:function cl:+) (cl:list a b))"
  (let ((template (host-primitive-target name ':cl))
        (params (host-primitive-params name)))
    (and template
         (let ((bindings (build-host-primitive-bindings params arg-forms)))
           (and bindings
                (expand-host-primitive-template template bindings))))))

(define (build-host-primitive-bindings params arg-forms)
  "Build an alist of (param-symbol . cl-form) for template substitution.

Returns #f when PARAMS and ARG-FORMS are incompatible.

Proper params map one-to-one with ARG-FORMS. Variadic params (a bare symbol
or a dotted tail) absorb the remaining ARG-FORMS into a (cl:list ...) form,
matching how the defun-path defuns receive their &rest arguments as a
pre-built list."
  (cond
   ((null? params)
    (and (null? arg-forms) '()))
   ((symbol? params)
    (list (cons params (cons 'cl:list arg-forms))))
   ((pair? params)
    (cond
     ((null? arg-forms) #f)
     (else
      (let ((rest (build-host-primitive-bindings (cdr params) (cdr arg-forms))))
        (and rest
             (cons (cons (car params) (car arg-forms))
                   rest))))))
   (else #f)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Manifest parser
;;; ─────────────────────────────────────────────────────────────────────────

;; Parse primitives.def into a hash table: name → (id arity platform).
;; Each line in the manifest is an s-expression:
;;   (id name arity platform description)
(define (parse-primitives-def filename)
  (let ((table (%make-hash-table))
        (port (open-input-file filename)))
    (let loop ()
      (let ((entry (ece-scheme-read port)))
        (cond
         ((eof? entry)
          (close-input-port port)
          table)
         ((and (pair? entry) (>= (length entry) 4))
          (let ((id (car entry))
                (name (cadr entry))
                (arity (caddr entry))
                (platform (cadddr entry)))
            (when (hash-has-key? table name)
              (%raw-error
               (string-append "primitives.def: duplicate entry for "
                              (symbol->string name))))
            (hash-set! table name (list id arity platform))
            (loop)))
         (else (loop)))))))

(define (manifest-id entry)       (car entry))
(define (manifest-arity entry)    (cadr entry))
(define (manifest-platform entry) (caddr entry))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Arity matching
;;; ─────────────────────────────────────────────────────────────────────────

(define (params-arity params)
  "Return the declared arity from a parameter spec.
   * fixed list (a b c) → 3
   * empty () → 0
   * dotted (a b . rest) → -1
   * symbol args → -1"
  (cond
   ((null? params) 0)
   ((symbol? params) -1)
   ((pair? params)
    (if (proper-list? params)
        (length params)
        -1))
   (else 0)))

(define (proper-list? lst)
  (cond
   ((null? lst) #t)
   ((pair? lst) (proper-list? (cdr lst)))
   (else #f)))

(define (arity-matches? template-arity manifest-arity)
  "Variadic on either side accepts any. Otherwise must be equal."
  (cond
   ((= manifest-arity -1) #t)
   ((= template-arity -1) #t)
   (else (= template-arity manifest-arity))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; CL parameter list builder
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Convert ECE parameter spec to CL defun param list:
;;;   ()              → ()
;;;   (a b c)         → (a b c)
;;;   args            → (&rest args)
;;;   (a b . rest)    → (a b &rest rest)

(define (params->cl-lambda-list params)
  (cond
   ((null? params) '())
   ((symbol? params) (list '&rest params))
   ((pair? params)
    (if (proper-list? params)
        params
        (let loop ((p params) (acc '()))
          (cond
           ((null? (cdr p)) (reverse (cons (car p) acc)))
           ((symbol? (cdr p))
            (reverse (cons (cdr p) (cons '&rest (cons (car p) acc)))))
           (else (loop (cdr p) (cons (car p) acc)))))))
   (else '())))

;;; ─────────────────────────────────────────────────────────────────────────
;;; CL output emitter
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; The emitter writes s-expressions in a form CL's standard reader (default
;;; :upcase mode) can parse and resolve correctly.
;;;
;;; Symbol-handling rules:
;;;   * Bare lowercase ECE symbol in a function/variable position →
;;;     emitted as-is, CL upcases on read (e.g. "scheme-bool" → SCHEME-BOOL).
;;;   * Symbol containing ":" (package qualifier) → emitted as-is, CL handles
;;;     the prefix split (e.g. "cl:car" → COMMON-LISP:CAR).
;;;   * Symbol in a quoted-data position with no ":" → wrapped in pipes so the
;;;     case is preserved literally (e.g. 'continuation → '|continuation|).
;;;
;;; The walker tracks the in-quote? flag through (quote ...) sub-forms.

(define (write-cl-form form port)
  "Top-level entry point: emit FORM as CL source to PORT."
  (write-cl form port #f))

(define (write-cl form port quoted?)
  (cond
   ((null? form) (write-string "()" port))
   ((eq? form #t) (write-string "T" port))
   ((eq? form #f) (write-string "NIL" port))
   ((number? form) (write-string (number->string form) port))
   ((string? form) (write-cl-string form port))
   ((char? form) (write-cl-char form port))
   ((symbol? form) (write-cl-symbol form port quoted?))
   ((pair? form) (write-cl-list form port quoted?))
   (else (%raw-error
          (string-append "write-cl: unsupported form " (write-to-string form))))))

(define (write-cl-string str port)
  ;; Quote the string with backslash-escaped double quotes and backslashes.
  (write-char #\" port)
  (let ((len (string-length str)))
    (let loop ((i 0))
      (when (< i len)
        (let ((ch (string-ref str i)))
          (cond
           ((char=? ch #\\)
            (write-char #\\ port)
            (write-char #\\ port))
           ((char=? ch #\")
            (write-char #\\ port)
            (write-char #\" port))
           (else (write-char ch port))))
        (loop (+ i 1)))))
  (write-char #\" port))

(define (write-cl-char ch port)
  (write-string "#\\" port)
  (cond
   ((char=? ch #\space)   (write-string "Space" port))
   ((char=? ch #\newline) (write-string "Newline" port))
   ((char=? ch #\tab)     (write-string "Tab" port))
   ((char=? ch #\return)  (write-string "Return" port))
   (else (write-char ch port))))

;; The QUOTED? parameter is unused but retained because the walker passes it
;; through every recursive call. The first cut auto-pipe-escaped lowercase
;; identifiers in quoted positions, but ECE primitives use both lowercase data
;; tags ('|continuation|) and uppercase ones ('parameter), so the codegen
;; can't infer the right answer from the symbol alone — the template author
;; writes |name| explicitly when lowercase preservation is required.
(define (write-cl-symbol sym port quoted?)
  "Emit SYM verbatim. The template author chooses case-preservation by writing
literal |name| pipe-escaped symbols where needed; bare lowercase symbols round
trip through CL's :upcase reader to uppercase package symbols."
  (write-string (symbol->string sym) port))

(define (write-cl-list lst port quoted?)
  (cond
   ;; Special case: (quote X) — write as 'X with X in quoted context.
   ;; Only when not already inside a quote (otherwise '(quote x) is data).
   ((and (not quoted?)
         (eq? (car lst) 'quote)
         (pair? (cdr lst))
         (null? (cddr lst)))
    (write-char #\' port)
    (write-cl (cadr lst) port #t))
   (else
    (write-char #\( port)
    (write-cl (car lst) port quoted?)
    (let loop ((rest (cdr lst)))
      (cond
       ((null? rest) (write-char #\) port))
       ((pair? rest)
        (write-char #\space port)
        (write-cl (car rest) port quoted?)
        (loop (cdr rest)))
       (else
        (write-string " . " port)
        (write-cl rest port quoted?)
        (write-char #\) port)))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Defun emission
;;; ─────────────────────────────────────────────────────────────────────────

(define (emit-defun port name params body)
  "Write (defun ece-NAME PARAMS BODY) to PORT, indented for readability."
  (write-string "(defun ece-" port)
  (write-string (symbol->string name) port)
  (write-char #\space port)
  (write-cl-form (params->cl-lambda-list params) port)
  (write-char #\newline port)
  (write-string "  " port)
  (write-cl-form body port)
  (write-char #\) port)
  (write-char #\newline port))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Joining / pre-emission validation
;;; ─────────────────────────────────────────────────────────────────────────

(define *partial-codegen?* #f)
(define (set-partial-codegen! flag) (set! *partial-codegen?* flag))

(define (collect-emit-list manifest)
  "Walk the manifest and template registry, validate, and return a list of
   (name params expanded-cl-body) entries — alphabetized by name.
   When *partial-codegen?* is #t, missing templates are skipped instead of
   triggering a hard error (used by PoC and incremental development)."
  (let ((errors '())
        (entries '()))
    ;; First pass: every core/cl primitive in the manifest must have a template.
    (let ((manifest-names (hash-keys manifest)))
      (let loop ((names manifest-names))
        (when (pair? names)
          (let* ((name (car names))
                 (mentry (hash-ref manifest name))
                 (platform (manifest-platform mentry)))
            (cond
             ((or (eq? platform 'core) (eq? platform 'cl))
              (cond
               ((not (hash-has-key? *host-primitives* name))
                (unless *partial-codegen?*
                  (set! errors
                        (cons (string-append "missing template for "
                                             (symbol->string platform)
                                             " primitive: "
                                             (symbol->string name))
                              errors))))
               (else
                (let* ((params (host-primitive-params name))
                       (template (host-primitive-target name ':cl))
                       (template-arity (params-arity params))
                       (declared-arity (manifest-arity mentry)))
                  (cond
                   ((not template)
                    (set! errors
                          (cons (string-append "no :cl template for "
                                               (symbol->string name))
                                errors)))
                   ((not (arity-matches? template-arity declared-arity))
                    (set! errors
                          (cons (string-append "arity mismatch for "
                                               (symbol->string name)
                                               ": template has "
                                               (number->string template-arity)
                                               ", manifest declares "
                                               (number->string declared-arity))
                                errors)))
                   (else
                    (set! entries
                          (cons (list name params (expand-template template))
                                entries))))))))
             ((eq? platform 'ece)
              ;; ECE-platform primitives must NOT have a host template.
              (when (hash-has-key? *host-primitives* name)
                (set! errors
                      (cons (string-append
                             "ece-platform primitive "
                             (symbol->string name)
                             " has a host template (should be in prelude.scm only)")
                            errors))))
             ((eq? platform 'browser)
              ;; Browser primitives may have templates but :cl is not required.
              #t))
            (loop (cdr names))))))
    ;; Second pass: every template entry must correspond to a manifest entry.
    (let loop ((names (host-primitive-names)))
      (when (pair? names)
        (let ((name (car names)))
          (unless (hash-has-key? manifest name)
            (set! errors
                  (cons (string-append "orphan template (not in primitives.def): "
                                       (symbol->string name))
                        errors)))
          (loop (cdr names)))))
    (cond
     ((null? errors)
      (sort-entries-by-name entries))
     (else
      (%raw-error
       (string-append
        "codegen-cl: aborting before emission due to validation errors:\n"
        (join-with-newline (reverse errors))))))))

(define (join-with-newline lst)
  (cond
   ((null? lst) "")
   ((null? (cdr lst)) (string-append "  - " (car lst)))
   (else (string-append "  - " (car lst) "\n"
                        (join-with-newline (cdr lst))))))

(define (sort-entries-by-name entries)
  ;; Insertion sort — small (~172) input, no need for fancier algorithm.
  (let loop ((unsorted entries) (sorted '()))
    (if (null? unsorted)
        sorted
        (loop (cdr unsorted) (insert-by-name (car unsorted) sorted)))))

(define (insert-by-name entry sorted)
  (cond
   ((null? sorted) (list entry))
   ((string<? (symbol->string (car entry))
              (symbol->string (car (car sorted))))
    (cons entry sorted))
   (else (cons (car sorted) (insert-by-name entry (cdr sorted))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; File emitter
;;; ─────────────────────────────────────────────────────────────────────────

(define (emit-header port)
  (write-string ";;;; bootstrap/primitives-auto.lisp" port) (newline port)
  (write-string ";;;;" port) (newline port)
  (write-string ";;;; AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND." port) (newline port)
  (write-string ";;;;" port) (newline port)
  (write-string ";;;; Source: primitives.def + src/primitives.scm" port) (newline port)
  (write-string ";;;; Generator: src/codegen-cl.scm" port) (newline port)
  (write-string ";;;; Regenerate: make bootstrap" port) (newline port)
  (write-string ";;;;" port) (newline port)
  (write-string ";;;; This file contains one (defun ece-NAME ...) per core/cl" port) (newline port)
  (write-string ";;;; primitive. The CL runtime loads it during boot, after" port) (newline port)
  (write-string ";;;; helper definitions and before init-primitive-dispatch-tables." port) (newline port)
  (newline port)
  (write-string "(in-package :ece)" port) (newline port)
  (newline port))

(define (emit-entries port entries)
  (let loop ((es entries))
    (when (pair? es)
      (let ((entry (car es)))
        (emit-defun port (car entry) (cadr entry) (caddr entry))
        (newline port)
        (loop (cdr es))))))

(define (generate-primitives-auto-lisp! manifest-path output-path)
  "Top-level entry point. Reads MANIFEST-PATH, joins with the templates loaded
into *host-primitives*, validates, and writes OUTPUT-PATH."
  (let* ((manifest (parse-primitives-def manifest-path))
         (entries (collect-emit-list manifest))
         (out (open-output-file output-path)))
    (emit-header out)
    (emit-entries out entries)
    (close-output-port out)
    output-path))
