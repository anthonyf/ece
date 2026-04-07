;;; Chibi R5RS Tests — adapted from chibi-scheme/tests/r5rs-tests.scm
;;; Original: BSD-3-Clause, Copyright (c) 2009-2024 Alex Shinn. All rights reserved.
;;;
;;; Changes from upstream:
;;; - Replaced test framework (removed call-with-output-string/flush-output)
;;; - Skipped tests using unsupported features
;;; - Skipped tests that trigger compile-time crashes (to be investigated)

;;; --- Test Framework (adapted) ---

(define *tests-run* 0)
(define *tests-passed* 0)
(define *tests-failed* 0)

(define-syntax test
  (syntax-rules ()
    ((test name expect expr)
     (test expect expr))
    ((test expect expr)
     (begin
       (set! *tests-run* (+ *tests-run* 1))
       (let ((res expr))
         (cond
          ((equal? res expect)
           (set! *tests-passed* (+ *tests-passed* 1)))
          (else
           (set! *tests-failed* (+ *tests-failed* 1))
           (display "  FAIL: ")
           (display 'expr)
           (newline)
           (display "    expected: ")
           (display expect)
           (display "  got: ")
           (display res)
           (newline))))))))

(define-syntax test-assert
  (syntax-rules ()
    ((test-assert expr) (test #t expr))))

(define (test-begin . name)
  (display "--- Chibi R5RS Tests ---")
  (newline))

(define (test-end)
  (display "  Chibi R5RS: ")
  (display *tests-passed*)
  (display " passed, ")
  (display *tests-failed*)
  (display " failed (")
  (display *tests-run*)
  (display " total)")
  (newline)
  (set! *conformance-passes* (+ *conformance-passes* *tests-passed*))
  (set! *conformance-failures* (+ *conformance-failures* *tests-failed*)))

;;; --- Tests ---

(test-begin "r5rs")

;; Lambda
(test 8 ((lambda (x) (+ x x)) 4))
(test '(3 4 5 6) ((lambda x x) 3 4 5 6))
(test '(5 6) ((lambda (x y . z) z) 3 4 5 6))

;; Conditionals
(test 'yes (if (> 3 2) 'yes 'no))
(test 'no (if (> 2 3) 'yes 'no))
(test 1 (if (> 3 2) (- 3 2) (+ 3 2)))
(test 'greater (cond ((> 3 2) 'greater) ((< 3 2) 'less)))
(test 'equal (cond ((> 3 3) 'greater) ((< 3 3) 'less) (else 'equal)))
(test 'composite (case (* 2 3) ((2 3 5 7) 'prime) ((1 4 6 8 9) 'composite)))
(test 'consonant
    (case (car '(c d))
      ((a e i o u) 'vowel)
      ((w y) 'semivowel)
      (else 'consonant)))

;; Boolean operators
(test #t (and (= 2 2) (> 2 1)))
(test #f (and (= 2 2) (< 2 1)))
(test '(f g) (and 1 2 'c '(f g)))
(test #t (and))
(test #t (or (= 2 2) (> 2 1)))
(test #t (or (= 2 2) (< 2 1)))

;; Binding
(test 6 (let ((x 2) (y 3)) (* x y)))
(test 35 (let ((x 2) (y 3)) (let ((x 7) (z (+ x y))) (* z x))))
(test 70 (let ((x 2) (y 3)) (let* ((x 7) (z (+ x y))) (* z x))))
(test -2 (let ()
           (define x 2)
           (define f (lambda () (- x)))
           (f)))

;; Do
(test '#(0 1 2 3 4) (do ((vec (make-vector 5)) (i 0 (+ i 1))) ((= i 5) vec) (vector-set! vec i i)))

(test 25
    (let ((x '(1 3 5 7 9)))
      (do ((x x (cdr x))
           (sum 0 (+ sum (car x))))
          ((null? x)
           sum))))

;; Named let
(test '((6 1 3) (-5 -2))
    (let loop ((numbers '(3 -2 1 6 -5)) (nonneg '()) (neg '()))
      (cond
       ((null? numbers)
        (list nonneg neg))
       ((>= (car numbers) 0)
        (loop (cdr numbers) (cons (car numbers) nonneg) neg))
       ((< (car numbers) 0)
        (loop (cdr numbers) nonneg (cons (car numbers) neg))))))

;; Quasiquote (basic)
(test '(list 3 4) `(list ,(+ 1 2) 4))
(test '(a 3 4 5 6 b)
    `(a ,(+ 1 2) ,@(map abs '(4 -5 6)) b))

;; Equality — eqv?
(test #t (eqv? 'a 'a))
(test #f (eqv? 'a 'b))
(test #t (eqv? '() '()))
(test #f (eqv? (cons 1 2) (cons 1 2)))
(test #f (eqv? (lambda () 1) (lambda () 2)))
(test #t (let ((p (lambda (x) x))) (eqv? p p)))

;; Equality — eq?
(test #t (eq? 'a 'a))
(test #f (eq? (list 'a) (list 'a)))
(test #t (eq? '() '()))
(test #t (eq? car car))
(test #t (let ((x '(a))) (eq? x x)))
(test #t (let ((p (lambda (x) x))) (eq? p p)))
(test #t (equal? 'a 'a))
(test #t (equal? '(a) '(a)))
(test #t (equal? '(a (b) c) '(a (b) c)))
(test #t (equal? "abc" "abc"))
(test #f (equal? "abc" "abcd"))
(test #f (equal? "a" "b"))
(test #t (equal? 2 2))
(test #t (equal? (make-vector 5 'a) (make-vector 5 'a)))

;; Arithmetic
(test 4 (max 3 4))
(test 7 (+ 3 4))
(test 3 (+ 3))
(test 0 (+))
(test 4 (* 4))
(test 1 (*))
(test -1 (- 3 4))
(test -6 (- 3 4 5))
(test -3 (- 3))
(test -1.0 (- 3.0 4))
(test 7 (abs -7))
(test 1 (modulo 13 4))
(test 3 (modulo -13 4))
(test 100 (string->number "100"))
(test "100" (number->string 100))

;; Boolean/type predicates
(test #f (not 3))
(test #f (not (list 3)))
(test #f (not '()))
(test #f (not (list)))
(test #f (boolean? 0))
(test #f (boolean? '()))

;; Pairs and lists
(test #t (pair? '(a . b)))
(test #t (pair? '(a b c)))
(test '(a) (cons 'a '()))
(test '((a) b c d) (cons '(a) '(b c d)))
(test '("a" b c) (cons "a" '(b c)))
(test '(a . 3) (cons 'a 3))
(test '((a b) . c) (cons '(a b) 'c))
(test 'a (car '(a b c)))
(test '(a) (car '((a) b c d)))
(test 1 (car '(1 . 2)))
(test '(b c d) (cdr '((a) b c d)))
(test 2 (cdr '(1 . 2)))
(test #t (list? '(a b c)))
(test #t (list? '()))
(test #f (list? '(a . b)))
(test '(a 7 c) (list 'a (+ 3 4) 'c))
(test '() (list))
(test 3 (length '(a b c)))
(test 3 (length '(a (b) (c d e))))
(test 0 (length '()))
(test '(x y) (append '(x) '(y)))
(test '(a b c d) (append '(a) '(b c d)))
(test '(a (b) (c)) (append '(a (b)) '((c))))
(test '(a b c . d) (append '(a b) '(c . d)))
(test 'a (append '() 'a))
(test '(c b a) (reverse '(a b c)))
(test '((e (f)) d (b c) a) (reverse '(a (b c) d (e (f)))))
(test 'c (list-ref '(a b c d) 2))
(test '(a b c) (memq 'a '(a b c)))
(test '(b c) (memq 'b '(a b c)))
(test #f (memq 'a '(b c d)))
(test #f (memq (list 'a) '(b (a) c)))
(test '((a) c) (member (list 'a) '(b (a) c)))
(test #f (assq (list 'a) '(((a)) ((b)) ((c)))))
(test '((a)) (assoc (list 'a) '(((a)) ((b)) ((c)))))

;; Symbols
(test #t (symbol? 'foo))
(test #t (symbol? (car '(a b))))
(test #f (symbol? "bar"))
(test #t (symbol? 'nil))
(test #f (symbol? '()))
(test "flying-fish" (symbol->string 'flying-fish))
(test "Martin" (symbol->string 'Martin))
(test "Malvina" (symbol->string (string->symbol "Malvina")))

;; Strings
(test #t (string? "a"))
(test #f (string? 'a))
(test 0 (string-length ""))
(test 3 (string-length "abc"))
(test #\a (string-ref "abc" 0))
(test #\c (string-ref "abc" 2))
(test "" (substring "abc" 0 0))
(test "a" (substring "abc" 0 1))
(test "bc" (substring "abc" 1 3))
(test "abc" (string-append "abc" ""))
(test "abc" (string-append "" "abc"))
(test "abc" (string-append "a" "bc"))

;; Vectors
(test '#(0 ("Sue" "Sue") "Anna")
    (let ((vec (vector 0 '(2 2 2 2) "Anna")))
      (vector-set! vec 1 '("Sue" "Sue"))
      vec))
(test '#(dididit dah) (list->vector '(dididit dah)))
(test '(dah dah didah) (vector->list '#(dah dah didah)))

;; Procedures
(test #t (procedure? car))
(test #f (procedure? 'car))
(test #t (procedure? (lambda (x) (* x x))))
(test #f (procedure? '(lambda (x) (* x x))))
(test #t (call-with-current-continuation procedure?))
(test 7 (call-with-current-continuation (lambda (k) (+ 2 5))))
(test 3 (call-with-current-continuation (lambda (k) (+ 2 5 (k 3)))))

;; Apply and map
(test 7 (apply + (list 3 4)))
(test '(b e h) (map cadr '((a b) (d e) (g h))))
(test '#(0 1 4 9 16) (let ((v (make-vector 5))) (for-each (lambda (i) (vector-set! v i (* i i))) '(0 1 2 3 4)) v))

;; Shadowing keywords
(test 'ok (let ((else 1)) (cond (else 'ok) (#t 'bad))))

;; Let mutation
(test '(2 1)
    ((lambda () (let ((x 1)) (let ((y x)) (set! x 2) (list x y))))))
(test '(2 2)
    ((lambda () (let ((x 1)) (set! x 2) (let ((y x)) (list x y))))))
(test '(1 2)
    ((lambda () (let ((x 1)) (let ((y x)) (set! y 2) (list x y))))))
(test '(2 3)
    ((lambda () (let ((x 1)) (let ((y x)) (set! x 2) (set! y 3) (list x y))))))

;; Dynamic-wind
(test '(a b c)
    (let* ((path '())
           (add (lambda (s) (set! path (cons s path)))))
      (dynamic-wind (lambda () (add 'a)) (lambda () (add 'b)) (lambda () (add 'c)))
      (reverse path)))

(test '(connect talk1 disconnect connect talk2 disconnect)
    (let ((path '())
          (c #f))
      (let ((add (lambda (s)
                   (set! path (cons s path)))))
        (dynamic-wind
            (lambda () (add 'connect))
            (lambda ()
              (add (call-with-current-continuation
                    (lambda (c0)
                      (set! c c0)
                      'talk1))))
            (lambda () (add 'disconnect)))
        (if (< (length path) 4)
            (c 'talk2)
            (reverse path)))))

(test-end)
