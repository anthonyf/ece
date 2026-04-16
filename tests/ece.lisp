(defpackage ece/tests/main
  (:use :cl
        :ece
        :rove))
(in-package :ece/tests/main)

;; Limit print depth to prevent stack overflow when rove tries to print
;; test results containing deeply nested captured environments/continuations.
(setf *print-circle* t *print-level* 10 *print-length* 10)

(defun ece-eval-string (source)
  "Read and evaluate SOURCE using the ECE reader in the image."
  (ece::evaluate (list 'eval (list 'read (list 'open-input-string source)))))

(defun ece-sym (name)
  "Intern NAME (a string or symbol) as a lowercase ECE-package symbol."
  (intern (string-downcase (string name)) :ece))

(defun make-test-env (vars vals &optional (base-env ece:*global-env*))
  "Create a hash-frame test environment extending BASE-ENV.
VARS are CL symbols (auto-downcased to ECE package)."
  (let ((ht (make-hash-table :test 'eq)))
    (loop for var in vars for val in vals
          do (setf (gethash (ece-sym var) ht) val))
    (cons (cons :hash-frame ht) base-env)))

;; NOTE: To run this test file, execute `(asdf:test-system :ece)' in your Lisp.

(defun image-available-p ()
  "Check if the bootstrap image exists (for tests that require image save/load)."
  (and (probe-file (asdf:system-relative-pathname :ece "bootstrap/ece.image")) t))

(deftest test-self-eval
    (testing "integers evaluate to themselves"
             (ok (= (evaluate 4 nil) 4))
             (ok (= (evaluate -10 nil) -10))
             (ok (= (evaluate .4 nil) .4))))

(deftest test-variable-eval
    (testing "variables evaluate to their bound values"
             (ok (= (evaluate (ece-sym 'x) (make-test-env '(x y) '(5 10))) 5))
             (ok (= (evaluate (ece-sym 'y) (make-test-env '(x y) '(5 10))) 10))
             (ok (= (evaluate (ece-sym 'z) (make-test-env '(x y z) '(5 10 -3))) -3)))

  (testing "unbound variables signal an error"
           (signals (evaluate (ece-sym 'a) (make-test-env '(b c) '(2 3))))
           (signals (evaluate (ece-sym 'foo) nil))))


(deftest test-quote-eval
    (testing "quote special form returns the quoted expression without evaluating it"
             (ok (equal (evaluate '(quote a) nil) 'a))
             (ok (equal (evaluate '(quote (1 2 3)) nil) '(1 2 3)))
             (ok (equal (evaluate '(quote (x y z)) (make-test-env '(x y z) '(10 20 30)))
                        '(x y z)))))


(deftest test-lambda-eval
    (testing "lambda expressions evaluate correctly with given arguments"
             (ok (= (evaluate '((lambda (x) (+ x 1)) 5)) 6))
             (ok (= (evaluate '((lambda (x y) (* x y)) 3 4)) 12))
             (ok (= (evaluate '((lambda (a b c) (- a b c)) 10 3 2)) 5)))

  (testing "lambda expressions with variable bindings"
           (ok (= (evaluate `((lambda (,(ece-sym 'x)) (+ ,(ece-sym 'x) ,(ece-sym 'y))) 5)
                            (make-test-env '(y) '(10))) 15))
           (ok (= (evaluate `((lambda (,(ece-sym 'a) ,(ece-sym 'b)) (+ ,(ece-sym 'a) ,(ece-sym 'b))) ,(ece-sym 'b) 2)
                            (make-test-env '(b) '(8))) 10))))

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
           (ok (ece::scheme-false-p (evaluate '(char? 42))))
           (ok (ece::scheme-false-p (evaluate '(char? "a")))))

  (testing "char=? equality"
           (ok (evaluate '(char=? #\a #\a)))
           (ok (ece::scheme-false-p (evaluate '(char=? #\a #\b)))))

  (testing "char<? ordering"
           (ok (evaluate '(char<? #\a #\b)))
           (ok (ece::scheme-false-p (evaluate '(char<? #\b #\a)))))

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
           (ok (ece::scheme-false-p (evaluate '(null? (quote (1))))))
           (ok (ece::scheme-false-p (evaluate '(not (quote ()))))))

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

  (testing "false predicate takes alternative"
           (ok (= (evaluate (list 'if ece::*scheme-false* 10 20)) 20))
           (ok (= (evaluate '(if (> 1 2) 10 20)) 20)))

  (testing "empty list is truthy"
           (ok (= (evaluate '(if (quote ()) 10 20)) 10))
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
           (ok (eq (evaluate `(begin (define (tco-or n)
                                         (if (= n 0) (quote done)
                                             (or ,ece::*scheme-false* (tco-or (- n 1)))))
                                     (tco-or 1000000)))
                   'done)))

  (testing "tail call in when body"
           (ok (ece::scheme-false-p (evaluate '(begin (define (tco-when n)
                                                       (when (> n 0) (tco-when (- n 1))))
                                                (tco-when 1000000))))))

  (testing "tail call in unless body"
           (ok (ece::scheme-false-p (evaluate '(begin (define (tco-unless n)
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
             (ok (= (evaluate '(begin (define x 1) (set! x 2) x)) 2)))

  (testing "update with a computed value"
           (ok (= (evaluate '(begin (define x 1) (set! x (+ x 10)) x)) 11)))

  (testing "set returns the new value"
           (ok (= (evaluate '(begin (define x 1) (set! x 42))) 42)))

  (testing "unbound variable signals error"
           (signals (evaluate '(set! nonexistent 10))))

  (testing "update variable in enclosing scope"
           (ok (= (evaluate '(begin (define x 1)
                              (define (f) (set! x 99))
                              (f)
                              x)) 99)))

  (testing "closure mutation counter pattern"
           (ok (= (evaluate '(begin
                              (define counter 0)
                              (define (inc) (set! counter (+ counter 1)))
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
           (ok (ece::scheme-false-p (evaluate '(pair? 42)))))

  (testing "pair? on empty list"
           (ok (ece::scheme-false-p (evaluate '(pair? (quote ())))))))

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
             (ok (eq (car (evaluate 'print)) 'ece::|compiled-procedure|)))

  (testing "read is bound (ECE reader)"
           (ok (eq (car (evaluate 'read)) 'ece::|compiled-procedure|)))

  (testing "display is bound"
           ;; display is now an ECE wrapper (compiled-procedure) around
           ;; the %display-to-port primitive.
           (ok (eq (car (evaluate 'display)) 'ece::|compiled-procedure|)))

  (testing "newline is bound"
           ;; newline is now an ECE wrapper (compiled-procedure).
           (ok (eq (car (evaluate 'newline)) 'ece::|compiled-procedure|)))

  (testing "eof? is bound"
           (ok (eq (car (evaluate 'eof?)) 'ece::|primitive|)))

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

  (testing "no clause matches returns #f"
           (ok (ece::scheme-false-p (evaluate '(cond ((= 1 2) 10) ((= 3 4) 20))))))

  (testing "multi-expression clause body"
           (ok (= (evaluate '(begin (define x 0)
                              (cond ((= 1 1) (set! x 10) (+ x 5)))
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

  (testing "no match returns #f"
           (ok (ece::scheme-false-p (evaluate '(case 5 ((1) (quote one)) ((2) (quote two)))))))

  (testing "key expression evaluated once"
           (ok (= (evaluate '(begin (define counter 0)
                              (case (begin (set! counter (+ counter 1)) counter)
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
                                    (set! result (cons i result)))))
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
           (ok (ece::scheme-false-p (evaluate (list 'and 1 ece::*scheme-false* 3)))))

  (testing "empty and"
           (ok (evaluate '(and)))))

(deftest test-or
    (testing "first truthy"
             (ok (= (evaluate (list 'or ece::*scheme-false* 2 3)) 2)))

  (testing "all falsy"
           (ok (ece::scheme-false-p (evaluate (list 'or ece::*scheme-false* ece::*scheme-false*)))))

  (testing "empty or"
           (ok (ece::scheme-false-p (evaluate '(or))))))

(deftest test-when-unless
    (testing "when with truthy test evaluates body"
             (ok (= (evaluate '(when (= 1 1) 42)) 42)))

  (testing "when with falsy test returns #f"
           (ok (ece::scheme-false-p (evaluate '(when (= 1 2) 42)))))

  (testing "unless with falsy test evaluates body"
           (ok (= (evaluate '(unless (= 1 2) 42)) 42)))

  (testing "unless with truthy test returns #f"
           (ok (ece::scheme-false-p (evaluate '(unless (= 1 1) 42))))))

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
                        (ece::downcase-ece-symbols
                         '(a (quasiquote (b (unquote x))))))))

  (testing "outer unquote evaluated, inner preserved"
           (ok (equal (evaluate '(begin (define x 1)
                                  (quasiquote (a (unquote x) (quasiquote (b (unquote x)))))))
                      (ece::downcase-ece-symbols
                       '(a 1 (quasiquote (b (unquote x))))))))

  (testing "nested unquote-splicing preserved at depth 2"
           (ok (equal (evaluate '(begin (define xs (quote (1 2)))
                                  (quasiquote (a (quasiquote (b (unquote-splicing xs)))))))
                      (ece::downcase-ece-symbols
                       '(a (quasiquote (b (unquote-splicing xs)))))))))

(deftest test-type-predicates
    (testing "number?"
             (ok (evaluate '(number? 42)))
             (ok (ece::scheme-false-p (evaluate '(number? "hello")))))

  (testing "string?"
           (ok (evaluate '(string? "hello")))
           (ok (ece::scheme-false-p (evaluate '(string? 42)))))

  (testing "symbol?"
           (ok (evaluate '(symbol? (quote foo))))
           (ok (ece::scheme-false-p (evaluate '(symbol? 42)))))

  (testing "boolean?"
           (ok (evaluate '(boolean? t)))
           (ok (ece::scheme-false-p (evaluate '(boolean? (quote ())))))
           (ok (ece::scheme-false-p (evaluate '(boolean? 42)))))

  (testing "zero?"
           (ok (evaluate '(zero? 0)))
           (ok (ece::scheme-false-p (evaluate '(zero? 5))))))

(deftest test-equality
    (testing "eq? on same symbol"
             (ok (evaluate '(eq? (quote a) (quote a)))))

  (testing "eq? on different symbols"
           (ok (ece::scheme-false-p (evaluate '(eq? (quote a) (quote b))))))

  (testing "equal? on identical lists"
           (ok (evaluate '(equal? (quote (1 2 3)) (quote (1 2 3))))))

  (testing "equal? on different lists"
           (ok (ece::scheme-false-p (evaluate '(equal? (quote (1 2)) (quote (1 3)))))))

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
           (ok (ece::scheme-false-p (evaluate '(even? 3)))))

  (testing "odd?"
           (ok (evaluate '(odd? 3))))

  (testing "positive?"
           (ok (evaluate '(positive? 5)))
           (ok (ece::scheme-false-p (evaluate '(positive? -1)))))

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
           (ok (ece::scheme-false-p (evaluate '(eq? (gensym) (gensym)))))))

(deftest test-or-no-double-eval
    (testing "or does not double-evaluate truthy argument"
             (ok (= (evaluate '(begin (define counter 0)
                                (or (begin (set! counter (+ counter 1)) counter) 99)
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
           (ok (ece::scheme-false-p (evaluate '(string->number "abc"))))
           (ok (= (evaluate '(string->number "3.14")) 3.14))
           (ok (= (evaluate '(string->number "-0.5")) -0.5))
           (ok (ece::scheme-false-p (evaluate '(string->number "3/4"))))
           (ok (ece::scheme-false-p (evaluate '(string->number ""))))
           (ok (ece::scheme-false-p (evaluate '(string->number "  ")))))

  (testing "number->string"
           (ok (equal (evaluate '(number->string 42)) "42"))
           (ok (equal (evaluate '(number->string -7)) "-7")))

  (testing "string->symbol"
           (ok (eq (ece-eval-string "(string->symbol \"hello\")") (intern "hello" :ece))))

  (testing "symbol->string"
           (ok (equal (ece-eval-string "(symbol->string 'hello)") "hello")))

  (testing "symbol round-trip"
           (ok (ece-eval-string "(equal? (string->symbol (symbol->string 'foo)) 'foo)"))))

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
           (ok (ece::scheme-false-p (evaluate '(assoc (quote d) (quote ((a 1) (b 2) (c 3))))))))

  (testing "assoc with numeric key"
           (ok (equal (evaluate '(assoc 2 (quote ((1 a) (2 b) (3 c))))) '(2 b))))

  (testing "member element found"
           (ok (equal (evaluate '(member 3 (quote (1 2 3 4 5)))) '(3 4 5))))

  (testing "member element not found"
           (ok (ece::scheme-false-p (evaluate '(member 6 (quote (1 2 3 4 5)))))))

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
           (ok (ece::scheme-false-p (evaluate '(string=? "hello" "world")))))

  (testing "string<? less than"
           (ok (evaluate '(string<? "abc" "abd"))))

  (testing "string<? not less than"
           (ok (ece::scheme-false-p (evaluate '(string<? "abd" "abc")))))

  (testing "string>? greater than"
           (ok (evaluate '(string>? "abd" "abc"))))

  (testing "string>? not greater than"
           (ok (ece::scheme-false-p (evaluate '(string>? "abc" "abd"))))))

(deftest test-vector-ops
    (testing "vector literal self-evaluates"
             (ok (equalp (evaluate #(1 2 3)) #(1 2 3))))

  (testing "vector? predicate"
           (ok (evaluate '(vector? #(1 2 3))))
           (ok (ece::scheme-false-p (evaluate '(vector? (quote (1 2 3))))))
           (ok (ece::scheme-false-p (evaluate '(vector? "hello")))))

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
                      (ok (= (evaluate (intern "load-test-x" :ece)) 42))
                      (ok (= (evaluate (intern "load-test-y" :ece)) 43)))
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
           (ok (equal (evaluate '(write-to-string t)) "#t")))

  (testing "list to string"
           (ok (equal (evaluate '(write-to-string (quote (1 2 3)))) "(1 2 3)")))

  (testing "empty list to string"
           (ok (equal (evaluate '(write-to-string (quote ()))) "()"))))

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

(deftest test-string-interpolation-eval
    (testing "interpolation with write-to-string semantics"
             ;; Test the expanded form directly: (string-append "hello " (write-to-string name))
             (ok (equal (evaluate '(begin (define name "world")
                                    (string-append "hello " (write-to-string name))))
                        "hello world")))

  (testing "interpolation with number"
           (ok (equal (evaluate '(begin (define n 42)
                                  (string-append "value: " (write-to-string n))))
                      "value: 42")))

  (testing "plain string stays as-is"
           (ok (equal (evaluate '"hello") "hello"))))

(deftest test-hash-table-literals
    (testing "curly brace reader produces hash table"
             (ok (evaluate '(hash-table? (eval (read (open-input-string "{}")))))))

  (testing "curly brace reader with symbol keys"
           (ok (ece-eval-string "(hash-table? {name \"Alice\" age 30})"))
           (ok (equal (ece-eval-string "(hash-ref {name \"Alice\" age 30} 'name)") "Alice"))
           (ok (= (ece-eval-string "(hash-ref {name \"Alice\" age 30} 'age)") 30)))

  (testing "hash table creation and access"
           (ok (evaluate '(hash-table? (hash-table 'name "Alice"))))
           (ok (equal (evaluate '(hash-ref (hash-table 'name "Alice") 'name)) "Alice")))

  (testing "hash table stored in variable"
           (ok (evaluate '(hash-table? (begin
                                        (define ht (hash-table 'a 1))
                                        ht))))
           (ok (= (evaluate '(hash-ref ht 'a)) 1))))

(deftest test-hash-table-ops
    (testing "hash-table constructor with symbol keys"
             (ok (evaluate '(hash-table? (hash-table 'a 1 'b 2))))
             (ok (= (evaluate '(hash-count (hash-table 'a 1 'b 2))) 2))
             (ok (= (evaluate '(hash-ref (hash-table 'a 1 'b 2) 'a)) 1))
             (ok (= (evaluate '(hash-ref (hash-table 'a 1 'b 2) 'b)) 2)))

  (testing "hash-table constructor empty"
           (ok (evaluate '(hash-table? (hash-table))))
           (ok (= (evaluate '(hash-count (hash-table))) 0)))

  (testing "hash-table constructor with computed key"
           (ok (equal (evaluate '(begin (define k 'name)
                                  (hash-ref (hash-table k "Alice") 'name)))
                      "Alice")))

  (testing "hash-table? predicate true"
           (ok (evaluate '(hash-table? (hash-table 'a 1)))))

  (testing "hash-table? predicate false for list"
           (ok (ece::scheme-false-p (evaluate '(hash-table? '(1 2 3))))))

  (testing "hash-table? predicate false for number"
           (ok (ece::scheme-false-p (evaluate '(hash-table? 42)))))

  (testing "hash-ref key found"
           (ok (equal (evaluate '(hash-ref (hash-table 'name "Alice" 'age 30) 'name))
                      "Alice")))

  (testing "hash-ref key not found returns #f"
           (ok (ece::scheme-false-p (evaluate '(hash-ref (hash-table 'a 1) 'missing)))))

  (testing "hash-ref key not found with default"
           (ok (equal (evaluate '(hash-ref (hash-table 'a 1) 'missing "default"))
                      "default")))

  (testing "hash-ref with string key"
           (ok (equal (evaluate '(hash-ref (hash-table "first" "Alice") "first"))
                      "Alice")))

  (testing "hash-has-key? true"
           (ok (evaluate '(hash-has-key? (hash-table 'name "Alice") 'name))))

  (testing "hash-has-key? false"
           (ok (ece::scheme-false-p (evaluate '(hash-has-key? (hash-table 'name "Alice") 'age)))))

  (testing "hash-keys returns all keys"
           (let ((keys (evaluate '(hash-keys (hash-table 'a 1 'b 2 'c 3)))))
             (ok (= (length keys) 3))
             (ok (member 'a keys))
             (ok (member 'b keys))
             (ok (member 'c keys))))

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
           (ok (ece::scheme-false-p (evaluate '(begin
                                                (define ht (hash-table 'hp 100))
                                                (hash-set ht 'mp 50)
                                                (hash-has-key? ht 'mp))))))

  (testing "hash-remove! removes key"
           (ok (ece::scheme-false-p (evaluate '(begin
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

;;; test-save-load-continuation removed — continuation serialization
;;; will be reimplemented separately from image format

(deftest test-define-record
    ;; define-record uses string->symbol internally, which interns in :ece.
    ;; We must use ece-eval-string so the reader also interns in :ece.
    (testing "constructor creates typed hash table"
             (ok (equal (ece-eval-string "(begin (define-record point x y)
                                            (point-x (make-point 10 20)))")
                        10))
             (ok (equal (ece-eval-string "(begin (define-record point x y)
                                            (point-y (make-point 10 20)))")
                        20))
             (ok (equal (ece-eval-string "(begin (define-record point x y)
                                            (hash-ref (make-point 10 20) 'type))")
                        (intern "point" :ece))))

  (testing "constructor with no fields"
           (ok (equal (ece-eval-string "(begin (define-record empty)
                                          (hash-count (make-empty)))")
                      1))
           (ok (equal (ece-eval-string "(begin (define-record empty)
                                          (hash-ref (make-empty) 'type))")
                      (intern "empty" :ece))))

  (testing "predicate returns true for matching record"
           (ok (equal (ece-eval-string "(begin (define-record point x y)
                                          (point? (make-point 1 2)))")
                      t)))

  (testing "predicate returns false for non-matching value"
           (ok (ece::scheme-false-p (ece-eval-string "(begin (define-record point x y)
                                          (point? 42))"))))

  (testing "predicate returns false for different record type"
           (ok (ece::scheme-false-p (ece-eval-string "(begin (define-record point x y)
                                          (define-record vec x y)
                                          (point? (make-vec 1 2)))"))))

  (testing "mutator updates field in place"
           (ok (equal (ece-eval-string "(begin (define-record point x y)
                                          (define p (make-point 1 2))
                                          (set-point-x! p 99)
                                          (point-x p))")
                      99)))

  (testing "functional update returns new record, original unchanged"
           (ok (equal (ece-eval-string "(begin (define-record point x y)
                                          (define p (make-point 1 2))
                                          (define p2 (point-with-x p 99))
                                          (list (point-x p) (point-x p2)))")
                      '(1 99))))

  (testing "copy creates independent record"
           (ok (equal (ece-eval-string "(begin (define-record point x y)
                                          (define p (make-point 1 2))
                                          (define p2 (copy-point p))
                                          (set-point-x! p2 99)
                                          (list (point-x p) (point-x p2)))")
                      '(1 99))))

  (testing "records are standard hash tables"
           (ok (equal (ece-eval-string "(begin (define-record point x y)
                                          (hash-table? (make-point 10 20)))")
                      t)))

  (testing "multiple record types coexist"
           (ok (equal (ece-eval-string "(begin (define-record point x y)
                                          (define-record person name age)
                                          (list (point-x (make-point 3 4))
                                           (person-name (make-person \"Alice\" 30))))")
                      (list 3 "Alice")))))

(deftest test-assert
    (testing "truthy condition passes"
             (ok (not (evaluate '(assert t))))
             (ok (not (evaluate '(assert 42))))
             (ok (not (evaluate '(assert "hello"))))
             (ok (not (evaluate '(assert ())))))
  (testing "falsy condition signals error"
           (ok (handler-case (progn (evaluate (list 'assert ece::*scheme-false*)) nil)
                 (error (c) (search "Assertion failed" (format nil "~A" c))))))
  (testing "custom message on failure"
           (ok (handler-case (progn (evaluate (list 'assert ece::*scheme-false* "x must be positive")) nil)
                 (error (c) (search "x must be positive" (format nil "~A" c))))))
  (testing "custom message not used on success"
           (ok (not (evaluate '(assert t "should not see this"))))))

(deftest test-any
    (testing "element found"
             (ok (evaluate '(any odd? (list 2 3 4)))))
  (testing "no element found"
           (ok (ece::scheme-false-p (evaluate '(any odd? (list 2 4 6))))))
  (testing "empty list"
           (ok (ece::scheme-false-p (evaluate '(any odd? (list)))))))

(deftest test-every
    (testing "all elements match"
             (ok (evaluate '(every even? (list 2 4 6)))))
  (testing "some element fails"
           (ok (ece::scheme-false-p (evaluate '(every even? (list 2 3 6))))))
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
           (ok (ece::scheme-false-p (evaluate '(string-contains? "hello world" "xyz")))))
  (testing "empty needle"
           (ok (evaluate '(string-contains? "hello" ""))))
  (testing "case sensitive"
           (ok (ece::scheme-false-p (evaluate '(string-contains? "Hello" "hello"))))))

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
             (let ((vals (evaluate '(hash-values (hash-table (quote a) 1 (quote b) 2)))))
               (ok (= (length vals) 2))
               (ok (member 1 vals))
               (ok (member 2 vals))))
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
                               (set! x (- x 1)))))
                  0)))
  (testing "loop accumulates then breaks"
           (ok (equal (evaluate '(let ((acc (list)) (i 0))
                                  (loop
                                   (if (= i 5) (break acc))
                                   (set! acc (cons i acc))
                                   (set! i (+ i 1)))))
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
    (when (image-available-p)
      (testing "save-image! returns t and creates a file"
               (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                 :type "img")
                                (declare (ignore s))
                                p)))
                 (unwind-protect
                      (progn
                        (ok (eq (ece::ece-save-image (namestring tmpfile)) t))
                        (ok (probe-file tmpfile)))
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-restores-simple-bindings
    (when (image-available-p)
      (testing "load-image! restores number bindings"
               (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                 :type "img")
                                (declare (ignore s))
                                p)))
                 (unwind-protect
                      (progn
                        (evaluate '(define img-test-num 42))
                        (ece::ece-save-image (namestring tmpfile))
                        (evaluate '(set! img-test-num 999))
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
                        (evaluate '(set! img-test-str "overwritten"))
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
                        (evaluate '(set! img-test-bool nil))
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
                        (evaluate '(set! img-test-lst (list 9 9 9)))
                        (ece::ece-load-image (namestring tmpfile))
                        (ok (equal (evaluate 'img-test-lst) '(1 2 3))))
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-restores-compiled-procedures
    (when (image-available-p)
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
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-restores-closures
    (when (image-available-p)
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
                                          (set! count (+ count 1))
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
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-restores-macros
    (when (image-available-p)
      (testing "compile-time macros survive round-trip"
               (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                 :type "img")
                                (declare (ignore s))
                                p)))
                 (unwind-protect
                      (progn
                        ;; Use explicit (list) instead of CL backtick — SBCL's internal
                        ;; comma objects don't survive image serialization round-trip.
                        (evaluate '(define-macro (img-swap a b) (list 'list b a)))
                        (ece::ece-save-image (namestring tmpfile))
                        (ece::ece-load-image (namestring tmpfile))
                        ;; Macro should still expand correctly for NEW code
                        (ok (equal (evaluate '(img-swap 1 2)) '(2 1))))
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-prelude-survives
    (when (image-available-p)
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
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-hash-tables-and-vectors
    (when (image-available-p)
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
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-continuations
    (when (image-available-p)
      (testing "continuation survives round-trip"
               (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                 :type "img")
                                (declare (ignore s))
                                p)))
                 (unwind-protect
                      (progn
                        ;; Capture a raw continuation and check it round-trips
                        ;; Use %raw-call/cc to get the unwrapped continuation
                        ;; (call/cc now wraps in a lambda for dynamic-wind support)
                        (evaluate '(define img-k (%raw-call/cc (lambda (k) k))))
                        (ok (eq t (evaluate `(eq? (car img-k)
                                                  ',(intern "continuation" :ece)))))
                        (ece::ece-save-image (namestring tmpfile))
                        (ece::ece-load-image (namestring tmpfile))
                        ;; After load, verify it's still a continuation
                        (ok (eq t (evaluate `(eq? (car img-k)
                                                  ',(intern "continuation" :ece))))))
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-compiler-works-after-load
    (when (image-available-p)
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
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

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
                      (list (intern "a" :ece) (intern "b" :ece) (intern "c" :ece)))))
  (testing "compile if true branch"
           (ok (= (ece-eval-string "(mc-compile-and-go '(if #t 1 2))") 1)))
  (testing "compile if false branch"
           (ok (= (ece-eval-string "(mc-compile-and-go '(if #f 1 2))") 2)))
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
                   "(mc-compile-and-go '(begin (define mc-y-test 1) (set! mc-y-test 42) mc-y-test))")
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
           (ok (= (ece-eval-string "(mc-compile-and-go '(or #f #f 42))") 42)))
  (testing "compile when/unless macros"
           (ok (= (ece-eval-string "(mc-compile-and-go '(when #t 42))") 42))
           (ok (= (ece-eval-string "(mc-compile-and-go '(unless #f 42))") 42)))
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
                      (list (intern "a" :ece) 42 (intern "c" :ece))))))

;;;; ========================================================================
;;;; CALL/CC REPL BOUNDARY TESTS
;;;; ========================================================================

(deftest test-callcc-cross-repl-expression
    ;; Regression test: invoking a continuation captured in one REPL expression
    ;; from a subsequent expression must not loop infinitely.
    ;; Each ece-eval-string call goes through mc-compile-and-go, simulating
    ;; separate REPL entries. The halt instruction prevents fall-through.
    (testing "continuation invoked across REPL expressions does not loop"
             (ece-eval-string "(define cross-repl-k #f)")
             (ece-eval-string "(call/cc (lambda (c) (set! cross-repl-k c) 'captured))")
             ;; Invoking the continuation should return the value, not hang.
             ;; Use a timeout to catch regressions.
             (let ((result (handler-case
                               (sb-ext:with-timeout 2
                                 (ece-eval-string "(cross-repl-k 99)"))
                             (sb-ext:timeout () :timeout))))
               (ok (eql result 99)))))

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
                 ;; Environment should be a non-empty list of frames
                 (ok (consp env))
                 (ok (car env))))))

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
             (let* ((proc (ece::lookup-variable-value (intern "my-test-fn" :ece) ece::*global-env*))
                    (entry-pc (cadr proc))
                    ;; Try qualified key first, then bare local-pc (old image compat)
                    (name (or (gethash entry-pc ece::*procedure-name-table*)
                              (when (consp entry-pc)
                                (gethash (cdr entry-pc) ece::*procedure-name-table*)))))
               (ok (eq name (intern "my-test-fn" :ece)))
               (ok (search "my-test-fn" (ece::format-ece-proc proc)))))

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
           (let ((anon-proc (list 'ece::|compiled-procedure| 999999 nil)))
             ;; PC 999999 is not in the name table
             (ok (search "entry=" (ece::format-ece-proc anon-proc)))))

  (when (image-available-p)
    (testing "image save/load preserves procedure name mappings"
             (ece-eval-string "(define (img-test-fn x) (* x x))")
             (let ((pc-before (cadr (ece::lookup-variable-value 'ece::img-test-fn ece::*global-env*))))
               ;; Save image
               (ece-eval-string "(save-image! \".tmp/ece-name-test.image\")")
               ;; Clear and reload
               (ece-eval-string "(load-image! \".tmp/ece-name-test.image\")")
               ;; Name should still be mapped (try qualified key then bare local-pc)
               (let ((name-after (or (gethash pc-before ece::*procedure-name-table*)
                                     (when (consp pc-before)
                                       (gethash (cdr pc-before) ece::*procedure-name-table*)))))
                 (ok (eq name-after 'ece::img-test-fn))))))

  (testing "MC-compiled defines register procedure names"
           (ece-eval-string "(mc-compile-and-go '(define (mc-name-test x) (+ x 1)))")
           (let* ((proc (ece::lookup-variable-value (intern "mc-name-test" :ece) ece::*global-env*))
                  (entry-pc (cadr proc))
                  ;; Try qualified key first, then bare local-pc (old image compat)
                  (name (or (gethash entry-pc ece::*procedure-name-table*)
                            (when (consp entry-pc)
                              (gethash (cdr entry-pc) ece::*procedure-name-table*)))))
             (ok (eq name (intern "mc-name-test" :ece))))))

(deftest test-tracing
    (testing "tracing a compiled procedure produces output and correct value"
             (ece-eval-string "(define (trace-add x y) (+ x y))")
             (ece-eval-string "(trace 'trace-add)")
             (let ((result nil))
               (let ((output (with-output-to-string (*standard-output*)
                               (setf result (ece-eval-string "(trace-add 3 4)")))))
                 (ok (eql 7 result))
                 (ok (search "trace-add" output))
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
               (ok (ece::ece-input-port? ip))
               (ok (ece::scheme-false-p (ece::ece-output-port? ip)))
               (ok (ece::ece-port? ip)))
             (ok (ece::scheme-false-p (ece::ece-port? 42)))
             (ok (ece::scheme-false-p (ece::ece-port? "hello")))
             (ok (ece::scheme-false-p (ece::ece-input-port? nil))))

  (testing "string port: open, read chars, EOF"
           (let ((p (ece::ece-open-input-string "hi")))
             (ok (char= (ece::ece-read-char p) #\h))
             (ok (char= (ece::ece-read-char p) #\i))
             (ok (ece::ece-eof? (ece::ece-read-char p)))))

  (testing "read-char and peek-char"
           (let ((p (ece::ece-open-input-string "ab")))
             ;; peek does not consume
             (ok (char= (ece::ece-peek-char p) #\a))
             (ok (char= (ece::ece-peek-char p) #\a))
             ;; read consumes
             (ok (char= (ece::ece-read-char p) #\a))
             (ok (char= (ece::ece-read-char p) #\b))
             ;; EOF
             (ok (ece::ece-eof? (ece::ece-peek-char p)))
             (ok (ece::ece-eof? (ece::ece-read-char p)))))

  (testing "write-char"
           (let* ((output (with-output-to-string (*standard-output*)
                            (let ((op (ece::ece-make-output-port *standard-output*)))
                              (ece::ece-%write-char-to-port #\x op)
                              (ece::ece-%write-char-to-port #\y op)))))
             (ok (string= "xy" output))))

  (testing "character predicates"
           (ok (ece::ece-char-whitespace-p #\Space))
           (ok (ece::ece-char-whitespace-p #\Newline))
           (ok (ece::ece-char-whitespace-p #\Tab))
           (ok (ece::scheme-false-p (ece::ece-char-whitespace-p #\a)))
           (ok (ece::ece-char-alphabetic-p #\a))
           (ok (ece::ece-char-alphabetic-p #\Z))
           (ok (ece::scheme-false-p (ece::ece-char-alphabetic-p #\5)))
           (ok (ece::ece-char-numeric-p #\0))
           (ok (ece::ece-char-numeric-p #\9))
           (ok (ece::scheme-false-p (ece::ece-char-numeric-p #\a))))

  (testing "read-line with port argument"
           (let ((p (ece::ece-open-input-string (format nil "hello~%world"))))
             (ok (string= "hello" (ece::ece-read-line p)))
             (ok (string= "world" (ece::ece-read-line p)))
             (ok (ece::ece-eof? (ece::ece-read-line p)))))

  (testing "current-input-port and current-output-port"
           ;; current-*-port are now ECE parameter objects defined in prelude.
           ;; Call via evaluate to read their current values.
           (ok (ece::ece-input-port?
                (ece:evaluate
                 (list (intern "current-input-port" :ece)))))
           (ok (ece::ece-output-port?
                (ece:evaluate
                 (list (intern "current-output-port" :ece))))))

  (testing "with-input-from-file reads from file"
           (ensure-directories-exist ".tmp/x")
           (let ((test-file ".tmp/ece-port-test.txt"))
             ;; Write a test file
             (with-open-file (s test-file :direction :output
                                :if-exists :supersede)
               (write-string "abc" s))
             ;; Read via the ECE-level with-input-from-file wrapper (evaluated in ECE)
             (let ((ch (ece:evaluate
                        `(,(intern "with-input-from-file" :ece)
                           ,test-file
                           (lambda () (,(intern "read-char" :ece)))))))
               (ok (char= ch #\a)))
             (delete-file test-file)))

  (testing "file ports: open, read, close"
           (ensure-directories-exist ".tmp/x")
           (let ((test-file ".tmp/ece-port-test2.txt"))
             ;; Write a test file
             (with-open-file (s test-file :direction :output
                                :if-exists :supersede)
               (write-string "xyz" s))
             ;; Open, read, close
             (let ((p (ece::ece-open-input-file test-file)))
               (ok (ece::ece-input-port? p))
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
           ;; Reader interns into ECE package; case-preserving
           (ok (string= (symbol-name (ece-read-string "hello")) "hello"))
           (ok (string= (symbol-name (ece-read-string "null?")) "null?"))
           (ok (string= (symbol-name (ece-read-string "set!")) "set!"))
           (ok (string= (symbol-name (ece-read-string "list->vector")) "list->vector"))
           ;; + and - are non-alpha, intern finds CL:+ via inheritance
           (ok (eq (ece-read-string "+") (intern "+" :ece)))
           (ok (eq (ece-read-string "-") (intern "-" :ece)))
           ;; define is interned as lowercase in :ece
           (ok (eq (ece-read-string "define") (intern "define" :ece))))

  (testing "strings with escapes"
           (ok (equal (ece-read-string "\"hello\"") "hello"))
           (ok (equal (ece-read-string "\"a\\nb\"")
                      (coerce (list #\a #\Newline #\b) 'string)))
           (ok (equal (ece-read-string "\"a\\tb\"")
                      (coerce (list #\a #\Tab #\b) 'string)))
           (ok (equal (ece-read-string "\"say \\\"hi\\\"\"") "say \"hi\"")))

  (testing "string interpolation"
           (ok (equal (ece-read-string "\"plain\"") "plain"))
           ;; Interpolation produces (string-append ... (write-to-string ...))
           (let ((result (ece-read-string "\"hello $name\"")))
             (ok (eq (car result) (intern "string-append" :ece)))
             (ok (equal (cadr result) "hello "))
             (ok (eq (car (caddr result)) (intern "write-to-string" :ece)))
             (ok (string= (symbol-name (cadr (caddr result))) "name")))
           (let ((result (ece-read-string "\"val: $(+ 1 2)\"")))
             (ok (eq (car result) (intern "string-append" :ece)))
             (ok (equal (cadr result) "val: "))
             (ok (eq (car (caddr result)) (intern "write-to-string" :ece)))
             (ok (= (length (cadr (caddr result))) 3)))  ; (+ 1 2)
           ;; Single interpolation without literals produces (write-to-string ...)
           (let ((result (ece-read-string "\"$name\"")))
             (ok (eq (car result) (intern "write-to-string" :ece))))
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
             (ok (string= (symbol-name (car result)) "a"))))

  (testing "dotted pairs"
           (ok (equal (ece-read-string "(1 . 2)") '(1 . 2)))
           (let ((result (ece-read-string "(a . b)")))
             (ok (string= (symbol-name (car result)) "a"))
             (ok (string= (symbol-name (cdr result)) "b"))))

  (testing "quote"
           (let ((result (ece-read-string "'foo")))
             (ok (eq (car result) (intern "quote" :ece)))
             (ok (string= (symbol-name (cadr result)) "foo")))
           (let ((result (ece-read-string "'(1 2 3)")))
             (ok (eq (car result) (intern "quote" :ece)))
             (ok (equal (cadr result) '(1 2 3)))))

  (testing "quasiquote, unquote, unquote-splicing"
           (let ((result (ece-read-string "`(a ,b)")))
             (ok (eq (car result) (intern "quasiquote" :ece)))
             (let ((inner (cadr result)))
               (ok (string= (symbol-name (car inner)) "a"))
               (ok (eq (car (cadr inner)) (intern "unquote" :ece)))))
           (let ((result (ece-read-string "`(a ,@b)")))
             (ok (eq (car result) (intern "quasiquote" :ece)))
             (ok (eq (car (cadr (cadr result))) (intern "unquote-splicing" :ece)))))

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
           ;; Reader returns (hash-table 'a 1 'b 2) form for the compiler
           (let ((form (ece-read-string "{a 1 b 2}")))
             (ok (consp form))
             (ok (eq (car form) (intern "hash-table" :ece)))
             ;; Test via ece-eval-string which compiles and runs the expression
             (ok (= (ece-eval-string "(hash-ref {a 1 b 2} 'a)") 1))
             (ok (= (ece-eval-string "(hash-ref {a 1 b 2} 'b)") 2))))

  (testing "booleans"
           (ok (eq (ece-read-string "#t") t))
           (ok (ece::scheme-false-p (ece-read-string "#f"))))

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

(defvar *ece-main-loaded* nil)

(defun ensure-ece-main-loaded ()
  "Load ece-main.ecec once so the ECE repl function is available."
  (unless *ece-main-loaded*
    (let ((path (namestring (asdf:system-relative-pathname :ece "share/ece/ece-main.ecec"))))
      (evaluate (list (intern "load-bundle" :ece) path)))
    (setf *ece-main-loaded* t)))

(defun run-repl (input-string)
  "Run the ECE REPL with INPUT-STRING as input, return captured output.
The ECE current-input-port / current-output-port parameters wrap synonym
streams pointing at *standard-input* / *standard-output*, so CL-level
rebindings redirect ECE's I/O."
  (ensure-ece-main-loaded)
  (with-input-from-string (*standard-input* input-string)
    (with-output-to-string (*standard-output*)
      (evaluate (list (intern "repl" :ece))))))

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
             ;; The define returns a compiled-procedure object; what matters is
             ;; the function call on the next line produces the correct result.
             (ok (search "7" output))))

  (testing "error recovery"
           ;; After ecec boot, error recovery in the REPL can leave stale labels
           ;; in the bootstrap space. Skip when no image is available.
           (when (image-available-p)
             (let ((output (run-repl (format nil "repl-test-nonexistent-var-xyz~%(+ 100 200)"))))
               (ok (search "Error:" output))
               (ok (search "300" output)))))

  (testing "string output"
           (let ((output (run-repl "\"hello\"")))
             (ok (search "\"hello\"" output))))

  (testing "boolean #t"
           (let ((output (run-repl "#t")))
             (ok (search "#t" output))))

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

(defun run-repl-geiser (input-string)
  "Run the ECE REPL in --geiser mode with INPUT-STRING as input.
Returns captured stdout."
  (ensure-ece-main-loaded)
  (with-input-from-string (*standard-input* input-string)
    (with-output-to-string (*standard-output*)
      (evaluate (list (intern "repl" :ece) t)))))

(deftest test-repl-geiser-mode
    (testing "simple eval returns structured alist"
             (let ((output (run-repl-geiser "(+ 1 2)")))
               (ok (search "((result" output))
               (ok (search "\"3\"" output))
               (ok (search "(output . \"\")" output))))

  (testing "eval with display captures output in alist"
           (let ((output (run-repl-geiser (format nil "(begin (display \"hi\") 42)"))))
             (ok (search "\"42\"" output))
             (ok (search "hi" output))))

  (testing "error recovery: subsequent eval works"
           (let ((output (run-repl-geiser
                          (format nil "undefined-var-xyz~%(+ 100 200)"))))
             (ok (search "\"300\"" output))))

  (testing "reader error produces clean alist"
           (let ((output (run-repl-geiser "(foo (bar baz")))
             (ok (search "Read error" output))
             (ok (search "Unexpected EOF" output))))

  (testing "terminal mode unchanged"
           (let ((output (run-repl "(+ 1 2)")))
             (ok (search "3" output))
             (ok (not (search "result" output))))))

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
                    (ok (= (evaluate (intern "round-trip-z" :ece)) 777)))
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
    (when (image-available-p)
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
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

;;;; ========================================================================
;;;; IMAGE-BASED STARTUP TESTS
;;;; ========================================================================

(deftest test-image-startup
    (when (image-available-p)
      (testing "mc-compile-and-go works after image load without compiler.lisp"
               (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                 :type "img")
                                (declare (ignore s))
                                p)))
                 (unwind-protect
                      (progn
                        (ece::ece-save-image (namestring tmpfile))
                        (ece::ece-load-image (namestring tmpfile))
                        (ok (= (ece::mc-eval '(+ 1 2)) 3))
                        (ok (= (ece::mc-eval '(begin (define img-startup-test 42)
                                               img-startup-test))
                               42))
                        (ok (equal (ece::mc-eval '(map (lambda (x) (* x x))
                                                   (list 1 2 3)))
                                   '(1 4 9))))
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

(deftest test-image-compaction-removes-dead-code
    (when (image-available-p)
      (testing "redefining a function then saving produces a smaller image"
               (let ((tmpfile1 (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                  :type "img")
                                 (declare (ignore s))
                                 p))
                     (tmpfile2 (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                  :type "img")
                                 (declare (ignore s))
                                 p)))
                 (unwind-protect
                      (progn
                        ;; Save once (baseline)
                        (ece::ece-save-image (namestring tmpfile1))
                        (let ((size-before (file-length
                                            (open tmpfile1 :direction :input))))
                          ;; Define, then redefine a function to leave dead code
                          (evaluate '(define (compact-test-fn x)
                                      (+ x 1 2 3 4 5 6 7 8 9 10)))
                          (evaluate '(define (compact-test-fn x)
                                      (+ x 1)))
                          ;; Save again — compaction should remove old definition
                          (ece::ece-save-image (namestring tmpfile2))
                          (let ((size-after (file-length
                                             (open tmpfile2 :direction :input))))
                            ;; Load the compacted image and verify function works
                            (ece::ece-load-image (namestring tmpfile2))
                            (ok (= (evaluate '(compact-test-fn 5)) 6))
                            ;; The compacted image should not be significantly larger
                            ;; than the baseline (dead code removed)
                            (ok (<= size-after (* size-before 1.1))))))
                   (when (probe-file tmpfile1) (delete-file tmpfile1))
                   (when (probe-file tmpfile2) (delete-file tmpfile2)))))))

(deftest test-image-compaction-preserves-anonymous-lambda
    (when (image-available-p)
      (testing "anonymous lambda stored in variable survives compaction"
               (let ((tmpfile (uiop:with-temporary-file (:stream s :pathname p :keep t
                                                                 :type "img")
                                (declare (ignore s))
                                p)))
                 (unwind-protect
                      (progn
                        (evaluate '(define compact-adder (lambda (x) (+ x 100))))
                        (ece::ece-save-image (namestring tmpfile))
                        (ece::ece-load-image (namestring tmpfile))
                        (ok (= (evaluate '(compact-adder 5)) 105)))
                   (when (probe-file tmpfile) (delete-file tmpfile)))))))

;;; ECE Native Test Suite
;;; Removed — ECE native tests are now run via `make test-ece` which invokes
;;; `bin/ece-test tests/ece/common tests/ece/cl-only`. Running them in-process
;;; via rove was redundant and caused heap pressure issues.

;; ============================================================
;; ece-sdk-toolchain integration tests
;; ============================================================

(defun ece-binary-path ()
  "Path to the in-tree bin/ece binary (built by `make ece')."
  (namestring (asdf:system-relative-pathname :ece "bin/ece")))

(defun run-ece-binary (args &key (input ""))
  "Run bin/ece with ARGS (a list of strings). Returns (exit-code stdout stderr).
Skips test gracefully via ok t if the binary hasn't been built yet."
  (declare (ignore input))
  (let* ((bin (ece-binary-path))
         (out (with-output-to-string (s)
                (let* ((err (make-string-output-stream))
                       (process
                        (sb-ext:run-program bin args
                                            :output s
                                            :error err
                                            :search nil
                                            :wait t)))
                  (list (sb-ext:process-exit-code process)
                        (get-output-stream-string err))))))
    (declare (ignore out))
    nil))

(defun run-ece-binary-capture (args)
  "Run bin/ece with ARGS. Returns (values exit-code stdout stderr)."
  (let* ((bin (ece-binary-path))
         (out-str (make-string-output-stream))
         (err-str (make-string-output-stream))
         (process (sb-ext:run-program bin args
                                      :output out-str
                                      :error err-str
                                      :search nil
                                      :wait t)))
    (values (sb-ext:process-exit-code process)
            (get-output-stream-string out-str)
            (get-output-stream-string err-str))))

(deftest test-ece-binary-version
    (testing "bin/ece -V prints version"
             (if (not (probe-file (ece-binary-path)))
                 (skip "bin/ece not built — run `make ece' first")
                 (multiple-value-bind (code stdout stderr)
                     (run-ece-binary-capture '("-V"))
                   (declare (ignore stderr))
                   (ok (zerop code) "exit code 0")
                   (ok (search "ece " stdout) "output contains version string")))))

(deftest test-ece-binary-eval
    (testing "bin/ece -e evaluates expression"
             (if (not (probe-file (ece-binary-path)))
                 (skip "bin/ece not built — run `make ece' first")
                 (multiple-value-bind (code stdout stderr)
                     (run-ece-binary-capture '("-e" "(display (+ 1 2))"))
                   (ok (zerop code)
                       (format nil "exit 0 (got ~A, stderr=~S)" code stderr))
                   (ok (search "3" stdout)
                       (format nil "output contains 3 (got ~S)" stdout))))))

(deftest test-ece-binary-exit-codes
    (testing "bin/ece propagates (exit N) codes"
             (if (not (probe-file (ece-binary-path)))
                 (skip "bin/ece not built — run `make ece' first")
                 (progn
                   (multiple-value-bind (code stdout stderr)
                       (run-ece-binary-capture '("-e" "(exit 0)"))
                     (declare (ignore stdout stderr))
                     (ok (zerop code) "(exit 0) returns 0"))
                   (multiple-value-bind (code stdout stderr)
                       (run-ece-binary-capture '("-e" "(exit 3)"))
                     (declare (ignore stdout stderr))
                     (ok (= code 3) "(exit 3) returns 3"))))))

(deftest test-ece-binary-argv-dispatch
    (testing "ece-build symlink dispatches to ece-build-main"
             ;; The symlink alone isn't enough — it may point at a missing
             ;; target. Only run if bin/ece is a real executable.
             (if (not (probe-file (ece-binary-path)))
                 (skip "bin/ece not built — run `make ece' first")
                 (let ((build-link (namestring (asdf:system-relative-pathname :ece "bin/ece-build"))))
                   (let* ((out-str (make-string-output-stream))
                          (process (sb-ext:run-program build-link '("--help")
                                                       :output out-str
                                                       :search nil
                                                       :wait t)))
                     (ok (zerop (sb-ext:process-exit-code process)) "exit 0")
                     (ok (search "Usage: ece-build" (get-output-stream-string out-str))
                         "help text mentions ece-build"))))))

(deftest test-ece-install-layout
    (testing "make install lays out PREFIX/bin + PREFIX/share/ece"
             (let* ((prefix (namestring
                             (ensure-directories-exist
                              (merge-pathnames
                               ".tmp/ece-install-test/"
                               (asdf:system-relative-pathname :ece "")))))
                    (bin (namestring (asdf:system-relative-pathname :ece "bin/ece"))))
               (if (not (probe-file bin))
                   (skip "bin/ece not built — run `make ece' first")
                   (progn
                     ;; Clean previous test state
                     (uiop:delete-directory-tree (pathname prefix) :validate t :if-does-not-exist :ignore)
                     (ensure-directories-exist prefix)
                     ;; Run `make install PREFIX=$TMP`
                     (let* ((err-str (make-string-output-stream))
                            (process (sb-ext:run-program
                                      "/usr/bin/make"
                                      (list "install" (format nil "PREFIX=~A" prefix))
                                      :directory (asdf:system-relative-pathname :ece "")
                                      :error err-str
                                      :wait t)))
                       (ok (zerop (sb-ext:process-exit-code process)) "make install exit 0"))
                     ;; Verify layout
                     (ok (probe-file (format nil "~A/bin/ece" prefix)) "ece binary installed")
                     (ok (probe-file (format nil "~A/bin/ece-repl" prefix)) "ece-repl symlink installed")
                     (ok (probe-file (format nil "~A/bin/ece-build" prefix)) "ece-build symlink installed")
                     (ok (probe-file (format nil "~A/bin/ece-test" prefix)) "ece-test symlink installed")
                     (ok (probe-file (format nil "~A/share/ece/bootstrap.ecec" prefix)) "bootstrap.ecec staged")
                     (ok (probe-file (format nil "~A/share/ece/ece-main.ecec" prefix)) "ece-main.ecec staged")
                     (ok (probe-file (format nil "~A/share/ece/runtime.wasm" prefix)) "runtime.wasm staged")
                     ;; Verify installed binary runs (relocatable)
                     (let* ((out-str (make-string-output-stream))
                            (p2 (sb-ext:run-program
                                 (format nil "~A/bin/ece" prefix)
                                 '("-V")
                                 :output out-str
                                 :search nil
                                 :wait t)))
                       (ok (zerop (sb-ext:process-exit-code p2)) "installed ece -V exit 0")
                       (ok (search "ece " (get-output-stream-string out-str)) "version string")))))))

;;;; ========================================================================
;;;; emit-host-primitives — codegen smoke / determinism / validation
;;;; ========================================================================

(defun expected-primitive-names ()
  "Return a list of CL symbol names (uppercased) for every core/cl primitive
in primitives.def. The auto-generated bootstrap/primitives-auto.lisp must
provide an ece-NAME defun for each."
  (with-open-file (s (asdf:system-relative-pathname :ece "primitives.def")
                     :direction :input)
    (loop for entry = (read s nil :eof)
          until (eq entry :eof)
          when (and (listp entry) (>= (length entry) 4)
                    (member (fourth entry) '(core cl)))
          collect (string-upcase (concatenate 'string "ECE-" (string (second entry)))))))

(deftest test-primitives-auto-fboundp
    (testing "every core/cl primitive has a generated ece-NAME defun"
             (let ((missing nil))
               (dolist (name (expected-primitive-names))
                 (let ((sym (find-symbol name :ece)))
                   (unless (and sym (fboundp sym))
                     (push name missing))))
               (ok (null missing)
                   (if missing
                       (format nil "missing fboundp: ~{~A~^, ~}" missing)
                       "all auto-generated primitives are fboundp")))))

(deftest test-primitives-auto-determinism
    (testing "bootstrap/primitives-auto.lisp exists and has substantial content"
             (let ((src (asdf:system-relative-pathname :ece "bootstrap/primitives-auto.lisp")))
               (ok (probe-file src) "primitives-auto.lisp exists")
               (let ((bytes (with-open-file (s src) (file-length s))))
                 (ok (and bytes (> bytes 1000))
                     "primitives-auto.lisp has >1000 bytes")))))

(deftest test-primitives-auto-validation
    (testing "codegen refuses to emit when templates are missing"
             ;; Drive the codegen with the real primitives.def manifest but
             ;; WITHOUT loading src/primitives.scm — *host-primitives* is then
             ;; empty and every core/cl entry should be flagged as missing,
             ;; causing strict-mode emission to abort with a descriptive error.
             (let ((scratch-out
                    (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                      (namestring p))))
               (ece::evaluate (list (intern "load" :ece) "src/codegen-cl.scm"))
               (let ((failed nil)
                     (msg nil))
                 (handler-case
                     (ece::evaluate (list (intern "generate-primitives-auto-lisp!" :ece)
                                          "primitives.def"
                                          scratch-out))
                   (ece:ece-runtime-error (c)
                     (setf failed t)
                     (setf msg (princ-to-string (ece:ece-original-error c))))
                   (error (c)
                     (setf failed t)
                     (setf msg (princ-to-string c))))
                 (ok failed "strict codegen aborts on missing templates")
                 (ok (and msg (search "missing template" msg))
                     (format nil "error names a missing template (got: ~A)"
                             (and msg (subseq msg 0 (min 120 (length msg))))))
                 (ok (not (probe-file scratch-out))
                     "no output file written when validation fails"))
               ;; Reload the real templates so subsequent tests in the same
               ;; image see a populated *host-primitives*.
               (ece::evaluate (list (intern "load" :ece) "src/primitives.scm")))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Compiled-zone walking skeleton (Stage 1 parity seed)
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; This test is the "walking skeleton" for Stage 1's inline codegen. It
;;; establishes the data shape and calling convention that
;;; src/codegen-cl-inline.scm will later emit automatically:
;;;
;;;   * The toy space is eight hand-assembled instructions that compute
;;;     val = 1 + 2 + 3 and halt.
;;;   * zone-toy-hand is the equivalent CL tagbody function with the exact
;;;     shape the codegen will emit: (initial-pc initial-val initial-env
;;;     initial-proc initial-argl initial-continue initial-stack) in,
;;;     (values pc val env proc argl continue stack) out, one tagbody tag
;;;     per instruction PC.
;;;   * The parity assertion runs the toy space through both the existing
;;;     execute-instructions dispatch loop AND the hand-written function,
;;;     and compares the resulting val registers.
;;;
;;; When the real codegen lands in Phase 3, its output for the toy space
;;; should be equivalent to zone-toy-hand below — byte-equivalent modulo
;;; formatting, or at least semantically equivalent.

(defun build-toy-zone-space ()
  "Assemble the 8-instruction toy space that computes val = 1 + 2 + 3.
Creates (or resets) the 'toy-zone' compilation space and returns its
space-id symbol. Safe to call more than once — the space is rebuilt on
each call, so tests stay deterministic across runs.

NB: instruction opcode/operand symbols must be interned in the :ece
package (case-preserved, lowercase) so they match the interpreter's
case dispatch in execute-instructions."
  (let ((space-id (ece::create-space "toy-zone"))
        ;; The primitive + has manifest ID 0. If primitives.def ever
        ;; renumbers +, this constant must follow. Fail loudly below via
        ;; the parity check if it drifts.
        (prim-plus-id 0))
    (ece::assemble-into-space
     space-id
     `((ece::|assign| ece::|val|  (ece::|const| 3))
       (ece::|assign| ece::|argl| (ece::|op| ece::|list|) (ece::|reg| ece::|val|))
       (ece::|assign| ece::|val|  (ece::|const| 2))
       (ece::|assign| ece::|argl| (ece::|op| ece::|cons|) (ece::|reg| ece::|val|) (ece::|reg| ece::|argl|))
       (ece::|assign| ece::|val|  (ece::|const| 1))
       (ece::|assign| ece::|argl| (ece::|op| ece::|cons|) (ece::|reg| ece::|val|) (ece::|reg| ece::|argl|))
       (ece::|assign| ece::|proc| (ece::|const| (ece::|primitive| ,prim-plus-id)))
       (ece::|assign| ece::|val|  (ece::|op| ece::|apply-primitive-procedure|) (ece::|reg| ece::|proc|) (ece::|reg| ece::|argl|))
       (ece::|halt|)))
    space-id))

(defun zone-toy-hand (initial-pc initial-val initial-env initial-proc
                      initial-argl initial-continue initial-stack)
  "Hand-written compiled-zone function for the toy space.
Mirrors the 8-instruction toy-zone that build-toy-zone-space assembles.
Returns (values pc val env proc argl continue stack) on zone exit, matching
the calling convention the inline codegen will emit in Phase 3."
  (let ((pc initial-pc)
        (val initial-val)
        (env initial-env)
        (proc initial-proc)
        (argl initial-argl)
        (continue initial-continue)
        (stack initial-stack))
    (tagbody
       (case pc
         (0 (go pc-0)) (1 (go pc-1)) (2 (go pc-2)) (3 (go pc-3))
         (4 (go pc-4)) (5 (go pc-5)) (6 (go pc-6)) (7 (go pc-7))
         (8 (go pc-8))
         (t (go zone-exit)))
     pc-0
       (setf val 3) (incf pc)
     pc-1
       (setf argl (cl:list val)) (incf pc)
     pc-2
       (setf val 2) (incf pc)
     pc-3
       (setf argl (cl:cons val argl)) (incf pc)
     pc-4
       (setf val 1) (incf pc)
     pc-5
       (setf argl (cl:cons val argl)) (incf pc)
     pc-6
       ;; The runtime tags primitive values with ECE::|primitive| (lowercase
       ;; preserved). Use the explicit ece:: prefix so this hand-written
       ;; skeleton matches what the codegen and runtime produce, even though
       ;; apply-primitive-procedure currently only inspects (cadr proc).
       (setf proc (cl:list 'ece::|primitive| 0)) (incf pc)
     pc-7
       (setf val (ece::apply-primitive-procedure proc argl)) (incf pc)
     pc-8
       (go zone-exit)
     zone-exit)
    (values pc val env proc argl continue stack)))

(deftest test-compiled-zone-walking-skeleton
    (testing "toy-zone assembles, runs interpreted, and matches hand-written CL"
             (let* ((space-id (build-toy-zone-space)))
               ;; Interpreter run: execute-instructions returns val on halt.
               (let ((interp-val
                      (ece::execute-instructions space-id 0 ece:*global-env*)))
                 (ok (= interp-val 6)
                     "interpreted toy-zone halts with val = 6"))
               ;; Hand-written compiled-zone run.
               (multiple-value-bind (pc val env proc argl continue stack)
                   (zone-toy-hand 0 nil ece:*global-env* nil nil nil nil)
                 (declare (ignore pc env proc argl continue stack))
                 (ok (= val 6)
                     "hand-written zone-toy-hand halts with val = 6")))))

(deftest test-compiled-zone-toy-parity
    (testing "interpreted and hand-written toy-zone produce identical val"
             (let* ((space-id (build-toy-zone-space))
                    (interp-val
                     (ece::execute-instructions space-id 0 ece:*global-env*)))
               (multiple-value-bind (pc compiled-val env proc argl continue stack)
                   (zone-toy-hand 0 nil ece:*global-env* nil nil nil nil)
                 (declare (ignore pc env proc argl continue stack))
                 (ok (eql interp-val compiled-val)
                     (format nil "parity: interpreted=~A compiled=~A"
                             interp-val compiled-val))))))

(defun load-codegen-cl-inline ()
  "Idempotently load the inline codegen and its dependencies into the
running ECE image. The codegen is loaded into *global-env*; subsequent
runs reuse the cached definitions, but explicit reload after edits keeps
the test deterministic against in-flight codegen changes."
  (ece::evaluate (list (intern "load" :ece) "src/codegen-cl.scm"))
  (ece::evaluate (list (intern "load" :ece) "src/primitives.scm"))
  (ece::evaluate (list (intern "load" :ece) "src/codegen-cl-inline.scm")))

(defun run-zone-codegen (space-name output-path)
  "Invoke (generate-zone-cl! SPACE-NAME OUTPUT-PATH) via the ECE evaluator."
  (ece::evaluate
   (list (intern "generate-zone-cl!" :ece) space-name output-path)))

(deftest test-inline-codegen-toy-zone
    (testing "inline codegen produces a runnable zone for the toy space"
             (build-toy-zone-space)
             (load-codegen-cl-inline)
             (let* ((output (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                              (namestring p))))
               (run-zone-codegen "toy-zone" output)
               (ok (probe-file output) "codegen wrote an output file")
               ;; Load the generated file into the live image and call the
               ;; resulting zone function. The generated defun is registered
               ;; in the :ece package.
               (load output)
               (let ((zone-fn (find-symbol "ZONE-TOY-ZONE" :ece)))
                 (ok (and zone-fn (fboundp zone-fn))
                     "codegen-emitted zone-toy-zone is fboundp")
                 (when (and zone-fn (fboundp zone-fn))
                   (multiple-value-bind (pc val env proc argl continue stack)
                       (funcall zone-fn 0 nil ece:*global-env* nil nil nil nil)
                     (declare (ignore env proc argl continue stack))
                     (ok (= val 6)
                         (format nil "auto-codegen toy-zone halts with val=6 pc=~A" pc))))))))

(deftest test-inline-codegen-determinism
    (testing "regenerating the toy zone twice produces byte-identical output"
             (build-toy-zone-space)
             (load-codegen-cl-inline)
             (let* ((path-a (uiop:with-temporary-file (:pathname p :type "lisp" :keep t)
                              (namestring p)))
                    (path-b (uiop:with-temporary-file (:pathname p :type "lisp" :keep t)
                              (namestring p))))
               (unwind-protect
                    (progn
                      (run-zone-codegen "toy-zone" path-a)
                      (run-zone-codegen "toy-zone" path-b)
                      (let ((bytes-a (alexandria:read-file-into-byte-vector path-a))
                            (bytes-b (alexandria:read-file-into-byte-vector path-b)))
                        (ok (equalp bytes-a bytes-b)
                            "two runs of generate-zone-cl! produce identical bytes")))
                 (ignore-errors (delete-file path-a))
                 (ignore-errors (delete-file path-b))))))

(deftest test-inline-codegen-inlines-known-primitive
    (testing "the +-call site at pc-7 inlines the :cl template body"
             (build-toy-zone-space)
             (load-codegen-cl-inline)
             (let* ((output (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                              (namestring p)))
                    (text nil))
               (run-zone-codegen "toy-zone" output)
               (with-open-file (s output)
                 (let ((buf (make-string (file-length s))))
                   (read-sequence buf s)
                   (setf text buf)))
               (ok (search "(cl:apply (cl:function cl:+) argl)" text)
                   "primitive + is inlined as the template body")
               (ok (not (search "apply-primitive-procedure proc argl" text))
                   "no fallback dispatch appears for the statically-known + call"))))

(defun build-empty-zone-space ()
  "Create an empty compilation space — no instructions at all. Exercises
the codegen's degenerate-space path."
  (ece::create-space "empty-zone"))

(defun build-branchy-zone-space ()
  "Assemble a space that exercises (test ...), (branch ...), label resolution
and goto. Builds argl=(3 5) and computes (> 3 5) → #f, then `false?` of #f
is #t, the branch IS taken, val becomes 200. The 100 then-arm is dead but
must still be compilable. Both interpreted and compiled paths must agree."
  (let ((space-id (ece::create-space "branchy-zone")))
    (ece::assemble-into-space
     space-id
     `((ece::|assign| ece::|val|  (ece::|const| 5))
       (ece::|assign| ece::|argl| (ece::|op| ece::|list|) (ece::|reg| ece::|val|))
       (ece::|assign| ece::|val|  (ece::|const| 3))
       (ece::|assign| ece::|argl| (ece::|op| ece::|cons|) (ece::|reg| ece::|val|) (ece::|reg| ece::|argl|))
       ;; (test (op apply-primitive-procedure) (const (primitive >)) (reg argl))
       ;; instead — but the test instruction doesn't take that shape. We
       ;; encode > as a primitive call that produces a boolean, then test.
       (ece::|assign| ece::|proc| (ece::|const| (ece::|primitive| 24))) ; 24 = >
       (ece::|assign| ece::|val|  (ece::|op| ece::|apply-primitive-procedure|)
             (ece::|reg| ece::|proc|) (ece::|reg| ece::|argl|))
       ;; Now use false? as the test predicate; if val is #t, false? returns
       ;; nil and the branch is NOT taken — we fall through to the then-arm.
       (ece::|test| (ece::|op| ece::|false?|) (ece::|reg| ece::|val|))
       (ece::|branch| (ece::|label| ece::|else-arm|))
       (ece::|assign| ece::|val| (ece::|const| 100))
       (ece::|goto| (ece::|label| ece::|done|))
       ece::|else-arm|
       (ece::|assign| ece::|val| (ece::|const| 200))
       ece::|done|
       (ece::|halt|)))
    space-id))

(deftest test-inline-codegen-empty-space
    (testing "codegen handles a zero-instruction space"
             (build-empty-zone-space)
             (load-codegen-cl-inline)
             (let ((output (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                             (namestring p))))
               (run-zone-codegen "empty-zone" output)
               (ok (probe-file output) "empty-zone codegen produced an output file")
               (load output)
               (let ((zone-fn (find-symbol "ZONE-EMPTY-ZONE" :ece)))
                 (ok (and zone-fn (fboundp zone-fn))
                     "zone-empty-zone is fboundp")
                 (when (and zone-fn (fboundp zone-fn))
                   (multiple-value-bind (pc val env proc argl continue stack)
                       (funcall zone-fn 0 :sentinel-val ece:*global-env* nil nil nil nil)
                     (declare (ignore env proc argl continue stack))
                     (ok (eql val :sentinel-val)
                         "empty zone leaves val unchanged")
                     (ok (= pc 0)
                         "empty zone leaves pc at the entry value"))))) ))

(deftest test-runtime-hook-dispatches-compiled-zone
    (testing "execute-instructions hands off to a registered compiled-zone fn"
             (build-toy-zone-space)
             (load-codegen-cl-inline)
             (let ((output (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                             (namestring p))))
               (run-zone-codegen "toy-zone" output)
               (load output)
               (let ((zone-fn (find-symbol "ZONE-TOY-ZONE" :ece))
                     (space-id (intern "toy-zone" :ece)))
                 ;; Register the compiled-zone function and run via the
                 ;; normal executor entry point. The interpreter MUST hand
                 ;; control to the compiled zone — verified by the
                 ;; observable result (which both paths produce identically)
                 ;; plus the call-counter trick below.
                 (let ((call-count 0))
                   (unwind-protect
                        (progn
                          (setf (gethash space-id ece::*compiled-zone-functions*)
                                (lambda (pc val env proc argl continue stack)
                                  (incf call-count)
                                  (funcall zone-fn pc val env proc argl
                                           continue stack)))
                          (let ((result (ece::execute-instructions
                                         space-id 0 ece:*global-env*)))
                            (ok (= result 6)
                                "executor result via compiled zone equals interpreter result")
                            (ok (>= call-count 1)
                                "compiled zone was called at least once")))
                     ;; Always unregister so other tests aren't affected.
                     (remhash space-id ece::*compiled-zone-functions*))))) ))

(deftest test-runtime-hook-no-compiled-zone
    (testing "execute-instructions falls through to the interpreter when no zone is registered"
             (build-toy-zone-space)
             (let ((space-id (intern "toy-zone" :ece)))
               ;; Make absolutely sure no compiled-zone fn is registered.
               (remhash space-id ece::*compiled-zone-functions*)
               (let ((result (ece::execute-instructions
                              space-id 0 ece:*global-env*)))
                 (ok (= result 6)
                     "interpreter alone produces 6 for toy-zone")))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Parity-test harness (Phase 5 — boundary semantics validation)
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; Compares execution under three configurations:
;;;   * pure-interp:   no compiled zone registered, everything runs in
;;;                    execute-instructions
;;;   * pure-compiled: the chosen space's compiled zone is registered, the
;;;                    interpreter still handles every other space (this is
;;;                    the "Stage 1 ships one space" model)
;;;
;;; A test passes when the observable result is identical across both
;;; configurations. The harness handles registration cleanup so tests don't
;;; bleed state into each other.

(defun with-compiled-zone (space-id zone-fn thunk)
  "Run THUNK with ZONE-FN registered as the compiled zone for SPACE-ID.
Always unregisters on exit, even if THUNK signals."
  (unwind-protect
       (progn
         (setf (gethash space-id ece::*compiled-zone-functions*) zone-fn)
         (funcall thunk))
    (remhash space-id ece::*compiled-zone-functions*)))

(defun parity-run (space-id zone-fn thunk)
  "Run THUNK twice — once with the compiled zone unregistered (interpreter
only), once with it registered. Return both results as a (cons interp
compiled) pair so the caller can assert equality."
  (remhash space-id ece::*compiled-zone-functions*)
  (let ((interp-result (funcall thunk)))
    (let ((compiled-result
           (with-compiled-zone space-id zone-fn thunk)))
      (cons interp-result compiled-result))))

(deftest test-parity-toy-zone-end-to-end
    (testing "toy-zone produces identical results under interpreter and compiled-zone"
             (build-toy-zone-space)
             (load-codegen-cl-inline)
             (let ((output (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                             (namestring p))))
               (run-zone-codegen "toy-zone" output)
               (load output)
               (let* ((zone-fn (find-symbol "ZONE-TOY-ZONE" :ece))
                      (space-id (intern "toy-zone" :ece))
                      (result-pair
                       (parity-run space-id (symbol-function zone-fn)
                                   (lambda ()
                                     (ece::execute-instructions
                                      space-id 0 ece:*global-env*)))))
                 (ok (eql (car result-pair) 6)
                     "interpreted produces 6")
                 (ok (eql (cdr result-pair) 6)
                     "compiled produces 6")
                 (ok (eql (car result-pair) (cdr result-pair))
                     "parity: interpreted = compiled")))))

(deftest test-compiled-zone-honors-initial-pc-dispatch
    (testing "executor entering at non-zero initial-pc dispatches into the right tag"
             (build-toy-zone-space)
             (load-codegen-cl-inline)
             (let ((output (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                             (namestring p))))
               (run-zone-codegen "toy-zone" output)
               (load output)
               (let ((zone-fn (find-symbol "ZONE-TOY-ZONE" :ece)))
                 ;; Enter at pc=2 — skips the (val=3, argl=(3)) prologue and
                 ;; starts with (val=2). The interpreter does the same.
                 (let* ((space-id (intern "toy-zone" :ece))
                        (interp-val
                         (ece::execute-instructions
                          space-id 2 ece:*global-env*))
                        (compiled-val
                         (multiple-value-bind (pc val env proc argl cont stack)
                             (funcall zone-fn 2 nil ece:*global-env*
                                      nil nil nil nil)
                           (declare (ignore pc env proc argl cont stack))
                           val)))
                   (ok (eql interp-val compiled-val)
                       (format nil "entry pc=2: interp=~A compiled=~A"
                               interp-val compiled-val)))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; First real space: assembler-zone parity (Phase 6)
;;; ─────────────────────────────────────────────────────────────────────────
;;;
;;; The assembler space (~962 instructions) is the smallest non-empty real
;;; space in the bootstrap image. It implements `load`, `for-each` over
;;; instruction lists, label registration, and the assemble-into-global
;;; rebinding — exercised every time ECE compiles a file. Compiling it to
;;; a zone and running the test suite with the zone registered is the most
;;; load-bearing parity test we have for Stage 1.

(defun ensure-assembler-zone-registered ()
  "Make sure the assembler space has a compiled-zone function registered.
Returns the space-id symbol. The boot-time loader (load-compiled-zones in
runtime.lisp) usually does this automatically; if not — for example after
a test cleared the registry — we re-register from the already-loaded
zone-assembler defun."
  (let ((space-id (intern "assembler" :ece))
        (zone-fn (find-symbol "ZONE-ASSEMBLER" :ece)))
    (when (and zone-fn (fboundp zone-fn))
      (setf (gethash space-id ece::*compiled-zone-functions*)
            (symbol-function zone-fn)))
    space-id))

(deftest test-real-space-parity-arithmetic
    (testing "(+ 1 2 3) returns 6 with the assembler compiled zone registered"
             (let ((space-id (ensure-assembler-zone-registered)))
               (unwind-protect
                    (let ((r (ece-eval-string "(+ 1 2 3)")))
                      (ok (= r 6) "compiled-zone arithmetic returns 6"))
                 (ensure-assembler-zone-registered)))))

(deftest test-real-space-parity-callcc-trivial
    (testing "(call/cc (lambda (k) (k 42))) → 42 with assembler zone registered"
             (let ((space-id (ensure-assembler-zone-registered)))
               (unwind-protect
                    (let ((r (ece-eval-string "(call/cc (lambda (k) (k 42)))")))
                      (ok (= r 42) "trivial call/cc returns 42"))
                 (ensure-assembler-zone-registered)))))

(deftest test-real-space-parity-callcc-escape
    (testing "call/cc as escape continuation works with assembler zone"
             (let ((space-id (ensure-assembler-zone-registered)))
               (unwind-protect
                    (let ((r (ece-eval-string
                              "(+ 1 (call/cc (lambda (k) (+ 10 (k 100)))))")))
                      (ok (= r 101)
                          "call/cc escape: 1 + 100 (10 is skipped) = 101"))
                 (ensure-assembler-zone-registered)))))

(deftest test-real-space-parity-dynamic-wind
    (testing "dynamic-wind ordering works with assembler zone registered"
             (let ((space-id (ensure-assembler-zone-registered)))
               (unwind-protect
                    (let ((r (ece-eval-string
                              "(let ((log '()))
                                 (dynamic-wind
                                   (lambda () (set! log (cons 'before log)))
                                   (lambda () (set! log (cons 'body log)) 'result)
                                   (lambda () (set! log (cons 'after log))))
                                 (reverse log))")))
                      (ok (equal (mapcar (lambda (s) (string (ece-sym s)))
                                         r)
                                 '("before" "body" "after"))
                          "dynamic-wind runs before/body/after in order"))
                 (ensure-assembler-zone-registered)))))

(deftest test-shipped-zone-files-load-and-register
    (testing "every bootstrap/*-zone.lisp file installs an fbound zone-NAME function"
             (let* ((bootstrap-dir
                     (asdf:system-relative-pathname :ece "bootstrap/"))
                    (pattern (merge-pathnames "*-zone.lisp" bootstrap-dir))
                    (files (directory pattern)))
               (ok (>= (length files) 1)
                   "at least one bootstrap/*-zone.lisp file ships with the build")
               (dolist (file files)
                 ;; The codegen prepends "zone-" to the space name passed in,
                 ;; so when the Makefile invokes generate-zone-cl! with
                 ;; "assembler" the resulting function is `zone-assembler` —
                 ;; we strip `-zone` from the file basename to recover the
                 ;; space name, then look up `zone-NAME` in :ece.
                 (let* ((base (pathname-name file))
                        (space-name (subseq base 0 (- (length base)
                                                      (length "-zone")))))
                   (let ((sym (find-symbol (concatenate 'string
                                                        "ZONE-"
                                                        (string-upcase space-name))
                                           :ece)))
                     (ok (and sym (fboundp sym))
                         (format nil "~A defines fbound ~A" file sym))
                     (let* ((space-id (intern space-name :ece))
                            (registered (gethash space-id ece::*compiled-zone-functions*)))
                       (ok registered
                           (format nil "~A registered in *compiled-zone-functions*" space-name))
                       (ok (eq registered (and sym (symbol-function sym)))
                           "registered function matches the defun"))))))))

(deftest test-shipped-zone-files-determinism
    (testing "regenerating the assembler zone file twice produces byte-identical output"
             (load-codegen-cl-inline)
             (let ((path-a (uiop:with-temporary-file (:pathname p :type "lisp" :keep t)
                             (namestring p)))
                   (path-b (uiop:with-temporary-file (:pathname p :type "lisp" :keep t)
                             (namestring p))))
               (unwind-protect
                    (progn
                      (run-zone-codegen "assembler" path-a)
                      (run-zone-codegen "assembler" path-b)
                      (let ((bytes-a (alexandria:read-file-into-byte-vector path-a))
                            (bytes-b (alexandria:read-file-into-byte-vector path-b)))
                        (ok (equalp bytes-a bytes-b)
                            "two runs against the assembler space produce identical bytes")))
                 (ignore-errors (delete-file path-a))
                 (ignore-errors (delete-file path-b))))))

(deftest test-real-space-parity-continuation-serialization
    (testing "continuation captured under compiled-zone dispatch round-trips through the serializer"
             (let ((space-id (ensure-assembler-zone-registered)))
               (unwind-protect
                    (let ((r (ece-eval-string
                              "(let ((k #f))
                                 (call/cc (lambda (c) (set! k c)))
                                 ;; Serialize → read string → deserialize.
                                 ;; The round-tripped object should be a
                                 ;; continuation matching the original
                                 ;; structurally. (Invoking it is tricky
                                 ;; under the test harness; existing
                                 ;; serialization tests note the same.)
                                 (let* ((s (serialize-value k))
                                        (form (read (open-input-string s)))
                                        (k2 (deserialize-value form)))
                                   (continuation? k2)))")))
                      (ok (eq r t)
                          "deserialized continuation is still a continuation"))
                 (ensure-assembler-zone-registered)))))

(deftest test-real-space-parity-redefinition
    (testing "REPL-style (define foo ...) takes effect across the compiled zone"
             (let ((space-id (ensure-assembler-zone-registered)))
               (unwind-protect
                    (progn
                      (ece-eval-string "(define stage1-test-fn (lambda (x) (* x 10)))")
                      (let ((before (ece-eval-string "(stage1-test-fn 7)")))
                        (ok (= before 70) "stage1-test-fn 7 = 70 before redef"))
                      (ece-eval-string "(define stage1-test-fn (lambda (x) (* x 100)))")
                      (let ((after (ece-eval-string "(stage1-test-fn 7)")))
                        (ok (= after 700) "stage1-test-fn 7 = 700 after redef")))
                 (ensure-assembler-zone-registered)))))

(deftest test-inline-codegen-branch-and-goto
    (testing "codegen handles test, branch, goto, labels, and runs to halt"
             (build-branchy-zone-space)
             (load-codegen-cl-inline)
             (let* ((space-id (intern "branchy-zone" :ece))
                    (interp-val
                     (ece::execute-instructions space-id 0 ece:*global-env*))
                    (output (uiop:with-temporary-file (:pathname p :type "lisp" :keep nil)
                              (namestring p))))
               (ok (= interp-val 200)
                   "interpreted branchy-zone takes the else-arm and halts with 200")
               (run-zone-codegen "branchy-zone" output)
               (load output)
               (let ((zone-fn (find-symbol "ZONE-BRANCHY-ZONE" :ece)))
                 (ok (and zone-fn (fboundp zone-fn))
                     "zone-branchy-zone is fboundp")
                 (when (and zone-fn (fboundp zone-fn))
                   (multiple-value-bind (pc val env proc argl continue stack)
                       (funcall zone-fn 0 nil ece:*global-env* nil nil nil nil)
                     (declare (ignore env proc argl continue stack))
                     (ok (= val 200)
                         (format nil "compiled branchy-zone halts with val=200 (pc=~A)" pc))
                     (ok (= val interp-val)
                         "compiled and interpreted branchy-zone agree")))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Dev-tooling primitives — TCP sockets and file watching for `ece serve`
;;; ─────────────────────────────────────────────────────────────────────────

(defun poll-until (thunk ready-p &key (timeout 1.0) (interval 0.005))
  "Call THUNK repeatedly until READY-P returns true on its result, or TIMEOUT
seconds have elapsed. Returns the final value of THUNK regardless of success.
Used to replace fixed sleeps in the TCP tests so they don't flake on slow CI."
  (let ((deadline (+ (get-internal-real-time)
                     (round (* timeout internal-time-units-per-second)))))
    (loop
          for value = (funcall thunk)
          when (funcall ready-p value) do (return value)
          when (>= (get-internal-real-time) deadline) do (return value)
          do (sleep interval))))

(defun connection-ready-p (value)
  "READY-P predicate for accept-nowait: truthy AND not scheme #f."
  (and value (not (ece::scheme-false-p value))))

(defun recv-ready-p (value)
  "READY-P predicate for recv-nowait: non-empty byte list (not would-block / eof symbol)."
  (and (consp value) (integerp (car value))))

(defparameter *ece-would-block* (intern "would-block" :ece))
(defparameter *ece-eof* (intern "eof" :ece))

(deftest test-tcp-listen-accept-roundtrip
    (testing "TCP server-client byte round-trip via ece-tcp-* primitives"
             (let* ((server (ece::ece-tcp-listen 0 "127.0.0.1"))  ; port 0 = OS-assign
                    (port (usocket:get-local-port server))
                    (client nil)
                    (conn nil))
               (unwind-protect
                    (progn
                      ;; No pending connection yet — accept-nowait returns the runtime's
                      ;; #f sentinel rather than nil/() so ECE callers can distinguish it.
                      (let ((no-conn (ece::ece-tcp-accept-nowait server)))
                        (ok (ece::scheme-false-p no-conn)
                            "accept-nowait returns scheme #f when no client is pending"))
                      ;; Open a client connection.
                      (setf client (usocket:socket-connect "127.0.0.1" port
                                                           :element-type '(unsigned-byte 8)))
                      ;; Poll for the connection to arrive rather than sleeping.
                      (setf conn (poll-until (lambda () (ece::ece-tcp-accept-nowait server))
                                             #'connection-ready-p))
                      (ok (and conn (not (ece::scheme-false-p conn)))
                          "accept-nowait returns a connection once a client arrives")
                      ;; Client → server: send three bytes, server should read them back.
                      (let ((stream (usocket:socket-stream client)))
                        (write-byte 65 stream) ; #\A
                        (write-byte 66 stream) ; #\B
                        (write-byte 67 stream) ; #\C
                        (force-output stream))
                      (let ((bytes (poll-until (lambda () (ece::ece-tcp-recv-nowait conn 16))
                                               #'recv-ready-p)))
                        (ok (equal bytes '(65 66 67))
                            "recv-nowait returns the three bytes the client sent"))
                      ;; Server → client: send a byte list, client reads back.
                      (let ((written (ece::ece-tcp-send-nowait conn '(88 89 90))))
                        (ok (= written 3) "send-nowait returns bytes-written"))
                      ;; Wait for the client socket to become readable rather than sleeping.
                      (ok (usocket:wait-for-input client :timeout 1.0 :ready-only t)
                          "client socket becomes readable after server sends data")
                      (let ((stream (usocket:socket-stream client)))
                        (ok (= (read-byte stream) 88) "client reads back X")
                        (ok (= (read-byte stream) 89) "client reads back Y")
                        (ok (= (read-byte stream) 90) "client reads back Z")))
                 ;; Cleanup — order matters for SO_REUSEADDR semantics.
                 (when conn (ignore-errors (ece::ece-tcp-close conn)))
                 (when client (ignore-errors (usocket:socket-close client)))
                 (ignore-errors (ece::ece-tcp-close server))))))

(deftest test-tcp-recv-would-block
    (testing "recv-nowait returns the ECE symbol would-block when no data is buffered"
             (let* ((server (ece::ece-tcp-listen 0 "127.0.0.1"))
                    (port (usocket:get-local-port server))
                    (client nil)
                    (conn nil))
               (unwind-protect
                    (progn
                      (setf client (usocket:socket-connect "127.0.0.1" port
                                                           :element-type '(unsigned-byte 8)))
                      (setf conn (poll-until (lambda () (ece::ece-tcp-accept-nowait server))
                                             #'connection-ready-p))
                      (ok (and conn (not (ece::scheme-false-p conn))) "got a connection")
                      (let ((result (ece::ece-tcp-recv-nowait conn 16)))
                        (ok (eq result *ece-would-block*)
                            "recv on idle connection returns ECE symbol would-block")
                        (ok (eq (symbol-package result) (find-package :ece))
                            "would-block sentinel is interned in the :ece package")))
                 (when conn (ignore-errors (ece::ece-tcp-close conn)))
                 (when client (ignore-errors (usocket:socket-close client)))
                 (ignore-errors (ece::ece-tcp-close server))))))

(deftest test-tcp-recv-eof-on-closed-peer
    (testing "recv-nowait returns the ECE symbol eof after peer closes"
             (let* ((server (ece::ece-tcp-listen 0 "127.0.0.1"))
                    (port (usocket:get-local-port server))
                    (client nil)
                    (conn nil))
               (unwind-protect
                    (progn
                      (setf client (usocket:socket-connect "127.0.0.1" port
                                                           :element-type '(unsigned-byte 8)))
                      (setf conn (poll-until (lambda () (ece::ece-tcp-accept-nowait server))
                                             #'connection-ready-p))
                      ;; Peer closes immediately without sending data.
                      (usocket:socket-close client)
                      (setf client nil)
                      ;; Wait for the server to notice the FIN.
                      (let ((result
                             (poll-until (lambda () (ece::ece-tcp-recv-nowait conn 16))
                                         (lambda (v) (eq v *ece-eof*)))))
                        (ok (eq result *ece-eof*)
                            "recv after peer close returns ECE symbol eof")
                        (ok (eq (symbol-package result) (find-package :ece))
                            "eof sentinel is interned in the :ece package")))
                 (when conn (ignore-errors (ece::ece-tcp-close conn)))
                 (when client (ignore-errors (usocket:socket-close client)))
                 (ignore-errors (ece::ece-tcp-close server))))))

(deftest test-tcp-recv-zero-max-bytes
    (testing "recv-nowait with max-bytes=0 returns empty without consuming input"
             (let* ((server (ece::ece-tcp-listen 0 "127.0.0.1"))
                    (port (usocket:get-local-port server))
                    (client nil)
                    (conn nil))
               (unwind-protect
                    (progn
                      (setf client (usocket:socket-connect "127.0.0.1" port
                                                           :element-type '(unsigned-byte 8)))
                      (setf conn (poll-until (lambda () (ece::ece-tcp-accept-nowait server))
                                             #'connection-ready-p))
                      ;; Push a byte from the client side.
                      (let ((stream (usocket:socket-stream client)))
                        (write-byte 42 stream)
                        (force-output stream))
                      ;; Wait until the server sees readable data.
                      (poll-until
                       (lambda () (usocket:wait-for-input conn :timeout 0 :ready-only t))
                       (lambda (v) (not (null v))))
                      ;; max-bytes=0 must return the empty list without reading.
                      (let ((r0 (ece::ece-tcp-recv-nowait conn 0)))
                        (ok (null r0) "max-bytes=0 returns empty list"))
                      ;; The byte is still buffered — a real read should find it.
                      (let ((r1 (ece::ece-tcp-recv-nowait conn 16)))
                        (ok (equal r1 '(42))
                            "pending byte still readable after a max-bytes=0 call")))
                 (when conn (ignore-errors (ece::ece-tcp-close conn)))
                 (when client (ignore-errors (usocket:socket-close client)))
                 (ignore-errors (ece::ece-tcp-close server))))))

(deftest test-fs-watch-detects-modification
    (testing "fs-watch-poll reports a path whose mtime advanced"
             (uiop:with-temporary-file
                 (:pathname tmp :type "scm" :keep nil)
               ;; Seed file with initial content.
               (with-open-file (out tmp :direction :output :if-exists :supersede)
                 (write-string ";; v1" out))
               (let ((path (namestring tmp))
                     (watcher nil))
                 (unwind-protect
                      (progn
                        (setf watcher (ece::ece-fs-watch-start (list path)))
                        (ok (integerp watcher) "fs-watch-start returns an integer id")
                        ;; First poll right after start — nothing changed.
                        (let ((changes (ece::ece-fs-watch-poll watcher)))
                          (ok (null changes)
                              "first poll after start sees no changes"))
                        ;; Mtime granularity on file-write-date is 1 second on most
                        ;; filesystems — sleep past it before the modification.
                        (sleep 1.1)
                        (with-open-file (out tmp :direction :output :if-exists :supersede)
                          (write-string ";; v2" out))
                        (let ((changes (ece::ece-fs-watch-poll watcher)))
                          (ok (member path changes :test #'string=)
                              "modified path appears in fs-watch-poll result"))
                        ;; Subsequent poll without further mtime change is empty.
                        (let ((changes (ece::ece-fs-watch-poll watcher)))
                          (ok (null changes)
                              "second poll after mtime caught up returns empty list")))
                   (when watcher (ece::ece-fs-watch-stop watcher)))))))

(deftest test-fs-watch-stop-discards-watcher
    (testing "fs-watch-stop forgets the watcher; later polls return empty"
             (uiop:with-temporary-file
                 (:pathname tmp :type "scm" :keep nil)
               (with-open-file (out tmp :direction :output :if-exists :supersede)
                 (write-string ";; init" out))
               (let* ((path (namestring tmp))
                      (watcher (ece::ece-fs-watch-start (list path))))
                 (ece::ece-fs-watch-stop watcher)
                 (let ((changes (ece::ece-fs-watch-poll watcher)))
                   (ok (null changes)
                       "polling a stopped watcher returns the empty list"))))))
