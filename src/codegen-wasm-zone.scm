;;; codegen-wasm-zone.scm -- register-machine WASM native-zone generator.
;;;
;;; This is deliberately not a direct-style Scheme-to-WASM compiler. It emits
;;; side-module functions that implement the existing ECE register-machine
;;; native-zone ABI:
;;;
;;;   zone(pc, val, env, proc, argl, continue, stack, co) -> result-vector
;;;
;;; Unsupported code objects return #f from the generator, leaving execution on
;;; the interpreter path. The supported subset is a register-machine PC loop:
;;;
;;;   (assign <register> (const <fixnum>))
;;;   (assign <register> (const ()))
;;;   (assign <register> (const #t))
;;;   (assign <register> (const #f))
;;;   (assign <register> (reg <register>))
;;;   (assign <register> (op list) <operand> ...)
;;;   (assign <register> (op cons) <operand> <operand>)
;;;   (assign <register> (op car) <operand>)
;;;   (assign <register> (op cdr) <operand>)
;;;   (assign <register> (op lookup-variable-value)
;;;                      (const <symbol>) (reg env))
;;;   (test (op false?) <operand>)
;;;   (branch (label <local-label>))
;;;   (goto (label <local-label>))
;;;   primitive tail application of a previously looked-up proc
;;;   (halt)
;;;
;;; If a supported prefix reaches an unsupported instruction, the zone returns
;;; mode 2 with the updated registers and the unsupported instruction's PC so
;;; the interpreter can resume there.

(define (wasm-zone/error message)
  (error (string-append "wasm-zone: " message)))

(define wasm-zone/min-fixnum -1073741824)
(define wasm-zone/max-fixnum 1073741823)

(define (wasm-zone/fixnum-immediate? value)
  (and (integer? value)
       (>= value wasm-zone/min-fixnum)
       (<= value wasm-zone/max-fixnum)))

(define (wasm-zone/safe-export-name? name)
  "Return #t when NAME is safe to splice into a simple WAT export string."
  (and (string? name)
       (> (string-length name) 0)
       (let loop ((i 0))
         (or (= i (string-length name))
             (let ((ch (string-ref name i)))
               (and (or (char-alphabetic? ch)
                        (char-numeric? ch)
                        (char=? ch #\_)
                        (char=? ch #\-)
                        (char=? ch #\.))
                    (loop (+ i 1))))))))

(define (wasm-zone/name name)
  "Return a WAT identifier. Build the leading dollar at runtime so archive
reload never sees dollar-prefixed strings as interpolation input."
  (string-append (string #\$) name))

(define (wasm-zone/register-local reg)
  "Return the WAT local name for a register symbol, or #f for unsupported regs."
  (cond ((eq? reg 'val) (wasm-zone/name "val"))
        ((eq? reg 'env) (wasm-zone/name "env"))
        ((eq? reg 'proc) (wasm-zone/name "proc"))
        ((eq? reg 'argl) (wasm-zone/name "argl"))
        ((eq? reg 'continue) (wasm-zone/name "cont"))
        ((eq? reg 'stack) (wasm-zone/name "stack"))
        (else #f)))

(define (wasm-zone/result-call-wat mode next-pc)
  (string-append
   "        (call " (wasm-zone/name "result") "\n"
   "          (i32.const " (number->string mode) ")\n"
   "          (i32.const " (number->string next-pc) ")\n"
   "          (local.get " (wasm-zone/name "val") ")\n"
   "          (local.get " (wasm-zone/name "env") ")\n"
   "          (local.get " (wasm-zone/name "proc") ")\n"
   "          (local.get " (wasm-zone/name "argl") ")\n"
   "          (local.get " (wasm-zone/name "cont") ")\n"
   "          (local.get " (wasm-zone/name "stack") "))"))

(define (wasm-zone/result-call-current-pc-wat mode)
  (string-append
   "        (call " (wasm-zone/name "result") "\n"
   "          (i32.const " (number->string mode) ")\n"
   "          (local.get " (wasm-zone/name "pc") ")\n"
   "          (local.get " (wasm-zone/name "val") ")\n"
   "          (local.get " (wasm-zone/name "env") ")\n"
   "          (local.get " (wasm-zone/name "proc") ")\n"
   "          (local.get " (wasm-zone/name "argl") ")\n"
   "          (local.get " (wasm-zone/name "cont") ")\n"
   "          (local.get " (wasm-zone/name "stack") "))"))

(define (wasm-zone/const-value-wat value)
  (cond ((wasm-zone/fixnum-immediate? value)
         (string-append "(call " (wasm-zone/name "h_fixnum") " (i32.const "
                        (number->string value)
                        "))"))
        ((null? value)
         (string-append "(call " (wasm-zone/name "h_nil") ")"))
        ((eq? value #t)
         (string-append "(call " (wasm-zone/name "h_true") ")"))
        ((eq? value #f)
         (string-append "(call " (wasm-zone/name "h_false") ")"))
        (else #f)))

(define (wasm-zone/source-value-wat source)
  (cond
   ((and (pair? source)
         (eq? (car source) 'const)
         (pair? (cdr source)))
    (wasm-zone/const-value-wat (cadr source)))
   ((and (pair? source)
         (eq? (car source) 'reg)
         (pair? (cdr source))
         (wasm-zone/register-local (cadr source)))
    (string-append "(local.get " (wasm-zone/register-local (cadr source)) ")"))
   (else #f)))

(define (wasm-zone/char-list-value-wat name)
  (let ((tail "(i32.const 0)"))
    (do ((index (- (string-length name) 1) (- index 1)))
        ((< index 0) tail)
      (set! tail
            (string-append
             "(call " (wasm-zone/name "h_cons")
             " (call " (wasm-zone/name "h_char")
             " (i32.const "
             (number->string (char->integer (string-ref name index)))
             ")) "
             tail
             ")")))))

(define (wasm-zone/symbol-handle-wat value)
  (if (symbol? value)
      (let ((name (symbol->string value)))
        (if (= (string-length name) 1)
            (string-append
             "(call " (wasm-zone/name "h_symbol_1")
             " (i32.const "
             (number->string (char->integer (string-ref name 0)))
             "))")
            (string-append
             "(call " (wasm-zone/name "h_symbol_from_chars")
             " " (wasm-zone/char-list-value-wat name)
             ")")))
      #f))

(define (wasm-zone/lookup-variable-value-operands? source operands)
  (and (eq? (wasm-zone/operation-name source) 'lookup-variable-value)
       (= (length operands) 2)
       (pair? (car operands))
       (eq? (caar operands) 'const)
       (pair? (cdr (car operands)))
       (pair? (cadr operands))
       (eq? (car (cadr operands)) 'reg)
       (eq? (cadr (cadr operands)) 'env)))

(define (wasm-zone/label-target-pc co target)
  (if (and (pair? target)
           (eq? (car target) 'label)
           (pair? (cdr target)))
      (let ((pc (code-object-label-ref co (cadr target))))
        (if (number? pc) pc #f))
      #f))

(define (wasm-zone/list-value-wat operands)
  (if (null? operands)
      (string-append "(call " (wasm-zone/name "h_nil") ")")
      (let ((head (wasm-zone/source-value-wat (car operands)))
            (tail (wasm-zone/list-value-wat (cdr operands))))
        (if (and head tail)
            (string-append "(call " (wasm-zone/name "h_cons") " " head " " tail ")")
            #f))))

(define (wasm-zone/operation-name source)
  (if (and (pair? source)
           (eq? (car source) 'op)
           (pair? (cdr source)))
      (cadr source)
      #f))

(define (wasm-zone/op-value-wat source operands)
  (let ((op-name (wasm-zone/operation-name source)))
    (cond
     ((eq? op-name 'list)
      (wasm-zone/list-value-wat operands))
     ((and (eq? op-name 'cons)
           (= (length operands) 2))
      (let ((car-wat (wasm-zone/source-value-wat (car operands)))
            (cdr-wat (wasm-zone/source-value-wat (cadr operands))))
        (if (and car-wat cdr-wat)
            (string-append "(call " (wasm-zone/name "h_cons") " " car-wat " " cdr-wat ")")
            #f)))
     ((and (eq? op-name 'car)
           (= (length operands) 1))
      (let ((pair-wat (wasm-zone/source-value-wat (car operands))))
        (if pair-wat
            (string-append "(call " (wasm-zone/name "h_car") " " pair-wat ")")
            #f)))
     ((and (eq? op-name 'cdr)
           (= (length operands) 1))
      (let ((pair-wat (wasm-zone/source-value-wat (car operands))))
        (if pair-wat
            (string-append "(call " (wasm-zone/name "h_cdr") " " pair-wat ")")
            #f)))
     ((wasm-zone/lookup-variable-value-operands? source operands)
      (let ((name-wat (wasm-zone/symbol-handle-wat (cadr (car operands)))))
        (if name-wat
            (string-append "(call " (wasm-zone/name "h_lookup")
                           " " name-wat
                           " (local.get " (wasm-zone/name "env") "))")
            #f)))
     (else #f))))

(define (wasm-zone/return-result-call-wat mode next-pc)
  (string-append
   "            (return\n"
   (wasm-zone/result-call-wat mode next-pc)
   ")\n"))

(define (wasm-zone/error-sentinel-bail-wat target-local pc)
  (string-append
   "        (if (call " (wasm-zone/name "h_error_sentinel_p")
   " (local.get " target-local "))\n"
   "          (then\n"
   (wasm-zone/return-result-call-wat 2 pc)
   "          ))\n"))

(define (wasm-zone/set-next-pc-wat next-pc)
  (string-append
   "        (local.set " (wasm-zone/name "pc")
   " (i32.const " (number->string next-pc) "))\n"
   "        (br " (wasm-zone/name "dispatch") ")\n"))

(define (wasm-zone/emit-assign-wat instr pc)
  "Return WAT for a supported assign instruction, else #f."
  (if (not (and (pair? instr)
                (eq? (car instr) 'assign)
                (pair? (cdr instr))
                (pair? (cddr instr))))
      #f
      (let* ((target (cadr instr))
             (source (caddr instr))
             (operands (cdddr instr))
             (target-local (wasm-zone/register-local target)))
        (if (not target-local)
            #f
            (let ((value-wat
                   (if (wasm-zone/operation-name source)
                       (wasm-zone/op-value-wat source operands)
                       (wasm-zone/source-value-wat source))))
              (if value-wat
                  (string-append
                   "        (local.set " target-local " " value-wat ")\n"
                   (if (wasm-zone/lookup-variable-value-operands? source operands)
                       (wasm-zone/error-sentinel-bail-wat target-local pc)
                       ""))
                  #f))))))

(define (wasm-zone/test-value-wat source operands)
  (let ((op-name (wasm-zone/operation-name source)))
    (cond
     ((and (eq? op-name 'false?)
           (= (length operands) 1))
      (let ((value-wat (wasm-zone/source-value-wat (car operands))))
        (if value-wat
            (string-append "(call " (wasm-zone/name "h_false_p")
                           " " value-wat ")")
            #f)))
     ((and (eq? op-name 'primitive-procedure?)
           (= (length operands) 1))
      (let ((value-wat (wasm-zone/source-value-wat (car operands))))
        (if value-wat
            (string-append "(call " (wasm-zone/name "h_primitive_p")
                           " " value-wat ")")
            #f)))
     (else #f))))

(define (wasm-zone/emit-test-wat instr)
  "Return WAT for a supported test instruction, else #f."
  (if (not (and (pair? instr)
                (eq? (car instr) 'test)
                (pair? (cdr instr))))
      #f
      (let ((test-wat (wasm-zone/test-value-wat (cadr instr) (cddr instr))))
        (if test-wat
            (string-append
             "        (local.set " (wasm-zone/name "flag")
             " " test-wat ")\n")
            #f))))

(define (wasm-zone/branch-instruction? instr)
  (and (pair? instr)
       (eq? (car instr) 'branch)
       (pair? (cdr instr))))

(define (wasm-zone/goto-instruction? instr)
  (and (pair? instr)
       (eq? (car instr) 'goto)
       (pair? (cdr instr))))

(define (wasm-zone/halt-instruction? instr)
  (and (pair? instr) (eq? (car instr) 'halt)))

(define (wasm-zone/test-primitive-procedure? instr)
  (and (pair? instr)
       (eq? (car instr) 'test)
       (pair? (cdr instr))
       (pair? (cadr instr))
       (eq? (car (cadr instr)) 'op)
       (eq? (cadr (cadr instr)) 'primitive-procedure?)
       (pair? (cddr instr))
       (pair? (caddr instr))
       (eq? (car (caddr instr)) 'reg)
       (eq? (cadr (caddr instr)) 'proc)))

(define (wasm-zone/apply-primitive-assign? instr)
  (and (pair? instr)
       (eq? (car instr) 'assign)
       (pair? (cdr instr))
       (eq? (cadr instr) 'val)
       (pair? (cddr instr))
       (pair? (caddr instr))
       (eq? (car (caddr instr)) 'op)
       (eq? (cadr (caddr instr)) 'apply-primitive-procedure)
       (pair? (cdddr instr))
       (pair? (cadddr instr))
       (eq? (car (cadddr instr)) 'reg)
       (eq? (cadr (cadddr instr)) 'proc)
       (pair? (cdr (cdddr instr)))
       (pair? (car (cdr (cdddr instr))))
       (eq? (car (car (cdr (cdddr instr)))) 'reg)
       (eq? (cadr (car (cdr (cdddr instr)))) 'argl)))

(define (wasm-zone/find-primitive-tail instrs len pc)
  "Return the apply-primitive PC when PC starts a primitive tail, else #f."
  (and (wasm-zone/test-primitive-procedure? (vector-ref instrs pc))
       (let loop ((i (+ pc 1)))
         (cond
          ((>= i (- len 1)) #f)
          ((and (wasm-zone/apply-primitive-assign? (vector-ref instrs i))
                (wasm-zone/halt-instruction? (vector-ref instrs (+ i 1))))
           i)
          (else (loop (+ i 1)))))))

(define (wasm-zone/primitive-tail-wat test-pc apply-pc)
  (string-append
   "        (if (result i32) (call " (wasm-zone/name "h_primitive_p")
   " (local.get " (wasm-zone/name "proc") "))\n"
   "          (then\n"
   "            (local.set " (wasm-zone/name "val")
   " (call " (wasm-zone/name "h_apply_primitive")
   " (local.get " (wasm-zone/name "proc")
   ") (local.get " (wasm-zone/name "argl") ")))\n"
   "            (if (result i32) (call " (wasm-zone/name "h_error_sentinel_p")
   " (local.get " (wasm-zone/name "val") "))\n"
   "              (then\n"
   (wasm-zone/result-call-wat 2 apply-pc) ")\n"
   "              (else\n"
   (wasm-zone/result-call-wat 0 apply-pc) ")))\n"
   "          (else\n"
   (wasm-zone/result-call-wat 2 test-pc) "))"))

(define (wasm-zone/instruction-body-wat co instrs len pc)
  "Return WAT for instruction PC, else #f when the interpreter should handle it."
  (let* ((instr (vector-ref instrs pc))
         (assign-wat (wasm-zone/emit-assign-wat instr pc))
         (test-wat (wasm-zone/emit-test-wat instr))
         (apply-pc (wasm-zone/find-primitive-tail instrs len pc)))
    (cond
     (assign-wat
      (string-append assign-wat (wasm-zone/set-next-pc-wat (+ pc 1))))
     (apply-pc
      (string-append
       "        (return\n"
       (wasm-zone/primitive-tail-wat pc apply-pc)
       ")\n"))
     (test-wat
      (string-append test-wat (wasm-zone/set-next-pc-wat (+ pc 1))))
     ((wasm-zone/branch-instruction? instr)
      (let ((target-pc (wasm-zone/label-target-pc co (cadr instr))))
        (if target-pc
            (string-append
             "        (if (local.get " (wasm-zone/name "flag") ")\n"
             "          (then\n"
             "            (local.set " (wasm-zone/name "pc")
             " (i32.const " (number->string target-pc) "))\n"
             "            (br " (wasm-zone/name "dispatch") ")))\n"
             (wasm-zone/set-next-pc-wat (+ pc 1)))
            #f)))
     ((wasm-zone/goto-instruction? instr)
      (let ((target-pc (wasm-zone/label-target-pc co (cadr instr))))
        (if target-pc
            (wasm-zone/set-next-pc-wat target-pc)
            #f)))
     ((wasm-zone/halt-instruction? instr)
      (string-append
       "        (return\n"
       (wasm-zone/result-call-wat 0 pc)
       ")\n"))
     (else #f))))

(define (wasm-zone/instruction-case-wat co instrs len pc)
  (let ((body (wasm-zone/instruction-body-wat co instrs len pc)))
    (if body
        (string-append
         "        (if (i32.eq (local.get " (wasm-zone/name "pc")
         ") (i32.const " (number->string pc) "))\n"
         "          (then\n"
         body
         "          ))\n")
        "")))

(define (wasm-zone/body-wat co)
  "Return WAT for CO's supported register-machine dispatch, or #f when PC 0
is unsupported."
  (if (not (code-object? co))
      #f
      (let ((instrs (code-object-instructions co))
            (len (code-object-length co)))
        (if (or (= len 0)
                (not (wasm-zone/instruction-body-wat co instrs len 0)))
            #f
            (let loop ((pc 0) (body ""))
              (if (>= pc len)
                  (string-append
                   "    (block " (wasm-zone/name "exit") "\n"
                   "      (loop " (wasm-zone/name "dispatch") "\n"
                   body
                   "        (return\n"
                   (wasm-zone/result-call-current-pc-wat 2)
                   ")\n"
                   "      ))\n"
                   "    (unreachable)\n")
                  (loop (+ pc 1)
                        (string-append
                         body
                         (wasm-zone/instruction-case-wat
                          co instrs len pc)))))))))

(define (wasm-zone/supported? co)
  (if (wasm-zone/body-wat co) #t #f))

(define (wasm-zone/result-helper-wat)
  (string-append
   "  (func " (wasm-zone/name "result")
   " (param " (wasm-zone/name "mode")
   " i32) (param " (wasm-zone/name "next_pc")
   " i32) (param " (wasm-zone/name "val") " i32)\n"
   "                (param " (wasm-zone/name "env")
   " i32) (param " (wasm-zone/name "proc")
   " i32) (param " (wasm-zone/name "argl") " i32)\n"
   "                (param " (wasm-zone/name "cont")
   " i32) (param " (wasm-zone/name "stack")
   " i32) (result i32)\n"
   "    (local " (wasm-zone/name "vec") " i32)\n"
   "    (local.set " (wasm-zone/name "vec")
   " (call " (wasm-zone/name "h_vector") " (i32.const 8)))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 0) (call " (wasm-zone/name "h_fixnum")
   " (local.get " (wasm-zone/name "mode") ")))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 1) (call " (wasm-zone/name "h_fixnum")
   " (local.get " (wasm-zone/name "next_pc") ")))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 2) (local.get " (wasm-zone/name "val") "))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 3) (local.get " (wasm-zone/name "env") "))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 4) (local.get " (wasm-zone/name "proc") "))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 5) (local.get " (wasm-zone/name "argl") "))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 6) (local.get " (wasm-zone/name "cont") "))\n"
   "    (call " (wasm-zone/name "h_vector_set")
   " (local.get " (wasm-zone/name "vec")
   ") (i32.const 7) (local.get " (wasm-zone/name "stack") "))\n"
   "    (local.get " (wasm-zone/name "vec") "))\n"))

(define (wasm-zone/imports-wat)
  (string-append
   "  (import \"ece\" \"h_fixnum\" (func " (wasm-zone/name "h_fixnum")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_nil\" (func " (wasm-zone/name "h_nil")
   " (result i32)))\n"
   "  (import \"ece\" \"h_true\" (func " (wasm-zone/name "h_true")
   " (result i32)))\n"
   "  (import \"ece\" \"h_false\" (func " (wasm-zone/name "h_false")
   " (result i32)))\n"
   "  (import \"ece\" \"h_false_p\" (func " (wasm-zone/name "h_false_p")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_char\" (func " (wasm-zone/name "h_char")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_cons\" (func " (wasm-zone/name "h_cons")
   " (param i32) (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_symbol_1\" (func " (wasm-zone/name "h_symbol_1")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_symbol_from_chars\" (func " (wasm-zone/name "h_symbol_from_chars")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_lookup\" (func " (wasm-zone/name "h_lookup")
   " (param i32) (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_primitive_p\" (func " (wasm-zone/name "h_primitive_p")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_apply_primitive\" (func " (wasm-zone/name "h_apply_primitive")
   " (param i32) (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_error_sentinel_p\" (func " (wasm-zone/name "h_error_sentinel_p")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"pair_car\" (func " (wasm-zone/name "h_car")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"pair_cdr\" (func " (wasm-zone/name "h_cdr")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_vector\" (func " (wasm-zone/name "h_vector")
   " (param i32) (result i32)))\n"
   "  (import \"ece\" \"h_vector_set\" (func " (wasm-zone/name "h_vector_set")
   " (param i32) (param i32) (param i32)))\n"))

(define (wasm-zone/export-function-wat export-name body)
  (string-append
   "  (func (export \"" export-name "\")\n"
   "        (param " (wasm-zone/name "pc")
   " i32) (param " (wasm-zone/name "val")
   " i32) (param " (wasm-zone/name "env") " i32)\n"
   "        (param " (wasm-zone/name "proc")
   " i32) (param " (wasm-zone/name "argl")
   " i32) (param " (wasm-zone/name "cont") " i32)\n"
   "        (param " (wasm-zone/name "stack")
   " i32) (param " (wasm-zone/name "co") " i32) (result i32)\n"
   "    (local " (wasm-zone/name "flag") " i32)\n"
   "    (if (result i32) (i32.eq (local.get " (wasm-zone/name "pc")
   ") (i32.const 0))\n"
   "      (then\n"
   body ")\n"
   "      (else\n"
   (wasm-zone/result-call-current-pc-wat 2) ")))\n"))

(define (wasm-zone/module-wat functions-wat)
  (string-append
   "(module\n"
   (wasm-zone/imports-wat)
   (wasm-zone/result-helper-wat)
   functions-wat
   ")\n"))

(define (generate-register-machine-wasm-zone co export-name)
  "Return WAT for CO, or #f if CO is outside this generator's subset.
The generated export uses positional register handles and never models Scheme
calls with the host WASM stack."
  (if (not (wasm-zone/safe-export-name? export-name))
      (wasm-zone/error "native-zone export name must contain only letters, digits, _, -, or .")
      (let ((body (wasm-zone/body-wat co)))
        (if (not body)
            #f
            (wasm-zone/module-wat
             (wasm-zone/export-function-wat export-name body))))))

(define (wasm-zone/default-export-name co-index)
  (string-append "zone_" (number->string co-index)))

(define (wasm-zone/archive-export-name section-index co-index)
  (string-append "unit_"
                 (number->string section-index)
                 "_zone_"
                 (number->string co-index)))

(define (wasm-zone/manifest module-unit-id entries maybe-module-url)
  (let ((module-url-fields
         (if (null? maybe-module-url)
             '()
             (list ':module-url (car maybe-module-url)))))
    (validate-native-zone-manifest
     (append
      (list ':ece-native-zones
            ':version 1
            ':unit-id module-unit-id)
      module-url-fields
      (list ':entries entries)))))

(define (generate-register-machine-wasm-zone-bundle unit-id cos
                                                    . maybe-module-url)
  "Return a plist with :wat and :manifest for supported code objects in COS.
COS must be the archive code-object vector. Unsupported code objects are
omitted from the manifest, leaving them on the interpreter path."
  (let ((len (vector-length cos)))
    (let loop ((i 0) (functions '()) (entries '()))
      (if (>= i len)
          (let ((manifest (wasm-zone/manifest unit-id
                                              (reverse entries)
                                              maybe-module-url))
                (function-wat (apply string-append (reverse functions))))
            (list ':wat (wasm-zone/module-wat function-wat)
                  ':manifest manifest))
          (let* ((co (vector-ref cos i))
                 (body (wasm-zone/body-wat co)))
            (if body
                (let* ((index (wasm-host/normalize-co-index i))
                       (export-name (wasm-zone/default-export-name index))
                       (fingerprint (ser/code-object-fingerprint co))
                       (fingerprint-fields
                        (if fingerprint
                            (list ':fingerprint fingerprint)
                            '())))
                  (loop (+ i 1)
                        (cons (wasm-zone/export-function-wat export-name body)
                              functions)
                        (cons (append
                               (list ':index index ':export export-name)
                               fingerprint-fields)
                              entries)))
                (loop (+ i 1) functions entries)))))))

(define (wasm-zone-bundle-wat bundle)
  (wasm-host/plist-get bundle ':wat))

(define (wasm-zone-bundle-manifest bundle)
  (wasm-host/plist-get bundle ':manifest))

(define (wasm-zone-bundle-entries bundle)
  (native-zone-manifest-entries (wasm-zone-bundle-manifest bundle)))

(define (wasm-zone/normalized-manifest manifest)
  (if (and (pair? manifest)
           (eq? (car manifest) ':ece-native-zones))
      (validate-native-zone-manifest manifest)
      manifest))

(define (wasm-zone/optional-string-field-text key value)
  (if value
      (list (string-append " "
                           (symbol->string key)
                           " "
                           (write-to-string-flat value)))
      '()))

(define (wasm-zone/fingerprint-field-text value)
  (if value
      (list (string-append
             " :fingerprint "
             (write-to-string-flat
              (if (string? value)
                  value
                  (write-to-string-flat value)))))
      '()))

(define (wasm-zone/entry->text entry)
  (string-append
   "("
   (string-join
    (if (native-zone-entry-unit-id entry)
        (list ":unit-id "
              (write-to-string-flat (native-zone-entry-unit-id entry))
              " ")
        '())
    "")
   ":index "
   (number->string (native-zone-entry-index entry))
   " :export "
   (write-to-string-flat (native-zone-entry-export-name entry))
   (string-join
    (wasm-zone/fingerprint-field-text
     (native-zone-entry-fingerprint entry))
    "")
   ")"))

(define (wasm-zone-manifest->text manifest)
  "Return canonical reader-safe text for a native-zone MANIFEST."
  (let* ((normalized (wasm-zone/normalized-manifest manifest))
         (entries (native-zone-manifest-entries normalized)))
    (string-append
     "(:ece-native-zones"
     " :version 1"
     " :unit-id "
     (write-to-string-flat (native-zone-manifest-unit-id normalized))
     (string-join
      (wasm-zone/optional-string-field-text
       ':source
       (native-zone-manifest-source normalized))
      "")
     (string-join
      (wasm-zone/optional-string-field-text
       ':module-url
       (native-zone-manifest-module-url normalized))
     "")
     " :entries ("
     (string-join (map wasm-zone/entry->text entries) " ")
     "))")))

(define (wasm-zone-bundle-manifest-text bundle)
  "Return canonical reader-safe native-zone manifest text for BUNDLE."
  (wasm-zone-manifest->text (wasm-zone-bundle-manifest bundle)))

(define (generate-register-machine-wasm-zone-manifest unit-id co-index
                                                      export-name
                                                      . maybe-module-url)
  "Return a validated native-zone manifest for one generated zone."
  (when (not (wasm-zone/safe-export-name? export-name))
    (wasm-zone/error "native-zone export name must contain only letters, digits, _, -, or ."))
  (let ((entry (list ':index (wasm-host/normalize-co-index co-index)
                     ':export export-name)))
    (wasm-zone/manifest unit-id (list entry) maybe-module-url)))

(define (generate-register-machine-wasm-zone-archive-text archive-text
                                                          module-url)
  "Generate one native-zone side-module WAT bundle for ARCHIVE-TEXT.
The resulting manifest uses per-entry :unit-id fields so one module can cover
all supported code objects across all archive sections in the .ecec bundle."
  (let ((port (open-input-string archive-text)))
    (define (scan-code-objects section-index unit-id cos i functions entries)
      (if (>= i (vector-length cos))
          (list functions entries)
          (let* ((co (vector-ref cos i))
                 (body (wasm-zone/body-wat co)))
            (if body
                (let* ((index (wasm-host/normalize-co-index i))
                       (export-name (wasm-zone/archive-export-name
                                     section-index
                                     index))
                       (fingerprint (ser/code-object-fingerprint co))
                       (fingerprint-fields
                        (if fingerprint
                            (list ':fingerprint fingerprint)
                            '())))
                  (scan-code-objects
                   section-index
                   unit-id
                   cos
                   (+ i 1)
                   (cons (wasm-zone/export-function-wat export-name body)
                         functions)
                   (cons (append
                          (list ':unit-id unit-id
                                ':index index
                                ':export export-name)
                          fingerprint-fields)
                         entries)))
                (scan-code-objects section-index unit-id cos (+ i 1)
                                   functions entries)))))
    (define (scan-sections section-index functions entries)
      (let ((archive (read-archive-section-form port)))
        (if (eof? archive)
            (begin
              (close-input-port port)
              (let ((manifest (wasm-zone/manifest
                               'archive-bundle
                               (reverse entries)
                               (list module-url)))
                    (function-wat (apply string-append
                                         (reverse functions))))
                (list ':wat (wasm-zone/module-wat function-wat)
                      ':manifest manifest)))
            (let* ((section (archive/materialize-section archive))
                   (unit (archive/section-unit section))
                   (unit-id (wasm-host/plist-get unit ':unit-id))
                   (cos (archive/section-cos section))
                   (result (scan-code-objects section-index unit-id cos 0
                                              functions entries)))
              (scan-sections (+ section-index 1)
                             (car result)
                             (cadr result))))))
    (scan-sections 0 '() '())))

(define (generate-register-machine-wasm-zone-archive-file archive-path
                                                          module-url)
  "Generate native-zone WAT and manifest data from an archive bundle file."
  (generate-register-machine-wasm-zone-archive-text
   (call-with-input-file archive-path
     (lambda (port)
       (let ((out (open-output-string)))
         (let loop ()
           (let ((ch (read-char port)))
             (if (eof? ch)
                 (get-output-string out)
                 (begin
                   (%write-char-to-port ch out)
                   (loop))))))))
   module-url))
