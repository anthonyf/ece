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
  "Parse a number from string s. Returns nil on failure."
  (handler-case
      (let ((result (read-from-string s)))
        (if (numberp result) result nil))
    (error () nil)))

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

;; Load the standard prelude (pure ECE stdlib definitions)
(ece-load (asdf:system-relative-pathname :ece "src/prelude.scm"))

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

