;;; Conformance Test Framework
;;; Minimal framework for running external Scheme conformance test suites.

(define *conformance-passes* 0)
(define *conformance-failures* 0)

(define-syntax conformance-test
  (syntax-rules ()
    ((_ name expected expr)
     (let ((result (guard (e (#t 'conformance-error))
                     expr)))
       (if (equal? result expected)
           (begin
             (set! *conformance-passes* (+ *conformance-passes* 1))
             (display "  PASS: ")
             (display name)
             (newline))
           (begin
             (set! *conformance-failures* (+ *conformance-failures* 1))
             (display "  FAIL: ")
             (display name)
             (newline)
             (display "    expected: ")
             (display expected)
             (newline)
             (display "    actual:   ")
             (display result)
             (newline)))))))

(define (conformance-summary)
  (newline)
  (display "Conformance results: ")
  (display *conformance-passes*)
  (display " passed, ")
  (display *conformance-failures*)
  (display " failed")
  (newline))
