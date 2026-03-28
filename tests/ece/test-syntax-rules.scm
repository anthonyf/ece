;;; Tests for syntax-rules and define-syntax

;; --- Single/multi-clause matching ---

(test "syntax-rules single clause" (lambda ()
  (define-syntax my-const
    (syntax-rules ()
      ((_ x) (quote x))))
  (assert-equal (my-const hello) 'hello)))

(test "syntax-rules multi-clause selects first match" (lambda ()
  (define-syntax my-if
    (syntax-rules ()
      ((_ test then) (cond (test then)))
      ((_ test then else-branch) (cond (test then) (#t else-branch)))))
  (assert-equal (my-if #t 42) 42)
  (assert-equal (my-if #f 42 99) 99)))

;; --- Underscore wildcard ---

(test "syntax-rules underscore wildcard" (lambda ()
  (define-syntax second
    (syntax-rules ()
      ((_ _ x) x)))
  (assert-equal (second 1 2) 2)))

;; --- Literal identifier matching ---

(test "syntax-rules literal keyword matching" (lambda ()
  (define-syntax my-arrow
    (syntax-rules (=>)
      ((_ x => y) (list y x))))
  (assert-equal (my-arrow 1 => 2) '(2 1))))

(test "syntax-rules literal mismatch falls through" (lambda ()
  (define-syntax my-arrow
    (syntax-rules (=>)
      ((_ x => y) (list y x))
      ((_ x y) (list x y))))
  (assert-equal (my-arrow 1 2) '(1 2))))

;; --- Ellipsis ---

(test "syntax-rules ellipsis zero elements" (lambda ()
  (define-syntax my-list
    (syntax-rules ()
      ((_ x ...) (list x ...))))
  (assert-equal (my-list) '())))

(test "syntax-rules ellipsis multiple elements" (lambda ()
  (define-syntax my-list
    (syntax-rules ()
      ((_ x ...) (list x ...))))
  (assert-equal (my-list 1 2 3) '(1 2 3))))

(test "syntax-rules ellipsis with fixed prefix" (lambda ()
  (define-syntax my-cons*
    (syntax-rules ()
      ((_ first rest ...) (cons first (list rest ...)))))
  (assert-equal (my-cons* 1 2 3) '(1 2 3))))

;; --- Hygiene ---

(test "syntax-rules hygiene: introduced temp does not capture" (lambda ()
  (define-syntax my-swap!
    (syntax-rules ()
      ((_ a b)
       (let ((temp a)) (set! a b) (set! b temp)))))
  (define temp 10)
  (define y 20)
  (my-swap! temp y)
  (assert-equal (list temp y) '(20 10))))

;; --- Sub-list patterns ---

(test "syntax-rules nested list pattern" (lambda ()
  (define-syntax my-let1
    (syntax-rules ()
      ((_ (var val) body) ((lambda (var) body) val))))
  (assert-equal (my-let1 (x 5) (+ x 1)) 6)))

;; --- No matching clause ---

(test "syntax-rules no matching clause signals error" (lambda ()
  (define-syntax only-two
    (syntax-rules ()
      ((_ a b) (list a b))))
  (assert-error (only-two 1))))

;; --- define-syntax coexists with define-macro ---

(test "define-syntax and define-macro coexist" (lambda ()
  (define-macro (dm-add a b) (list '+ a b))
  (define-syntax sr-add
    (syntax-rules ()
      ((_ a b) (+ a b))))
  (assert-equal (+ (dm-add 1 2) (sr-add 3 4)) 10)))

;; --- Lexical shadowing ---

(test "lambda parameter shadows define-syntax macro" (lambda ()
  (define-syntax foo
    (syntax-rules ()
      ((_ x) (+ x 1))))
  (assert-equal ((lambda (foo) foo) 42) 42)))

;; --- Compile-time availability ---

(test "define-syntax macro usable in same unit" (lambda ()
  (define-syntax double
    (syntax-rules ()
      ((_ x) (+ x x))))
  (assert-equal (double 21) 42)))

;; --- define-syntax with body ellipsis (my-when pattern) ---

(test "define-syntax with body ellipsis" (lambda ()
  (define-syntax my-when
    (syntax-rules ()
      ((_ test body ...)
       (if test (begin body ...)))))
  (assert-equal (my-when #t 42) 42)
  (assert-equal (my-when #f 42) #f)))

;; --- Operator-position hygiene (%global-ref) ---

(test "hygiene: shadowed + in operator position" (lambda ()
  (let-syntax ((add1 (syntax-rules ()
                        ((_ e) (+ e 1)))))
    (let ((+ *))
      (assert-equal (add1 3) 4)))))

(test "hygiene: shadowed cons in operator position" (lambda ()
  (let-syntax ((my-pair (syntax-rules ()
                          ((_ a b) (cons a b)))))
    (let ((cons list))
      (assert-equal (my-pair 1 2) '(1 . 2))))))

(test "hygiene: shadowed - in operator position" (lambda ()
  (let-syntax ((sub1 (syntax-rules ()
                        ((_ e) (- e 1)))))
    (let ((- +))
      (assert-equal (sub1 10) 9)))))

(test "hygiene: multiple free operators in template" (lambda ()
  (let-syntax ((math (syntax-rules ()
                        ((_ a b) (+ (* a b) 1)))))
    (let ((+ -) (* /))
      (assert-equal (math 3 4) 13)))))

(test "hygiene: operator hygiene with ellipsis" (lambda ()
  (let-syntax ((add-all (syntax-rules ()
                           ((_ x ...) (+ x ...)))))
    (let ((+ *))
      (assert-equal (add-all 1 2 3) 6)))))

(test "hygiene: quote not affected by wrapping" (lambda ()
  (define-syntax my-quote
    (syntax-rules ()
      ((_ x) (quote x))))
  (assert-equal (my-quote hello) 'hello)
  (assert-equal (my-quote (a b c)) '(a b c))))

(test "hygiene: lambda params not broken by wrapping" (lambda ()
  (define-syntax my-let1
    (syntax-rules ()
      ((_ (var val) body) ((lambda (var) body) val))))
  (assert-equal (my-let1 (x 5) (+ x 1)) 6)))

(test "hygiene: set! in template works" (lambda ()
  (define counter 0)
  (let-syntax ((inc! (syntax-rules ()
                        ((_) (set! counter (+ counter 1))))))
    (inc!)
    (inc!)
    (assert-equal counter 2))))

(test "hygiene: nested let-syntax preserves lexical refs" (lambda ()
  (let ((x 1))
    (let-syntax ((foo (syntax-rules ()
                        ((_ y) (let-syntax
                                    ((bar (syntax-rules ()
                                            ((_) (let ((x 2)) y)))))
                                  (bar))))))
      (assert-equal (foo x) 1)))))

(test "hygiene: cond with else in template" (lambda ()
  (let-syntax ((safe-div (syntax-rules ()
                            ((_ a b) (cond ((= b 0) 0)
                                           (else (/ a b)))))))
    (assert-equal (safe-div 10 2) 5)
    (assert-equal (safe-div 10 0) 0))))

(test "hygiene: define-syntax macro with if in template" (lambda ()
  (define-syntax my-abs
    (syntax-rules ()
      ((_ x) (if (< x 0) (- 0 x) x))))
  (assert-equal (my-abs 5) 5)
  (assert-equal (my-abs -3) 3)))
