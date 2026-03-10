(in-package :ece)

;;;; ========================================================================
;;;; COMPILER (SICP 5.5)
;;;; ========================================================================

;;; Expression predicates

(defun self-evaluating-p (expr)
  (or (numberp expr)
      (stringp expr)
      (characterp expr)
      (vectorp expr)
      (null expr)
      (eq expr t)
      (keywordp expr)
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
;;; *compile-time-macros* is declared in runtime.lisp (needed for image save/load)

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
                                   '(proc) *all-regs*
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
;;;; INTEGRATION
;;;; ========================================================================

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

(defun evaluate (expr &optional (env *global-env*))
  "Compile and execute EXPR in ENV."
  (compile-and-go expr env))

;;; Compiler-dependent primitives
;;; These call evaluate/compile-file-ece so they must be defined after the compiler.

(defun ece-try-eval (expr)
  "Evaluate expr, catching errors. Prints the error and returns nil on failure."
  (handler-case
      (evaluate expr)
    (error (c)
      (format t "Error: ~A~%" c)
      (finish-output)
      nil)))

(defun ece-load (filename)
  "Load and compile all expressions from an ECE source file."
  (compile-file-ece filename))

(define-variable! 'try-eval (list 'primitive 'ece-try-eval) *global-env*)
(define-variable! 'load (list 'primitive 'ece-load) *global-env*)
(define-variable! 'save-image! (list 'primitive 'ece-save-image) *global-env*)
(define-variable! 'load-image! (list 'primitive 'ece-load-image) *global-env*)
(define-variable! 'assemble-into-global (list 'primitive 'assemble-into-global) *global-env*)
(define-variable! 'execute-from-pc (list 'primitive 'ece-execute-from-pc) *global-env*)
(define-variable! 'get-macro (list 'primitive 'ece-get-macro) *global-env*)
(define-variable! 'set-macro! (list 'primitive 'ece-set-macro!) *global-env*)
(define-variable! 'expand-macro (list 'primitive 'expand-macro-at-compile-time) *global-env*)

;; Load the standard prelude (pure ECE stdlib definitions)
(compile-file-ece (asdf:system-relative-pathname :ece "src/prelude.scm"))

;; Load the metacircular compiler (ECE compiler written in ECE)
(compile-file-ece (asdf:system-relative-pathname :ece "src/compiler.scm"))

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
