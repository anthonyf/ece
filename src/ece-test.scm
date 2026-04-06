;;; ece-test.scm — Test runner for ECE programs.
;;;
;;; Discovers test-*.scm files in directories (or runs specified files),
;;; loads each with a fresh test-state, captures output, reports, and
;;; exits 0/1/2 based on results.

;; ---- Argument parsing ----

(define (parse-test-args argv)
  "Parse ece-test CLI args. Returns
 (list verbose? help? filters paths)."
  (let loop ((rest argv)
             (verbose? #f)
             (help? #f)
             (filters '())
             (paths '()))
    (cond
     ((null? rest)
      (list verbose? help? (reverse filters) (reverse paths)))
     (else
      (let ((arg (car rest)))
        (cond
         ((or (string=? arg "-h") (string=? arg "--help"))
          (loop (cdr rest) verbose? #t filters paths))
         ((or (string=? arg "-v") (string=? arg "--verbose"))
          (loop (cdr rest) #t help? filters paths))
         ((string=? arg "--filter")
          (cond
           ((null? (cdr rest))
            (display "Error: --filter requires an argument")
            (newline)
            (exit 2))
           (else
            (loop (cddr rest) verbose? help?
                  (cons (cadr rest) filters) paths))))
         ((starts-with? arg "-")
          (display "Error: Unknown option: ")
          (display arg)
          (newline)
          (exit 2))
         (else
          (loop (cdr rest) verbose? help? filters (cons arg paths)))))))))

(define (ece-test-usage)
  (display "Usage: ece-test [OPTIONS] <path> ...")
  (newline)
  (newline)
  (display "Paths may be directories (scanned for test-*.scm files)")
  (newline)
  (display "or individual .scm files.")
  (newline)
  (newline)
  (display "Options:")
  (newline)
  (display "  -v, --verbose        Show output from all tests (not just failures)")
  (newline)
  (display "  --filter PATTERN     Run only tests whose name contains PATTERN")
  (newline)
  (display "                       (substring match, case-sensitive;")
  (newline)
  (display "                       repeatable with OR semantics)")
  (newline)
  (display "  -h, --help           Show this help")
  (newline))

;; ---- Test file discovery ----

(define (is-test-file? name)
  "Predicate: does NAME match test-*.scm?"
  (and (starts-with? name "test-")
       (ends-with? name ".scm")))

(define (discover-tests-in-dir dir)
  "Return list of test-*.scm files in DIR, sorted by name."
  (let ((entries (%list-directory dir)))
    (let loop ((rest entries) (acc '()))
      (cond
       ((null? rest) (reverse acc))
       ((is-test-file? (car rest))
        (loop (cdr rest) (cons (path-join dir (car rest)) acc)))
       (else (loop (cdr rest) acc))))))

(define (expand-paths paths)
  "For each path, if it's a directory, find test-*.scm files.
Otherwise use it as a single file. Returns a flat list of file paths."
  (let loop ((rest paths) (acc '()))
    (cond
     ((null? rest) (reverse acc))
     (else
      (let ((p (car rest)))
        (cond
         ((not (%file-exists? p))
          (display "Error: path does not exist: ")
          (display p)
          (newline)
          (exit 2))
         ((ends-with? p ".scm")
          (loop (cdr rest) (cons p acc)))
         (else
          (loop (cdr rest)
                (append (reverse (discover-tests-in-dir p)) acc)))))))))

;; ---- Test execution ----

(define (run-one-test-file path verbose? matcher)
  "Load PATH, run registered tests (filtered by MATCHER) with per-test output
 capture. Returns
 (list file collected ran passes failures failure-msgs per-test-output)."
  (let ((load-error #f))
    (parameterize ((*test-state* (make-test-state)))
      (guard (e (#t (set! load-error
                          (if (error-object? e)
                              (error-object-message e)
                              "load error"))))
             (load path))
      (cond
       (load-error
        (list path 0 0 0 1 (list (list "(load)" load-error)) '()))
       (else
        (let ((result (run-tests matcher)))
          ;; result = (collected ran passes failures messages per-test-output)
          (list path (car result) (cadr result) (caddr result) (cadddr result)
                (list-ref result 4) (list-ref result 5))))))))

;; ---- Reporting ----

(define (find-capture-for-test name per-test-output)
  "Find captured output string for test NAME in PER-TEST-OUTPUT.
Returns \"\" if not found."
  (let loop ((rest per-test-output))
    (cond
     ((null? rest) "")
     ((string=? (car (car rest)) name) (cadr (car rest)))
     (else (loop (cdr rest))))))

(define (print-file-results result verbose?)
  (let ((path (car result))
        (collected (cadr result))
        (ran (caddr result))
        (passes (cadddr result))
        (failures (list-ref result 4))
        (messages (list-ref result 5))
        (per-test-output (list-ref result 6)))
    (display path)
    (display ": ")
    (display collected)
    (display " collected, ")
    (display ran)
    (display " ran, ")
    (display passes)
    (display " passed, ")
    (display failures)
    (display " failed")
    (newline)
    ;; Print failures with captured output
    (for-each
     (lambda (msg-entry)
       (let* ((name (car msg-entry))
              (msg (cadr msg-entry))
              (captured (find-capture-for-test name per-test-output)))
         (display "    FAIL: ")
         (display name)
         (display " — ")
         (display msg)
         (newline)
         (when (> (string-length captured) 0)
           (display "      (output: ")
           (display captured)
           (display ")")
           (newline))))
     messages)
    ;; Verbose: print captured output for all tests
    (when verbose?
      (for-each
       (lambda (entry)
         (let ((name (car entry))
               (captured (cadr entry)))
           (when (> (string-length captured) 0)
             (display "    ")
             (display name)
             (display ": ")
             (display captured)
             (newline))))
       per-test-output))))

(define (print-summary all-results)
  (let loop ((rest all-results)
             (total-collected 0)
             (total-ran 0)
             (total-passes 0)
             (total-failures 0))
    (cond
     ((null? rest)
      (newline)
      (display "Total: ")
      (display total-collected)
      (display " collected, ")
      (display total-ran)
      (display " ran, ")
      (display total-passes)
      (display " passed, ")
      (display total-failures)
      (display " failed")
      (newline)
      (list total-collected total-ran total-passes total-failures))
     (else
      (let* ((r (car rest))
             (c (cadr r))
             (n (caddr r))
             (p (cadddr r))
             (f (list-ref r 4)))
        (loop (cdr rest)
              (+ total-collected c)
              (+ total-ran n)
              (+ total-passes p)
              (+ total-failures f)))))))

;; ---- Main entry point ----

(define (ece-test-main argv)
  "ece-test: run test suites and report."
  (let* ((parsed (parse-test-args argv))
         (verbose? (car parsed))
         (help? (cadr parsed))
         (filters (caddr parsed))
         (paths (cadddr parsed)))
    (when help?
      (ece-test-usage)
      (exit 0))
    (when (null? paths)
      (display "Error: at least one path argument is required")
      (newline)
      (ece-test-usage)
      (exit 2))
    (let* ((matcher (make-substring-matcher filters))
           (files (expand-paths paths))
           (results
            (let loop ((rest files) (acc '()))
              (cond
               ((null? rest) (reverse acc))
               (else
                (let ((r (run-one-test-file (car rest) verbose? matcher)))
                  (print-file-results r verbose?)
                  (loop (cdr rest) (cons r acc)))))))
           (totals (print-summary results))
           (total-collected (car totals))
           (failures (cadddr totals)))
      (cond
       ((= total-collected 0)
        (display "Error: zero tests collected from the given paths")
        (newline)
        (exit 2))
       ((> failures 0) (exit 1))
       (else (exit 0))))))
