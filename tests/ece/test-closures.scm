;;; Closure and binding tests — lambda, let, let*, letrec, named let, closures

(test "lambda basic" (lambda ()
  (assert-equal ((lambda (x) (+ x 1)) 5) 6)
  (assert-equal ((lambda (x y) (* x y)) 3 4) 12)
  (assert-equal ((lambda (a b c) (- a b c)) 10 3 2) 5)))

(test "multi-body lambda" (lambda ()
  (assert-equal ((lambda (x) (+ x 1) (+ x 2)) 10) 12)))

(test "zero-arg lambda" (lambda ()
  (assert-equal ((lambda () 42)) 42)))

(test "rest params" (lambda ()
  (assert-equal ((lambda (x . rest) rest) 1 2 3) '(2 3))
  (assert-equal ((lambda (x . rest) rest) 1) '())
  (assert-equal ((lambda (x y . rest) (list x y rest)) 1 2 3 4) '(1 2 (3 4)))))

(test "rest-only params" (lambda ()
  (assert-equal ((lambda args args) 1 2 3) '(1 2 3))))

(test "define with rest params" (lambda ()
  (define (f x . rest) rest)
  (assert-equal (f 1 2 3) '(2 3))
  (define (g . args) args)
  (assert-equal (g 1 2 3) '(1 2 3))))

(test "closure capture" (lambda ()
  (define (make-adder n)
    (lambda (x) (+ x n)))
  (define add5 (make-adder 5))
  (assert-equal (add5 10) 15)
  (assert-equal (add5 0) 5)))

(test "closure over mutable state" (lambda ()
  (define counter 0)
  (define (inc) (set counter (+ counter 1)))
  (inc) (inc) (inc)
  (assert-equal counter 3)))

(test "let parallel bindings" (lambda ()
  (assert-equal (let ((x 10) (y 20)) (+ x y)) 30)))

(test "let bindings don't see each other" (lambda ()
  (define x 1)
  (assert-equal (let ((x 10) (y x)) y) 1)))

(test "let* sequential bindings" (lambda ()
  (assert-equal (let* ((x 10) (y (+ x 5))) y) 15)))

(test "letrec recursive bindings" (lambda ()
  (assert-equal
   (letrec ((fact (lambda (n) (if (= n 0) 1 (* n (fact (- n 1)))))))
     (fact 5))
   120)))

(test "letrec mutual recursion" (lambda ()
  (assert-true
   (letrec ((is-even? (lambda (n) (if (= n 0) t (is-odd? (- n 1)))))
            (is-odd? (lambda (n) (if (= n 0) '() (is-even? (- n 1))))))
     (is-even? 4)))))

(test "named let" (lambda ()
  (assert-equal
   (let loop ((i 0) (sum 0))
     (if (= i 5) sum (loop (+ i 1) (+ sum i))))
   10)))

(test "define function shorthand" (lambda ()
  (define (square x) (* x x))
  (assert-equal (square 5) 25)
  (define (add a b) (+ a b))
  (assert-equal (add 3 4) 7)))

(test "define variable" (lambda ()
  (define x 42)
  (assert-equal x 42)
  (define y (+ 1 2))
  (assert-equal y 3)))

(test "set mutation" (lambda ()
  (define x 1)
  (set x 2)
  (assert-equal x 2)
  (set x (+ x 10))
  (assert-equal x 12)))
