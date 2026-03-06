(defpackage ece/tests/main
  (:use :cl
        :ece
        :rove))
(in-package :ece/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :ece)' in your Lisp.

(deftest test-self-eval
  (testing "integers evaluate to themselves"
    (ok (= (evaluate 4 nil) 4))
    (ok (= (evaluate -10 nil) -10))
    (ok (= (evaluate .4 nil) .4))))

(deftest test-variable-eval
  (testing "variables evaluate to their bound values"
    (ok (= (evaluate 'x '((x . 5)(y . 10))) 5))
    (ok (= (evaluate 'y '((x . 5)(y . 10))) 10))
    (ok (= (evaluate 'z '((x . 5)(y . 10)(z . -3))) -3)))

  (testing "unbound variables signal an error"
    (signals (evaluate 'a '((b . 2)(c . 3))))
    (signals (evaluate 'foo nil))))


(deftest test-quote-eval
  (testing "quote special form returns the quoted expression without evaluating it"
    (ok (equal (evaluate '(quote a) nil) 'a))
    (ok (equal (evaluate '(quote (1 2 3)) nil) '(1 2 3)))
    (ok (equal (evaluate '(quote (x y z)) '((x . 10)(y . 20)(z . 30))) '(x y z)))))


(deftest test-lambda-eval
  (testing "lambda expressions evaluate correctly with given arguments"
    (ok (= (evaluate '((lambda (x) (+ x 1)) 5)) 6))
    (ok (= (evaluate '((lambda (x y) (* x y)) 3 4)) 12))
    (ok (= (evaluate '((lambda (a b c) (- a b c)) 10 3 2)) 5)))

  (testing "lambda expressions with variable bindings"
    (ok (= (evaluate '((lambda (x) (+ x y)) 5) (append *global-env*
						    '((y . 10)))) 15))
    (ok (= (evaluate '((lambda (a b) (+ a b)) b 2) (append *global-env*
							'((b . 8)))) 10))))

(deftest test-begin-eval
  (testing "begin evaluates sequence and returns last value"
    (ok (= (evaluate '(begin 42)) 42))
    (ok (= (evaluate '(begin 1 2 3)) 3))
    (ok (= (evaluate '(begin (+ 1 2) (* 3 4))) 12))))

(deftest test-string-self-eval
  (testing "strings evaluate to themselves"
    (ok (equal (evaluate "hello" nil) "hello"))
    (ok (equal (evaluate "" nil) ""))))

(deftest test-division
  (testing "division primitive"
    (ok (= (evaluate '(/ 10 2)) 5))))

(deftest test-comparison-primitives
  (testing "comparison operators"
    (ok (evaluate '(= 3 3)))
    (ok (evaluate '(< 1 2)))
    (ok (evaluate '(> 5 3)))
    (ok (evaluate '(<= 3 3)))
    (ok (evaluate '(>= 4 3)))))

(deftest test-list-primitives
  (testing "cons, car, cdr"
    (ok (equal (evaluate '(cons 1 2)) '(1 . 2)))
    (ok (= (evaluate '(car (cons 1 2))) 1))
    (ok (= (evaluate '(cdr (cons 1 2))) 2)))

  (testing "list"
    (ok (equal (evaluate '(list 1 2 3)) '(1 2 3))))

  (testing "null? and not"
    (ok (evaluate '(ece::null? (quote ()))))
    (ok (not (evaluate '(ece::null? (quote (1))))))
    (ok (evaluate '(not (quote ()))))))

(deftest test-multi-body-lambda
  (testing "lambda with multiple body expressions returns last value"
    (ok (= (evaluate '((lambda (x) (+ x 1) (+ x 2)) 10)) 12))))

(deftest test-nested-application
  (testing "nested function calls"
    (ok (= (evaluate '(+ (* 2 3) (- 10 4))) 12))
    (ok (= (evaluate '(+ (+ 1 2) (+ 3 (+ 4 5)))) 15))))

(deftest test-zero-arg-application
  (testing "zero-argument function application"
    (ok (equal (evaluate '(list)) nil))))

(deftest test-if-eval
  (testing "truthy predicate takes consequent"
    (ok (= (evaluate '(if 1 42 0)) 42))
    (ok (= (evaluate '(if (< 1 2) 10 20)) 10))
    (ok (= (evaluate '(if (quote t) 1 2)) 1)))

  (testing "nil predicate takes alternative"
    (ok (= (evaluate '(if (quote ()) 10 20)) 20))
    (ok (= (evaluate '(if (> 1 2) 10 20)) 20)))

  (testing "omitted alternative returns nil"
    (ok (equal (evaluate '(if (quote ()) 42)) nil))
    (ok (= (evaluate '(if 1 42)) 42)))

  (testing "computed subexpressions and nested if"
    (ok (= (evaluate '(if (= (+ 1 1) 2) (* 3 4) (- 5 1))) 12))
    (ok (= (evaluate '(if (< 1 2) (if (< 2 3) 100 200) 300)) 100))))

(deftest test-callcc-eval
  (testing "simple call/cc returns receiver's value"
    (ok (= (evaluate '(ece::call/cc (lambda (k) 42))) 42)))

  (testing "continuation used for non-local exit"
    (ok (= (evaluate '(ece::call/cc (lambda (k) (k 10) 20))) 10)))

  (testing "call/cc in arithmetic expression"
    (ok (= (evaluate '(+ 1 (ece::call/cc (lambda (k) (k 10))))) 11)))

  (testing "nested non-local exit abandons inner computation"
    (ok (= (evaluate '(+ 1 (ece::call/cc (lambda (k) (+ 2 (k 10)))))) 11)))

  (testing "variable as receiver"
    (ok (= (evaluate '((lambda (f) (ece::call/cc f)) (lambda (k) (k 99)))) 99)))

  (testing "continuation ignored returns receiver result"
    (ok (= (evaluate '(+ 1 (ece::call/cc (lambda (k) 5)))) 6))))

(deftest test-tail-call-optimization
  (testing "deep tail recursion does not blow the stack"
    (ok (= (evaluate '((lambda (loop)
                          (loop loop 1000000))
                        (lambda (self n)
                          (if (= n 0)
                            0
                            (self self (- n 1))))))
           0))))

(deftest test-unknown-expression-error
  (testing "unrecognized expression types signal an error"
    (signals (evaluate (make-hash-table) nil))))
