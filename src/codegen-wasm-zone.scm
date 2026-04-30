;;; codegen-wasm-zone.scm -- register-machine WASM native-zone generator.
;;;
;;; This is deliberately not a direct-style Scheme-to-WASM compiler. It emits
;;; side-module functions that implement the existing ECE register-machine
;;; native-zone ABI:
;;;
;;;   zone(pc, val, env, proc, argl, continue, stack, co) -> result-vector
;;;
;;; Unsupported code objects return #f from the generator, leaving execution on
;;; the interpreter path. The supported subset is a straight-line prefix:
;;;
;;;   (assign <register> (const <fixnum>))
;;;   (assign <register> (reg <register>))
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

(define (wasm-zone/register-local reg)
  "Return the WAT local name for a register symbol, or #f for unsupported regs."
  (cond ((eq? reg 'val) "\$val")
        ((eq? reg 'env) "\$env")
        ((eq? reg 'proc) "\$proc")
        ((eq? reg 'argl) "\$argl")
        ((eq? reg 'continue) "\$cont")
        ((eq? reg 'stack) "\$stack")
        (else #f)))

(define (wasm-zone/result-call-wat mode next-pc)
  (string-append
   "        (call \$result\n"
   "          (i32.const " (number->string mode) ")\n"
   "          (i32.const " (number->string next-pc) ")\n"
   "          (local.get \$val)\n"
   "          (local.get \$env)\n"
   "          (local.get \$proc)\n"
   "          (local.get \$argl)\n"
   "          (local.get \$cont)\n"
   "          (local.get \$stack))"))

(define (wasm-zone/result-call-current-pc-wat mode)
  (string-append
   "        (call \$result\n"
   "          (i32.const " (number->string mode) ")\n"
   "          (local.get \$pc)\n"
   "          (local.get \$val)\n"
   "          (local.get \$env)\n"
   "          (local.get \$proc)\n"
   "          (local.get \$argl)\n"
   "          (local.get \$cont)\n"
   "          (local.get \$stack))"))

(define (wasm-zone/emit-assign-wat instr)
  "Return WAT for a supported assign instruction, else #f."
  (if (not (and (pair? instr)
                (eq? (car instr) 'assign)
                (pair? (cdr instr))
                (pair? (cddr instr))))
      #f
      (let* ((target (cadr instr))
             (source (caddr instr))
             (target-local (wasm-zone/register-local target)))
        (if (not target-local)
            #f
            (cond
             ((and (pair? source)
                   (eq? (car source) 'const)
                   (pair? (cdr source))
                   (wasm-zone/fixnum-immediate? (cadr source)))
              (string-append
               "        (local.set " target-local
               " (call \$h_fixnum (i32.const "
               (number->string (cadr source))
               ")))\n"))
             ((and (pair? source)
                   (eq? (car source) 'reg)
                   (pair? (cdr source))
                   (wasm-zone/register-local (cadr source)))
              (string-append
               "        (local.set " target-local
               " (local.get " (wasm-zone/register-local (cadr source)) "))\n"))
             (else #f))))))

(define (wasm-zone/halt-instruction? instr)
  (and (pair? instr) (eq? (car instr) 'halt)))

(define (wasm-zone/body-wat co)
  "Return WAT for CO's supported prefix, or #f when no prefix is supported."
  (if (not (code-object? co))
      #f
      (let ((instrs (code-object-instructions co))
            (len (code-object-length co)))
        (let loop ((pc 0) (emitted? #f) (body ""))
          (if (>= pc len)
              (if emitted?
                  (string-append body (wasm-zone/result-call-wat 2 pc))
                  #f)
              (let* ((instr (vector-ref instrs pc))
                     (assign-wat (wasm-zone/emit-assign-wat instr)))
                (cond
                 (assign-wat
                  (loop (+ pc 1) #t (string-append body assign-wat)))
                 ((wasm-zone/halt-instruction? instr)
                  (string-append body (wasm-zone/result-call-wat 0 pc)))
                 (emitted?
                  (string-append body (wasm-zone/result-call-wat 2 pc)))
                 (else #f))))))))

(define (wasm-zone/supported? co)
  (if (wasm-zone/body-wat co) #t #f))

(define (wasm-zone/result-helper-wat)
  (string-append
   "  (func \$result (param \$mode i32) (param \$next_pc i32) (param \$val i32)\n"
   "                (param \$env i32) (param \$proc i32) (param \$argl i32)\n"
   "                (param \$cont i32) (param \$stack i32) (result i32)\n"
   "    (local \$vec i32)\n"
   "    (local.set \$vec (call \$h_vector (i32.const 8)))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 0) (call \$h_fixnum (local.get \$mode)))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 1) (call \$h_fixnum (local.get \$next_pc)))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 2) (local.get \$val))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 3) (local.get \$env))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 4) (local.get \$proc))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 5) (local.get \$argl))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 6) (local.get \$cont))\n"
   "    (call \$h_vector_set (local.get \$vec) (i32.const 7) (local.get \$stack))\n"
   "    (local.get \$vec))\n"))

(define (generate-register-machine-wasm-zone co export-name)
  "Return WAT for CO, or #f if CO is outside this generator's subset.
The generated export uses positional register handles and never models Scheme
calls with the host WASM stack."
  (if (not (wasm-zone/safe-export-name? export-name))
      (wasm-zone/error "native-zone export name must contain only letters, digits, _, -, or .")
      (let ((body (wasm-zone/body-wat co)))
        (if (not body)
            #f
            (string-append
             "(module\n"
             "  (import \"ece\" \"h_fixnum\" (func \$h_fixnum (param i32) (result i32)))\n"
             "  (import \"ece\" \"h_vector\" (func \$h_vector (param i32) (result i32)))\n"
             "  (import \"ece\" \"h_vector_set\" (func \$h_vector_set (param i32) (param i32) (param i32)))\n"
             (wasm-zone/result-helper-wat)
             "  (func (export \"" export-name "\")\n"
             "        (param \$pc i32) (param \$val i32) (param \$env i32)\n"
             "        (param \$proc i32) (param \$argl i32) (param \$cont i32)\n"
             "        (param \$stack i32) (param \$co i32) (result i32)\n"
             "    (if (result i32) (i32.eq (local.get \$pc) (i32.const 0))\n"
             "      (then\n"
             body ")\n"
             "      (else\n"
             (wasm-zone/result-call-current-pc-wat 2) ")))\n"
             ")\n")))))

(define (generate-register-machine-wasm-zone-manifest unit-id co-index
                                                      export-name
                                                      . maybe-module-url)
  "Return a validated native-zone manifest for one generated zone."
  (when (not (wasm-zone/safe-export-name? export-name))
    (wasm-zone/error "native-zone export name must contain only letters, digits, _, -, or ."))
  (let ((entry (list ':index (wasm-host/normalize-co-index co-index)
                     ':export export-name))
        (module-url-fields
         (if (null? maybe-module-url)
             '()
             (list ':module-url (car maybe-module-url)))))
    (validate-native-zone-manifest
     (append
      (list ':ece-native-zones
            ':version 1
            ':unit-id unit-id)
      module-url-fields
      (list ':entries (list entry))))))
