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
;;;   (assign <register> (const ()))
;;;   (assign <register> (reg <register>))
;;;   (assign <register> (op list) <operand> ...)
;;;   (assign <register> (op cons) <operand> <operand>)
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
     (else #f))))

(define (wasm-zone/emit-assign-wat instr)
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
                   "        (local.set " target-local " " value-wat ")\n")
                  #f))))))

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
   "  (import \"ece\" \"h_cons\" (func " (wasm-zone/name "h_cons")
   " (param i32) (param i32) (result i32)))\n"
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
                       (export-name (wasm-zone/default-export-name index)))
                  (loop (+ i 1)
                        (cons (wasm-zone/export-function-wat export-name body)
                              functions)
                        (cons (list ':index index ':export export-name)
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
    (wasm-zone/optional-string-field-text
     ':fingerprint
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
                                     index)))
                  (scan-code-objects
                   section-index
                   unit-id
                   cos
                   (+ i 1)
                   (cons (wasm-zone/export-function-wat export-name body)
                         functions)
                   (cons (list ':unit-id unit-id
                               ':index index
                               ':export export-name)
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
