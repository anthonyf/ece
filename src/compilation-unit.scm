;;; ECE Compilation Units
;;; First-class compiled unit values: compile, inspect, execute, serialize.
;;; Loaded after compiler.scm and assembler.scm.

;;; --- Compiled unit type ---

(define (compile-form expr)
  "Compile a single expression and return a compiled unit value."
  (let ((compiled (mc-compile expr 'val 'next)))
    (list 'compiled-unit (mc-instructions compiled))))

(define (compiled-unit? obj)
  "Return #t if OBJ is a compiled unit."
  (and (pair? obj) (eq? (car obj) 'compiled-unit)))

(define (compiled-unit-instructions unit)
  "Return the flat instruction list from a compiled unit."
  (cadr unit))

(define (execute unit)
  "Assemble and execute a compiled unit, returning the result."
  (let ((start-pc (assemble-into-global (compiled-unit-instructions unit))))
    (execute-from-pc start-pc)))

;;; --- Serialization ---
;;; Uses write-to-string + write-char for port-directed output,
;;; since ECE's write/display don't accept port arguments.

(define (write-string-to-port str port)
  "Write each character of STR to PORT."
  (define len (string-length str))
  (define (loop i)
    (when (< i len)
      (write-char (string-ref str i) port)
      (loop (+ i 1))))
  (loop 0))

(define (write-compiled-unit unit port)
  "Write a compiled unit to PORT as an s-expression.
Uses write-to-string-flat to avoid CL shared-structure markers."
  (write-string-to-port (write-to-string-flat (compiled-unit-instructions unit)) port)
  (write-char #\newline port))

(define (read-compiled-unit port)
  "Read a compiled unit from PORT. Returns eof on end of input."
  (let ((instructions (ece-scheme-read port)))
    (if (eof? instructions)
        instructions
        (list 'compiled-unit instructions))))

;;; --- File compilation and loading ---

(define (filename-strip-extension filename ext)
  "Strip EXT (e.g., \".scm\") from end of FILENAME if present."
  (let ((flen (string-length filename))
        (elen (string-length ext)))
    (if (and (> flen elen)
             (string=? (substring filename (- flen elen) flen) ext))
        (substring filename 0 (- flen elen))
        filename)))

(define (filename-basename filename)
  "Extract the basename from FILENAME (strip directory path)."
  (let loop ((i (- (string-length filename) 1)))
    (cond
     ((< i 0) filename)
     ((char=? (string-ref filename i) #\/)
      (substring filename (+ i 1) (string-length filename)))
     (else (loop (- i 1))))))

(define (compile-file filename)
  "Compile all forms in FILENAME, write compiled units to a .ecec file.
Emits an ecec-header with space name and macro list, followed by compiled units.
Macro definitions are executed at compile time so subsequent forms can use them.
Returns the output filename."
  (define space-name
    (string->symbol (filename-strip-extension (filename-basename filename) ".scm")))
  (define output-name
    (string-append (filename-strip-extension filename ".scm") ".ecec"))
  (define in (open-input-file filename))
  ;; Phase 1: compile all forms, track macros
  ;; Returns (units-reversed . macros-reversed)
  ;; For define-macro forms, we:
  ;;   1. Execute at compile time (so later forms can use the macro)
  ;;   2. Compile a set-macro! + lambda expression for the .ecec file
  ;;      (so macros are registered at load time, not just compile time)
  (define (define-macro-to-set-macro expr)
    "Transform (define-macro (name params...) body...) into
     (begin (set-macro! 'name (lambda (params...) body...)) 'name)"
    (define name (if (pair? (cadr expr)) (car (cadr expr)) (cadr expr)))
    (define params (if (pair? (cadr expr)) (cdr (cadr expr)) (list (cadr expr))))
    (define body (cddr expr))
    (list 'begin
          (list 'set-macro! (list 'quote name)
                (cons 'lambda (cons params body)))
          (list 'quote name)))
  (define (read-loop units macros)
    (define expr (ece-scheme-read in))
    (if (eof? expr)
        (begin (close-input-port in) (cons units macros))
        (begin
          ;; Track and execute macro definitions at compile time
          (when (and (pair? expr) (eq? (car expr) 'define-macro))
            (mc-compile-and-go expr))
          (read-loop
           (cons (compile-form
                  (if (and (pair? expr) (eq? (car expr) 'define-macro))
                      (define-macro-to-set-macro expr)
                      expr))
                 units)
           (if (and (pair? expr) (eq? (car expr) 'define-macro))
               (cons (if (pair? (cadr expr)) (car (cadr expr)) (cadr expr))
                     macros)
               macros)))))
  (define result (read-loop '() '()))
  (define units (reverse (car result)))
  (define macros-defined (reverse (cdr result)))
  ;; Phase 2: write header + units
  (define out (open-output-file output-name))
  (write-string-to-port
   (write-to-string-flat
    (list 'ecec-header
          (list 'space space-name)
          (list 'macros macros-defined)))
   out)
  (write-char #\newline out)
  (for-each (lambda (unit) (write-compiled-unit unit out)) units)
  (close-output-port out)
  output-name)

(define (load-compiled filename)
  "Load and execute compiled units from a .ecec file.
Reads the ecec-header, creates a named space, then executes units in that space.
Returns the result of the last executed unit."
  (let ((port (open-input-file filename)))
    (let ((first-form (ece-scheme-read port)))
      ;; Check if this is a new-format .ecec with header
      (if (and (pair? first-form) (eq? (car first-form) 'ecec-header))
          ;; New format: header + compiled units
          (let* ((space-sym (cadr (assoc 'space (cdr first-form))))
                 (prev-space (%current-space-id))
                 (new-space (%create-space (symbol->string space-sym))))
            (%set-current-space-id! new-space)
            (let loop ((result '()))
              (let ((unit (read-compiled-unit port)))
                (if (eof? unit)
                    (begin
                      (close-input-port port)
                      (%set-current-space-id! prev-space)
                      result)
                    (loop (execute unit))))))
          ;; Old format: no header, first form is a compiled unit
          (let loop ((result (execute (list 'compiled-unit first-form))))
            (let ((unit (read-compiled-unit port)))
              (if (eof? unit)
                  (begin (close-input-port port) result)
                  (loop (execute unit)))))))))
