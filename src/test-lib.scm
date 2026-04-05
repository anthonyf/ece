;;; test-lib.scm — Assertion API + test registry for ECE programs.
;;;
;;; State is held in a mutable-box (a single cons) that is itself wrapped
;;; in a parameter, so each `parameterize`-wrapped run-tests invocation
;;; gets its own independent state. Mutation inside the run uses set-car!
;;; on the box rather than re-binding the parameter.
;;;
;;; Exports: `test`, `assert-equal`, `assert-true`, `assert-false`,
;;; `assert-error`, `assert-error-message`, `run-tests`, `reset-test-state!`.

;; ---- State (stored in a single list used as mutable vector) ----
;; Positions: 0=tests 1=passes 2=failures 3=messages 4=current-name 5=per-test-output

(define (make-test-state)
  (list '() 0 0 '() "" '()))

(define *test-state* (make-parameter (make-test-state)))

(define (tests-box) (*test-state*))
(define (get-tests) (list-ref (tests-box) 0))
(define (set-tests! v) (list-set! (tests-box) 0 v))
(define (get-passes) (list-ref (tests-box) 1))
(define (set-passes! v) (list-set! (tests-box) 1 v))
(define (get-failures) (list-ref (tests-box) 2))
(define (set-failures! v) (list-set! (tests-box) 2 v))
(define (get-failure-messages) (list-ref (tests-box) 3))
(define (set-failure-messages! v) (list-set! (tests-box) 3 v))
(define (get-current-test-name) (list-ref (tests-box) 4))
(define (set-current-test-name! v) (list-set! (tests-box) 4 v))

;; list-set! for mutable position access on a list of length 5.
(define (list-set! lst i v)
  (cond
   ((= i 0) (set-car! lst v))
   (else (list-set! (cdr lst) (- i 1) v))))

;; ---- Registration ----

(define (test name thunk)
  "Register a named test thunk."
  (set-tests! (append (get-tests) (list (list name thunk)))))

;; ---- Failure reporting ----

(define (record-pass!)
  (set-passes! (+ (get-passes) 1)))

(define (record-failure! msg)
  (set-failures! (+ (get-failures) 1))
  (set-failure-messages!
   (cons (list (get-current-test-name) msg) (get-failure-messages))))

(define (write-to-string-safe v)
  "Convert V to a string for error messages."
  (let ((p (open-output-string)))
    (write v p)
    (get-output-string p)))

;; ---- Assertions ----

(define (assert-equal actual expected)
  "Pass if (equal? actual expected)."
  (if (equal? actual expected)
      (record-pass!)
      (record-failure!
       (string-append "expected " (write-to-string-safe expected)
                      " got " (write-to-string-safe actual)))))

(define (assert-true val)
  "Pass if VAL is truthy."
  (if val
      (record-pass!)
      (record-failure! "expected truthy value, got false")))

(define (assert-false val)
  "Pass if VAL is #f."
  (if val
      (record-failure! "expected #f, got truthy value")
      (record-pass!)))

(define-macro (assert-error expr)
  "Pass if EXPR raises. Thunk is evaluated inside a guard."
  `(guard (e (#t (record-pass!)))
          ,expr
          (record-failure!
           (string-append "expected error from "
                          (write-to-string-safe ',expr)))))

(define-macro (assert-error-message expr expected-msg)
  "Pass if EXPR raises an error-object whose message equals EXPECTED-MSG."
  (let ((result (gensym)))
    `(let ((,result
            (guard (e
                    ((error-object? e) (error-object-message e))
                    (else ':not-error-object))
                   ,expr
                   ':no-error)))
       (cond
        ((eq? ,result ':no-error)
         (record-failure! "expected error but expression succeeded"))
        ((eq? ,result ':not-error-object)
         (record-failure! "raised value was not an error object"))
        ((equal? ,result ,expected-msg)
         (record-pass!))
        (else
         (record-failure!
          (string-append "expected error message "
                         (write-to-string-safe ,expected-msg)
                         " got "
                         (write-to-string-safe ,result))))))))

;; ---- Runner ----
;;
;; Returns a list: (passes failures failure-msgs).
;; Callers (the ece-test runner) format output.

;; Per-test output captures: (list (test-name captured-output) ...)
(define (get-per-test-output) (list-ref (tests-box) 5))
(define (set-per-test-output! v) (list-set! (tests-box) 5 v))

(define (run-tests)
  "Run all registered tests, capturing each test's output. Returns
 (list passes failures failure-msgs per-test-output)."
  (let ((tests-list (get-tests)))
    (set-per-test-output! '())
    (for-each
     (lambda (entry)
       (let ((name (car entry))
             (thunk (cadr entry))
             (capture (open-output-string)))
         (set-current-test-name! name)
         (parameterize ((current-output-port capture))
           (guard (e (#t
                      (record-failure!
                       (string-append "ERROR: "
                                      (if (error-object? e)
                                          (error-object-message e)
                                          (write-to-string-safe e))))))
                  (thunk)))
         (set-per-test-output!
          (cons (list name (get-output-string capture))
                (get-per-test-output)))))
     tests-list)
    (list (get-passes) (get-failures) (reverse (get-failure-messages))
          (reverse (get-per-test-output)))))

(define (reset-test-state!)
  "Clear counters and registrations. Use between test files."
  (set-tests! '())
  (set-passes! 0)
  (set-failures! 0)
  (set-failure-messages! '())
  (set-current-test-name! ""))
