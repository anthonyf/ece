;;; Parameter tests — make-parameter, parameterize

(test "make-parameter read" (lambda ()
  (define p (make-parameter 42))
  (assert-equal (p) 42)))

(test "make-parameter set" (lambda ()
  (define p (make-parameter 42))
  (p 99)
  (assert-equal (p) 99)))

(test "make-parameter with converter" (lambda ()
  (define p (make-parameter "hello" string-length))
  (assert-equal (p) 5)))

(test "parameterize dynamic binding" (lambda ()
  (define p (make-parameter 42))
  (assert-equal (parameterize ((p 99)) (p)) 99)
  ;; restored after exit
  (assert-equal (p) 42)))

(test "parameterize propagates to called functions" (lambda ()
  (define p (make-parameter 0))
  (define (read-p) (p))
  (assert-equal (parameterize ((p 99)) (read-p)) 99)))

(test "parameterize multiple bindings" (lambda ()
  (define p1 (make-parameter 1))
  (define p2 (make-parameter 2))
  (parameterize ((p1 10) (p2 20))
    (assert-equal (p1) 10)
    (assert-equal (p2) 20))))

(test "parameterize nested" (lambda ()
  (define p (make-parameter 0))
  (parameterize ((p 10))
    (assert-equal (p) 10)
    (parameterize ((p 20))
      (assert-equal (p) 20))
    (assert-equal (p) 10))))
