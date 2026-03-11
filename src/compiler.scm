;;; ECE Metacircular Compiler
;;; A self-hosting compiler for ECE, ported from compiler.lisp (SICP 5.5).
;;; Compiles ECE expressions to register machine instructions.

;;; Instruction sequences: (needs modifies instructions)
;;; - needs: list of registers read before any write
;;; - modifies: list of registers written
;;; - instructions: list of instruction forms

(define (make-instruction-sequence needs modifies instructions)
  (list needs modifies instructions))

(define (instruction-seq-needs seq) (car seq))
(define (instruction-seq-modifies seq) (cadr seq))
(define (instruction-seq-instructions seq) (caddr seq))

(define (empty-instruction-sequence)
  (make-instruction-sequence '() '() '()))

(define (registers-needed seq)
  (if (symbol? seq) '() (instruction-seq-needs seq)))

(define (registers-modified seq)
  (if (symbol? seq) '() (instruction-seq-modifies seq)))

(define (mc-instructions seq)
  (if (symbol? seq) (list seq) (instruction-seq-instructions seq)))

(define (needs-register? seq reg)
  (member reg (registers-needed seq)))

(define (modifies-register? seq reg)
  (member reg (registers-modified seq)))

;;; Combining instruction sequences

(define (append-2-sequences seq1 seq2)
  (make-instruction-sequence
   (union (registers-needed seq1)
          (set-difference (registers-needed seq2)
                          (registers-modified seq1)))
   (union (registers-modified seq1)
          (registers-modified seq2))
   (append (mc-instructions seq1) (mc-instructions seq2))))

(define (append-instruction-sequences . seqs)
  (reduce append-2-sequences (empty-instruction-sequence) seqs))

(define (tack-on-instruction-sequence seq body-seq)
  (make-instruction-sequence
   (registers-needed seq)
   (registers-modified seq)
   (append (mc-instructions seq) (mc-instructions body-seq))))

(define (parallel-instruction-sequences seq1 seq2)
  (make-instruction-sequence
   (union (registers-needed seq1) (registers-needed seq2))
   (union (registers-modified seq1) (registers-modified seq2))
   (append (mc-instructions seq1) (mc-instructions seq2))))

;;; Preserving: the core optimization

(define (preserving regs seq1 seq2)
  (if (null? regs)
      (append-2-sequences seq1 seq2)
      (let ((first-reg (car regs)))
        (if (and (modifies-register? seq1 first-reg)
                 (needs-register? seq2 first-reg))
            (preserving (cdr regs)
                        (make-instruction-sequence
                         (union (list first-reg) (registers-needed seq1))
                         (set-difference (registers-modified seq1)
                                         (list first-reg))
                         (append (list (list 'save first-reg))
                                 (mc-instructions seq1)
                                 (list (list 'restore first-reg))))
                        seq2)
            (preserving (cdr regs) seq1 seq2)))))

;;; Label generation

(define mc-label-counter 0)

(define (mc-make-label name)
  (set mc-label-counter (+ mc-label-counter 1))
  (string->symbol
   (string-append "mc-" (symbol->string name) "-" (number->string mc-label-counter))))

;;; Linkage code

(define (compile-linkage linkage)
  (cond ((eq? linkage 'next) (empty-instruction-sequence))
        ((eq? linkage 'return)
         (make-instruction-sequence '(continue) '() '((goto (reg continue)))))
        (else
         (make-instruction-sequence '() '() (list (list 'goto (list 'label linkage)))))))

(define (end-with-linkage linkage instruction-sequence)
  (preserving '(continue)
              instruction-sequence
              (compile-linkage linkage)))

;;; Expression predicates

(define *mc-special-forms*
  '(quote if var set lambda begin call/cc define apply define-macro quasiquote))

(define (mc-self-evaluating? expr)
  (or (number? expr)
      (string? expr)
      (char? expr)
      (vector? expr)
      (null? expr)
      (eq? expr t)
      (and (pair? expr) (eq? (car expr) :hash-table))))

(define (mc-variable? expr)
  (symbol? expr))

(define (mc-tagged-list? expr tag)
  (and (pair? expr) (eq? (car expr) tag)))

(define (mc-quoted? expr) (mc-tagged-list? expr 'quote))
(define (mc-quasiquote? expr) (mc-tagged-list? expr 'quasiquote))
(define (mc-lambda? expr) (mc-tagged-list? expr 'lambda))
(define (mc-begin? expr) (mc-tagged-list? expr 'begin))
(define (mc-if? expr) (mc-tagged-list? expr 'if))
(define (mc-callcc? expr) (mc-tagged-list? expr 'call/cc))
(define (mc-define? expr) (mc-tagged-list? expr 'define))
(define (mc-assignment? expr) (mc-tagged-list? expr 'set))
(define (mc-apply-form? expr) (mc-tagged-list? expr 'apply))
(define (mc-define-macro? expr) (mc-tagged-list? expr 'define-macro))

(define (mc-application? expr)
  (and (pair? expr)
       (not (null? expr))
       (not (member (car expr) *mc-special-forms*))))

;;; Compile functions — core forms

(define (mc-compile-self-evaluating expr target linkage)
  (end-with-linkage linkage
                    (make-instruction-sequence
                     '() (list target)
                     (list (list 'assign target (list 'const expr))))))

(define (mc-compile-variable expr target linkage)
  (end-with-linkage linkage
                    (make-instruction-sequence
                     '(env) (list target)
                     (list (list 'assign target
                                 '(op lookup-variable-value)
                                 (list 'const expr)
                                 '(reg env))))))

(define (mc-compile-quoted expr target linkage)
  (end-with-linkage linkage
                    (make-instruction-sequence
                     '() (list target)
                     (list (list 'assign target (list 'const (cadr expr)))))))

(define (mc-compile-if expr target linkage)
  (let ((true-branch (mc-make-label 'true-branch))
        (false-branch (mc-make-label 'false-branch))
        (after-if (mc-make-label 'after-if)))
    (let ((consequent-linkage (if (eq? linkage 'next) after-if linkage)))
      (let ((predicate-code (mc-compile (cadr expr) 'val 'next))
            (consequent-code (mc-compile (caddr expr) target consequent-linkage))
            (alternative-code (mc-compile (if (cdr (cddr expr)) (cadr (cddr expr)) '())
                                          target linkage)))
        (preserving '(env continue)
                    predicate-code
                    (append-instruction-sequences
                     (make-instruction-sequence
                      '(val) '()
                      (list '(test (op false?) (reg val))
                            (list 'branch (list 'label false-branch))))
                     (parallel-instruction-sequences
                      (append-instruction-sequences true-branch consequent-code)
                      (append-instruction-sequences false-branch alternative-code))
                     after-if))))))

(define (mc-extract-define-names body)
  (filter (lambda (x) x)
          (map (lambda (form)
                 (if (and (pair? form) (eq? (car form) 'define))
                     (let ((name-spec (cadr form)))
                       (if (pair? name-spec) (car name-spec) name-spec))
                     ()))
               body)))

(define (mc-compile-begin expr target linkage)
  (let ((body (cdr expr)))
    (let ((defined-names (mc-extract-define-names body)))
      (if (not (null? defined-names))
          (parameterize ((*mc-compile-lexical-env*
                          (append defined-names (*mc-compile-lexical-env*))))
            (mc-compile-sequence body target linkage))
          (mc-compile-sequence body target linkage)))))

(define (mc-compile-sequence seq target linkage)
  (if (null? (cdr seq))
      (mc-compile (car seq) target linkage)
      ;; Use let to force left-to-right compilation order.
      ;; Without this, right-to-left argument evaluation in the SICP compiler
      ;; causes (mc-compile-sequence rest) to run before (mc-compile first),
      ;; breaking define-macro side effects that must happen before later forms.
      (let ((first-seq (mc-compile (car seq) target 'next)))
        (preserving '(env continue)
                    first-seq
                    (mc-compile-sequence (cdr seq) target linkage)))))

;;; Lambda & application

(define (mc-flatten-params params)
  (cond ((null? params) '())
        ((symbol? params) (list params))
        ((pair? params) (cons (car params) (mc-flatten-params (cdr params))))))

(define (mc-compile-lambda-body params body proc-entry)
  (parameterize ((*mc-compile-lexical-env*
                  (append (mc-flatten-params params) (*mc-compile-lexical-env*))))
    (append-instruction-sequences
     (make-instruction-sequence
      '(env proc argl) '(env)
      (list proc-entry
            '(assign env (op compiled-procedure-env) (reg proc))
            (list 'assign 'env '(op extend-environment)
                  (list 'const params) '(reg argl) '(reg env))))
     (mc-compile-sequence body 'val 'return))))

(define (mc-compile-lambda expr target linkage)
  (let ((proc-entry (mc-make-label 'entry))
        (after-lambda (mc-make-label 'after-lambda)))
    (let ((lambda-linkage (if (eq? linkage 'next) after-lambda linkage)))
      (let ((params (cadr expr))
            (body (cddr expr)))
        (let ((body-code (mc-compile-lambda-body params body proc-entry)))
          (append-instruction-sequences
           (tack-on-instruction-sequence
            (end-with-linkage lambda-linkage
                              (make-instruction-sequence
                               '(env) (list target)
                               (list (list 'assign target '(op make-compiled-procedure)
                                           (list 'label proc-entry) '(reg env)))))
            body-code)
           after-lambda))))))

(define *mc-all-regs* '(env proc val argl continue))

(define (mc-compile-proc-appl target linkage)
  (cond
   ((and (eq? target 'val) (not (eq? linkage 'return)))
    (make-instruction-sequence
     '(proc) *mc-all-regs*
     (list (list 'assign 'continue (list 'label linkage))
           '(assign val (op compiled-procedure-entry) (reg proc))
           '(goto (reg val)))))
   ((and (not (eq? target 'val)) (not (eq? linkage 'return)))
    (let ((proc-return (mc-make-label 'proc-return)))
      (make-instruction-sequence
       '(proc) *mc-all-regs*
       (list (list 'assign 'continue (list 'label proc-return))
             '(assign val (op compiled-procedure-entry) (reg proc))
             '(goto (reg val))
             proc-return
             (list 'assign target '(reg val))
             (list 'goto (list 'label linkage))))))
   ((and (eq? target 'val) (eq? linkage 'return))
    (make-instruction-sequence
     '(proc continue) *mc-all-regs*
     '((assign val (op compiled-procedure-entry) (reg proc))
       (goto (reg val)))))
   ((and (not (eq? target 'val)) (eq? linkage 'return))
    (error "Return linkage, target not val -- MC-COMPILE"))))

(define (mc-compile-procedure-call target linkage)
  (let ((primitive-branch (mc-make-label 'primitive-branch))
        (compiled-branch (mc-make-label 'compiled-branch))
        (continuation-branch (mc-make-label 'continuation-branch))
        (after-call (mc-make-label 'after-call)))
    (let ((compiled-linkage (if (eq? linkage 'next) after-call linkage)))
      (append-instruction-sequences
       (make-instruction-sequence
        '(proc) '()
        (list '(test (op primitive-procedure?) (reg proc))
              (list 'branch (list 'label primitive-branch))
              '(test (op continuation?) (reg proc))
              (list 'branch (list 'label continuation-branch))))
       (parallel-instruction-sequences
        ;; Compiled branch
        (append-instruction-sequences
         compiled-branch
         (mc-compile-proc-appl target compiled-linkage))
        (parallel-instruction-sequences
         ;; Continuation branch
         (append-instruction-sequences
          continuation-branch
          (make-instruction-sequence
           '(proc argl) '(stack continue val)
           '((assign val (op car) (reg argl))
             (assign stack (op continuation-stack) (reg proc))
             (assign continue (op continuation-conts) (reg proc))
             (goto (reg continue)))))
         ;; Primitive branch
         (append-instruction-sequences
          primitive-branch
          (end-with-linkage linkage
                            (make-instruction-sequence
                             '(proc argl) (list target)
                             (list (list 'assign target '(op apply-primitive-procedure)
                                         '(reg proc) '(reg argl))))))))
       after-call))))

(define (mc-code-to-get-rest-args operand-codes)
  (let ((code-for-next-arg
         (preserving '(argl)
                     (car operand-codes)
                     (make-instruction-sequence
                      '(val argl) '(argl)
                      '((assign argl (op cons) (reg val) (reg argl)))))))
    (if (null? (cdr operand-codes))
        code-for-next-arg
        (preserving '(env)
                    code-for-next-arg
                    (mc-code-to-get-rest-args (cdr operand-codes))))))

(define (mc-construct-arglist operand-codes)
  (if (null? operand-codes)
      (make-instruction-sequence '() '(argl) '((assign argl (const ()))))
      (let ((rev-operand-codes (reverse operand-codes)))
        (let ((code-to-get-last-arg
               (append-2-sequences
                (car rev-operand-codes)
                (make-instruction-sequence '(val) '(argl)
                                           '((assign argl (op list) (reg val)))))))
          (if (null? (cdr rev-operand-codes))
              code-to-get-last-arg
              (preserving '(env)
                          code-to-get-last-arg
                          (mc-code-to-get-rest-args (cdr rev-operand-codes))))))))

(define (mc-compile-application expr target linkage)
  (let ((proc-code (mc-compile (car expr) 'proc 'next))
        (operand-codes (map (lambda (operand) (mc-compile operand 'val 'next))
                            (cdr expr))))
    (preserving '(env continue)
                proc-code
                (preserving '(proc continue)
                            (mc-construct-arglist operand-codes)
                            (mc-compile-procedure-call target linkage)))))

;;; Remaining special forms

(define (mc-compile-assignment expr target linkage)
  (let ((variable (cadr expr))
        (value-code (mc-compile (caddr expr) 'val 'next)))
    (end-with-linkage linkage
                      (preserving '(env)
                                  value-code
                                  (make-instruction-sequence
                                   '(env val) (list target)
                                   (list (list 'perform '(op set-variable-value!)
                                               (list 'const variable) '(reg val) '(reg env))
                                         (list 'assign target '(reg val))))))))

(define (mc-find-entry-label instruction-list)
  "Find the entry label from a compiled lambda's instruction list."
  (if (null? instruction-list)
      ()
      (let ((instr (car instruction-list)))
        (if (and (pair? instr)
                 (eq? (car instr) 'assign)
                 (pair? (caddr instr))
                 (eq? (car (caddr instr)) 'op)
                 (eq? (cadr (caddr instr)) 'make-compiled-procedure))
            (let ((label-arg (car (cdr (cddr instr)))))
              (if (and (pair? label-arg) (eq? (car label-arg) 'label))
                  (cadr label-arg)
                  (mc-find-entry-label (cdr instruction-list))))
            (mc-find-entry-label (cdr instruction-list))))))

(define (mc-compile-define expr target linkage)
  (let ((variable (if (pair? (cadr expr)) (car (cadr expr)) (cadr expr)))
        (value-expr (if (pair? (cadr expr))
                        (cons 'lambda (cons (cdr (cadr expr)) (cddr expr)))
                        (caddr expr))))
    (let ((value-code (mc-compile value-expr 'val 'next)))
      (let ((define-code (preserving '(env)
                                     value-code
                                     (make-instruction-sequence
                                      '(env val) (list target)
                                      (list (list 'perform '(op define-variable!)
                                                  (list 'const variable) '(reg val) '(reg env))
                                            (list 'assign target '(reg val))))))
            (entry-label (if (and (pair? value-expr) (eq? (car value-expr) 'lambda))
                             (mc-find-entry-label (mc-instructions value-code))
                             ())))
        (end-with-linkage linkage
                          (if entry-label
                              (append-instruction-sequences
                               define-code
                               (make-instruction-sequence
                                '() '()
                                (list (list 'procedure-name entry-label variable))))
                              define-code))))))

(define (mc-compile-callcc expr target linkage)
  (let ((receiver-code (mc-compile (cadr expr) 'proc 'next))
        (return-label (mc-make-label 'callcc-return)))
    (end-with-linkage linkage
                      (preserving '(env continue)
                                  receiver-code
                                  (make-instruction-sequence
                                   '(proc) *mc-all-regs*
                                   (list (list 'assign 'continue (list 'label return-label))
                                         '(assign argl (op capture-continuation) (reg stack) (reg continue))
                                         '(assign argl (op list) (reg argl))
                                         '(assign val (op compiled-procedure-entry) (reg proc))
                                         '(goto (reg val))
                                         return-label
                                         (list 'assign target '(reg val))))))))

(define (mc-compile-apply-form expr target linkage)
  (let ((proc-code (mc-compile (cadr expr) 'proc 'next))
        (args-code (mc-compile (caddr expr) 'argl 'next)))
    (preserving '(env continue)
                proc-code
                (preserving '(proc continue)
                            args-code
                            (mc-compile-procedure-call target linkage)))))

;;; Compile-time macro expansion (self-hosted)
;;; Expands macros using ECE's own mc-compile-and-go instead of CL primitive.

(define (mc-expand-macro-at-compile-time macro-def operands)
  (let ((params (car macro-def))
        (body (cadr macro-def))
        (macro-env (caddr macro-def)))
    (let ((expansion-env (extend-environment params operands macro-env)))
      (let loop ((exprs body) (result '()))
        (if (null? exprs)
            result
            (loop (cdr exprs) (mc-compile-and-go (car exprs) expansion-env)))))))

(define (mc-compile-define-macro expr target linkage)
  (let ((variable (car (cadr expr)))
        (params (cdr (cadr expr)))
        (body (cddr expr)))
    ;; Store macro for compile-time expansion using the shared macro table
    (set-macro! variable (list params body *global-env*))
    (end-with-linkage linkage
                      (make-instruction-sequence
                       '() (list target)
                       (list (list 'assign target (list 'const variable)))))))

;;; Quasiquote expansion

(define (mc-qq-expand form depth)
  (cond
   ((null? form) '(quote ()))
   ((not (pair? form)) (list 'quote form))
   ;; nested quasiquote
   ((eq? (car form) 'quasiquote)
    (list 'list (list 'quote 'quasiquote) (mc-qq-expand (cadr form) (+ depth 1))))
   ;; unquote at depth 0
   ((and (eq? (car form) 'unquote) (= depth 0))
    (cadr form))
   ;; unquote at depth > 0
   ((and (eq? (car form) 'unquote) (> depth 0))
    (list 'list (list 'quote 'unquote) (mc-qq-expand (cadr form) (- depth 1))))
   ;; unquote-splicing at depth 0
   ((and (pair? (car form)) (eq? (car (car form)) 'unquote-splicing) (= depth 0))
    (list 'append (cadr (car form)) (mc-qq-expand (cdr form) depth)))
   ;; unquote-splicing at depth > 0
   ((and (pair? (car form)) (eq? (car (car form)) 'unquote-splicing) (> depth 0))
    (list 'cons
          (list 'list (list 'quote 'unquote-splicing)
                (mc-qq-expand (cadr (car form)) (- depth 1)))
          (mc-qq-expand (cdr form) depth)))
   (else (list 'cons (mc-qq-expand (car form) depth) (mc-qq-expand (cdr form) depth)))))

(define (mc-compile-quasiquote expr target linkage)
  (let ((expanded (mc-qq-expand (cadr expr) 0)))
    (mc-compile expanded target linkage)))

;;; Main compile dispatch

(define *mc-compile-lexical-env* (make-parameter '()))

(define (mc-compile expr target linkage)
  (cond
   ((mc-self-evaluating? expr) (mc-compile-self-evaluating expr target linkage))
   ((mc-variable? expr) (mc-compile-variable expr target linkage))
   ((mc-quoted? expr) (mc-compile-quoted expr target linkage))
   ((mc-quasiquote? expr) (mc-compile-quasiquote expr target linkage))
   ((mc-lambda? expr) (mc-compile-lambda expr target linkage))
   ((mc-if? expr) (mc-compile-if expr target linkage))
   ((mc-callcc? expr) (mc-compile-callcc expr target linkage))
   ((mc-assignment? expr) (mc-compile-assignment expr target linkage))
   ((mc-apply-form? expr) (mc-compile-apply-form expr target linkage))
   ((mc-define-macro? expr) (mc-compile-define-macro expr target linkage))
   ((mc-define? expr) (mc-compile-define expr target linkage))
   ((mc-begin? expr) (mc-compile-begin expr target linkage))
   ((mc-application? expr)
    ;; Check for compile-time macro (skip if operator is lexically shadowed)
    (let ((macro-def (if (member (car expr) (*mc-compile-lexical-env*))
                         ()
                         (get-macro (car expr)))))
      (if macro-def
          (mc-compile (mc-expand-macro-at-compile-time macro-def (cdr expr))
                      target linkage)
          (mc-compile-application expr target linkage))))
   (else (error (string-append "Unknown expression type -- MC-COMPILE: "
                               (write-to-string expr))))))

;;; Integration: compile-and-go via metacircular compiler

(define (mc-compile-and-go expr . env-args)
  (let ((compiled (mc-compile expr 'val 'next)))
    (let ((start-pc (assemble-into-global (mc-instructions compiled))))
      (if (null? env-args)
          (execute-from-pc start-pc)
          (execute-from-pc start-pc (car env-args))))))

(define (eval expr) (mc-compile-and-go expr))
