;;; guard / raise / error-object tests — R7RS exception handling

(test "guard catches raised error" (lambda ()
  (assert-equal
   (guard (e (#t 'caught))
     (error "fail"))
   'caught)))

(test "guard with error-object inspection" (lambda ()
  (assert-equal
   (guard (e ((error-object? e) (error-object-message e)))
     (error "hello"))
   "hello")))

(test "guard with irritants" (lambda ()
  (assert-equal
   (guard (e ((error-object? e) (error-object-irritants e)))
     (error "out of range" 5 10))
   '(5 10))))

(test "guard with multiple clauses" (lambda ()
  (assert-equal
   (guard (e ((string? e) 'string)
             ((number? e) 'number)
             (else 'other))
     (raise 42))
   'number)))

(test "guard with else clause" (lambda ()
  (assert-equal
   (guard (e (else 'default))
     (raise 'anything))
   'default)))

(test "guard body returns normally" (lambda ()
  (assert-equal
   (guard (e (#t 'error))
     (+ 1 2))
   3)))

(test "guard re-raises when no clause matches" (lambda ()
  (assert-equal
   (guard (outer (else 'outer-caught))
     (guard (inner ((number? inner) 'num))
       (raise "not-a-number")))
   'outer-caught)))

(test "guard nested" (lambda ()
  (assert-equal
   (guard (outer (#t 'outer))
     (guard (inner (#t 'inner))
       (error "boom")))
   'inner)))

(test "error-object? predicate" (lambda ()
  (assert-equal
   (guard (e (#t (error-object? e)))
     (error "test"))
   t)))

(test "error-object? false for non-errors" (lambda ()
  (assert-true (not (error-object? 42)))
  (assert-true (not (error-object? "hello")))
  (assert-true (not (error-object? '())))))

(test "raise with non-error object" (lambda ()
  (assert-equal
   (guard (e (#t e))
     (raise 'my-signal))
   'my-signal)))

(test "with-exception-handler basic" (lambda ()
  (define caught '())
  (with-exception-handler
   (lambda (e) (set caught e))
   (lambda ()
     (guard (e (#t 'handled))
       (error "test"))))
  ;; guard handles it, so with-exception-handler's handler is NOT called
  (assert-equal caught '())))

(test "error with no irritants" (lambda ()
  (assert-equal
   (guard (e (#t (error-object-irritants e)))
     (error "simple"))
   '())))
