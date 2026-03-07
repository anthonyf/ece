(uiop:define-package #:ece
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

(defparameter *primitive-procedure-names*
  (mapcar (lambda (proc) (if (listp proc) (car proc) proc))
          '(+ - * / = < > <= >= car cdr cadr caddr caar cddr cons list append length
            (null? . null) (pair? . consp) not
            (number? . numberp) (string? . stringp) (symbol? . symbolp)
            (zero? . zerop) (even? . evenp) (odd? . oddp)
            (positive? . plusp) (negative? . minusp)
            (eq? . eq) (equal? . equal)
            (modulo . mod) abs min max reverse)))

(defparameter *primitive-procedure-objects*
  (mapcar (lambda (proc)
            (list 'primitive (symbol-function (if (listp proc) (cdr proc) proc))))
          '(+ - * / = < > <= >= car cdr cadr caddr caar cddr cons list append length
            (null? . null) (pair? . consp) not
            (number? . numberp) (string? . stringp) (symbol? . symbolp)
            (zero? . zerop) (even? . evenp) (odd? . oddp)
            (positive? . plusp) (negative? . minusp)
            (eq? . eq) (equal? . equal)
            (modulo . mod) abs min max reverse)))

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

(dolist (entry (list (cons 'read (list 'primitive #'ece-read))
                     (cons 'print (list 'primitive #'print))
                     (cons 'display (list 'primitive #'ece-display))
                     (cons 'newline (list 'primitive #'ece-newline))
                     (cons 'eof? (list 'primitive #'ece-eof-p))
                     (cons 'try-eval (list 'primitive #'ece-try-eval))
                     (cons 'boolean? (list 'primitive #'ece-boolean-p))
                     (cons 'gensym (list 'primitive #'gensym))))
  (define-variable! (car entry) (cdr entry) *global-env*))

(defun self-evaluating-p (expr)
  (or (numberp expr)
      (stringp expr)
      (null expr)
      (eq expr t)))

(defun variable-p (expr)
  (symbolp expr))

(defun assignment-p (expr)
  (and (listp expr)
       (eq (car expr) 'set)))

(defun quoted-p (expr)
  (and (listp expr)
       (eq (car expr) 'quote)))

(defun lambda-p (expr)
  (and (listp expr)
       (eq (car expr) 'lambda)))

(defun make-procedure (parameters body env)
  (list 'procedure parameters body env))

(defun begin-p (expr)
  (and (listp expr)
       (eq (car expr) 'begin)))

(defun if-p (expr)
  (and (listp expr)
       (eq (car expr) 'if)))

(defun callcc-p (expr)
  (and (listp expr)
       (eq (car expr) 'call/cc)))

(defun define-p (expr)
  (and (listp expr)
       (eq (car expr) 'define)))

(defun apply-form-p (expr)
  (and (listp expr)
       (eq (car expr) 'apply)))

(defun define-macro-p (expr)
  (and (listp expr)
       (eq (car expr) 'define-macro)))

(defun quasiquote-p (expr)
  (and (listp expr)
       (eq (car expr) 'quasiquote)))

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
		  ;; 	(op lambda-parameters)
		  ;; 	(reg exp))
		  ;; (assign exp 
		  ;; 	(op lambda-body)
		  ;; 	(reg exp))
		  ;; (assign val 
		  ;; 	(op make-procedure)
		  ;; 	(reg unev)
		  ;; 	(reg exp)
		  ;; 	(reg env))
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
		  ;; (restore unev)		; the operands
		  ;; (restore env)
		  ;; (assign argl (op empty-arglist))
		  ;; (assign proc (reg val))	; the operator
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
		  ;; 	(op first-operand)
		  ;; 	(reg unev))
		  ;; (test (op last-operand?) (reg unev))
		  ;; (branch (label ev-appl-last-arg))
		  ;; (save env)
		  ;; (save unev)
		  ;; (assign continue 
		  ;; 	(label ev-appl-accumulate-arg))
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
		  ;; 	(op adjoin-arg)
		  ;; 	(reg val)
		  ;; 	(reg argl))
		  ;; (assign unev
		  ;; 	(op rest-operands)
		  ;; 	(reg unev))
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
		  ;; 	(label ev-appl-accum-last-arg))
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
		  ;; 	(op adjoin-arg)
		  ;; 	(reg val)
		  ;; 	(reg argl))
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
		  ;; 	(reg proc)
		  ;; 	(reg argl))
		  ;; (restore continue)
		  ;; (goto (reg continue))
		  #+nil (dbg :primitive-apply :start)
		  (setf val (apply (cadr proc) (nreverse argl)))
		  (setf conts (pop stack))
		  #+nil (dbg :primitive-apply :end)
		  )
		 (:compound-apply
		  ;; compound-apply
		  ;; (assign unev 
		  ;; 	(op procedure-parameters)
		  ;; 	(reg proc))
		  ;; (assign env
		  ;; 	(op procedure-environment)
		  ;; 	(reg proc))
		  ;; (assign env
		  ;; 	(op extend-environment)
		  ;; 	(reg unev)
		  ;; 	(reg argl)
		  ;; 	(reg env))
		  ;; (assign unev
		  ;; 	(op procedure-body)
		  ;; 	(reg proc))
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
		  ;; 	(op begin-actions)
		  ;; 	(reg exp))
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
		  ;; 	(label ev-sequence-continue))
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
		  ;; 	(op rest-exps)
		  ;; 	(reg unev))
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

;; Define map as an ECE function (must be after evaluate is defined)
(evaluate
 '(define (map f lst)
    (begin
      (define (loop rest acc)
        (if (null? rest)
            (reverse acc)
            (loop (cdr rest) (cons (f (car rest)) acc))))
      (loop lst (quote ())))))

(evaluate
 '(define (reduce f init lst)
    (if (null? lst)
        init
        (reduce f (f init (car lst)) (cdr lst)))))

(evaluate
 '(define (for-each f lst)
    (if (null? lst)
        (quote ())
        (begin (f (car lst))
               (for-each f (cdr lst))))))

(evaluate
 '(define (filter pred lst)
    (begin
      (define (loop rest acc)
        (if (null? rest)
            (reverse acc)
            (if (pred (car rest))
                (loop (cdr rest) (cons (car rest) acc))
                (loop (cdr rest) acc))))
      (loop lst (quote ())))))

;; Standard derived forms (defined as macros)
;; Switch to ECE readtable so ` , ,@ produce ECE quasiquote forms
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* *ece-readtable*))

(evaluate
 '(define-macro (cond . clauses)
    (if (null? clauses)
        (quote ())
        (if (eq? (caar clauses) (quote else))
            `(begin ,@(cdr (car clauses)))
            `(if ,(caar clauses)
                 (begin ,@(cdr (car clauses)))
                 (cond ,@(cdr clauses)))))))

(evaluate
 '(define-macro (let bindings . body)
    (if (symbol? bindings)
        ;; Named let: (let name ((var init) ...) body...)
        ;; bindings is the name, (car body) is the actual bindings, (cdr body) is the real body
        `(begin (define (,bindings ,@(map car (car body))) ,@(cdr body))
                (,bindings ,@(map cadr (car body))))
        ;; Regular let: (let ((var init) ...) body...)
        (cons `(lambda ,(map car bindings)
                 ,@body)
              (map cadr bindings)))))

(evaluate
 '(define-macro (let* bindings . body)
    (if (null? bindings)
        `(begin ,@body)
        `(let (,(car bindings))
           (let* ,(cdr bindings) ,@body)))))

(evaluate
 '(define-macro (and . args)
    (if (null? args)
        (quote t)
        (if (null? (cdr args))
            (car args)
            `(if ,(car args)
                 (and ,@(cdr args))
                 ())))))

(evaluate
 '(define-macro (or . args)
    (if (null? args)
        (quote ())
        (if (null? (cdr args))
            (car args)
            (let ((temp (gensym)))
              `(let ((,temp ,(car args)))
                 (if ,temp
                     ,temp
                     (or ,@(cdr args)))))))))

(evaluate
 '(define-macro (when test . body)
    `(if ,test (begin ,@body) ())))

(evaluate
 '(define-macro (unless test . body)
    `(if ,test () (begin ,@body))))

(evaluate
 '(define-macro (letrec bindings . body)
    `(let ,(map (lambda (b) (list (car b) (quote ()))) bindings)
       ,@(map (lambda (b) `(set ,(car b) ,(cadr b))) bindings)
       ,@body)))

(evaluate
 '(define-macro (case key . clauses)
    (define (expand-clauses k clauses)
      (if (null? clauses)
          (quote ())
          (if (eq? (caar clauses) (quote else))
              `(begin ,@(cdr (car clauses)))
              `(if ,(if (null? (cdr (caar clauses)))
                        `(equal? ,k (quote ,(caar (car clauses))))
                        `(or ,@(map (lambda (d) `(equal? ,k (quote ,d)))
                                    (caar clauses))))
                   (begin ,@(cdr (car clauses)))
                   ,(expand-clauses k (cdr clauses))))))
    (define (temp) (gensym))
    ((lambda (g)
       `((lambda (,g) ,(expand-clauses g clauses)) ,key))
     (temp))))

(evaluate
 '(define-macro (do bindings test-and-result . body)
    (define (var-inits) (map (lambda (b) (list (car b) (cadr b))) bindings))
    (define (var-steps)
      (map (lambda (b)
             (if (null? (cddr b))
                 (car b)
                 (caddr b)))
           bindings))
    (define (test-expr) (car test-and-result))
    (define (result-exprs) (cdr test-and-result))
    (define (loop-name) (gensym))
    ((lambda (name)
       `(let ,name ,(var-inits)
          (if ,(test-expr)
              (begin ,@(if (null? (result-exprs)) (list (quote ())) (result-exprs)))
              (begin ,@body (,name ,@(var-steps))))))
     (loop-name))))

;; Restore standard readtable
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))

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

