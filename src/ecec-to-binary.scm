;;; ecec-to-binary.scm — Convert .ecec to .ececb binary format
;;; Written in ECE, runs on CL host during `make bootstrap`.
;;; Reads .ecec s-expressions, emits .ececb binary (see wasm/ececb-format.md).

;;; ── Byte-writing helpers ──────────────────────────────────────────

(define (write-u8 byte port)
  (write-byte byte port))

(define (write-u16-le n port)
  (write-byte (modulo n 256) port)
  (write-byte (modulo (arithmetic-shift n -8) 256) port))

(define (write-u32-le n port)
  (write-byte (modulo n 256) port)
  (write-byte (modulo (arithmetic-shift n -8) 256) port)
  (write-byte (modulo (arithmetic-shift n -16) 256) port)
  (write-byte (modulo (arithmetic-shift n -24) 256) port))

(define (write-i32-le n port)
  ;; Write signed i32 as unsigned bytes
  (write-u32-le (if (< n 0) (+ n 4294967296) n) port))

(define (write-f64-le f port)
  ;; TODO: IEEE 754 encoding — for now just write as fixnum if integer
  ;; This is a placeholder; proper float encoding needs bit manipulation
  (write-i32-le (if (integer? f) f 0) port)
  (write-u32-le 0 port))

(define (write-utf8-string str port)
  ;; Write string as UTF-8 bytes (ASCII subset for now)
  (let loop ((i 0))
    (when (< i (string-length str))
      (write-byte (char->integer (string-ref str i)) port)
      (loop (+ i 1)))))

(define (write-length-prefixed-string str port)
  ;; u16-le length + UTF-8 bytes
  (write-u16-le (string-length str) port)
  (write-utf8-string str port))

(define (write-length-prefixed-string-u32 str port)
  ;; u32-le length + UTF-8 bytes
  (write-u32-le (string-length str) port)
  (write-utf8-string str port))


;;; ── Name → ID mappings ───────────────────────────────────────────

(define (register-name->id name)
  (cond
   ((eq? name 'val)      0)
   ((eq? name 'env)      1)
   ((eq? name 'proc)     2)
   ((eq? name 'argl)     3)
   ((eq? name 'continue) 4)
   ((eq? name 'stack)    5)
   (else (error "Unknown register" name))))

(define (op-name->id name)
  (cond
   ((eq? name 'lookup-variable-value)    0)
   ((eq? name 'compiled-procedure-entry) 1)
   ((eq? name 'compiled-procedure-env)   2)
   ((eq? name 'make-compiled-procedure)  3)
   ((eq? name 'extend-environment)       4)
   ((eq? name 'primitive-procedure?)     5)
   ((eq? name 'apply-primitive-procedure) 6)
   ((eq? name 'continuation?)            7)
   ((eq? name 'continuation-stack)       8)
   ((eq? name 'continuation-conts)       9)
   ((eq? name 'parameter?)              10)
   ((eq? name 'apply-parameter)         11)
   ((eq? name 'false?)                  12)
   ((eq? name 'list)                    13)
   ((eq? name 'cons)                    14)
   ((eq? name 'car)                     15)
   ((eq? name 'cdr)                     16)
   ((eq? name 'lexical-ref)             17)
   ((eq? name 'lexical-set!)            18)
   ((eq? name 'define-variable!)        19)
   ((eq? name 'set-variable-value!)     20)
   ((eq? name 'capture-continuation)    21)
   ((eq? name 'parameter-ref)           22)
   ((eq? name 'parameter-set!)          23)
   ((eq? name 'parameter-raw-set!)      24)
   (else (error "Unknown operation" name))))


;;; ── Value encoding ───────────────────────────────────────────────

(define (scheme-false-struct? v)
  ;; CL prints #S(SCHEME-FALSE) for our false representation
  (and (string? (write-to-string v))
       (string-contains? (write-to-string v) "SCHEME-FALSE")))

(define (write-value val port)
  (cond
   ;; #t
   ((eq? val #t)
    (write-u8 3 port))
   ;; #f or #S(SCHEME-FALSE) — check by identity OR by struct type
   ((or (eq? val #f) (scheme-false-struct? val))
    (write-u8 4 port))
   ;; nil / '()
   ((null? val)
    (write-u8 5 port))
   ;; fixnum
   ((integer? val)
    (write-u8 0 port)
    (write-i32-le val port))
   ;; string
   ((string? val)
    (write-u8 1 port)
    (write-length-prefixed-string-u32 val port))
   ;; symbol
   ((symbol? val)
    (let ((name (symbol->string val)))
      ;; Check for #S(SCHEME-FALSE) pattern
      (if (string-contains? name "SCHEME-FALSE")
          (write-u8 4 port)  ;; encode as #f
          (begin
            (write-u8 2 port)
            (write-length-prefixed-string name port)))))
   ;; char
   ((char? val)
    (write-u8 7 port)
    (write-u32-le (char->integer val) port))
   ;; vector
   ((vector? val)
    (write-u8 11 port)
    (write-u32-le (vector-length val) port)
    (let loop ((i 0))
      (when (< i (vector-length val))
        (write-value (vector-ref val i) port)
        (loop (+ i 1)))))
   ;; float bytes from CL bridge (:ece-float-bytes b0 b1 ... b7)
   ((and (pair? val) (eq? (car val) ':ece-float-bytes))
    (write-u8 8 port)
    (for-each (lambda (b) (write-u8 b port)) (cdr val)))
   ;; pair
   ((pair? val)
    (write-u8 10 port)
    (write-value (car val) port)
    (write-value (cdr val) port))
   ;; float (fallback — integer floats)
   ((number? val)
    (write-u8 8 port)
    (write-f64-le val port))
   ;; Default: void
   (else
    (write-u8 9 port))))


;;; ── Operand encoding ─────────────────────────────────────────────

(define (write-operand operand port)
  ;; Operand is (type value ...) from the instruction
  ;; In .ecec: (const <val>) or (reg <name>) or (label <name>)
  (let ((type (car operand))
        (val  (cadr operand)))
    (cond
     ((eq? type 'const)
      (write-u8 0 port)
      (write-value val port))
     ((eq? type 'reg)
      (write-u8 1 port)
      (write-u8 (register-name->id val) port))
     ((eq? type 'label)
      (write-u8 2 port)
      (write-length-prefixed-string (symbol->string val) port))
     (else (error "Unknown operand type" type)))))


;;; ── Instruction encoding ─────────────────────────────────────────

(define (write-instruction instr port)
  (let ((opcode (car instr)))
    (cond
     ;; assign
     ((eq? opcode 'assign)
      (write-u8 0 port)
      (write-u8 (register-name->id (cadr instr)) port)
      (let ((source (caddr instr)))
        (cond
         ;; assign from const
         ((eq? (car source) 'const)
          (write-u8 0 port)
          (write-value (cadr source) port))
         ;; assign from reg
         ((eq? (car source) 'reg)
          (write-u8 1 port)
          (write-u8 (register-name->id (cadr source)) port))
         ;; assign from label
         ((eq? (car source) 'label)
          (write-u8 2 port)
          (write-length-prefixed-string (symbol->string (cadr source)) port))
         ;; assign from op
         ((eq? (car source) 'op)
          (write-u8 3 port)
          (write-u8 (op-name->id (cadr source)) port)
          ;; operands are the rest of the instruction (cdr (cdr (cdr instr)))
          (let ((operands (cdr (cdr (cdr instr)))))
            (write-u8 (length operands) port)
            (for-each (lambda (op) (write-operand op port)) operands)))
         (else (error "Unknown assign source" source)))))

     ;; test
     ((eq? opcode 'test)
      (write-u8 1 port)
      (let ((op-spec (cadr instr)))
        (write-u8 (op-name->id (cadr op-spec)) port)
        (let ((operands (cddr instr)))
          (write-u8 (length operands) port)
          (for-each (lambda (op) (write-operand op port)) operands))))

     ;; branch
     ((eq? opcode 'branch)
      (write-u8 2 port)
      (let ((dest (cadr instr)))
        (write-length-prefixed-string (symbol->string (cadr dest)) port)))

     ;; goto
     ((eq? opcode 'goto)
      (write-u8 3 port)
      (let ((dest (cadr instr)))
        (cond
         ((eq? (car dest) 'label)
          (write-u8 0 port)
          (write-length-prefixed-string (symbol->string (cadr dest)) port))
         ((eq? (car dest) 'reg)
          (write-u8 1 port)
          (write-u8 (register-name->id (cadr dest)) port))
         (else (error "Unknown goto dest" dest)))))

     ;; save
     ((eq? opcode 'save)
      (write-u8 4 port)
      (write-u8 (register-name->id (cadr instr)) port))

     ;; restore
     ((eq? opcode 'restore)
      (write-u8 5 port)
      (write-u8 (register-name->id (cadr instr)) port))

     ;; perform
     ((eq? opcode 'perform)
      (write-u8 6 port)
      (let ((op-spec (cadr instr)))
        (write-u8 (op-name->id (cadr op-spec)) port)
        (let ((operands (cddr instr)))
          (write-u8 (length operands) port)
          (for-each (lambda (op) (write-operand op port)) operands))))

     ;; procedure-name (pseudo-instruction, skip)
     ((eq? opcode 'procedure-name)
      #f)  ;; don't emit anything

     (else (error "Unknown opcode" opcode)))))


;;; ── Unit processing ──────────────────────────────────────────────
;;; A unit is a flat list of instructions and labels (one line in .ecec).
;;; Labels are bare symbols, instructions are lists.

(define (separate-labels-and-instrs items)
  ;; Walk the flat list, separate labels (with their PCs) from instructions.
  ;; Returns (labels . instructions) where labels is ((name . pc) ...)
  (let loop ((items items) (labels '()) (instrs '()) (pc 0))
    (if (null? items)
        (cons (reverse labels) (reverse instrs))
        (let ((item (car items)))
          (cond
           ;; Bare symbol = label
           ((symbol? item)
            (loop (cdr items) (cons (cons item pc) labels) instrs pc))
           ;; procedure-name pseudo-instruction: don't count as instruction
           ((and (pair? item) (eq? (car item) 'procedure-name))
            (loop (cdr items) labels instrs pc))
           ;; Regular instruction
           ((pair? item)
            (loop (cdr items) labels (cons item instrs) (+ pc 1)))
           (else (loop (cdr items) labels instrs pc)))))))

(define (write-unit items port)
  ;; Emit unit marker
  (write-u8 254 port)
  (let* ((separated (separate-labels-and-instrs items))
         (labels (car separated))
         (instrs (cdr separated)))
    ;; Write label count and labels
    (write-u32-le (length labels) port)
    (for-each
     (lambda (label)
       (write-length-prefixed-string (symbol->string (car label)) port)
       (write-u32-le (cdr label) port))
     labels)
    ;; Write instruction count and instructions
    (write-u32-le (length instrs) port)
    (for-each
     (lambda (instr) (write-instruction instr port))
     instrs)))


;;; ── Header parsing ───────────────────────────────────────────────

(define (parse-ecec-header header)
  ;; (ecec-header (space <name>) (macros <list>))
  (let ((space-name (symbol->string (cadr (cadr header))))
        (macros (cadr (caddr header))))
    (cons space-name (if (null? macros) '() macros))))

(define (write-header space-name macros port)
  ;; Magic
  (write-u8 69 port) ;; E
  (write-u8 67 port) ;; C
  (write-u8 69 port) ;; E
  (write-u8 66 port) ;; B
  ;; Version
  (write-u8 1 port)
  ;; Space name
  (write-length-prefixed-string space-name port)
  ;; Macro count
  (let ((macro-list (if (null? macros) '() macros)))
    (write-u16-le (length macro-list) port)
    (for-each
     (lambda (m)
       (write-length-prefixed-string (symbol->string m) port))
     macro-list)))


;;; ── Main entry point ─────────────────────────────────────────────

(define (ecec-to-binary-unit header-info units output-path)
  ;; Called with pre-parsed data (CL reads the .ecec, ECE writes binary).
  ;; header-info: (space-name . macros)
  ;; units: list of unit lists (each is a flat list of instrs/labels)
  (let ((out (open-binary-output-file output-path)))
    (write-header (car header-info) (cdr header-info) out)
    (for-each (lambda (unit) (write-unit unit out)) units)
    (close-output-port out)
    (display "Wrote ")
    (display output-path)
    (newline)))

;; Convert all bootstrap .ecec files when run directly
(define (convert-all-bootstrap)
  (for-each
   (lambda (name)
     (let ((ecec-path (string-append "bootstrap/" name ".ecec"))
           (ececb-path (string-append "bootstrap/" name ".ececb")))
       (display "Converting ")
       (display ecec-path)
       (display " -> ")
       (display ececb-path)
       (newline)
       (ecec-to-binary ecec-path ececb-path)))
   '("prelude" "compiler" "reader" "assembler" "compilation-unit")))
