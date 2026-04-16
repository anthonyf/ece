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
  (display "  --geiser              Run REPL in Geiser wire-protocol mode")
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
;;   geiser?      — #t if --geiser seen (REPL in Geiser wire-protocol mode)

(define (parse-argv argv)
  "Parse argv (excluding argv[0]). Returns
 (list interactive? help? version? extra-args steps geiser?)."
  (let loop ((rest argv)
             (interactive? #f)
             (help? #f)
             (version? #f)
             (extra-args '())
             (steps '())
             (geiser? #f))
    (cond
     ((null? rest)
      (list interactive? help? version? extra-args (reverse steps) geiser?))
     (else
      (let ((arg (car rest)))
        (cond
         ;; -- : take everything after it as passthrough args
         ((opt-terminator? arg)
          (list interactive? help? version? (cdr rest) (reverse steps) geiser?))
         ;; --help / -h
         ((or (string=? arg "--help") (string=? arg "-h"))
          (loop (cdr rest) interactive? #t version? extra-args steps geiser?))
         ;; --version / -V
         ((or (string=? arg "--version") (string=? arg "-V"))
          (loop (cdr rest) interactive? help? #t extra-args steps geiser?))
         ;; --interactive / -i
         ((or (string=? arg "--interactive") (string=? arg "-i"))
          (loop (cdr rest) #t help? version? extra-args steps geiser?))
         ;; --geiser
         ((string=? arg "--geiser")
          (loop (cdr rest) interactive? help? version? extra-args steps #t))
         ;; --load FILE
         ((string=? arg "--load")
          (if (or (null? (cdr rest)))
              (begin
                (display "Error: --load requires an argument")
                (newline)
                (exit 2))
              (loop (cddr rest) interactive? help? version? extra-args
                    (cons (list 'load (cadr rest)) steps) geiser?)))
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
                    (cons (list 'eval (cadr rest)) steps) geiser?)))
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
                (cons (list 'load arg) steps) geiser?))))))))

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
;;
;; `repl` accepts an optional geiser? flag. In geiser mode, the REPL
;; captures current-output-port during evaluation and formats each
;; result as a chibi-style alist `((result "...") (output . "..."))`.
;; Both modes wrap `read` in a `guard` so reader errors (unbalanced
;; parens, unexpected EOF in list) don't crash the subprocess.

(define *repl-read-error* (list 'repl-read-error))

(define (repl . opts)
  (let ((geiser? (and (not (null? opts)) (car opts))))
    (display "ece> ")
    (let ((input (guard (e (#t
                            (cond
                             (geiser?
                              (display (write-to-string-flat
                                        (list (list 'result "")
                                              (cons 'output
                                                    (string-append "Read error: "
                                                                   (if (error-object? e)
                                                                       (error-object-message e)
                                                                       (write-to-string e)))))))
                              (newline))
                             (else
                              (display "Error: ")
                              (display (if (error-object? e)
                                           (error-object-message e)
                                           e))
                              (newline)))
                            *repl-read-error*))
                        (read))))
      (cond
       ((eof? input)
        (newline)
        (display "Bye!")
        (newline))
       ((eq? input *repl-read-error*)
        (repl geiser?))
       (else
        (cond
         (geiser?
          (%geiser-eval-and-respond input))
         (else
          (let ((result (try-eval input)))
            (when (not (eof? result))
              (write result)
              (newline)))))
        (repl geiser?))))))

(define (%geiser-eval-and-respond input)
  ;; Capture user-code output, evaluate via try-eval, emit chibi-style alist.
  (let ((capture (open-output-string)))
    (let ((value (parameterize ((current-output-port capture))
                   (try-eval input))))
      (let ((output (get-output-string capture)))
        (display (write-to-string-flat
                  (list (list 'result
                              (if (eof? value) "" (write-to-string-flat value)))
                        (cons 'output output))))
        (newline)))))

;; ---- Default main (ece / unknown argv[0]) ----

(define (ece-default-main argv)
  "Default ece entry point. Parses argv, runs steps, optionally enters REPL."
  (let* ((parsed (parse-argv argv))
         (interactive? (list-ref parsed 0))
         (help? (list-ref parsed 1))
         (version? (list-ref parsed 2))
         (_extra (list-ref parsed 3))
         (steps (list-ref parsed 4))
         (geiser? (list-ref parsed 5)))
    (cond
     (help? (print-usage) (exit 0))
     (version? (print-version) (exit 0))
     (else
      (run-steps steps)
      (cond
       (interactive? (repl geiser?))
       ((null? steps) (repl geiser?))
       (else (exit 0)))))))

;; ---- ece-repl entry point ----

(define (ece-repl-main argv)
  "ece-repl: always enter REPL after optionally loading any positional files."
  (let* ((parsed (parse-argv argv))
         (help? (list-ref parsed 1))
         (version? (list-ref parsed 2))
         (steps (list-ref parsed 4))
         (geiser? (list-ref parsed 5)))
    (cond
     (help? (print-usage) (exit 0))
     (version? (print-version) (exit 0))
     (else
      (run-steps steps)
      (repl geiser?)))))

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
     ((string=? tool "ece-serve") (ece-serve-main rest))
     (else (ece-default-main rest)))))

;; Tool entry points are stubs unless their .scm files are loaded.
;; Callers (the saved image) are responsible for loading ece-build.scm,
;; ece-test.scm, and ece-serve.scm BEFORE dispatch so these definitions
;; are overridden.

(define (ece-build-main argv)
  (display "Error: ece-build.scm not loaded")
  (newline)
  (exit 2))

(define (ece-test-main argv)
  (display "Error: ece-test.scm not loaded")
  (newline)
  (exit 2))

(define (ece-serve-main argv)
  (display "Error: ece-serve.scm not loaded")
  (newline)
  (exit 2))
