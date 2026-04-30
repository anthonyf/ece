;;; codegen-wasm-zone.scm -- register-machine WASM native-zone generator.
;;;
;;; This is deliberately not a direct-style Scheme-to-WASM compiler. It emits
;;; side-module functions that implement the existing ECE register-machine
;;; native-zone ABI:
;;;
;;;   zone(pc, val, env, proc, argl, continue, stack, co) -> result-vector
;;;
;;; Unsupported code objects return #f from the generator, leaving execution on
;;; the interpreter path. The first slice supports only the smallest useful
;;; straight-line shape:
;;;
;;;   (assign val (const <fixnum>))
;;;   (halt)

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

(define (wasm-zone/fixnum-constant-return co)
  "Return the fixnum constant for the first supported zone shape, else #f."
  (if (not (and (code-object? co)
                (= (code-object-length co) 2)))
      #f
      (let* ((instrs (code-object-instructions co))
             (first (vector-ref instrs 0))
             (second (vector-ref instrs 1)))
        (if (and (pair? first)
                 (eq? (car first) 'assign)
                 (pair? (cdr first))
                 (eq? (cadr first) 'val)
                 (pair? (cddr first))
                 (let ((source (caddr first)))
                   (and (pair? source)
                        (eq? (car source) 'const)
                        (pair? (cdr source))
                        (wasm-zone/fixnum-immediate? (cadr source))))
                 (pair? second)
                 (eq? (car second) 'halt))
            (cadr (caddr first))
            #f))))

(define (wasm-zone/supported? co)
  (if (wasm-zone/fixnum-constant-return co) #t #f))

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
      (let ((constant (wasm-zone/fixnum-constant-return co)))
        (if (not constant)
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
             "        (call \$result\n"
             "          (i32.const 0)\n"
             "          (i32.const 0)\n"
             "          (call \$h_fixnum (i32.const " (number->string constant) "))\n"
             "          (local.get \$env)\n"
             "          (local.get \$proc)\n"
             "          (local.get \$argl)\n"
             "          (local.get \$cont)\n"
             "          (local.get \$stack)))\n"
             "      (else\n"
             "        (call \$result\n"
             "          (i32.const 2)\n"
             "          (local.get \$pc)\n"
             "          (local.get \$val)\n"
             "          (local.get \$env)\n"
             "          (local.get \$proc)\n"
             "          (local.get \$argl)\n"
             "          (local.get \$cont)\n"
             "          (local.get \$stack)))))\n"
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
