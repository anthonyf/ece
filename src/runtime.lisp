(defpackage #:ece
  (:use #:cl)
  (:export #:*global-env*
           #:evaluate
           #:lambda
           #:var
           #:set
           #:set!
           #:if
           #:begin
           #:quote
           #:%raw-call/cc
           #:call/cc
           #:define
           #:display
           #:newline
           #:null?
           #:eof?
           #:primitive
           #:pair?
           #:map
           #:apply
           #:define-macro
           #:quasiquote
           #:unquote
           #:unquote-splicing
           #:number?
           #:string?
           #:symbol?
           #:boolean?
           #:zero?
           #:eq?
           #:eqv?
           #:equal?
           #:modulo
           #:even?
           #:odd?
           #:positive?
           #:negative?
           #:filter
           #:reduce
           #:for-each
           #:gensym
           #:letrec
           #:else
           #:reverse
           #:case
           #:do
           #:char?
           #:char=?
           #:char<?
           #:char->integer
           #:integer->char
           #:string-length
           #:string-ref
           #:string-append
           #:substring
           #:string->number
           #:number->string
           #:string->symbol
           #:symbol->string
           #:string=?
           #:string<?
           #:string>?
           #:error
           #:assoc
           #:member
           #:list-ref
           #:list-tail
           #:vector?
           #:make-vector
           #:vector
           #:vector-length
           #:vector-ref
           #:vector-set!
           #:vector->list
           #:list->vector
           #:load
           #:read-line
           #:write-to-string
           #:bitwise-and
           #:bitwise-or
           #:bitwise-xor
           #:bitwise-not
           #:arithmetic-shift
           #:random
           #:random-seed!
           #:*random-state*
           #:%make-hash-table
           #:hash-table
           #:hash-table?
           #:hash-ref
           #:hash-set!
           #:hash-set
           #:hash-remove!
           #:hash-has-key?
           #:hash-keys
           #:hash-values
           #:hash-count
           #:sleep
           #:clear-screen
           #:write-byte
           #:string-downcase
           #:string-upcase
           #:string-split
           #:string-trim
           #:string-contains?
           #:string-join
           #:save-image!
           #:load-image!
           #:define-record
           #:any
           #:every
           #:compose
           #:identity
           #:range
           #:clamp
           #:fold
           #:fold-left
           #:fold-right
           #:collect
           #:union
           #:set-difference
           #:execute-from-pc
           #:get-macro
           #:set-macro!
           #:expand-macro
           #:mc-compile
           #:mc-compile-and-go
           #:make-parameter
           #:parameterize
           #:dynamic-wind
           #:call-with-current-continuation
           #:%raw-error
           #:error-object?
           #:error-object-message
           #:error-object-irritants
           #:make-error-object
           #:raise
           #:with-exception-handler
           #:guard
           #:input-port?
           #:output-port?
           #:port?
           #:current-input-port
           #:current-output-port
           #:open-input-file
           #:open-output-file
           #:close-input-port
           #:close-output-port
           #:open-input-string
           #:read-char
           #:peek-char
           #:write-char
           #:char-ready?
           #:char-whitespace?
           #:char-alphabetic?
           #:char-numeric?
           #:with-input-from-file
           #:with-output-to-file
           #:call-with-input-file
           #:call-with-output-file
           #:%display-to-port
           #:%write-to-port
           #:%newline-to-port
           #:%write-char-to-port
           #:%write-string-to-port
           #:%initial-output-port
           #:%initial-input-port
           #:%intern-ece
           #:%instruction-vector-length
           #:%instruction-vector-push!
           #:%label-table-set!
           #:%label-table-ref
           #:code-object
           #:code-object-p
           #:make-code-object
           #:code-object-source-instructions
           #:code-object-resolved-instructions
           #:code-object-labels
           #:code-object-name
           #:code-object-arity
           #:code-object-source-loc
           #:code-object-native-fn
           #:code-object-archive-key
           #:disassemble
           #:extend-environment
           #:ece-runtime-error
           #:ece-original-error
           #:ece-error-procedure
           #:ece-error-arguments
           #:ece-error-environment
           #:ece-error-instruction
           #:ece-error-backtrace
           #:mc-eval
           #:command-line
           #:exit
           #:get-environment-variable
           #:%exe-path
           #:%list-directory
           #:%file-exists?
           #:open-binary-input-file
           #:read-byte
           #:%make-directory
           #:%chmod
           #:*scheme-false*
           #:scheme-false-p
           #:scheme-bool))

(in-package :ece)

;;;; ========================================================================
;;;; SCHEME BOOLEAN SENTINEL
;;;; ========================================================================
;;;
;;; In Scheme, #f is the only false value — '() is truthy.
;;; CL conflates nil and '(), so we need a distinct sentinel for #f.

(defstruct (scheme-false (:constructor %make-scheme-false)))
(defvar *scheme-false* (%make-scheme-false))
(declaim (inline scheme-bool))
(defun scheme-bool (x)
  "Convert a CL boolean (t/nil) to a Scheme boolean (#t/#f)."
  (if x t *scheme-false*))

;;;; ========================================================================
;;;; RUNTIME — Minimal code needed to execute compiled ECE instructions
;;;; ========================================================================
;;;
;;; Stage 0 of the self-hosting roadmap (emit-host-primitives) moved the
;;; implementation of every core/cl primitive out of this file. Each primitive
;;; now lives as a (define-host-primitive ...) template in src/primitives.scm.
;;; The codegen tool (src/codegen-cl.scm) walks those templates and emits
;;; bootstrap/primitives-auto.lisp, which is loaded near the bottom of this
;;; file just before init-primitive-dispatch-tables. To regenerate after
;;; editing primitives.scm, run `make bootstrap` or
;;; `make bootstrap/primitives-auto.lisp`.
;;;
;;; What stays here: helper functions referenced by templates (scheme-bool,
;;; hash-frame-p, ece-output-to-stream, ece-port-stream and related,
;;; format-ece-proc, etc.), CL specials (*executing-code-obj*, *global-env*,
;;; *traced-procedures*, ...), the code-object struct, the executor
;;; (execute-instructions), and the operation dispatch infrastructure.

;;; ECE runtime error condition
;;; Wraps CL errors with register machine context for debugging

(define-condition ece-runtime-error (error)
  ((original-error :initarg :original-error :reader ece-original-error)
   (ece-procedure :initarg :procedure :reader ece-error-procedure :initform nil)
   (ece-arguments :initarg :arguments :reader ece-error-arguments :initform nil)
   (ece-environment :initarg :environment :reader ece-error-environment :initform nil)
   (ece-instruction :initarg :instruction :reader ece-error-instruction :initform nil)
   (ece-backtrace :initarg :backtrace :reader ece-error-backtrace :initform nil))
  (:report (lambda (c stream)
             (let ((*print-circle* t) (*print-level* 5) (*print-length* 20))
               (format stream "ECE error: ~A" (ece-original-error c))
               (let ((proc (ece-error-procedure c)))
                 (when proc
                   (format stream "~%  in procedure: ~A" (format-ece-proc proc))
                   (let ((args (ece-error-arguments c)))
                     (when args
                       (format stream "~%  with arguments: ~S" args)))))
               (let ((env (ece-error-environment c)))
                 (when (and env (consp env) (consp (car env)))
                   (let ((frame (car env)))
                     (format stream "~%  bindings:")
                     (if (hash-frame-p frame)
                         (let ((i 0))
                           (block done
                             (maphash (lambda (k v)
                                        (when (>= i 10) (return-from done))
                                        (format stream "~%    ~A = ~S"
                                                k (truncate-value v))
                                        (incf i))
                                      (cdr frame))))
                         (loop for var in (car frame)
                               for val in (cdr frame)
                               for i below 10
                               do (format stream "~%    ~A = ~S"
                                          var (truncate-value val)))))))
               (let ((bt (ece-error-backtrace c)))
                 (when bt
                   (format stream "~%  backtrace:")
                   (loop for entry in bt
                         for i from 0
                         do (let ((space-sym (cadr entry))
                                  (local-pc (cddr entry)))
                              (format stream "~%    [~D] ~A at ~A" i
                                      (if (car entry)
                                          (format-ece-proc (car entry))
                                          "<unknown>")
                                      (format-ece-location space-sym local-pc))))))))))

(defun format-ece-proc (proc)
  "Format a procedure value for display in errors.
Includes source location if available."
  (cond
    ((compiled-procedure-p proc)
     (let* ((entry (compiled-procedure-entry proc))
            (name (procedure-name proc))
            (loc (cond
                   ;; §7.4: bare code-object entry — read source-loc from struct
                   ((code-object-p entry)
                    (code-object-source-loc entry))
                   ((and (consp entry) (code-object-p (car entry)))
                    (code-object-source-loc (car entry)))
                   ((consp entry)
                    (resolve-ece-source-location (car entry) (cdr entry))))))
       (cond
         ((and name loc)
          (format nil "~A (~A:~D:~D)" name (car loc) (cadr loc) (caddr loc)))
         (name (format nil "~A" name))
         (t (format nil "<compiled-procedure entry=~A>" entry)))))
    ((primitive-procedure-p proc)
     (let ((id-or-name (primitive-procedure-id proc)))
       (if (integerp id-or-name)
           (format nil "<primitive ~A>" (aref *primitive-name-table* id-or-name))
           (format nil "<primitive ~A>" id-or-name))))
    (t (format nil "~S" proc))))

(defun truncate-value (val)
  "Truncate a value for display if too long."
  (let* ((*print-level* 3)
         (*print-length* 5)
         (*print-circle* t)
         (s (format nil "~S" val)))
    (if (> (length s) 60)
        (format nil "~A..." (subseq s 0 57))
        s)))

(defun extract-ece-backtrace (stack)
  "Walk the register stack to extract a backtrace.
Returns a list of (proc space-sym . local-pc) entries, limited to 10 frames.
The stack interleaves saved registers; we look for saved proc values
and saved continue values (integers = PCs). A continue value paired with
a nearby proc gives a named frame; a lone continue gives an anonymous frame."
  (let ((frames '())
        (last-proc nil))
    (dolist (item stack)
      (when (>= (length frames) 10)
        (return))
      (cond
        ;; A compiled-procedure or primitive on the stack is likely a saved proc
        ((or (compiled-procedure-p item) (primitive-procedure-p item))
         (setf last-proc item))
        ;; An integer or qualified address on the stack is likely a saved continue
        ((or (integerp item) (qualified-address-p item))
         (push (cons last-proc
                     (cons (qualified-space-id item)
                           (qualified-local-pc item)))
               frames)
         (setf last-proc nil))))
    (nreverse frames)))

(defun format-ece-location (space-sym local-pc)
  "Format a source location for SPACE-SYM at LOCAL-PC.
Returns \"file:line:col\" if source-map has an entry, otherwise \"pc=N\"."
  (let ((loc (resolve-ece-source-location space-sym local-pc)))
    (if loc
        (format nil "~A:~D:~D" (car loc) (cadr loc) (caddr loc))
        (format nil "pc=~D" local-pc))))

(defun format-ece-backtrace (backtrace)
  "Format a backtrace as readable text.
Each entry is (proc space-sym . local-pc)."
  (with-output-to-string (s)
    (loop for entry in backtrace
          for i from 0
          do (let ((space-sym (cadr entry))
                   (local-pc (cddr entry)))
               (format s "~%  [~D] ~A at ~A"
                       i (format-ece-proc (car entry))
                       (format-ece-location space-sym local-pc))))))

;;; Frame-based environment (SICP Section 4.1.3)
;;; A frame is one of:
;;;   - vector-based: #(val1 val2 ...) — O(1) lexical access (no variable names)
;;;   - hash-table-based: (:hash-frame . <hash-table>) — O(1) named access for globals
;;; An environment is a list of frames

(defun hash-frame-p (frame)
  "Return T if FRAME is a hash-table-backed frame (:hash-frame . ht)."
  (and (consp frame)
       (or (eq (car frame) :hash-frame)
           ;; ECE code can construct archive/module environments using
           ;; ECE keyword-style symbols. Accept that spelling so module
           ;; loaders written in ECE can create hash frames for the CL VM.
           (and (symbolp (car frame))
                (string= (symbol-name (car frame)) ":hash-frame")))))

(defun lexical-ref (depth offset env)
  "O(1) variable access: traverse DEPTH frames, index at OFFSET."
  (declare (type fixnum depth offset))
  (let ((frame env))
    (loop repeat depth do (setf frame (cdr frame)))
    (svref (car frame) offset)))

(defun lexical-set! (depth offset val env)
  "O(1) variable mutation: traverse DEPTH frames, set at OFFSET."
  (declare (type fixnum depth offset))
  (let ((frame env))
    (loop repeat depth do (setf frame (cdr frame)))
    (setf (svref (car frame) offset) val)))

(defun extend-environment (vars vals base-env &optional (extra-slots 0))
  "Create a new vector environment frame for O(1) lexical access."
  (let ((extra (the fixnum extra-slots)))
    (cond
      ((or (listp vars) (null vars))
       (let ((val-list nil) (v vars) (a vals))
         (loop while (consp v)
               do (push (car a) val-list)
               (setf v (cdr v)) (setf a (cdr a)))
         (when v (push a val-list))
         (let ((vals-vec (nreverse val-list)))
           (when (> extra 0)
             (setf vals-vec (nconc vals-vec (make-list extra))))
           (cons (coerce vals-vec 'simple-vector) base-env))))
      (t ; rest-only parameter
       (if (> extra 0)
           (let ((vec (make-array (1+ extra) :initial-element nil)))
             (setf (svref vec 0) vals)
             (cons vec base-env))
           (cons (vector vals) base-env))))))

(defun lookup-variable-value (var env)
  "Look up VAR by name. Dispatches on frame type: hash-table O(1), skip vectors."
  (labels ((env-loop (env)
             (if (null env)
                 (error "Unbound variable: ~A" var)
                 (let ((frame (car env)))
                   (cond
                     ((vectorp frame)
                      (env-loop (cdr env)))
                     ((hash-frame-p frame)
                      (multiple-value-bind (val found)
                          (gethash var (cdr frame))
                        (if found val (env-loop (cdr env)))))
                     (t (env-loop (cdr env))))))))
    (env-loop env)))

(defun lookup-global-variable (var)
  "Look up VAR in the global environment only, bypassing lexical frames.
Used by %global-ref for syntax-rules hygiene."
  (lookup-variable-value var *global-env*))

(defun set-variable-value! (var val env)
  "Set VAR by name. Dispatches on frame type: hash-table O(1), skip vectors."
  (labels ((env-loop (env)
             (if (null env)
                 (error "Unbound variable: ~A" var)
                 (let ((frame (car env)))
                   (cond
                     ((vectorp frame)
                      (env-loop (cdr env)))
                     ((hash-frame-p frame)
                      (multiple-value-bind (old found)
                          (gethash var (cdr frame))
                        (declare (ignore old))
                        (if found
                            (progn (setf (gethash var (cdr frame)) val) val)
                            (env-loop (cdr env)))))
                     (t (env-loop (cdr env))))))))
    (env-loop env)))

(defun define-variable! (var val env)
  "Define VAR in the first hash frame in ENV, skipping vector frames."
  (labels ((find-hash-frame (e)
             (cond ((null e) (error "No hash frame found for define-variable!"))
                   ((hash-frame-p (car e)) (car e))
                   (t (find-hash-frame (cdr e))))))
    (setf (gethash var (cdr (find-hash-frame env))) val)))

;;; Primitives and global environment
;;; Implementations live in src/primitives.scm and are emitted into
;;; bootstrap/primitives-auto.lisp by codegen-cl.scm. The legacy override
;;; table and CL-fallthrough conventions have been retired — every core/cl
;;; primitive resolves via Convention 1 (ece-NAME in :ece package).

;;; --- Manifest-based dispatch tables ---

(defun parse-primitives-manifest (filename)
  "Parse primitives.def and return a list of (id name arity platform) entries."
  (unless (probe-file filename)
    (error "Manifest not found: ~A" filename))
  (let ((entries nil))
    (with-open-file (stream filename :direction :input)
      (loop for form = (cl:read stream nil :eof)
            until (eq form :eof)
            when (and (listp form) (>= (length form) 4))
            do (push (list (first form)   ; id
                           (second form)  ; name
                           (third form)   ; arity
                           (fourth form)) ; platform
                     entries)))
    (let ((result (nreverse entries)))
      (when (null result)
        (error "No entries parsed from ~A" filename))
      result)))

(defparameter *manifest-path*
  (asdf:system-relative-pathname :ece "primitives.def"))

(defparameter *manifest-entries*
  (parse-primitives-manifest *manifest-path*))

(defparameter *primitive-max-id*
  (reduce #'max *manifest-entries* :key #'first))

;; Dispatch table: vector indexed by primitive ID → CL function
(defparameter *primitive-dispatch-table*
  (make-array (1+ *primitive-max-id*) :initial-element nil))

;; Name table: vector indexed by primitive ID → ECE name symbol
(defparameter *primitive-name-table*
  (make-array (1+ *primitive-max-id*) :initial-element nil))

;; Reverse lookup: ECE name symbol → primitive ID
(defparameter *primitive-name-to-id*
  (make-hash-table :test 'eq))

;; Set of IDs that this platform actually implements (not stubs)
(defparameter *primitive-available-ids*
  (make-hash-table :test 'eql))

(defun ece-sym (cl-sym)
  "Convert a CL symbol to its lowercase ECE equivalent."
  (intern (string-downcase (symbol-name cl-sym)) :ece))

(defun resolve-cl-primitive (ece-name-sym)
  "Resolve ECE primitive name to its CL implementation function.
Every core/cl primitive has an ece-NAME defun emitted into
bootstrap/primitives-auto.lisp from a template in src/primitives.scm."
  (let* ((name-str (symbol-name ece-name-sym))
         (name-up (string-upcase name-str))
         (sym (find-symbol (concatenate 'string "ECE-" name-up) :ece)))
    (and sym (fboundp sym) (symbol-function sym))))

(defun init-primitive-dispatch-tables ()
  "Initialize dispatch tables from manifest via convention-based resolution."
  (dolist (entry *manifest-entries*)
    (destructuring-bind (id name arity platform) entry
      (declare (ignore arity))
      (let ((name-sym (intern (string-downcase (symbol-name name)) :ece)))
        ;; Populate name table
        (setf (aref *primitive-name-table* id) name-sym)
        ;; Populate reverse lookup
        (setf (gethash name-sym *primitive-name-to-id*) id)
        ;; Populate dispatch table
        (let ((cl-fn (resolve-cl-primitive name-sym)))
          (cond
            (cl-fn
             (setf (aref *primitive-dispatch-table* id) cl-fn)
             (setf (gethash id *primitive-available-ids*) t))
            ;; ECE-platform and browser-platform primitives don't need CL implementations
            ((member platform '(ece browser))
             (let ((captured-name name-sym)
                   (captured-platform platform))
               (setf (aref *primitive-dispatch-table* id)
                     (lambda (&rest args)
                       (declare (ignore args))
                       (error "Primitive ~A requires ~A platform"
                              captured-name captured-platform)))))
            ;; Core/CL primitive with no implementation — stub for now, validated later
            (t
             (let ((captured-name name-sym))
               (setf (aref *primitive-dispatch-table* id)
                     (lambda (&rest args)
                       (declare (ignore args))
                       (error "Primitive ~A is not implemented" captured-name)))))))))))

(defun validate-primitive-dispatch-tables ()
  "Error if any core/cl primitive is still unresolved after all registrations."
  (let ((missing nil))
    (dolist (entry *manifest-entries*)
      (destructuring-bind (id name arity platform) entry
        (declare (ignore arity))
        (when (and (member platform '(core cl))
                   (not (gethash id *primitive-available-ids*)))
          (push (format nil "~A (id ~D, platform ~A)" name id platform) missing))))
    (when missing
      (error "Boot failed: ~D primitive~:P have no CL implementation:~%~{  ~A~%~}"
             (length missing) (nreverse missing)))))

(defun make-hash-frame (names objects)
  "Build a hash-table frame (:hash-frame . ht) from parallel name/object lists."
  (let ((ht (make-hash-table :test 'eq :size (length names))))
    (loop for name in names
          for obj in objects
          do (setf (gethash name ht) obj))
    (cons :hash-frame ht)))

(defun build-global-env-from-manifest ()
  "Build the initial *global-env* with primitives stored as (primitive <id>)."
  (let ((names nil)
        (objects nil))
    (dolist (entry *manifest-entries*)
      (destructuring-bind (id name arity platform) entry
        (declare (ignore arity))
        ;; Only register primitives that this platform implements
        (when (or (gethash id *primitive-available-ids*)
                  ;; Also register stubs so they error with good messages
                  (member platform '(browser)))
          (let ((name-sym (intern (string-downcase (symbol-name name)) :ece)))
            (push name-sym names)
            (push (list '|primitive| id) objects)))))
    (list (make-hash-frame (nreverse names) (nreverse objects)))))

;; *global-env* initialization deferred until after dispatch tables are built.
;; See init call after platform discovery primitives.

;; EOF sentinel for safe read
(defvar *eof-sentinel* (gensym "EOF"))

;;; Custom readtable for ECE: ` → quasiquote, , → unquote, ,@ → unquote-splicing
;;; I/O primitives with custom wrappers


(defun format-ece-hash-table (obj stream writer)
  "Format a platform hash table as {k1 v1 k2 v2 ...}."
  (write-char #\{ stream)
  (let ((first t))
    (maphash (lambda (key val)
               (unless first (write-char #\Space stream))
               (setf first nil)
               (funcall writer key stream)
               (write-char #\Space stream)
               (funcall writer val stream))
             obj))
  (write-char #\} stream))

(defun ece-output-to-stream (obj stream print-fn)
  "Shared display/write helper. PRINT-FN is #'princ (display) or #'prin1 (write)."
  (cond
    ((scheme-false-p obj) (write-string "#f" stream))
    ((eq obj t) (write-string "#t" stream))
    ((null obj) (write-string "()" stream))
    ((or (compiled-procedure-p obj) (primitive-procedure-p obj))
     (princ (format-ece-proc obj) stream))
    ((hash-table-p obj)
     ;; TODO: self-referential hash tables will cause infinite recursion here
     (format-ece-hash-table obj stream
                            (lambda (v s) (ece-output-to-stream v s print-fn))))
    (t (let ((*print-circle* t)) (funcall print-fn obj stream)))))

(defun ece-display-to-stream (obj stream)
  "Display obj to a specific stream."
  (ece-output-to-stream obj stream #'princ))

(defun ece-write-to-stream (obj stream)
  "Write obj in readable form to a specific stream."
  (ece-output-to-stream obj stream #'prin1))















(defvar *preserve-readtable*
  (let ((rt (copy-readtable nil)))
    (setf (readtable-case rt) :preserve)
    rt)
  "Cached readtable with :preserve case for write-to-string-flat.")


(defun ece-type-tag (x)
  "Return a `#<type-name>` string identifying X's tagged type, or nil if
X is a type (number, string, character, regular symbol, etc.) that
prin1 handles correctly. Used by `ece-print-flat` (the implementation
of `write-to-string-flat`) so flat-serialized output for ECE struct
types matches WAT's `$write-to-string-impl` fallback shape. The
non-flat `write-to-string` host primitive at primitives.scm has its
own catch-all (princ-to-string) and is not affected by this helper."
  (cond
    ((typep x 'code-object) "#<code-object>")
    ((typep x 'ece-error-sentinel) "#<error-sentinel>")
    (t nil)))

(defun ece-print-flat (x s)
  "Recursively print X to S using ECE-readable syntax."
  (cond
    ((scheme-false-p x) (write-string "#f" s))
    ((eq x t) (write-string "#t" s))
    ((null x) (write-string "()" s))
    ((hash-table-p x) (write-string "(%ser/opaque)" s))
    ;; ECE-package symbol whose name starts with #\: — emit bare (no pipes,
    ;; no package prefix). Round-trip via CL read yields a :keyword-package
    ;; symbol, which downcase-ece-symbols normalizes back to :ece-package.
    ((and (symbolp x)
          (not (null x))
          (eq (symbol-package x) (find-package :ece))
          (let ((name (symbol-name x)))
            (and (> (length name) 0)
                 (char= (char name 0) #\:))))
     (write-string (symbol-name x) s))
    ((consp x)
     (write-char #\( s)
     (ece-print-flat (car x) s)
     (loop with cur = (cdr x) while cur do
           (cond
             ((consp cur)
              (write-char #\space s)
              (ece-print-flat (car cur) s)
              (setf cur (cdr cur)))
             (t
              (write-string " . " s)
              (ece-print-flat cur s)
              (setf cur nil))))
     (write-char #\) s))
    (t (let ((tag (ece-type-tag x)))
         (if tag (write-string tag s) (prin1 x s))))))









(defun ece-string-trim (str)
  "Trim whitespace from both ends of a string."
  (string-trim '(#\Space #\Tab #\Newline #\Return) str))

(defun ece-string-split (str &optional (delimiter #\Space))
  "Split a string by a delimiter character, returning a list of substrings."
  (let ((result nil)
        (start 0)
        (len (length str)))
    (loop for i from 0 below len
          when (char= (char str i) delimiter)
          do (push (subseq str start i) result)
          (setf start (1+ i)))
    (push (subseq str start len) result)
    (nreverse result)))

(defun ece-string-contains-p (haystack needle)
  "Test if HAYSTACK contains NEEDLE as a substring."
  (scheme-bool (search needle haystack)))

(defun ece-string-join (lst separator)
  "Join a list of strings with SEPARATOR between them."
  (if (null lst)
      ""
      (reduce (lambda (a b) (concatenate 'string a separator b))
              lst)))

;;; Continuation save/load removed — was using flat-image serialization.
;;; Continuation serialization will be reimplemented when needed (separate concern).

;;; Ports (R7RS-style I/O abstraction)

(defun ece-make-input-port (stream &optional name)
  (list 'input-port stream name 1 0))

(defun ece-make-output-port (stream &optional name)
  (list 'output-port stream name 1 0))




(defun ece-port-stream (port)
  (cadr port))

(defun ece-port-name (port)
  (caddr port))



(defun set-ece-port-line! (port val) (setf (cadddr port) val))
(defun set-ece-port-col!  (port val) (setf (car (cddddr port)) val))

;;; current-input-port / current-output-port are now ECE parameters
;;; (created in prelude.scm via %initial-input-port / %initial-output-port).
;;; Host defvars were removed — the parameter is the sole source of truth.

;;; File and string port constructors








;;; Port-required write primitives (R7RS ports via ECE wrappers)
;;; These require an explicit port argument — no ambient fallback.
;;; The ECE wrappers in prelude.scm supply (current-output-port) when omitted.



;;; Process environment and filesystem — host-only capabilities.
;;; Each is a one-line wrapper; all logic lives in ECE.
















;;; Character I/O primitives






;;; Character predicates

(defun ece-char-whitespace-p (ch)
  (scheme-bool (member ch '(#\Space #\Tab #\Newline #\Return #\Page))))

(defun ece-char-alphabetic-p (ch)
  (scheme-bool (alpha-char-p ch)))

(defun ece-char-numeric-p (ch)
  (scheme-bool (digit-char-p ch)))

;;; Scoped port redirection

;; with-input-from-file / with-output-to-file are now ECE procedures
;; (defined in prelude.scm using parameterize + current-*-port). The ECE
;; wrappers shadow these CL primitives. These CL versions remain as a
;; fallback for callers that invoke primitive 102/103 directly; they bind
;; the host's *standard-input* / *standard-output* streams only.


(defun ece-call-with-input-file (filename proc)
  (let ((port (ece-open-input-file filename)))
    (unwind-protect
         (apply-ece-procedure proc (list port))
      (ece-close-input-port port))))

(defun ece-call-with-output-file (filename proc)
  (let ((port (ece-open-output-file filename)))
    (unwind-protect
         (apply-ece-procedure proc (list port))
      (ece-close-output-port port))))

;;; Compile-time macro table (used by compiler.lisp for macro expansion)
(defvar *compile-time-macros* (make-hash-table :test 'eq)
  "Hash table mapping macro names to compiled transformer procedures.")

;;; Primitive dispatch is now convention-based via resolve-cl-primitive.
;;; No manual wrapper list needed — functions named ece-<name> resolve automatically.

;;; --- CL-internal type predicates and accessors ---
;;; Return CL booleans. Used by executor and dispatch code.
;;; ECE-facing predicates (below) delegate to these.

(defun compiled-procedure-p (proc)
  (and (listp proc) (eq (car proc) '|compiled-procedure|)))

(defun compiled-procedure-entry (proc)
  (cadr proc))

(defun compiled-procedure-env (proc)
  (caddr proc))

(defun primitive-procedure-p (proc)
  (and (listp proc) (eq (car proc) '|primitive|)))

(defun primitive-procedure-id (proc)
  (cadr proc))

(defun continuation-p (cont)
  (and (listp cont) (eq (car cont) '|continuation|)))

(defun continuation-stack (cont)
  (cadr cont))

(defun continuation-conts (cont)
  (caddr cont))

(defun continuation-winds (cont)
  (cadddr cont))

(defun parameter-p (proc)
  "Test if PROC is a parameter object: (parameter (<value> . <converter>))"
  (and (listp proc) (eq (car proc) 'parameter)))

(defun parameter-cell (param)
  (cadr param))

(defun procedure-name (proc)
  "Look up a compiled procedure's name. Names live on the code-object
struct (set at compile time via %code-object-set-name!). Legacy
non-code-object entries have no name — returns NIL."
  (let ((entry (compiled-procedure-entry proc)))
    (cond
      ((code-object-p entry) (code-object-name entry))
      ((and (consp entry) (code-object-p (car entry)))
       (code-object-name (car entry)))
      (t nil))))

;;; --- Type introspection primitives (ECE-facing) ---
;;; Return Scheme booleans. Exposed as ECE primitives.















;; Env-frame introspection (CL frames are vectors for O(1) lexical access)





;; Winding stack sync
(defvar *cl-winding-stack* nil)



;;; --- Boot registration primitives (no-ops on CL) ---
;;; CL runtime already handles primitive registration, assembler symbol setup,
;;; continuation/error symbol caching, and REPL space creation via
;;; init-primitive-dispatch-tables and build-global-env-from-manifest.
;;; These exist so boot-env.ecec can execute without error on CL.







;;; --- Platform discovery primitives ---






;;; Dispatch table initialization and *global-env* are deferred to end of file,
;;; after all wrapper functions are defined (see BOOT section).

;;;; ========================================================================
;;;; INSTRUCTION EXECUTOR (SICP 5.5)
;;;; ========================================================================

;;; Parameter representation — (parameter (<value> . <converter-or-nil>))
;;; The inner cons cell is mutable: set-car! updates the value.

(defun apply-ece-procedure (proc args)
  "Apply an ECE procedure (primitive or compiled) to ARGS."
  (cond
    ((primitive-procedure-p proc) (apply-primitive-procedure proc args))
    ((compiled-procedure-p proc) (execute-compiled-call proc args))
    (t (error "Not a procedure: ~S" proc))))


(defun parameter-ref (param)
  "Read the current value of a parameter."
  (car (parameter-cell param)))

(defun parameter-set! (param new-val)
  "Set a parameter's value, applying converter if present. Returns old value."
  (let* ((cell (parameter-cell param))
         (old (car cell))
         (converter (cdr cell)))
    (setf (car cell)
          (if (and converter (not (null converter))
                   (not (scheme-false-p converter)))
              (apply-ece-procedure converter (list new-val))
              new-val))
    old))

(defun parameter-raw-set! (param new-val)
  "Set a parameter's value without applying converter. Returns old value."
  (let* ((cell (parameter-cell param))
         (old (car cell)))
    (setf (car cell) new-val)
    old))

(defun apply-parameter (param argl)
  "Apply a parameter object: 0 args = get, 1 arg = set with converter, 2 args = raw set."
  (cond
    ((null argl) (parameter-ref param))
    ((null (cdr argl)) (parameter-set! param (car argl)))
    (t (parameter-raw-set! param (car argl)))))

;;; Compiled procedure representation

(defun make-compiled-procedure (entry env)
  (list '|compiled-procedure|
        (cond ((consp entry) entry)
              ;; §7.1: a bare code-object entry IS the closure's entry —
              ;; the body starts at its pc 0 implicitly. No cons wrapper.
              ((code-object-p entry) entry)
              (t (cons *executing-code-obj* entry)))
        env))

;;; Space-qualified address helpers
;;; A qualified address is (space-id . local-pc).
;;; During migration, bare integers are treated as (0 . pc).

(defun qualified-address-p (addr)
  "Test if ADDR is a space-qualified address (cons pair)."
  (consp addr))

(defun qualified-space-id (addr)
  "Extract code-object from a qualified address.
A bare code-object is itself the identity (§7.1/§7.2). A (code-obj . pc)
pair returns the code-obj head."
  (cond ((code-object-p addr) addr)
        ((consp addr) (car addr))
        (t (error "qualified-space-id: expected code-object or (code-obj . pc), got ~S" addr))))

(defun qualified-local-pc (addr)
  "Extract local-pc from a qualified address. A bare code-object is pc 0.
A (code-obj . pc) pair returns the pc."
  (cond ((code-object-p addr) 0)
        ((consp addr) (cdr addr))
        (t (error "qualified-local-pc: expected code-object or (code-obj . pc), got ~S" addr))))

(defun make-qualified-address (space-id local-pc)
  "Create a (code-obj . pc) qualified address."
  (cons space-id local-pc))

;;; Error sentinel — returned by apply-primitive-procedure when CL signals
;;; a type-error or division-by-zero, so the executor can bridge to ECE's raise.
(defstruct ece-error-sentinel message irritants)

(defun apply-primitive-procedure (proc argl)
  ;; Safety check: if a parameter object reaches here (compiled code without
  ;; parameter? branch), handle it directly.
  (when (parameter-p proc)
    (return-from apply-primitive-procedure (apply-parameter proc argl)))
  (let ((id-or-name (primitive-procedure-id proc)))
    (if (symbolp id-or-name)
        ;; Symbol-based dispatch: legacy parameters via *parameter-table*,
        ;; or trace wrappers via symbol-function.
        (let ((param-cell (gethash id-or-name *parameter-table*)))
          (if param-cell
              (cond
                ((null argl) (car param-cell))
                ((null (cdr argl))
                 (let* ((old (car param-cell))
                        (converter (cdr param-cell)))
                   (setf (car param-cell)
                         (if (and converter (not (null converter))
                                  (not (scheme-false-p converter)))
                             (apply-ece-procedure converter argl)
                             (car argl)))
                   old))
                (t (let ((old (car param-cell)))
                     (setf (car param-cell) (car argl))
                     old)))
              (handler-case
                  (apply (symbol-function id-or-name) argl)
                (division-by-zero ()
                  (make-ece-error-sentinel
                   :message (format nil "~(~A~): division by zero" id-or-name)
                   :irritants nil))
                (type-error (e)
                  (make-ece-error-sentinel
                   :message (format nil "~(~A~): ~A" id-or-name e)
                   :irritants (list (type-error-datum e)))))))
        ;; Numeric ID — dispatch via table
        (progn
          (unless (and (integerp id-or-name)
                       (<= 0 id-or-name)
                       (< id-or-name (length *primitive-dispatch-table*)))
            (error "Invalid primitive ID: ~A" id-or-name))
          (let ((fn (aref *primitive-dispatch-table* id-or-name))
                (prim-name (aref *primitive-name-table* id-or-name)))
            (handler-case
                (apply fn argl)
              (division-by-zero ()
                (make-ece-error-sentinel
                 :message (format nil "~(~A~): division by zero" prim-name)
                 :irritants nil))
              (type-error (e)
                (make-ece-error-sentinel
                 :message (format nil "~(~A~): ~A" prim-name e)
                 :irritants (list (type-error-datum e))))))))))

;;; Continuation helpers for compiled code

(defun cl-winding-stack ()
  "Read the ECE *winding-stack* variable. Returns nil during cold boot."
  (ignore-errors
    (lookup-variable-value (intern "*winding-stack*" :ece) *global-env*)))

(defun capture-continuation (stack continue-reg)
  (list '|continuation| (copy-list stack)
        (if (consp continue-reg)
            continue-reg
            (cons *executing-code-obj* continue-reg))
        (or (cl-winding-stack) nil)))

(defun do-continuation-winds (cont)
  "If the continuation's saved winding stack differs from the current one,
call do-winds! to transition. Uses nested execute-compiled-call."
  (let* ((target-winds (continuation-winds cont))
         (current-winds (or (cl-winding-stack) nil)))
    (when (and (not (eq current-winds target-winds))
               (not (and (null current-winds) (null target-winds))))
      (let ((do-winds-fn (lookup-variable-value
                          (intern "do-winds!" :ece) *global-env*)))
        (execute-compiled-call do-winds-fn
                               (list current-winds target-winds))))))

;;; Operations dispatch

;; Safe wrappers for operations that signal CL errors (not ECE raise).
;; These return ece-error-sentinels so the executor can bridge to ECE's error.
(defun safe-lookup-variable-value (var env)
  (handler-case
      (lookup-variable-value var env)
    (error (e)
      (make-ece-error-sentinel
       :message (format nil "Unbound variable: ~A" var)
       :irritants nil))))

(defun safe-lookup-global-variable (var)
  (handler-case
      (lookup-global-variable var)
    (error (e)
      (make-ece-error-sentinel
       :message (format nil "Unbound variable: ~A" var)
       :irritants nil))))

;;; Operations manifest — parallels primitives manifest infrastructure

(defun parse-operations-manifest (filename)
  "Parse operations.def and return a list of (id name arity) entries."
  (unless (probe-file filename)
    (error "Manifest not found: ~A" filename))
  (let ((entries nil))
    (with-open-file (stream filename :direction :input)
      (loop for form = (cl:read stream nil :eof)
            until (eq form :eof)
            when (and (listp form) (>= (length form) 3))
            do (push (list (first form)    ; id
                           (second form)   ; name
                           (third form))   ; arity
                     entries)))
    (let ((result (nreverse entries)))
      (when (null result)
        (error "No entries parsed from ~A" filename))
      result)))

(defparameter *operations-manifest-path*
  (asdf:system-relative-pathname :ece "operations.def"))

(defparameter *operations-manifest-entries*
  (parse-operations-manifest *operations-manifest-path*))

(defparameter *operation-max-id*
  (reduce #'max *operations-manifest-entries* :key #'first))

;; Dispatch table: vector indexed by operation ID → CL function
(defparameter *operation-dispatch-table*
  (make-array (1+ *operation-max-id*) :initial-element nil))

;; Reverse lookup: ECE name symbol → operation ID
(defparameter *operation-name-to-id*
  (make-hash-table :test 'eq))

(defun build-operation-function-map ()
  "Build a hash table mapping ECE operation name symbols to CL functions."
  (let ((ht (make-hash-table :test 'eq)))
    (setf (gethash (intern "lookup-variable-value" :ece) ht) #'safe-lookup-variable-value)
    (setf (gethash (intern "lookup-global-variable" :ece) ht) #'safe-lookup-global-variable)
    (setf (gethash (intern "set-variable-value!" :ece) ht) #'set-variable-value!)
    (setf (gethash (intern "define-variable!" :ece) ht) #'define-variable!)
    (setf (gethash (intern "extend-environment" :ece) ht) #'extend-environment)
    (setf (gethash (intern "lexical-ref" :ece) ht) #'lexical-ref)
    (setf (gethash (intern "lexical-set!" :ece) ht) #'lexical-set!)
    (setf (gethash (intern "make-compiled-procedure" :ece) ht) #'make-compiled-procedure)
    (setf (gethash (intern "compiled-procedure-entry" :ece) ht) #'compiled-procedure-entry)
    (setf (gethash (intern "compiled-procedure-env" :ece) ht) #'compiled-procedure-env)
    (setf (gethash (intern "primitive-procedure?" :ece) ht) #'primitive-procedure-p)
    (setf (gethash (intern "continuation?" :ece) ht) #'continuation-p)
    (setf (gethash (intern "parameter?" :ece) ht) #'parameter-p)
    (setf (gethash (intern "apply-primitive-procedure" :ece) ht) #'apply-primitive-procedure)
    (setf (gethash (intern "apply-parameter" :ece) ht) #'apply-parameter)
    (setf (gethash (intern "parameter-ref" :ece) ht) #'parameter-ref)
    (setf (gethash (intern "parameter-set!" :ece) ht) #'parameter-set!)
    (setf (gethash (intern "parameter-raw-set!" :ece) ht) #'parameter-raw-set!)
    (setf (gethash (intern "capture-continuation" :ece) ht) #'capture-continuation)
    (setf (gethash (intern "do-continuation-winds" :ece) ht) #'do-continuation-winds)
    (setf (gethash (intern "continuation-stack" :ece) ht) #'continuation-stack)
    (setf (gethash (intern "continuation-conts" :ece) ht) #'continuation-conts)
    (setf (gethash (intern "false?" :ece) ht) #'scheme-false-p)
    (setf (gethash (intern "list" :ece) ht) #'list)
    (setf (gethash (intern "cons" :ece) ht) #'cons)
    (setf (gethash (intern "car" :ece) ht) #'car)
    (setf (gethash (intern "cdr" :ece) ht) #'cdr)
    ht))

(defun init-operation-dispatch-tables ()
  "Initialize operation dispatch tables from manifest + function map."
  (let ((op-fns (build-operation-function-map)))
    (dolist (entry *operations-manifest-entries*)
      (destructuring-bind (id name arity) entry
        (declare (ignore arity))
        (let ((name-sym (intern (string-downcase (symbol-name name)) :ece)))
          ;; Populate reverse lookup
          (setf (gethash name-sym *operation-name-to-id*) id)
          ;; Populate dispatch table
          (let ((cl-fn (gethash name-sym op-fns)))
            (if cl-fn
                (setf (aref *operation-dispatch-table* id) cl-fn)
                (warn "Operations manifest entry ~A (id ~D) has no CL implementation"
                      name id))))))))

(defun get-operation-by-id (id)
  "Get the CL function for an operation by numeric ID."
  (aref *operation-dispatch-table* id))

(defun get-operation-id (name)
  "Get the numeric ID for an operation name symbol."
  (or (gethash name *operation-name-to-id*)
      (error "Unknown operation: ~A" name)))

(defun get-operation (name)
  "Get the CL function for a compiled operation name.
Uses the manifest-driven dispatch table via name→ID→function lookup."
  (let ((id (gethash name *operation-name-to-id*)))
    (unless id
      (error "Unknown operation: ~A" name))
    (or (aref *operation-dispatch-table* id)
        (error "Operation ~A (id ~D) has no implementation" name id))))

;;; Instruction executor

(defvar *executing-code-obj* nil
  "The current dispatch target in the executor — a live code-object
struct. Dynamically bound on each executor entry and updated on every
cross-procedure jump. Read by host-primitive templates (e.g. capture-
continuation) that need to qualify PCs against the running code-object.")

(defun execute-instructions (initial-code-obj initial-pc initial-env
                             &key initial-proc initial-argl initial-continue
                               initial-stack)
  "Execute assembled instructions starting at INITIAL-CODE-OBJ / INITIAL-PC.
INITIAL-CODE-OBJ is a code-object (per-procedure identity). Single-loop
executor: cross-dispatch-target jumps update local code-obj/instrs/ltab
variables inline."
  (let* ((code-obj initial-code-obj)
         (instrs (code-object-resolved-instructions initial-code-obj))
         (ltab (code-object-labels initial-code-obj))
         (*executing-code-obj* code-obj)
         (pc initial-pc)
         (flag nil)
         (val nil)
         (env initial-env)
         (proc initial-proc)
         (argl initial-argl)
         (continue initial-continue)
         (stack (or initial-stack '()))
         (len (length instrs))
         ;; Dual-zone hook flag (Stage 1). Set on entry and after every
         ;; switch-code-object. The loop-start tagbody body checks this
         ;; flag, clears it, and dispatches to the registered compiled-zone
         ;; function for the current dispatch target (if any). The flag
         ;; prevents the hook from re-firing every loop iteration, which
         ;; would cause infinite recursion when the compiled zone bails
         ;; to the interpreter from a register-valued goto.
         (just-entered-space t))
    (labels ((get-reg (name)
               (ecase name
                 (|val| val) (|env| env) (|proc| proc) (|argl| argl)
                 (|continue| continue) (|stack| stack)))
             (set-reg (name value)
               (ecase name
                 (|val| (setf val value))
                 (|env| (setf env value))
                 (|proc| (setf proc value))
                 (|argl| (setf argl value))
                 (|continue| (setf continue value))
                 (|stack| (setf stack value))))
             (resolve-label (label)
               (or (gethash label ltab)
                   (error "Unknown label: ~A" label)))
             (switch-code-object (target)
               ;; TARGET is a code-object (per-procedure identity). Updates
               ;; the three executor-local fields (instrs, ltab, len) so the
               ;; dispatch loop doesn't care.
               (setf code-obj target)
               (setf instrs (code-object-resolved-instructions target))
               (setf ltab (code-object-labels target))
               (setf len (length instrs))
               (setf *executing-code-obj* target)
               ;; Mark "we just entered a (potentially compiled) dispatch
               ;; target". The actual hash lookup + dispatch happens in
               ;; loop-start AFTER pc has been updated by the caller (the
               ;; goto instruction's setf pc runs after switch-code-object
               ;; returns).
               (setf just-entered-space t))
             (maybe-dispatch-compiled-zone ()
               ;; Read the native-fn slot off the current code-object.
               ;; When nil, the interpreter keeps running (§6.5).
               (let ((zone-fn (code-object-native-fn code-obj)))
                 (when zone-fn
                   (multiple-value-bind (new-pc new-val new-env new-proc
                                                new-argl new-continue new-stack)
                       (funcall zone-fn pc val env proc argl continue stack)
                     (setf pc new-pc
                           val new-val
                           env new-env
                           proc new-proc
                           argl new-argl
                           continue new-continue
                           stack new-stack)))))
             (eval-operand (operand)
               (ecase (car operand)
                 (|const| (cadr operand))
                 (|reg| (get-reg (cadr operand)))
                 (|label| (resolve-label (cadr operand)))))
             (call-op (fn operands)
               ;; Call operation without allocating an argument list
               (if (null operands) (funcall fn)
                   (let ((a (eval-operand (car operands)))
                         (r (cdr operands)))
                     (if (null r) (funcall fn a)
                         (let ((b (eval-operand (car r)))
                               (r2 (cdr r)))
                           (if (null r2) (funcall fn a b)
                               (let ((c (eval-operand (car r2)))
                                     (r3 (cdr r2)))
                                 (if (null r3) (funcall fn a b c)
                                     (funcall fn a b c (eval-operand (car r3))))))))))))
      (handler-bind
          ((error
            (lambda (e)
              (unless (typep e 'ece-runtime-error)
                (let ((wrapped
                       (ignore-errors
                         (make-condition
                          'ece-runtime-error
                          :original-error e
                          :procedure proc
                          :arguments argl
                          :environment env
                          :instruction (when (< pc len)
                                         (aref instrs pc))
                          :backtrace (extract-ece-backtrace stack)))))
                  (if wrapped
                      (error wrapped)
                      (error e)))))))
        (tagbody
         loop-start
           ;; Dual-zone hook: when just-entered-space is set, the compiled
           ;; zone for the current dispatch target gets one chance to run
           ;; from the current pc. The flag is cleared first so the hook
           ;; doesn't re-fire on subsequent loop iterations (which would
           ;; infinite-loop on register-valued goto bails). This runs
           ;; AFTER pc has been updated by switch-code-object callers, so
           ;; the dispatch lands on the correct PC in the new target's PC space.
           (when just-entered-space
             (setf just-entered-space nil)
             (maybe-dispatch-compiled-zone))
           (when (>= pc len) (go loop-end))
           (let ((instr (aref instrs pc)))
             (case (car instr)
               (|assign|
                (let ((target (cadr instr))
                      (source (caddr instr)))
                  (case (car source)
                    (|const| (set-reg target (cadr source)))
                    (|reg| (set-reg target (get-reg (cadr source))))
                    (|label| (let ((resolved-pc (resolve-label (cadr source))))
                               (set-reg target
                                        (if (eq target '|continue|)
                                            (cons code-obj resolved-pc)
                                            resolved-pc))))
                    (|op-fn|
                     (let ((result (call-op (cadr source) (cdddr instr))))
                       (if (ece-error-sentinel-p result)
                           ;; Bridge CL error to ECE's error function
                           (let ((error-fn (ignore-errors
                                             (lookup-variable-value (intern "error" :ece) *global-env*))))
                             (if (and error-fn (compiled-procedure-p error-fn))
                                 (let* ((err-entry (compiled-procedure-entry error-fn))
                                        (err-space (qualified-space-id err-entry))
                                        (err-pc (qualified-local-pc err-entry)))
                                   (setf proc error-fn)
                                   (setf argl (cons (ece-error-sentinel-message result)
                                                    (ece-error-sentinel-irritants result)))
                                   (unless (eq err-space code-obj)
                                     (switch-code-object err-space))
                                   (setf pc err-pc)
                                   (go loop-start))
                                 ;; Fallback: no error yet (cold boot) — signal CL error
                                 (error "~A" (ece-error-sentinel-message result))))
                           (set-reg target result))))
                    (|op| (set-reg target
                                   (call-op (get-operation (cadr source))
                                            (cdddr instr))))
                    (t (error "Bad assign source: ~A" source)))))
               (|test|
                (let ((op-spec (cadr instr)))
                  (case (car op-spec)
                    (|op-fn| (setf flag (call-op (cadr op-spec) (cddr instr))))
                    (t (setf flag (call-op (get-operation (cadr op-spec))
                                           (cddr instr)))))))
               (|branch|
                (when flag
                  (setf pc (resolve-label (cadr (cadr instr))))
                  (go loop-start)))
               (|goto|
                (let ((dest (cadr instr)))
                  (ecase (car dest)
                    (|label| (setf pc (resolve-label (cadr dest))))
                    (|reg| (let ((addr (get-reg (cadr dest))))
                             (cond
                               ;; §7.1/§7.2: bare code-object is an entry
                               ;; at its pc 0. Switch if it's not the
                               ;; currently-executing code-object.
                               ((code-object-p addr)
                                (unless (eq addr code-obj)
                                  (switch-code-object addr))
                                (setf pc 0))
                               ;; Cross-target qualified address
                               ;; (code-obj . local-pc) — §7.3 continuations.
                               ((and (consp addr) (not (eq (car addr) code-obj)))
                                (switch-code-object (car addr))
                                (setf pc (cdr addr)))
                               ;; Same-target qualified address
                               ((consp addr) (setf pc (cdr addr)))
                               ;; Bare integer (same-target relative pc)
                               ((numberp addr) (setf pc addr))
                               ;; Symbol label
                               (t (setf pc (resolve-label addr)))))))
                  (go loop-start)))
               (|save|
                (push (get-reg (cadr instr)) stack))
               (|restore|
                (set-reg (cadr instr) (pop stack)))
               (|perform|
                (let ((op-spec (cadr instr)))
                  (case (car op-spec)
                    (|op-fn| (call-op (cadr op-spec) (cddr instr)))
                    (t (call-op (get-operation (cadr op-spec)) (cddr instr))))))
               (|halt| (go loop-end))
               (t (error "Unknown instruction: ~A" instr))))
           (incf pc)
           (go loop-start)
         loop-end))
      val)))

;;; *procedure-name-table* and *procedure-params-table* retired in
;;; per-procedure-code-objects §11.2. Names and parameter metadata now
;;; live on the code-object struct (code-object-name / code-object-arity).

(defvar *traced-procedures*
  (make-hash-table :test 'eq)
  "Maps symbol names to their original procedure values when traced.")

(defvar *trace-depth* 0
  "Current nesting depth for trace output indentation.")

;;; ============================================================
;;; Code Objects (per-procedure compilation unit)
;;; ============================================================
;;; A code-object is the per-procedure output of the compiler: the
;;; source and resolved instruction vectors for one procedure body,
;;; its own label table, and metadata. Entry/continuation addresses
;;; become (code-object . local-pc) pairs.
;;;
;;; Replaces the `compilation-space` / `*space-registry*` /
;;; `*current-space-id*` / `create-space` / `get-space` /
;;; `assemble-into-space` infrastructure that retired in Phase F of
;;; the per-procedure-code-objects change.

(defstruct code-object
  "A code object — the compilation unit for a single procedure or top-level form."
  (source-instructions (make-array 32 :adjustable t :fill-pointer 0)
                       :type vector)
  (resolved-instructions (make-array 32 :adjustable t :fill-pointer 0)
                         :type vector)
  (labels (make-hash-table :test 'eq)
    :type hash-table)
  (name nil)
  (arity nil)
  (source-loc nil)
  (native-fn nil)
  (archive-key nil))

(defmethod print-object ((obj code-object) stream)
  (print-unreadable-object (obj stream :type nil :identity t)
    (format stream "code-object ~A len=~D"
            (or (code-object-name obj) "<anon>")
            (length (code-object-source-instructions obj)))))











;;; Compiled zone support (compile-to-host, Stage 1+)
;;;
;;; Dual-zone runtime: ECE programs run in either the dynamic zone (the
;;; instruction-vector interpreter in execute-instructions) or the compiled
;;; zone (a per-space CL function emitted by src/codegen-cl-inline.scm whose
;;; body is the inlined translation of that space's instructions).
;;;
;;; Both zones share the same registers, stack, environment, primitive defuns,
;;; and *global-env* lookup path. A continuation captured in one zone can be
;;; resumed in the other — call/cc, dynamic-wind, and REPL function
;;; redefinition all work across the boundary without any special handling.
;;;
;;; *compiled-zone-functions* is the registry: when execute-instructions
;;; enters a space whose symbol ID is a key, it hands control to the
;;; registered CL function instead of running the dispatch loop for that
;;; space. See src/codegen-cl-inline.scm for the codegen and calling
;;; convention.

(defvar *compiled-zone-functions* (make-hash-table :test 'eq)
  "Registry mapping space-id symbols to compiled-zone CL functions.
Each entry is a function of (initial-pc initial-val initial-env initial-proc
initial-argl initial-continue initial-stack) returning
(values pc val env proc argl continue stack) on zone exit. Populated by
.tmp/bootstrap-zones/ generated shard files at load time. Spaces without a
registered entry fall through to the interpreted dispatch loop unchanged.")

(defvar *archive-zone-fns* (make-hash-table :test #'equal)
  "Registry mapping (unit-id . co-key) keys to compiled-zone CL
functions for per-code-object zones. Current file archives synthesize
UNIT-ID from the archive's |file| field minus its extension; future module
archives can provide explicit unit identity. CO-KEY is the zero-based index
within the archive. Populated by the generated CL native-zone shards at load
time; archive loaders consult this to attach code-object-native-fn.

Distinct from *compiled-zone-functions* (symbol-keyed on space-id, still
used by the legacy space path during Phase C coexistence).")

(defvar *archive-code-objects* (make-hash-table :test #'equal)
  "Registry mapping (unit-id . co-key) keys to the live code-object
struct materialized by the archive loader. Same keying convention as
*archive-zone-fns*. Used by emitted zone code at execution time to
resolve (const <code-object>) operands for inner-lambda references —
the zone-file is emitted for one specific archive, so the unit id is
a constant in the emitted form and the co-key identifies the target.")

(defvar *native-zone-registry* (make-hash-table :test #'equal)
  "Registry mapping (normalized-unit-key . co-index) to native-zone export
references. The browser runtime stores opaque host refs here; the CL runtime
keeps the same shape for cross-runtime policy tests.")

(defstruct archive-unit
  "Materialized archive section plus normalized module-ready metadata."
  unit-id
  kind
  phase
  imports
  exports
  init-index
  cos
  state
  env
  result
  instance)

(defstruct module-instance
  "Instantiated module value namespace."
  unit-id
  env
  exports
  result)

(defvar *archive-units* (make-hash-table :test #'equal)
  "Registry of materialized archive units keyed by normalized unit-id.")

(defvar *module-instances* (make-hash-table :test #'equal)
  "Registry of initialized module instances keyed by normalized unit-id.")

(defun archive-co-lookup (unit-id co-key)
  "Resolve a (unit-id . co-key) pair to the live code-object struct in
*archive-code-objects*. Called from emitted zone code to dereference
nested-lambda constants at zone-execution time. Signals ECE-runtime-error
if the key is unregistered — that indicates either a stale zone file
(archive re-generated but zone not regenerated) or a mis-threaded
co-key at codegen time."
  (or (gethash (cons unit-id co-key) *archive-code-objects*)
      (error 'ece-runtime-error
             :procedure nil
             :arguments nil
             :environment *global-env*
             :instruction nil
             :backtrace nil
             :original-error
             (make-condition 'simple-error
                             :format-control "archive-co-lookup: no code-object registered for (~A . ~A). Zone file may be stale; run `make bootstrap`."
                             :format-arguments (list unit-id co-key)))))


(defun resolve-operations (instr)
  "Pre-resolve operation names to function pointers in an instruction."
  (case (car instr)
    (|assign|
     (let ((source (caddr instr)))
       (if (and (consp source) (eq (car source) '|op|))
           `(|assign| ,(cadr instr) (|op-fn| ,(get-operation (cadr source)))
                      ,@(cdddr instr))
           instr)))
    (|test|
     (let ((op-spec (cadr instr)))
       `(|test| (|op-fn| ,(get-operation (cadr op-spec))) ,@(cddr instr))))
    (|perform|
     (let ((op-spec (cadr instr)))
       `(|perform| (|op-fn| ,(get-operation (cadr op-spec))) ,@(cddr instr))))
    (t instr)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Archive-format parser (CL-side, mirrors archive-sexp->code-objects
;;; in src/compilation-unit.scm). Needed at boot because bootstrap.ecec
;;; is read by load-ecec-section BEFORE ECE prelude is loaded, so the
;;; ECE-side parser isn't available yet.
;;; ─────────────────────────────────────────────────────────────────────────

(defun archive-plist-get (plist key)
  "Walk a keyword-keyed archive plist, return value after KEY or NIL.
During the keyword-format transition this also matches a plain-symbol
key whose name is KEY minus the leading colon, so old-format
bootstrap.ecec files continue to load while new-format files become the
norm. Can be simplified to a strict eq match once every on-disk .ecec
is in the keyword format."
  (cond
    ((null plist) nil)
    ((null (cdr plist)) nil)
    ((eq (car plist) key) (cadr plist))
    ;; Transition fallback: match plain-symbol form of KEY (e.g., |version|
    ;; when KEY is :ece ":version"). Only fires when KEY starts with #\:.
    ((and (symbolp (car plist))
          (let ((kn (symbol-name key))
                (pn (symbol-name (car plist))))
            (and (> (length kn) 0)
                 (char= (char kn 0) #\:)
                 (string= pn (subseq kn 1)))))
     (cadr plist))
    (t (archive-plist-get (cddr plist) key))))

(defun archive-plist-has-key-p (plist key)
  "Return true when PLIST contains KEY, using the same legacy key matching as
archive-plist-get. This distinguishes an absent field from an explicit NIL
value for metadata such as :exports."
  (cond
    ((null plist) nil)
    ((null (cdr plist)) nil)
    ((eq (car plist) key) t)
    ((and (symbolp (car plist))
          (let ((kn (symbol-name key))
                (pn (symbol-name (car plist))))
            (and (> (length kn) 0)
                 (char= (char kn 0) #\:)
                 (string= pn (subseq kn 1)))))
     t)
    (t (archive-plist-has-key-p (cddr plist) key))))

(defun archive-patch-co-refs (tree cos-vec)
  "Replace every (const (co-ref N)) in TREE with (const <code-object-at-N>)."
  (cond
    ((null tree) nil)
    ((not (consp tree)) tree)
    ((and (eq (car tree) '|const|)
          (consp (cdr tree))
          (consp (cadr tree))
          (eq (car (cadr tree)) '|co-ref|))
     (list '|const| (aref cos-vec (cadr (cadr tree)))))
    (t (cons (archive-patch-co-refs (car tree) cos-vec)
             (archive-patch-co-refs (cdr tree) cos-vec)))))

(defun parse-archive-sexp (archive)
  "Parse a read archive s-expr into a simple-vector of code-object structs.
The shape matches the ECE-side archive-sexp->code-objects output: entries
hold the init code-object plus nested hoisted code-objects. Signals an
ece-runtime-error on version mismatch."
  (let* ((unit (archive-unit-metadata archive))
         (version (archive-plist-get (cdr archive) (intern ":version" :ece)))
         (entries (archive-plist-get unit (intern ":entries" :ece))))
    (unless (eql version 2)
      (error 'ece-runtime-error
             :procedure nil
             :arguments nil
             :environment *global-env*
             :instruction nil
             :backtrace nil
             :original-error
             (make-condition 'simple-error
                             :format-control "Unsupported .ecec archive version: ~A. Run `make bootstrap` to regenerate."
                             :format-arguments (list (or version "missing")))))
    (let* ((entries-vec (coerce entries 'simple-vector))
           (n (length entries-vec))
           (cos (make-array n)))
      ;; Pass 1: create code-objects, set metadata + labels.
      (dotimes (i n)
        (let* ((entry (aref entries-vec i))
               (fields (cdr entry))
               (co (make-code-object)))
          (let ((name (archive-plist-get fields (intern ":name" :ece))))
            (when name (setf (code-object-name co) name)))
          (let ((arity (archive-plist-get fields (intern ":arity" :ece))))
            (when arity (setf (code-object-arity co) arity)))
          (let ((src-loc (archive-plist-get fields (intern ":source-loc" :ece))))
            (when src-loc (setf (code-object-source-loc co) src-loc)))
          (dolist (pair (archive-plist-get fields (intern ":labels" :ece)))
            (setf (gethash (car pair) (code-object-labels co)) (cdr pair)))
          (setf (aref cos i) co)))
      ;; Pass 2: push instructions (with (co-ref N) patched to code-objects).
      (dotimes (i n)
        (let* ((entry (aref entries-vec i))
               (co (aref cos i))
               (raw-instrs (archive-plist-get (cdr entry) (intern ":instructions" :ece))))
          (dolist (instr raw-instrs)
            (let ((patched (archive-patch-co-refs instr cos)))
              (vector-push-extend patched (code-object-source-instructions co))
              (vector-push-extend (resolve-operations patched)
                                  (code-object-resolved-instructions co))))))
      cos)))

;;; assemble-into-space / assemble-into-global retired in Phase F
;;; alongside compilation-space and *space-registry*. Callers go through
;;; assemble-into-code-object (defined in src/assembler.scm) with a fresh
;;; code-object per compilation unit.













;;; User-facing hash table primitives (platform-native, core IDs 141-149)
;;; These back the ECE-level hash-table API on all hosts.









;;; Hash-table frame primitives (for compaction.scm)





;;; Metacircular compiler support primitives




(defun execute-compiled-call (compiled-proc args)
  "Call a compiled procedure with ARGS.
Sets up proc and argl registers so the compiled code's entry point can
extract its environment and extend it with arguments.
Sets continue to a past-end address so (goto (reg continue)) exits cleanly."
  (let* ((entry (compiled-procedure-entry compiled-proc))
         (code-obj (qualified-space-id entry))
         (local-pc (qualified-local-pc entry))
         (return-pc (length (code-object-resolved-instructions code-obj))))
    (execute-instructions code-obj local-pc *global-env*
                          :initial-proc compiled-proc
                          :initial-argl args
                          :initial-continue (cons code-obj return-pc))))




;;; Symbol-keyed dispatch table used by apply-primitive-procedure for
;;; legacy (primitive SYMNAME) forms. Kept empty — no new entries are
;;; created, but the lookup path in apply-primitive-procedure still
;;; references it.
(defvar *parameter-table* (make-hash-table :test 'eq))

(defun mc-eval (expr &optional (env nil env-supplied-p))
  "Evaluate EXPR using the metacircular compiler from the global env.
Works with image-only startup (no compiler.lisp needed).
When ENV is supplied, it is passed to mc-compile-and-go."
  (let ((mc-cag (lookup-variable-value (intern "mc-compile-and-go" :ece) *global-env*)))
    (if env-supplied-p
        (execute-compiled-call mc-cag (list expr env))
        (execute-compiled-call mc-cag (list expr)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Dev-tooling helpers (TCP sockets + filesystem watch)
;;;
;;; CL-only support code for the `ece serve` dev server. Wraps usocket and
;;; provides a simple polling file watcher. The corresponding ECE-level
;;; primitives are declared in src/primitives.scm and entered in the manifest
;;; at primitives.def ids 229-236. These helpers are not portable to WASM
;;; and exist solely so the ece-serve change can drive sockets and file
;;; watching from ECE code.
;;; ─────────────────────────────────────────────────────────────────────────

(defun ece-tcp-recv-nowait-impl (conn max-bytes)
  "Try to read up to MAX-BYTES from CONN without blocking.
Returns a list of byte integers, the ECE symbol would-block if no data is
currently available and the connection is still open, or the ECE symbol eof
if the peer has closed the connection. Both sentinels are interned in the
:ece package so ECE `eq?` against the literal symbols `'would-block` and
`'eof` works as expected."
  ;; Guard against MAX-BYTES <= 0 — the caller asked for zero (or nonsense)
  ;; bytes; honour that by returning an empty list without consuming any
  ;; input. Otherwise usocket:wait-for-input reports the socket ready when
  ;; EITHER data is pending OR the peer has closed. We then attempt to read
  ;; one byte: nil means EOF, otherwise pull the rest of the buffered run
  ;; via (listen ...) so we don't block waiting for additional data.
  (cond
    ((<= max-bytes 0) nil)
    ((not (usocket:wait-for-input conn :timeout 0 :ready-only t))
     (intern "would-block" :ece))
    (t
     (let* ((stream (usocket:socket-stream conn))
            (first-byte (read-byte stream nil nil)))
       (cond
         ((null first-byte) (intern "eof" :ece))
         (t
          (let ((bytes (list first-byte))
                (count 1))
            (loop while (and (< count max-bytes) (listen stream))
                  do (let ((b (read-byte stream nil nil)))
                       (cond
                         ((null b) (loop-finish))
                         (t (push b bytes) (incf count)))))
            (nreverse bytes))))))))

(defun ece-tcp-send-nowait-impl (conn bytes)
  "Write BYTES (a list of integers in [0, 255]) to CONN. Returns the number
of bytes written. Pragmatically blocking on the underlying TCP buffer — the
:would-block return value is reserved for a future enhancement once usocket
exposes non-blocking write semantics cleanly."
  (let* ((stream (usocket:socket-stream conn))
         (vec (make-array (length bytes) :element-type '(unsigned-byte 8))))
    (loop for b in bytes
          for i from 0
          do (setf (aref vec i) b))
    (write-sequence vec stream)
    (force-output stream)
    (length bytes)))

(defvar *fs-watchers* (make-hash-table :test 'eql)
  "Map watcher-id → hash-table of (path → last-known mtime).")

(defvar *fs-watcher-counter* 0
  "Monotonic counter for fresh watcher ids.")

(defun ece-fs-watch-start-impl (paths)
  "Begin watching PATHS (a list of file path strings). Returns a watcher id
suitable for ece-fs-watch-poll-impl / ece-fs-watch-stop-impl."
  (let ((id (incf *fs-watcher-counter*))
        (table (make-hash-table :test 'equal)))
    (dolist (path paths)
      (setf (gethash path table) (or (file-write-date path) 0)))
    (setf (gethash id *fs-watchers*) table)
    id))

(defun ece-fs-watch-poll-impl (watcher)
  "Return list of paths whose mtime changed since the previous poll for
WATCHER. Updates the stored mtimes as a side effect. Unknown watchers
return an empty list."
  (let ((table (gethash watcher *fs-watchers*)))
    (cond
      ((null table) nil)
      (t
       (let ((changed nil))
         (maphash (lambda (path stored-mtime)
                    (let ((current (or (file-write-date path) 0)))
                      (when (/= current stored-mtime)
                        (setf (gethash path table) current)
                        (push path changed))))
                  table)
         (nreverse changed))))))

(defun ece-fs-watch-stop-impl (watcher)
  "Forget WATCHER. Subsequent polls return an empty list."
  (remhash watcher *fs-watchers*)
  nil)

(defun ece-wasm-as-impl (wat-path wasm-path)
  "Assemble WAT-PATH to WASM-PATH using the host wasm-as tool.
Returns T on success and Scheme #f on failure so Scheme callers can raise an
ECE-level error instead of letting a CL condition escape the executor."
  (handler-case
      (progn
        (uiop:run-program
         (list "wasm-as"
               "--enable-gc"
               "--enable-reference-types"
               wat-path
               "-o"
               wasm-path)
         :output *standard-output*
         :error-output *error-output*)
        t)
    (error (e)
      (format *error-output*
              "wasm-as failed for ~A -> ~A: ~A~%"
              wat-path
              wasm-path
              e)
      (finish-output *error-output*)
      *scheme-false*)))

;;; Load auto-generated primitive defuns. The file contains one (defun ece-NAME ...)
;;; per core/cl primitive in primitives.def. It is regenerated from
;;; src/primitives.scm via `make bootstrap` and committed under bootstrap/.
;;;
;;; Stage 0 of the self-hosting roadmap (see proposal: emit-host-primitives).
;;; The handwritten ece-NAME defuns previously in this file have been deleted —
;;; templates in src/primitives.scm are the source of truth.
(let ((primitives-auto-path
       (asdf:system-relative-pathname :ece "bootstrap/primitives-auto.lisp")))
  (unless (probe-file primitives-auto-path)
    (error "Missing generated bootstrap file ~A.~%~
            Run `make bootstrap` (or `make bootstrap/primitives-auto.lisp`) ~
            to regenerate it from src/primitives.scm."
           primitives-auto-path))
  (handler-case (load primitives-auto-path)
    (error (e)
      (error "Failed to load generated bootstrap file ~A: ~A~%~
              The file may be corrupt — try `make bootstrap` to regenerate, ~
              or `git checkout bootstrap/primitives-auto.lisp` to restore."
             primitives-auto-path e))))

;;; Fallback defuns for primitives added to primitives.def after the current
;;; bootstrap/primitives-auto.lisp was generated. Defined here so boot can
;;; complete even with a stale bootstrap file; `make bootstrap` regenerates
;;; primitives-auto.lisp with the canonical codegen.
(unless (and (find-symbol "ECE-CODE-OBJECT-ARCHIVE-KEY" :ece)
             (fboundp (find-symbol "ECE-CODE-OBJECT-ARCHIVE-KEY" :ece)))
  (eval `(defun ,(intern "ECE-CODE-OBJECT-ARCHIVE-KEY" :ece) (co)
           (or (code-object-archive-key co) *scheme-false*))))
(unless (and (find-symbol "ECE-%CODE-OBJECT-SET-ARCHIVE-KEY!" :ece)
             (fboundp (find-symbol "ECE-%CODE-OBJECT-SET-ARCHIVE-KEY!" :ece)))
  (eval `(defun ,(intern "ECE-%CODE-OBJECT-SET-ARCHIVE-KEY!" :ece) (co key)
           (progn (setf (code-object-archive-key co)
                        (if (eq key *scheme-false*) nil key))
                  nil))))
(unless (and (find-symbol "ECE-%ARCHIVE-CO-LOOKUP" :ece)
             (fboundp (find-symbol "ECE-%ARCHIVE-CO-LOOKUP" :ece)))
  (eval `(defun ,(intern "ECE-%ARCHIVE-CO-LOOKUP" :ece) (unit-id index)
           (or (gethash (cons unit-id index) *archive-code-objects*)
               *scheme-false*))))
(unless (and (find-symbol "ECE-%NATIVE-ZONE-REGISTER!" :ece)
             (fboundp (find-symbol "ECE-%NATIVE-ZONE-REGISTER!" :ece)))
  (eval `(defun ,(intern "ECE-%NATIVE-ZONE-REGISTER!" :ece) (unit-key index export-ref)
           (progn
             (setf (gethash (cons unit-key index) *native-zone-registry*)
                   export-ref)
             export-ref))))
(unless (and (find-symbol "ECE-%NATIVE-ZONE-LOOKUP" :ece)
             (fboundp (find-symbol "ECE-%NATIVE-ZONE-LOOKUP" :ece)))
  (eval `(defun ,(intern "ECE-%NATIVE-ZONE-LOOKUP" :ece) (unit-key index)
           (or (gethash (cons unit-key index) *native-zone-registry*)
               *scheme-false*))))
(unless (and (find-symbol "ECE-WASM-AS" :ece)
             (fboundp (find-symbol "ECE-WASM-AS" :ece)))
  (eval `(defun ,(intern "ECE-WASM-AS" :ece) (wat-path wasm-path)
           (ece-wasm-as-impl wat-path wasm-path))))

;;; Now that all primitives and wrapper functions are defined, initialize
;;; the dispatch tables from the manifest, then build *global-env*.
(init-primitive-dispatch-tables)
(init-operation-dispatch-tables)
(defparameter *global-env* (build-global-env-from-manifest))

;;;; ========================================================================
;;;; BOOT — Load bootstrap from .ecec files
;;;; ========================================================================

(defun canonicalize-ecec-constants (form)
  "Walk FORM and replace deserialized #S(SCHEME-FALSE) structs with the
canonical *scheme-false* singleton. Needed because CL's reader creates fresh
struct instances that are not EQ to *scheme-false*.
Iterative on the cdr spine so very long lists don't overflow the stack."
  (cond
    ((scheme-false-p form) *scheme-false*)
    ((consp form)
     ;; Walk the cdr spine iteratively; recurse only on cars.
     (let* ((head (cons nil nil))
            (tail head)
            (cur form))
       (loop while (consp cur) do
             (let ((new-cell (cons (canonicalize-ecec-constants (car cur)) nil)))
               (setf (cdr tail) new-cell
                     tail new-cell
                     cur (cdr cur))))
       (setf (cdr tail) (canonicalize-ecec-constants cur))
       (cdr head)))
    (t form)))

(defun downcase-ece-symbols (form)
  "Walk FORM and downcase symbols for case-sensitive transition.
Handles old .ecec files that have uppercase symbols from the legacy reader.
Downcases both ECE-package and CL-package symbols into the ECE package
(since old reader resolved names like LIST, CAR as CL symbols via inheritance).
Preserves T, NIL, and symbols from other packages.
Iterative on the cdr spine so very long lists don't overflow the stack."
  (cond
    ((null form) form)
    ((eq form t) form)
    ((symbolp form)
     (let ((pkg (symbol-package form)))
       (cond
         ;; CL keyword-package symbols (result of CL:READ-ing bare :foo
         ;; tokens in the new keyword archive format). Convert to
         ;; :ece-package symbol named ":foo" — matches what the ECE
         ;; reader produces for :foo source tokens.
         ((eq pkg (find-package :keyword))
          (intern (format nil ":~A" (string-downcase (symbol-name form)))
                  :ece))
         ((or (null pkg)
              (and (not (eq pkg (find-package :ece)))
                   (not (eq pkg (find-package :cl)))))
          form)
         (t (intern (string-downcase (symbol-name form)) :ece)))))
    ((consp form)
     (let* ((head (cons nil nil))
            (tail head)
            (cur form))
       (loop while (consp cur) do
             (let ((new-cell (cons (downcase-ece-symbols (car cur)) nil)))
               (setf (cdr tail) new-cell
                     tail new-cell
                     cur (cdr cur))))
       (setf (cdr tail) (downcase-ece-symbols cur))
       (cdr head)))
    (t form)))

;;; Source-map table: space-name → hash-table of pc → (file line col)
(defvar *ece-source-maps* (make-hash-table :test 'eq))

(defun register-ecec-source-map (space-sym source-map-field)
  "Register source-map entries from an ecec-header. SOURCE-MAP-FIELD is
the downcased (source-map filename (pc line col) ...) cdr."
  (when source-map-field
    (let ((filename (car source-map-field))
          (ht (make-hash-table :test 'eql)))
      (dolist (entry (cdr source-map-field))
        (when (consp entry)
          (setf (gethash (car entry) ht)
                (list filename (cadr entry) (caddr entry)))))
      (setf (gethash space-sym *ece-source-maps*) ht))))

(defun resolve-ece-source-location (space-sym pc)
  "Look up PC in source-map for SPACE-SYM. Returns (file line col) or NIL."
  (let ((space-map (gethash space-sym *ece-source-maps*)))
    (when space-map
      (gethash pc space-map))))

(defvar *ecec-readtable*
  (let ((rt (copy-readtable nil)))
    (set-dispatch-macro-character #\# #\f
                                  (lambda (stream subchar arg)
                                    (declare (ignore stream subchar arg))
                                    *scheme-false*)
                                  rt)
    (set-dispatch-macro-character #\# #\t
                                  (lambda (stream subchar arg)
                                    (declare (ignore stream subchar arg))
                                    t)
                                  rt)
    rt)
  "Custom CL readtable that understands #f, #t (plus default #S, etc.)
so load-ecec-file can read both old and new serialization formats.")

(defun ecec-archive-form-p (value)
  (and (consp value)
       (symbolp (car value))
       (let ((n (symbol-name (car value))))
         ;; Accept both the new keyword head (:ecec-archive) and the legacy
         ;; plain-symbol head (ecec-archive) so older generated test fixtures
         ;; can still be diagnosed by the version gate.
         (or (string-equal n ":ecec-archive")
             (string-equal n "ecec-archive")))))

(defun read-ecec-archive-form (stream)
  "Read one archive form from STREAM, returning :EOF at end of file."
  (let* ((*package* (find-package :ece))
         (*readtable* *ecec-readtable*)
         (raw-head (cl:read stream nil :eof)))
    (when (eq raw-head :eof) (return-from read-ecec-archive-form :eof))
    (unless (ecec-archive-form-p raw-head)
      (error 'ece-runtime-error
             :procedure nil :arguments nil :environment *global-env*
             :instruction nil :backtrace nil
             :original-error
             (make-condition 'simple-error
                             :format-control "read-ecec-archive-form: expected (:ecec-archive ...), got ~A. Run `make bootstrap` to regenerate."
                             :format-arguments (list (if (consp raw-head) (car raw-head) raw-head)))))
    raw-head))

(defun ecec-archive-skipped-p (raw-archive skip)
  (when skip
    (let* ((archive (downcase-ece-symbols raw-archive))
           (file (archive-plist-get (cdr archive) (intern ":file" :ece))))
      (and file (member file skip :test #'string=)))))

(defun load-ecec-section (stream &key skip)
  "Load one ecec archive section from STREAM. Expects (ecec-archive ...).
SKIP is retained for Makefile API compat (skips sections whose archive
|file| field matches) but is rarely used. Returns T while the stream
has more sections (including skipped ones), NIL on EOF. Legacy
(ecec-header ...) files were retired in §9.3 — if one is encountered,
signals an error pointing at `make bootstrap` for regeneration."
  (let ((raw-head (read-ecec-archive-form stream)))
    (when (eq raw-head :eof) (return-from load-ecec-section nil))
    (when skip
      (when (ecec-archive-skipped-p raw-head skip)
        (return-from load-ecec-section t)))
    (load-ecec-archive-section raw-head)
    t))

(defun materialize-ecec-archive-section (raw-archive)
  "Parse RAW-ARCHIVE into a materialized archive section descriptor."
  (let* ((archive (downcase-ece-symbols
                   (canonicalize-ecec-constants raw-archive)))
         (cos (parse-archive-sexp archive))
         (unit (archive-unit-metadata archive))
         (unit-id (archive-plist-get unit (intern ":unit-id" :ece))))
    (when unit-id
      (register-archive-code-objects cos unit-id)
      (attach-archive-native-fns cos unit-id))
    (list :archive archive :unit unit :cos cos)))

(defun ensure-archive-unit-registered (unit cos)
  "Return UNIT's existing archive-unit record, or register it when absent."
  (let* ((unit-id (archive-unit-field unit ":unit-id"))
         (existing (gethash unit-id *archive-units*)))
    (or existing (register-archive-unit unit cos))))

(defun register-bundle-archive-section (section)
  "Register SECTION's unit for bundle-wide module graph resolution.
Module duplicate unit ids stay hard errors. File units are recorded when
absent so module-shaped imports of non-module units fail as non-module imports
rather than missing imports."
  (let* ((unit (getf section :unit))
         (cos (getf section :cos))
         (unit-id (archive-unit-field unit ":unit-id")))
    (if (module-kind-p (archive-unit-field unit ":kind"))
        (register-archive-unit unit cos)
        (unless (gethash unit-id *archive-units*)
          (setf (gethash unit-id *archive-units*)
                (make-archive-unit
                 :unit-id unit-id
                 :kind (archive-unit-field unit ":kind")
                 :phase (archive-unit-field unit ":phase")
                 :imports (archive-unit-field unit ":imports")
                 :exports (archive-unit-field unit ":exports")
                 :init-index (archive-validated-init-index unit cos)
                 :cos cos
                 :state :registered))))))

(defun load-materialized-ecec-archive-section (section &key bundle-registered)
  "Execute or instantiate SECTION. BUNDLE-REGISTERED means module records were
already created during bundle discovery."
  (let* ((unit (getf section :unit))
         (cos (getf section :cos))
         (kind (archive-unit-field unit ":kind")))
    (cond
      ((module-kind-p kind)
       (module-instance-result
        (instantiate-module-unit
         (if bundle-registered
             (ensure-archive-unit-registered unit cos)
             (register-archive-unit unit cos)))))
      (t
       (let ((init (aref cos (archive-validated-init-index unit cos))))
         (execute-instructions init 0 *global-env*))))))

(defun load-ecec-archive-section (raw-archive)
  "Archive-format dispatch: parse the archive, register each code-object
in *archive-code-objects*, attach any pre-loaded zone fn to native-fn,
then execute the init code-object.

RAW-ARCHIVE is the form as produced by CL:READ — this handler owns its
own downcasing + constant canonicalization so the dispatcher never walks
the tree.

Registration key convention (shared with codegen-cl-inline.scm
emit-zone-registration-for-co):
  key = (cons UNIT-ID CO-KEY)
  UNIT-ID = explicit archive unit identity, synthesized from |file| for
            current file archives
  CO-KEY  = the zero-based index

After the init runs, nested code-objects remain reachable via the
closures the init builds — *archive-code-objects* is only consulted by
emitted zone code at execution time (to resolve (const <inner-co>)
operands), not for general reachability.

Missing zone fn => native-fn left NIL. The executor's
maybe-dispatch-compiled-zone checks the slot and falls through to the
interpreter when it's NIL, so code-objects with no registered zone run
interpreted. This is the Phase C / Phase D transitional state: once
Phase D flips compile-system to archive format and the zone-file load
order is corrected, every reachable code-object gets a zone fn here."
  (load-materialized-ecec-archive-section
   (materialize-ecec-archive-section raw-archive)))

(defun archive-file-stem-symbol (archive)
  "Derive the :ece-package file-stem symbol for ARCHIVE's |file| field,
stripping any extension. Returns NIL when the archive has no |file|
field (shouldn't happen for well-formed archives, but we degrade
gracefully — callers skip registration rather than erroring)."
  (let ((file-str (archive-plist-get (cdr archive) (intern ":file" :ece))))
    (when (stringp file-str)
      (let ((dot (position #\. file-str :from-end t)))
        (intern (if dot (subseq file-str 0 dot) file-str) :ece)))))

(defun archive-unit-id (archive)
  "Return ARCHIVE's semantic unit identity.

Current version-2 file archives do not carry explicit unit metadata, so this
falls back to the historic file-stem symbol. Future module archives can provide
:unit-id directly without changing code-object registry mechanics. String unit
ids are treated as legacy file stems and normalized to ECE symbols."
  (let ((unit-id (archive-plist-get (cdr archive) (intern ":unit-id" :ece))))
    (cond
      ((stringp unit-id) (intern unit-id :ece))
      (unit-id unit-id)
      (t (archive-file-stem-symbol archive)))))

(defun archive-unit-metadata (archive)
  "Return normalized archive-unit metadata for ARCHIVE as an ECE-keyed plist.
Current file archives default to historic global loading semantics. Explicit
module-shaped archives can already carry kind, unit-id, phase, imports,
exports, and init metadata; enforcement happens in the later module registry
phase."
  (let ((fields (cdr archive)))
    (flet ((field (key default)
             (if (archive-plist-has-key-p fields key)
                 (archive-plist-get fields key)
                 default)))
      (list (intern ":kind" :ece)
            (field (intern ":kind" :ece) (intern ":file" :ece))
            (intern ":unit-id" :ece)
            (archive-unit-id archive)
            (intern ":phase" :ece)
            (field (intern ":phase" :ece) 0)
            (intern ":imports" :ece)
            (field (intern ":imports" :ece) nil)
            (intern ":exports" :ece)
            (field (intern ":exports" :ece) (intern ":all" :ece))
            (intern ":init" :ece)
            (field (intern ":init" :ece) 0)
            (intern ":file" :ece)
            (archive-plist-get fields (intern ":file" :ece))
            (intern ":entries" :ece)
            (archive-plist-get fields (intern ":entries" :ece))))))

(defun archive-validated-init-index (unit cos)
  "Return UNIT's validated init entry index for COS.
Malformed metadata gets a clear archive-format error instead of bubbling up
as a low-level AREF type or bounds condition during boot."
  (let ((init (archive-plist-get unit (intern ":init" :ece)))
        (count (length cos)))
    (unless (and (integerp init) (<= 0 init) (< init count))
      (error 'ece-runtime-error
             :procedure nil
             :arguments nil
             :environment *global-env*
             :instruction nil
             :backtrace nil
             :original-error
             (make-condition 'simple-error
                             :format-control "Invalid .ecec archive init index: ~S for ~D entries."
                             :format-arguments (list init count))))
    init))

(defun archive-runtime-error (format-control &rest format-arguments)
  "Signal a clear archive/module loading error."
  (error 'ece-runtime-error
         :procedure nil
         :arguments nil
         :environment *global-env*
         :instruction nil
         :backtrace nil
         :original-error
         (make-condition 'simple-error
                         :format-control format-control
                         :format-arguments format-arguments)))

(defun archive-unit-field (unit key)
  (archive-plist-get unit (intern key :ece)))

(defun module-kind-p (kind)
  (and (symbolp kind) (string= (symbol-name kind) ":module")))

(defun module-unit-id-p (value)
  (and (consp value)
       (symbolp (car value))
       (string= (symbol-name (car value)) "module")))

(defun module-import-spec-p (value)
  (and (consp value)
       (symbolp (car value))
       (string= (symbol-name (car value)) ":module")))

(defun module-import-target (import)
  (if (module-import-spec-p import)
      (archive-plist-get import (intern ":module" :ece))
      import))

(defun normalize-module-import-id (import phase)
  "Normalize an import form or import spec to an archive unit id.
Phase 3 accepts a `(:module ...)` import spec, a full unit id
`(module <name> <phase>)`, or the short module name `<name>`. Short names
and import specs normalize to `(module <name> PHASE)`."
  (let ((target (module-import-target import)))
    (cond
      ((module-unit-id-p target) target)
      (t (list (intern "module" :ece) target phase)))))

(defun module-import-spec-field (import key default)
  (if (module-import-spec-p import)
      (let ((field-key (intern key :ece)))
        (if (archive-plist-has-key-p import field-key)
            (archive-plist-get import field-key)
            default))
      default))

(defun module-import-spec-has-field-p (import key)
  (and (module-import-spec-p import)
       (archive-plist-has-key-p import (intern key :ece))))

(defun module-import-symbol-member-p (name names)
  (member name names :test #'eq))

(defun module-import-rename-target (name renames)
  (let ((entry (assoc name renames :test #'eq)))
    (if entry (second entry) name)))

(defun register-archive-unit (unit cos)
  "Register UNIT and COS as an archive-unit record. Duplicate unit ids are
rejected so module identity remains unambiguous."
  (let* ((unit-id (archive-unit-field unit ":unit-id"))
         (existing (gethash unit-id *archive-units*)))
    (when existing
      (archive-runtime-error "Duplicate archive unit id: ~S." unit-id))
    (let ((record (make-archive-unit
                   :unit-id unit-id
                   :kind (archive-unit-field unit ":kind")
                   :phase (archive-unit-field unit ":phase")
                   :imports (archive-unit-field unit ":imports")
                   :exports (archive-unit-field unit ":exports")
                   :init-index (archive-validated-init-index unit cos)
                   :cos cos
                   :state :registered)))
      (setf (gethash unit-id *archive-units*) record)
      record)))

(defun make-module-environment (imported-exports)
  "Create a private module environment seeded with IMPORTED-EXPORTS."
  (let ((table (make-hash-table :test 'eq)))
    (maphash (lambda (name value)
               (setf (gethash name table) value))
             imported-exports)
    (list* (cons :hash-frame table) *global-env*)))

(defun module-instance-for-import (import phase importer-id)
  "Resolve and instantiate IMPORT for IMPORTER-ID."
  (let* ((unit-id (normalize-module-import-id import phase))
         (unit (gethash unit-id *archive-units*)))
    (unless unit
      (archive-runtime-error "Module import not found: ~S imported by ~S."
                             unit-id importer-id))
    (instantiate-module-unit unit)))

(defun collect-module-imports (unit)
  "Instantiate UNIT's imports and return a hash table of imported bindings."
  (let ((bindings (make-hash-table :test 'eq))
        (providers (make-hash-table :test 'eq))
        (importer-id (archive-unit-unit-id unit)))
    (flet ((validate-exported-names (unit-id exports names context)
             (dolist (name names)
               (multiple-value-bind (_ found) (gethash name exports)
                 (declare (ignore _))
                 (unless found
                   (archive-runtime-error
                    "Module import ~S in ~S ~A missing export ~S."
                    unit-id importer-id context name)))))
           (import-name-p (name only-present-p only except)
             (and (or (not only-present-p)
                      (module-import-symbol-member-p name only))
                  (not (module-import-symbol-member-p name except)))))
      (labels ((record-import (local-name value provider-id importer-id)
                 (multiple-value-bind (_ found) (gethash local-name bindings)
                   (declare (ignore _))
                   (when found
                     (archive-runtime-error
                      "Ambiguous import ~S in ~S: provided by ~S and ~S."
                      local-name
                      importer-id
                      (gethash local-name providers)
                      provider-id)))
                 (setf (gethash local-name bindings) value
                       (gethash local-name providers) provider-id)))
    (dolist (import (archive-unit-imports unit))
      (let* ((unit-id (normalize-module-import-id
                       import
                       (archive-unit-phase unit)))
             (only-present-p (module-import-spec-has-field-p import ":only"))
             (only (module-import-spec-field import ":only" nil))
             (except (module-import-spec-field import ":except" nil))
             (renames (module-import-spec-field import ":rename" nil))
             (instance (module-instance-for-import
                        import
                        (archive-unit-phase unit)
                        importer-id))
             (exports (module-instance-exports instance)))
        (when only-present-p
          (validate-exported-names unit-id exports only "only list names"))
        (validate-exported-names unit-id exports except "except list names")
        (validate-exported-names
         unit-id exports (mapcar #'first renames) "rename list names")
        (maphash (lambda (exported-name value)
                   (when (import-name-p exported-name only-present-p only except)
                     (record-import
                      (module-import-rename-target exported-name renames)
                      value
                      unit-id
                      importer-id)))
                 exports))))
    bindings)))

(defun module-env-table (env)
  (let ((frame (car env)))
    (unless (hash-frame-p frame)
      (archive-runtime-error "Internal module environment has no hash frame."))
    (cdr frame)))

(defun capture-module-exports (unit env)
  "Capture UNIT's declared exports from ENV."
  (let ((declared (archive-unit-exports unit))
        (table (module-env-table env))
        (exports (make-hash-table :test 'eq)))
    (cond
      ((and (symbolp declared) (string= (symbol-name declared) ":all"))
       (maphash (lambda (name value)
                  (setf (gethash name exports) value))
                table))
      (t
       (dolist (name declared)
         (multiple-value-bind (value found) (gethash name table)
           (unless found
             (archive-runtime-error "Module ~S declared missing export ~S."
                                    (archive-unit-unit-id unit) name))
           (setf (gethash name exports) value)))))
    exports))

(defun instantiate-module-unit (unit)
  "Instantiate UNIT once, recursively initializing imports first."
  (case (archive-unit-state unit)
    (:initialized (archive-unit-instance unit))
    (:initializing
     (archive-runtime-error "Module import cycle involving ~S."
                            (archive-unit-unit-id unit)))
    (otherwise
     (unless (module-kind-p (archive-unit-kind unit))
       (archive-runtime-error "Import ~S does not name a module archive unit."
                              (archive-unit-unit-id unit)))
     (setf (archive-unit-state unit) :initializing)
     (let* ((imports (collect-module-imports unit))
            (env (make-module-environment imports))
            (init (aref (archive-unit-cos unit)
                        (archive-unit-init-index unit)))
            (result (execute-instructions init 0 env))
            (exports (capture-module-exports unit env))
            (instance (make-module-instance
                       :unit-id (archive-unit-unit-id unit)
                       :env env
                       :exports exports
                       :result result)))
       (setf (archive-unit-env unit) env
             (archive-unit-result unit) result
             (archive-unit-instance unit) instance
             (archive-unit-state unit) :initialized
             (gethash (archive-unit-unit-id unit) *module-instances*) instance)
       instance))))

(defun archive-co-key (co index)
  "Derive the registry key for CO at archive INDEX. Always uses the
archive index — names are not unique within an archive (e.g., prelude
has 7 distinct `iter` code-objects nested inside reverse, length, map,
for-each, min/max, range). If we keyed on name, registration would
silently overwrite earlier entries, and all same-named code-objects
would share a single zone fn — catastrophic for correctness.

Must match the key the codegen emits in src/codegen-cl-inline.scm
co-key-for-archive-entry. CO is unused but kept here because
attach-archive-native-fns / register-archive-code-objects already have
the CO in hand and passing it matches the helper's positional shape."
  (declare (ignore co))
  index)

(defun archive-code-object-key (unit-id index)
  "Return the registry key for code-object INDEX in UNIT-ID."
  (cons unit-id index))

(defun register-archive-code-objects (cos unit-id)
  "Register each code-object in COS under (UNIT-ID . CO-KEY) in
*archive-code-objects* so emitted zone code can dereference nested-
lambda (const <co>) operands at execution time."
  (dotimes (i (length cos))
    (let* ((co (aref cos i))
           (co-key (archive-co-key co i))
           (key (archive-code-object-key unit-id co-key)))
      (setf (gethash key *archive-code-objects*) co)
      ;; Stamp the archive-key on the code-object for O(1) serialization
      ;; dispatch (ser/code-object reads this to decide by-ref vs inline).
      (setf (code-object-archive-key co) key))))

(defun attach-archive-native-fns (cos unit-id)
  "For each code-object in COS, look up its zone fn in *archive-zone-fns*
and, when found, set the native-fn slot so the executor's compiled-zone
fast-path dispatches to it on entry.

When a key is missing, leave native-fn NIL. This lets native-zone generation
remain an optional acceleration layer: code objects without generated native
functions fall through to the interpreter."
  (dotimes (i (length cos))
    (let* ((co (aref cos i))
           (co-key (archive-co-key co i))
           (zone-fn (gethash (archive-code-object-key unit-id co-key)
                             *archive-zone-fns*)))
      (when zone-fn
        (setf (code-object-native-fn co) zone-fn)))))

(defun load-ecec-file (pathname &key skip)
  "Load a .ecec file: read sections, create named spaces, assemble and execute.
Supports multi-space bundles (loops until EOF).
If SKIP is a list of strings, skip sections whose archive |file| field matches.
Uses the CL reader (not the ECE reader) so this works at boot before the ECE reader exists."
  (with-open-file (stream pathname)
    (let ((sections nil))
      (loop
        for raw = (read-ecec-archive-form stream)
        until (eq raw :eof)
        unless (ecec-archive-skipped-p raw skip)
          do (push (materialize-ecec-archive-section raw) sections))
      (setf sections (nreverse sections))
      (dolist (section sections)
        (register-bundle-archive-section section))
      (dolist (section sections)
        (load-materialized-ecec-archive-section
         section
         :bundle-registered t)))))

(defun boot-from-compiled ()
  "Boot ECE by loading the bootstrap bundle, skipping browser-lib."
  ;; Pre-define keyword symbols that ECE source code references as variables.
  ;; The ECE reader interns :foo as a symbol named ":foo" in the ECE package
  ;; (not a CL keyword). These must be in the environment for compiled code
  ;; that references them as variables (until the compiler treats them as
  ;; self-evaluating). The value is the ECE-interned symbol itself.
  (dolist (name '(":hash-table" ":hamt-node" ":hamt-collision"))
    (let ((sym (intern name :ece)))
      (define-variable! sym sym *global-env*)))
  ;; Define *global-env* as an ECE variable BEFORE boot so that env-reset
  ;; instructions in flat .ecec files can look it up during execution.
  (define-variable! (intern "*global-env*" :ece) *global-env* *global-env*)
  (let ((path (asdf:system-relative-pathname :ece "bootstrap/bootstrap.ecec")))
    (when (probe-file path)
      (load-ecec-file path :skip '("browser-lib")))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Compiled-zone loader (Stage 1)
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Load the generated .tmp/bootstrap-zones/ native-zone shards, when present.
;;; Their load-time effects register zone-NAME functions in one of two
;;; registries:
;;;   - *compiled-zone-functions* (legacy space path) — keyed on space-id
;;;     symbol. Consulted by execute-instructions on space entry.
;;;   - *archive-zone-fns* (§9.2 archive path) — keyed on
;;;     (unit-id . co-key). Consulted by load-ecec-archive-section as it
;;;     materializes each code-object, to attach native-fn in place.
;;;
;;; Load order: zones FIRST, then boot-from-compiled. This ordering lets
;;; the archive loader (inside boot-from-compiled → load-ecec-file →
;;; load-ecec-archive-section) populate code-object-native-fn immediately
;;; as each archive section is read. Zone files are pure self-registration
;;; (they only mutate the two hash tables above) and have no dependency
;;; on any state established by boot-from-compiled, so this flip is safe.
;;;
;;; Missing bootstrap/ directory is not an error — Stage 1 ships zero or more
;;; compiled zones depending on the build state. A fallback scan for legacy
;;; aggregate and *-zone.lisp files remains so stale local worktrees fail
;;; softly during transitions; current builds emit manifest-listed shards.

(defun read-compiled-zone-manifest (manifest-path)
  "Read and validate the generated CL native-zone shard manifest."
  (with-open-file (in manifest-path :direction :input)
    (let* ((*read-eval* nil)
           (*readtable* (copy-readtable nil))
           (form (read in nil nil)))
      (unless (and (consp form)
                   (eq (car form) :ece-cl-native-zones)
                   (eql (getf (cdr form) :version) 1)
                   (listp (getf (cdr form) :files)))
        (error "Malformed compiled-zone manifest ~A" manifest-path))
      form)))

(defun compiled-zone-string-suffix-p (suffix string)
  "Return true when STRING ends with SUFFIX."
  (let ((suffix-length (length suffix))
        (string-length (length string)))
    (and (>= string-length suffix-length)
         (string= suffix string :start2 (- string-length suffix-length)))))

(defun compiled-zone-shard-filename-p (file)
  "Return true when FILE is a simple generated shard filename."
  (and (stringp file)
       (> (length file) 0)
       (string= file (file-namestring file))
       (compiled-zone-string-suffix-p "-zones.lisp" file)
       (not (find #\: file))
       (not (find #\/ file))
       (not (find #\\ file))))

(defun compiled-zone-manifest-source-files (manifest-path zone-dir)
  "Return shard source files listed by MANIFEST-PATH in manifest order."
  (mapcar
   (lambda (entry)
     (let ((file (getf entry :file)))
       (unless (compiled-zone-shard-filename-p file)
         (error "Malformed compiled-zone manifest entry in ~A: ~S"
                manifest-path entry))
       (merge-pathnames file zone-dir)))
   (getf (cdr (read-compiled-zone-manifest manifest-path)) :files)))

(defun compiled-zone-source-files (zone-dir)
  "Return generated CL zone source files to load from ZONE-DIR.
Current builds emit manifest-listed source/module shards. The aggregate bundle
and legacy per-code-object files are used only when the manifest is absent."
  (let ((manifest (merge-pathnames "manifest.sexp" zone-dir))
        (bundle (merge-pathnames "bootstrap-zones.lisp" zone-dir)))
    (cond
      ((probe-file manifest)
       (compiled-zone-manifest-source-files manifest zone-dir))
      ((probe-file bundle) (list bundle))
      ((probe-file zone-dir)
       (sort (directory (merge-pathnames "*-zone.lisp" zone-dir))
             #'string<
             :key #'namestring))
      (t '()))))

(defun aggregate-compiled-zone-source-p (path)
  "Return true when PATH names the current aggregate zone bundle."
  (string= (file-namestring path) "bootstrap-zones.lisp"))

(defun compiled-zone-fasl-path (path fasl-dir)
  "Return the translated FASL path for generated zone source PATH."
  (merge-pathnames
   (make-pathname :type "fasl" :defaults (file-namestring path))
   fasl-dir))

(defun load-aggregate-compiled-zone (path fasl-dir)
  "Load aggregate zone source PATH, using an up-to-date cached FASL if present.
This intentionally does not call compile-file: compiling the aggregate bundle
as one file exceeds the normal SBCL test-process heap. If the cached FASL is
stale or partial, fall back to source-loading PATH."
  (let ((fasl-path (compiled-zone-fasl-path path fasl-dir)))
    (if (and (probe-file fasl-path)
             (>= (file-write-date fasl-path) (file-write-date path)))
        (handler-case
            (load fasl-path)
          (error ()
            (load path)))
        (load path))))

(defun load-compiled-zones ()
  "Find and load generated bootstrap zone Lisp files.
Current builds use manifest-listed source/module shards that define zone-NAME
functions and register them in *compiled-zone-functions* (legacy space path) or
*archive-zone-fns* (archive path). Shards use compile-file cached FASLs. A
legacy aggregate bundle still uses an up-to-date FASL when one already exists,
otherwise it is source-loaded directly because compiling it as one file can
exceed SBCL's dynamic-space budget. Errors during load are propagated with a
hint about regeneration."
  (let* ((zone-dir (asdf:system-relative-pathname :ece ".tmp/bootstrap-zones/"))
         (files (handler-case
                    (compiled-zone-source-files zone-dir)
                  (error (e)
                    (error "Failed to discover compiled-zone files in ~A: ~A~%~
                            The files may be stale — try `make bootstrap` to regenerate, ~
                            or `make clean` to remove generated zone artifacts."
                           zone-dir e))))
         (fasl-dir (asdf:apply-output-translations zone-dir)))
    (ensure-directories-exist (merge-pathnames "x" fasl-dir))
    (dolist (path files)
      (handler-case
          (if (aggregate-compiled-zone-source-p path)
              (load-aggregate-compiled-zone path fasl-dir)
              (let ((fasl-path (compiled-zone-fasl-path path fasl-dir)))
                (when (or (not (probe-file fasl-path))
                          (> (file-write-date path) (file-write-date fasl-path)))
                  (compile-file path :output-file fasl-path :print nil))
                (load fasl-path)))
        (error (e)
          (error "Failed to load compiled-zone file ~A: ~A~%~
                  The file may be stale — try `make bootstrap` to regenerate, ~
                  or `make clean` to remove generated zone artifacts."
                 path e))))))

(load-compiled-zones)

;;; Boot from .ecec files. Runs AFTER load-compiled-zones so the archive
;;; loader's attach-archive-native-fns call finds registrations in
;;; *archive-zone-fns* for every code-object in bootstrap.ecec.
(boot-from-compiled)

;;; Ensure all manifest primitives are in *global-env*. The image/ecec may
;;; predate new manifest entries; this top-up adds any missing bindings.
(dolist (entry *manifest-entries*)
  (destructuring-bind (id name arity platform) entry
    (declare (ignore arity))
    (let ((name-sym (intern (string-downcase (symbol-name name)) :ece)))
      (when (or (gethash id *primitive-available-ids*)
                (member platform '(browser)))
        (handler-case
            (lookup-variable-value name-sym *global-env*)
          (error ()
            (define-variable! name-sym (list '|primitive| id) *global-env*)))))))

;;; evaluate: compile and execute EXPR via the metacircular compiler in the image.
(defun evaluate (expr &optional (env *global-env* env-supplied-p))
  "Compile and execute EXPR in ENV using the metacircular compiler.
Downcases ECE-package symbols for CL→ECE boundary compatibility."
  (let ((normalized (downcase-ece-symbols expr)))
    (if env-supplied-p
        (mc-eval normalized env)
        (mc-eval normalized))))

;;; All registrations done — validate that every core/cl primitive resolved.
(validate-primitive-dispatch-tables)

;;; .ecec → .ececb binary conversion
;;; CL reads the .ecec (handles #S(SCHEME-FALSE), NIL, etc.), then
;;; calls the ECE converter function to emit binary.

(defun convert-ecec-to-ececb (input-path output-path)
  "Read INPUT-PATH with CL reader, pass to ECE converter, write OUTPUT-PATH."
  (let ((*readtable* (copy-readtable nil))
        (*package* (find-package :ece))
        (header nil)
        (units nil))
    ;; Use preserve case for reading ecec, read floats as double
    (setf (readtable-case *readtable*) :preserve)
    (setf *read-default-float-format* 'double-float)
    (with-open-file (in input-path :direction :input)
      ;; Read header
      (setf header (read in nil :eof))
      ;; Read all units
      (loop for unit = (read in nil :eof)
            until (eq unit :eof)
            do (push (downcase-ece-symbols unit) units))
      (setf units (nreverse units)))
    ;; Parse header: (ecec-header (space <name>) (macros <list>))
    (let* ((space-name (symbol-name (cadr (cadr header))))
           (macros-raw (cadr (caddr header)))
           (macros (if (or (null macros-raw) (eq macros-raw '|NIL|))
                       '()
                       (downcase-ece-symbols macros-raw)))
           (header-info (cons space-name macros)))
      ;; Replace all SCHEME-FALSE structs with ECE's actual #f singleton
      (setf units (subst *scheme-false* *scheme-false* units
                         :test (lambda (a b)
                                 (declare (ignore a))
                                 (scheme-false-p b))))
      ;; Convert CL floats to tagged byte lists for the ECE converter
      ;; (ECE can't do IEEE 754 bit manipulation, so CL extracts the bytes)
      (labels ((float-to-bytes (f)
                 (let* ((d (coerce f 'double-float))
                        (hi (sb-kernel:double-float-high-bits d))
                        (lo (sb-kernel:double-float-low-bits d)))
                   (list (intern ":ece-float-bytes" :ece)
                         (ldb (byte 8 0) lo) (ldb (byte 8 8) lo)
                         (ldb (byte 8 16) lo) (ldb (byte 8 24) lo)
                         (ldb (byte 8 0) hi) (ldb (byte 8 8) hi)
                         (ldb (byte 8 16) hi) (ldb (byte 8 24) hi))))
               (convert-floats (tree)
                 (cond
                   ((and (numberp tree) (not (integerp tree)))
                    (float-to-bytes tree))
                   ((consp tree)
                    (cons (convert-floats (car tree))
                          (convert-floats (cdr tree))))
                   (t tree))))
        (setf units (convert-floats units)))
      ;; Call ECE converter
      (evaluate (list (intern "ecec-to-binary-unit" :ece)
                      (list 'quote header-info)
                      (list 'quote units)
                      output-path)))))
