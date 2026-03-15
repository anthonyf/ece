(defpackage #:ece
  (:use #:cl)
  (:export #:*global-env*
           #:evaluate
           #:lambda
           #:var
           #:set
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
           #:string-downcase
           #:string-upcase
           #:string-split
           #:string-trim
           #:string-contains?
           #:string-join
           #:save-continuation!
           #:load-continuation
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
           #:scheme-bool
           #:ece-disassemble-image))

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
                   (loop for var in (car frame)
                         for val in (cdr frame)
                         for i below 10
                         do (format stream "~%    ~A = ~S"
                                    var (truncate-value val))))))
             (let ((bt (ece-error-backtrace c)))
               (when bt
                 (format stream "~%  backtrace:")
                 (loop for entry in bt
                       for i from 0
                       do (format stream "~%    [~D] ~A at pc=~D" i
                                  (if (car entry)
                                      (format-ece-proc (car entry))
                                      "<unknown>")
                                  (cdr entry))))))))

(defun format-ece-proc (proc)
  "Format a procedure value for display in errors."
  (cond
    ((and (listp proc) (eq (car proc) 'compiled-procedure))
     (let ((name (gethash (cadr proc) *procedure-name-table*)))
       (if name
           (format nil "~A" name)
           (format nil "<compiled-procedure entry=~A>" (cadr proc)))))
    ((and (listp proc) (eq (car proc) 'primitive))
     (format nil "<primitive ~A>" (cadr proc)))
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
Returns a list of (proc . pc) pairs, limited to 10 frames.
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
              (or (eq (car item) 'compiled-procedure)
                  (eq (car item) 'primitive)))
         (setf last-proc item))
        ;; An integer on the stack is likely a saved continue (return address)
        ((integerp item)
         (push (cons last-proc item) frames)
         (setf last-proc nil))))
    (nreverse frames)))

(defun format-ece-backtrace (backtrace)
  "Format a backtrace as readable text."
  (with-output-to-string (s)
    (loop for entry in backtrace
          for i from 0
          do (format s "~%  [~D] ~A at pc=~D"
                     i (format-ece-proc (car entry)) (cdr entry)))))

;;; Frame-based environment (SICP Section 4.1.3)
;;; A frame is (cons vars vals) — parallel lists of variable names and values
;;; An environment is a list of frames

(defun make-frame (vars vals)
  (cons vars vals))

(defun frame-variables (frame)
  (car frame))

(defun frame-values (frame)
  (cdr frame))

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

(defun extend-environment (vars vals base-env &optional extra-slots)
  "Create a new environment frame.
When EXTRA-SLOTS is provided (even if 0), creates vector frames for O(1) lexical access.
When EXTRA-SLOTS is nil (3-arg call), creates list-based frames for name-based lookup."
  (if extra-slots
      ;; 4-arg call from CL compiler: create vector frame
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
               (cons (vector vals) base-env)))))
      ;; 3-arg call from metacircular compiler: create list-based frame
      (if (or (listp vars) (null vars))
          (let ((var-list nil) (val-list nil) (v vars) (a vals))
            (loop while (consp v)
                  do (push (car v) var-list) (push (car a) val-list)
                  (setf v (cdr v)) (setf a (cdr a)))
            (when v (push v var-list) (push a val-list))
            (cons (make-frame (nreverse var-list) (nreverse val-list)) base-env))
          (cons (make-frame (list vars) (list vals)) base-env))))

(defun lookup-variable-value (var env)
  "Look up VAR by name, skipping vector frames (lexical-only)."
  (labels ((scan-frame (vars vals)
             (cond
               ((null vars) nil)
               ((eq var (car vars)) (cons t (car vals)))
               (t (scan-frame (cdr vars) (cdr vals)))))
           (env-loop (env)
             (if (null env)
                 (error "Unbound variable: ~A" var)
                 (let ((frame (car env)))
                   (if (vectorp frame)
                       ;; Skip vector frames — no variable names
                       (env-loop (cdr env))
                       (let ((result (scan-frame (frame-variables frame)
                                                 (frame-values frame))))
                         (if result
                             (cdr result)
                             (env-loop (cdr env)))))))))
    (env-loop env)))

(defun set-variable-value! (var val env)
  "Set VAR by name, skipping vector frames (lexical-only)."
  (labels ((scan (vars vals)
             (cond
               ((null vars) nil)
               ((eq var (car vars))
                (setf (car vals) val)
                t)
               (t (scan (cdr vars) (cdr vals)))))
           (env-loop (env)
             (if (null env)
                 (error "Unbound variable: ~A" var)
                 (let ((frame (car env)))
                   (if (vectorp frame)
                       (env-loop (cdr env))
                       (if (scan (frame-variables frame)
                                 (frame-values frame))
                           val
                           (env-loop (cdr env))))))))
    (env-loop env)))

(defun define-variable! (var val env)
  "Define VAR in the first list-based frame in ENV, skipping vector frames."
  (labels ((find-list-frame (e)
             (cond ((null e) (error "No list-based frame found for define-variable!"))
                   ((vectorp (car e)) (find-list-frame (cdr e)))
                   (t (car e)))))
    (let ((frame (find-list-frame env)))
      (labels ((scan (vars vals)
                 (cond
                   ((null vars)
                    (setf (car frame) (cons var (car frame)))
                    (setf (cdr frame) (cons val (cdr frame))))
                   ((eq var (car vars))
                    (setf (car vals) val))
                   (t (scan (cdr vars) (cdr vals))))))
        (scan (frame-variables frame) (frame-values frame))))))

;;; Primitives and global environment

(defparameter *primitive-procedures*
  '(+ - * / car cdr cons list
    (modulo . mod)
    (char->integer . char-code) (integer->char . code-char)
    (%raw-error . error)
    (vector-length . length) (vector-ref . aref)
    (bitwise-and . logand) (bitwise-or . logior)
    (bitwise-xor . logxor) (bitwise-not . lognot)
    (arithmetic-shift . ash)))

;;; Boolean-returning primitive wrappers
;;; These CL functions return t/nil; we convert nil → *scheme-false*.

(defun ece-= (&rest args) (scheme-bool (apply #'cl:= args)))
(defun ece-< (&rest args) (scheme-bool (apply #'cl:< args)))
(defun ece-> (&rest args) (scheme-bool (apply #'cl:> args)))
(defun ece-null? (x) (scheme-bool (null x)))
(defun ece-pair? (x) (scheme-bool (consp x)))
(defun ece-number? (x) (scheme-bool (numberp x)))
(defun ece-string? (x) (scheme-bool (stringp x)))
(defun ece-symbol? (x) (scheme-bool (symbolp x)))
(defun ece-integer? (x) (scheme-bool (integerp x)))
(defun ece-eq? (x y) (scheme-bool (eq x y)))
(defun ece-equal? (x y) (scheme-bool (equal x y)))
(defun ece-char? (x) (scheme-bool (characterp x)))
(defun ece-char=? (x y) (scheme-bool (char= x y)))
(defun ece-char<? (x y) (scheme-bool (char< x y)))
(defun ece-string=? (x y) (scheme-bool (string= x y)))
(defun ece-string<? (x y) (scheme-bool (if (string< x y) t nil)))
(defun ece-string>? (x y) (scheme-bool (if (string> x y) t nil)))

(defparameter *primitive-procedure-names*
  (mapcar (lambda (p) (if (listp p) (car p) p))
          *primitive-procedures*))

(defparameter *primitive-procedure-objects*
  (mapcar (lambda (p) (list 'primitive (if (listp p) (cdr p) p)))
          *primitive-procedures*))

(defparameter *global-env*
  (list (make-frame (copy-list *primitive-procedure-names*)
                    (copy-list *primitive-procedure-objects*))))

;; EOF sentinel for safe read
(defvar *eof-sentinel* (gensym "EOF"))

;;; Custom readtable for ECE: ` → quasiquote, , → unquote, ,@ → unquote-splicing
;;; I/O primitives with custom wrappers

(defun hamt-collect-entries (root)
  "Walk a HAMT trie and collect all (key . val) pairs into a list."
  (cond
    ((null root) nil)
    ((and (consp root) (eq (car root) :hamt-node))
     (let ((vec (caddr root))
           (entries nil))
       (dotimes (i (length vec))
         (let ((entry (aref vec i)))
           (cond
             ((and (consp entry) (member (car entry) '(:hamt-node :hamt-collision)))
              (setf entries (nconc entries (hamt-collect-entries entry))))
             ((consp entry)
              (push entry entries)))))
       entries))
    ((and (consp root) (eq (car root) :hamt-collision))
     (copy-list (cadr root)))
    (t nil)))

(defun ece-hash-table-p (obj)
  "Check if obj is an ECE hash table (HAMT-backed)."
  (and (consp obj) (eq (car obj) :hash-table)))

(defun format-ece-hash-table (obj stream writer)
  "Format an ECE HAMT hash table as {k1 v1 k2 v2 ...}."
  (let ((root (cddr obj))
        (entries (hamt-collect-entries (cddr obj))))
    (write-char #\{ stream)
    (loop for (pair . rest) on entries
          for key = (car pair)
          for val = (cdr pair)
          do (funcall writer key stream)
          (write-char #\Space stream)
          (funcall writer val stream)
          when rest do (write-char #\Space stream))
    (write-char #\} stream)))

(defun ece-display (obj)
  "Write obj without leading newline (princ)."
  (cond
    ((scheme-false-p obj) (write-string "#f"))
    ((eq obj t) (write-string "#t"))
    ((null obj) (write-string "()"))
    ((and (listp obj) (member (car obj) '(compiled-procedure primitive)))
     (princ (format-ece-proc obj)))
    ((ece-hash-table-p obj)
     (format-ece-hash-table obj *standard-output*
                            (lambda (v s) (ece-display-to-stream v s))))
    (t (let ((*print-circle* t))
         (princ obj))))
  (finish-output)
  obj)

(defun ece-display-to-stream (obj stream)
  "Display obj to a specific stream."
  (cond
    ((scheme-false-p obj) (write-string "#f" stream))
    ((eq obj t) (write-string "#t" stream))
    ((null obj) (write-string "()" stream))
    (t (let ((*print-circle* t)) (princ obj stream)))))

(defun ece-write (obj)
  "Write obj in readable form (prin1). Strings are quoted, symbols uppercase."
  (cond
    ((scheme-false-p obj) (write-string "#f"))
    ((eq obj t) (write-string "#t"))
    ((null obj) (write-string "()"))
    ((and (listp obj) (member (car obj) '(compiled-procedure primitive)))
     (princ (format-ece-proc obj)))
    ((ece-hash-table-p obj)
     (format-ece-hash-table obj *standard-output*
                            (lambda (v s) (ece-write-to-stream v s))))
    (t (let ((*print-circle* t))
         (prin1 obj))))
  (finish-output)
  obj)

(defun ece-write-to-stream (obj stream)
  "Write obj in readable form to a specific stream."
  (cond
    ((scheme-false-p obj) (write-string "#f" stream))
    ((eq obj t) (write-string "#t" stream))
    ((null obj) (write-string "()" stream))
    (t (let ((*print-circle* t)) (prin1 obj stream)))))

(defun ece-newline ()
  "Write a newline."
  (terpri)
  (finish-output)
  nil)

(defun ece-eof-p (obj)
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

(defun ece-string->number (s)
  "Parse a number from string S without invoking the CL reader.
Supports integers and decimal floats. Returns #f on failure."
  (let ((trimmed (string-trim '(#\Space #\Tab) s)))
    (when (zerop (length trimmed))
      (return-from ece-string->number *scheme-false*))
    (let ((dot-pos (position #\. trimmed)))
      (if dot-pos
          ;; Try float: parse integer and fractional parts separately
          (let* ((int-str (subseq trimmed 0 dot-pos))
                 (frac-str (subseq trimmed (1+ dot-pos)))
                 ;; Allow leading sign with empty integer part (e.g., "-.5" -> "-0" + "5")
                 (sign-only (or (string= int-str "") (string= int-str "-") (string= int-str "+")))
                 (int-part (if (string= int-str "")
                               0
                               (parse-integer int-str :junk-allowed t)))
                 (frac-part (if (zerop (length frac-str))
                                nil
                                (parse-integer frac-str :junk-allowed t))))
            (when (and sign-only (null frac-part))
              (return-from ece-string->number *scheme-false*))
            (when (or (and (not sign-only) (null int-part))
                      (and (> (length frac-str) 0) (null frac-part)))
              (return-from ece-string->number *scheme-false*))
            (let* ((negative (and (> (length int-str) 0) (char= (char int-str 0) #\-)))
                   (abs-int (abs (or int-part 0)))
                   (frac-val (if frac-part
                                 (/ (float frac-part) (expt 10.0 (length frac-str)))
                                 0.0))
                   (result (+ (float abs-int) frac-val)))
              (if negative (- result) result)))
          ;; Try integer
          (multiple-value-bind (val pos)
              (parse-integer trimmed :junk-allowed t)
            (if (and val (= pos (length trimmed)))
                val
                *scheme-false*))))))

(defun ece-number->string (n)
  "Convert number n to string."
  (write-to-string n))

(defun ece-string->symbol (s)
  "Intern a symbol from string s in the ECE package."
  (intern (string-upcase s) :ece))

(defun ece-%intern-ece (s)
  "Intern an already-upcased string S as a symbol in the ECE package."
  (intern s :ece))

(defun ece-symbol->string (s)
  "Return the name of symbol s as a lowercase string."
  (string-downcase (symbol-name s)))

(defun ece-vector-p (x)
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

(defun ece-vector->list (vec)
  "Convert vector to list."
  (coerce vec 'list))

(defun ece-list->vector (lst)
  "Convert list to vector."
  (coerce lst 'vector))

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
    ((ece-hash-table-p x)
     (with-output-to-string (s)
       (format-ece-hash-table x s
                              (lambda (v str) (ece-display-to-stream v str)))))
    (t (let ((*print-circle* t))
         (princ-to-string x)))))

(defun ece-sleep (seconds)
  "Pause execution for the given number of seconds. Returns nil."
  (cl:sleep seconds)
  nil)

(defun ece-clear-screen ()
  "Clear the terminal screen using ANSI escape sequences."
  (format t "~c[2J~c[H" #\Escape #\Escape)
  (finish-output)
  nil)

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

(defun ece-save-continuation! (filename value)
  "Write a value to a file in flat image format."
  (with-open-file (stream filename :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (flat-image-serialize value stream))
  t)

(defun ece-load-continuation (filename)
  "Read a value from a file in flat image format."
  (with-open-file (stream filename :direction :input)
    (flat-image-deserialize stream)))

;;; Ports (R7RS-style I/O abstraction)

(defun ece-make-input-port (stream)
  (list 'input-port stream))

(defun ece-make-output-port (stream)
  (list 'output-port stream))

(defun ece-input-port-p (x)
  (scheme-bool (and (consp x) (eq (car x) 'input-port))))

(defun ece-output-port-p (x)
  (scheme-bool (and (consp x) (eq (car x) 'output-port))))

(defun ece-port-p (x)
  (scheme-bool (or (and (consp x) (eq (car x) 'input-port))
                   (and (consp x) (eq (car x) 'output-port)))))

(defun ece-port-stream (port)
  (cadr port))

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
  (ece-make-input-port (open filename :direction :input)))

(defun ece-open-output-file (filename)
  (ece-make-output-port (open filename :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create)))

(defun ece-close-input-port (port)
  (close (ece-port-stream port))
  nil)

(defun ece-close-output-port (port)
  (close (ece-port-stream port))
  nil)

(defun ece-open-input-string (str)
  (ece-make-input-port (make-string-input-stream str)))

;;; Character I/O primitives

(defun ece-read-char (&optional port)
  (let* ((p (or port *current-input-port*))
         (ch (read-char (ece-port-stream p) nil nil)))
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

(defun ece-char-ready-p (&optional port)
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
         (let ((*current-input-port* port))
           (apply-primitive-procedure thunk nil))
      (ece-close-input-port port))))

(defun ece-with-output-to-file (filename thunk)
  (let ((port (ece-open-output-file filename)))
    (unwind-protect
         (let ((*current-output-port* port))
           (apply-primitive-procedure thunk nil))
      (ece-close-output-port port))))

;;; Compile-time macro table (declared here so image save/load can access it;
;;; used by compiler.lisp for macro expansion)
(defvar *compile-time-macros* (make-hash-table :test 'eq)
  "Hash table mapping macro names to compiled transformer procedures.")

;;; Register wrapper primitives that don't depend on the compiler.
;;; (try-eval, load, save-image!, and load-image! are registered in compiler.lisp.)

(defparameter *wrapper-primitives*
  '((= . ece-=) (< . ece-<) (> . ece->)
    (null? . ece-null?) (pair? . ece-pair?)
    (number? . ece-number?) (string? . ece-string?) (symbol? . ece-symbol?)
    (integer? . ece-integer?)
    (eq? . ece-eq?) (equal? . ece-equal?)
    (char? . ece-char?) (char=? . ece-char=?) (char<? . ece-char<?)
    (string=? . ece-string=?) (string<? . ece-string<?) (string>? . ece-string>?)
    (print . print)
    (write . ece-write)
    (display . ece-display)
    (newline . ece-newline)
    (eof? . ece-eof-p)
    (gensym . gensym)
    (string-length . length)
    (string-ref . ece-string-ref)
    (string-append . ece-string-append)
    (substring . ece-substring)
    (string->number . ece-string->number)
    (number->string . ece-number->string)
    (string->symbol . ece-string->symbol)
    (symbol->string . ece-symbol->string)
    (vector? . ece-vector-p)
    (make-vector . ece-make-vector)
    (vector . ece-vector)
    (vector-set! . ece-vector-set!)
    (vector->list . ece-vector->list)
    (list->vector . ece-list->vector)
    (read-line . ece-read-line)
    (write-to-string . ece-write-to-string)
    (sleep . ece-sleep)
    (clear-screen . ece-clear-screen)
    (string-downcase . string-downcase)
    (string-upcase . string-upcase)
    (string-split . ece-string-split)
    (string-trim . ece-string-trim)
    (string-contains? . ece-string-contains-p)
    (string-join . ece-string-join)
    (save-continuation! . ece-save-continuation!)
    (load-continuation . ece-load-continuation)
    (trace . ece-trace)
    (untrace . ece-untrace)
    (input-port? . ece-input-port-p)
    (output-port? . ece-output-port-p)
    (port? . ece-port-p)
    (current-input-port . ece-current-input-port)
    (current-output-port . ece-current-output-port)
    (open-input-file . ece-open-input-file)
    (open-output-file . ece-open-output-file)
    (close-input-port . ece-close-input-port)
    (close-output-port . ece-close-output-port)
    (open-input-string . ece-open-input-string)
    (read-char . ece-read-char)
    (peek-char . ece-peek-char)
    (write-char . ece-write-char)
    (char-ready? . ece-char-ready-p)
    (char-whitespace? . ece-char-whitespace-p)
    (char-alphabetic? . ece-char-alphabetic-p)
    (char-numeric? . ece-char-numeric-p)
    (with-input-from-file . ece-with-input-from-file)
    (with-output-to-file . ece-with-output-to-file)
    (string . string)
    (%intern-ece . ece-%intern-ece)
    (%instruction-vector-length . ece-%instruction-vector-length)
    (%instruction-vector-push! . ece-%instruction-vector-push!)
    (%label-table-set! . ece-%label-table-set!)
    (%label-table-ref . ece-%label-table-ref)
    (%procedure-name-set! . ece-%procedure-name-set!)
    (%instruction-source-ref . ece-%instruction-source-ref)
    (%instruction-source-length . ece-%instruction-source-length)
    (%procedure-name-entries . ece-%procedure-name-entries)
    (%label-table-entries . ece-%label-table-entries)
    (%macro-table-entries . ece-%macro-table-entries)
    (%parameter-table-entries . ece-%parameter-table-entries)
    (%parameter-counter . ece-%parameter-counter)
    (%eq-hash-table . ece-%eq-hash-table)
    (%eq-hash-ref . ece-%eq-hash-ref)
    (%eq-hash-set! . ece-%eq-hash-set!)
    (%eq-hash-has-key? . ece-%eq-hash-has-key-p)
    (%eq-hash-keys . ece-%eq-hash-keys)
    (%write-image . ece-%write-image)
    (set-car! . rplaca)
    (set-cdr! . rplacd)
    (extend-environment . extend-environment)))

(dolist (entry *wrapper-primitives*)
  (define-variable! (car entry) (list 'primitive (cdr entry)) *global-env*))

;;;; ========================================================================
;;;; INSTRUCTION EXECUTOR (SICP 5.5)
;;;; ========================================================================

;;; Compiled procedure representation

(defun make-compiled-procedure (entry env)
  (list 'compiled-procedure entry env))

(defun compiled-procedure-p (proc)
  (and (listp proc) (eq (car proc) 'compiled-procedure)))

(defun compiled-procedure-entry (proc)
  (cadr proc))

(defun compiled-procedure-env (proc)
  (caddr proc))

;;; Predicate helpers for executor operations

(defun primitive-procedure-p (proc)
  (and (listp proc) (eq (car proc) 'primitive)))

;;; Error sentinel — returned by apply-primitive-procedure when CL signals
;;; a type-error or division-by-zero, so the executor can bridge to ECE's raise.
(defstruct ece-error-sentinel message irritants)

(defun apply-primitive-procedure (proc argl)
  (let* ((name (cadr proc))
         (param-cell (gethash name *parameter-table*)))
    (if param-cell
        ;; Parameter dispatch: 0 args = get, 1 arg = set, 2 args = raw set
        (cond
          ((null argl) (car param-cell))
          ((null (cdr argl))
           (let ((old (car param-cell)))
             (setf (car param-cell)
                   (if (cdr param-cell)
                       (apply-primitive-procedure (cdr param-cell) argl)
                       (car argl)))
             old))
          (t ;; 2 args: raw set (bypass converter)
           (let ((old (car param-cell)))
             (setf (car param-cell) (car argl))
             old)))
        (handler-case
            (apply (symbol-function name) argl)
          (division-by-zero ()
            (make-ece-error-sentinel
             :message (format nil "~(~A~): division by zero" name)
             :irritants nil))
          (type-error (e)
            (make-ece-error-sentinel
             :message (format nil "~(~A~): ~A" name e)
             :irritants (list (type-error-datum e))))))))

;;; Continuation helpers for compiled code

(defun continuation-p (cont)
  (and (listp cont) (eq (car cont) 'continuation)))

(defun continuation-stack (cont)
  (cadr cont))

(defun continuation-conts (cont)
  (caddr cont))

(defun capture-continuation (stack continue-reg)
  (list 'continuation (copy-list stack) continue-reg))

;;; Operations dispatch

(defun get-operation (name)
  "Get the CL function for a compiled operation name."
  (ecase name
    (lookup-variable-value #'lookup-variable-value)
    (set-variable-value! #'set-variable-value!)
    (define-variable! #'define-variable!)
    (lexical-ref #'lexical-ref)
    (lexical-set! #'lexical-set!)
    (extend-environment #'extend-environment)
    (make-compiled-procedure #'make-compiled-procedure)
    (compiled-procedure-entry #'compiled-procedure-entry)
    (compiled-procedure-env #'compiled-procedure-env)
    (primitive-procedure? #'primitive-procedure-p)
    (continuation? #'continuation-p)
    (apply-primitive-procedure #'apply-primitive-procedure)
    (capture-continuation #'capture-continuation)
    (continuation-stack #'continuation-stack)
    (continuation-conts #'continuation-conts)
    (false? #'scheme-false-p)
    (list #'list)
    (cons #'cons)
    (car #'car)))

;;; Instruction executor

(defun execute-instructions (instruction-vector label-table initial-env
                             &optional (start-pc 0)
                             &key initial-proc initial-argl initial-continue)
  "Execute assembled instructions from START-PC, return val register.
Optional INITIAL-PROC, INITIAL-ARGL, and INITIAL-CONTINUE pre-load registers
for re-entering the executor to call a compiled procedure."
  (let ((pc start-pc)
        (flag nil)
        (val nil)
        (env initial-env)
        (proc initial-proc)
        (argl initial-argl)
        (continue initial-continue)
        (stack '())
        (len (length instruction-vector)))
    (labels ((get-reg (name)
               (ecase name
                 (val val) (env env) (proc proc) (argl argl)
                 (continue continue) (stack stack)))
             (set-reg (name value)
               (ecase name
                 (val (setf val value))
                 (env (setf env value))
                 (proc (setf proc value))
                 (argl (setf argl value))
                 (continue (setf continue value))
                 (stack (setf stack value))))
             (resolve-label (label)
               (or (gethash label label-table)
                   (error "Unknown label: ~A" label)))
             (eval-operand (operand)
               (ecase (car operand)
                 (const (cadr operand))
                 (reg (get-reg (cadr operand)))
                 (label (resolve-label (cadr operand)))))
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
                                         (aref instruction-vector pc))
                          :backtrace (extract-ece-backtrace stack)))))
                  (if wrapped
                      (error wrapped)
                      (error e)))))))
        (tagbody
         loop-start
           (when (>= pc len) (go loop-end))
           (let ((instr (aref instruction-vector pc)))
             (case (car instr)
               (assign
                (let ((target (cadr instr))
                      (source (caddr instr)))
                  (case (car source)
                    (const (set-reg target (cadr source)))
                    (reg (set-reg target (get-reg (cadr source))))
                    (label (set-reg target (resolve-label (cadr source))))
                    (op-fn
                     (let ((result (call-op (cadr source) (cdddr instr))))
                       (if (ece-error-sentinel-p result)
                           ;; Bridge CL error to ECE's error function
                           ;; (error msg . irritants) creates a proper error-object and raises
                           (let ((error-fn (ignore-errors
                                             (lookup-variable-value 'error *global-env*))))
                             (if (and error-fn (compiled-procedure-p error-fn))
                                 (progn
                                   (setf proc error-fn)
                                   (setf argl (cons (ece-error-sentinel-message result)
                                                    (ece-error-sentinel-irritants result)))
                                   (setf pc (compiled-procedure-entry error-fn))
                                   (go loop-start))
                                 ;; Fallback: no error yet (cold boot) — signal CL error
                                 (error "~A" (ece-error-sentinel-message result))))
                           (set-reg target result))))
                    (op (set-reg target
                                 (call-op (get-operation (cadr source))
                                          (cdddr instr))))
                    (t (error "Bad assign source: ~A" source)))))
               (test
                (let ((op-spec (cadr instr)))
                  (case (car op-spec)
                    (op-fn (setf flag (call-op (cadr op-spec) (cddr instr))))
                    (t (setf flag (call-op (get-operation (cadr op-spec))
                                           (cddr instr)))))))
               (branch
                (when flag
                  (setf pc (resolve-label (cadr (cadr instr))))
                  (go loop-start)))
               (goto
                (let ((dest (cadr instr)))
                  (ecase (car dest)
                    (label (setf pc (resolve-label (cadr dest))))
                    (reg (let ((addr (get-reg (cadr dest))))
                           (setf pc (if (numberp addr) addr (resolve-label addr))))))
                  (go loop-start)))
               (save
                (push (get-reg (cadr instr)) stack))
               (restore
                (set-reg (cadr instr) (pop stack)))
               (perform
                (let ((op-spec (cadr instr)))
                  (case (car op-spec)
                    (op-fn (call-op (cadr op-spec) (cddr instr)))
                    (t (call-op (get-operation (cadr op-spec)) (cddr instr))))))
               (t (error "Unknown instruction: ~A" instr))))
           (incf pc)
           (go loop-start)
         loop-end))
      val)))

;;; Global instruction accumulator
;;; All compiled code lives in one growing vector so compiled procedures
;;; can reference entry points from earlier compilations.

(defvar *global-instruction-vector*
  (make-array 256 :adjustable t :fill-pointer 0))

(defvar *global-instruction-source*
  (make-array 256 :adjustable t :fill-pointer 0)
  "Parallel vector of unresolved instructions for serialization.
Each index corresponds to the same index in *global-instruction-vector*.")

(defvar *global-label-table*
  (make-hash-table :test 'eq))

(defvar *procedure-name-table*
  (make-hash-table)
  "Maps entry PCs (integers) to procedure name symbols.
Populated at assembly time from procedure-name pseudo-instructions.")

(defvar *traced-procedures*
  (make-hash-table :test 'eq)
  "Maps symbol names to their original procedure values when traced.")

(defvar *trace-depth* 0
  "Current nesting depth for trace output indentation.")

(defun resolve-operations (instr)
  "Pre-resolve operation names to function pointers in an instruction."
  (case (car instr)
    (assign
     (let ((source (caddr instr)))
       (if (and (consp source) (eq (car source) 'op))
           `(assign ,(cadr instr) (op-fn ,(get-operation (cadr source)))
                    ,@(cdddr instr))
           instr)))
    (test
     (let ((op-spec (cadr instr)))
       `(test (op-fn ,(get-operation (cadr op-spec))) ,@(cddr instr))))
    (perform
     (let ((op-spec (cadr instr)))
       `(perform (op-fn ,(get-operation (cadr op-spec))) ,@(cddr instr))))
    (t instr)))

(defun assemble-into-global (instruction-list)
  "Append instructions to global vector, register labels. Return start PC."
  (let ((start-pc (fill-pointer *global-instruction-vector*)))
    (dolist (item instruction-list)
      (cond
        ((symbolp item)
         (setf (gethash item *global-label-table*)
               (fill-pointer *global-instruction-vector*)))
        ((and (consp item) (eq (car item) 'procedure-name))
         ;; Pseudo-instruction: (procedure-name <label> <name>)
         ;; Resolve label to PC and store in name table
         (let ((pc (gethash (cadr item) *global-label-table*)))
           (when pc
             (setf (gethash pc *procedure-name-table*) (caddr item)))))
        (t
         (vector-push-extend item *global-instruction-source*)
         (vector-push-extend (resolve-operations item)
                             *global-instruction-vector*))))
    start-pc))

;;; Assembler access primitives for ECE assembler
;;; These thin wrappers let the ECE assembler manipulate the global
;;; instruction vector, label table, and procedure name table.

(defun ece-%instruction-vector-length ()
  "Return the current fill-pointer of the global instruction vector."
  (fill-pointer *global-instruction-vector*))

(defun ece-%instruction-vector-push! (source-instr)
  "Append SOURCE-INSTR to the source vector and its resolved form to the execution vector."
  (vector-push-extend source-instr *global-instruction-source*)
  (vector-push-extend (resolve-operations source-instr) *global-instruction-vector*)
  nil)

(defun ece-%label-table-set! (label pc)
  "Register LABEL at PC in the global label table."
  (setf (gethash label *global-label-table*) pc)
  nil)

(defun ece-%procedure-name-set! (pc name)
  "Register procedure NAME at entry PC in the procedure name table."
  (setf (gethash pc *procedure-name-table*) name)
  nil)

(defun ece-%label-table-ref (label)
  "Look up LABEL in the global label table. Returns the PC or ()."
  (gethash label *global-label-table*))

;;; Read-only accessor primitives for ECE-side compaction
;;; These expose read access to global tables so compaction logic
;;; can live in ECE code (compaction.scm).

(defun ece-%instruction-source-ref (pc)
  "Return the source instruction at PC index."
  (aref *global-instruction-source* pc))

(defun ece-%instruction-source-length ()
  "Return the length of the source instruction vector."
  (fill-pointer *global-instruction-source*))

(defun ece-%procedure-name-entries ()
  "Return an alist of (pc . name) from the procedure-name table."
  (let ((entries nil))
    (maphash (lambda (pc name) (push (cons pc name) entries))
             *procedure-name-table*)
    entries))

(defun ece-%label-table-entries ()
  "Return an alist of (label . pc) from the global label table."
  (let ((entries nil))
    (maphash (lambda (label pc) (push (cons label pc) entries))
             *global-label-table*)
    entries))

(defun ece-%macro-table-entries ()
  "Return an alist of (name . proc) from the compile-time macro table."
  (let ((entries nil))
    (maphash (lambda (name proc) (push (cons name proc) entries))
             *compile-time-macros*)
    entries))

(defun ece-%parameter-table-entries ()
  "Return an alist of (name . cell) from the parameter table."
  (let ((entries nil))
    (maphash (lambda (name cell) (push (cons name cell) entries))
             *parameter-table*)
    entries))

(defun ece-%parameter-counter ()
  "Return the current parameter counter value."
  *parameter-counter*)

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

(defun ece-%eq-hash-has-key-p (ht key)
  "Test if KEY exists in an eq-based hash table."
  (multiple-value-bind (val found) (gethash key ht)
    (declare (ignore val))
    (scheme-bool found)))

(defun ece-%eq-hash-keys (ht)
  "Return a list of all keys in an eq-based hash table."
  (let ((keys nil))
    (maphash (lambda (k v) (declare (ignore v)) (push k keys)) ht)
    keys))

;;; Metacircular compiler support primitives

(defun ece-execute-from-pc (start-pc &optional (env *global-env*))
  "Execute instructions starting from START-PC in ENV (default: global)."
  (execute-instructions *global-instruction-vector*
                        *global-label-table*
                        env
                        start-pc))

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
      (set-variable-value! name (list 'primitive wrapper-sym) *global-env*)))
  name)

(defun ece-untrace (name)
  "Disable tracing for procedure NAME, restoring the original binding."
  (let ((original (gethash name *traced-procedures*)))
    (when original
      (set-variable-value! name original *global-env*)
      (remhash name *traced-procedures*)))
  name)

(defun execute-compiled-call (compiled-proc args)
  "Call a compiled procedure with ARGS by re-entering the executor.
Sets up proc and argl registers so the compiled code's entry point can
extract its environment and extend it with arguments.
Sets continue to past-end-of-vector so (goto (reg continue)) exits cleanly."
  (let ((entry (compiled-procedure-entry compiled-proc))
        (return-pc (length *global-instruction-vector*)))
    (execute-instructions *global-instruction-vector*
                          *global-label-table*
                          *global-env*
                          entry
                          :initial-proc compiled-proc
                          :initial-argl args
                          :initial-continue return-pc)))

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

(defvar *parameter-table* (make-hash-table :test 'eq)
  "Maps parameter name symbols (PARAM1, PARAM2, ...) to (value . converter) cells.")
(defvar *parameter-counter* 0)

(defun ece-make-parameter (init &optional converter)
  "Create a parameter object. Returns a (primitive <name>) that dispatches
through *parameter-table*: 0 args = get, 1 arg = set (with converter),
2 args = raw set (bypass converter, used by parameterize restore).
State is stored in *parameter-table* so parameters survive image round-trips."
  (let* ((converted-init (if converter
                             (apply-primitive-procedure
                              converter (list init))
                             init))
         (name (intern (format nil "PARAM~D" (incf *parameter-counter*)) :ece)))
    (setf (gethash name *parameter-table*) (cons converted-init converter))
    (list 'primitive name)))


;;;; ========================================================================
;;;; IMAGE SAVE/LOAD
;;;; ========================================================================

;;; ---- Binary format constants ----

;; Instruction opcodes
(defconstant +bin-assign+  #x01)
(defconstant +bin-test+    #x02)
(defconstant +bin-perform+ #x03)
(defconstant +bin-save+    #x04)
(defconstant +bin-restore+ #x05)
(defconstant +bin-goto+    #x06)
(defconstant +bin-branch+  #x07)

;; Register enum
(defconstant +reg-val+      #x00)
(defconstant +reg-env+      #x01)
(defconstant +reg-proc+     #x02)
(defconstant +reg-argl+     #x03)
(defconstant +reg-continue+ #x04)
(defconstant +reg-stack+    #x05)

;; Source type (for assign)
(defconstant +src-const+ #x00)
(defconstant +src-reg+   #x01)
(defconstant +src-op+    #x02)
(defconstant +src-label+ #x03)

;; Operand type (for op arguments)
(defconstant +operand-reg+   #x00)
(defconstant +operand-const+ #x01)
(defconstant +operand-label+ #x02)

;; Goto/branch target type
(defconstant +target-label+ #x00)
(defconstant +target-reg+   #x01)

;; Operation enum — must match get-operation dispatch
(defparameter *operation-to-id*
  (let ((ht (make-hash-table :test 'eq)))
    (loop for (sym id) in '((lookup-variable-value     #x00)
                            (set-variable-value!        #x01)
                            (define-variable!           #x02)
                            (lexical-ref                #x03)
                            (lexical-set!               #x04)
                            (extend-environment         #x05)
                            (make-compiled-procedure    #x06)
                            (compiled-procedure-entry   #x07)
                            (compiled-procedure-env     #x08)
                            (primitive-procedure?       #x09)
                            (continuation?              #x0A)
                            (apply-primitive-procedure  #x0B)
                            (capture-continuation       #x0C)
                            (continuation-stack         #x0D)
                            (continuation-conts         #x0E)
                            (false?                     #x0F)
                            (list                       #x10)
                            (cons                       #x11)
                            (car                        #x12))
          do (setf (gethash sym ht) id))
    ht))

(defparameter *id-to-operation*
  (let ((vec (make-array 19)))
    (maphash (lambda (sym id) (setf (aref vec id) sym)) *operation-to-id*)
    vec))

;; Register name lookup tables
(defparameter *register-to-id*
  (let ((ht (make-hash-table :test 'eq)))
    (loop for (sym id) in '((val #x00) (env #x01) (proc #x02)
                            (argl #x03) (continue #x04) (stack #x05))
          do (setf (gethash sym ht) id))
    ht))

(defparameter *id-to-register*
  #(val env proc argl continue stack))

;; Data type tags (for binary stack-machine encoding)
(defconstant +data-nil+     #x01)
(defconstant +data-t+       #x02)
(defconstant +data-false+   #x03)
(defconstant +data-int+     #x04)
(defconstant +data-float+   #x05)
(defconstant +data-char+    #x06)
(defconstant +data-sym+     #x07)
(defconstant +data-kwd+     #x08)
(defconstant +data-str+     #x09)
(defconstant +data-cons+    #x0A)
(defconstant +data-list+    #x0B)
(defconstant +data-def+     #x0C)
(defconstant +data-ref+     #x0D)
(defconstant +data-vec+     #x0E)
(defconstant +data-gsym+    #x0F)

;; Symbol table package tags
(defconstant +pkg-ece+        #x00)
(defconstant +pkg-keyword+    #x01)
(defconstant +pkg-cl+         #x02)
(defconstant +pkg-uninterned+ #x03)
(defconstant +pkg-other+      #x04)

;; Section type tags
(defconstant +section-instructions+ #x00)
(defconstant +section-labels+       #x01)
(defconstant +section-env+          #x02)
(defconstant +section-macros+       #x03)
(defconstant +section-names+        #x04)
(defconstant +section-params+       #x05)
(defconstant +section-param-counter+ #x06)

;;; ---- Binary I/O helpers ----

(defun bin-write-u8 (byte stream)
  (write-byte byte stream))

(defun bin-write-u16-be (val stream)
  (write-byte (ldb (byte 8 8) val) stream)
  (write-byte (ldb (byte 8 0) val) stream))

(defun bin-write-u32-be (val stream)
  (write-byte (ldb (byte 8 24) val) stream)
  (write-byte (ldb (byte 8 16) val) stream)
  (write-byte (ldb (byte 8 8) val) stream)
  (write-byte (ldb (byte 8 0) val) stream))

(defun bin-write-i64-be (val stream)
  ;; Handles negative values via two's complement
  (let ((unsigned (if (< val 0) (+ (ash 1 64) val) val)))
    (loop for shift from 56 downto 0 by 8
          do (write-byte (ldb (byte 8 shift) unsigned) stream))))

(defun bin-write-f64-be (val stream)
  (let* ((d (float val 1.0d0))
         (hi (sb-kernel:double-float-high-bits d))
         (lo (sb-kernel:double-float-low-bits d)))
    (bin-write-u32-be (logand hi #xFFFFFFFF) stream)
    (bin-write-u32-be lo stream)))

(defun bin-read-u8 (stream)
  (read-byte stream))

(defun bin-read-u16-be (stream)
  (let ((hi (read-byte stream))
        (lo (read-byte stream)))
    (logior (ash hi 8) lo)))

(defun bin-read-u32-be (stream)
  (let ((b3 (read-byte stream))
        (b2 (read-byte stream))
        (b1 (read-byte stream))
        (b0 (read-byte stream)))
    (logior (ash b3 24) (ash b2 16) (ash b1 8) b0)))

(defun bin-read-i64-be (stream)
  (let ((unsigned 0))
    (loop for shift from 56 downto 0 by 8
          do (setf unsigned (logior unsigned (ash (read-byte stream) shift))))
    (if (logbitp 63 unsigned)
        (- unsigned (ash 1 64))
        unsigned)))

(defun bin-read-f64-be (stream)
  (let ((hi (bin-read-u32-be stream))
        (lo (bin-read-u32-be stream)))
    (sb-kernel:make-double-float (if (logbitp 31 hi)
                                     (- hi (ash 1 32))
                                     hi)
                                 lo)))

;;; ---- Shared utilities ----

(defun hash-table-to-alist (ht)
  "Convert a hash table to an alist."
  (let ((pairs nil))
    (maphash (lambda (k v) (push (cons k v) pairs)) ht)
    pairs))

(defun flat-image-count-refs (data)
  "Pre-pass: walk DATA depth-first, counting references by identity (eq).
Returns a hash table mapping objects to their reference count.
Only cons cells, vectors, and strings are tracked (atoms are cheap to re-emit).
Uses an explicit work stack to avoid CL stack overflow."
  (let ((counts (make-hash-table :test 'eq))
        (work (list data)))
    (loop while work do
          (let ((obj (pop work)))
            (when (or (consp obj) (vectorp obj) (stringp obj)
                      ;; Track uninterned symbols (gensyms) for identity sharing
                      (and (symbolp obj) (null (symbol-package obj))))
              (let ((n (gethash obj counts 0)))
                (setf (gethash obj counts) (1+ n))
                (when (= n 0)
                  ;; First visit — push children (symbols have none)
                  (cond
                    ((consp obj)
                     (push (cdr obj) work)
                     (push (car obj) work))
                    ((and (vectorp obj) (not (stringp obj)))
                     (loop for i from (1- (length obj)) downto 0
                           do (push (aref obj i) work)))))))))
    counts))

(defun flat-image-escape-string (s)
  "Escape a string for flat image format: \\n, \\t, \\r, \\\", \\\\."
  (with-output-to-string (out)
    (loop for c across s do
          (case c
            (#\Newline (write-string "\\n" out))
            (#\Tab (write-string "\\t" out))
            (#\Return (write-string "\\r" out))
            (#\" (write-string "\\\"" out))
            (#\\ (write-string "\\\\" out))
            (t (write-char c out))))))

(defun flat-image-format-keyword-name (sym)
  "Format a keyword name, using |...| escaping if needed."
  (let ((name (symbol-name sym)))
    (if (and (> (length name) 0)
             (every (lambda (c)
                      (or (alpha-char-p c) (digit-char-p c)
                          (member c '(#\- #\_ #\? #\! #\* #\> #\< #\/ #\+ #\= #\. #\~))))
                    name))
        name
        (format nil "|~A|" name))))

(defun flat-image-proper-list-p (obj def-ids)
  "Return the length if OBJ is a proper list with no shared internal cons cells, NIL otherwise.
A list can use the `list N` opcode only if no cdr spine cons is shared."
  (let ((len 0))
    (loop
     (cond
       ((null obj) (return len))
       ((not (consp obj)) (return nil))
       ;; If a cdr-spine cons (after the head) is shared, can't use list opcode
       ((and (> len 0) (gethash obj def-ids)) (return nil))
       (t (incf len)
          (setf obj (cdr obj)))))))

(defun flat-image-serialize (data stream)
  "Serialize DATA to STREAM in flat image format.
Two-pass: first count references, then emit instructions.
Fully iterative to avoid stack overflow."
  (let* ((counts (flat-image-count-refs data))
         (def-ids (make-hash-table :test 'eq))
         (emitted (make-hash-table :test 'eq))
         (next-id 0)
         (work-stack (make-array 1024 :adjustable t :fill-pointer 0)))
    ;; Assign def IDs to multiply-referenced objects
    (maphash (lambda (obj count)
               (when (> count 1)
                 (setf (gethash obj def-ids) next-id)
                 (incf next-id)))
             counts)
    (flet ((wpush (item) (vector-push-extend item work-stack))
           (wpop () (vector-pop work-stack)))
      (labels
          ((schedule-emit (obj) (wpush (cons :emit obj)))
           (mark-emitted (obj)
             (let ((id (gethash obj def-ids)))
               (when id
                 (setf (gethash obj emitted) t))))
           (emit-atom (obj)
             (cond
               ((scheme-false-p obj) (write-string "false" stream) (terpri stream))
               ((null obj) (write-string "nil" stream) (terpri stream))
               ((eq obj t) (write-string "t" stream) (terpri stream))
               ((integerp obj) (format stream "int ~D~%" obj))
               ((floatp obj) (format stream "float ~F~%" obj))
               ((characterp obj) (format stream "chr ~D~%" (char-code obj)))
               ((keywordp obj) (format stream "kwd ~A~%" (flat-image-format-keyword-name obj)))
               ;; Uninterned symbol (gensym)
               ((and (symbolp obj) (null (symbol-package obj)))
                (format stream "gsym ~A~%" (symbol-name obj)))
               ;; Interned symbol — include package if not accessible from :ece
               ((symbolp obj)
                (let ((name (symbol-name obj)))
                  (multiple-value-bind (found-sym status)
                      (find-symbol name :ece)
                    (if (and status (eq found-sym obj))
                        (format stream "sym ~A~%" name)
                        (format stream "sym ~A::~A~%"
                                (package-name (symbol-package obj)) name)))))
               (t (warn "flat-image-serialize: unhandled type ~A for ~S" (type-of obj) obj)
                  (write-string "nil" stream) (terpri stream))))
           (schedule-cons-structure (start)
             ;; Mark start as emitted immediately to prevent duplicate scheduling
             (mark-emitted start)
             (let ((list-len (flat-image-proper-list-p start def-ids)))
               (if list-len
                   ;; Proper list
                   (progn
                     (when (gethash start def-ids)
                       (wpush (cons :def start)))
                     (wpush (cons :list list-len))
                     (let ((rev nil))
                       (do ((cur start (cdr cur)))
                           ((null cur))
                         (push (car cur) rev))
                       (dolist (item rev)
                         (schedule-emit item))))
                   ;; Dotted/improper chain
                   (let ((cars nil) (n 0) (final-cdr nil))
                     (do ((cur start))
                         (nil)
                       (push (car cur) cars)
                       (incf n)
                       (let ((next (cdr cur)))
                         (cond
                           ((null next) (setf final-cdr nil) (return))
                           ((not (consp next)) (setf final-cdr next) (return))
                           ;; Shared cdr: stop here
                           ((gethash next def-ids) (setf final-cdr next) (return))
                           (t (setf cur next)))))
                     (when (gethash start def-ids)
                       (wpush (cons :def start)))
                     (wpush (cons :conses n))
                     (schedule-emit final-cdr)
                     ;; cars is in reverse; emit outermost first
                     (dolist (car-val cars)
                       (schedule-emit car-val)))))))
        ;; Initialize
        (schedule-emit data)
        ;; Process work stack
        (loop while (> (fill-pointer work-stack) 0) do
              (let* ((item (wpop))
                     (tag (car item))
                     (val (cdr item)))
                (case tag
                  (:emit
                   (cond
                     ;; Already emitted (shared): back-reference
                     ((gethash val emitted)
                      (format stream "ref ~D~%" (gethash val def-ids)))
                     ;; String
                     ((stringp val)
                      (format stream "str \"~A\"~%" (flat-image-escape-string val))
                      (mark-emitted val)
                      (let ((id (gethash val def-ids)))
                        (when id (format stream "def ~D~%" id))))
                     ;; Vector (non-string)
                     ((and (vectorp val) (not (stringp val)))
                      (mark-emitted val)
                      (when (gethash val def-ids)
                        (wpush (cons :def val)))
                      (wpush (cons :vec (length val)))
                      (loop for i from (1- (length val)) downto 0
                            do (schedule-emit (aref val i))))
                     ;; Uninterned symbol (gensym) - needs def/ref like strings
                     ((and (symbolp val) (null (symbol-package val)))
                      (format stream "gsym ~A~%" (symbol-name val))
                      (mark-emitted val)
                      (let ((id (gethash val def-ids)))
                        (when id (format stream "def ~D~%" id))))
                     ;; Cons cell
                     ((consp val)
                      (schedule-cons-structure val))
                     ;; Atoms
                     (t (emit-atom val))))
                  (:def
                   (format stream "def ~D~%" (gethash val def-ids)))
                  (:list
                   (format stream "list ~D~%" val))
                  (:vec
                   (format stream "vec ~D~%" val))
                  (:conses
                   (loop repeat val
                         do (write-string "cons" stream)
                         (terpri stream))))))))))

(defun ece-save-image (filename)
  "Delegate to ECE-side save-image! which handles compaction and serialization."
  (let ((save-fn (lookup-variable-value 'save-image! *global-env*)))
    (execute-compiled-call save-fn (list filename))))

(defun alist-to-hash-table (alist &key (test 'eql))
  "Build a hash table from an alist."
  (let ((ht (make-hash-table :test test)))
    (dolist (pair alist ht)
      (setf (gethash (car pair) ht) (cdr pair)))))

(defun flat-image-unescape-string (s)
  "Unescape a flat image string: \\n → newline, \\t → tab, \\r → CR, \\\" → quote, \\\\ → backslash."
  (let ((result (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (i 0)
        (len (length s)))
    (loop while (< i len) do
          (let ((c (char s i)))
            (if (and (eql c #\\) (< (1+ i) len))
                (let ((next (char s (1+ i))))
                  (case next
                    (#\n (vector-push-extend #\Newline result))
                    (#\t (vector-push-extend #\Tab result))
                    (#\r (vector-push-extend #\Return result))
                    (#\" (vector-push-extend #\" result))
                    (#\\ (vector-push-extend #\\ result))
                    (t (vector-push-extend #\\ result)
                       (vector-push-extend next result)))
                  (incf i 2))
                (progn
                  (vector-push-extend c result)
                  (incf i)))))
    (copy-seq result)))

(defun flat-image-parse-keyword-name (name-str)
  "Parse a keyword name, handling |...| escaping."
  (if (and (>= (length name-str) 2)
           (eql (char name-str 0) #\|)
           (eql (char name-str (1- (length name-str))) #\|))
      ;; Escaped name: strip the pipes
      (intern (subseq name-str 1 (1- (length name-str))) :keyword)
      (intern name-str :keyword)))

(defun flat-image-backpatch (root defs forward-refs)
  "Walk ROOT replacing forward-reference placeholders with actual values.
FORWARD-REFS maps placeholder symbols to def IDs."
  (let ((visited (make-hash-table :test 'eq)))
    (labels ((patch-value (v)
               "Return the patched value for V."
               (let ((id (gethash v forward-refs)))
                 (if id (gethash id defs) v)))
             (walk (obj)
               (when (and obj (not (gethash obj visited)))
                 (cond
                   ((consp obj)
                    (setf (gethash obj visited) t)
                    (setf (car obj) (patch-value (car obj)))
                    (setf (cdr obj) (patch-value (cdr obj)))
                    (walk (car obj))
                    (walk (cdr obj)))
                   ((and (vectorp obj) (not (stringp obj)))
                    (setf (gethash obj visited) t)
                    (loop for i below (length obj)
                          do (setf (aref obj i) (patch-value (aref obj i)))
                          (walk (aref obj i))))))))
      (walk root)
      root)))

(defun flat-image-deserialize (stream)
  "Deserialize flat image format from STREAM. Returns the top-of-stack value.
Supports forward references: ref N before def N uses placeholders that are
backpatched after deserialization."
  (let ((stack nil)
        (defs (make-hash-table))
        (forward-refs (make-hash-table :test 'eq))
        (has-forward-refs nil))
    (loop for line = (read-line stream nil nil)
          while line do
          (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
            (when (> (length trimmed) 0)
              (let* ((space-pos (position #\Space trimmed))
                     (opcode (if space-pos (subseq trimmed 0 space-pos) trimmed))
                     (arg (if space-pos (subseq trimmed (1+ space-pos)) nil)))
                (cond
                  ;; nil
                  ((string= opcode "nil")
                   (push nil stack))
                  ;; t
                  ((string= opcode "t")
                   (push t stack))
                  ;; false (#f sentinel)
                  ((string= opcode "false")
                   (push *scheme-false* stack))
                  ;; int N
                  ((string= opcode "int")
                   (push (parse-integer arg) stack))
                  ;; float N
                  ((string= opcode "float")
                   (push (read-from-string arg) stack))
                  ;; chr N
                  ((string= opcode "chr")
                   (push (code-char (parse-integer arg)) stack))
                  ;; sym NAME or sym PACKAGE::NAME
                  ((string= opcode "sym")
                   (let ((dcolon (search "::" arg)))
                     (if dcolon
                         (let ((pkg-name (subseq arg 0 dcolon))
                               (sym-name (subseq arg (+ 2 dcolon))))
                           (push (intern sym-name (or (find-package pkg-name)
                                                      (make-package pkg-name :use nil)))
                                 stack))
                         (push (intern arg :ece) stack))))
                  ;; gsym NAME (uninterned symbol)
                  ((string= opcode "gsym")
                   (push (make-symbol arg) stack))
                  ;; kwd NAME
                  ((string= opcode "kwd")
                   (push (flat-image-parse-keyword-name arg) stack))
                  ;; str "..."
                  ((string= opcode "str")
                   ;; Strip surrounding quotes and unescape
                   (let ((content (subseq arg 1 (1- (length arg)))))
                     (push (flat-image-unescape-string content) stack)))
                  ;; cons
                  ((string= opcode "cons")
                   (let ((b (pop stack))
                         (a (pop stack)))
                     (push (cons a b) stack)))
                  ;; list N
                  ((string= opcode "list")
                   (let* ((n (parse-integer arg))
                          (items (make-list n)))
                     ;; Pop N items (last pushed = last element)
                     (loop for i from (1- n) downto 0
                           do (setf (nth i items) (pop stack)))
                     (push items stack)))
                  ;; vec N
                  ((string= opcode "vec")
                   (let* ((n (parse-integer arg))
                          (v (make-array n)))
                     (loop for i from (1- n) downto 0
                           do (setf (aref v i) (pop stack)))
                     (push v stack)))
                  ;; def N
                  ((string= opcode "def")
                   (let ((id (parse-integer arg)))
                     (setf (gethash id defs) (first stack))))
                  ;; ref N
                  ((string= opcode "ref")
                   (let ((id (parse-integer arg)))
                     (let ((val (gethash id defs)))
                       (if val
                           (push val stack)
                           ;; Forward reference: create placeholder
                           (let ((placeholder (gensym "FWD-")))
                             (setf (gethash placeholder forward-refs) id)
                             (setf has-forward-refs t)
                             (push placeholder stack))))))
                  ;; Unknown opcode
                  (t (warn "flat-image-deserialize: unknown opcode ~S" opcode)))))))
    (let ((result (first stack)))
      (if has-forward-refs
          (flat-image-backpatch result defs forward-refs)
          result))))

;;; ---- Binary image format ----

;;; Symbol table: collect, write, read

(defun bin-collect-symbols (data)
  "Walk DATA collecting all unique symbols. Returns (values symbol-vector symbol-to-index-ht).
DATA is the 7-element image list. Uses explicit work stack to avoid CL stack overflow."
  (let ((seen (make-hash-table :test 'eq))
        (symbols (make-array 256 :adjustable t :fill-pointer 0))
        (work-stack (make-array 1024 :adjustable t :fill-pointer 0)))
    (labels ((add-sym (s)
               (unless (gethash s seen)
                 (setf (gethash s seen) (fill-pointer symbols))
                 (vector-push-extend s symbols)))
             (wpush (obj) (vector-push-extend obj work-stack))
             (walk ()
               (loop while (> (fill-pointer work-stack) 0) do
                     (let ((obj (vector-pop work-stack)))
                       (cond
                         ((symbolp obj) (add-sym obj))
                         ((consp obj)
                          (unless (gethash obj seen)
                            (setf (gethash obj seen) t)
                            (wpush (cdr obj))
                            (wpush (car obj))))
                         ((and (vectorp obj) (not (stringp obj)))
                          (unless (gethash obj seen)
                            (setf (gethash obj seen) t)
                            (loop for i from (1- (length obj)) downto 0
                                  do (wpush (aref obj i))))))))))
      (wpush data)
      (walk)
      ;; Reset seen to be symbol-to-index only
      (let ((sym-to-idx (make-hash-table :test 'eq)))
        (loop for i below (fill-pointer symbols)
              do (setf (gethash (aref symbols i) sym-to-idx) i))
        (values symbols sym-to-idx)))))

(defun bin-write-symbol-table (symbols stream)
  "Write SYMBOLS vector to binary STREAM."
  (loop for sym across symbols do
        (cond
          ;; Uninterned (gensym)
          ((null (symbol-package sym))
           (let ((bytes (sb-ext:string-to-octets (symbol-name sym) :external-format :utf-8)))
             (bin-write-u8 +pkg-uninterned+ stream)
             (bin-write-u16-be (length bytes) stream)
             (write-sequence bytes stream)))
          ;; Keyword
          ((eq (symbol-package sym) (find-package :keyword))
           (let ((bytes (sb-ext:string-to-octets (symbol-name sym) :external-format :utf-8)))
             (bin-write-u8 +pkg-keyword+ stream)
             (bin-write-u16-be (length bytes) stream)
             (write-sequence bytes stream)))
          ;; ECE package
          ((multiple-value-bind (found-sym status)
               (find-symbol (symbol-name sym) :ece)
             (and status (eq found-sym sym)))
           (let ((bytes (sb-ext:string-to-octets (symbol-name sym) :external-format :utf-8)))
             (bin-write-u8 +pkg-ece+ stream)
             (bin-write-u16-be (length bytes) stream)
             (write-sequence bytes stream)))
          ;; CL package
          ((multiple-value-bind (found-sym status)
               (find-symbol (symbol-name sym) :cl)
             (and status (eq found-sym sym)))
           (let ((bytes (sb-ext:string-to-octets (symbol-name sym) :external-format :utf-8)))
             (bin-write-u8 +pkg-cl+ stream)
             (bin-write-u16-be (length bytes) stream)
             (write-sequence bytes stream)))
          ;; Other package
          (t
           (let ((name-bytes (sb-ext:string-to-octets (symbol-name sym) :external-format :utf-8))
                 (pkg-bytes (sb-ext:string-to-octets (package-name (symbol-package sym)) :external-format :utf-8)))
             (bin-write-u8 +pkg-other+ stream)
             (bin-write-u16-be (length pkg-bytes) stream)
             (write-sequence pkg-bytes stream)
             (bin-write-u16-be (length name-bytes) stream)
             (write-sequence name-bytes stream))))))

(defun bin-read-symbol-table (count stream)
  "Read COUNT symbol entries from STREAM. Returns index-to-symbol vector."
  (let ((symbols (make-array count)))
    (loop for i below count do
          (let ((pkg-tag (bin-read-u8 stream)))
            (case pkg-tag
              (#.+pkg-ece+
               (let* ((len (bin-read-u16-be stream))
                      (bytes (make-array len :element-type '(unsigned-byte 8))))
                 (read-sequence bytes stream)
                 (setf (aref symbols i)
                       (intern (sb-ext:octets-to-string bytes :external-format :utf-8) :ece))))
              (#.+pkg-keyword+
               (let* ((len (bin-read-u16-be stream))
                      (bytes (make-array len :element-type '(unsigned-byte 8))))
                 (read-sequence bytes stream)
                 (setf (aref symbols i)
                       (intern (sb-ext:octets-to-string bytes :external-format :utf-8) :keyword))))
              (#.+pkg-cl+
               (let* ((len (bin-read-u16-be stream))
                      (bytes (make-array len :element-type '(unsigned-byte 8))))
                 (read-sequence bytes stream)
                 (setf (aref symbols i)
                       (intern (sb-ext:octets-to-string bytes :external-format :utf-8) :cl))))
              (#.+pkg-uninterned+
               (let* ((len (bin-read-u16-be stream))
                      (bytes (make-array len :element-type '(unsigned-byte 8))))
                 (read-sequence bytes stream)
                 (setf (aref symbols i)
                       (make-symbol (sb-ext:octets-to-string bytes :external-format :utf-8)))))
              (#.+pkg-other+
               (let* ((pkg-len (bin-read-u16-be stream))
                      (pkg-bytes (make-array pkg-len :element-type '(unsigned-byte 8))))
                 (read-sequence pkg-bytes stream)
                 (let* ((name-len (bin-read-u16-be stream))
                        (name-bytes (make-array name-len :element-type '(unsigned-byte 8))))
                   (read-sequence name-bytes stream)
                   (let ((pkg-name (sb-ext:octets-to-string pkg-bytes :external-format :utf-8))
                         (sym-name (sb-ext:octets-to-string name-bytes :external-format :utf-8)))
                     (setf (aref symbols i)
                           (intern sym-name (or (find-package pkg-name)
                                                (make-package pkg-name :use nil)))))))))))
    symbols))

;;; Binary instruction serializer

(defun bin-register-id (name)
  "Get register ID for NAME."
  (or (gethash name *register-to-id*)
      (error "Unknown register: ~S" name)))

(defun bin-operation-id (name)
  "Get operation ID for NAME."
  (or (gethash name *operation-to-id*)
      (error "Unknown operation: ~S" name)))

(defun bin-write-operand (operand sym-to-idx stream)
  "Write a single operand (reg, const, or label) for an op instruction."
  (cond
    ((and (consp operand) (eq (car operand) 'reg))
     (bin-write-u8 +operand-reg+ stream)
     (bin-write-u8 (bin-register-id (cadr operand)) stream))
    ((and (consp operand) (eq (car operand) 'const))
     (bin-write-u8 +operand-const+ stream)
     (bin-serialize-data-value (cadr operand) sym-to-idx stream))
    ((and (consp operand) (eq (car operand) 'label))
     (bin-write-u8 +operand-label+ stream)
     (bin-serialize-data-value (cadr operand) sym-to-idx stream))
    (t (error "Unknown operand form: ~S" operand))))

(defun bin-serialize-instruction (instr sym-to-idx stream)
  "Encode a single register machine instruction in binary format."
  (case (car instr)
    (assign
     (bin-write-u8 +bin-assign+ stream)
     (bin-write-u8 (bin-register-id (cadr instr)) stream)
     (let ((source (caddr instr)))
       (cond
         ;; (assign reg (const val))
         ((and (consp source) (eq (car source) 'const))
          (bin-write-u8 +src-const+ stream)
          (bin-serialize-data-value (cadr source) sym-to-idx stream))
         ;; (assign reg (reg src))
         ((and (consp source) (eq (car source) 'reg))
          (bin-write-u8 +src-reg+ stream)
          (bin-write-u8 (bin-register-id (cadr source)) stream))
         ;; (assign reg (op name) operands...)
         ((and (consp source) (eq (car source) 'op))
          (bin-write-u8 +src-op+ stream)
          (bin-write-u8 (bin-operation-id (cadr source)) stream)
          (let ((operands (cdddr instr)))
            (bin-write-u8 (length operands) stream)
            (dolist (op operands)
              (bin-write-operand op sym-to-idx stream))))
         ;; (assign reg (label name))
         ((and (consp source) (eq (car source) 'label))
          (bin-write-u8 +src-label+ stream)
          (bin-serialize-data-value (cadr source) sym-to-idx stream))
         (t (error "Unknown assign source: ~S" source)))))
    (test
     (bin-write-u8 +bin-test+ stream)
     (let ((op-spec (cadr instr)))
       (bin-write-u8 (bin-operation-id (cadr op-spec)) stream)
       (let ((operands (cddr instr)))
         (bin-write-u8 (length operands) stream)
         (dolist (op operands)
           (bin-write-operand op sym-to-idx stream)))))
    (perform
     (bin-write-u8 +bin-perform+ stream)
     (let ((op-spec (cadr instr)))
       (bin-write-u8 (bin-operation-id (cadr op-spec)) stream)
       (let ((operands (cddr instr)))
         (bin-write-u8 (length operands) stream)
         (dolist (op operands)
           (bin-write-operand op sym-to-idx stream)))))
    (save
     (bin-write-u8 +bin-save+ stream)
     (bin-write-u8 (bin-register-id (cadr instr)) stream))
    (restore
     (bin-write-u8 +bin-restore+ stream)
     (bin-write-u8 (bin-register-id (cadr instr)) stream))
    (goto
     (bin-write-u8 +bin-goto+ stream)
     (let ((dest (cadr instr)))
       (cond
         ((and (consp dest) (eq (car dest) 'label))
          (bin-write-u8 +target-label+ stream)
          (bin-serialize-data-value (cadr dest) sym-to-idx stream))
         ((and (consp dest) (eq (car dest) 'reg))
          (bin-write-u8 +target-reg+ stream)
          (bin-write-u8 (bin-register-id (cadr dest)) stream))
         (t (error "Unknown goto target: ~S" dest)))))
    (branch
     (bin-write-u8 +bin-branch+ stream)
     (let ((dest (cadr instr)))
       (bin-serialize-data-value (cadr dest) sym-to-idx stream)))
    (t (error "Unknown instruction type: ~S" (car instr)))))

;;; Binary data serializer (stack-machine encoding for arbitrary values)
;;; Fully iterative (work-stack) to handle circular/deeply nested structures.

(defun bin-serialize-data-atom (obj sym-to-idx stream)
  "Emit a single atom in binary data format. For use by the work-stack serializer."
  (cond
    ((scheme-false-p obj) (bin-write-u8 +data-false+ stream))
    ((null obj) (bin-write-u8 +data-nil+ stream))
    ((eq obj t) (bin-write-u8 +data-t+ stream))
    ((integerp obj)
     (bin-write-u8 +data-int+ stream)
     (bin-write-i64-be obj stream))
    ((floatp obj)
     (bin-write-u8 +data-float+ stream)
     (bin-write-f64-be obj stream))
    ((characterp obj)
     (bin-write-u8 +data-char+ stream)
     (bin-write-u32-be (char-code obj) stream))
    ((keywordp obj)
     (bin-write-u8 +data-kwd+ stream)
     (bin-write-u16-be (gethash obj sym-to-idx) stream))
    ((and (symbolp obj) (null (symbol-package obj)))
     (bin-write-u8 +data-gsym+ stream)
     (bin-write-u16-be (gethash obj sym-to-idx) stream))
    ((symbolp obj)
     (bin-write-u8 +data-sym+ stream)
     (bin-write-u16-be (gethash obj sym-to-idx) stream))
    (t (warn "bin-serialize-data-atom: unhandled type ~A for ~S" (type-of obj) obj)
       (bin-write-u8 +data-nil+ stream))))

(defun bin-proper-list-p (start def-ids)
  "If START is a proper list with no shared internal cdrs, return its length. Otherwise nil."
  (let ((len 0))
    (do ((cur start (cdr cur)))
        ((null cur) len)
      (unless (consp cur) (return nil))
      ;; If a cdr-spine cons (after the head) is shared, can't use list opcode
      (when (and (> len 0) (gethash cur def-ids))
        (return nil))
      (incf len))))

(defun bin-serialize-data (data sym-to-idx stream)
  "Serialize DATA to binary STREAM with shared reference tracking.
Fully iterative using a work stack to avoid stack overflow on circular structures."
  (let* ((counts (flat-image-count-refs data))
         (def-ids (make-hash-table :test 'eq))
         (emitted (make-hash-table :test 'eq))
         (next-id 0)
         (work-stack (make-array 1024 :adjustable t :fill-pointer 0)))
    ;; Assign def IDs to multiply-referenced objects
    (maphash (lambda (obj count)
               (when (> count 1)
                 (setf (gethash obj def-ids) next-id)
                 (incf next-id)))
             counts)
    (flet ((wpush (item) (vector-push-extend item work-stack))
           (wpop () (vector-pop work-stack)))
      (labels
          ((schedule-emit (obj) (wpush (cons :emit obj)))
           (mark-emitted (obj)
             (let ((id (gethash obj def-ids)))
               (when id (setf (gethash obj emitted) t))))
           (schedule-cons-structure (start)
             (mark-emitted start)
             (let ((list-len (bin-proper-list-p start def-ids)))
               (if list-len
                   ;; Proper list
                   (progn
                     (when (gethash start def-ids) (wpush (cons :def start)))
                     (wpush (cons :list list-len))
                     (let ((rev nil))
                       (do ((cur start (cdr cur))) ((null cur))
                         (push (car cur) rev))
                       (dolist (item rev) (schedule-emit item))))
                   ;; Dotted/improper chain — emit as individual conses
                   (let ((cars nil) (n 0) (final-cdr nil))
                     (do ((cur start)) (nil)
                       (push (car cur) cars)
                       (incf n)
                       (let ((next (cdr cur)))
                         (cond
                           ((null next) (setf final-cdr nil) (return))
                           ((not (consp next)) (setf final-cdr next) (return))
                           ((gethash next def-ids) (setf final-cdr next) (return))
                           (t (setf cur next)))))
                     (when (gethash start def-ids) (wpush (cons :def start)))
                     (wpush (cons :conses n))
                     (schedule-emit final-cdr)
                     (dolist (car-val cars) (schedule-emit car-val)))))))
        ;; Initialize
        (schedule-emit data)
        ;; Process work stack
        (loop while (> (fill-pointer work-stack) 0) do
              (let* ((item (wpop))
                     (tag (car item))
                     (val (cdr item)))
                (case tag
                  (:emit
                   (cond
                     ;; Already emitted (shared): back-reference
                     ((gethash val emitted)
                      (bin-write-u8 +data-ref+ stream)
                      (bin-write-u16-be (gethash val def-ids) stream))
                     ;; String
                     ((stringp val)
                      (bin-write-u8 +data-str+ stream)
                      (let ((bytes (sb-ext:string-to-octets val :external-format :utf-8)))
                        (bin-write-u32-be (length bytes) stream)
                        (write-sequence bytes stream))
                      (mark-emitted val)
                      (let ((id (gethash val def-ids)))
                        (when id
                          (bin-write-u8 +data-def+ stream)
                          (bin-write-u16-be id stream))))
                     ;; Vector (non-string)
                     ((and (vectorp val) (not (stringp val)))
                      (mark-emitted val)
                      (when (gethash val def-ids) (wpush (cons :def val)))
                      (wpush (cons :vec (length val)))
                      (loop for i from (1- (length val)) downto 0
                            do (schedule-emit (aref val i))))
                     ;; Uninterned symbol (gensym) — needs def/ref like strings
                     ((and (symbolp val) (null (symbol-package val)))
                      (bin-write-u8 +data-gsym+ stream)
                      (bin-write-u16-be (gethash val sym-to-idx) stream)
                      (mark-emitted val)
                      (let ((id (gethash val def-ids)))
                        (when id
                          (bin-write-u8 +data-def+ stream)
                          (bin-write-u16-be id stream))))
                     ;; Cons cell
                     ((consp val) (schedule-cons-structure val))
                     ;; Atoms
                     (t (bin-serialize-data-atom val sym-to-idx stream))))
                  (:def
                   (bin-write-u8 +data-def+ stream)
                      (bin-write-u16-be (gethash val def-ids) stream))
                  (:list
                   (bin-write-u8 +data-list+ stream)
                   (bin-write-u16-be val stream))
                  (:vec
                   (bin-write-u8 +data-vec+ stream)
                   (bin-write-u16-be val stream))
                  (:conses
                   (loop repeat val do (bin-write-u8 +data-cons+ stream))))))))))

;;; bin-serialize-data-value — simple recursive version for inline const values
;;; in instructions. These are always small atoms/lists, no circular structures.

(defun bin-serialize-data-value (obj sym-to-idx stream)
  "Serialize a single (small) value for inline instruction operands."
  (cond
    ((scheme-false-p obj) (bin-write-u8 +data-false+ stream))
    ((null obj) (bin-write-u8 +data-nil+ stream))
    ((eq obj t) (bin-write-u8 +data-t+ stream))
    ((integerp obj) (bin-write-u8 +data-int+ stream) (bin-write-i64-be obj stream))
    ((floatp obj) (bin-write-u8 +data-float+ stream) (bin-write-f64-be obj stream))
    ((characterp obj) (bin-write-u8 +data-char+ stream) (bin-write-u32-be (char-code obj) stream))
    ((stringp obj)
     (bin-write-u8 +data-str+ stream)
     (let ((bytes (sb-ext:string-to-octets obj :external-format :utf-8)))
       (bin-write-u32-be (length bytes) stream)
       (write-sequence bytes stream)))
    ((keywordp obj) (bin-write-u8 +data-kwd+ stream) (bin-write-u16-be (gethash obj sym-to-idx) stream))
    ((and (symbolp obj) (null (symbol-package obj)))
     (bin-write-u8 +data-gsym+ stream) (bin-write-u16-be (gethash obj sym-to-idx) stream))
    ((symbolp obj) (bin-write-u8 +data-sym+ stream) (bin-write-u16-be (gethash obj sym-to-idx) stream))
    ((consp obj)
     ;; Tree-order encoding for inline consts: tag first, then children
     ;; Check for proper list (list-length errors on dotted lists, so catch it)
     (let ((len (ignore-errors (list-length obj))))
       (cond
         (len
          ;; Proper list
          (bin-write-u8 +data-list+ stream)
          (bin-write-u16-be len stream)
          (dolist (item obj)
            (bin-serialize-data-value item sym-to-idx stream)))
         (t
          ;; Dotted pair / improper list — serialize as chain of cons cells
          (bin-write-u8 +data-cons+ stream)
          (bin-serialize-data-value (car obj) sym-to-idx stream)
          (bin-serialize-data-value (cdr obj) sym-to-idx stream)))))
    (t (warn "bin-serialize-data-value: unhandled ~S" obj) (bin-write-u8 +data-nil+ stream))))

;;; In-memory byte buffer stream for section serialization

(defclass byte-buffer-stream (sb-gray:fundamental-binary-output-stream)
  ((buffer :initform (make-array 4096 :element-type '(unsigned-byte 8)
                                 :adjustable t :fill-pointer 0)
           :accessor bbs-buffer)))

(defmethod sb-gray:stream-write-byte ((stream byte-buffer-stream) byte)
  (vector-push-extend byte (bbs-buffer stream))
  byte)

(defmethod sb-gray:stream-write-sequence ((stream byte-buffer-stream) seq &optional (start 0) end)
  (let ((end (or end (length seq))))
    (loop for i from start below end
          do (vector-push-extend (aref seq i) (bbs-buffer stream))))
  seq)

(defun make-byte-buffer-stream ()
  "Create an in-memory binary output stream."
  (make-instance 'byte-buffer-stream))

(defun byte-buffer-contents (stream)
  "Get the accumulated bytes from a byte-buffer-stream as a simple array."
  (let* ((buf (bbs-buffer stream))
         (len (fill-pointer buf))
         (result (make-array len :element-type '(unsigned-byte 8))))
    (replace result buf)
    result))

;;; Full binary image serializer

(defun binary-image-serialize (data stream)
  "Serialize 7-element image DATA to binary STREAM."
  (let ((source-list (first data))
        (label-alist (second data))
        (env (third data))
        (macro-alist (fourth data))
        (name-alist (fifth data))
        (param-alist (sixth data))
        (param-counter (seventh data)))
    ;; Collect all symbols from the entire image data
    (multiple-value-bind (symbols sym-to-idx)
        (bin-collect-symbols data)
      ;; Build section byte vectors
      (let* ((section-data
              (list
               ;; Section 0: Instructions
               (cons +section-instructions+
                     (let ((buf (make-byte-buffer-stream)))
                       (bin-write-u32-be (length source-list) buf)
                       (dolist (instr source-list)
                         (bin-serialize-instruction instr sym-to-idx buf))
                       (byte-buffer-contents buf)))
               ;; Section 1: Labels
               (cons +section-labels+
                     (let ((buf (make-byte-buffer-stream)))
                       (bin-serialize-data label-alist sym-to-idx buf)
                       (byte-buffer-contents buf)))
               ;; Section 2: Environment
               (cons +section-env+
                     (let ((buf (make-byte-buffer-stream)))
                       (bin-serialize-data env sym-to-idx buf)
                       (byte-buffer-contents buf)))
               ;; Section 3: Macros
               (cons +section-macros+
                     (let ((buf (make-byte-buffer-stream)))
                       (bin-serialize-data macro-alist sym-to-idx buf)
                       (byte-buffer-contents buf)))
               ;; Section 4: Procedure names
               (cons +section-names+
                     (let ((buf (make-byte-buffer-stream)))
                       (bin-serialize-data name-alist sym-to-idx buf)
                       (byte-buffer-contents buf)))
               ;; Section 5: Parameters
               (cons +section-params+
                     (let ((buf (make-byte-buffer-stream)))
                       (bin-serialize-data param-alist sym-to-idx buf)
                       (byte-buffer-contents buf)))
               ;; Section 6: Parameter counter
               (cons +section-param-counter+
                     (let ((buf (make-byte-buffer-stream)))
                       (bin-serialize-data param-counter sym-to-idx buf)
                       (byte-buffer-contents buf)))))
             (num-sections (length section-data)))
        ;; Write header
        (write-byte (char-code #\E) stream)
        (write-byte (char-code #\C) stream)
        (write-byte (char-code #\E) stream)
        (bin-write-u8 1 stream)  ; version
        (bin-write-u32-be (length symbols) stream)
        (bin-write-u32-be num-sections stream)
        ;; Write symbol table
        (bin-write-symbol-table symbols stream)
        ;; Write section directory
        ;; Calculate offsets: header(12) + symbol-table + directory, then sections sequentially
        (let ((dir-size (* num-sections 9)))  ; 1 + 4 + 4 per entry
          (declare (ignore dir-size))
          ;; First compute all offsets (relative to start of section data area)
          (let ((offset 0))
            (dolist (entry section-data)
              (let ((bytes (cdr entry)))
                (bin-write-u8 (car entry) stream)
                (bin-write-u32-be offset stream)
                (bin-write-u32-be (length bytes) stream)
                (incf offset (length bytes))))))
        ;; Write section bodies
        (dolist (entry section-data)
          (write-sequence (cdr entry) stream))))))

;;; Binary image deserializer

(defun bin-deserialize-data-value (stream symbols)
  "Deserialize a single value from binary STREAM using SYMBOLS table.
Tree-order encoding: tag first, then children (for inline instruction constants)."
  (let ((tag (bin-read-u8 stream)))
    (case tag
      (#.+data-nil+ nil)
      (#.+data-t+ t)
      (#.+data-false+ *scheme-false*)
      (#.+data-int+ (bin-read-i64-be stream))
      (#.+data-float+ (bin-read-f64-be stream))
      (#.+data-char+ (code-char (bin-read-u32-be stream)))
      (#.+data-sym+ (aref symbols (bin-read-u16-be stream)))
      (#.+data-kwd+ (aref symbols (bin-read-u16-be stream)))
      (#.+data-gsym+ (aref symbols (bin-read-u16-be stream)))
      (#.+data-str+
       (let* ((len (bin-read-u32-be stream))
              (bytes (make-array len :element-type '(unsigned-byte 8))))
         (read-sequence bytes stream)
         (sb-ext:octets-to-string bytes :external-format :utf-8)))
      (#.+data-cons+
       ;; Tree order: tag, then car, then cdr
       (let ((a (bin-deserialize-data-value stream symbols))
             (b (bin-deserialize-data-value stream symbols)))
         (cons a b)))
      (#.+data-list+
       (let* ((n (bin-read-u16-be stream)))
         (loop repeat n collect (bin-deserialize-data-value stream symbols))))
      (#.+data-vec+
       (let* ((n (bin-read-u16-be stream)))
         (let ((v (make-array n)))
           (loop for i below n
                 do (setf (aref v i) (bin-deserialize-data-value stream symbols)))
           v)))
      (t (error "bin-deserialize-data-value: unknown tag ~X" tag)))))

(defun bin-deserialize-data-stream (stream symbols end-pos)
  "Deserialize data from binary STREAM until END-POS, using SYMBOLS table.
Returns the final value on the stack.
Supports forward references via placeholder gensyms and backpatching."
  (let ((stack nil)
        (defs (make-hash-table))
        (forward-refs (make-hash-table :test 'eq))
        (has-forward-refs nil))
    (loop while (< (file-position stream) end-pos) do
          (let ((tag (bin-read-u8 stream)))
            (case tag
              (#.+data-nil+ (push nil stack))
              (#.+data-t+ (push t stack))
              (#.+data-false+ (push *scheme-false* stack))
              (#.+data-int+ (push (bin-read-i64-be stream) stack))
              (#.+data-float+ (push (bin-read-f64-be stream) stack))
              (#.+data-char+ (push (code-char (bin-read-u32-be stream)) stack))
              (#.+data-sym+ (push (aref symbols (bin-read-u16-be stream)) stack))
              (#.+data-kwd+ (push (aref symbols (bin-read-u16-be stream)) stack))
              (#.+data-gsym+ (push (aref symbols (bin-read-u16-be stream)) stack))
              (#.+data-str+
               (let* ((len (bin-read-u32-be stream))
                      (bytes (make-array len :element-type '(unsigned-byte 8))))
                 (read-sequence bytes stream)
                 (push (sb-ext:octets-to-string bytes :external-format :utf-8) stack)))
              (#.+data-cons+
               (let ((b (pop stack)) (a (pop stack)))
                 (push (cons a b) stack)))
              (#.+data-list+
               (let* ((n (bin-read-u16-be stream))
                      (items (make-list n)))
                 (loop for i from (1- n) downto 0
                       do (setf (nth i items) (pop stack)))
                 (push items stack)))
              (#.+data-vec+
               (let* ((n (bin-read-u16-be stream))
                      (v (make-array n)))
                 (loop for i from (1- n) downto 0
                       do (setf (aref v i) (pop stack)))
                 (push v stack)))
              (#.+data-def+
               (let ((id (bin-read-u16-be stream)))
                 (setf (gethash id defs) (first stack))))
              (#.+data-ref+
               (let ((id (bin-read-u16-be stream)))
                 (let ((val (gethash id defs)))
                   (if val
                       (push val stack)
                       ;; Forward reference: create placeholder
                       (let ((placeholder (gensym "FWD-")))
                         (setf (gethash placeholder forward-refs) id)
                         (setf has-forward-refs t)
                         (push placeholder stack))))))
              (t (error "bin-deserialize-data-stream: unknown tag ~X" tag)))))
    (let ((result (first stack)))
      (if has-forward-refs
          (flat-image-backpatch result defs forward-refs)
          result))))

(defun bin-read-operand (stream symbols)
  "Read a single instruction operand. Returns (reg X), (const X), or (label X)."
  (let ((type (bin-read-u8 stream)))
    (case type
      (#.+operand-reg+
       (list 'reg (aref *id-to-register* (bin-read-u8 stream))))
      (#.+operand-const+
       (list 'const (bin-deserialize-data-value stream symbols)))
      (#.+operand-label+
       (list 'label (bin-deserialize-data-value stream symbols)))
      (t (error "Unknown operand type: ~X" type)))))

(defun bin-deserialize-instruction (stream symbols)
  "Decode one instruction from binary STREAM. Returns (values resolved source).
RESOLVED has op-fn with function pointers; SOURCE has op with symbol names."
  (let ((opcode (bin-read-u8 stream)))
    (case opcode
      (#.+bin-assign+
       (let* ((reg (aref *id-to-register* (bin-read-u8 stream)))
              (src-type (bin-read-u8 stream)))
         (case src-type
           (#.+src-const+
            (let ((val (bin-deserialize-data-value stream symbols)))
              (let ((instr `(assign ,reg (const ,val))))
                (values instr instr))))
           (#.+src-reg+
            (let ((src-reg (aref *id-to-register* (bin-read-u8 stream))))
              (let ((instr `(assign ,reg (reg ,src-reg))))
                (values instr instr))))
           (#.+src-op+
            (let* ((op-id (bin-read-u8 stream))
                   (op-name (aref *id-to-operation* op-id))
                   (op-fn (get-operation op-name))
                   (n-operands (bin-read-u8 stream))
                   (operands (loop repeat n-operands
                                   collect (bin-read-operand stream symbols))))
              (values `(assign ,reg (op-fn ,op-fn) ,@operands)
                      `(assign ,reg (op ,op-name) ,@operands))))
           (#.+src-label+
            (let ((label (bin-deserialize-data-value stream symbols)))
              (let ((instr `(assign ,reg (label ,label))))
                (values instr instr))))
           (t (error "Unknown assign source type: ~X" src-type)))))
      (#.+bin-test+
       (let* ((op-id (bin-read-u8 stream))
              (op-name (aref *id-to-operation* op-id))
              (op-fn (get-operation op-name))
              (n-operands (bin-read-u8 stream))
              (operands (loop repeat n-operands
                              collect (bin-read-operand stream symbols))))
         (values `(test (op-fn ,op-fn) ,@operands)
                 `(test (op ,op-name) ,@operands))))
      (#.+bin-perform+
       (let* ((op-id (bin-read-u8 stream))
              (op-name (aref *id-to-operation* op-id))
              (op-fn (get-operation op-name))
              (n-operands (bin-read-u8 stream))
              (operands (loop repeat n-operands
                              collect (bin-read-operand stream symbols))))
         (values `(perform (op-fn ,op-fn) ,@operands)
                 `(perform (op ,op-name) ,@operands))))
      (#.+bin-save+
       (let* ((reg (aref *id-to-register* (bin-read-u8 stream)))
              (instr `(save ,reg)))
         (values instr instr)))
      (#.+bin-restore+
       (let* ((reg (aref *id-to-register* (bin-read-u8 stream)))
              (instr `(restore ,reg)))
         (values instr instr)))
      (#.+bin-goto+
       (let ((target-type (bin-read-u8 stream)))
         (case target-type
           (#.+target-label+
            (let ((label (bin-deserialize-data-value stream symbols)))
              (let ((instr `(goto (label ,label))))
                (values instr instr))))
           (#.+target-reg+
            (let ((reg (aref *id-to-register* (bin-read-u8 stream))))
              (let ((instr `(goto (reg ,reg))))
                (values instr instr))))
           (t (error "Unknown goto target type: ~X" target-type)))))
      (#.+bin-branch+
       (let ((label (bin-deserialize-data-value stream symbols)))
         (let ((instr `(branch (label ,label))))
           (values instr instr))))
      (t (error "Unknown instruction opcode: ~X" opcode)))))

;;; Full binary image deserializer

(defun binary-image-deserialize (stream)
  "Deserialize a binary format image from STREAM.
Returns (values) and directly sets global state.
Builds resolved instructions (with op-fn) directly — no resolve-operations pass needed."
  ;; Read header (magic already consumed for format detection)
  (let ((version (bin-read-u8 stream))
        (sym-count (bin-read-u32-be stream))
        (section-count (bin-read-u32-be stream)))
    (declare (ignore version))
    ;; Read symbol table
    (let ((symbols (bin-read-symbol-table sym-count stream)))
      ;; Read section directory
      (let ((sections (loop repeat section-count
                            collect (let ((type (bin-read-u8 stream))
                                          (offset (bin-read-u32-be stream))
                                          (length (bin-read-u32-be stream)))
                                      (list type offset length)))))
        ;; Record the start of section data area
        (let ((data-start (file-position stream)))
          ;; Process each section
          (dolist (sec sections)
            (destructuring-bind (type offset length) sec
              (file-position stream (+ data-start offset))
              (let ((end-pos (+ data-start offset length)))
                (case type
                  (#.+section-instructions+
                   (let* ((n (bin-read-u32-be stream))
                          (exec-vec (make-array n :adjustable t :fill-pointer n))
                          (src-vec (make-array n :adjustable t :fill-pointer n)))
                     (loop for i below n do
                           (multiple-value-bind (resolved source)
                               (bin-deserialize-instruction stream symbols)
                             (setf (aref exec-vec i) resolved)
                             (setf (aref src-vec i) source)))
                     (setf *global-instruction-vector* exec-vec)
                     (setf *global-instruction-source* src-vec)))
                  (#.+section-labels+
                   (let ((alist (bin-deserialize-data-stream stream symbols end-pos)))
                     (setf *global-label-table* (alist-to-hash-table alist :test 'eq))))
                  (#.+section-env+
                   (setf *global-env*
                         (bin-deserialize-data-stream stream symbols end-pos)))
                  (#.+section-macros+
                   (let ((alist (bin-deserialize-data-stream stream symbols end-pos)))
                     (setf *compile-time-macros* (alist-to-hash-table alist :test 'eq))))
                  (#.+section-names+
                   (let ((alist (bin-deserialize-data-stream stream symbols end-pos)))
                     (setf *procedure-name-table* (alist-to-hash-table alist))))
                  (#.+section-params+
                   (let ((alist (bin-deserialize-data-stream stream symbols end-pos)))
                     (when alist
                       (setf *parameter-table* (alist-to-hash-table alist :test 'eq)))))
                  (#.+section-param-counter+
                   (let ((val (bin-deserialize-data-stream stream symbols end-pos)))
                     (when val
                       (setf *parameter-counter* val))))
                  (t (warn "binary-image-deserialize: unknown section type ~X" type)))))))))))

;;; Disassembler

(defun ece-disassemble-image (filename &optional (output *standard-output*))
  "Read a binary image file and produce human-readable instruction listing."
  (with-open-file (stream filename :direction :input :element-type '(unsigned-byte 8))
    ;; Read and verify magic
    (let ((m0 (read-byte stream))
          (m1 (read-byte stream))
          (m2 (read-byte stream)))
      (unless (and (= m0 (char-code #\E)) (= m1 (char-code #\C)) (= m2 (char-code #\E)))
        (error "Not a binary ECE image: ~A" filename)))
    (let ((version (bin-read-u8 stream))
          (sym-count (bin-read-u32-be stream))
          (section-count (bin-read-u32-be stream)))
      ;; Read symbol table
      (let ((symbols (bin-read-symbol-table sym-count stream)))
        ;; Read section directory
        (let ((sections (loop repeat section-count
                              collect (list (bin-read-u8 stream)
                                            (bin-read-u32-be stream)
                                            (bin-read-u32-be stream)))))
          (let ((data-start (file-position stream))
                (instructions nil)
                (labels-alist nil)
                (env nil)
                (instr-count 0))
            ;; Process sections
            (dolist (sec sections)
              (destructuring-bind (type offset length) sec
                (file-position stream (+ data-start offset))
                (let ((end-pos (+ data-start offset length)))
                  (case type
                    (#.+section-instructions+
                     (setf instr-count (bin-read-u32-be stream))
                     (setf instructions
                           (loop repeat instr-count
                                 collect (multiple-value-bind (resolved source)
                                             (bin-deserialize-instruction stream symbols)
                                           (declare (ignore resolved))
                                           source))))
                    (#.+section-labels+
                     (setf labels-alist
                           (bin-deserialize-data-stream stream symbols end-pos)))
                    (#.+section-env+
                     (setf env
                           (bin-deserialize-data-stream stream symbols end-pos)))))))
            ;; Print header
            (format output ";; ECE Image v~D — ~D instructions, ~D symbols~%"
                    version instr-count sym-count)
            (format output ";;~%")
            ;; Build PC → label reverse map
            (let ((pc-to-labels (make-hash-table)))
              (dolist (pair labels-alist)
                (push (car pair) (gethash (cdr pair) pc-to-labels)))
              ;; Print instructions
              (format output ";; === Instructions ===~%")
              (format output ";;  PC    Instruction~%")
              (format output ";; ----  ------------------------------------------------~%")
              (loop for instr in instructions
                    for pc from 0 do
                    ;; Print labels at this PC
                    (let ((lbls (gethash pc pc-to-labels)))
                      (when lbls
                        (dolist (l (reverse lbls))
                          (format output ";;~%")
                          (format output "~A:~%" l))))
                    (format output ";;~4,' D  ~S~%" pc instr)))
            ;; Print label summary
            (format output ";;~%;; === Labels (~D) ===~%" (length labels-alist))
            (dolist (pair (sort (copy-list labels-alist) #'< :key #'cdr))
              (format output ";;   ~30A → PC ~D~%" (car pair) (cdr pair)))
            ;; Print environment summary
            (format output ";;~%;; === Environment ===~%")
            (when env
              (let ((frame (car env)))
                (when (consp frame)
                  (loop for var in (car frame)
                        for val in (cdr frame) do
                        (format output ";;   ~30A → ~A~%" var
                                (cond
                                  ((and (consp val) (eq (car val) 'compiled-procedure))
                                   (format nil "<compiled-procedure @~D>" (cadr val)))
                                  ((and (consp val) (eq (car val) 'primitive))
                                   (format nil "<primitive ~A>" (cadr val)))
                                  ((and (consp val) (eq (car val) 'continuation))
                                   "<continuation>")
                                  ((stringp val) (format nil "~S" val))
                                  (t (let ((s (format nil "~S" val)))
                                       (if (> (length s) 50)
                                           (concatenate 'string (subseq s 0 47) "...")
                                           s)))))))))))))))

;;; ece-load-image / ece-%write-image — updated for binary format

(defun ece-%write-image (filename data)
  "Serialize DATA to FILENAME in binary image format.
DATA should be the 7-element image format list."
  (with-open-file (out filename :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create
                       :element-type '(unsigned-byte 8))
    (binary-image-serialize data out))
  t)

(defun ece-load-image (filename)
  "Load ECE system state from FILENAME.
Auto-detects binary vs text format by checking for 'ECE' magic header."
  (with-open-file (stream filename :direction :input :element-type '(unsigned-byte 8))
    (let ((b0 (read-byte stream))
          (b1 (read-byte stream))
          (b2 (read-byte stream)))
      (if (and (= b0 (char-code #\E)) (= b1 (char-code #\C)) (= b2 (char-code #\E)))
          ;; Binary format
          (binary-image-deserialize stream)
          ;; Text format fallback — reopen as character stream
          (with-open-file (text-stream filename :direction :input)
            (let ((data (flat-image-deserialize text-stream)))
              (let ((source-list (first data))
                    (label-alist (second data))
                    (env (third data))
                    (macro-alist (fourth data))
                    (name-alist (fifth data))
                    (param-alist (sixth data))
                    (param-counter (seventh data)))
                (setf *global-instruction-source*
                      (make-array (length source-list) :adjustable t
                                  :fill-pointer (length source-list)))
                (loop for instr in source-list
                      for i from 0
                      do (setf (aref *global-instruction-source* i) instr))
                (setf *global-instruction-vector*
                      (make-array (length source-list) :adjustable t
                                  :fill-pointer (length source-list)))
                (loop for instr in source-list
                      for i from 0
                      do (setf (aref *global-instruction-vector* i)
                               (resolve-operations instr)))
                (setf *global-label-table* (alist-to-hash-table label-alist :test 'eq))
                (setf *global-env* env)
                (setf *compile-time-macros* (alist-to-hash-table macro-alist :test 'eq))
                (setf *procedure-name-table* (alist-to-hash-table name-alist))
                (when param-alist
                  (setf *parameter-table* (alist-to-hash-table param-alist :test 'eq)))
                (when param-counter
                  (setf *parameter-counter* param-counter))))))))
  t)

(defun mc-eval (expr &optional (env nil env-supplied-p))
  "Evaluate EXPR using the metacircular compiler from the global env.
Works with image-only startup (no compiler.lisp needed).
When ENV is supplied, it is passed to mc-compile-and-go."
  (let ((mc-cag (lookup-variable-value 'mc-compile-and-go *global-env*)))
    (if env-supplied-p
        (execute-compiled-call mc-cag (list expr env))
        (execute-compiled-call mc-cag (list expr)))))

