(defpackage ece/tests/main
  (:use :cl
        :ece
        :rove))
(in-package :ece/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :ece)' in your Lisp.

(deftest test-self-eval
  (testing "integers evaluate to themselves"
    (ok (evaluate 4 nil) 4)
    (ok (evaluate -10 nil) -10)
    (ok (evaluate .4 nil) .4)))

(deftest test-variable-eval
  (testing "variables evaluate to their bound values"
    (ok (evaluate 'x '((x . 5)(y . 10))) 5)
    (ok (evaluate 'y '((x . 5)(y . 10))) 10)
    (ok (evaluate 'z '((x . 5)(y . 10)(z . -3))) -3))

  (testing "unbound variables signal an error"
    (signals (evaluate 'a '((b . 2)(c . 3))))
    (signals (evaluate 'foo nil))))


(deftest test-quote-eval
  (testing "quote special form returns the quoted expression without evaluating it"
    (ok (evaluate '(quote a) nil) 'a)
    (ok (evaluate '(quote (1 2 3)) nil) '(1 2 3))
    (ok (evaluate '(quote (x y z)) '((x . 10)(y . 20)(z . 30))) '(x y z))))


(deftest test-lambda-eval
  (testing "lambda expressions evaluate correctly with given arguments"
    (ok (evaluate '((lambda (x) (+ x 1)) 5)) 6)
    (ok (evaluate '((lambda (x y) (* x y)) 3 4)) 12)
    (ok (evaluate '((lambda (a b c) (- a b c)) 10 3 2)) 5))

  (testing "lambda expressions with variable bindings"
    (ok (evaluate '((lambda (x) (+ x y)) 5) (append *global-env*
						    '((y . 10)))) 15)
    (ok (evaluate '((lambda (a b) (+ a b)) b 2) (append *global-env*
							'((b . 8)))) 10)))

