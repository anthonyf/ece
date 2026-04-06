;;; WASM Test Runner — lean runner without per-test output capture.
;;;
;;; This file is cat'd at the end of the WASM test bundle, after ece-unit.scm
;;; and all tests/ece/common/test-*.scm files. It provides a lean run-tests
;;; that skips per-test output capture (too memory-intensive for WASM), prints
;;; results, and exposes *test-passes* / *test-failures* globals for
;;; wasm/test.js env_lookup.

;; Globals consumed by wasm/test.js via env_lookup.
(define *test-passes* 0)
(define *test-failures* 0)

(define (wasm-run-all-tests)
  "Run all registered tests without per-test output capture."
  (let ((tests-list (get-tests))
        (passes 0)
        (failures 0)
        (failure-msgs '()))
    (for-each
     (lambda (entry)
       (let ((name (car entry))
             (thunk (cadr entry)))
         (set-current-test-name! name)
         (display "  ")
         (display name)
         (newline)
         (guard (e (#t
                    (record-failure!
                     (string-append "ERROR: "
                                    (if (error-object? e)
                                        (error-object-message e)
                                        (write-to-string-safe e))))))
                (thunk))))
     tests-list)
    (set! *test-passes* (get-passes))
    (set! *test-failures* (get-failures))
    ;; Print failures
    (for-each
     (lambda (entry)
       (display "  FAIL: ")
       (display (car entry))
       (display " — ")
       (display (cadr entry))
       (newline))
     (reverse (get-failure-messages)))
    ;; Print summary
    (display (length tests-list))
    (display " collected, ")
    (display (length tests-list))
    (display " ran, ")
    (display *test-passes*)
    (display " passed, ")
    (display *test-failures*)
    (display " failed")
    (newline)))

(wasm-run-all-tests)
