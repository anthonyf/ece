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
           #:assemble-into-global
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
           #:%intern-ece
           #:%instruction-vector-length
           #:%instruction-vector-push!
           #:%label-table-set!
           #:%label-table-ref
           #:%procedure-name-set!
           #:extend-environment
           #:ece-runtime-error
           #:ece-original-error
           #:ece-error-procedure
           #:ece-error-arguments
           #:ece-error-environment
           #:ece-error-instruction
           #:ece-error-backtrace
           #:repl
           #:mc-eval
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
    ((and (listp proc) (eq (car proc) '|compiled-procedure|))
     (let* ((entry (cadr proc))
            (name (or (gethash entry *procedure-name-table*)
                      ;; Backward compat: try bare local-pc if entry is qualified
                      (when (consp entry)
                        (gethash (cdr entry) *procedure-name-table*))))
            (loc (when (consp entry)
                   (resolve-ece-source-location (car entry) (cdr entry)))))
       (cond
         ((and name loc)
          (format nil "~A (~A:~D:~D)" name (car loc) (cadr loc) (caddr loc)))
         (name (format nil "~A" name))
         (t (format nil "<compiled-procedure entry=~A>" entry)))))
    ((and (listp proc) (eq (car proc) '|primitive|))
     (let ((id-or-name (cadr proc)))
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
        ((and (listp item)
              (consp item)
              (or (eq (car item) '|compiled-procedure|)
                  (eq (car item) '|primitive|)))
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
  (and (consp frame) (eq (car frame) :hash-frame)))

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

;;; --- Override table for non-conventional CL mappings ---
;;; Most primitives resolve via naming convention (ece-<name> or CL <name>).
;;; These ~13 entries have CL function names that don't follow convention.

(defparameter *primitive-cl-overrides*
  '((char->integer . char-code)
    (integer->char . code-char)
    (%raw-error . error)
    (vector-length . length)
    (vector-ref . aref)
    (string-length . length)
    (bitwise-and . logand)
    (bitwise-or . logior)
    (bitwise-xor . logxor)
    (bitwise-not . lognot)
    (arithmetic-shift . ash)
    (set-car! . rplaca)
    (set-cdr! . rplacd)))

;;; Boolean-returning primitive wrappers
;;; These CL functions return t/nil; we convert nil → *scheme-false*.

(defun ece-= (&rest args) (scheme-bool (apply #'cl:= args)))
(defun ece-< (&rest args) (scheme-bool (apply #'cl:< args)))
(defun ece-> (&rest args) (scheme-bool (apply #'cl:> args)))
(defun ece-null? (x) (scheme-bool (null x)))
(defun ece-pair? (x) (scheme-bool (consp x)))
(defun ece-number? (x) (scheme-bool (numberp x)))
(defun ece-keyword? (x) (scheme-bool (keywordp x)))
(defun ece-string? (x) (scheme-bool (stringp x)))
(defun ece-symbol? (x) (scheme-bool (and (symbolp x) x)))  ;; exclude nil ('())
(defun ece-integer? (x) (scheme-bool (integerp x)))
(defun ece-eq? (x y) (scheme-bool (eq x y)))
(defun ece-eqv? (x y) (scheme-bool (eql x y)))
(defun ece-equal? (x y) (scheme-bool (equal x y)))
(defun ece-char? (x) (scheme-bool (characterp x)))

;;; --- Manifest-based dispatch tables ---

(defun parse-primitives-manifest (filename)
  "Parse primitives.def and return a list of (id name arity platform) entries."
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
    (nreverse entries)))

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
  "Resolve ECE primitive name to CL function via override table or naming convention.
Tries: override table → ece-<name> in ECE package → <name> in CL package → <name> in ECE package."
  (let* ((name-str (symbol-name ece-name-sym))       ; lowercase ECE name
         (name-up (string-upcase name-str))           ; uppercase for CL symbol lookup
         (override (assoc name-up *primitive-cl-overrides*
                          :test #'string-equal
                          :key #'symbol-name)))
    (cond
      ;; Explicit override
      (override
       (let ((cl-sym (cdr override)))
         (and (fboundp cl-sym) (symbol-function cl-sym))))
      ;; Convention 1: ECE-<NAME> in ECE package
      ((let ((sym (find-symbol (concatenate 'string "ECE-" name-up) :ece)))
         (and sym (fboundp sym) (symbol-function sym))))
      ;; Convention 2: <NAME> in CL package
      ((let ((sym (find-symbol name-up :cl)))
         (and sym (fboundp sym) (symbol-function sym))))
      ;; Convention 3: <NAME> in ECE package
      ((let ((sym (find-symbol name-up :ece)))
         (and sym (fboundp sym) (symbol-function sym)))))))

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

(defun ece-hash-table? (obj)
  "ECE primitive: returns scheme bool. Use hash-table-p for CL-side checks."
  (scheme-bool (hash-table-p obj)))

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

(defun ece-display (obj &optional port)
  "Write obj without leading newline (princ). Optional PORT argument."
  (let ((stream (if port (ece-port-stream port) *standard-output*)))
    (cond
      ((scheme-false-p obj) (write-string "#f" stream))
      ((eq obj t) (write-string "#t" stream))
      ((null obj) (write-string "()" stream))
      ((and (listp obj) (member (car obj) '(compiled-procedure primitive)))
       (princ (format-ece-proc obj) stream))
      ((hash-table-p obj)
       (format-ece-hash-table obj stream
                              (lambda (v s) (ece-display-to-stream v s))))
      (t (let ((*print-circle* t))
           (princ obj stream))))
    (finish-output stream))
  obj)

(defun ece-display-to-stream (obj stream)
  "Display obj to a specific stream."
  (cond
    ((scheme-false-p obj) (write-string "#f" stream))
    ((eq obj t) (write-string "#t" stream))
    ((null obj) (write-string "()" stream))
    (t (let ((*print-circle* t)) (princ obj stream)))))

(defun ece-write (obj &optional port)
  "Write obj in readable form (prin1). Optional PORT argument."
  (let ((stream (if port (ece-port-stream port) *standard-output*)))
    (cond
      ((scheme-false-p obj) (write-string "#f" stream))
      ((eq obj t) (write-string "#t" stream))
      ((null obj) (write-string "()" stream))
      ((and (listp obj) (member (car obj) '(compiled-procedure primitive)))
       (princ (format-ece-proc obj) stream))
      ((hash-table-p obj)
       (format-ece-hash-table obj stream
                              (lambda (v s) (ece-write-to-stream v s))))
      (t (let ((*print-circle* t))
           (prin1 obj stream))))
    (finish-output stream))
  obj)

(defun ece-write-to-stream (obj stream)
  "Write obj in readable form to a specific stream."
  (cond
    ((scheme-false-p obj) (write-string "#f" stream))
    ((eq obj t) (write-string "#t" stream))
    ((null obj) (write-string "()" stream))
    (t (let ((*print-circle* t)) (prin1 obj stream)))))

(defun ece-newline (&optional port)
  "Write a newline. Optional PORT argument."
  (let ((stream (if port (ece-port-stream port) *standard-output*)))
    (terpri stream)
    (finish-output stream)
    nil))

(defun ece-eof? (obj)
  "Test if obj is the EOF sentinel."
  (scheme-bool (eq obj *eof-sentinel*)))

(defun ece-string-ref (s i)
  "Return the character at index i in string s."
  (char s i))

(defun ece-string-append (&rest strings)
  "Concatenate all string arguments."
  (apply #'concatenate 'string strings))

(defun ece-substring (s start end)
  "Extract substring from start to end."
  (subseq s start end))


(defun ece-string->symbol (s)
  "Intern a symbol from string s in the ECE package."
  (intern s :ece))

(defun ece-%intern-ece (s)
  "Intern string S as a symbol in the ECE package."
  (intern s :ece))

(defun ece-symbol->string (s)
  "Return the name of symbol s."
  (symbol-name s))

(defun ece-vector? (x)
  "Test if x is a vector (but not a string)."
  (scheme-bool (and (vectorp x) (not (stringp x)))))

(defun ece-make-vector (n &optional (fill 0))
  "Create a vector of n elements filled with fill (default 0)."
  (make-array n :initial-element fill))

(defun ece-vector (&rest args)
  "Create a vector from arguments."
  (apply #'vector args))

(defun ece-vector-set! (vec idx val)
  "Set element at idx in vec to val."
  (setf (aref vec idx) val)
  val)

(defun ece-read-line (&optional port)
  "Read a line of text from PORT (default current-input-port).
Returns EOF sentinel at end of input."
  (let ((stream (if port (ece-port-stream port) (ece-port-stream *current-input-port*))))
    (multiple-value-bind (line missing-newline-p)
        (read-line stream nil nil)
      (or line *eof-sentinel*))))

(defun ece-write-to-string (x)
  "Convert any value to its human-readable string representation."
  (cond
    ((scheme-false-p x) "#f")
    ((eq x t) "#t")
    ((null x) "()")
    ((and (listp x) (member (car x) '(compiled-procedure primitive)))
     (format-ece-proc x))
    ((hash-table-p x)
     (with-output-to-string (s)
       (format-ece-hash-table x s
                              (lambda (v str) (ece-display-to-stream v str)))))
    (t (let ((*print-circle* t))
         (princ-to-string x)))))

(defvar *preserve-readtable*
  (let ((rt (copy-readtable nil)))
    (setf (readtable-case rt) :preserve)
    rt)
  "Cached readtable with :preserve case for write-to-string-flat.")

(defun ece-write-to-string-flat (x)
  "Serialize X to a string without *print-circle* shared-structure markers.
Used for .ecec file serialization where the ECE reader needs to parse the output.
Binds *package* to :ece and uses :preserve readtable-case so lowercase symbols
print without CL pipe escaping."
  (let ((*print-circle* nil) (*print-pretty* nil) (*package* (find-package :ece))
        (*readtable* *preserve-readtable*))
    (if (hash-table-p x)
        ;; CL hash tables are not ECE-readable; emit sentinel
        "(%ser/opaque)"
        (prin1-to-string x))))

(defun ece-truncate (x)
  "Truncate number toward zero to integer."
  (values (cl:truncate x)))

(defun ece-floor (x)
  "Floor number toward negative infinity to integer."
  (values (cl:floor x)))

(defun ece-exact->inexact (x)
  "Convert exact number to inexact (float)."
  (float x 1.0))

(defun ece-sleep (seconds)
  "Pause execution for the given number of seconds. Returns nil."
  (cl:sleep seconds)
  nil)

(defun ece-clear-screen ()
  "Clear the terminal screen using ANSI escape sequences."
  (format t "~c[2J~c[H" #\Escape #\Escape)
  (finish-output)
  nil)

(defun ece-%yield! (k)
  "No-op yield on CL — cooperative scheduling is browser-only."
  k)

(defun ece-current-milliseconds ()
  "Milliseconds since SBCL start (CL approximation of performance.now)."
  (truncate (* (/ (get-internal-real-time) internal-time-units-per-second) 1000)))

(defun ece-wall-clock-ms ()
  "Milliseconds since midnight local time."
  (multiple-value-bind (sec min hour) (get-decoded-time)
    (+ (* hour 3600000) (* min 60000) (* sec 1000))))

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

(defun ece-input-port? (x)
  (scheme-bool (and (consp x) (eq (car x) 'input-port))))

(defun ece-output-port? (x)
  (scheme-bool (and (consp x) (eq (car x) 'output-port))))

(defun ece-port? (x)
  (scheme-bool (or (and (consp x) (eq (car x) 'input-port))
                   (and (consp x) (eq (car x) 'output-port)))))

(defun ece-port-stream (port)
  (cadr port))

(defun ece-port-name (port)
  (caddr port))

(defun ece-port-line (port)
  (cadddr port))

(defun ece-port-col (port)
  (car (cddddr port)))

(defvar *current-input-port*
  (ece-make-input-port *standard-input*))

(defvar *current-output-port*
  (ece-make-output-port *standard-output*))

(defun ece-current-input-port ()
  *current-input-port*)

(defun ece-current-output-port ()
  *current-output-port*)

;;; File and string port constructors

(defun ece-open-input-file (filename)
  (ece-make-input-port (open filename :direction :input)
                       (if (stringp filename) filename
                           (namestring filename))))

(defun ece-open-output-file (filename)
  (ece-make-output-port (open filename :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create)
                        (if (stringp filename) filename
                            (namestring filename))))

(defun ece-close-input-port (port)
  (close (ece-port-stream port))
  nil)

(defun ece-close-output-port (port)
  (close (ece-port-stream port))
  nil)

(defun ece-open-input-string (str)
  (ece-make-input-port (make-string-input-stream str)))

(defun ece-open-output-string ()
  (ece-make-output-port (make-string-output-stream)))

(defun ece-get-output-string (port)
  (get-output-stream-string (ece-port-stream port)))

;;; Character I/O primitives

(defun ece-read-char (&optional port)
  (let* ((p (or port *current-input-port*))
         (ch (read-char (ece-port-stream p) nil nil)))
    (when ch
      (if (char= ch #\Newline)
          (progn
            (setf (cadddr p) (1+ (cadddr p)))        ; increment line
            (setf (car (cddddr p)) 0))               ; reset col
          (setf (car (cddddr p)) (1+ (car (cddddr p)))))) ; increment col
    (or ch *eof-sentinel*)))

(defun ece-peek-char (&optional port)
  (let* ((p (or port *current-input-port*))
         (ch (peek-char nil (ece-port-stream p) nil nil)))
    (or ch *eof-sentinel*)))

(defun ece-write-char (ch &optional port)
  (let ((p (or port *current-output-port*)))
    (write-char ch (ece-port-stream p))
    (finish-output (ece-port-stream p))
    ch))

(defun ece-open-binary-output-file (filename)
  "Open FILENAME for binary writing. Returns an output port."
  (ece-make-output-port (open filename :direction :output
                              :element-type '(unsigned-byte 8)
                              :if-exists :supersede
                              :if-does-not-exist :create)
                        (if (stringp filename) filename
                            (namestring filename))))

(defun ece-write-byte (byte port)
  "Write BYTE (integer 0-255) to output PORT as a raw byte."
  (write-byte byte (ece-port-stream port))
  byte)

(defun ece-char-ready? (&optional port)
  (let ((p (or port *current-input-port*)))
    (scheme-bool (listen (ece-port-stream p)))))

;;; Character predicates

(defun ece-char-whitespace-p (ch)
  (scheme-bool (member ch '(#\Space #\Tab #\Newline #\Return #\Page))))

(defun ece-char-alphabetic-p (ch)
  (scheme-bool (alpha-char-p ch)))

(defun ece-char-numeric-p (ch)
  (scheme-bool (digit-char-p ch)))

;;; Scoped port redirection

(defun ece-with-input-from-file (filename thunk)
  (let ((port (ece-open-input-file filename)))
    (unwind-protect
         (let ((*current-input-port* port)
               (*standard-input* (ece-port-stream port)))
           (apply-ece-procedure thunk nil))
      (ece-close-input-port port))))

(defun ece-with-output-to-file (filename thunk)
  (let ((port (ece-open-output-file filename)))
    (unwind-protect
         (let ((*current-output-port* port)
               (*standard-output* (ece-port-stream port)))
           (apply-ece-procedure thunk nil))
      (ece-close-output-port port))))

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

;;; --- Type introspection primitives ---

(defun ece-compiled-procedure? (x)
  (scheme-bool (and (listp x) (eq (car x) '|compiled-procedure|))))

(defun ece-continuation? (x)
  (scheme-bool (and (listp x) (eq (car x) '|continuation|))))

(defun ece-primitive? (x)
  (scheme-bool (and (listp x) (eq (car x) '|primitive|))))

(defun ece-compiled-procedure-entry (proc)
  (cadr proc))

(defun ece-compiled-procedure-env (proc)
  (caddr proc))

(defun ece-continuation-stack (k)
  (cadr k))

(defun ece-continuation-conts (k)
  (caddr k))

(defun ece-%primitive-id-of (prim)
  (cadr prim))

(defun ece-%make-compiled-procedure (entry env)
  (list '|compiled-procedure| entry env))

(defun ece-%make-continuation (stack conts winds)
  (list '|continuation| stack conts winds))

(defun ece-continuation-winds (k)
  (cadddr k))

(defun ece-%make-primitive (id)
  (list '|primitive| id))

;; Env-frame introspection (CL frames are vectors for O(1) lexical access)
(defun ece-%env-frame? (x)
  (scheme-bool (vectorp x)))

(defun ece-%env-frame-names (frame)
  (declare (ignore frame))
  nil)

(defun ece-%env-frame-vals (frame)
  (coerce frame 'list))

(defun ece-%env-frame-enclosing (frame)
  (declare (ignore frame))
  nil)  ;; CL env frames don't have a single enclosing pointer accessible here

(defun ece-%make-env-frame (names vals enclosing)
  (declare (ignore names enclosing))
  (coerce vals 'simple-vector))

;; Winding stack sync
(defvar *cl-winding-stack* nil)

(defun ece-%set-winding-stack! (val)
  (setf *cl-winding-stack* val)
  nil)

(defun ece-%get-winding-stack ()
  (or *cl-winding-stack* nil))

;;; --- Platform discovery primitives ---

(defun ece-platform-has? (name)
  "Check if the named primitive is available on this platform.
Returns ECE #t if the primitive exists and has a non-stub implementation, #f otherwise."
  (let ((id (gethash name *primitive-name-to-id*)))
    (if (and id (gethash id *primitive-available-ids*))
        't
        'nil)))

(defun ece-%platform-primitives ()
  "Return a list of all primitive names available on this platform."
  (let ((result '()))
    (maphash (lambda (id available)
               (declare (ignore available))
               (let ((name (aref *primitive-name-table* id)))
                 (when name
                   (push name result))))
             *primitive-available-ids*)
    result))

(defun ece-%primitive-name (id)
  "Return the symbol name of the primitive with numeric ID, or #f."
  (if (and (integerp id) (< id (length *primitive-name-table*)))
      (or (aref *primitive-name-table* id) *scheme-false*)
      *scheme-false*))

(defun ece-%primitive-id (name)
  "Return the numeric ID for the named primitive, or #f."
  (or (gethash name *primitive-name-to-id*) *scheme-false*))

(defun ece-%global-env-frame ()
  "Return the first frame of *global-env* for identity comparison.
Used by the serializer to detect the global environment sentinel."
  (car *global-env*))

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

(defun ece-make-parameter (init &optional converter)
  "Create a parameter object: (parameter (<value> . <converter>)).
The prelude wrapper applies the converter before calling this,
so INIT is already converted. We just store it with the converter."
  (list 'parameter (cons init converter)))

(defun parameter-ref (param)
  "Read the current value of a parameter."
  (car (cadr param)))

(defun parameter-set! (param new-val)
  "Set a parameter's value, applying converter if present. Returns old value."
  (let* ((cell (cadr param))
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
  (let* ((cell (cadr param))
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
        (if (consp entry) entry
            (cons *executing-space-id* entry))
        env))

(defun compiled-procedure-p (proc)
  (and (listp proc) (eq (car proc) '|compiled-procedure|)))

(defun compiled-procedure-entry (proc)
  (cadr proc))

(defun compiled-procedure-env (proc)
  (caddr proc))

;;; Space-qualified address helpers
;;; A qualified address is (space-id . local-pc).
;;; During migration, bare integers are treated as (0 . pc).

(defun qualified-address-p (addr)
  "Test if ADDR is a space-qualified address (cons pair)."
  (consp addr))

(defun qualified-space-id (addr)
  "Extract space-id (symbol) from a qualified address.
Bare integers and integer 0 in qualified addresses return '|bootstrap|
for backward compat with old images."
  (if (consp addr)
      (let ((sid (car addr)))
        (if (eql sid 0) '|bootstrap| sid))
      '|bootstrap|))

(defun qualified-local-pc (addr)
  "Extract local-pc from a qualified address. Bare integers return themselves."
  (if (consp addr) (cdr addr) addr))

(defun make-qualified-address (space-id local-pc)
  "Create a space-qualified address."
  (cons space-id local-pc))

;;; Predicate helpers for executor operations

(defun primitive-procedure-p (proc)
  (and (listp proc) (eq (car proc) '|primitive|)))

(defun parameter-p (proc)
  "Test if PROC is a parameter object: (parameter (<value> . <converter>))"
  (and (listp proc) (eq (car proc) 'parameter)))

(defun ece-parameter? (x)
  "ECE-accessible: test if X is a parameter."
  (scheme-bool (parameter-p x)))

;;; Error sentinel — returned by apply-primitive-procedure when CL signals
;;; a type-error or division-by-zero, so the executor can bridge to ECE's raise.
(defstruct ece-error-sentinel message irritants)

(defun apply-primitive-procedure (proc argl)
  ;; Safety check: if a parameter object reaches here (compiled code without
  ;; parameter? branch), handle it directly.
  (when (parameter-p proc)
    (return-from apply-primitive-procedure (apply-parameter proc argl)))
  (let ((id-or-name (cadr proc)))
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
               :irritants (list (type-error-datum e)))))))))

;;; Continuation helpers for compiled code

(defun continuation-p (cont)
  (and (listp cont) (eq (car cont) '|continuation|)))

(defun continuation-stack (cont)
  (cadr cont))

(defun continuation-conts (cont)
  (caddr cont))

(defun cl-winding-stack ()
  "Read the ECE *winding-stack* variable. Returns nil during cold boot."
  (ignore-errors
    (lookup-variable-value (intern "*winding-stack*" :ece) *global-env*)))

(defun capture-continuation (stack continue-reg)
  (list '|continuation| (copy-list stack)
        (if (consp continue-reg)
            continue-reg
            (cons *executing-space-id* continue-reg))
        (or (cl-winding-stack) nil)))

(defun do-continuation-winds (cont)
  "If the continuation's saved winding stack differs from the current one,
call do-winds! to transition. Uses nested execute-compiled-call."
  (let* ((target-winds (cadddr cont))
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
  (let ((entries nil))
    (with-open-file (stream filename :direction :input)
      (loop for form = (cl:read stream nil :eof)
            until (eq form :eof)
            when (and (listp form) (>= (length form) 3))
            do (push (list (first form)    ; id
                           (second form)   ; name
                           (third form))   ; arity
                     entries)))
    (nreverse entries)))

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

(defvar *executing-space-id* '|bootstrap|
  "The space-id (symbol) of the currently executing space in the executor.
Used by make-compiled-procedure and capture-continuation to qualify
addresses. Distinct from *current-space-id* which is the assembler's
target space.")

(defun execute-instructions (initial-space-id initial-pc initial-env
                             &key initial-proc initial-argl initial-continue
                               initial-stack)
  "Execute assembled instructions starting in INITIAL-SPACE-ID at INITIAL-PC.
Single-loop executor: cross-space jumps update local space-id/instrs/ltab
variables inline — no throw/catch, no dispatcher, no allocation per transition."
  (let* ((space-id initial-space-id)
         (cs (get-space space-id))
         (instrs (compilation-space-resolved-instructions cs))
         (ltab (compilation-space-label-table cs))
         (*executing-space-id* space-id)
         (pc initial-pc)
         (flag nil)
         (val nil)
         (env initial-env)
         (proc initial-proc)
         (argl initial-argl)
         (continue initial-continue)
         (stack (or initial-stack '()))
         (len (length instrs)))
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
             (norm-space (sid)
               ;; Normalize integer 0 to bootstrap for old image compat
               (if (eql sid 0) '|bootstrap| sid))
             (switch-space (target-space-id)
               (let ((normalized (norm-space target-space-id)))
                 (setf space-id normalized)
                 (let ((target-cs (get-space normalized)))
                   (setf instrs (compilation-space-resolved-instructions target-cs))
                   (setf ltab (compilation-space-label-table target-cs))
                   (setf len (length instrs))
                   (setf *executing-space-id* normalized))))
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
                                            (cons space-id resolved-pc)
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
                                   (unless (eq err-space space-id)
                                     (switch-space err-space))
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
                               ;; Cross-space qualified address
                               ((and (consp addr) (not (eq (norm-space (car addr)) space-id)))
                                (switch-space (car addr))
                                (setf pc (cdr addr)))
                               ;; Same-space qualified address
                               ((consp addr) (setf pc (cdr addr)))
                               ;; Bare integer (backward compat)
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
               (t (error "Unknown instruction: ~A" instr))))
           (incf pc)
           (go loop-start)
         loop-end))
      val)))

(defvar *procedure-name-table*
  (make-hash-table :test 'equal)
  "Maps space-qualified entry addresses (space-id . local-pc) to procedure name symbols.
Populated at assembly time from procedure-name pseudo-instructions.")

(defvar *traced-procedures*
  (make-hash-table :test 'eq)
  "Maps symbol names to their original procedure values when traced.")

(defvar *trace-depth* 0
  "Current nesting depth for trace output indentation.")

;;; ============================================================
;;; Compilation Spaces
;;; ============================================================
;;; Each compilation space holds its own instruction array with local PCs.
;;; Procedure entry points and continuation addresses are space-qualified:
;;; (space-id . local-pc) instead of bare integers.

(defstruct compilation-space
  "A compilation space — an independent instruction array with local PCs."
  (name "" :type string)
  (instructions (make-array 256 :adjustable t :fill-pointer 0)
                :type vector)
  (resolved-instructions (make-array 256 :adjustable t :fill-pointer 0)
                         :type vector)
  (label-table (make-hash-table :test 'eq)
               :type hash-table)
  (compiled-fn nil))

(defvar *space-registry* (make-hash-table :test 'eq)
  "Hash table of space records, keyed by symbol.")

(defvar *current-space-id* '|bootstrap|
  "The space-id (symbol) that the assembler currently targets.
Set by (load ...) for per-file spaces, defaults to bootstrap.")


(defun create-space (name)
  "Allocate a new space with NAME (string), intern as symbol in :ece, return symbol."
  (let* ((sym (intern name :ece))
         (cs (make-compilation-space :name name)))
    (setf (gethash sym *space-registry*) cs)
    sym))

(defun get-space (space-id)
  "Look up a space by its symbol ID. Integer 0 maps to bootstrap for backward compat."
  (let ((key (if (eql space-id 0) '|bootstrap| space-id)))
    (or (gethash key *space-registry*)
        (error "Unknown space: ~A" space-id))))

(defun find-space-by-name (name)
  "Find a space by name string. Returns the space record, or NIL."
  (let ((sym (find-symbol name :ece)))
    (when sym (gethash sym *space-registry*))))

;;; ECE-accessible space primitives

(defun ece-%create-space (name)
  "ECE primitive: create a new compilation space."
  (create-space name))

(defun ece-%get-space (space-id)
  "ECE primitive: get a space by ID."
  (get-space space-id))

(defun ece-%space-instruction-length (space-id)
  "ECE primitive: get the instruction count for a space."
  (fill-pointer (compilation-space-instructions (get-space space-id))))

(defun ece-%space-name (space-id)
  "ECE primitive: get the name of a space."
  (compilation-space-name (get-space space-id)))

(defun ece-%current-space-id ()
  "ECE primitive: get the current space ID."
  *current-space-id*)

(defun ece-%set-current-space-id! (space-id)
  "ECE primitive: set the current space ID."
  (setf *current-space-id* space-id))

(defun ece-%space-instruction-push! (space-id source-instr)
  "ECE primitive: append instruction to a space's arrays."
  (let* ((cs (get-space space-id))
         (instrs (compilation-space-instructions cs))
         (resolved (compilation-space-resolved-instructions cs)))
    (vector-push-extend source-instr instrs)
    (vector-push-extend (resolve-operations source-instr) resolved)
    nil))

(defun ece-%space-label-set! (space-id label local-pc)
  "ECE primitive: register a label in a space's label table."
  (setf (gethash label (compilation-space-label-table (get-space space-id))) local-pc)
  nil)

(defun ece-%space-label-ref (space-id label)
  "ECE primitive: look up a label in a space's label table. Returns local-pc or ()."
  (gethash label (compilation-space-label-table (get-space space-id))))

(defun ece-%space-count ()
  "ECE primitive: return the number of spaces in the registry."
  (hash-table-count *space-registry*))

(defun ece-%space-source-ref (space-id index)
  "ECE primitive: get source instruction at INDEX in a space."
  (aref (compilation-space-instructions (get-space space-id)) index))

(defun ece-%space-label-entries (space-id)
  "ECE primitive: return label table of a space as an alist of (label . local-pc)."
  (let ((entries nil))
    (maphash (lambda (label pc) (push (cons label pc) entries))
             (compilation-space-label-table (get-space space-id)))
    entries))

;;; Create bootstrap space (keyed by symbol '|bootstrap|).
(unless (gethash '|bootstrap| *space-registry*)
  (setf (gethash '|bootstrap| *space-registry*)
        (make-compilation-space :name "bootstrap")))

;;; Compiled zone support (compile-to-host)
;;; When a compiled zone is loaded, execution dispatches between native CL
;;; code (compiled zone) and the interpreter (dynamic zone).

(defvar *compiled-zone-function* nil
  "The compiled zone function, or NIL if no compiled zone is loaded.
When set, holds a function of (pc val env proc argl continue stack)
that executes pre-compiled code and returns (values pc val env proc argl continue stack)
on zone exit.")

(defvar *compiled-zone-limit* 0
  "PC boundary: PCs 0 to (1- limit) are in the compiled zone.
PCs >= limit are in the dynamic/interpreter zone.")

(defvar *compiled-zone-op-table* (make-array 0)
  "Vector mapping operation index to CL function.
Populated when a compiled zone is loaded. The codegen emits
(aref *compiled-zone-op-table* N) references.")

(defun build-compiled-zone-op-table (op-names)
  "Build the operation table from a list of operation names.
Returns the populated *compiled-zone-op-table*.
OP-NAMES is a list of symbols in index order."
  (let ((table (make-array (length op-names))))
    (loop for name in op-names
          for i from 0
          do (setf (aref table i) (get-operation name)))
    (setf *compiled-zone-op-table* table)))

(defun resolve-operation-index (name op-name-to-index)
  "Get or create an index for operation NAME in the op-name-to-index hash table.
Returns the index."
  (or (gethash name op-name-to-index)
      (let ((idx (hash-table-count op-name-to-index)))
        (setf (gethash name op-name-to-index) idx)
        idx)))


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

(defun assemble-into-space (space-id instruction-list)
  "Append instructions to a space's arrays, register labels. Return local start PC."
  (let* ((cs (get-space space-id))
         (instrs (compilation-space-instructions cs))
         (resolved (compilation-space-resolved-instructions cs))
         (labels (compilation-space-label-table cs))
         (start-pc (fill-pointer instrs)))
    (dolist (item instruction-list)
      (cond
        ((symbolp item)
         (setf (gethash item labels) (fill-pointer instrs)))
        ((and (consp item) (eq (car item) '|procedure-name|))
         ;; Pseudo-instruction: (procedure-name <label> <name>)
         ;; Resolve label to local PC and store in name table with qualified key.
         (let ((local-pc (gethash (cadr item) labels)))
           (when local-pc
             (setf (gethash (cons space-id local-pc) *procedure-name-table*)
                   (caddr item)))))
        ;; Source-location marker — skip (used by compile-file for source-map)
        ((and (consp item) (eq (car item) '|source-location|)))
        (t
         (vector-push-extend item instrs)
         (vector-push-extend (resolve-operations item) resolved))))
    start-pc))

(defun assemble-into-global (instruction-list)
  "Append instructions to the bootstrap space. Return start PC.
Delegates to assemble-into-space with the bootstrap space."
  (assemble-into-space '|bootstrap| instruction-list))

;;; Assembler access primitives for ECE assembler
;;; These thin wrappers use the bootstrap space's instruction vector,
;;; label table, and the global procedure name table.

(defun ece-%instruction-vector-length ()
  "Return the instruction count of the bootstrap space."
  (fill-pointer (compilation-space-resolved-instructions (get-space '|bootstrap|))))

(defun ece-%instruction-vector-push! (source-instr)
  "Append SOURCE-INSTR to the bootstrap space's arrays."
  (ece-%space-instruction-push! '|bootstrap| source-instr))

(defun ece-%label-table-set! (label pc)
  "Register LABEL at PC in the bootstrap space's label table."
  (ece-%space-label-set! '|bootstrap| label pc))

(defun ece-%procedure-name-set! (pc-or-qualified name)
  "Register procedure NAME at entry PC in the procedure name table."
  (setf (gethash pc-or-qualified *procedure-name-table*) name)
  nil)

(defun ece-%label-table-ref (label)
  "Look up LABEL in the bootstrap space's label table."
  (ece-%space-label-ref '|bootstrap| label))

(defun ece-%label-table-entries ()
  "Return an alist of (label . pc) from the bootstrap space's label table."
  (ece-%space-label-entries '|bootstrap|))

(defun ece-%macro-table-entries ()
  "Return an alist of (name . proc) from the compile-time macro table."
  (let ((entries nil))
    (maphash (lambda (name proc) (push (cons name proc) entries))
             *compile-time-macros*)
    entries))

(defun ece-%eq-hash-table ()
  "Create an empty hash table with eq test (identity-based keys).
Returns a raw CL hash table — use %eq-hash-ref/set!/has-key? to access."
  (make-hash-table :test 'eq))

(defun ece-%eq-hash-ref (ht key &optional (default *scheme-false*))
  "Look up KEY in an eq-based hash table. Returns *scheme-false* if not found."
  (multiple-value-bind (val found) (gethash key ht)
    (if found val default)))

(defun ece-%eq-hash-set! (ht key val)
  "Set KEY to VAL in an eq-based hash table."
  (setf (gethash key ht) val)
  ht)

(defun ece-%eq-hash-has-key? (ht key)
  "Test if KEY exists in an eq-based hash table."
  (multiple-value-bind (val found) (gethash key ht)
    (declare (ignore val))
    (scheme-bool found)))

(defun ece-%eq-hash-keys (ht)
  "Return a list of all keys in an eq-based hash table."
  (let ((keys nil))
    (maphash (lambda (k v) (declare (ignore v)) (push k keys)) ht)
    keys))

;;; User-facing hash table primitives (platform-native, core IDs 141-149)
;;; These back the ECE-level hash-table API on all hosts.

(defun ece-%make-hash-table ()
  "Create a new empty mutable hash table."
  (make-hash-table :test 'eq))

(defun ece-hash-ref (ht key &rest default)
  "Look up KEY in hash table. Returns default (or #f) if not found."
  (multiple-value-bind (val found) (gethash key ht)
    (if found val
        (if default (car default) *scheme-false*))))

(defun ece-hash-set! (ht key val)
  "Set KEY to VAL in hash table (mutating)."
  (setf (gethash key ht) val)
  val)

(defun ece-hash-remove! (ht key)
  "Remove KEY from hash table."
  (remhash key ht)
  *scheme-false*)

(defun ece-hash-has-key? (ht key)
  "Test if KEY exists in hash table."
  (multiple-value-bind (val found) (gethash key ht)
    (declare (ignore val))
    (scheme-bool found)))

(defun ece-hash-keys (ht)
  "Return list of all keys in hash table."
  (let ((keys nil))
    (maphash (lambda (k v) (declare (ignore v)) (push k keys)) ht)
    keys))

(defun ece-hash-values (ht)
  "Return list of all values in hash table."
  (let ((vals nil))
    (maphash (lambda (k v) (declare (ignore k)) (push v vals)) ht)
    vals))

(defun ece-hash-count (ht)
  "Return number of entries in hash table."
  (hash-table-count ht))

;;; Hash-table frame primitives (for compaction.scm)

(defun ece-%hash-frame? (frame)
  "Test if FRAME is a hash-table-backed environment frame."
  (scheme-bool (hash-frame-p frame)))

(defun ece-%hash-frame-entries (frame)
  "Return an alist of (symbol . value) pairs from a hash-table frame."
  (unless (and (consp frame) (hash-table-p (cdr frame)))
    (error "ece-%hash-frame-entries: expected (:hash-frame . <hash-table>), got ~S (type ~A)"
           frame (type-of frame)))
  (let ((entries nil))
    (maphash (lambda (k v) (push (cons k v) entries)) (cdr frame))
    entries))

(defun ece-%make-hash-frame ()
  "Create an empty hash-table frame."
  (cons :hash-frame (make-hash-table :test 'eq)))

(defun ece-%hash-frame-set! (frame key val)
  "Set KEY to VAL in a hash-table frame."
  (setf (gethash key (cdr frame)) val)
  frame)

;;; Metacircular compiler support primitives

(defun ece-execute-from-pc (start-pc &optional (env *global-env*))
  "Execute instructions starting from START-PC in ENV (default: global).
START-PC may be a bare integer (space 0) or a qualified address."
  (execute-instructions (qualified-space-id start-pc)
                        (qualified-local-pc start-pc)
                        env))

(defun ece-trace (name)
  "Enable tracing for procedure NAME in the global environment.
Replaces the binding with a primitive wrapper that logs entry/exit."
  (let ((original (lookup-variable-value name *global-env*)))
    (when (gethash name *traced-procedures*)
      ;; Already traced, just return
      (return-from ece-trace name))
    (setf (gethash name *traced-procedures*) original)
    (let ((wrapper-sym (intern (format nil "TRACE-~A" name) :ece)))
      (setf (symbol-function wrapper-sym)
            (lambda (&rest args)
              (let ((indent (make-string (* 2 *trace-depth*) :initial-element #\Space)))
                (format t "~A(~A~{ ~S~})~%" indent name args)
                (incf *trace-depth*)
                (let ((result
                       (if (compiled-procedure-p original)
                           (execute-compiled-call original args)
                           (apply-primitive-procedure original args))))
                  (decf *trace-depth*)
                  (format t "~A=> ~S~%" indent result)
                  result))))
      (set-variable-value! name (list '|primitive| wrapper-sym) *global-env*)))
  name)

(defun ece-untrace (name)
  "Disable tracing for procedure NAME, restoring the original binding."
  (let ((original (gethash name *traced-procedures*)))
    (when original
      (set-variable-value! name original *global-env*)
      (remhash name *traced-procedures*)))
  name)

(defun execute-compiled-call (compiled-proc args)
  "Call a compiled procedure with ARGS.
Sets up proc and argl registers so the compiled code's entry point can
extract its environment and extend it with arguments.
Sets continue to a past-end address so (goto (reg continue)) exits cleanly."
  (let* ((entry (compiled-procedure-entry compiled-proc))
         (space-id (qualified-space-id entry))
         (local-pc (qualified-local-pc entry))
         (cs (get-space space-id))
         (return-pc (fill-pointer (compilation-space-resolved-instructions cs))))
    (execute-instructions space-id local-pc *global-env*
                          :initial-proc compiled-proc
                          :initial-argl args
                          :initial-continue (cons space-id return-pc))))

(defun ece-apply-compiled-procedure (compiled-proc args)
  "Call a compiled procedure with ARGS. Thin wrapper around execute-compiled-call
for use as an ECE primitive."
  (execute-compiled-call compiled-proc args))

(defun ece-get-macro (name)
  "Look up a compile-time macro by NAME. Returns the macro def or #f."
  (or (gethash name *compile-time-macros*) *scheme-false*))

(defun ece-set-macro! (name def)
  "Set a compile-time macro NAME to DEF."
  (setf (gethash name *compile-time-macros*) def)
  def)

;;; Parameter objects (R7RS / SRFI-39)
;;; New-style: (parameter (<value> . <converter>)) in the ECE environment.
;;; Legacy: (primitive PARAMN) via *parameter-table* — kept for bootstrap
;;; transition from old .ecec files. The wrapper-primitives maps make-parameter
;;; to the legacy version during first bootstrap. After rebuild with new
;;; compiler (which has parameter? dispatch), switch to new version.
(defvar *parameter-table* (make-hash-table :test 'eq))
(defvar *parameter-counter* 0)

(defun ece-make-parameter-legacy (init &optional converter)
  "Legacy make-parameter: creates (primitive PARAMN) with *parameter-table* dispatch."
  (let* ((converted-init (if (and converter (not (null converter))
                                  (not (scheme-false-p converter)))
                             (apply-ece-procedure converter (list init))
                             init))
         (name (intern (format nil "PARAM~D" (incf *parameter-counter*)) :ece)))
    (setf (gethash name *parameter-table*) (cons converted-init converter))
    (list '|primitive| name)))

(defun mc-eval (expr &optional (env nil env-supplied-p))
  "Evaluate EXPR using the metacircular compiler from the global env.
Works with image-only startup (no compiler.lisp needed).
When ENV is supplied, it is passed to mc-compile-and-go."
  (let ((mc-cag (lookup-variable-value (intern "mc-compile-and-go" :ece) *global-env*)))
    (if env-supplied-p
        (execute-compiled-call mc-cag (list expr env))
        (execute-compiled-call mc-cag (list expr)))))

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
struct instances that are not EQ to *scheme-false*."
  (cond ((scheme-false-p form) *scheme-false*)
        ((consp form) (cons (canonicalize-ecec-constants (car form))
                            (canonicalize-ecec-constants (cdr form))))
        (t form)))

(defun downcase-ece-symbols (form)
  "Walk FORM and downcase symbols for case-sensitive transition.
Handles old .ecec files that have uppercase symbols from the legacy reader.
Downcases both ECE-package and CL-package symbols into the ECE package
(since old reader resolved names like LIST, CAR as CL symbols via inheritance).
Preserves T, NIL, and symbols from other packages."
  (cond ((null form) form)
        ((eq form t) form)
        ((symbolp form)
         (let ((pkg (symbol-package form)))
           (if (or (null pkg)  ; uninterned
                   (and (not (eq pkg (find-package :ece)))
                        (not (eq pkg (find-package :cl)))))
               form
               (intern (string-downcase (symbol-name form)) :ece))))
        ((consp form) (cons (downcase-ece-symbols (car form))
                            (downcase-ece-symbols (cdr form))))
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

(defun load-ecec-section (stream)
  "Load one ecec section (header + instructions) from STREAM.
Creates a named space, registers source-map, assembles, and executes.
Returns T if a section was loaded, NIL on EOF."
  ;; Bind *package* to :ece so cl:read interns symbols in the ECE package,
  ;; regardless of caller context (e.g., CL-USER from run.lisp).
  (let* ((*package* (find-package :ece))
         (raw-header (cl:read stream nil :eof)))
    (when (eq raw-header :eof) (return-from load-ecec-section nil))
    (let* ((header (downcase-ece-symbols raw-header))
           (space-sym (cadr (assoc '|space| (cdr header))))
           (source-map-raw (cdr (assoc '|source-map| (cdr header))))
           (sid (create-space (symbol-name space-sym))))
      ;; Register source-map if present
      (when source-map-raw
        (register-ecec-source-map space-sym source-map-raw))
      (let ((*current-space-id* sid))
        (let* ((instrs (cl:read stream))
               (fixed (downcase-ece-symbols
                       (canonicalize-ecec-constants instrs)))
               (start-pc (assemble-into-space sid fixed)))
          (execute-instructions sid start-pc *global-env*))))
    t))

(defun load-ecec-file (pathname)
  "Load a .ecec file: read sections, create named spaces, assemble and execute.
Supports multi-space bundles (loops until EOF).
Uses the CL reader (not the ECE reader) so this works at boot before the ECE reader exists."
  (with-open-file (stream pathname)
    (loop while (load-ecec-section stream))))

(defun boot-from-compiled ()
  "Boot ECE by loading .ecec files from bootstrap/ in fixed order."
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
  (dolist (name '("prelude" "compiler" "reader" "assembler"
                  "compilation-unit" "syntax-rules"))
    (let ((path (asdf:system-relative-pathname :ece
                                               (format nil "bootstrap/~A.ecec" name))))
      (when (probe-file path)
        (load-ecec-file path))))
  )

;;; Boot from .ecec files
(boot-from-compiled)

;;; Ensure all manifest primitives are in *global-env*.
;;; The image/ecec may predate new manifest entries (e.g., platform-has?, try-eval).
;;; Pre-register try-eval as available so it gets added to the env.
(let ((id (gethash (intern "try-eval" :ece) *primitive-name-to-id*)))
  (when id (setf (gethash id *primitive-available-ids*) t)))
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

;;; ece-try-eval: error-handling wrapper around evaluate.
;;; The image's (primitive ece-try-eval) binding resolves to this via symbol-function.
(defun ece-try-eval (expr)
  "Evaluate expr, catching errors. Prints the error and returns the EOF sentinel on failure."
  (handler-case
      (evaluate expr)
    (error (c)
      (format t "Error: ~A~%" c)
      (finish-output)
      *eof-sentinel*)))

;;; Register try-eval dispatch now that ece-try-eval is defined
(let ((id (gethash (intern "try-eval" :ece) *primitive-name-to-id*)))
  (when id
    (setf (aref *primitive-dispatch-table* id) #'ece-try-eval)
    (setf (gethash id *primitive-available-ids*) t)))

;;; All late registrations done — validate that every core/cl primitive resolved.
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

;;; REPL: compile and run the REPL loop via the metacircular compiler.
(defun repl ()
  "Start the ECE REPL."
  (evaluate
   (downcase-ece-symbols
    '(begin
      (define (repl-loop)
       (display "ece> ")
       (define input (read))
       (if (eof? input)
           (begin (newline) (display "Bye!") (newline))
           (begin
            (define result (try-eval input))
            (if (not (eof? result)) (begin (write result) (newline)) (quote ()))
            (repl-loop))))
      (repl-loop)))))

