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
  (display "       ece dev [ece.project] [OPTIONS]")
  (newline)
  (display "       ece init web DIR [--force]")
  (newline)
  (newline)
  (display "Options:")
  (newline)
  (display "  --load FILE           Load and execute FILE")
  (newline)
  (display "  -e EXPR, --eval EXPR  Evaluate EXPR")
  (newline)
  (display "  --module MODULE       Select module entry point, e.g. '(app main)'")
  (newline)
  (display "  --entry SYMBOL        Run exported procedure from --module")
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

;; ---- App skeleton init ----

(define (copy-file-binary/simple src dst)
  "Copy SRC to DST byte-for-byte."
  (let ((in (open-binary-input-file src))
        (out (open-binary-output-file dst)))
    (let loop ()
      (let ((b (read-byte in)))
        (cond
         ((eof? b)
          (close-input-port in)
          (close-output-port out))
         (else
          (write-byte b out)
          (loop)))))))

(define (copy-file-text/simple src dst)
  "Copy text SRC to DST."
  (let ((in (open-input-file src))
        (out (open-output-file dst)))
    (let loop ()
      (let ((ch (read-char in)))
        (cond
         ((eof? ch)
          (close-input-port in)
          (close-output-port out))
         (else
          (%write-char-to-port ch out)
          (loop)))))))

(define (parse-init-web-args argv)
  "Parse `ece init web' ARGV after the web subcommand.
Returns (list target-dir force?)."
  (let loop ((rest argv) (target #f) (force? #f))
    (cond
     ((null? rest)
      (cond
       (target (list target force?))
       (else
        (display "Error: ece init web requires DIR")
        (newline)
        (exit 2))))
     ((string=? (car rest) "--force")
      (loop (cdr rest) target #t))
     ((or (string=? (car rest) "--help")
          (string=? (car rest) "-h"))
      (print-init-usage)
      (exit 0))
     ((long-opt? (car rest))
      (display "Error: unknown ece init web option: ")
      (display (car rest))
      (newline)
      (exit 2))
     (target
      (display "Error: ece init web accepts exactly one DIR")
      (newline)
      (exit 2))
     (else
      (loop (cdr rest) (car rest) force?)))))

(define (print-init-usage)
  (display "Usage: ece init web DIR [--force]")
  (newline)
  (display "Create a minimal app-local web skeleton for ece-serve.")
  (newline))

(define (ensure-init-target-safe! path force?)
  "Refuse to overwrite PATH unless FORCE? is true."
  (when (and (not force?) (%file-exists? path))
    (display "Error: refusing to overwrite existing file: ")
    (display path)
    (newline)
    (display "Use --force to overwrite skeleton files.")
    (newline)
    (exit 2)))

(define (ece-init-web-project-text target-dir)
  "Return the default ece.project contents for a generated web app."
  (string-append
   "(:ece-project\n"
   " :version 1\n"
   " :name " (write-to-string-flat (basename target-dir)) "\n"
   " :source-roots (\".\")\n"
   " :entry \"main.scm\"\n"
   " :static-root \".\"\n"
   " :index \"index.html\")\n"))

(define (write-text-file/simple path text)
  "Write TEXT to PATH."
  (let ((out (open-output-file path)))
    (display text out)
    (close-output-port out)))

(define (ece-init-web target-dir force?)
  "Create a minimal app-local web skeleton under TARGET-DIR."
  (let* ((home (ece-home))
         (template-dir (path-join home "templates" "web-app"))
         (project-file (path-join target-dir "ece.project"))
         (files (list (list (path-join template-dir "main.scm")
                            (path-join target-dir "main.scm")
                            'text)
                      (list (path-join template-dir "index.html")
                            (path-join target-dir "index.html")
                            'text)
                      (list (path-join home "glue.js")
                            (path-join target-dir "ece-runtime.js")
                            'binary)
                      (list (path-join home "runtime.wasm")
                            (path-join target-dir "runtime.wasm")
                            'binary)
                      (list (path-join home "bootstrap.ecec")
                            (path-join target-dir "bootstrap.ecec")
                            'binary))))
    (for-each
     (lambda (spec)
       (let ((src (car spec)))
         (when (not (%file-exists? src))
           (display "Error: skeleton source file missing: ")
           (display src)
           (newline)
           (exit 2))))
     files)
    (%make-directory target-dir)
    (for-each
     (lambda (spec)
       (ensure-init-target-safe! (cadr spec) force?))
     files)
    (ensure-init-target-safe! project-file force?)
    (for-each
     (lambda (spec)
       (let ((src (car spec))
             (dst (cadr spec))
             (kind (caddr spec)))
         (cond
          ((eq? kind 'text) (copy-file-text/simple src dst))
          (else (copy-file-binary/simple src dst)))))
     files)
    (write-text-file/simple project-file (ece-init-web-project-text target-dir))
    (display "Created ECE web app skeleton in ")
    (display target-dir)
    (newline)
    (display "Next:")
    (newline)
    (display "  cd ")
    (display target-dir)
    (newline)
    (display "  ece dev")
    (newline)))

(define (ece-init-main argv)
  "Dispatch `ece init' subcommands."
  (cond
   ((or (null? argv)
        (string=? (car argv) "--help")
        (string=? (car argv) "-h"))
    (print-init-usage)
    (exit 0))
   ((string=? (car argv) "web")
    (let ((parsed (parse-init-web-args (cdr argv))))
      (ece-init-web (car parsed) (cadr parsed))
      (exit 0)))
   (else
    (display "Error: unknown ece init target: ")
    (display (car argv))
    (newline)
    (print-init-usage)
    (exit 2))))

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
;;   module-name   — module name datum from --module, or #f
;;   entry-name    — symbol from --entry, or #f

(define (read-cli-datum option value)
  "Read exactly one datum from VALUE for OPTION."
  (let ((port (open-input-string value)))
    (let ((datum (read port)))
      (cond
       ((eof? datum)
        (display "Error: ")
        (display option)
        (display " requires a datum")
        (newline)
        (exit 2))
       ((not (eof? (read port)))
        (display "Error: ")
        (display option)
        (display " accepts exactly one datum")
        (newline)
        (exit 2))
       (else
        (close-input-port port)
        datum)))))

(define (read-entry-symbol value)
  "Read one symbol from VALUE for --entry."
  (let ((datum (read-cli-datum "--entry" value)))
    (when (not (symbol? datum))
      (display "Error: --entry requires a symbol")
      (newline)
      (exit 2))
    datum))

(define (parse-argv argv)
  "Parse argv (excluding argv[0]). Returns
 (list interactive? help? version? extra-args steps geiser? module-name entry-name)."
  (let loop ((rest argv)
             (interactive? #f)
             (help? #f)
             (version? #f)
             (extra-args '())
             (steps '())
             (geiser? #f)
             (module-name #f)
             (entry-name #f))
    (cond
     ((null? rest)
      (list interactive? help? version? extra-args (reverse steps) geiser?
            module-name entry-name))
     (else
      (let ((arg (car rest)))
        (cond
         ;; -- : take everything after it as passthrough args
         ((opt-terminator? arg)
          (list interactive? help? version? (cdr rest) (reverse steps) geiser?
                module-name entry-name))
         ;; --help / -h
         ((or (string=? arg "--help") (string=? arg "-h"))
          (loop (cdr rest) interactive? #t version? extra-args steps geiser?
                module-name entry-name))
         ;; --version / -V
         ((or (string=? arg "--version") (string=? arg "-V"))
          (loop (cdr rest) interactive? help? #t extra-args steps geiser?
                module-name entry-name))
         ;; --interactive / -i
         ((or (string=? arg "--interactive") (string=? arg "-i"))
          (loop (cdr rest) #t help? version? extra-args steps geiser?
                module-name entry-name))
         ;; --geiser
         ((string=? arg "--geiser")
          (loop (cdr rest) interactive? help? version? extra-args steps #t
                module-name entry-name))
         ;; --module MODULE
         ((string=? arg "--module")
          (if (or (null? (cdr rest)))
              (begin
                (display "Error: --module requires an argument")
                (newline)
                (exit 2))
              (loop (cddr rest) interactive? help? version? extra-args steps
                    geiser? (read-cli-datum "--module" (cadr rest)) entry-name)))
         ;; --entry SYMBOL
         ((string=? arg "--entry")
          (if (or (null? (cdr rest)))
              (begin
                (display "Error: --entry requires an argument")
                (newline)
                (exit 2))
              (loop (cddr rest) interactive? help? version? extra-args steps
                    geiser? module-name (read-entry-symbol (cadr rest)))))
         ;; --load FILE
         ((string=? arg "--load")
          (if (or (null? (cdr rest)))
              (begin
                (display "Error: --load requires an argument")
                (newline)
                (exit 2))
              (loop (cddr rest) interactive? help? version? extra-args
                    (cons (list 'load (cadr rest)) steps) geiser?
                    module-name entry-name)))
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
                    (cons (list 'eval (cadr rest)) steps) geiser?
                    module-name entry-name)))
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
                (cons (list 'load arg) steps) geiser?
                module-name entry-name))))))))

(define (run-module-entry-if-requested module-name entry-name)
  "Run the requested module entry point, or do nothing when none was supplied."
  (cond
   ((and module-name entry-name)
    (run-module-export module-name entry-name))
   (module-name
    (display "Error: --module requires --entry")
    (newline)
    (exit 2))
   (entry-name
    (display "Error: --entry requires --module")
    (newline)
    (exit 2))
   (else #f)))

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
         (geiser? (list-ref parsed 5))
         (module-name (list-ref parsed 6))
         (entry-name (list-ref parsed 7)))
    (cond
     (help? (print-usage) (exit 0))
     (version? (print-version) (exit 0))
     (else
      (run-steps steps)
      (run-module-entry-if-requested module-name entry-name)
      (cond
       (interactive? (repl geiser?))
       ((and (null? steps) (not module-name) (not entry-name)) (repl geiser?))
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
     ((and (string=? tool "ece")
           (not (null? rest))
           (string=? (car rest) "dev"))
      (ece-dev-main (cdr rest)))
     ((and (string=? tool "ece")
           (not (null? rest))
           (string=? (car rest) "init"))
      (ece-init-main (cdr rest)))
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

(define (ece-dev-main argv)
  (display "Error: ece-serve.scm not loaded")
  (newline)
  (exit 2))
