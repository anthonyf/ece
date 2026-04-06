;;; Macro tests — define-macro, quasiquote, macro shadowing

(test "define-macro basic" (lambda ()
  (define-macro (my-const name) (list 'quote name))
  (assert-equal (my-const hello) 'hello)))

(test "macro with quasiquote" (lambda ()
  (define-macro (my-add a b) `(+ ,a ,b))
  (assert-equal (my-add 10 20) 30)))

(test "macro receives unevaluated operands" (lambda ()
  (define-macro (my-if test then) `(if ,test ,then))
  (assert-equal (my-if (= 1 1) 42) 42)))

(test "quasiquote basic" (lambda ()
  (assert-equal `(a b c) '(a b c))
  (assert-equal `hello 'hello)))

(test "unquote" (lambda ()
  (define x 42)
  (assert-equal `(a ,x c) '(a 42 c))
  (assert-equal `(result ,(+ 1 2)) '(result 3))))

(test "unquote-splicing" (lambda ()
  (define xs '(1 2 3))
  (assert-equal `(a ,@xs d) '(a 1 2 3 d))
  (define empty '())
  (assert-equal `(a ,@empty b) '(a b))))

(test "quote preserves structure" (lambda ()
  (assert-equal '(1 2 3) (list 1 2 3))
  (assert-equal 'a 'a)))

(test "lambda param shadows macro" (lambda ()
  ;; Using a name that could be a macro as a lambda parameter
  ;; should treat it as a variable, not expand as macro
  (define result
    ((lambda (loop) (loop loop 5))
     (lambda (self n) (if (= n 0) 0 (self self (- n 1))))))
  (assert-equal result 0)))
