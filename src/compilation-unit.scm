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
  "Write a compiled unit to PORT as an s-expression."
  (write-string-to-port (write-to-string (compiled-unit-instructions unit)) port)
  (write-char #\newline port))

(define (read-compiled-unit port)
  "Read a compiled unit from PORT. Returns eof on end of input."
  (let ((instructions (ece-scheme-read port)))
    (if (eof? instructions)
        instructions
        (list 'compiled-unit instructions))))

;;; --- File compilation and loading ---

(define (compile-file filename)
  "Compile all forms in FILENAME, write compiled units to a .ecec file.
Macro definitions are executed at compile time so subsequent forms can use them.
Returns the output filename."
  (let ((output-name (string-append filename ".ecec")))
    (let ((in (open-input-file filename))
          (out (open-output-file output-name)))
      (let loop ()
        (let ((expr (ece-scheme-read in)))
          (if (eof? expr)
              (begin
                (close-input-port in)
                (close-output-port out)
                output-name)
              (begin
                ;; Execute macro definitions at compile time
                (when (and (pair? expr) (eq? (car expr) 'define-macro))
                  (mc-compile-and-go expr))
                (write-compiled-unit (compile-form expr) out)
                (loop))))))
    output-name))

(define (load-compiled filename)
  "Load and execute compiled units from a .ecec file.
Returns the result of the last executed unit."
  (let ((port (open-input-file filename)))
    (let loop ((result '()))
      (let ((unit (read-compiled-unit port)))
        (if (eof? unit)
            (begin (close-input-port port) result)
            (loop (execute unit)))))))
