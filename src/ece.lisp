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
           #:repl))

(in-package :ece)

;; Frame-based environment (SICP Section 4.1.3)
;; A frame is (cons vars vals) — parallel lists of variable names and values
;; An environment is a list of frames

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

;; Custom readtable for ECE: ` → quasiquote, , → unquote, ,@ → unquote-splicing
;; Wrapped in eval-when so it's available at compile time (needed for backtick
;; syntax in macro definitions below).
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

;; I/O primitives with custom wrappers
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

(defun ece-newline ()
  "Write a newline."
  (terpri)
  (finish-output)
  nil)

(defun ece-eof-p (obj)
  "Test if obj is the EOF sentinel."
  (eq obj *eof-sentinel*))

(defun ece-try-eval (expr)
  "Evaluate expr, catching errors. Prints the error and returns nil on failure."
  (handler-case
      (evaluate expr)
    (error (c)
      (format t "Error: ~A~%" c)
      (finish-output)
      nil)))

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

(defun ece-load (filename)
  "Load and evaluate all expressions from an ECE source file."
  (with-open-file (stream filename :direction :input)
    (let ((*readtable* *ece-readtable*)
          (*read-eval* nil)
          (*package* (find-package :ece))
          (result nil))
      (loop for expr = (read stream nil *eof-sentinel*)
            until (eq expr *eof-sentinel*)
            do (setf result (evaluate expr)))
      result)))

(defparameter *wrapper-primitives*
  '((read . ece-read)
    (print . print)
    (display . ece-display)
    (newline . ece-newline)
    (eof? . ece-eof-p)
    (try-eval . ece-try-eval)
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
    (load . ece-load)
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
    (load-continuation . ece-load-continuation)))

(dolist (entry *wrapper-primitives*)
  (define-variable! (car entry) (list 'primitive (cdr entry)) *global-env*))

(defun self-evaluating-p (expr)
  (or (numberp expr)
      (stringp expr)
      (characterp expr)
      (vectorp expr)
      (null expr)
      (eq expr t)
      (and (consp expr) (eq (car expr) :hash-table))))

(defun variable-p (expr)
  (symbolp expr))

(defmacro define-special-form-predicate (symbol name)
  "Generate a predicate NAME-P that tests if expr starts with SYMBOL."
  `(defun ,(intern (format nil "~A-P" name)) (expr)
     (and (listp expr) (eq (car expr) ',symbol))))

(define-special-form-predicate set assignment)
(define-special-form-predicate quote quoted)
(define-special-form-predicate lambda lambda)
(define-special-form-predicate begin begin)
(define-special-form-predicate if if)
(define-special-form-predicate call/cc callcc)
(define-special-form-predicate define define)
(define-special-form-predicate apply apply-form)
(define-special-form-predicate define-macro define-macro)
(define-special-form-predicate quasiquote quasiquote)

(defun make-procedure (parameters body env)
  (list 'procedure parameters body env))

(defun qq-expand (form &optional (depth 0))
  "Walk a quasiquote template and produce a cons/append construction expression.
   Tracks nesting depth so inner quasiquotes preserve their unquote forms."
  (cond
    ((null form) '(quote ()))
    ((atom form) (list 'quote form))
    ;; nested quasiquote: increment depth, preserve as literal structure
    ((eq (car form) 'quasiquote)
     (list 'list (list 'quote 'quasiquote) (qq-expand (cadr form) (1+ depth))))
    ;; unquote at depth 0: evaluate
    ((and (eq (car form) 'unquote) (= depth 0))
     (cadr form))
    ;; unquote at depth > 0: decrement depth, preserve as literal structure
    ((and (eq (car form) 'unquote) (> depth 0))
     (list 'list (list 'quote 'unquote) (qq-expand (cadr form) (1- depth))))
    ;; unquote-splicing at depth 0: splice
    ((and (consp (car form)) (eq (caar form) 'unquote-splicing) (= depth 0))
     (list 'append (cadar form) (qq-expand (cdr form) depth)))
    ;; unquote-splicing at depth > 0: preserve as literal structure
    ((and (consp (car form)) (eq (caar form) 'unquote-splicing) (> depth 0))
     (list 'cons
           (list 'list (list 'quote 'unquote-splicing) (qq-expand (cadar form) (1- depth)))
           (qq-expand (cdr form) depth)))
    (t (list 'cons (qq-expand (car form) depth) (qq-expand (cdr form) depth)))))

(defparameter *special-forms* '(quote if var set lambda begin call/cc define apply define-macro quasiquote))

(defun application-p (expr)
  (and (listp expr)
       (not (null expr))
       (not (member (car expr) *special-forms*))))

;; implement an explicit control evaluator
(defun evaluate (expr &optional (env *global-env*))
  "Compile and execute EXPR in ENV."
  (compile-and-go expr env))

;;; Old interpreter (kept for reference, used by macro expansion during bootstrap)
(defun evaluate-interpreted (expr &optional (env *global-env*))
  ;; registers
  (let ((stack nil)
        (conts nil) ;; continuation stack
        (val nil)   ;; result value
        (unev nil)  ;; unevaluated operands
        (argl nil)  ;; argument list
        (proc nil)  ;; procedure to apply
        )
    (push :ev-dispatch conts)
    (flet ((dbg (section label)
             (format t "~A: ~A expr=~A env=~A stack=~A conts=~A val=~A unev=~A argl=~A proc=~A ~%" section label expr env stack conts val unev argl proc)))
      (loop while conts
            for cont = (pop conts)
            do (case cont
                 (:ev-dispatch
                  #+nil (dbg :ev-dispatch :start)
                  (cond
                    ((self-evaluating-p expr) (push :ev-self-eval conts))
                    ((variable-p expr)        (push :ev-variable conts))
                    ((quoted-p expr)          (push :ev-quoted conts))
                    ((quasiquote-p expr)     (push :ev-quasiquote conts))
                    ((lambda-p expr)          (push :ev-lambda conts))
                    ((application-p expr)     (push :ev-application conts))
                    ((if-p expr)              (push :ev-if conts))
                    ((callcc-p expr)          (push :ev-callcc conts))
                    ((assignment-p expr)      (push :ev-assignment conts))
                    ((apply-form-p expr)     (push :ev-apply conts))
                    ((define-macro-p expr)   (push :ev-define-macro conts))
                    ((define-p expr)          (push :ev-define conts))
                    ((begin-p expr)           (push :ev-begin conts))
                    (t (error "Unknown expression type: ~A" expr)))
                  #+nil (dbg :ev-dispatch :end))

                 (:ev-self-eval
                  #+nil (dbg :ev-self-eval :start)
                  (setf val expr)
                  #+nil (dbg :ev-self-eval :end))

                 (:ev-variable
                  #+nil (dbg :ev-variable :start)
                  (setf val (lookup-variable-value expr env))
                  #+nil (dbg :ev-variable :end))

                 (:ev-quoted
                  #+nil (dbg :ev-quoted :start)
                  (setf val (cadr expr))
                  #+nil (dbg :ev-quoted :end))

                 (:ev-quasiquote
                  ;; Transform quasiquote template into cons/append expression, re-dispatch
                  #+nil (dbg :ev-quasiquote :start)
                  (setf expr (qq-expand (cadr expr)))
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-quasiquote :end))

                 (:ev-lambda
                  ;; ev-lambda
                  ;; (assign unev
                  ;;    (op lambda-parameters)
                  ;;    (reg exp))
                  ;; (assign exp 
                  ;;    (op lambda-body)
                  ;;    (reg exp))
                  ;; (assign val 
                  ;;    (op make-procedure)
                  ;;    (reg unev)
                  ;;    (reg exp)
                  ;;    (reg env))
                  ;; (goto (reg continue))
                  #+nil (dbg :ev-lambda :start)
                  (setf unev (cadr expr)) ;; parameters
                  (setf expr (cddr expr)) ;; body
                  (setf val (make-procedure unev expr env))
                  #+nil (dbg :ev-lambda :end))
                 (:ev-application
                  ;; ev-application
                  ;; (save continue)
                  ;; (save env)
                  ;; (assign unev (op operands) (reg exp))
                  ;; (save unev)
                  ;; (assign exp (op operator) (reg exp))
                  ;; (assign
                  ;;  continue (label ev-appl-did-operator))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-application :start)
                  (push conts stack)
                  (push env stack)
                  (setf unev (cdr expr))
                  (push unev stack)
                  (setf expr (car expr))
                  (push :ev-appl-did-operator conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-application :end))
                 (:ev-appl-did-operator
                  ;; ev-appl-did-operator
                  ;; (restore unev)             ; the operands
                  ;; (restore env)
                  ;; (assign argl (op empty-arglist))
                  ;; (assign proc (reg val))    ; the operator
                  ;; (test (op no-operands?) (reg unev))
                  ;; (branch (label apply-dispatch))
                  ;; (save proc)
                  #+nil (dbg :ev-appl-did-operator :start)
                  (setf unev (pop stack))
                  (setf env (pop stack))
                  (setf argl nil)
                  (setf proc val)
                  (if (and (listp proc) (eq (car proc) 'macro))
                      ;; Macro: don't evaluate operands, expand and re-dispatch
                      (push :macro-apply conts)
                      (if (null unev)
                          (push :apply-dispatch conts)
                          (progn (push proc stack)
                                 (push :ev-appl-operand-loop conts))))
                  #+nil (dbg :ev-appl-did-operator :end))
                 (:ev-appl-operand-loop
                  ;; ev-appl-operand-loop
                  ;; (save argl)
                  ;; (assign exp
                  ;;    (op first-operand)
                  ;;    (reg unev))
                  ;; (test (op last-operand?) (reg unev))
                  ;; (branch (label ev-appl-last-arg))
                  ;; (save env)
                  ;; (save unev)
                  ;; (assign continue 
                  ;;    (label ev-appl-accumulate-arg))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-appl-operand-loop :start)
                  (push argl stack)
                  (setf expr (car unev))
                  (if (null (cdr unev)) ;; last operand?
                      (push :ev-appl-last-arg conts)
                      (progn (push :ev-appl-accumulate-arg conts)
                             (push env stack)
                             (push unev stack)
                             (push :ev-appl-accumulate-arg conts)
                             (push :ev-dispatch conts)))
                  #+nil (dbg :ev-appl-operand-loop :end))
                 (:ev-appl-accumulate-arg
                  ;; ev-appl-accumulate-arg
                  ;; (restore unev)
                  ;; (restore env)
                  ;; (restore argl)
                  ;; (assign argl 
                  ;;    (op adjoin-arg)
                  ;;    (reg val)
                  ;;    (reg argl))
                  ;; (assign unev
                  ;;    (op rest-operands)
                  ;;    (reg unev))
                  ;; (goto (label ev-appl-operand-loop))
                  #+nil (dbg :ev-appl-accumulate-arg :start)
                  (setf unev (pop stack))
                  (setf env (pop stack))
                  (setf argl (pop stack))
                  (setf argl (cons val argl))
                  (setf unev (cdr unev))
                  (push :ev-appl-operand-loop conts)
                  #+nil (dbg :ev-appl-accumulate-arg :end)
                  )
                 (:ev-appl-last-arg
                  ;; ev-appl-last-arg
                  ;; (assign continue 
                  ;;    (label ev-appl-accum-last-arg))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-appl-last-arg :start)
                  (push :ev-appl-accum-last-arg conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-appl-last-arg :end)
                  )
                 (:ev-appl-accum-last-arg
                  ;; ev-appl-accum-last-arg
                  ;; (restore argl)
                  ;; (assign argl 
                  ;;    (op adjoin-arg)
                  ;;    (reg val)
                  ;;    (reg argl))
                  ;; (restore proc)
                  ;; (goto (label apply-dispatch))
                  #+nil (dbg :ev-appl-accum-last-arg :start)
                  (setf argl (pop stack))
                  (setf argl (cons val argl))
                  (setf proc (pop stack))
                  (push :apply-dispatch conts)
                  #+nil (dbg :ev-appl-accum-last-arg :end)
                  )
                 (:apply-dispatch
                  ;; apply-dispatch
                  ;; (test (op primitive-procedure?) (reg proc))
                  ;; (branch (label primitive-apply))
                  ;; (test (op compound-procedure?) (reg proc))
                  ;; (branch (label compound-apply))
                  ;; (goto (label unknown-procedure-type))
                  #+nil (dbg :apply-dispatch :start)
                  (cond
                    ((eq (car proc) 'primitive)     (push :primitive-apply conts))
                    ((eq (car proc) 'procedure)     (push :compound-apply conts))
                    ((eq (car proc) 'continuation)  (push :continuation-apply conts))
                    (t                              (push :unknown-procedure-type conts)))
                  #+nil (dbg :apply-dispatch :end)
                  )
                 (:primitive-apply
                  ;; primitive-apply
                  ;; (assign val (op apply-primitive-procedure)
                  ;;    (reg proc)
                  ;;    (reg argl))
                  ;; (restore continue)
                  ;; (goto (reg continue))
                  #+nil (dbg :primitive-apply :start)
                  (setf val (apply (symbol-function (cadr proc)) (nreverse argl)))
                  (setf conts (pop stack))
                  #+nil (dbg :primitive-apply :end)
                  )
                 (:compound-apply
                  ;; compound-apply
                  ;; (assign unev 
                  ;;    (op procedure-parameters)
                  ;;    (reg proc))
                  ;; (assign env
                  ;;    (op procedure-environment)
                  ;;    (reg proc))
                  ;; (assign env
                  ;;    (op extend-environment)
                  ;;    (reg unev)
                  ;;    (reg argl)
                  ;;    (reg env))
                  ;; (assign unev
                  ;;    (op procedure-body)
                  ;;    (reg proc))
                  ;; (goto (label ev-sequence))
                  #+nil (dbg :compound-apply :start)
                  (setf unev (cadr proc))  ;; parameters
                  (setf env (cadddr proc)) ;; environment
                  (setf env (extend-environment unev (nreverse argl) env)) ;; extend env
                  (setf unev (caddr proc)) ;; body
                  (push :ev-sequence conts)
                  #+nil (dbg :compound-apply :end)
                  )
                 (:continuation-apply
                  ;; Restore captured continuation state, set val to argument
                  #+nil (dbg :continuation-apply :start)
                  (setf stack (copy-list (cadr proc)))
                  (setf conts (copy-list (caddr proc)))
                  (setf val (car argl))
                  #+nil (dbg :continuation-apply :end)
                  )
                 (:unknown-procedure-type
                  #+nil (dbg :unknown-procedure-type :start)
                  (error "Unknown procedure type: ~A" proc))
                 (:macro-apply
                  ;; Macro expansion: extend macro env with unevaluated operands, evaluate body
                  ;; Stack: [caller-conts, ...]
                  #+nil (dbg :macro-apply :start)
                  (push env stack)
                  (push (list :macro-apply-result) stack)
                  (setf env (extend-environment (cadr proc) unev (cadddr proc)))
                  (setf unev (caddr proc))
                  (push :ev-sequence conts)
                  #+nil (dbg :macro-apply :end))
                 (:macro-apply-result
                  ;; val is the expanded form — re-dispatch it in the caller's context
                  #+nil (dbg :macro-apply-result :start)
                  (setf env (pop stack))
                  (setf conts (pop stack))
                  (setf expr val)
                  (push :ev-dispatch conts)
                  #+nil (dbg :macro-apply-result :end))
                 (:ev-begin
                  ;; ev-begin
                  ;; (assign unev
                  ;;    (op begin-actions)
                  ;;    (reg exp))
                  ;; (save continue)
                  ;; (goto (label ev-sequence))
                  #+nil (dbg :ev-begin :start)
                  (setf unev (cdr expr))
                  (push conts stack)
                  (push :ev-sequence conts)
                  #+nil (dbg :ev-begin :end)
                  )
                 (:ev-sequence
                  ;; ev-sequence
                  ;; (assign exp (op first-exp) (reg unev))
                  ;; (test (op last-exp?) (reg unev))
                  ;; (branch (label ev-sequence-last-exp))
                  ;; (save unev)
                  ;; (save env)
                  ;; (assign continue
                  ;;    (label ev-sequence-continue))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-sequence :start)
                  (setf expr (car unev))
                  (if (null (cdr unev)) ;; last exp?
                      (push :ev-sequence-last-exp conts)
                      (progn (push unev stack)
                             (push env stack)
                             (push :ev-sequence-continue conts)
                             (push :ev-dispatch conts)))
                  #+nil (dbg :ev-sequence :end)
                  )
                 (:ev-sequence-continue
                  ;; ev-sequence-continue
                  ;; (restore env)
                  ;; (restore unev)
                  ;; (assign unev
                  ;;    (op rest-exps)
                  ;;    (reg unev))
                  ;; (goto (label ev-sequence))
                  #+nil (dbg :ev-sequence-continue :start)
                  (setf env (pop stack))
                  (setf unev (pop stack))
                  (setf unev (cdr unev))
                  (push :ev-sequence conts)
                  #+nil (dbg :ev-sequence-continue :end)
                  )
                 (:ev-sequence-last-exp
                  ;; ev-sequence-last-exp
                  ;; (restore continue)
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-sequence-last-exp :start)
                  (setf conts (pop stack))
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-sequence-last-exp :end)
                  )
                 (:ev-callcc
                  ;; ev-callcc
                  ;; Capture current continuation, then evaluate receiver
                  #+nil (dbg :ev-callcc :start)
                  (let ((captured (list 'continuation
                                        (copy-list stack)
                                        (copy-list conts))))
                    (push captured stack))
                  (setf expr (cadr expr)) ;; receiver expression
                  (push :ev-callcc-apply conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-callcc :end)
                  )
                 (:ev-callcc-apply
                  ;; Apply evaluated receiver (in val) to captured continuation
                  #+nil (dbg :ev-callcc-apply :start)
                  (let ((captured (pop stack)))
                    (setf proc val)
                    (setf argl (list captured))
                    (push conts stack) ;; save return continuation for compound-apply's ev-sequence
                    (push :apply-dispatch conts))
                  #+nil (dbg :ev-callcc-apply :end)
                  )
                 (:ev-apply
                  ;; (apply proc-expr args-expr)
                  ;; Save env and conts, evaluate proc-expr
                  #+nil (dbg :ev-apply :start)
                  (push env stack)
                  (push conts stack)
                  (push (caddr expr) stack)  ;; save args-expr for later
                  (setf expr (cadr expr))    ;; proc-expr
                  (push :ev-apply-did-proc conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-apply :end))
                 (:ev-apply-did-proc
                  ;; proc is in val, now evaluate args-expr
                  #+nil (dbg :ev-apply-did-proc :start)
                  (setf expr (pop stack))    ;; restore args-expr
                  (push val stack)           ;; save proc
                  (push :ev-apply-dispatch conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-apply-did-proc :end))
                 (:ev-apply-dispatch
                  ;; args list is in val, proc is on stack
                  ;; Set up argl/proc and jump to apply-dispatch
                  #+nil (dbg :ev-apply-dispatch :start)
                  (setf proc (pop stack))
                  (setf argl (reverse val))  ;; reverse so nreverse in apply handlers produces correct order
                  (setf conts (pop stack))   ;; restore caller's conts
                  (setf env (pop stack))     ;; restore caller's env
                  (push conts stack)         ;; apply-dispatch expects conts on stack
                  (push :apply-dispatch conts)
                  #+nil (dbg :ev-apply-dispatch :end))
                 (:ev-assignment
                  ;; ev-assignment (SICP)
                  ;; Save variable name, env, conts; evaluate value expression
                  #+nil (dbg :ev-assignment :start)
                  (push (cadr expr) stack)     ;; variable name
                  (setf expr (caddr expr))     ;; value expression
                  (push env stack)
                  (push conts stack)
                  (push :ev-assignment-assign conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-assignment :end))
                 (:ev-assignment-assign
                  ;; Restore state, call set-variable-value!, set val
                  #+nil (dbg :ev-assignment-assign :start)
                  (setf conts (pop stack))
                  (setf env (pop stack))
                  (let ((variable (pop stack)))
                    (set-variable-value! variable val env))
                  #+nil (dbg :ev-assignment-assign :end))
                 (:ev-define
                  ;; ev-definition (SICP)
                  ;; (assign unev (op definition-variable) (reg exp))
                  ;; (save unev)
                  ;; (assign exp (op definition-value) (reg exp))
                  ;; (save env)
                  ;; (save continue)
                  ;; (assign continue (label ev-definition-1))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-define :start)
                  (let ((variable (if (listp (cadr expr))
                                      (caadr expr)                ;; (define (f x) body...) → f
                                      (cadr expr))))               ;; (define x val) → x
                    (push variable stack))
                  (setf expr (if (listp (cadr expr))
                                 ;; function shorthand: build lambda
                                 (cons 'lambda (cons (cdadr expr) (cddr expr)))
                                 ;; value form
                                 (caddr expr)))
                  (push env stack)
                  (push conts stack)
                  (push :ev-define-assign conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-define :end))
                 (:ev-define-macro
                  ;; (define-macro (name params...) body...)
                  ;; Create macro value directly (no evaluation needed) and store it
                  #+nil (dbg :ev-define-macro :start)
                  (let* ((variable (caadr expr))
                         (params (cdadr expr))
                         (body (cddr expr)))
                    (define-variable! variable (list 'macro params body env) env)
                    (setf val variable))
                  #+nil (dbg :ev-define-macro :end))
                 (:ev-define-assign
                  ;; ev-definition-1 (SICP)
                  ;; (restore continue)
                  ;; (restore env)
                  ;; (restore unev)
                  ;; (perform (op define-variable!) (reg unev) (reg val) (reg env))
                  ;; (assign val (const ok))
                  ;; (goto (reg continue))
                  #+nil (dbg :ev-define-assign :start)
                  (setf conts (pop stack))
                  (setf env (pop stack))
                  (let ((variable (pop stack)))
                    (define-variable! variable val env))
                  #+nil (dbg :ev-define-assign :end))
                 (:ev-if
                  ;; ev-if
                  ;; (save exp)   ; save expression for later
                  ;; (save env)
                  ;; (save continue)
                  ;; (assign continue (label ev-if-decide))
                  ;; (assign exp (op if-predicate) (reg exp))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-if :start)
                  (push expr stack)
                  (push env stack)
                  (push conts stack)
                  (setf expr (cadr expr)) ;; if-predicate
                  (push :ev-if-decide conts)
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-if :end)
                  )
                 (:ev-if-decide
                  ;; ev-if-decide
                  ;; (restore continue)
                  ;; (restore env)
                  ;; (restore exp)
                  ;; (test (op true?) (reg val))
                  ;; (branch (label ev-if-consequent))
                  #+nil (dbg :ev-if-decide :start)
                  (setf conts (pop stack))
                  (setf env (pop stack))
                  (setf expr (pop stack))
                  (if val
                      (push :ev-if-consequent conts)
                      (push :ev-if-alternative conts))
                  #+nil (dbg :ev-if-decide :end)
                  )
                 (:ev-if-alternative
                  ;; ev-if-alternative
                  ;; (assign exp (op if-alternative) (reg exp))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-if-alternative :start)
                  (setf expr (cadddr expr)) ;; if-alternative (nil if absent)
                  (if expr
                      (progn (push :ev-dispatch conts))
                      (setf val nil))
                  #+nil (dbg :ev-if-alternative :end)
                  )
                 (:ev-if-consequent
                  ;; ev-if-consequent
                  ;; (assign exp (op if-consequent) (reg exp))
                  ;; (goto (label eval-dispatch))
                  #+nil (dbg :ev-if-consequent :start)
                  (setf expr (caddr expr)) ;; if-consequent
                  (push :ev-dispatch conts)
                  #+nil (dbg :ev-if-consequent :end)
                  )
                 
                 (t (error "Unknown cont: ~A" cont)))))
    val))

;;;; ========================================================================
;;;; COMPILER (SICP 5.5)
;;;; ========================================================================

;;; Instruction sequences: (needs modifies instructions)
;;; - needs: list of registers read before any write
;;; - modifies: list of registers written
;;; - instructions: list of instruction forms

(defun make-instruction-sequence (needs modifies instructions)
  (list needs modifies instructions))

(defun instruction-seq-needs (seq) (car seq))
(defun instruction-seq-modifies (seq) (cadr seq))
(defun instruction-seq-instructions (seq) (caddr seq))

(defun empty-instruction-sequence ()
  (make-instruction-sequence '() '() '()))

(defun registers-needed (seq)
  (if (symbolp seq) '() (instruction-seq-needs seq)))

(defun registers-modified (seq)
  (if (symbolp seq) '() (instruction-seq-modifies seq)))

(defun instructions (seq)
  (if (symbolp seq) (list seq) (instruction-seq-instructions seq)))

(defun needs-register-p (seq reg)
  (member reg (registers-needed seq)))

(defun modifies-register-p (seq reg)
  (member reg (registers-modified seq)))

;;; Combining instruction sequences

(defun append-instruction-sequences (&rest seqs)
  "Append instruction sequences, merging needs/modifies."
  (reduce #'append-2-sequences seqs :initial-value (empty-instruction-sequence)))

(defun append-2-sequences (seq1 seq2)
  (make-instruction-sequence
   (union (registers-needed seq1)
          (set-difference (registers-needed seq2)
                          (registers-modified seq1)))
   (union (registers-modified seq1)
          (registers-modified seq2))
   (append (instructions seq1) (instructions seq2))))

(defun tack-on-instruction-sequence (seq body-seq)
  "Append body-seq instructions but don't include its needs/modifies
   (used for lambda bodies that execute in a different context)."
  (make-instruction-sequence
   (registers-needed seq)
   (registers-modified seq)
   (append (instructions seq) (instructions body-seq))))

;;; Preserving: the core optimization

(defun preserving (regs seq1 seq2)
  "Wrap save/restore around seq1 for each reg in REGS that seq1 modifies
   and seq2 needs."
  (if (null regs)
      (append-2-sequences seq1 seq2)
      (let ((first-reg (car regs)))
        (if (and (modifies-register-p seq1 first-reg)
                 (needs-register-p seq2 first-reg))
            (preserving (cdr regs)
                        (make-instruction-sequence
                         (union (list first-reg) (registers-needed seq1))
                         (set-difference (registers-modified seq1)
                                         (list first-reg))
                         (append `((save ,first-reg))
                                 (instructions seq1)
                                 `((restore ,first-reg))))
                        seq2)
            (preserving (cdr regs) seq1 seq2)))))

;;; Label generation

(let ((label-counter 0))
  (defun make-label (name)
    (intern (format nil "~A-~D" name (incf label-counter)) :ece)))

;;; Linkage code

(defun compile-linkage (linkage)
  "Emit instructions for a linkage: next (fall through), return, or a label."
  (cond
    ((eq linkage 'next) (empty-instruction-sequence))
    ((eq linkage 'return)
     (make-instruction-sequence '(continue) '() '((goto (reg continue)))))
    (t ; label
     (make-instruction-sequence '() '() `((goto (label ,linkage)))))))

(defun end-with-linkage (linkage instruction-sequence)
  "Append linkage code to an instruction sequence, preserving continue."
  (preserving '(continue)
              instruction-sequence
              (compile-linkage linkage)))

;;; Compile-time macro environment
(defvar *compile-time-macros* (make-hash-table :test 'eq)
  "Hash table mapping macro names to (params body env) for compile-time expansion.")

(defvar *compile-lexical-env* nil
  "List of locally-bound variable names, used to shadow macros.")

;;; Main compile dispatch

(defun ece-compile (expr target linkage)
  "Compile EXPR, placing result in TARGET register, with LINKAGE."
  (cond
    ((self-evaluating-p expr) (compile-self-evaluating expr target linkage))
    ((variable-p expr) (compile-variable expr target linkage))
    ((quoted-p expr) (compile-quoted expr target linkage))
    ((quasiquote-p expr) (compile-quasiquote expr target linkage))
    ((lambda-p expr) (compile-lambda expr target linkage))
    ((if-p expr) (compile-if expr target linkage))
    ((callcc-p expr) (compile-callcc expr target linkage))
    ((assignment-p expr) (compile-assignment expr target linkage))
    ((apply-form-p expr) (compile-apply-form expr target linkage))
    ((define-macro-p expr) (compile-define-macro expr target linkage))
    ((define-p expr) (compile-define expr target linkage))
    ((begin-p expr) (compile-begin expr target linkage))
    ((application-p expr)
     ;; Check for compile-time macro (skip if operator is lexically shadowed)
     (let ((macro-def (and (not (member (car expr) *compile-lexical-env*))
                           (gethash (car expr) *compile-time-macros*))))
       (if macro-def
           (let ((expanded (expand-macro-at-compile-time macro-def (cdr expr))))
             (ece-compile expanded target linkage))
           (compile-application expr target linkage))))
    (t (error "Unknown expression type -- COMPILE: ~A" expr))))

;;; Compile-time macro expansion

(defun expand-macro-at-compile-time (macro-def operands)
  "Expand a macro at compile time. MACRO-DEF is (params body env)."
  (let ((params (car macro-def))
        (body (cadr macro-def))
        (macro-env (caddr macro-def)))
    ;; Build a temporary env for expansion, evaluate the body with the interpreter
    (let ((expansion-env (extend-environment params operands macro-env)))
      ;; Evaluate macro body in expansion env to get the expanded form
      ;; We use the old evaluate for macro expansion at compile time
      (let ((expanded nil))
        (dolist (body-expr body)
          (setf expanded (evaluate body-expr expansion-env)))
        expanded))))

;;; Individual compile functions

(defun compile-self-evaluating (expr target linkage)
  (end-with-linkage linkage
                    (make-instruction-sequence
                     '() (list target)
                     `((assign ,target (const ,expr))))))

(defun compile-variable (expr target linkage)
  (end-with-linkage linkage
                    (make-instruction-sequence
                     '(env) (list target)
                     `((assign ,target (op lookup-variable-value) (const ,expr) (reg env))))))

(defun compile-quoted (expr target linkage)
  (end-with-linkage linkage
                    (make-instruction-sequence
                     '() (list target)
                     `((assign ,target (const ,(cadr expr)))))))

(defun compile-quasiquote (expr target linkage)
  "Expand quasiquote at compile time, then compile the expanded form."
  (let ((expanded (qq-expand (cadr expr) 0)))
    (ece-compile expanded target linkage)))

(defun compile-assignment (expr target linkage)
  (let ((variable (cadr expr))
        (value-code (ece-compile (caddr expr) 'val 'next)))
    (end-with-linkage linkage
                      (preserving '(env)
                                  value-code
                                  (make-instruction-sequence
                                   '(env val) (list target)
                                   `((perform (op set-variable-value!) (const ,variable) (reg val) (reg env))
                                     (assign ,target (reg val))))))))

(defun compile-define (expr target linkage)
  (let* ((variable (if (listp (cadr expr)) (caadr expr) (cadr expr)))
         (value-expr (if (listp (cadr expr))
                         ;; (define (f x) body) → (lambda (x) body)
                         `(lambda ,(cdadr expr) ,@(cddr expr))
                         (caddr expr)))
         (value-code (ece-compile value-expr 'val 'next)))
    (end-with-linkage linkage
                      (preserving '(env)
                                  value-code
                                  (make-instruction-sequence
                                   '(env val) (list target)
                                   `((perform (op define-variable!) (const ,variable) (reg val) (reg env))
                                     (assign ,target (reg val))))))))

(defun compile-if (expr target linkage)
  (let ((true-branch (make-label 'true-branch))
        (false-branch (make-label 'false-branch))
        (after-if (make-label 'after-if)))
    (let ((consequent-linkage (if (eq linkage 'next) after-if linkage)))
      (let ((predicate-code (ece-compile (cadr expr) 'val 'next))
            (consequent-code (ece-compile (caddr expr) target consequent-linkage))
            (alternative-code (ece-compile (if (cdddr expr) (cadddr expr) nil)
                                           target linkage)))
        (preserving '(env continue)
                    predicate-code
                    (append-instruction-sequences
                     (make-instruction-sequence
                      '(val) '()
                      `((test (op false?) (reg val))
                        (branch (label ,false-branch))))
                     (parallel-instruction-sequences
                      (append-instruction-sequences true-branch consequent-code)
                      (append-instruction-sequences false-branch alternative-code))
                     after-if))))))

(defun parallel-instruction-sequences (seq1 seq2)
  "Combine two alternative branches (like if consequent/alternative)."
  (make-instruction-sequence
   (union (registers-needed seq1) (registers-needed seq2))
   (union (registers-modified seq1) (registers-modified seq2))
   (append (instructions seq1) (instructions seq2))))

(defun extract-define-names (body)
  "Extract names bound by define forms in a body (for macro shadowing)."
  (loop for form in body
        when (and (consp form) (eq (car form) 'define))
        collect (let ((name-spec (cadr form)))
                  (if (consp name-spec) (car name-spec) name-spec))))

(defun compile-begin (expr target linkage)
  (let ((body (cdr expr)))
    (let ((defined-names (extract-define-names body)))
      (if defined-names
          (let ((*compile-lexical-env* (append defined-names *compile-lexical-env*)))
            (compile-sequence body target linkage))
          (compile-sequence body target linkage)))))

(defun compile-sequence (seq target linkage)
  "Compile a sequence of expressions."
  (if (null (cdr seq))
      (ece-compile (car seq) target linkage)
      (preserving '(env continue)
                  (ece-compile (car seq) target 'next)
                  (compile-sequence (cdr seq) target linkage))))

(defun compile-lambda (expr target linkage)
  (let ((proc-entry (make-label 'entry))
        (after-lambda (make-label 'after-lambda)))
    (let ((lambda-linkage (if (eq linkage 'next) after-lambda linkage)))
      (let* ((params (cadr expr))
             (body (cddr expr))
             (body-code (compile-lambda-body params body proc-entry)))
        (append-instruction-sequences
         (tack-on-instruction-sequence
          (end-with-linkage lambda-linkage
                            (make-instruction-sequence
                             '(env) (list target)
                             `((assign ,target (op make-compiled-procedure)
                                       (label ,proc-entry) (reg env)))))
          body-code)
         after-lambda)))))

(defun flatten-params (params)
  "Extract all parameter names from a param list (proper or dotted)."
  (cond ((null params) nil)
        ((symbolp params) (list params))
        ((consp params) (cons (car params) (flatten-params (cdr params))))))

(defun compile-lambda-body (params body proc-entry)
  "Compile the body of a lambda, with entry point label."
  (let ((*compile-lexical-env* (append (flatten-params params)
                                       *compile-lexical-env*)))
    (append-instruction-sequences
     (make-instruction-sequence
      '(env proc argl) '(env)
      `(,proc-entry
        (assign env (op compiled-procedure-env) (reg proc))
        (assign env (op extend-environment) (const ,params) (reg argl) (reg env))))
     (compile-sequence body 'val 'return))))

(defun compile-application (expr target linkage)
  (let ((proc-code (ece-compile (car expr) 'proc 'next))
        (operand-codes (mapcar (lambda (operand) (ece-compile operand 'val 'next))
                               (cdr expr))))
    (preserving '(env continue)
                proc-code
                (preserving '(proc continue)
                            (construct-arglist operand-codes)
                            (compile-procedure-call target linkage)))))

(defun construct-arglist (operand-codes)
  "Compile operands and build argl."
  (if (null operand-codes)
      (make-instruction-sequence '() '(argl) '((assign argl (const ()))))
      ;; Reverse to evaluate left-to-right, build list right-to-left
      (let ((rev-operand-codes (reverse operand-codes)))
        (let ((code-to-get-last-arg
               (append-2-sequences
                (car rev-operand-codes)
                (make-instruction-sequence '(val) '(argl)
                                           '((assign argl (op list) (reg val)))))))
          (if (null (cdr rev-operand-codes))
              code-to-get-last-arg
              (preserving '(env)
                          code-to-get-last-arg
                          (code-to-get-rest-args (cdr rev-operand-codes))))))))

(defun code-to-get-rest-args (operand-codes)
  (let ((code-for-next-arg
         (preserving '(argl)
                     (car operand-codes)
                     (make-instruction-sequence
                      '(val argl) '(argl)
                      '((assign argl (op cons) (reg val) (reg argl)))))))
    (if (null (cdr operand-codes))
        code-for-next-arg
        (preserving '(env)
                    code-for-next-arg
                    (code-to-get-rest-args (cdr operand-codes))))))

(defun compile-procedure-call (target linkage)
  "Emit apply dispatch for a procedure call."
  (let ((primitive-branch (make-label 'primitive-branch))
        (compiled-branch (make-label 'compiled-branch))
        (continuation-branch (make-label 'continuation-branch))
        (after-call (make-label 'after-call)))
    (let ((compiled-linkage (if (eq linkage 'next) after-call linkage)))
      (append-instruction-sequences
       (make-instruction-sequence
        '(proc) '()
        `((test (op primitive-procedure?) (reg proc))
          (branch (label ,primitive-branch))
          (test (op continuation?) (reg proc))
          (branch (label ,continuation-branch))))
       (parallel-instruction-sequences
        ;; Compiled branch
        (append-instruction-sequences
         compiled-branch
         (compile-proc-appl target compiled-linkage))
        (parallel-instruction-sequences
         ;; Continuation branch — non-local jump, always goto restored continue
         (append-instruction-sequences
          continuation-branch
          (make-instruction-sequence
           '(proc argl) '(stack continue val)
           `((assign val (op car) (reg argl))
             (assign stack (op continuation-stack) (reg proc))
             (assign continue (op continuation-conts) (reg proc))
             (goto (reg continue)))))
         ;; Primitive branch
         (append-instruction-sequences
          primitive-branch
          (end-with-linkage linkage
                            (make-instruction-sequence
                             '(proc argl) (list target)
                             `((assign ,target (op apply-primitive-procedure)
                                       (reg proc) (reg argl))))))))
       after-call))))

(defparameter *all-regs* '(env proc val argl continue))

(defun compile-proc-appl (target linkage)
  "Compile application of a compiled procedure."
  (cond
    ((and (eq target 'val) (not (eq linkage 'return)))
     ;; Non-tail call targeting val
     (make-instruction-sequence
      '(proc) *all-regs*
      `((assign continue (label ,linkage))
        (assign val (op compiled-procedure-entry) (reg proc))
        (goto (reg val)))))
    ((and (not (eq target 'val)) (not (eq linkage 'return)))
     ;; Non-tail call to other target
     (let ((proc-return (make-label 'proc-return)))
       (make-instruction-sequence
        '(proc) *all-regs*
        `((assign continue (label ,proc-return))
          (assign val (op compiled-procedure-entry) (reg proc))
          (goto (reg val))
          ,proc-return
          (assign ,target (reg val))
          (goto (label ,linkage))))))
    ((and (eq target 'val) (eq linkage 'return))
     ;; Tail call
     (make-instruction-sequence
      '(proc continue) *all-regs*
      '((assign val (op compiled-procedure-entry) (reg proc))
        (goto (reg val)))))
    ((and (not (eq target 'val)) (eq linkage 'return))
     (error "Return linkage, target not val -- COMPILE: ~A" target))))

;;; call/cc compilation

(defun compile-callcc (expr target linkage)
  "Compile (call/cc receiver-expr)."
  (let ((receiver-code (ece-compile (cadr expr) 'proc 'next))
        (return-label (make-label 'callcc-return)))
    (end-with-linkage linkage
                      (preserving '(env continue)
                                  receiver-code
                                  (make-instruction-sequence
                                   '(proc) (list target 'argl 'continue)
                                   `((assign continue (label ,return-label))
                                     (assign argl (op capture-continuation) (reg stack) (reg continue))
                                     (assign argl (op list) (reg argl))
                                     (assign val (op compiled-procedure-entry) (reg proc))
                                     (goto (reg val))
                                     ,return-label
                                     (assign ,target (reg val))))))))

;;; define-macro compilation

(defun compile-define-macro (expr target linkage)
  "Register a macro at compile time. Evaluate the macro body to capture it."
  (let* ((variable (caadr expr))
         (params (cdadr expr))
         (body (cddr expr)))
    ;; Store macro for compile-time expansion
    (setf (gethash variable *compile-time-macros*)
          (list params body *global-env*))
    ;; Also define it in the runtime env so it persists
    (define-variable! variable (list 'macro params body *global-env*) *global-env*)
    (end-with-linkage linkage
                      (make-instruction-sequence
                       '() (list target)
                       `((assign ,target (const ,variable)))))))

;;; apply form compilation

(defun compile-apply-form (expr target linkage)
  "Compile (apply proc-expr args-expr)."
  (let ((proc-code (ece-compile (cadr expr) 'proc 'next))
        (args-code (ece-compile (caddr expr) 'argl 'next)))
    (preserving '(env continue)
                proc-code
                (preserving '(proc continue)
                            args-code
                            (compile-procedure-call target linkage)))))

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

;;; Assembler

(defun assemble (instruction-list)
  "Convert flat instruction list (with label symbols) to vector + label table.
   Labels are symbols interspersed among instruction forms."
  (let ((label-table (make-hash-table :test 'eq))
        (instructions '())
        (index 0))
    (dolist (item instruction-list)
      (if (symbolp item)
          (setf (gethash item label-table) index)
          (progn (push item instructions) (incf index))))
    (values (coerce (nreverse instructions) 'vector) label-table)))

;;; Instruction executor

(defun execute-instructions (instruction-vector label-table initial-env
                             &optional (start-pc 0))
  "Execute assembled instructions from START-PC, return val register."
  (let ((pc start-pc)
        (flag nil)
        (val nil)
        (env initial-env)
        (proc nil)
        (argl nil)
        (continue nil)
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
       loop-end)
      val)))

;;; Global instruction accumulator
;;; All compiled code lives in one growing vector so compiled procedures
;;; can reference entry points from earlier compilations.

(defvar *global-instruction-vector*
  (make-array 256 :adjustable t :fill-pointer 0))

(defvar *global-label-table*
  (make-hash-table :test 'eq))

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
      (if (symbolp item)
          (setf (gethash item *global-label-table*)
                (fill-pointer *global-instruction-vector*))
          (vector-push-extend (resolve-operations item)
                              *global-instruction-vector*)))
    start-pc))

;;; compile-and-go: compile + assemble into global vector + execute

(defun compile-and-go (expr &optional (env *global-env*))
  "Compile EXPR and execute the resulting instructions in ENV."
  (let* ((compiled (ece-compile expr 'val 'next))
         (start-pc (assemble-into-global (instructions compiled))))
    (execute-instructions *global-instruction-vector*
                          *global-label-table*
                          env
                          start-pc)))

;;; compile-file: compile all forms from a file

(defun compile-file-ece (filename)
  "Read and compile-and-go all forms from an ECE source file."
  (with-open-file (stream filename :direction :input)
    (let ((*readtable* *ece-readtable*)
          (*read-eval* nil)
          (*package* (find-package :ece))
          (result nil))
      (loop for expr = (read stream nil *eof-sentinel*)
            until (eq expr *eof-sentinel*)
            do (setf result (compile-and-go expr)))
      result)))

;; Load the standard prelude (pure ECE stdlib definitions)
(compile-file-ece (asdf:system-relative-pathname :ece "src/prelude.scm"))


(defun repl ()
  "Bootstrap and run the ECE REPL as a tail-recursive ECE function."
  (evaluate
   '(begin
     (define (repl-loop)
      (display "ece> ")
      (define input (read))
      (if (eof? input)
          (begin (newline) (display "Bye!") (newline))
          (begin
           (define result (try-eval input))
           (if result (print result) (quote ()))
           (repl-loop))))
     (repl-loop))))

