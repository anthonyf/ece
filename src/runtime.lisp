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
           #:fmt
           #:print-text
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
           #:lines
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
           #:ece-runtime-error
           #:ece-original-error
           #:ece-error-procedure
           #:ece-error-arguments
           #:ece-error-environment
           #:ece-error-instruction
           #:ece-error-backtrace
           #:repl))

(in-package :ece)

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

(defun extend-environment (vars vals base-env)
  (if (or (listp vars) (null vars))
      ;; Walk vars/vals, handling dotted pair rest parameters
      (let ((var-list nil)
            (val-list nil)
            (v vars)
            (a vals))
        (loop while (consp v)
              do (push (car v) var-list)
              (push (car a) val-list)
              (setf v (cdr v))
              (setf a (cdr a)))
        ;; If v is non-nil atom, it's the rest parameter
        (when v
          (push v var-list)
          (push a val-list))
        (cons (make-frame (nreverse var-list) (nreverse val-list)) base-env))
      ;; vars is a symbol: rest-only parameter
      (cons (make-frame (list vars) (list vals)) base-env)))

(defun lookup-variable-value (var env)
  (labels ((scan-frame (vars vals)
             (cond
               ((null vars) nil)
               ((eq var (car vars)) (cons t (car vals)))
               (t (scan-frame (cdr vars) (cdr vals)))))
           (env-loop (env)
             (if (null env)
                 (error "Unbound variable: ~A" var)
                 (let ((result (scan-frame (frame-variables (car env))
                                           (frame-values (car env)))))
                   (if result
                       (cdr result)
                       (env-loop (cdr env)))))))
    (env-loop env)))

(defun set-variable-value! (var val env)
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
                 (if (scan (frame-variables (car env))
                           (frame-values (car env)))
                     val
                     (env-loop (cdr env))))))
    (env-loop env)))

(defun define-variable! (var val env)
  (let ((frame (car env)))
    (labels ((scan (vars vals)
               (cond
                 ((null vars)
                  (setf (car frame) (cons var (car frame)))
                  (setf (cdr frame) (cons val (cdr frame))))
                 ((eq var (car vars))
                  (setf (car vals) val))
                 (t (scan (cdr vars) (cdr vals))))))
      (scan (frame-variables frame) (frame-values frame)))))

;;; Primitives and global environment

(defun ece-boolean-p (x)
  "Test if x is a boolean (t or nil)."
  (or (eq x t) (eq x nil)))

(defparameter *primitive-procedures*
  '(+ - * / = < > <= >= car cdr cadr caddr caar cddr cons list append length
    (null? . null) (pair? . consp) not
    (number? . numberp) (string? . stringp) (symbol? . symbolp)
    (zero? . zerop) (even? . evenp) (odd? . oddp)
    (positive? . plusp) (negative? . minusp)
    (eq? . eq) (equal? . equal)
    (modulo . mod) abs min max reverse
    (char? . characterp) (char=? . char=) (char<? . char<)
    (char->integer . char-code) (integer->char . code-char)
    (error . error)
    (assoc . assoc) (member . member)
    (string=? . string=) (string<? . string<) (string>? . string>)
    (vector-length . length) (vector-ref . aref)
    (bitwise-and . logand) (bitwise-or . logior) (bitwise-xor . logxor)
    (bitwise-not . lognot) (arithmetic-shift . ash)))

(defparameter *primitive-procedure-names*
  (mapcar (lambda (p) (if (listp p) (car p) p))
          *primitive-procedures*))

(defparameter *primitive-procedure-objects*
  (mapcar (lambda (p) (list 'primitive (if (listp p) (cdr p) p)))
          *primitive-procedures*))

(defparameter *global-env*
  (extend-environment *primitive-procedure-names*
                      *primitive-procedure-objects*
                      nil))

;; EOF sentinel for safe read
(defvar *eof-sentinel* (gensym "EOF"))

;;; Custom readtable for ECE: ` → quasiquote, , → unquote, ,@ → unquote-splicing
;;; Wrapped in eval-when so it's available at compile time (needed for backtick
;;; syntax in macro definitions below).
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *ece-readtable* (copy-readtable))

  (set-macro-character #\`
                       (lambda (stream char)
                         (declare (ignore char))
                         (list 'quasiquote (read stream t nil t)))
                       nil *ece-readtable*)

  (set-macro-character #\,
                       (lambda (stream char)
                         (declare (ignore char))
                         (if (eql (peek-char nil stream nil nil) #\@)
                             (progn (read-char stream)
                                    (list 'unquote-splicing (read stream t nil t)))
                             (list 'unquote (read stream t nil t))))
                       nil *ece-readtable*)

  ;; Hash table literal: {k1 v1 k2 v2 ...} → (hash-table (k1 . v1) (k2 . v2) ...)
  (set-macro-character #\{
                       (lambda (stream char)
                         (declare (ignore char))
                         (let* ((items (read-delimited-list #\} stream t))
                                (entries (loop for (k v) on items by #'cddr
                                               collect (cons k v))))
                           (cons :hash-table entries)))
                       nil *ece-readtable*)

  (set-macro-character #\}
                       (get-macro-character #\))
                       nil *ece-readtable*)

  ;; String interpolation: "Hello $name, $(+ 1 2)" → (fmt "Hello " name ", " (+ 1 2))
  ;; $var interpolates a variable, $(expr) interpolates an expression, $$ is literal $
  ;; Strings without $ are returned as plain strings.
  (defun ece-identifier-char-p (c)
    "Return T if C is a valid identifier character after $."
    (and c (or (alphanumericp c)
               (member c '(#\- #\? #\! #\* #\> #\< #\_ #\/)))))

  (set-macro-character #\"
                       (lambda (stream char)
                         (declare (ignore char))
                         (let ((segments '())
                               (buf (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
                           (flet ((flush-buf ()
                                    (when (> (length buf) 0)
                                      (push (copy-seq buf) segments)
                                      (setf (fill-pointer buf) 0))))
                             (loop
                              (let ((c (read-char stream t nil t)))
                                (cond
                                  ;; End of string
                                  ((eql c #\")
                                   (flush-buf)
                                   (let ((segs (nreverse segments)))
                                     (return
                                       (if (and (= (length segs) 1) (stringp (first segs)))
                                           (first segs)
                                           (cons 'fmt segs)))))
                                  ;; Backslash escape
                                  ((eql c #\\)
                                   (let ((next (read-char stream t nil t)))
                                     (case next
                                       (#\n (vector-push-extend #\Newline buf))
                                       (#\t (vector-push-extend #\Tab buf))
                                       (#\" (vector-push-extend #\" buf))
                                       (#\\ (vector-push-extend #\\ buf))
                                       (t (vector-push-extend next buf)))))
                                  ;; Dollar interpolation
                                  ((eql c #\$)
                                   (let ((next (peek-char nil stream t nil t)))
                                     (cond
                                       ;; $$ → literal $
                                       ((eql next #\$)
                                        (read-char stream t nil t)
                                        (vector-push-extend #\$ buf))
                                       ;; $(expr) → read s-expression
                                       ((eql next #\()
                                        (flush-buf)
                                        (push (read stream t nil t) segments))
                                       ;; $identifier → read symbol name
                                       ((ece-identifier-char-p next)
                                        (flush-buf)
                                        (let ((sym-buf (make-array 0 :element-type 'character
                                                                   :adjustable t :fill-pointer 0)))
                                          (loop for sc = (peek-char nil stream nil nil t)
                                                while (ece-identifier-char-p sc)
                                                do (vector-push-extend (read-char stream t nil t) sym-buf))
                                          (push (intern (string-upcase sym-buf) :ece) segments)))
                                       ;; $ followed by non-identifier → literal $
                                       (t (vector-push-extend #\$ buf)))))
                                  ;; Regular character
                                  (t (vector-push-extend c buf))))))))
                       nil *ece-readtable*))

;;; I/O primitives with custom wrappers

(defun ece-read ()
  "Read an s-expression with *read-eval* disabled. Returns *eof-sentinel* on EOF."
  (handler-case
      (let ((*read-eval* nil)
            (*readtable* *ece-readtable*))
        (read))
    (end-of-file () *eof-sentinel*)))

(defun ece-display (obj)
  "Write obj without leading newline (princ)."
  (princ obj)
  (finish-output)
  obj)

(defun ece-write (obj)
  "Write obj in readable form (prin1). Strings are quoted, symbols uppercase."
  (prin1 obj)
  (finish-output)
  obj)

(defun ece-newline ()
  "Write a newline."
  (terpri)
  (finish-output)
  nil)

(defun ece-eof-p (obj)
  "Test if obj is the EOF sentinel."
  (eq obj *eof-sentinel*))

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
Supports integers and decimal floats. Returns NIL on failure."
  (let ((trimmed (string-trim '(#\Space #\Tab) s)))
    (when (zerop (length trimmed))
      (return-from ece-string->number nil))
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
              (return-from ece-string->number nil))
            (when (or (and (not sign-only) (null int-part))
                      (and (> (length frac-str) 0) (null frac-part)))
              (return-from ece-string->number nil))
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
                nil))))))

(defun ece-number->string (n)
  "Convert number n to string."
  (write-to-string n))

(defun ece-string->symbol (s)
  "Intern a symbol from string s."
  (intern (string-upcase s)))

(defun ece-symbol->string (s)
  "Return the name of symbol s as a lowercase string."
  (string-downcase (symbol-name s)))

(defun ece-list-ref (lst n)
  "Return element at index n in lst. Scheme arg order: (list-ref list index)."
  (nth n lst))

(defun ece-list-tail (lst n)
  "Return sublist from index n. Scheme arg order: (list-tail list index)."
  (nthcdr n lst))

(defun ece-vector-p (x)
  "Test if x is a vector (but not a string)."
  (and (vectorp x) (not (stringp x))))

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

(defun ece-read-line ()
  "Read a line of text from standard input and return it as a string."
  (read-line))

(defun ece-write-to-string (x)
  "Convert any value to its human-readable string representation."
  (princ-to-string x))

;; Hash table primitives
(defun ece-hash-table (&rest args)
  "Create a hash table from alternating key-value arguments."
  (cons :hash-table
        (loop for (k v) on args by #'cddr
              collect (cons k v))))

(defun ece-hash-table-p (x)
  "Test if x is a hash table."
  (and (consp x) (eq (car x) :hash-table) t))

(defun ece-hash-ref (ht key &optional default)
  "Look up key in hash table using equal. Returns default (nil) if not found."
  (let ((pair (assoc key (cdr ht) :test #'equal)))
    (if pair (cdr pair) default)))

(defun ece-hash-has-key-p (ht key)
  "Test if key exists in hash table."
  (if (assoc key (cdr ht) :test #'equal) t nil))

(defun ece-hash-keys (ht)
  "Return list of all keys in hash table."
  (mapcar #'car (cdr ht)))

(defun ece-hash-values (ht)
  "Return list of all values in hash table."
  (mapcar #'cdr (cdr ht)))

(defun ece-hash-count (ht)
  "Return number of entries in hash table."
  (length (cdr ht)))

(defun ece-hash-set! (ht key val)
  "Mutate hash table in place. Update existing key or add new entry."
  (let ((pair (assoc key (cdr ht) :test #'equal)))
    (if pair
        (setf (cdr pair) val)
        (setf (cdr ht) (cons (cons key val) (cdr ht)))))
  ht)

(defun ece-hash-set (ht key val)
  "Return a new hash table with key set to val. Original is unchanged."
  (let ((found nil))
    (cons :hash-table
          (append (mapcar (lambda (pair)
                            (if (equal (car pair) key)
                                (progn (setf found t)
                                       (cons key val))
                                (cons (car pair) (cdr pair))))
                          (cdr ht))
                  (unless found (list (cons key val)))))))

(defun ece-hash-remove! (ht key)
  "Remove key from hash table in place."
  (setf (cdr ht) (remove key (cdr ht) :key #'car :test #'equal))
  ht)

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
  (if (search needle haystack) t nil))

(defun ece-string-join (lst separator)
  "Join a list of strings with SEPARATOR between them."
  (if (null lst)
      ""
      (reduce (lambda (a b) (concatenate 'string a separator b))
              lst)))

(defun ece-save-continuation! (filename value)
  "Write a value to a file as a readable s-expression with circular structure support."
  (with-open-file (stream filename :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (let ((*print-circle* t)
          (*print-readably* t)
          (*package* (find-package :ece)))
      (write value :stream stream)))
  t)

(defun ece-load-continuation (filename)
  "Read a single s-expression from a file, returning it as an ECE value."
  (with-open-file (stream filename :direction :input)
    (let ((*readtable* *ece-readtable*)
          (*read-eval* nil)
          (*package* (find-package :ece)))
      (read stream))))

;;; Compile-time macro table (declared here so image save/load can access it;
;;; used by compiler.lisp for macro expansion)
(defvar *compile-time-macros* (make-hash-table :test 'eq)
  "Hash table mapping macro names to (params body env) for compile-time expansion.")

;;; Register wrapper primitives that don't depend on the compiler.
;;; (try-eval, load, save-image!, and load-image! are registered in compiler.lisp.)

(defparameter *wrapper-primitives*
  '((read . ece-read)
    (print . print)
    (write . ece-write)
    (display . ece-display)
    (newline . ece-newline)
    (eof? . ece-eof-p)
    (boolean? . ece-boolean-p)
    (gensym . gensym)
    (string-length . length)
    (string-ref . ece-string-ref)
    (string-append . ece-string-append)
    (substring . ece-substring)
    (string->number . ece-string->number)
    (number->string . ece-number->string)
    (string->symbol . ece-string->symbol)
    (symbol->string . ece-symbol->string)
    (list-ref . ece-list-ref)
    (list-tail . ece-list-tail)
    (vector? . ece-vector-p)
    (make-vector . ece-make-vector)
    (vector . ece-vector)
    (vector-set! . ece-vector-set!)
    (vector->list . ece-vector->list)
    (list->vector . ece-list->vector)
    (read-line . ece-read-line)
    (write-to-string . ece-write-to-string)
    (hash-table . ece-hash-table)
    (hash-table? . ece-hash-table-p)
    (hash-ref . ece-hash-ref)
    (hash-has-key? . ece-hash-has-key-p)
    (hash-keys . ece-hash-keys)
    (hash-values . ece-hash-values)
    (hash-count . ece-hash-count)
    (hash-set! . ece-hash-set!)
    (hash-set . ece-hash-set)
    (hash-remove! . ece-hash-remove!)
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
    (untrace . ece-untrace)))

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

(defun apply-primitive-procedure (proc argl)
  (apply (symbol-function (cadr proc)) argl))

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
    (false? #'null)
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
                               (funcall fn a b (eval-operand (car r2))))))))))
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
                    (op-fn (set-reg target (call-op (cadr source) (cdddr instr))))
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

;;; Metacircular compiler support primitives

(defun ece-execute-from-pc (start-pc)
  "Execute instructions starting from START-PC using current global state."
  (execute-instructions *global-instruction-vector*
                        *global-label-table*
                        *global-env*
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

(defun ece-get-macro (name)
  "Look up a compile-time macro by NAME. Returns the macro def or nil."
  (gethash name *compile-time-macros*))

(defun ece-set-macro! (name def)
  "Set a compile-time macro NAME to DEF."
  (setf (gethash name *compile-time-macros*) def)
  def)

;;; Parameter objects (R7RS / SRFI-39)

(defvar *parameter-counter* 0)

(defun ece-make-parameter (init &optional converter)
  "Create a parameter object. Returns a (primitive <name>) whose function
dispatches on arg count: 0 args = get, 1 arg = set (with converter),
2 args = raw set (bypass converter, used by parameterize restore).
Uses interned symbols so parameters survive image save/load round-trips."
  (let* ((converted-init (if converter
                             (apply-primitive-procedure
                              converter (list init))
                             init))
         (cell (cons converted-init converter))
         (name (intern (format nil "PARAM~D" (incf *parameter-counter*)) :ece)))
    (setf (symbol-function name)
          (lambda (&optional (new-val nil supplied-p) (raw nil))
            (if supplied-p
                (let ((old (car cell)))
                  (setf (car cell)
                        (if (and (cdr cell) (not raw))
                            (apply-primitive-procedure (cdr cell) (list new-val))
                            new-val))
                  old)
                (car cell))))
    (list 'primitive name)))

;;;; ========================================================================
;;;; IMAGE SAVE/LOAD
;;;; ========================================================================

(defun ece-save-image (filename)
  "Save the full ECE system state to FILENAME.
Serializes: instruction source vector, label table, global environment,
compile-time macros, and procedure name table."
  (let ((label-alist (let ((pairs nil))
                       (maphash (lambda (k v) (push (cons k v) pairs))
                                *global-label-table*)
                       pairs))
        (macro-alist (let ((pairs nil))
                       (maphash (lambda (k v) (push (cons k v) pairs))
                                *compile-time-macros*)
                       pairs))
        (name-alist (let ((pairs nil))
                      (maphash (lambda (k v) (push (cons k v) pairs))
                               *procedure-name-table*)
                      pairs)))
    (with-open-file (stream filename :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (let ((*print-circle* t)
            (*print-readably* t)
            (*package* (find-package :ece)))
        (write (list (coerce *global-instruction-source* 'list)
                     label-alist
                     *global-env*
                     macro-alist
                     name-alist)
               :stream stream))))
  t)

(defun ece-load-image (filename)
  "Load ECE system state from FILENAME, replacing all globals.
Rebuilds the execution vector by resolving operations on each instruction."
  (let ((data (with-open-file (stream filename :direction :input)
                (let ((*readtable* *ece-readtable*)
                      (*read-eval* nil)
                      (*package* (find-package :ece)))
                  (read stream)))))
    (let ((source-list (first data))
          (label-alist (second data))
          (env (third data))
          (macro-alist (fourth data))
          (name-alist (fifth data)))
      ;; Rebuild instruction source vector
      (setf *global-instruction-source*
            (make-array (length source-list) :adjustable t :fill-pointer (length source-list)))
      (loop for instr in source-list
            for i from 0
            do (setf (aref *global-instruction-source* i) instr))
      ;; Rebuild execution vector with resolved operations
      (setf *global-instruction-vector*
            (make-array (length source-list) :adjustable t :fill-pointer (length source-list)))
      (loop for instr in source-list
            for i from 0
            do (setf (aref *global-instruction-vector* i) (resolve-operations instr)))
      ;; Rebuild label table
      (setf *global-label-table* (make-hash-table :test 'eq))
      (dolist (pair label-alist)
        (setf (gethash (car pair) *global-label-table*) (cdr pair)))
      ;; Restore environment and macros
      (setf *global-env* env)
      (setf *compile-time-macros* (make-hash-table :test 'eq))
      (dolist (pair macro-alist)
        (setf (gethash (car pair) *compile-time-macros*) (cdr pair)))
      ;; Restore procedure name table
      (setf *procedure-name-table* (make-hash-table))
      (dolist (pair name-alist)
        (setf (gethash (car pair) *procedure-name-table*) (cdr pair)))))
  t)
