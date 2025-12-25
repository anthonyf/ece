(uiop:define-package #:ece
  (:use #:cl)
  (:export #:*global-env*
	   #:evaluate
	   #:lambda
	   #:var
	   #:set
	   #:if
	   #:begin
	   #:quote))

(in-package :ece)

(defun env-lookup (env var)
  (cond
    ((null env)
     (error "Unbound variable: ~A" var))
    ((eq var (caar env))
     (cdar env))
    (t
     (env-lookup (cdr env) var))))

(defparameter *primitive-procedures* (mapcar (lambda (proc)
					       (if (listp proc)
						   (cons (car proc) (list 'primitive (symbol-function (cdr proc))))
						   (cons proc (list 'primitive (symbol-function proc)))))
					     '(+ - * / = < > <= >= car cdr cons list (null? . null) not)))

(defparameter *global-env* (append *primitive-procedures*
				   nil))

#+nil
(env-lookup '((x . 10) (y . 20)) 'x) ;; => 10

(defun self-evaluating-p (expr)
  (or (numberp expr)
      (stringp expr)))

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


(defparameter *special-forms* '(quote if var set lambda begin))

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
		    ((lambda-p expr)          (push :ev-lambda conts))
		    ((application-p expr)     (push :ev-application conts))
		    ((begin-p expr)           (push :ev-begin conts))
		    (t (error "Unknown expression type: ~A" expr)))
		  #+nil (dbg :ev-dispatch :end))

		 (:ev-self-eval
		  #+nil (dbg :ev-self-eval :start)
		  (setf val expr)
		  #+nil (dbg :ev-self-eval :end))

		 (:ev-variable
		  #+nil (dbg :ev-variable :start)
		  (setf val (env-lookup env expr))
		  #+nil (dbg :ev-variable :end))

		 (:ev-quoted
		  #+nil (dbg :ev-quoted :start)
		  (setf val (cadr expr))
		  #+nil (dbg :ev-quoted :end))

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
		  (if (null unev)
		      (push :apply-dispatch conts)
		      (progn (push proc stack)
			     (push :ev-appl-operand-loop conts)))
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
		  (if (eq (car proc) 'primitive)
		      (push :primitive-apply conts)
		      (if (eq (car proc) 'procedure)
			  (push :compound-apply conts)
			  (push :unknown-procedure-type conts)))
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
		  (setf env (append (mapcar #'cons unev (nreverse argl)) env)) ;; extend env
		  (setf unev (caddr proc)) ;; body
		  (push :ev-sequence conts)
		  #+nil (dbg :compound-apply :end)
		  )
		 (:unknown-procedure-type
		  #+nil (dbg :unknown-procedure-type :start)
		  (error "Unknown procedure type: ~A" proc))
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
		  ;; (assign exp (op callcc-receiver) (reg exp)) ; Get the receiver function
		  ;; (assign val (op make-continuation) (reg stack) (reg continue)) ; Capture stack/continue
		  ;; (assign argl (op list) (reg val)) ; Wrap continuation as the argument
		  ;; (goto (label apply-dispatch)) ; Apply the receiver to the continuation
		  )
		 (:ev-if
		  ;; ev-if
		  ;; (save exp)   ; save expression for later
		  ;; (save env)
		  ;; (save continue)
		  ;; (assign continue (label ev-if-decide))
		  ;; (assign exp (op if-predicate) (reg exp))
		  ;; 			; evaluate the predicate:
		  ;; (goto (label eval-dispatch))  
		  )
		 (:ev-if-decide
		  ;; ev-if-decide
		  ;; (restore continue)
		  ;; (restore env)
		  ;; (restore exp)
		  ;; (test (op true?) (reg val))
		  ;; (branch (label ev-if-consequent))
		  )
		 (:ev-if-alternative
		  ;; ev-if-alternative
		  ;; (assign exp (op if-alternative) (reg exp))
		  ;; (goto (label eval-dispatch))
		  )
		 (:ev-if-consequent
		  ;; ev-if-consequent
		  ;; (assign exp (op if-consequent) (reg exp))
		  ;; (goto (label eval-dispatch))		  
		  )
		
		 (t (error "Unknown cont: ~A" cont)))))
    val))

