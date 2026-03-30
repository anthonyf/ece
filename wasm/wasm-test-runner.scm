;;; Continuation serialize!/deserialize round-trip — deferred to runtime.
;;; Cannot run at compile-file time: continuation resume corrupts reader state.
(define (run-continuation-roundtrip-test)
  (define result
    (%raw-call/cc (lambda (k)
      (let ((port (open-output-file "/tmp/ece-rt-ser.dat")))
        (serialize! k port)
        (close-output-port port))
      "first")))
  (if (equal? result "first")
      (begin
        (define loaded-k
          (let ((port (open-input-file "/tmp/ece-rt-ser.dat")))
            (let ((v (deserialize port)))
              (close-input-port port)
              v)))
        (loaded-k "second"))
      (begin
        (assert-equal result "second")
        (set! *test-passes* (+ *test-passes* 1))
        (display "  serialize! / deserialize continuation round-trip")
        (newline))))

;;; WASM Test Runner — calls thunks directly (no try-eval)
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
     (thunk))
   *tests*)
  ;; Run deferred tests that can't be in the test framework
  (run-continuation-roundtrip-test)
  (newline)
  (display *test-passes*)
  (display " passed, ")
  (display *test-failures*)
  (display " failed")
  (newline)
  (= *test-failures* 0))
