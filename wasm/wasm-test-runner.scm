;;; Continuation serialize!/deserialize round-trip — deferred to runtime.
;;; Cannot run at compile-file time: continuation resume corrupts reader state.
(define (run-continuation-roundtrip-test)
  (define result
    (%raw-call/cc (lambda (k)
      (let ((port (open-output-file ".tmp/ece-rt-ser.dat")))
        (serialize! k port)
        (close-output-port port))
      "first")))
  (if (equal? result "first")
      (begin
        (define loaded-k
          (let ((port (open-input-file ".tmp/ece-rt-ser.dat")))
            (let ((v (deserialize port)))
              (close-input-port port)
              v)))
        (loaded-k "second"))
      (begin
        (assert-equal result "second")
        (set! *test-passes* (+ *test-passes* 1))
        (display "  serialize! / deserialize continuation round-trip")
        (newline))))

;;; WASM Test Runner — with guard wrapping for error isolation
(define (run-tests)
  (define total (length *tests*))
  (display "Running ")
  (display total)
  (display " tests...")
  (newline)
  (newline)
  (for-each
   (lambda (entry)
     (define name (car entry))
     (define thunk (cadr entry))
     (display "  ")
     (display name)
     (newline)
     (guard (e (#t
                (display "    ERROR: ")
                (display (if (error-object? e) (error-object-message e) e))
                (newline)))
       (thunk)))
   *tests*)
  ;; Continuation roundtrip test is CL-only — serialize! walks CL-specific
  ;; continuation internals. Skipped on WASM (run in CL tests instead).
  (newline)
  (display *test-passes*)
  (display " passed, ")
  (display *test-failures*)
  (display " failed")
  (newline)
  (= *test-failures* 0))
