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
    (ok (= (evaluate 'x (list (cons '(x y) '(5 10)))) 5))
    (ok (= (evaluate 'y (list (cons '(x y) '(5 10)))) 10))
    (ok (= (evaluate 'z (list (cons '(x y z) '(5 10 -3)))) -3)))

  (testing "unbound variables signal an error"
    (signals (evaluate 'a (list (cons '(b c) '(2 3)))))
    (signals (evaluate 'foo nil))))


(deftest test-quote-eval
  (testing "quote special form returns the quoted expression without evaluating it"
    (ok (equal (evaluate '(quote a) nil) 'a))
    (ok (equal (evaluate '(quote (1 2 3)) nil) '(1 2 3)))
    (ok (equal (evaluate '(quote (x y z)) (list (cons '(x y z) '(10 20 30)))) '(x y z)))))


(deftest test-lambda-eval
  (testing "lambda expressions evaluate correctly with given arguments"
    (ok (= (evaluate '((lambda (x) (+ x 1)) 5)) 6))
    (ok (= (evaluate '((lambda (x y) (* x y)) 3 4)) 12))
    (ok (= (evaluate '((lambda (a b c) (- a b c)) 10 3 2)) 5)))

  (testing "lambda expressions with variable bindings"
    (ok (= (evaluate '((lambda (x) (+ x y)) 5) (cons (cons '(y) '(10))
                                                      *global-env*)) 15))
    (ok (= (evaluate '((lambda (a b) (+ a b)) b 2) (cons (cons '(b) '(8))
                                                          *global-env*)) 10))))

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

(deftest test-define-eval
  (testing "simple value binding"
    (ok (= (evaluate '(begin (ece::define x 42) x)) 42)))

  (testing "expression value binding"
    (ok (= (evaluate '(begin (ece::define y (+ 1 2)) y)) 3)))

  (testing "define returns the value"
    (ok (= (evaluate '(ece::define z 10)) 10)))

  (testing "function shorthand"
    (ok (= (evaluate '(begin (ece::define (square x) (* x x))
                             (square 5))) 25)))

  (testing "function shorthand with multiple parameters"
    (ok (= (evaluate '(begin (ece::define (add a b) (+ a b))
                             (add 3 4))) 7)))

  (testing "function shorthand with multi-body"
    (ok (= (evaluate '(begin (ece::define (f x) (+ x 1) (+ x 2))
                             (f 10))) 12)))

  (testing "redefine a variable"
    (ok (= (evaluate '(begin (ece::define a 1)
                             (ece::define a 2)
                             a)) 2)))

  (testing "named recursion"
    (ok (= (evaluate '(begin (ece::define (countdown n)
                               (if (= n 0) 0 (countdown (- n 1))))
                             (countdown 10))) 0)))

  (testing "tail-recursive define does not blow the stack"
    (ok (= (evaluate '(begin (ece::define (countdown n)
                               (if (= n 0) 0 (countdown (- n 1))))
                             (countdown 100000))) 0))))

(deftest test-io-primitives
  (testing "print is bound"
    (ok (eq (car (evaluate 'print)) 'ece::primitive)))

  (testing "read is bound"
    (ok (eq (car (evaluate 'read)) 'ece::primitive)))

  (testing "display is bound"
    (ok (eq (car (evaluate 'ece::display)) 'ece::primitive)))

  (testing "newline is bound"
    (ok (eq (car (evaluate 'ece::newline)) 'ece::primitive)))

  (testing "eof? is bound"
    (ok (eq (car (evaluate 'ece::eof?)) 'ece::primitive)))

  (testing "display outputs without leading newline"
    (ok (equal (with-output-to-string (*standard-output*)
                (evaluate '(ece::display "hello")))
              "hello")))

  (testing "print outputs value"
    (let ((output (with-output-to-string (*standard-output*)
                    (evaluate '(print 42)))))
      (ok (search "42" output)))))

(deftest test-unknown-expression-error
  (testing "unrecognized expression types signal an error"
    (signals (evaluate (make-hash-table) nil))))
