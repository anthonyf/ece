;;; Error message tests — verify error content is inspectable

(test "custom error message" (lambda ()
  (assert-error-message (error "custom problem") "custom problem")))

(test "custom error with irritants" (lambda ()
  (assert-equal
   (guard (e (#t (error-object-irritants e)))
     (error "out of range" 42))
   '(42))))

(test "custom error multiple irritants" (lambda ()
  (assert-equal
   (guard (e (#t (error-object-irritants e)))
     (error "bounds" 3 0 10))
   '(3 0 10))))

(test "assert with custom message" (lambda ()
  (assert-error-message (assert #f "my custom assert message") "my custom assert message")))

(test "assert default message" (lambda ()
  (assert-error-message (assert #f) "Assertion failed")))

(test "error-object round-trip" (lambda ()
  (define obj (make-error-object "test msg" '(a b c)))
  (assert-true (error-object? obj))
  (assert-equal (error-object-message obj) "test msg")
  (assert-equal (error-object-irritants obj) '(a b c))))

;; CL-bridged primitive errors: type errors and division-by-zero are
;; caught at the CL level and bridged to ECE error-objects via raise.
;; Messages are CL-implementation-specific, so we test error-object?
;; rather than exact message text.

(test "guard catches (+ \"a\" 1)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (+ "a" 1) ()))))

(test "guard catches (car 5)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (car 5) ()))))

(test "guard catches (/ 1 0)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (/ 1 0) ()))))

(test "guard catches (vector-ref 42 0)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (vector-ref 42 0) ()))))

(test "guard catches (- \"x\")" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (- "x") ()))))

(test "guard catches (* #t 2)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (* #t 2) ()))))

(test "guard catches (< 1 \"two\")" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (< 1 "two") ()))))

(test "guard catches (cdr 42)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (cdr 42) ()))))

(test "guard catches (string=? 1 2)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (string=? 1 2) ()))))

(test "guard catches (char->integer 5)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (char->integer 5) ()))))

(test "guard catches (bitwise-and 1.5 2)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (bitwise-and 1.5 2) ()))))

(test "guard catches (modulo 10 0)" (lambda ()
  (assert-true (guard (e ((error-object? e) #t)) (modulo 10 0) ()))))

;; Bridged error has message and irritants
(test "bridged error has message string" (lambda ()
  (assert-true
   (guard (e ((error-object? e) (string? (error-object-message e))))
     (+ "a" 1) ()))))

(test "bridged error has irritants list" (lambda ()
  (assert-true
   (guard (e ((error-object? e) (pair? (error-object-irritants e))))
     (+ "a" 1) ()))))

;; Division by zero message is fixed format
(test "division by zero message" (lambda ()
  (assert-error-message (/ 1 0) "/: division by zero")))

;; Verify primitives still work normally
(test "+ works normally" (lambda ()
  (assert-equal (+ 1 2 3) 6)))

(test "car works normally" (lambda ()
  (assert-equal (car '(a b)) 'a)))

(test "/ works normally" (lambda ()
  (assert-equal (/ 10 2) 5)))

(test "car of nil returns nil" (lambda ()
  (assert-equal (car '()) '())))

(test "cdr of nil returns nil" (lambda ()
  (assert-equal (cdr '()) '())))

(test "unbound variable error" (lambda ()
  (assert-error this-variable-does-not-exist-12345)))
