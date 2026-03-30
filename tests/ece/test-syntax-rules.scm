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

;; assert-error requires try-eval which is CL-only
(when (platform-has? 'try-eval)
  (test "syntax-rules no matching clause signals error" (lambda ()
    (define-syntax only-two
      (syntax-rules ()
        ((_ a b) (list a b))))
    (assert-error (only-two 1)))))

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

(test "hygiene: pattern variable in operator position" (lambda ()
  ;; f is a pattern var — should be substituted, not wrapped
  (define-syntax apply1
    (syntax-rules ()
      ((_ f x) (f x))))
  (assert-equal (apply1 + 0) 0)
  (assert-equal (apply1 car '(1 2)) 1)
  (assert-equal (apply1 (lambda (x) (* x 2)) 5) 10)))

(test "hygiene: pattern var operator with use-site shadowing" (lambda ()
  ;; f comes from use site — should use use-site binding
  (define-syntax call-with
    (syntax-rules ()
      ((_ f x) (f x))))
  (let ((add1 (lambda (n) (+ n 1))))
    (assert-equal (call-with add1 5) 6))))

(test "hygiene: let macro in template works normally" (lambda ()
  ;; let in the template is a macro — it should expand correctly
  (let-syntax ((bind-and-add (syntax-rules ()
                                ((_ v e) (let ((x v)) (+ x e))))))
    (assert-equal (bind-and-add 3 4) 7))))

(test "hygiene: and/or macros in template" (lambda ()
  (let-syntax ((both? (syntax-rules ()
                         ((_ a b) (and a b)))))
    (assert-equal (both? 1 2) 2)
    (assert-equal (both? #f 2) #f))
  (let-syntax ((either? (syntax-rules ()
                           ((_ a b) (or a b)))))
    (assert-equal (either? #f 3) 3)
    (assert-equal (either? 1 2) 1))))

(test "hygiene: deeply nested operators all protected" (lambda ()
  (let-syntax ((deep (syntax-rules ()
                        ((_ a b c) (+ (* a b) (- c 1))))))
    (let ((+ -) (* +) (- *))
      ;; All three operators in the template should resolve globally
      (assert-equal (deep 3 4 5) 16)))))

(test "hygiene: macro calls macro preserves hygiene" (lambda ()
  ;; Inner macro's + should resolve globally even when outer shadows it
  (let-syntax ((dbl (syntax-rules ()
                       ((_ x) (+ x x)))))
    (let ((+ *))
      ;; dbl's + is hygienic — uses global +, not the shadow
      (assert-equal (dbl 5) 10)))))

(test "hygiene: letrec-syntax mutual reference" (lambda ()
  ;; letrec-syntax bindings can reference each other
  (letrec-syntax ((first (syntax-rules ()
                            ((_ a b) a)))
                  (second (syntax-rules ()
                             ((_ a b) (first b a)))))
    (assert-equal (first 1 2) 1)
    (assert-equal (second 1 2) 2))))

(test "hygiene: multiple clauses with different free operators" (lambda ()
  (let-syntax ((math-op (syntax-rules (add mul)
                           ((_ add a b) (+ a b))
                           ((_ mul a b) (* a b)))))
    (let ((+ -) (* /))
      (assert-equal (math-op add 3 1) 4)
      (assert-equal (math-op mul 6 2) 12)))))

(test "hygiene: template with only pattern vars (no free vars)" (lambda ()
  (define-syntax swap-pair
    (syntax-rules ()
      ((_ a b) (list b a))))
  (assert-equal (swap-pair 1 2) '(2 1))))

(test "hygiene: argument-position vars resolve at use site" (lambda ()
  ;; Known limitation: only operator position is protected.
  ;; Argument-position free vars resolve at the use site.
  (define-syntax get-op
    (syntax-rules ()
      ((_ x) (list + x))))
  ;; Without shadowing: + resolves to the global +
  (assert-equal (get-op 1) (list + 1))
  ;; With shadowing: + in argument position uses the shadow
  (let ((+ 42))
    (assert-equal (get-op 1) (list 42 1)))))

;; --- Quasiquote in templates ---

(test "hygiene: quasiquote preserves symbols as data" (lambda ()
  ;; Symbols inside quasiquote are data, not code — should not be wrapped
  (let-syntax ((make-expr (syntax-rules ()
                             ((_ n) (quasiquote (+ (unquote n) 1))))))
    (assert-equal (make-expr 3) '(+ 3 1)))))


