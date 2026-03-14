;;; ECE Native Test Framework
;;; Minimal test runner with pass/fail counting and error isolation.

;; --- State ---

(define *tests* '())
(define *test-passes* 0)
(define *test-failures* 0)
(define *current-test-thunk* '())

;; --- Registration ---

(define (test name thunk)
  "Register a named test thunk for later execution."
  (set *tests* (append *tests* (list (list name thunk)))))

;; --- Assertions ---

(define (assert-equal actual expected)
  "Check that actual equals expected using equal?."
  (if (equal? actual expected)
      (set *test-passes* (+ *test-passes* 1))
      (begin
        (set *test-failures* (+ *test-failures* 1))
        (display "    FAIL: expected ")
        (write expected)
        (display " got ")
        (write actual)
        (newline))))

(define (assert-true val)
  "Check that val is truthy (not false/nil)."
  (if val
      (set *test-passes* (+ *test-passes* 1))
      (begin
        (set *test-failures* (+ *test-failures* 1))
        (display "    FAIL: expected truthy value, got false")
        (newline))))

(define-macro (assert-error expr)
  "Check that expr signals an error. Uses try-eval."
  `(if (eof? (try-eval ',expr))
       (set *test-passes* (+ *test-passes* 1))
       (begin
         (set *test-failures* (+ *test-failures* 1))
         (display "    FAIL: expected error from ")
         (display ',expr)
         (newline))))

(define-macro (assert-error-message expr expected-msg)
  "Check that expr raises an error with the expected message."
  (let ((result (gensym))
        (msg-val (gensym)))
    `(let ((,result
            (guard (e
                    ((error-object? e) (error-object-message e))
                    (else ':not-error-object))
              ,expr
              ':no-error)))
       (cond
        ((eq? ,result ':no-error)
         (begin
           (set *test-failures* (+ *test-failures* 1))
           (display "    FAIL: expected error but expression succeeded")
           (newline)))
        ((eq? ,result ':not-error-object)
         (begin
           (set *test-failures* (+ *test-failures* 1))
           (display "    FAIL: raised value was not an error object")
           (newline)))
        ((equal? ,result ,expected-msg)
         (set *test-passes* (+ *test-passes* 1)))
        (else
         (begin
           (set *test-failures* (+ *test-failures* 1))
           (display "    FAIL: expected error message ")
           (write ,expected-msg)
           (display " got ")
           (write ,result)
           (newline)))))))

;; --- Runner ---

(define (run-tests)
  "Execute all registered tests with error isolation. Returns #t if all pass."
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
     ;; Run with error isolation via try-eval
     (set *current-test-thunk* thunk)
     (try-eval '(*current-test-thunk*)))
   *tests*)
  (newline)
  (display *test-passes*)
  (display " passed, ")
  (display *test-failures*)
  (display " failed")
  (newline)
  (= *test-failures* 0))
