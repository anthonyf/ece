;;; Tests for direct let/let* compilation — scoping, TCO, define-at-top

;;; --- Scoping correctness (tasks 6.1-6.7) ---

(test "let parallel binding" (lambda ()
  (assert-equal (let ((x 1) (y 2)) (+ x y)) 3)))

(test "let parallel binding with outer shadow" (lambda ()
  (assert-equal (let ((x 10)) (let ((x 1) (y x)) y)) 10)))

(test "let* sequential reference" (lambda ()
  (assert-equal (let* ((x 1) (y (+ x 1))) y) 2)))

(test "let* shadowing" (lambda ()
  (assert-equal (let ((x 1)) (let* ((y x) (x 2)) y)) 1)))

(test "nested let/let*" (lambda ()
  (assert-equal (let ((a 1)) (let* ((b a) (c (+ b 1))) (let ((d (+ c 1))) d))) 3)))

(test "let binding shadows macro" (lambda ()
  (assert-equal (let ((when 42)) when) 42)))

(test "let* binding shadows macro for subsequent bindings" (lambda ()
  (assert-equal (let* ((when 42) (x when)) x) 42)))

;;; --- TCO tests (tasks 7.1-7.4) ---

(test "TCO in let body" (lambda ()
  (define (loop-let n)
    (let ((m (- n 1)))
      (if (= m 0) 'done (loop-let m))))
  (assert-equal (loop-let 1000000) 'done)))

(test "TCO in let* body" (lambda ()
  (define (loop-let* n)
    (let* ((m (- n 1)) (k m))
      (if (= k 0) 'done (loop-let* k))))
  (assert-equal (loop-let* 1000000) 'done)))

(test "TCO in nested let* body" (lambda ()
  (define (loop n)
    (let* ((a (- n 1)))
      (let* ((b a))
        (if (= b 0) 'done (loop b)))))
  (assert-equal (loop 1000000) 'done)))

(test "non-tail let followed by tail call" (lambda ()
  (define (loop n)
    (let ((x n)) x)
    (if (= n 0) 'done (loop (- n 1))))
  (assert-equal (loop 1000000) 'done)))

;;; --- Non-tail let env restoration ---

(test "non-tail let restores environment" (lambda ()
  (define (foo) (let ((x 1)) x) 42)
  (assert-equal (foo) 42)))

(test "nested non-tail lets" (lambda ()
  (assert-equal (let ((x 1)) (let ((y 2)) y) x) 1)))

;;; --- Empty let/let* ---

(test "empty let" (lambda ()
  (assert-equal (let () 42) 42)))

(test "empty let*" (lambda ()
  (assert-equal (let* () 42) 42)))

;;; --- Named let still works ---

(test "named let still works" (lambda ()
  (assert-equal (let loop ((n 10)) (if (= n 0) 'done (loop (- n 1)))) 'done)))

;;; --- Define-at-top enforcement (tasks 8.1-8.6) ---

(test "defines at top of body accepted" (lambda ()
  (define (f)
    (define x 1)
    (define y 2)
    (+ x y))
  (assert-equal (f) 3)))

(test "define after expression is compile-time error" (lambda ()
  ;; NOTE: This test requires the new compiler (post-bootstrap).
  ;; The old bootstrap compiler allows defines after expressions.
  (assert-error
   (eval '(lambda () (display "hi") (define x 1) x)))))

(test "define inside top-level begin accepted" (lambda ()
  (define (f)
    (begin (define x 1) (define y 2))
    (+ x y))
  (assert-equal (f) 3)))

(test "define-macro at top of body accepted" (lambda ()
  (define (f)
    (define-macro (m x) x)
    (define y 1)
    (m y))
  (assert-equal (f) 1)))

(test "define inside if is compile-time error" (lambda ()
  ;; NOTE: This test requires the new compiler (post-bootstrap).
  ;; The old bootstrap compiler allows defines inside if.
  (assert-error
   (eval '(lambda () (if #t (define x 1) (define x 2)) x)))))

(test "top-level defines are unrestricted" (lambda ()
  ;; Top-level forms are not inside a lambda body, no restriction
  (eval '(begin (display "") (define top-level-test-var 99) top-level-test-var))
  (assert-equal (eval 'top-level-test-var) 99)))
