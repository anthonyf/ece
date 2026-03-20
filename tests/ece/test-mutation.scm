;;; Mutation primitive tests
;;; Verify set-car! and set-cdr! behavior.

(test "set-car! modifies pair" (lambda ()
  (define p (cons 1 2))
  (set-car! p 99)
  (assert-equal (car p) 99)))

(test "set-cdr! modifies pair" (lambda ()
  (define p (cons 1 2))
  (set-cdr! p 99)
  (assert-equal (cdr p) 99)))

(test "mutation visible through shared reference" (lambda ()
  (define p (cons 1 2))
  (define q p)
  (set-car! p 99)
  (assert-equal (car q) 99)))

(test "mutation inside closure affects outer scope" (lambda ()
  (define p (list 1 2 3))
  (define (mutate!) (set-car! p 99))
  (mutate!)
  (assert-equal (car p) 99)))

(test "set-car! on list element" (lambda ()
  (define xs (list 1 2 3))
  (set-car! (cdr xs) 20)
  (assert-equal xs (list 1 20 3))))

(test "set-cdr! truncates list" (lambda ()
  (define xs (list 1 2 3))
  (set-cdr! xs '())
  (assert-equal xs (list 1))))
