;;; ece-main.scm — ECE command-line entry point.
;;;
;;; Called by the save-lisp-and-die `:toplevel` shim after the VM boots.
;;; Receives argv via (command-line), inspects (basename argv[0]) to dispatch,
;;; and runs the appropriate tool.

;; ---- Version ----

(define *ece-version* "0.1.0")

;; ---- ECE_HOME resolution ----
;;
;; Checks (1) $ECE_HOME env var, (2) $(dirname $(dirname %exe-path))/share/ece,
;; (3) falls back to ".". String-only; no new primitives needed.

(define (ece-home)
  (let ((env (get-environment-variable "ECE_HOME")))
    (cond
     ((and env (> (string-length env) 0)) env)
     (else
      (let ((exe (%exe-path)))
        (if (and exe (> (string-length exe) 0))
            (path-join (dirname (dirname exe)) "share" "ece")
            "."))))))

;; ---- Usage / version output ----

(define (print-version)
  (display "ece ")
  (display *ece-version*)
  (newline))

(define (print-usage)
  (display "Usage: ece [OPTIONS] [FILE...]")
  (newline)
  (newline)
  (display "Options:")
  (newline)
  (display "  --load FILE           Load and execute FILE")
  (newline)
  (display "  -e EXPR, --eval EXPR  Evaluate EXPR")
  (newline)
  (display "  -i, --interactive     Enter REPL after processing files")
  (newline)
  (display "  --                    Stop option processing")
  (newline)
  (display "  -h, --help            Show this help and exit")
  (newline)
  (display "  -V, --version         Show version and exit")
  (newline)
  (newline)
  (display "Positional FILE arguments are loaded (.scm or .ecec) in the order given.")
  (newline))

;; ---- Argv parsing ----
;;
;; Returns a list whose head is a plist of flags and whose tail is the list
;; of execution steps in order. Each step is:
;;   (load <path>)  — positional .scm/.ecec or --load FILE
;;   (eval <expr-string>)  — -e/--eval EXPR
;; Flags:
;;   interactive? — #t if -i/--interactive seen
;;   help?        — #t if -h/--help seen
;;   version?     — #t if -V/--version seen
;;   extra-args   — list of strings after --

(define (parse-argv argv)
  "Parse argv (excluding argv[0]). Returns
 (list interactive? help? version? extra-args steps)."
  (let loop ((rest argv)
             (interactive? #f)
             (help? #f)
             (version? #f)
             (extra-args '())
             (steps '()))
    (cond
     ((null? rest)
      (list interactive? help? version? extra-args (reverse steps)))
     (else
      (let ((arg (car rest)))
        (cond
         ;; -- : take everything after it as passthrough args
         ((opt-terminator? arg)
          (list interactive? help? version? (cdr rest) (reverse steps)))
         ;; --help / -h
         ((or (string=? arg "--help") (string=? arg "-h"))
          (loop (cdr rest) interactive? #t version? extra-args steps))
         ;; --version / -V
         ((or (string=? arg "--version") (string=? arg "-V"))
          (loop (cdr rest) interactive? help? #t extra-args steps))
         ;; --interactive / -i
         ((or (string=? arg "--interactive") (string=? arg "-i"))
          (loop (cdr rest) #t help? version? extra-args steps))
         ;; --load FILE
         ((string=? arg "--load")
          (if (or (null? (cdr rest)))
              (begin
                (display "Error: --load requires an argument")
                (newline)
                (exit 2))
              (loop (cddr rest) interactive? help? version? extra-args
                    (cons (list 'load (cadr rest)) steps))))
         ;; --eval EXPR / -e EXPR
         ((or (string=? arg "--eval") (string=? arg "-e"))
          (if (or (null? (cdr rest)))
              (begin
                (display "Error: ")
                (display arg)
                (display " requires an argument")
                (newline)
                (exit 2))
              (loop (cddr rest) interactive? help? version? extra-args
                    (cons (list 'eval (cadr rest)) steps))))
         ;; Unknown long option
         ((long-opt? arg)
          (display "Error: unknown option: ")
          (display arg)
          (newline)
          (exit 2))
         ;; Unknown short option
         ((short-opt? arg)
          (display "Error: unknown option: ")
          (display arg)
          (newline)
          (exit 2))
         ;; Positional file argument
         (else
          (loop (cdr rest) interactive? help? version? extra-args
                (cons (list 'load arg) steps)))))))))

;; ---- Step execution ----

(define (load-file-step path)
  "Load a file. Dispatches to load-bundle for .ecec, load for .scm."
  (cond
   ((has-extension? path "ecec") (load-bundle path))
   (else (load path))))

(define (eval-string expr-str)
  "Read and evaluate every expression from a string in sequence.
Returns the value of the last expression."
  (let ((port (open-input-string expr-str)))
    (let loop ((last '()))
      (let ((expr (read port)))
        (cond
         ((eof? expr)
          (close-input-port port)
          last)
         (else (loop (eval expr))))))))

(define (run-step step)
  (let ((kind (car step))
        (arg (cadr step)))
    (cond
     ((eq? kind 'load) (load-file-step arg))
     ((eq? kind 'eval) (eval-string arg))
     (else (error "unknown step kind" kind)))))

(define (run-steps steps)
  (for-each run-step steps))

;; ---- REPL ----

(define (repl)
  (display "ece> ")
  (let ((input (read)))
    (cond
     ((eof? input)
      (newline)
      (display "Bye!")
      (newline))
     (else
      (let ((result (try-eval input)))
        (when (not (eof? result))
          (write result)
          (newline)))
      (repl)))))

;; ---- Default main (ece / unknown argv[0]) ----

(define (ece-default-main argv)
  "Default ece entry point. Parses argv, runs steps, optionally enters REPL."
  (let* ((parsed (parse-argv argv))
         (interactive? (list-ref parsed 0))
         (help? (list-ref parsed 1))
         (version? (list-ref parsed 2))
         (_extra (list-ref parsed 3))
         (steps (list-ref parsed 4)))
    (cond
     (help? (print-usage) (exit 0))
     (version? (print-version) (exit 0))
     (else
      (run-steps steps)
      (cond
       (interactive? (repl))
       ((null? steps) (repl))
       (else (exit 0)))))))

;; ---- ece-repl entry point ----

(define (ece-repl-main argv)
  "ece-repl: always enter REPL after optionally loading any positional files."
  (let* ((parsed (parse-argv argv))
         (help? (list-ref parsed 1))
         (version? (list-ref parsed 2))
         (steps (list-ref parsed 4)))
    (cond
     (help? (print-usage) (exit 0))
     (version? (print-version) (exit 0))
     (else
      (run-steps steps)
      (repl)))))

;; ---- argv[0] dispatch ----

(define (ece-main argv)
  "Top-level entry point. Inspect basename of argv[0] and dispatch."
  (let* ((prog (if (null? argv) "ece" (car argv)))
         (tool (basename prog))
         (rest (if (null? argv) '() (cdr argv))))
    (cond
     ((string=? tool "ece-repl") (ece-repl-main rest))
     ((string=? tool "ece-build") (ece-build-main rest))
     ((string=? tool "ece-test") (ece-test-main rest))
     (else (ece-default-main rest)))))

;; Tool entry points are stubs unless their .scm files are loaded.
;; Callers (the saved image) are responsible for loading ece-build.scm and
;; ece-test.scm BEFORE dispatch so these definitions are overridden.

(define (ece-build-main argv)
  (display "Error: ece-build.scm not loaded")
  (newline)
  (exit 2))

(define (ece-test-main argv)
  (display "Error: ece-test.scm not loaded")
  (newline)
  (exit 2))
