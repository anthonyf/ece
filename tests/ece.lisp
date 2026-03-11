(defpackage ece/tests/main
  (:use :cl
        :ece
        :rove))
(in-package :ece/tests/main)

;; Limit print depth to prevent stack overflow when rove tries to print
;; test results containing deeply nested captured environments/continuations.
(setf *print-circle* t *print-level* 10 *print-length* 10)

(defun ece-eval-string (source)
  "Read SOURCE with the ECE readtable, then evaluate the result."
  (let* ((*readtable* ece::*ece-readtable*)
         (*package* (find-package :ece))
         (expr (read-from-string source)))
    (evaluate expr)))

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

(deftest test-char-ops
    (testing "character literal self-evaluates"
             (ok (char= (evaluate #\a) #\a))
             (ok (char= (evaluate #\space) #\space)))

  (testing "char? predicate"
           (ok (evaluate '(char? #\a)))
           (ok (not (evaluate '(char? 42))))
           (ok (not (evaluate '(char? "a")))))

  (testing "char=? equality"
           (ok (evaluate '(char=? #\a #\a)))
           (ok (not (evaluate '(char=? #\a #\b)))))

  (testing "char<? ordering"
           (ok (evaluate '(char<? #\a #\b)))
           (ok (not (evaluate '(char<? #\b #\a)))))

  (testing "char->integer"
           (ok (= (evaluate '(char->integer #\a)) 97)))

  (testing "integer->char"
           (ok (char= (evaluate '(integer->char 97)) #\a)))

  (testing "round-trip conversion"
           (ok (evaluate '(char=? (integer->char (char->integer #\z)) #\z)))))

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
           (ok (evaluate '(null? (quote ()))))
           (ok (not (evaluate '(null? (quote (1))))))
           (ok (evaluate '(not (quote ())))))

  (testing "reverse"
           (ok (equal (evaluate '(reverse (quote (1 2 3)))) '(3 2 1)))
           (ok (equal (evaluate '(reverse (quote ()))) '()))
           (ok (equal (evaluate '(reverse (quote (42)))) '(42)))))

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
             (ok (= (evaluate '(call/cc (lambda (k) 42))) 42)))

  (testing "continuation used for non-local exit"
           (ok (= (evaluate '(call/cc (lambda (k) (k 10) 20))) 10)))

  (testing "call/cc in arithmetic expression"
           (ok (= (evaluate '(+ 1 (call/cc (lambda (k) (k 10))))) 11)))

  (testing "nested non-local exit abandons inner computation"
           (ok (= (evaluate '(+ 1 (call/cc (lambda (k) (+ 2 (k 10)))))) 11)))

  (testing "variable as receiver"
           (ok (= (evaluate '((lambda (f) (call/cc f)) (lambda (k) (k 99)))) 99)))

  (testing "continuation ignored returns receiver result"
           (ok (= (evaluate '(+ 1 (call/cc (lambda (k) 5)))) 6))))

(deftest test-tail-call-optimization
    (testing "deep tail recursion does not blow the stack"
             (ok (= (evaluate '((lambda (loop)
                                  (loop loop 1000000))
                                (lambda (self n)
                                  (if (= n 0)
                                      0
                                      (self self (- n 1))))))
                    0)))

  (testing "tail call in if consequent/alternative"
           (ok (eq (evaluate '(begin (define (tco-if n)
                                      (if (= n 0) (quote done) (tco-if (- n 1))))
                               (tco-if 1000000)))
                   'done)))

  (testing "tail call in begin last expression"
           (ok (eq (evaluate '(begin (define (tco-begin n)
                                      (if (= n 0) (quote done)
                                          (begin (quote ignore) (tco-begin (- n 1)))))
                               (tco-begin 1000000)))
                   'done)))

  (testing "tail call in cond clause body"
           (ok (eq (evaluate '(begin (define (tco-cond n)
                                      (cond ((= n 0) (quote done))
                                            ((quote t) (tco-cond (- n 1)))))
                               (tco-cond 1000000)))
                   'done)))

  (testing "tail call as last argument of and"
           (ok (eq (evaluate '(begin (define (tco-and n)
                                      (if (= n 0) (quote done)
                                          (and (quote t) (tco-and (- n 1)))))
                               (tco-and 1000000)))
                   'done)))

  (testing "tail call as last argument of or"
           (ok (eq (evaluate '(begin (define (tco-or n)
                                      (if (= n 0) (quote done)
                                          (or (quote ()) (tco-or (- n 1)))))
                               (tco-or 1000000)))
                   'done)))

  (testing "tail call in when body"
           (ok (null (evaluate '(begin (define (tco-when n)
                                        (when (> n 0) (tco-when (- n 1))))
                                 (tco-when 1000000))))))

  (testing "tail call in unless body"
           (ok (null (evaluate '(begin (define (tco-unless n)
                                        (unless (= n 0) (tco-unless (- n 1))))
                                 (tco-unless 1000000))))))

  (testing "tail call in let body"
           (ok (eq (evaluate '(begin (define (tco-let n)
                                      (let ((m (- n 1)))
                                        (if (= m 0) (quote done) (tco-let m))))
                               (tco-let 1000000)))
                   'done)))

  (testing "tail call in let* body"
           (ok (eq (evaluate '(begin (define (tco-let* n)
                                      (let* ((m (- n 1)) (k m))
                                        (if (= k 0) (quote done) (tco-let* k))))
                               (tco-let* 1000000)))
                   'done)))

  (testing "tail call via apply"
           (ok (eq (evaluate '(begin (define (tco-apply n)
                                      (if (= n 0) (quote done)
                                          (apply tco-apply (list (- n 1)))))
                               (tco-apply 1000000)))
                   'done))))

(deftest test-define-eval
    (testing "simple value binding"
             (ok (= (evaluate '(begin (define x 42) x)) 42)))

  (testing "expression value binding"
           (ok (= (evaluate '(begin (define y (+ 1 2)) y)) 3)))

  (testing "define returns the value"
           (ok (= (evaluate '(define z 10)) 10)))

  (testing "function shorthand"
           (ok (= (evaluate '(begin (define (square x) (* x x))
                              (square 5))) 25)))

  (testing "function shorthand with multiple parameters"
           (ok (= (evaluate '(begin (define (add a b) (+ a b))
                              (add 3 4))) 7)))

  (testing "function shorthand with multi-body"
           (ok (= (evaluate '(begin (define (f x) (+ x 1) (+ x 2))
                              (f 10))) 12)))

  (testing "redefine a variable"
           (ok (= (evaluate '(begin (define a 1)
                              (define a 2)
                              a)) 2)))

  (testing "named recursion"
           (ok (= (evaluate '(begin (define (countdown n)
                                     (if (= n 0) 0 (countdown (- n 1))))
                              (countdown 10))) 0)))

  (testing "tail-recursive define does not blow the stack"
           (ok (= (evaluate '(begin (define (countdown n)
                                     (if (= n 0) 0 (countdown (- n 1))))
                              (countdown 100000))) 0))))

(deftest test-set-eval
    (testing "update a defined variable"
             (ok (= (evaluate '(begin (define x 1) (set x 2) x)) 2)))

  (testing "update with a computed value"
           (ok (= (evaluate '(begin (define x 1) (set x (+ x 10)) x)) 11)))

  (testing "set returns the new value"
           (ok (= (evaluate '(begin (define x 1) (set x 42))) 42)))

  (testing "unbound variable signals error"
           (signals (evaluate '(set nonexistent 10))))

  (testing "update variable in enclosing scope"
           (ok (= (evaluate '(begin (define x 1)
                              (define (f) (set x 99))
                              (f)
                              x)) 99)))

  (testing "closure mutation counter pattern"
           (ok (= (evaluate '(begin
                              (define counter 0)
                              (define (inc) (set counter (+ counter 1)))
                              (inc)
                              (inc)
                              (inc)
                              counter)) 3))))

(deftest test-rest-params
    (testing "rest parameter captures extra arguments"
             (ok (equal (evaluate '((lambda (x . rest) rest) 1 2 3)) '(2 3))))

  (testing "rest parameter with no extra arguments"
           (ok (equal (evaluate '((lambda (x . rest) rest) 1)) nil)))

  (testing "rest parameter with fixed and rest args"
           (ok (equal (evaluate '((lambda (x y . rest) (list x y rest)) 1 2 3 4))
                      '(1 2 (3 4)))))

  (testing "rest-only parameter (symbol instead of list)"
           (ok (equal (evaluate '((lambda args args) 1 2 3)) '(1 2 3)))))

(deftest test-rest-params-define
    (testing "define with rest parameter"
             (ok (equal (evaluate '(begin (define (f x . rest) rest) (f 1 2 3)))
                        '(2 3))))

  (testing "define rest-only"
           (ok (equal (evaluate '(begin (define (f . args) args) (f 1 2 3)))
                      '(1 2 3)))))

(deftest test-list-access-primitives
    (testing "cadr returns second element"
             (ok (= (evaluate '(cadr (quote (1 2 3)))) 2)))

  (testing "caddr returns third element"
           (ok (= (evaluate '(caddr (quote (1 2 3)))) 3)))

  (testing "caar returns car of car"
           (ok (eq (evaluate '(caar (quote ((a b) c)))) 'a)))

  (testing "cddr returns cdr of cdr"
           (ok (equal (evaluate '(cddr (quote (1 2 3)))) '(3)))))

(deftest test-append-length-pair
    (testing "append two lists"
             (ok (equal (evaluate '(append (quote (1 2)) (quote (3 4)))) '(1 2 3 4))))

  (testing "append empty list"
           (ok (equal (evaluate '(append (quote ()) (quote (1 2)))) '(1 2))))

  (testing "length of a list"
           (ok (= (evaluate '(length (quote (a b c)))) 3)))

  (testing "length of empty list"
           (ok (= (evaluate '(length (quote ()))) 0)))

  (testing "pair? on cons cell"
           (ok (evaluate '(pair? (cons 1 2)))))

  (testing "pair? on number"
           (ok (not (evaluate '(pair? 42)))))

  (testing "pair? on empty list"
           (ok (not (evaluate '(pair? (quote ())))))))

(deftest test-map
    (testing "map with lambda"
             (ok (equal (evaluate '(map (lambda (x) (+ x 1)) (quote (1 2 3)))) '(2 3 4))))

  (testing "map with primitive"
           (ok (equal (evaluate '(map car (quote ((1 2) (3 4) (5 6))))) '(1 3 5))))

  (testing "map over empty list"
           (ok (equal (evaluate '(map (lambda (x) x) (quote ()))) nil)))

  (testing "map large list without stack overflow"
           (ok (= (evaluate '(begin
                              (define (make-list n)
                               (let loop ((i 0) (acc (quote ())))
                                    (if (= i n) acc (loop (+ i 1) (cons i acc)))))
                              (car (map (lambda (x) (+ x 1)) (make-list 10000)))))
                  10000))))

(deftest test-apply-special-form
    (testing "apply primitive with argument list"
             (ok (= (evaluate '(apply + (quote (1 2 3)))) 6)))

  (testing "apply lambda with argument list"
           (ok (= (evaluate '(apply (lambda (x y) (+ x y)) (quote (3 4)))) 7)))

  (testing "apply named ECE function"
           (ok (= (evaluate '(begin (define (add a b) (+ a b))
                              (apply add (quote (10 20))))) 30))))

(deftest test-io-primitives
    (testing "print is bound"
             (ok (eq (car (evaluate 'print)) 'primitive)))

  (testing "read is bound (ECE reader)"
           (ok (eq (car (evaluate 'read)) 'ece::compiled-procedure)))

  (testing "display is bound"
           (ok (eq (car (evaluate 'display)) 'primitive)))

  (testing "newline is bound"
           (ok (eq (car (evaluate 'newline)) 'primitive)))

  (testing "eof? is bound"
           (ok (eq (car (evaluate 'eof?)) 'primitive)))

  (testing "display outputs without leading newline"
           (ok (equal (with-output-to-string (*standard-output*)
                        (evaluate '(display "hello")))
                      "hello")))

  (testing "print outputs value"
           (let ((output (with-output-to-string (*standard-output*)
                           (evaluate '(print 42)))))
             (ok (search "42" output)))))

(deftest test-define-macro
    (testing "simple macro definition and expansion"
             (ok (eq (evaluate '(begin (define-macro (my-const name) (list (quote quote) name))
                                 (my-const hello)))
                     'hello)))

  (testing "macro receives unevaluated operands"
           (ok (= (evaluate '(begin (define-macro (identity-macro expr) expr)
                              (identity-macro (+ 1 2))))
                  3)))

  (testing "macro with multiple body expressions"
           (ok (= (evaluate '(begin (define-macro (last-of a b) b)
                              (last-of (error "never") (+ 10 20))))
                  30))))

(deftest test-cond
    (testing "first true clause"
             (ok (= (evaluate '(cond ((= 1 1) 10) ((= 2 3) 20))) 10)))

  (testing "second clause matches"
           (ok (= (evaluate '(cond ((= 1 2) 10) ((= 2 2) 20))) 20)))

  (testing "no clause matches returns nil"
           (ok (null (evaluate '(cond ((= 1 2) 10) ((= 3 4) 20))))))

  (testing "multi-expression clause body"
           (ok (= (evaluate '(begin (define x 0)
                              (cond ((= 1 1) (set x 10) (+ x 5)))
                              x))
                  10)))

  (testing "else clause as catch-all"
           (ok (= (evaluate '(cond ((= 1 2) 10) (else 99))) 99)))

  (testing "t clause as catch-all"
           (ok (= (evaluate '(cond ((= 1 2) 10) (t 99))) 99))))

(deftest test-case
    (testing "match single datum"
             (ok (= (evaluate '(case (+ 1 1) ((1) 10) ((2) 20) ((3) 30))) 20)))

  (testing "match in datum list"
           (ok (eq (evaluate '(case 3 ((1 2) (quote low)) ((3 4) (quote high)))) 'high)))

  (testing "else clause"
           (ok (eq (evaluate '(case 99 ((1) (quote one)) (else (quote other)))) 'other)))

  (testing "no match returns nil"
           (ok (null (evaluate '(case 5 ((1) (quote one)) ((2) (quote two)))))))

  (testing "key expression evaluated once"
           (ok (= (evaluate '(begin (define counter 0)
                              (case (begin (set counter (+ counter 1)) counter)
                                ((1) (quote one))
                                ((2) (quote two)))
                              counter))
                  1)))

  (testing "match symbol datums"
           (ok (= (evaluate '(case (quote b) ((a) 1) ((b) 2) ((c) 3))) 2))))

(deftest test-do
    (testing "simple counting loop"
             (ok (= (evaluate '(do ((i 0 (+ i 1))) ((= i 5) i))) 5)))

  (testing "accumulating loop"
           (ok (= (evaluate '(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum))) 10)))

  (testing "loop with body for side effects"
           (ok (equal (evaluate '(begin (define result (quote ()))
                                  (do ((i 0 (+ i 1)))
                                      ((= i 3) result)
                                    (set result (cons i result)))))
                      '(2 1 0))))

  (testing "variable without step expression stays constant"
           (ok (= (evaluate '(do ((x 10) (i 0 (+ i 1))) ((= i 3) x))) 10)))

  (testing "immediate termination"
           (ok (eq (evaluate '(do ((i 0 (+ i 1))) ((= i 0) (quote done)))) 'done))))

(deftest test-let
    (testing "simple let binding"
             (ok (= (evaluate '(let ((x 10) (y 20)) (+ x y))) 30)))

  (testing "let bindings do not see each other"
           (ok (= (evaluate '(begin (define x 1) (let ((x 10) (y x)) y))) 1))))

(deftest test-named-let
    (testing "simple counting loop"
             (ok (= (evaluate '(let recur ((i 0) (sum 0))
                                (if (= i 5) sum (recur (+ i 1) (+ sum i)))))
                    10)))

  (testing "named let with tail recursion"
           (ok (eq (evaluate '(let recur ((n 1000000))
                               (if (= n 0) (quote done) (recur (- n 1)))))
                   'done)))

  (testing "building a list with named let"
           (ok (equal (evaluate '(let recur ((i 3) (acc (quote ())))
                                  (if (= i 0) acc (recur (- i 1) (cons i acc)))))
                      '(1 2 3))))

  (testing "regular let still works"
           (ok (= (evaluate '(let ((x 10) (y 20)) (+ x y))) 30))))

(deftest test-let*
    (testing "sequential bindings"
             (ok (= (evaluate '(let* ((x 10) (y (+ x 5))) y)) 15)))

  (testing "single binding"
           (ok (= (evaluate '(let* ((x 42)) x)) 42))))

(deftest test-letrec
    (testing "single recursive binding"
             (ok (= (evaluate '(letrec ((fact (lambda (n) (if (= n 0) 1 (* n (fact (- n 1)))))))
                                (fact 5)))
                    120)))

  (testing "mutually recursive bindings"
           (ok (eq (evaluate '(letrec ((even? (lambda (n) (if (= n 0) (quote t) (odd? (- n 1)))))
                                       (odd? (lambda (n) (if (= n 0) (quote ()) (even? (- n 1))))))
                               (even? 10)))
                   't)))

  (testing "mutually recursive bindings (odd case)"
           (ok (eq (evaluate '(letrec ((even? (lambda (n) (if (= n 0) (quote t) (odd? (- n 1)))))
                                       (odd? (lambda (n) (if (= n 0) (quote ()) (even? (- n 1))))))
                               (odd? 7)))
                   't)))

  (testing "body in tail position"
           (ok (eq (evaluate '(letrec ((loop (lambda (n) (if (= n 0) (quote done) (loop (- n 1))))))
                               (loop 1000000)))
                   'done))))

(deftest test-and
    (testing "all truthy"
             (ok (= (evaluate '(and 1 2 3)) 3)))

  (testing "short-circuit on false"
           (ok (null (evaluate '(and 1 (quote ()) 3)))))

  (testing "empty and"
           (ok (evaluate '(and)))))

(deftest test-or
    (testing "first truthy"
             (ok (= (evaluate '(or (quote ()) 2 3)) 2)))

  (testing "all falsy"
           (ok (null (evaluate '(or (quote ()) (quote ()))))))

  (testing "empty or"
           (ok (null (evaluate '(or))))))

(deftest test-when-unless
    (testing "when with truthy test evaluates body"
             (ok (= (evaluate '(when (= 1 1) 42)) 42)))

  (testing "when with falsy test returns nil"
           (ok (null (evaluate '(when (= 1 2) 42)))))

  (testing "unless with falsy test evaluates body"
           (ok (= (evaluate '(unless (= 1 2) 42)) 42)))

  (testing "unless with truthy test returns nil"
           (ok (null (evaluate '(unless (= 1 1) 42))))))

(deftest test-quasiquote
    (testing "all-literal template"
             (ok (equal (evaluate '(quasiquote (a b c))) '(a b c))))

  (testing "atomic template"
           (ok (eq (evaluate '(quasiquote hello)) 'hello))))

(deftest test-unquote
    (testing "unquote a variable"
             (ok (equal (evaluate '(begin (define x 42) (quasiquote (a (unquote x) c))))
                        '(a 42 c))))

  (testing "unquote an expression"
           (ok (equal (evaluate '(quasiquote (result (unquote (+ 1 2)))))
                      '(result 3))))

  (testing "unquote in tail position"
           (ok (equal (evaluate '(begin (define xs (quote (1 2 3)))
                                  (quasiquote (prefix (unquote xs)))))
                      '(prefix (1 2 3))))))

(deftest test-unquote-splicing
    (testing "splice a list"
             (ok (equal (evaluate '(begin (define xs (quote (1 2 3)))
                                    (quasiquote (a (unquote-splicing xs) d))))
                        '(a 1 2 3 d))))

  (testing "splice an empty list"
           (ok (equal (evaluate '(begin (define xs (quote ()))
                                  (quasiquote (a (unquote-splicing xs) b))))
                      '(a b)))))

(deftest test-quasiquote-in-macro
    (testing "macro using quasiquote"
             (ok (= (evaluate '(begin (define-macro (my-if test then)
                                       (quasiquote (if (unquote test) (unquote then))))
                                (my-if (= 1 1) 42)))
                    42))))

(deftest test-nested-quasiquote
    (testing "inner unquote preserved at depth 2"
             (ok (equal (evaluate '(begin (define x 1)
                                    (quasiquote (a (quasiquote (b (unquote x)))))))
                        '(a (quasiquote (b (unquote x)))))))

  (testing "outer unquote evaluated, inner preserved"
           (ok (equal (evaluate '(begin (define x 1)
                                  (quasiquote (a (unquote x) (quasiquote (b (unquote x)))))))
                      '(a 1 (quasiquote (b (unquote x)))))))

  (testing "nested unquote-splicing preserved at depth 2"
           (ok (equal (evaluate '(begin (define xs (quote (1 2)))
                                  (quasiquote (a (quasiquote (b (unquote-splicing xs)))))))
                      '(a (quasiquote (b (unquote-splicing xs))))))))

(deftest test-type-predicates
    (testing "number?"
             (ok (evaluate '(number? 42)))
             (ok (not (evaluate '(number? "hello")))))

  (testing "string?"
           (ok (evaluate '(string? "hello")))
           (ok (not (evaluate '(string? 42)))))

  (testing "symbol?"
           (ok (evaluate '(symbol? (quote foo))))
           (ok (not (evaluate '(symbol? 42)))))

  (testing "boolean?"
           (ok (evaluate '(boolean? t)))
           (ok (evaluate '(boolean? (quote ()))))
           (ok (not (evaluate '(boolean? 42)))))

  (testing "zero?"
           (ok (evaluate '(zero? 0)))
           (ok (not (evaluate '(zero? 5))))))

(deftest test-equality
    (testing "eq? on same symbol"
             (ok (evaluate '(eq? (quote a) (quote a)))))

  (testing "eq? on different symbols"
           (ok (not (evaluate '(eq? (quote a) (quote b))))))

  (testing "equal? on identical lists"
           (ok (evaluate '(equal? (quote (1 2 3)) (quote (1 2 3))))))

  (testing "equal? on different lists"
           (ok (not (evaluate '(equal? (quote (1 2)) (quote (1 3)))))))

  (testing "equal? on strings"
           (ok (evaluate '(equal? "hello" "hello")))))

(deftest test-numeric-utilities
    (testing "modulo"
             (ok (= (evaluate '(modulo 10 3)) 1)))

  (testing "abs"
           (ok (= (evaluate '(abs -5)) 5)))

  (testing "min"
           (ok (= (evaluate '(min 3 1 4 1 5)) 1)))

  (testing "max"
           (ok (= (evaluate '(max 3 1 4 1 5)) 5)))

  (testing "even?"
           (ok (evaluate '(even? 4)))
           (ok (not (evaluate '(even? 3)))))

  (testing "odd?"
           (ok (evaluate '(odd? 3))))

  (testing "positive?"
           (ok (evaluate '(positive? 5)))
           (ok (not (evaluate '(positive? -1)))))

  (testing "negative?"
           (ok (evaluate '(negative? -1)))))

(deftest test-filter
    (testing "filter even numbers"
             (ok (equal (evaluate '(filter even? (quote (1 2 3 4 5 6)))) '(2 4 6))))

  (testing "filter with no matches"
           (ok (equal (evaluate '(filter even? (quote (1 3 5)))) '())))

  (testing "filter empty list"
           (ok (equal (evaluate '(filter even? (quote ()))) '())))

  (testing "filter with lambda"
           (ok (equal (evaluate '(filter (lambda (x) (> x 3)) (quote (1 2 3 4 5)))) '(4 5))))

  (testing "filter large list without stack overflow"
           (ok (= (evaluate '(begin
                              (define (make-list n)
                               (let loop ((i 0) (acc (quote ())))
                                    (if (= i n) acc (loop (+ i 1) (cons i acc)))))
                              (length (filter even? (make-list 10000)))))
                  5000))))

(deftest test-reduce
    (testing "reduce sum"
             (ok (= (evaluate '(reduce + 0 (quote (1 2 3 4 5)))) 15)))

  (testing "reduce with empty list"
           (ok (= (evaluate '(reduce + 0 (quote ()))) 0)))

  (testing "reduce building a reversed list"
           (ok (equal (evaluate '(reduce (lambda (acc x) (cons x acc)) (quote ()) (quote (1 2 3)))) '(3 2 1)))))

(deftest test-for-each
    (testing "for-each returns nil"
             (ok (equal (evaluate '(for-each (lambda (x) x) (quote (1 2 3)))) '()))))

(deftest test-gensym
    (testing "gensym returns a symbol"
             (ok (evaluate '(symbol? (gensym)))))

  (testing "gensym returns unique symbols"
           (ok (not (evaluate '(eq? (gensym) (gensym)))))))

(deftest test-or-no-double-eval
    (testing "or does not double-evaluate truthy argument"
             (ok (= (evaluate '(begin (define counter 0)
                                (or (begin (set counter (+ counter 1)) counter) 99)
                                counter))
                    1))))

(deftest test-string-ops
    (testing "string-length"
             (ok (= (evaluate '(string-length "hello")) 5))
             (ok (= (evaluate '(string-length "")) 0)))

  (testing "string-ref"
           (ok (char= (evaluate '(string-ref "hello" 0)) #\h))
           (ok (char= (evaluate '(string-ref "hello" 4)) #\o)))

  (testing "string-append"
           (ok (equal (evaluate '(string-append "hello" " world")) "hello world"))
           (ok (equal (evaluate '(string-append "a" "b" "c")) "abc"))
           (ok (equal (evaluate '(string-append "" "hello")) "hello")))

  (testing "substring"
           (ok (equal (evaluate '(substring "hello world" 0 5)) "hello"))
           (ok (equal (evaluate '(substring "hello world" 6 11)) "world")))

  (testing "string->number"
           (ok (= (evaluate '(string->number "42")) 42))
           (ok (= (evaluate '(string->number "-7")) -7))
           (ok (null (evaluate '(string->number "abc"))))
           (ok (= (evaluate '(string->number "3.14")) 3.14))
           (ok (= (evaluate '(string->number "-0.5")) -0.5))
           (ok (null (evaluate '(string->number "3/4"))))
           (ok (null (evaluate '(string->number ""))))
           (ok (null (evaluate '(string->number "  ")))))

  (testing "number->string"
           (ok (equal (evaluate '(number->string 42)) "42"))
           (ok (equal (evaluate '(number->string -7)) "-7")))

  (testing "string->symbol"
           (ok (eq (evaluate '(string->symbol "hello")) 'hello)))

  (testing "symbol->string"
           (ok (equal (evaluate '(symbol->string (quote hello))) "hello")))

  (testing "symbol round-trip"
           (ok (evaluate '(equal? (string->symbol (symbol->string (quote foo))) (quote foo))))))

(deftest test-error-signaling
    (testing "error signals a condition"
             (signals (evaluate '(error "something went wrong"))))

  (testing "error is catchable"
           (ok (null (handler-case (evaluate '(error "oops"))
                       (error () nil))))))

(deftest test-assoc-member
    (testing "assoc finds key"
             (ok (equal (evaluate '(assoc (quote b) (quote ((a 1) (b 2) (c 3))))) '(b 2))))

  (testing "assoc key not found"
           (ok (null (evaluate '(assoc (quote d) (quote ((a 1) (b 2) (c 3))))))))

  (testing "assoc with numeric key"
           (ok (equal (evaluate '(assoc 2 (quote ((1 a) (2 b) (3 c))))) '(2 b))))

  (testing "member element found"
           (ok (equal (evaluate '(member 3 (quote (1 2 3 4 5)))) '(3 4 5))))

  (testing "member element not found"
           (ok (null (evaluate '(member 6 (quote (1 2 3 4 5)))))))

  (testing "member with symbol"
           (ok (equal (evaluate '(member (quote c) (quote (a b c d)))) '(c d)))))

(deftest test-list-indexing
    (testing "list-ref first element"
             (ok (eq (evaluate '(list-ref (quote (a b c d)) 0)) 'a)))

  (testing "list-ref third element"
           (ok (eq (evaluate '(list-ref (quote (a b c d)) 2)) 'c)))

  (testing "list-ref last element"
           (ok (eq (evaluate '(list-ref (quote (a b c d)) 3)) 'd)))

  (testing "list-tail from index 0"
           (ok (equal (evaluate '(list-tail (quote (a b c d)) 0)) '(a b c d))))

  (testing "list-tail from index 2"
           (ok (equal (evaluate '(list-tail (quote (a b c d)) 2)) '(c d))))

  (testing "list-tail at end"
           (ok (null (evaluate '(list-tail (quote (a b c d)) 4))))))

(deftest test-string-comparisons
    (testing "string=? equal"
             (ok (evaluate '(string=? "hello" "hello"))))

  (testing "string=? unequal"
           (ok (not (evaluate '(string=? "hello" "world")))))

  (testing "string<? less than"
           (ok (evaluate '(string<? "abc" "abd"))))

  (testing "string<? not less than"
           (ok (not (evaluate '(string<? "abd" "abc")))))

  (testing "string>? greater than"
           (ok (evaluate '(string>? "abd" "abc"))))

  (testing "string>? not greater than"
           (ok (not (evaluate '(string>? "abc" "abd"))))))

(deftest test-vector-ops
    (testing "vector literal self-evaluates"
             (ok (equalp (evaluate #(1 2 3)) #(1 2 3))))

  (testing "vector? predicate"
           (ok (evaluate '(vector? #(1 2 3))))
           (ok (not (evaluate '(vector? (quote (1 2 3))))))
           (ok (not (evaluate '(vector? "hello")))))

  (testing "make-vector"
           (ok (= (evaluate '(vector-length (make-vector 5))) 5))
           (ok (= (evaluate '(vector-ref (make-vector 3 42) 0)) 42)))

  (testing "vector constructor"
           (ok (equalp (evaluate '(vector 1 2 3)) #(1 2 3))))

  (testing "vector-length"
           (ok (= (evaluate '(vector-length #(1 2 3))) 3))
           (ok (= (evaluate '(vector-length #())) 0)))

  (testing "vector-ref"
           (ok (= (evaluate '(vector-ref #(10 20 30) 0)) 10))
           (ok (= (evaluate '(vector-ref #(10 20 30) 2)) 30)))

  (testing "vector-set!"
           (ok (= (evaluate '(begin (define v (make-vector 3 0))
                              (vector-set! v 1 42)
                              (vector-ref v 1)))
                  42))
           (ok (equalp (evaluate '(begin (define v (vector 1 2 3))
                                   (vector-set! v 0 99)
                                   v))
                       #(99 2 3))))

  (testing "vector->list"
           (ok (equal (evaluate '(vector->list #(1 2 3))) '(1 2 3))))

  (testing "list->vector"
           (ok (equalp (evaluate '(list->vector (quote (1 2 3)))) #(1 2 3)))))

(deftest test-load
    (testing "load file with definitions"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "scm")
                              (write-string "(define load-test-x 42)" s)
                              (terpri s)
                              (write-string "(define load-test-y (+ load-test-x 1))" s)
                              p)))
               (unwind-protect
                    (progn
                      (evaluate `(load ,(namestring tmpfile)))
                      (ok (= (evaluate (intern "LOAD-TEST-X" :ece)) 42))
                      (ok (= (evaluate (intern "LOAD-TEST-Y" :ece)) 43)))
                 (delete-file tmpfile))))

  (testing "load returns last value"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "scm")
                            (write-string "(+ 1 2)" s)
                            p)))
             (unwind-protect
                  (ok (= (evaluate `(load ,(namestring tmpfile))) 3))
               (delete-file tmpfile))))

  (testing "load empty file"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "scm")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (ok (null (evaluate `(load ,(namestring tmpfile)))))
               (delete-file tmpfile)))))

(deftest test-write-to-string
    (testing "number to string"
             (ok (equal (evaluate '(write-to-string 42)) "42")))

  (testing "symbol to string"
           (ok (equal (evaluate '(write-to-string (quote hello))) "HELLO")))

  (testing "string passes through"
           (ok (equal (evaluate '(write-to-string "hello")) "hello")))

  (testing "boolean to string"
           (ok (equal (evaluate '(write-to-string t)) "T")))

  (testing "list to string"
           (ok (equal (evaluate '(write-to-string (quote (1 2 3)))) "(1 2 3)")))

  (testing "empty list to string"
           (ok (equal (evaluate '(write-to-string (quote ()))) "NIL"))))

(deftest test-bitwise-ops
    (testing "bitwise-and"
             (ok (= (evaluate '(bitwise-and 12 10)) 8))
             (ok (= (evaluate '(bitwise-and 255 0)) 0)))

  (testing "bitwise-or"
           (ok (= (evaluate '(bitwise-or 12 10)) 14))
           (ok (= (evaluate '(bitwise-or 0 5)) 5)))

  (testing "bitwise-xor"
           (ok (= (evaluate '(bitwise-xor 12 10)) 6))
           (ok (= (evaluate '(bitwise-xor 42 42)) 0)))

  (testing "bitwise-not"
           (ok (= (evaluate '(bitwise-not 0)) -1))
           (ok (= (evaluate '(bitwise-not 255)) -256)))

  (testing "arithmetic-shift left"
           (ok (= (evaluate '(arithmetic-shift 1 8)) 256)))

  (testing "arithmetic-shift right"
           (ok (= (evaluate '(arithmetic-shift 256 -4)) 16)))

  (testing "arithmetic-shift by zero"
           (ok (= (evaluate '(arithmetic-shift 42 0)) 42))))

(deftest test-xorshift-random
    (testing "random is within range"
             (ok (let ((val (evaluate '(random 6))))
                   (and (>= val 0) (< val 6)))))

  (testing "random with small range"
           (ok (= (evaluate '(random 1)) 0)))

  (testing "same seed produces same sequence"
           (ok (equal (evaluate '(begin
                                  (random-seed! 42)
                                  (list (random 100) (random 100) (random 100))))
                      (evaluate '(begin
                                  (random-seed! 42)
                                  (list (random 100) (random 100) (random 100)))))))

  (testing "random-state is a number"
           (ok (evaluate '(number? *random-state*))))

  (testing "random-state changes after random call"
           (ok (evaluate '(begin
                           (random-seed! 999)
                           (let ((before *random-state*))
                             (random 10)
                             (not (= before *random-state*))))))))

(deftest test-fmt-macro
    (testing "concatenate strings"
             (ok (equal (evaluate '(fmt "hello" " " "world")) "hello world")))

  (testing "mix strings and numbers"
           (ok (equal (evaluate '(fmt "You have " 5 " gold")) "You have 5 gold")))

  (testing "single string argument"
           (ok (equal (evaluate '(fmt "hello")) "hello")))

  (testing "number argument"
           (ok (equal (evaluate '(fmt 42)) "42")))

  (testing "print-text displays formatted text"
           (ok (equal (with-output-to-string (*standard-output*)
                        (evaluate '(print-text "You have " 5 " gold")))
                      "You have 5 gold"))))

(deftest test-hash-table-literals
    (testing "curly brace reader produces hash table"
             (let ((*readtable* ece::*ece-readtable*))
               (ok (equal (read-from-string "{}")
                          '(:hash-table)))))

  (testing "curly brace reader with symbol keys"
           (let* ((*readtable* ece::*ece-readtable*)
                  (*package* (find-package :ece))
                  (result (read-from-string "{name \"Alice\" age 30}")))
             (ok (eq (car result) :hash-table))
             (ok (= (length (cdr result)) 2))
             (ok (equal (cdr (assoc (intern "NAME" :ece) (cdr result))) "Alice"))
             (ok (= (cdr (assoc (intern "AGE" :ece) (cdr result))) 30))))

  (testing "hash table is self-evaluating"
           (ok (equal (evaluate '(:hash-table (name . "Alice")))
                      '(:hash-table (name . "Alice")))))

  (testing "hash table stored in variable"
           (ok (equal (evaluate '(begin
                                  (define ht (hash-table 'a 1))
                                  ht))
                      '(:hash-table (a . 1)))))

  (testing "serialization round-trip"
           (let* ((*package* (find-package :ece))
                  (ht (list :hash-table (cons (intern "NAME" :ece) "Alice") (cons (intern "AGE" :ece) 30)))
                  (str (prin1-to-string ht))
                  (result (let ((*readtable* ece::*ece-readtable*))
                            (read-from-string str))))
             (ok (equal result ht)))))

(deftest test-hash-table-ops
    (testing "hash-table constructor with symbol keys"
             (ok (equal (evaluate '(hash-table 'a 1 'b 2))
                        '(:hash-table (a . 1) (b . 2)))))

  (testing "hash-table constructor empty"
           (ok (equal (evaluate '(:hash-table))
                      '(:hash-table))))

  (testing "hash-table constructor with computed key"
           (ok (equal (evaluate '(begin (define k 'name)
                                  (hash-table k "Alice")))
                      '(:hash-table (name . "Alice")))))

  (testing "hash-table? predicate true"
           (ok (evaluate '(hash-table? (hash-table 'a 1)))))

  (testing "hash-table? predicate false for list"
           (ok (not (evaluate '(hash-table? '(1 2 3))))))

  (testing "hash-table? predicate false for number"
           (ok (not (evaluate '(hash-table? 42)))))

  (testing "hash-ref key found"
           (ok (equal (evaluate '(hash-ref (hash-table 'name "Alice" 'age 30) 'name))
                      "Alice")))

  (testing "hash-ref key not found returns nil"
           (ok (null (evaluate '(hash-ref (hash-table 'a 1) 'missing)))))

  (testing "hash-ref key not found with default"
           (ok (equal (evaluate '(hash-ref (hash-table 'a 1) 'missing "default"))
                      "default")))

  (testing "hash-ref with string key"
           (ok (equal (evaluate '(hash-ref (hash-table "first" "Alice") "first"))
                      "Alice")))

  (testing "hash-has-key? true"
           (ok (evaluate '(hash-has-key? (hash-table 'name "Alice") 'name))))

  (testing "hash-has-key? false"
           (ok (not (evaluate '(hash-has-key? (hash-table 'name "Alice") 'age)))))

  (testing "hash-keys returns all keys"
           (ok (equal (evaluate '(hash-keys (hash-table 'a 1 'b 2 'c 3)))
                      '(a b c))))

  (testing "hash-keys empty"
           (ok (null (evaluate '(hash-keys (hash-table))))))

  (testing "hash-count non-empty"
           (ok (= (evaluate '(hash-count (hash-table 'a 1 'b 2 'c 3))) 3)))

  (testing "hash-count empty"
           (ok (= (evaluate '(hash-count (hash-table))) 0))))

(deftest test-hash-table-mutation
    (testing "hash-set! updates existing key"
             (ok (= (evaluate '(begin
                                (define ht (hash-table 'hp 100))
                                (hash-set! ht 'hp 80)
                                (hash-ref ht 'hp)))
                    80)))

  (testing "hash-set! adds new key"
           (ok (= (evaluate '(begin
                              (define ht (hash-table 'hp 100))
                              (hash-set! ht 'mp 50)
                              (hash-ref ht 'mp)))
                  50)))

  (testing "hash-set! preserves other keys"
           (ok (= (evaluate '(begin
                              (define ht (hash-table 'hp 100))
                              (hash-set! ht 'mp 50)
                              (hash-ref ht 'hp)))
                  100)))

  (testing "hash-set! preserves identity"
           (ok (evaluate '(begin
                           (define ht (hash-table 'a 1))
                           (define ht2 ht)
                           (hash-set! ht 'a 2)
                           (= (hash-ref ht2 'a) 2)))))

  (testing "hash-set returns new table"
           (ok (= (evaluate '(begin
                              (define ht (hash-table 'hp 100))
                              (define ht2 (hash-set ht 'hp 80))
                              (hash-ref ht2 'hp)))
                  80)))

  (testing "hash-set does not modify original"
           (ok (= (evaluate '(begin
                              (define ht (hash-table 'hp 100))
                              (hash-set ht 'hp 80)
                              (hash-ref ht 'hp)))
                  100)))

  (testing "hash-set adds new key"
           (ok (= (evaluate '(begin
                              (define ht (hash-table 'hp 100))
                              (define ht2 (hash-set ht 'mp 50))
                              (hash-ref ht2 'mp)))
                  50)))

  (testing "hash-set original lacks new key"
           (ok (not (evaluate '(begin
                                (define ht (hash-table 'hp 100))
                                (hash-set ht 'mp 50)
                                (hash-has-key? ht 'mp))))))

  (testing "hash-remove! removes key"
           (ok (not (evaluate '(begin
                                (define ht (hash-table 'a 1 'b 2))
                                (hash-remove! ht 'a)
                                (hash-has-key? ht 'a))))))

  (testing "hash-remove! preserves other keys"
           (ok (evaluate '(begin
                           (define ht (hash-table 'a 1 'b 2))
                           (hash-remove! ht 'a)
                           (hash-has-key? ht 'b)))))

  (testing "hash-remove! non-existent key is no-op"
           (ok (= (evaluate '(begin
                              (define ht (hash-table 'a 1))
                              (hash-remove! ht 'z)
                              (hash-count ht)))
                  1))))

(deftest test-utility-primitives
    (testing "string-downcase"
             (ok (equal (evaluate '(string-downcase "Hello World")) "hello world"))
             (ok (equal (evaluate '(string-downcase "hello")) "hello")))

  (testing "string-upcase"
           (ok (equal (evaluate '(string-upcase "Hello World")) "HELLO WORLD"))
           (ok (equal (evaluate '(string-upcase "HELLO")) "HELLO")))

  (testing "string-split by default (space)"
           (ok (equal (evaluate '(string-split "hello world")) '("hello" "world"))))

  (testing "string-split by explicit delimiter"
           (ok (equal (evaluate '(string-split "a,b,c" #\,)) '("a" "b" "c"))))

  (testing "string-split no delimiter found"
           (ok (equal (evaluate '(string-split "hello" #\,)) '("hello"))))

  (testing "string-split empty string"
           (ok (equal (evaluate '(string-split "" #\,)) '(""))))

  (testing "sleep returns nil"
           (ok (null (evaluate '(sleep 0)))))

  (testing "clear-screen returns nil"
           (ok (null (let ((*standard-output* (make-string-output-stream)))
                       (evaluate '(clear-screen)))))))

(deftest test-save-load-continuation
    (testing "round-trip with plain value"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "sav")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (evaluate `(save-continuation! ,(namestring tmpfile) (quote (1 2 3))))
                      (ok (equal (evaluate `(load-continuation ,(namestring tmpfile)))
                                 '(1 2 3))))
                 (delete-file tmpfile))))

  (testing "round-trip with hash table"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "sav")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate `(save-continuation! ,(namestring tmpfile)
                                                   (hash-table 'name "Alice" 'age 30)))
                    (let ((loaded (evaluate `(load-continuation ,(namestring tmpfile)))))
                      (ok (equal loaded '(:hash-table (name . "Alice") (age . 30))))))
               (delete-file tmpfile))))

  (testing "round-trip with continuation"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "sav")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    ;; Capture a continuation and save it
                    (evaluate `(begin
                                (define k nil)
                                (call/cc (lambda (cont) (set k cont)))
                                (save-continuation! ,(namestring tmpfile) k)))
                    ;; Verify entirely within ECE to avoid circular data in CL test output
                    (ok (eq t (evaluate `(begin
                                          (define loaded (load-continuation ,(namestring tmpfile)))
                                          (eq? (car loaded) ',(intern "CONTINUATION" :ece)))))))
               (delete-file tmpfile))))

  (testing "save-continuation! returns t"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "sav")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (ok (eq (evaluate `(save-continuation! ,(namestring tmpfile) 42)) t))
               (delete-file tmpfile))))

  (testing "save-continuation! overwrites existing file"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "sav")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate `(save-continuation! ,(namestring tmpfile) "old"))
                    (evaluate `(save-continuation! ,(namestring tmpfile) "new"))
                    (ok (equal (evaluate `(load-continuation ,(namestring tmpfile)))
                               "new")))
               (delete-file tmpfile)))))

(deftest test-define-record
    (testing "constructor creates typed hash table"
             (ok (equal (evaluate '(begin (define-record point x y)
                                    (point-x (make-point 10 20))))
                        10))
             (ok (equal (evaluate '(begin (define-record point x y)
                                    (point-y (make-point 10 20))))
                        20))
             (ok (equal (evaluate '(begin (define-record point x y)
                                    (hash-ref (make-point 10 20) 'type)))
                        'point)))

  (testing "constructor with no fields"
           (ok (equal (evaluate '(begin (define-record empty)
                                  (hash-count (make-empty))))
                      1))
           (ok (equal (evaluate '(begin (define-record empty)
                                  (hash-ref (make-empty) 'type)))
                      'empty)))

  (testing "predicate returns true for matching record"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (point? (make-point 1 2))))
                      t)))

  (testing "predicate returns false for non-matching value"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (point? 42)))
                      nil)))

  (testing "predicate returns false for different record type"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (define-record vec x y)
                                  (point? (make-vec 1 2))))
                      nil)))

  (testing "mutator updates field in place"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (define p (make-point 1 2))
                                  (set-point-x! p 99)
                                  (point-x p)))
                      99)))

  (testing "functional update returns new record, original unchanged"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (define p (make-point 1 2))
                                  (define p2 (point-with-x p 99))
                                  (list (point-x p) (point-x p2))))
                      '(1 99))))

  (testing "copy creates independent record"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (define p (make-point 1 2))
                                  (define p2 (copy-point p))
                                  (set-point-x! p2 99)
                                  (list (point-x p) (point-x p2))))
                      '(1 99))))

  (testing "records are standard hash tables"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (hash-table? (make-point 10 20))))
                      t)))

  (testing "multiple record types coexist"
           (ok (equal (evaluate '(begin (define-record point x y)
                                  (define-record person name age)
                                  (list (point-x (make-point 3 4))
                                   (person-name (make-person "Alice" 30)))))
                      (list 3 "Alice")))))

(deftest test-assert
    (testing "truthy condition passes"
             (ok (not (evaluate '(assert t))))
             (ok (not (evaluate '(assert 42))))
             (ok (not (evaluate '(assert "hello")))))
  (testing "falsy condition signals error"
           (ok (handler-case (progn (evaluate '(assert ())) nil)
                 (error (c) (search "Assertion failed" (format nil "~A" c))))))
  (testing "custom message on failure"
           (ok (handler-case (progn (evaluate '(assert () "x must be positive")) nil)
                 (error (c) (search "x must be positive" (format nil "~A" c))))))
  (testing "custom message not used on success"
           (ok (not (evaluate '(assert t "should not see this"))))))

(deftest test-any
    (testing "element found"
             (ok (evaluate '(any odd? (list 2 3 4)))))
  (testing "no element found"
           (ok (not (evaluate '(any odd? (list 2 4 6))))))
  (testing "empty list"
           (ok (not (evaluate '(any odd? (list)))))))

(deftest test-every
    (testing "all elements match"
             (ok (evaluate '(every even? (list 2 4 6)))))
  (testing "some element fails"
           (ok (not (evaluate '(every even? (list 2 3 6))))))
  (testing "empty list"
           (ok (evaluate '(every even? (list))))))

(deftest test-compose
    (testing "compose two functions"
             (ok (equal (evaluate '((compose car cdr) (list 1 2 3))) 2))))

(deftest test-identity
    (testing "returns its argument"
             (ok (equal (evaluate '(identity 42)) 42)))
  (testing "as function argument"
           (ok (equal (evaluate '(map identity (list 1 2 3))) '(1 2 3)))))

(deftest test-range
    (testing "range of 5"
             (ok (equal (evaluate '(range 5)) '(0 1 2 3 4))))
  (testing "range of 0"
           (ok (equal (evaluate '(range 0)) nil)))
  (testing "range of 1"
           (ok (equal (evaluate '(range 1)) '(0)))))

(deftest test-lines
    (testing "multiple lines"
             (ok (equal (evaluate '(lines "hello" "world"))
                        (format nil "hello~%world~%"))))
  (testing "single line"
           (ok (equal (evaluate '(lines "hello"))
                      (format nil "hello~%"))))
  (testing "empty call"
           (ok (equal (evaluate '(lines)) "")))
  (testing "mixed types auto-stringified"
           (ok (equal (evaluate '(lines "count:" 42))
                      (format nil "count:~%42~%")))))

(deftest test-string-interpolation
    (testing "plain string without $ is unchanged"
             (ok (equal (ece-eval-string "\"hello world\"") "hello world")))
  (testing "variable interpolation"
           (ok (equal (ece-eval-string "(begin (define name \"Alice\") \"Hello $name\")") "Hello Alice")))
  (testing "expression interpolation"
           (ok (equal (ece-eval-string "(begin (define x 3) \"result: $(+ x 1)\")") "result: 4")))
  (testing "literal dollar with $$"
           (ok (equal (ece-eval-string "\"Price: $$5.00\"") "Price: $5.00")))
  (testing "number auto-stringified"
           (ok (equal (ece-eval-string "(begin (define age 30) \"Age: $age\")") "Age: 30")))
  (testing "multiple interpolations"
           (ok (equal (ece-eval-string "(begin (define a 1) (define b 2) \"$a and $b\")") "1 and 2")))
  (testing "star variable"
           (ok (equal (ece-eval-string "(begin (define *count* 5) \"Total: $*count*\")") "Total: 5"))))

(deftest test-string-contains
    (testing "substring found"
             (ok (evaluate '(string-contains? "hello world" "world"))))
  (testing "substring not found"
           (ok (not (evaluate '(string-contains? "hello world" "xyz")))))
  (testing "empty needle"
           (ok (evaluate '(string-contains? "hello" ""))))
  (testing "case sensitive"
           (ok (not (evaluate '(string-contains? "Hello" "hello"))))))

(deftest test-string-join
    (testing "join with comma"
             (ok (equal (evaluate '(string-join (list "a" "b" "c") ", ")) "a, b, c")))
  (testing "join with empty separator"
           (ok (equal (evaluate '(string-join (list "a" "b" "c") "")) "abc")))
  (testing "single element"
           (ok (equal (evaluate '(string-join (list "hello") "-")) "hello")))
  (testing "empty list"
           (ok (equal (evaluate '(string-join (list) ", ")) ""))))

(deftest test-hash-values
    (testing "table with entries"
             (ok (equal (evaluate '(hash-values (hash-table (quote a) 1 (quote b) 2)))
                        '(1 2))))
  (testing "empty table"
           (ok (null (evaluate '(hash-values (hash-table)))))))

(deftest test-string-trim
    (testing "trim spaces"
             (ok (equal (evaluate '(string-trim "  hello  ")) "hello")))
  (testing "no whitespace"
           (ok (equal (evaluate '(string-trim "hello")) "hello")))
  (testing "all whitespace"
           (ok (equal (evaluate '(string-trim "   ")) "")))
  (testing "empty string"
           (ok (equal (evaluate '(string-trim "")) ""))))

(deftest test-clamp
    (testing "value within range"
             (ok (= (evaluate '(clamp 5 0 10)) 5)))
  (testing "value below range"
           (ok (= (evaluate '(clamp -3 0 10)) 0)))
  (testing "value above range"
           (ok (= (evaluate '(clamp 15 0 10)) 10)))
  (testing "value at boundary"
           (ok (= (evaluate '(clamp 0 0 10)) 0))))

(deftest test-fold
    (testing "fold sums a list"
             (ok (= (evaluate '(fold + 0 (list 1 2 3 4))) 10)))
  (testing "fold-left sums a list"
           (ok (= (evaluate '(fold-left + 0 (list 1 2 3))) 6)))
  (testing "fold-right cons copies list"
           (ok (equal (evaluate '(fold-right cons (list) (list 1 2 3))) '(1 2 3))))
  (testing "fold-right subtraction order"
           (ok (= (evaluate '(fold-right - 0 (list 1 2 3))) 2))))

(deftest test-loop
    (testing "loop with immediate break"
             (ok (= (evaluate '(loop (break 42))) 42)))
  (testing "loop with counter"
           (ok (= (evaluate '(let ((x 5))
                              (loop
                               (if (= x 0) (break x))
                               (set x (- x 1)))))
                  0)))
  (testing "loop accumulates then breaks"
           (ok (equal (evaluate '(let ((acc (list)) (i 0))
                                  (loop
                                   (if (= i 5) (break acc))
                                   (set acc (cons i acc))
                                   (set i (+ i 1)))))
                      '(4 3 2 1 0)))))

(deftest test-collect
    (testing "square numbers"
             (ok (equal (evaluate '(collect (x (range 5)) (* x x)))
                        '(0 1 4 9 16))))
  (testing "transform strings"
           (ok (equal (evaluate '(collect (s (list "a" "b" "c"))
                                  (string-append s "!")))
                      '("a!" "b!" "c!")))))

(deftest test-unknown-expression-error
    (testing "unrecognized expression types signal an error"
             (signals (evaluate (make-hash-table) nil))))

;;; Compiler-specific tests

(deftest test-compiled-procedure-objects
    (testing "lambda produces a compiled procedure list"
             (ok (listp (evaluate '(lambda (x) (+ x 1))))))
  (testing "compiled procedure is callable"
           (ok (= (evaluate '((lambda (x) (+ x 1)) 5)) 6))))

(deftest test-macro-lexical-shadowing
    (testing "lambda parameter shadows macro"
             (ok (= (evaluate '((lambda (loop) (loop loop 5))
                                (lambda (self n)
                                  (if (= n 0) 0 (self self (- n 1))))))
                    0)))
  (testing "define in begin shadows macro"
           (ok (eq (evaluate '(begin
                               (define (loop n)
                                (if (= n 0) (quote done) (loop (- n 1))))
                               (loop 10)))
                   'done)))
  (testing "named let with loop name works"
           (ok (= (evaluate '(let loop ((n 10) (acc 0))
                              (if (= n 0) acc (loop (- n 1) (+ acc n)))))
                  55))))

;;;; ========================================================================
;;;; IMAGE SAVE/LOAD TESTS
;;;; ========================================================================

(deftest test-image-save-returns-t
    (testing "save-image! returns t and creates a file"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (ok (eq (ece::ece-save-image (namestring tmpfile)) t))
                      (ok (probe-file tmpfile)))
                 (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-restores-simple-bindings
    (testing "load-image! restores number bindings"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (evaluate '(define img-test-num 42))
                      (ece::ece-save-image (namestring tmpfile))
                      (evaluate '(set img-test-num 999))
                      (ece::ece-load-image (namestring tmpfile))
                      (ok (= (evaluate 'img-test-num) 42)))
                 (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "load-image! restores string bindings"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate '(define img-test-str "hello world"))
                    (ece::ece-save-image (namestring tmpfile))
                    (evaluate '(set img-test-str "overwritten"))
                    (ece::ece-load-image (namestring tmpfile))
                    (ok (equal (evaluate 'img-test-str) "hello world")))
               (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "load-image! restores boolean and symbol bindings"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate '(define img-test-bool t))
                    (evaluate '(define img-test-sym (quote hello)))
                    (ece::ece-save-image (namestring tmpfile))
                    (evaluate '(set img-test-bool nil))
                    (ece::ece-load-image (namestring tmpfile))
                    (ok (eq (evaluate 'img-test-bool) t))
                    (ok (eq (evaluate 'img-test-sym) 'hello)))
               (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "load-image! restores list bindings"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate '(define img-test-lst (list 1 2 3)))
                    (ece::ece-save-image (namestring tmpfile))
                    (evaluate '(set img-test-lst (list 9 9 9)))
                    (ece::ece-load-image (namestring tmpfile))
                    (ok (equal (evaluate 'img-test-lst) '(1 2 3))))
               (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-restores-compiled-procedures
    (testing "compiled function survives round-trip"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (evaluate '(define (img-square n) (* n n)))
                      (ece::ece-save-image (namestring tmpfile))
                      ;; Clobber the environment to prove load restores it
                      (evaluate '(define (img-square n) 0))
                      (ece::ece-load-image (namestring tmpfile))
                      (ok (= (evaluate '(img-square 7)) 49)))
                 (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "recursive function survives round-trip"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate '(define (img-fact n)
                                (if (= n 0) 1 (* n (img-fact (- n 1))))))
                    (ece::ece-save-image (namestring tmpfile))
                    (ece::ece-load-image (namestring tmpfile))
                    (ok (= (evaluate '(img-fact 10)) 3628800)))
               (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-restores-closures
    (testing "closure over variable survives round-trip"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (evaluate '(begin
                                  (define img-make-counter
                                   (lambda ()
                                     (begin
                                      (define count 0)
                                      (lambda ()
                                        (set count (+ count 1))
                                        count))))
                                  (define img-counter (img-make-counter))))
                      ;; Increment twice before save
                      (evaluate '(img-counter))
                      (evaluate '(img-counter))
                      (ece::ece-save-image (namestring tmpfile))
                      ;; Increment more to change state
                      (evaluate '(img-counter))
                      (evaluate '(img-counter))
                      (ece::ece-load-image (namestring tmpfile))
                      ;; After load, counter should continue from 2
                      (ok (= (evaluate '(img-counter)) 3)))
                 (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-restores-macros
    (testing "compile-time macros survive round-trip"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (evaluate '(define-macro (img-swap a b) `(list ,b ,a)))
                      (ece::ece-save-image (namestring tmpfile))
                      (ece::ece-load-image (namestring tmpfile))
                      ;; Macro should still expand correctly for NEW code
                      (ok (equal (evaluate '(img-swap 1 2)) '(2 1))))
                 (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-prelude-survives
    (testing "map works after round-trip"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (ece::ece-save-image (namestring tmpfile))
                      (ece::ece-load-image (namestring tmpfile))
                      (ok (equal (evaluate '(map (lambda (x) (* x x)) (list 1 2 3)))
                                 '(1 4 9))))
                 (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "filter works after round-trip"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (ece::ece-save-image (namestring tmpfile))
                    (ece::ece-load-image (namestring tmpfile))
                    (ok (equal (evaluate '(filter odd? (list 1 2 3 4 5)))
                               '(1 3 5))))
               (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "reduce works after round-trip"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (ece::ece-save-image (namestring tmpfile))
                    (ece::ece-load-image (namestring tmpfile))
                    (ok (= (evaluate '(reduce + 0 (list 1 2 3))) 6)))
               (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-hash-tables-and-vectors
    (testing "hash tables survive round-trip"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (evaluate '(define img-ht (hash-table 'name "Alice" 'age 30)))
                      (ece::ece-save-image (namestring tmpfile))
                      (ece::ece-load-image (namestring tmpfile))
                      (ok (equal (evaluate '(hash-ref img-ht 'name)) "Alice"))
                      (ok (= (evaluate '(hash-ref img-ht 'age)) 30)))
                 (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "vectors survive round-trip"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate '(define img-vec (vector 10 20 30)))
                    (ece::ece-save-image (namestring tmpfile))
                    (ece::ece-load-image (namestring tmpfile))
                    (ok (= (evaluate '(vector-ref img-vec 0)) 10))
                    (ok (= (evaluate '(vector-ref img-vec 2)) 30))
                    (ok (= (evaluate '(vector-length img-vec)) 3)))
               (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-continuations
    (testing "continuation survives round-trip"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      ;; Capture a continuation and check it round-trips
                      (evaluate '(define img-k (call/cc (lambda (k) k))))
                      (ok (eq t (evaluate `(eq? (car img-k)
                                                ',(intern "CONTINUATION" :ece)))))
                      (ece::ece-save-image (namestring tmpfile))
                      (ece::ece-load-image (namestring tmpfile))
                      ;; After load, verify it's still a continuation
                      (ok (eq t (evaluate `(eq? (car img-k)
                                                ',(intern "CONTINUATION" :ece))))))
                 (when (probe-file tmpfile) (delete-file tmpfile))))))

(deftest test-image-compiler-works-after-load
    (testing "new code compiles and runs after loading an image"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (ece::ece-save-image (namestring tmpfile))
                      (ece::ece-load-image (namestring tmpfile))
                      ;; Compile and run brand new code
                      (ok (= (evaluate '(+ 1 2)) 3))
                      ;; Define a new function after load
                      (ok (= (evaluate '(begin
                                         (define (img-post-load-fn x y) (+ (* x x) (* y y)))
                                         (img-post-load-fn 3 4)))
                             25))
                      ;; Lambda and higher-order after load
                      (ok (equal (evaluate '(map (lambda (x) (+ x 10)) (list 1 2 3)))
                                 '(11 12 13))))
                 (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "define-macro works after loading an image"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (ece::ece-save-image (namestring tmpfile))
                    (ece::ece-load-image (namestring tmpfile))
                    ;; Define a NEW macro after load (use list instead of backtick
                    ;; to avoid SBCL reader producing COMMA structs)
                    (evaluate '(define-macro (img-double x) (list (quote +) x x)))
                    (ok (= (evaluate '(img-double 21)) 42)))
               (when (probe-file tmpfile) (delete-file tmpfile))))))

;;;; ========================================================================
;;;; METACIRCULAR COMPILER FOUNDATION TESTS
;;;; ========================================================================

(deftest test-union
    (testing "union of disjoint lists"
             (ok (equal (evaluate '(union '(a b) '(c d))) '(a b c d))))
  (testing "union with overlap"
           (let ((result (evaluate '(union '(a b c) '(b c d)))))
             (ok (= (length result) 4))
             (ok (member 'a result))
             (ok (member 'b result))
             (ok (member 'c result))
             (ok (member 'd result))))
  (testing "union with empty list"
           (ok (equal (evaluate '(union '() '(a b))) '(a b)))
           (ok (equal (evaluate '(union '(a b) '())) '(a b)))))

(deftest test-set-difference
    (testing "basic difference"
             (ok (equal (evaluate '(set-difference '(a b c d) '(b d))) '(a c))))
  (testing "no overlap"
           (ok (equal (evaluate '(set-difference '(a b) '(c d))) '(a b))))
  (testing "complete overlap"
           (ok (null (evaluate '(set-difference '(a b) '(a b))))))
  (testing "empty first list"
           (ok (null (evaluate '(set-difference '() '(a b)))))))

(deftest test-assemble-and-execute
    (testing "assemble-into-global returns a PC and execute-from-pc runs it"
             (ok (= (ece-eval-string
                     "(begin
                       (define aig-test-pc
                         (assemble-into-global
                          (list (list 'assign 'val (list 'const 77)))))
                       (execute-from-pc aig-test-pc))")
                    77))))

;;;; ========================================================================
;;;; METACIRCULAR COMPILER TESTS
;;;; ========================================================================

;;; Instruction sequence infrastructure tests

(deftest test-mc-instruction-sequences
    (testing "make-instruction-sequence creates correct triple"
             ;; Verify structure: list of 3 elements
             (let ((result (ece-eval-string
                            "(make-instruction-sequence '(env) '(val) '((assign val (const 1))))")))
               (ok (= (length result) 3))
               (ok (= (length (car result)) 1))    ; needs = (env)
               (ok (= (length (cadr result)) 1)))) ; modifies = (val)
  (testing "empty-instruction-sequence"
           (ok (equal (ece-eval-string "(empty-instruction-sequence)")
                      '(() () ()))))
  (testing "registers-needed and registers-modified"
           (ok (= (length (ece-eval-string
                           "(registers-needed (make-instruction-sequence '(env val) '(proc) '()))"))
                  2))
           (ok (= (length (ece-eval-string
                           "(registers-modified (make-instruction-sequence '(env val) '(proc) '()))"))
                  1)))
  (testing "registers-needed of symbol is empty"
           (ok (null (ece-eval-string "(registers-needed 'some-label)"))))
  (testing "append-2-sequences merges needs/modifies"
           ;; seq1 needs (env), modifies (val); seq2 needs (val), modifies (proc)
           ;; result needs: (env), modifies: (val proc), instructions: 2
           (let ((result (ece-eval-string
                          "(append-2-sequences
                            (make-instruction-sequence '(env) '(val) '((i1)))
                            (make-instruction-sequence '(val) '(proc) '((i2))))")))
             (ok (= (length (car result)) 1))     ; needs = (env)
             (ok (= (length (cadr result)) 2))    ; modifies = (val proc)
             (ok (= (length (caddr result)) 2)))) ; 2 instructions
  (testing "preserving inserts save/restore when needed"
           ;; seq1 modifies env, seq2 needs env -> should add save/restore = 4 instructions
           (let ((instrs (ece-eval-string
                          "(caddr (preserving '(env)
                            (make-instruction-sequence '() '(env) '((modify-env)))
                            (make-instruction-sequence '(env) '() '((use-env)))))")))
             (ok (= (length instrs) 4))))  ; save + modify + restore + use
  (testing "preserving skips save/restore when not needed"
           ;; seq1 modifies val, seq2 needs env (not val) -> no save/restore = 2 instructions
           (let ((instrs (ece-eval-string
                          "(caddr (preserving '(env)
                            (make-instruction-sequence '() '(val) '((modify-val)))
                            (make-instruction-sequence '(env) '() '((use-env)))))")))
             (ok (= (length instrs) 2)))))

;;; Label generation tests

(deftest test-mc-labels
    (testing "mc-make-label produces unique symbols"
             (let ((l1 (ece-eval-string "(mc-make-label 'test)"))
                   (l2 (ece-eval-string "(mc-make-label 'test)")))
               (ok (symbolp l1))
               (ok (symbolp l2))
               (ok (not (eq l1 l2))))))

;;; Core compile function tests

(deftest test-mc-compile-core
    (testing "compile self-evaluating integer"
             (ok (= (ece-eval-string "(mc-compile-and-go 42)") 42)))
  (testing "compile self-evaluating string"
           (ok (equal (ece-eval-string "(mc-compile-and-go \"hello\")") "hello")))
  (testing "compile variable reference"
           (ece-eval-string "(define mc-test-var 99)")
           (ok (= (ece-eval-string "(mc-compile-and-go 'mc-test-var)") 99)))
  (testing "compile quoted expression"
           (ok (equal (ece-eval-string "(mc-compile-and-go '(quote (a b c)))")
                      (list (intern "A" :ece) (intern "B" :ece) (intern "C" :ece)))))
  (testing "compile if true branch"
           (ok (= (ece-eval-string "(mc-compile-and-go '(if t 1 2))") 1)))
  (testing "compile if false branch"
           (ok (= (ece-eval-string "(mc-compile-and-go '(if () 1 2))") 2)))
  (testing "compile begin sequence"
           (ok (= (ece-eval-string "(mc-compile-and-go '(begin 1 2 3))") 3))))

;;; Metacircular compiler integration tests
;;; All mc-compile-and-go tests in a single deftest to minimize overhead

(deftest test-mc-compile-integration
    ;; Lambda & application
    (testing "compile and call lambda"
             (ok (= (ece-eval-string "(mc-compile-and-go '((lambda (x) (+ x 1)) 5))") 6)))
  (testing "compile lambda with multiple args"
           (ok (= (ece-eval-string "(mc-compile-and-go '((lambda (x y) (+ x y)) 3 4))") 7)))
  (testing "compile closure"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go
                     '(begin
                       (define (mc-make-adder n) (lambda (x) (+ n x)))
                       ((mc-make-adder 10) 5)))")
                  15)))
  (testing "compile primitive application"
           (ok (= (ece-eval-string "(mc-compile-and-go '(+ (* 2 3) (* 4 5)))") 26)))
  ;; Special forms
  (testing "compile define and use"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go '(begin (define mc-x-test 42) mc-x-test))")
                  42)))
  (testing "compile function shorthand define"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go '(begin (define (mc-sq x) (* x x)) (mc-sq 7)))")
                  49)))
  (testing "compile set"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go '(begin (define mc-y-test 1) (set mc-y-test 42) mc-y-test))")
                  42)))
  (testing "compile call/cc"
           (ok (= (ece-eval-string "(mc-compile-and-go '(call/cc (lambda (k) (k 42))))") 42)))
  (testing "compile apply form"
           (ok (= (ece-eval-string "(mc-compile-and-go '(apply + (list 1 2 3)))") 6)))
  ;; Macros
  (testing "compile let macro"
           (ok (= (ece-eval-string "(mc-compile-and-go '(let ((x 10) (y 20)) (+ x y)))") 30)))
  (testing "compile cond macro"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go '(cond ((= 1 2) 10) ((= 1 1) 20) (else 30)))")
                  20)))
  (testing "compile and/or macros"
           (ok (= (ece-eval-string "(mc-compile-and-go '(and 1 2 3))") 3))
           (ok (= (ece-eval-string "(mc-compile-and-go '(or () () 42))") 42)))
  (testing "compile when/unless macros"
           (ok (= (ece-eval-string "(mc-compile-and-go '(when t 42))") 42))
           (ok (= (ece-eval-string "(mc-compile-and-go '(unless () 42))") 42)))
  ;; Recursion
  (testing "compile recursive function"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go
                     '(begin
                       (define (mc-fact n) (if (= n 0) 1 (* n (mc-fact (- n 1)))))
                       (mc-fact 10)))")
                  3628800)))
  (testing "compile tail-recursive function"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go
                     '(begin
                       (define (mc-sum-iter n acc)
                         (if (= n 0) acc (mc-sum-iter (- n 1) (+ acc n))))
                       (mc-sum-iter 100 0)))")
                  5050)))
  (testing "compile higher-order functions"
           (ok (equal (ece-eval-string
                       "(mc-compile-and-go '(map (lambda (x) (* x x)) (list 1 2 3)))")
                      '(1 4 9))))
  ;; Quasiquote
  (testing "compile quasiquote with unquote"
           (ok (equal (ece-eval-string
                       "(mc-compile-and-go
                         '(begin
                           (define mc-qq-val 42)
                           (quasiquote (a (unquote mc-qq-val) c))))")
                      (list (intern "A" :ece) 42 (intern "C" :ece))))))

;;;; ========================================================================
;;;; PARAMETER OBJECT TESTS
;;;; ========================================================================

(deftest test-make-parameter
    (testing "create and read parameter"
             (ok (= (ece-eval-string
                     "(begin (define p (make-parameter 42)) (p))")
                    42)))
  (testing "set parameter value"
           (ok (= (ece-eval-string
                   "(begin (define p (make-parameter 42)) (p 99) (p))")
                  99)))
  (testing "set returns old value"
           (ok (= (ece-eval-string
                   "(begin (define p (make-parameter 42)) (p 99))")
                  42)))
  (testing "parameter with converter on init"
           (ok (= (ece-eval-string
                   "(begin (define p (make-parameter \"hello\" string-length)) (p))")
                  5)))
  (testing "converter applied on set"
           (ok (= (ece-eval-string
                   "(begin
                     (define p (make-parameter \"hello\" string-length))
                     (p \"world\")
                     (p))")
                  5))))

(deftest test-parameterize
    (testing "basic dynamic rebinding"
             (ok (= (ece-eval-string
                     "(begin
                       (define p (make-parameter 42))
                       (parameterize ((p 99)) (p)))")
                    99)))
  (testing "restore after exit"
           (ok (= (ece-eval-string
                   "(begin
                     (define p (make-parameter 42))
                     (parameterize ((p 99)) (p))
                     (p))")
                  42)))
  (testing "dynamic scope propagates to called functions"
           (ok (= (ece-eval-string
                   "(begin
                     (define p (make-parameter 42))
                     (define (read-p) (p))
                     (parameterize ((p 99)) (read-p)))")
                  99)))
  (testing "multiple bindings"
           (ok (= (ece-eval-string
                   "(begin
                     (define p1 (make-parameter 0))
                     (define p2 (make-parameter 0))
                     (parameterize ((p1 10) (p2 20)) (+ (p1) (p2))))")
                  30)))
  (testing "nested parameterize"
           (ok (= (ece-eval-string
                   "(begin
                     (define p (make-parameter 0))
                     (parameterize ((p 1))
                       (parameterize ((p 2)) (p))))")
                  2)))
  (testing "nested parameterize restores correctly"
           (ok (= (ece-eval-string
                   "(begin
                     (define p (make-parameter 0))
                     (parameterize ((p 1))
                       (parameterize ((p 2)) (p))
                       (p)))")
                  1)))
  (testing "converter applied during parameterize"
           (ok (= (ece-eval-string
                   "(begin
                     (define p (make-parameter \"hello\" string-length))
                     (parameterize ((p \"goodbye\")) (p)))")
                  7))))

(deftest test-mc-macro-shadowing
    (testing "MC compiler: lambda parameter shadows macro"
             (ok (= (ece-eval-string
                     "(mc-compile-and-go
                       '((lambda (when) (+ when 1)) 41))")
                    42)))
  (testing "MC compiler: define in begin shadows macro"
           (ok (= (ece-eval-string
                   "(mc-compile-and-go
                     '(begin
                       (define (when x) (+ x 10))
                       (when 5)))")
                  15))))

(deftest test-error-context
    (testing "error captures current procedure from proc register"
             (handler-case
                 (progn
                   (ece-eval-string "(begin (define (f x) (+ x y)) (f 5))")
                   (ok nil "should have signaled"))
               (ece-runtime-error (e)
                 ;; proc register has the inner call (+ x y), which is (primitive +)
                 (ok (ece-error-procedure e))
                 (ok (ece-original-error e)))))

  (testing "error includes visible environment bindings"
           (handler-case
               (progn
                 (ece-eval-string "((lambda (x) (+ x y)) 5)")
                 (ok nil "should have signaled"))
             (ece-runtime-error (e)
               (let ((env (ece-error-environment e)))
                 (ok (consp env))
                 ;; innermost frame should have x=5
                 (let* ((frame (car env))
                        (vars (car frame))
                        (vals (cdr frame))
                        (pos (position 'ece::x vars)))
                   (ok pos)
                   (when pos (ok (= (nth pos vals) 5))))))))

  (testing "original error is accessible"
           (handler-case
               (progn
                 (ece-eval-string "(+ 1 \"bad\")")
                 (ok nil "should have signaled"))
             (ece-runtime-error (e)
               (ok (typep (ece-original-error e) 'error)))))

  (testing "nested non-tail calls produce backtrace"
           (handler-case
               (progn
                 (ece-eval-string
                  "(begin
                     (define (g x) (+ x \"bad\"))
                     (define (f x) (+ (g x) 1))
                     (f 5))")
                 (ok nil "should have signaled"))
             (ece-runtime-error (e)
               (ok (listp (ece-error-backtrace e)))
               ;; non-tail calls save continues on the stack
               (ok (>= (length (ece-error-backtrace e)) 1)))))

  (testing "condition slots are programmatically accessible"
           (handler-case
               (progn
                 (ece-eval-string "((lambda (a) (+ a z)) 99)")
                 (ok nil "should have signaled"))
             (ece-runtime-error (e)
               (ok (typep e 'ece-runtime-error))
               (ok (ece-original-error e))
               (ok (ece-error-environment e))
               (ok (ece-error-instruction e)))))

  (testing "normal execution is not degraded"
           ;; Run a loop and ensure it completes (performance, not timing)
           (ok (= (ece-eval-string
                   "(begin
                      (define (loop-sum n acc)
                        (if (= n 0) acc (loop-sum (- n 1) (+ acc n))))
                      (loop-sum 100000 0))")
                  5000050000))))

(deftest test-procedure-name-table
    (testing "format-ece-proc displays procedure name for defined function"
             (ece-eval-string "(define (my-test-fn x) (+ x 1))")
             ;; Find my-test-fn's entry PC in the environment
             (let* ((proc (ece::lookup-variable-value 'ece::my-test-fn ece::*global-env*))
                    (entry-pc (cadr proc))
                    (name (gethash entry-pc ece::*procedure-name-table*)))
               (ok (eq name 'ece::my-test-fn))
               (ok (search "MY-TEST-FN" (ece::format-ece-proc proc)))))

  (testing "error message shows procedure name in backtrace"
           (handler-case
               (progn
                 (ece-eval-string
                  "(begin
                     (define (outer-fn x) (+ (inner-fn x) 1))
                     (define (inner-fn x) (+ x \"bad\"))
                     (outer-fn 5))")
                 (ok nil "should have signaled"))
             (ece-runtime-error (e)
               (let ((msg (format nil "~A" e)))
                 ;; The error message should contain formatted output
                 (ok (search "ECE error" msg))))))

  (testing "anonymous lambdas display as unnamed"
           (let ((anon-proc (list 'ece::compiled-procedure 999999 nil)))
             ;; PC 999999 is not in the name table
             (ok (search "entry=" (ece::format-ece-proc anon-proc)))))

  (testing "image save/load preserves procedure name mappings"
           (ece-eval-string "(define (img-test-fn x) (* x x))")
           (let ((pc-before (cadr (ece::lookup-variable-value 'ece::img-test-fn ece::*global-env*))))
             ;; Save image
             (ece-eval-string "(save-image! \"/tmp/ece-name-test.image\")")
             ;; Clear and reload
             (ece-eval-string "(load-image! \"/tmp/ece-name-test.image\")")
             ;; Name should still be mapped
             (let ((name-after (gethash pc-before ece::*procedure-name-table*)))
               (ok (eq name-after 'ece::img-test-fn)))))

  (testing "MC-compiled defines register procedure names"
           (ece-eval-string "(mc-compile-and-go '(define (mc-name-test x) (+ x 1)))")
           (let* ((proc (ece::lookup-variable-value 'ece::mc-name-test ece::*global-env*))
                  (entry-pc (cadr proc))
                  (name (gethash entry-pc ece::*procedure-name-table*)))
             (ok (eq name 'ece::mc-name-test)))))

(deftest test-tracing
    (testing "tracing a compiled procedure produces output and correct value"
             (ece-eval-string "(define (trace-add x y) (+ x y))")
             (ece-eval-string "(trace 'trace-add)")
             (let ((result nil))
               (let ((output (with-output-to-string (*standard-output*)
                               (setf result (ece-eval-string "(trace-add 3 4)")))))
                 (ok (eql 7 result))
                 (ok (search "TRACE-ADD" output))
                 (ok (search "3" output))
                 (ok (search "7" output))))
             (ece-eval-string "(untrace 'trace-add)"))

  (testing "tracing a primitive produces output and correct value"
           (ece-eval-string "(trace '+)")
           (let ((result nil))
             (let ((output (with-output-to-string (*standard-output*)
                             (setf result (ece-eval-string "(+ 2 3)")))))
               (ok (eql 5 result))
               (ok (search "+" output))
               (ok (search "5" output))))
           (ece-eval-string "(untrace '+)"))

  (testing "untrace restores original behavior"
           (ece-eval-string "(define (trace-sq x) (* x x))")
           (ece-eval-string "(trace 'trace-sq)")
           ;; Call once with tracing
           (with-output-to-string (*standard-output*)
             (ece-eval-string "(trace-sq 5)"))
           ;; Untrace
           (ece-eval-string "(untrace 'trace-sq)")
           ;; Call again — should produce no trace output
           (let ((result nil))
             (let ((output (with-output-to-string (*standard-output*)
                             (setf result (ece-eval-string "(trace-sq 5)")))))
               (ok (eql 25 result))
               (ok (eql 0 (length output))))))

  (testing "nested traced calls show increasing indentation"
           (ece-eval-string "(define (trace-outer x) (trace-inner x))")
           (ece-eval-string "(define (trace-inner x) (+ x 1))")
           (ece-eval-string "(trace 'trace-outer)")
           (ece-eval-string "(trace 'trace-inner)")
           (let* ((output (with-output-to-string (*standard-output*)
                            (ece-eval-string "(trace-outer 10)")))
                  (lines (remove-if (lambda (s) (zerop (length s)))
                                    (ece::ece-string-split output #\Newline))))
             ;; Should have 4 lines: enter outer, enter inner, exit inner, exit outer
             (ok (>= (length lines) 4))
             ;; Inner call lines should have more leading spaces than outer
             (let ((outer-spaces (- (length (first lines))
                                    (length (string-left-trim " " (first lines)))))
                   (inner-spaces (- (length (second lines))
                                    (length (string-left-trim " " (second lines))))))
               (ok (> inner-spaces outer-spaces))))
           (ece-eval-string "(untrace 'trace-outer)")
           (ece-eval-string "(untrace 'trace-inner)"))

  (testing "untrace on non-traced procedure does not error"
           (ece-eval-string "(define (not-traced-fn x) x)")
           (ok (ece-eval-string "(untrace 'not-traced-fn)"))))

(deftest test-ports
    (testing "port predicates"
             (let ((ip (ece::ece-open-input-string "test")))
               (ok (ece::ece-input-port-p ip))
               (ok (not (ece::ece-output-port-p ip)))
               (ok (ece::ece-port-p ip)))
             (ok (not (ece::ece-port-p 42)))
             (ok (not (ece::ece-port-p "hello")))
             (ok (not (ece::ece-input-port-p nil))))

  (testing "string port: open, read chars, EOF"
           (let ((p (ece::ece-open-input-string "hi")))
             (ok (char= (ece::ece-read-char p) #\h))
             (ok (char= (ece::ece-read-char p) #\i))
             (ok (ece::ece-eof-p (ece::ece-read-char p)))))

  (testing "read-char and peek-char"
           (let ((p (ece::ece-open-input-string "ab")))
             ;; peek does not consume
             (ok (char= (ece::ece-peek-char p) #\a))
             (ok (char= (ece::ece-peek-char p) #\a))
             ;; read consumes
             (ok (char= (ece::ece-read-char p) #\a))
             (ok (char= (ece::ece-read-char p) #\b))
             ;; EOF
             (ok (ece::ece-eof-p (ece::ece-peek-char p)))
             (ok (ece::ece-eof-p (ece::ece-read-char p)))))

  (testing "write-char"
           (let* ((result nil)
                  (output (with-output-to-string (*standard-output*)
                            (let ((op (ece::ece-make-output-port *standard-output*)))
                              (ece::ece-write-char #\x op)
                              (ece::ece-write-char #\y op)))))
             (ok (string= "xy" output))))

  (testing "character predicates"
           (ok (ece::ece-char-whitespace-p #\Space))
           (ok (ece::ece-char-whitespace-p #\Newline))
           (ok (ece::ece-char-whitespace-p #\Tab))
           (ok (not (ece::ece-char-whitespace-p #\a)))
           (ok (ece::ece-char-alphabetic-p #\a))
           (ok (ece::ece-char-alphabetic-p #\Z))
           (ok (not (ece::ece-char-alphabetic-p #\5)))
           (ok (ece::ece-char-numeric-p #\0))
           (ok (ece::ece-char-numeric-p #\9))
           (ok (not (ece::ece-char-numeric-p #\a))))

  (testing "read-line with port argument"
           (let ((p (ece::ece-open-input-string (format nil "hello~%world"))))
             (ok (string= "hello" (ece::ece-read-line p)))
             (ok (string= "world" (ece::ece-read-line p)))
             (ok (ece::ece-eof-p (ece::ece-read-line p)))))

  (testing "current-input-port and current-output-port"
           (ok (ece::ece-input-port-p (ece::ece-current-input-port)))
           (ok (ece::ece-output-port-p (ece::ece-current-output-port))))

  (testing "with-input-from-file reads from file"
           (let ((test-file "/tmp/ece-port-test.txt"))
             ;; Write a test file
             (with-open-file (s test-file :direction :output
                                :if-exists :supersede)
               (write-string "abc" s))
             ;; Read via with-input-from-file
             (let ((ch (ece::ece-with-input-from-file
                        test-file
                        (list 'primitive 'ece::ece-read-char))))
               (ok (char= ch #\a)))
             (delete-file test-file)))

  (testing "file ports: open, read, close"
           (let ((test-file "/tmp/ece-port-test2.txt"))
             ;; Write a test file
             (with-open-file (s test-file :direction :output
                                :if-exists :supersede)
               (write-string "xyz" s))
             ;; Open, read, close
             (let ((p (ece::ece-open-input-file test-file)))
               (ok (ece::ece-input-port-p p))
               (ok (char= (ece::ece-read-char p) #\x))
               (ok (char= (ece::ece-read-char p) #\y))
               (ece::ece-close-input-port p))
             (delete-file test-file))))

;;; Helper: read one expression via ECE reader from a string
(defun ece-read-string (s)
  "Read one s-expression from string S using the ECE reader."
  (evaluate `(ece::ece-scheme-read (open-input-string ,s))))

(deftest test-ece-reader
    (testing "integers"
             (ok (= (ece-read-string "42") 42))
             (ok (= (ece-read-string "-7") -7))
             (ok (= (ece-read-string "+3") 3))
             (ok (= (ece-read-string "0") 0)))

  (testing "floats"
           (ok (= (ece-read-string "3.14") 3.14))
           (ok (= (ece-read-string "-0.5") -0.5)))

  (testing "symbols"
           ;; Reader interns into ECE package; compare by name
           (ok (string= (symbol-name (ece-read-string "hello")) "HELLO"))
           (ok (string= (symbol-name (ece-read-string "null?")) "NULL?"))
           (ok (string= (symbol-name (ece-read-string "set!")) "SET!"))
           (ok (string= (symbol-name (ece-read-string "list->vector")) "LIST->VECTOR"))
           ;; + and - are CL symbols, should still be eq
           (ok (eq (ece-read-string "+") '+))
           (ok (eq (ece-read-string "-") '-))
           ;; define is exported from ECE via :use
           (ok (eq (ece-read-string "define") 'define)))

  (testing "strings with escapes"
           (ok (equal (ece-read-string "\"hello\"") "hello"))
           (ok (equal (ece-read-string "\"a\\nb\"")
                      (coerce (list #\a #\Newline #\b) 'string)))
           (ok (equal (ece-read-string "\"a\\tb\"")
                      (coerce (list #\a #\Tab #\b) 'string)))
           (ok (equal (ece-read-string "\"say \\\"hi\\\"\"") "say \"hi\"")))

  (testing "string interpolation"
           (ok (equal (ece-read-string "\"plain\"") "plain"))
           ;; Interpolation produces (FMT ...) with ECE-package symbols
           (let ((result (ece-read-string "\"hello $name\"")))
             (ok (eq (car result) 'fmt))
             (ok (equal (cadr result) "hello "))
             (ok (string= (symbol-name (caddr result)) "NAME")))
           (let ((result (ece-read-string "\"val: $(+ 1 2)\"")))
             (ok (eq (car result) 'fmt))
             (ok (equal (cadr result) "val: "))
             (ok (= (length (caddr result)) 3)))  ; (+ 1 2)
           (ok (equal (ece-read-string "\"costs $$5\"") "costs $5")))

  (testing "lists"
           ;; Use evaluate to test lists round-trip through compilation
           (ok (equal (evaluate '(mc-compile-and-go
                                  (list 'quote (ece::ece-scheme-read
                                                (open-input-string "(1 2 3)")))))
                      '(1 2 3)))
           (ok (equal (ece-read-string "()") '()))
           ;; Verify list structure
           (let ((result (ece-read-string "(a b c)")))
             (ok (= (length result) 3))
             (ok (string= (symbol-name (car result)) "A"))))

  (testing "dotted pairs"
           (ok (equal (ece-read-string "(1 . 2)") '(1 . 2)))
           (let ((result (ece-read-string "(a . b)")))
             (ok (string= (symbol-name (car result)) "A"))
             (ok (string= (symbol-name (cdr result)) "B"))))

  (testing "quote"
           (let ((result (ece-read-string "'foo")))
             (ok (eq (car result) 'quote))
             (ok (string= (symbol-name (cadr result)) "FOO")))
           (let ((result (ece-read-string "'(1 2 3)")))
             (ok (eq (car result) 'quote))
             (ok (equal (cadr result) '(1 2 3)))))

  (testing "quasiquote, unquote, unquote-splicing"
           (let ((result (ece-read-string "`(a ,b)")))
             (ok (eq (car result) 'quasiquote))
             (let ((inner (cadr result)))
               (ok (string= (symbol-name (car inner)) "A"))
               (ok (eq (car (cadr inner)) 'unquote))))
           (let ((result (ece-read-string "`(a ,@b)")))
             (ok (eq (car result) 'quasiquote))
             (ok (eq (car (cadr (cadr result))) 'unquote-splicing))))

  (testing "character literals"
           (ok (char= (ece-read-string "#\\a") #\a))
           (ok (char= (ece-read-string "#\\space") #\Space))
           (ok (char= (ece-read-string "#\\newline") #\Newline))
           (ok (char= (ece-read-string "#\\tab") #\Tab)))

  (testing "vectors"
           (let ((v (ece-read-string "#(1 2 3)")))
             (ok (vectorp v))
             (ok (= (length v) 3))
             (ok (= (aref v 0) 1))
             (ok (= (aref v 2) 3))))

  (testing "hash table literals"
           (let ((ht (ece-read-string "{a 1 b 2}")))
             (ok (consp ht))
             (ok (eq (car ht) :hash-table))
             ;; Keys are in ECE package
             (ok (string= (symbol-name (caar (cdr ht))) "A"))
             (ok (= (cdar (cdr ht)) 1))))

  (testing "booleans"
           (ok (eq (ece-read-string "#t") t))
           (ok (eq (ece-read-string "#f") nil)))

  (testing "comments"
           (ok (= (ece-read-string "; comment
42") 42)))

  (testing "EOF"
           (ok (evaluate `(eof? (ece::ece-scheme-read (open-input-string "")))))
           ;; Read past last expression → EOF
           (let ((result (evaluate
                          '(begin
                            (define p (open-input-string "42"))
                            (ece::ece-scheme-read p)
                            (eof? (ece::ece-scheme-read p))))))
             (ok result))))

(defun run-repl (input-string)
  "Run the ECE REPL with INPUT-STRING as input, return captured output."
  (let ((ece::*current-input-port* (ece::ece-open-input-string input-string)))
    (with-output-to-string (*standard-output*)
      (ece:repl))))

(deftest test-repl
    (testing "simple integer expression"
             (let ((output (run-repl "42")))
               (ok (search "42" output))))

  (testing "arithmetic expression"
           (let ((output (run-repl "(+ 1 2)")))
             (ok (search "3" output))))

  (testing "multiple expressions"
           (let ((output (run-repl (format nil "1~%2~%3"))))
             (ok (search "1" output))
             (ok (search "2" output))
             (ok (search "3" output))
             ;; Should have multiple prompts
             (ok (> (count-substring "ece> " output) 1))))

  (testing "define variable"
           (let ((output (run-repl (format nil "(define repl-test-x 10)~%repl-test-x"))))
             (ok (search "10" output))))

  (testing "define function (crash regression)"
           (let ((output (run-repl (format nil "(define (repl-test-plus a b) (+ a b))~%(repl-test-plus 3 4)"))))
             (ok (search "REPL-TEST-PLUS" output))
             (ok (search "7" output))))

  (testing "error recovery"
           (let ((output (run-repl (format nil "repl-test-nonexistent-var-xyz~%(+ 100 200)"))))
             (ok (search "Error:" output))
             (ok (search "300" output))))

  (testing "string output"
           (let ((output (run-repl "\"hello\"")))
             (ok (search "\"hello\"" output))))

  (testing "boolean #t"
           (let ((output (run-repl "#t")))
             (ok (search "T" output))))

  (testing "lambda printing"
           (let ((output (run-repl "(lambda (x) x)")))
             (ok (search "procedure" output))))

  (testing "EOF goodbye"
           (let ((output (run-repl "42")))
             (ok (search "Bye!" output))))

  (testing "prompt displayed"
           (let ((output (run-repl "1")))
             (ok (search "ece> " output)))))

(defun count-substring (substr string)
  "Count occurrences of SUBSTR in STRING."
  (loop :with len = (length substr)
        :for i :from 0 :to (- (length string) len)
        :count (string= substr string :start2 i :end2 (+ i len))))

(deftest test-ece-assembler
    (testing "assemble and execute"
             ;; Compile an expression with ECE compiler, assemble with ECE assembler, execute
             (ok (= (evaluate '(mc-compile-and-go '(+ 1 2))) 3))
             (ok (= (evaluate '(mc-compile-and-go '(begin (define asm-test-x 99) asm-test-x))) 99)))

  (testing "round-trip: ECE reader + ECE compiler + ECE assembler"
           ;; Read with ECE reader, compile with ECE compiler, assemble with ECE assembler
           (ok (= (evaluate '(mc-compile-and-go
                              (ece::ece-scheme-read (open-input-string "(+ 10 20)")))) 30))
           ;; Full pipeline: load a file with ECE
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t :type "scm")
                            (write-string "(define round-trip-z 777)" s)
                            p)))
             (unwind-protect
                  (progn
                    (evaluate `(load ,(namestring tmpfile)))
                    (ok (= (evaluate (intern "ROUND-TRIP-Z" :ece)) 777)))
               (delete-file tmpfile)))))

(deftest test-eval
    (testing "eval literal"
             (ok (= (evaluate '(eval 42)) 42)))

  (testing "eval arithmetic"
           (ok (= (evaluate '(eval '(+ 1 2))) 3)))

  (testing "eval define"
           (ok (= (evaluate '(eval '(begin (define eval-test-var 99) eval-test-var))) 99)))

  (testing "eval lambda and call"
           (ok (= (evaluate '(eval '(begin (define (eval-test-fn x) (* x x))
                                     (eval-test-fn 5))))
                  25))))

(deftest test-self-hosted-macros
    (testing "simple user-defined macro expands correctly"
             (ok (= (evaluate '(begin
                                (define-macro (my-add a b) (list '+ a b))
                                (my-add 10 20)))
                    30)))

  (testing "macro using stdlib macros in body"
           (ok (= (evaluate '(begin
                              (define-macro (my-when-add c a b)
                               (list 'when c (list '+ a b)))
                              (my-when-add t 3 4)))
                  7)))

  (testing "lexical shadowing prevents macro expansion"
           (ok (= (evaluate '(begin
                              (define-macro (shadowed-mac x) (list '+ x 1))
                              ((lambda (shadowed-mac) (shadowed-mac 5))
                               (lambda (x) (* x 10)))))
                  50))))

;;;; ========================================================================
;;;; PARAMETER ROUND-TRIP TESTS
;;;; ========================================================================

(deftest test-parameter-round-trip
    (testing "parameter survives image save/load"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (evaluate '(define param-rt-test (make-parameter 42)))
                      (ok (= (evaluate '(param-rt-test)) 42))
                      (ece::ece-save-image (namestring tmpfile))
                      (ece::ece-load-image (namestring tmpfile))
                      ;; Parameter get should work after round-trip
                      (ok (= (evaluate '(param-rt-test)) 42))
                      ;; Parameter set should work after round-trip
                      (evaluate '(param-rt-test 99))
                      (ok (= (evaluate '(param-rt-test)) 99)))
                 (when (probe-file tmpfile) (delete-file tmpfile)))))

  (testing "parameterize works after image round-trip"
           (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                             :type "img")
                            (declare (ignore s))
                            p)))
             (unwind-protect
                  (progn
                    (evaluate '(define param-rt-dyn (make-parameter 10)))
                    (ece::ece-save-image (namestring tmpfile))
                    (ece::ece-load-image (namestring tmpfile))
                    ;; parameterize should work with restored parameter
                    (ok (= (evaluate '(parameterize ((param-rt-dyn 777))
                                       (param-rt-dyn)))
                           777))
                    ;; Original value restored after parameterize
                    (ok (= (evaluate '(param-rt-dyn)) 10)))
               (when (probe-file tmpfile) (delete-file tmpfile))))))

;;;; ========================================================================
;;;; IMAGE-BASED STARTUP TESTS
;;;; ========================================================================

(deftest test-image-startup
    (testing "mc-compile-and-go works after image load without compiler.lisp"
             (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                               :type "img")
                              (declare (ignore s))
                              p)))
               (unwind-protect
                    (progn
                      (ece::ece-save-image (namestring tmpfile))
                      ;; Simulate image-only startup by loading image into current state
                      (ece::ece-load-image (namestring tmpfile))
                      ;; Use mc-eval which goes through the ECE metacircular compiler
                      (ok (= (ece::mc-eval '(+ 1 2)) 3))
                      (ok (= (ece::mc-eval '(begin (define img-startup-test 42)
                                             img-startup-test))
                             42))
                      (ok (equal (ece::mc-eval '(map (lambda (x) (* x x))
                                                 (list 1 2 3)))
                                 '(1 4 9))))
                 (when (probe-file tmpfile) (delete-file tmpfile))))))
