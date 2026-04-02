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
  (let loop ((i 0))
    (when (< i (string-length str))
      (write-char (string-ref str i) port)
      (loop (+ i 1)))))

(define (rename-labels instrs)
  "Rename gensym labels — currently identity (renaming deferred to golden tests)."
  instrs)

;;; --- Flat instruction list writing ---

(define (write-flat-instructions instrs port)
  "Write a flat instruction list to PORT, one instruction/label per line."
  (write-char #\( port)
  (let loop ((items instrs) (first? #t))
    (when (pair? items)
      (if first?
          (write-string-to-port (write-to-string-flat (car items)) port)
          (begin
            (write-char #\newline port)
            (write-char #\space port)
            (write-string-to-port (write-to-string-flat (car items)) port)))
      (loop (cdr items) #f)))
  (write-char #\) port)
  (write-char #\newline port))

;;; --- Merging compilation units ---

(define (merge-instruction-lists units)
  "Merge compiled units into a single flat instruction list with env-resets between units."
  (if (null? units)
      '()
      (let loop ((units units))
        (if (null? (cdr units))
            (compiled-unit-instructions (car units))
            (append (compiled-unit-instructions (car units))
                    (list '(assign env (op lookup-variable-value)
                                   (const *global-env*) (reg env)))
                    (loop (cdr units)))))))

(define (write-compiled-unit unit port)
  "Write a compiled unit to PORT with one instruction per line.
Gensym labels are renamed to deterministic $L0, $L1, ... names."
  (let ((renamed (rename-labels (compiled-unit-instructions unit))))
    (write-flat-instructions renamed port)))

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
  (let* ((space-name
          (string->symbol (filename-strip-extension (filename-basename filename) ".scm")))
         (output-name
          (string-append (filename-strip-extension filename ".scm") ".ecec"))
         (in (open-input-file filename)))
    ;; Phase 1: compile all forms, track macros
    ;; Returns (units-reversed . macros-reversed)
    ;; For define-macro forms, we:
    ;;   1. Execute at compile time (so later forms can use the macro)
    ;;   2. Compile a set-macro! + lambda expression for the .ecec file
    ;;      (so macros are registered at load time, not just compile time)
    (define (define-macro-to-set-macro expr)
      "Transform (define-macro (name params...) body...) into
       (begin (set-macro! 'name (lambda (params...) body...)) 'name)"
      (let* ((name (if (pair? (cadr expr)) (car (cadr expr)) (cadr expr)))
             (params (if (pair? (cadr expr)) (cdr (cadr expr)) (list (cadr expr))))
             (body (cddr expr)))
        (list 'begin
              (list 'set-macro! (list 'quote name)
                    (cons 'lambda (cons params body)))
              (list 'quote name))))
    (define (maybe-expand-define-syntax expr)
      "If EXPR is (define-syntax ...), expand to (define-macro ...) so it gets
       compile-time execution and load-time set-macro! treatment."
      (if (and (pair? expr) (eq? (car expr) 'define-syntax)
               (get-macro 'define-syntax))
          (mc-expand-macro-at-compile-time
           (get-macro 'define-syntax) (cdr expr))
          expr))
    (define (read-loop units macros)
      (let ((expr (maybe-expand-define-syntax (ece-scheme-read in))))
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
                   macros))))))
    (let* ((result (read-loop '() '()))
           (units (reverse (car result)))
           (macros-defined (reverse (cdr result)))
           ;; Phase 2: merge units, rename labels, write flat output
           (merged (merge-instruction-lists units))
           (renamed (rename-labels merged))
           (out (open-output-file output-name)))
      (write-string-to-port
       (write-to-string-flat
        (list 'ecec-header
              (list 'space space-name)
              (list 'macros macros-defined)))
       out)
      (write-char #\newline out)
      (write-flat-instructions renamed out)
      (close-output-port out)
      output-name)))

(define (load-compiled filename)
  "Load and execute compiled code from a .ecec file.
Reads the ecec-header, creates a named space, then executes the flat instruction list."
  (let ((port (open-input-file filename)))
    (let ((header (ece-scheme-read port)))
      (let* ((space-sym (cadr (assoc 'space (cdr header))))
             (prev-space (%current-space-id))
             (new-space (%create-space (symbol->string space-sym)))
             (instrs (ece-scheme-read port)))
        (close-input-port port)
        (%set-current-space-id! new-space)
        (let ((result (execute (list 'compiled-unit instrs))))
          (%set-current-space-id! prev-space)
          result)))))
