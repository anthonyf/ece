;; Golden test: closures and higher-order functions
(define (make-adder n)
  (lambda (x) (+ n x)))

(define add5 (make-adder 5))
(add5 10)

(define (compose f g)
  (lambda (x) (f (g x))))
