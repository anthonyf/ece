;;; R5RS Pitfall Tests
;;; Adapted from http://sisc-scheme.org/r5rs_pitfall.php
;;; Original code collected from public forums, placed in the public domain.
;;;
;;; Tests cover subtle edge cases in R5RS conformance:
;;; - Proper letrec semantics with call/cc
;;; - Continuation behavior in procedure application
;;; - Hygienic macros (skipped: requires let-syntax)
;;; - Reserved identifier shadowing
;;; - #f/() distinctness
;;; - string->symbol case sensitivity
;;; - First-class continuations

;; R5RS shim: procedure? (needed by tests 1.2)
(define %primitive-tag (car +))
(define %continuation-tag (car (call/cc (lambda (k) k))))
(define (procedure? x)
  (or (compiled-procedure? x)
      (and (pair? x) (eq? (car x) %primitive-tag))
      (and (pair? x) (eq? (car x) %continuation-tag))))

;; Skip tests that require let-syntax (not yet implemented)
(conformance-skip! "3.1 hygienic let-syntax")
(conformance-skip! "3.2 let-syntax define interaction")
(conformance-skip! "3.3 nested let-syntax hygiene")
(conformance-skip! "3.4 empty syntax-rules")
(conformance-skip! "8.3 let-syntax scope")

;; eqv? now available (PR #59)

;; Tests 1.2 and 1.3 need procedure? (defined below).

;;; Section 1: Proper letrec implementation

;; Al Petrofsky — letrec + call/cc interaction
(conformance-test "1.1 letrec call/cc" 0
  (let ((cont #f))
    (letrec ((x (call-with-current-continuation (lambda (c) (set! cont c) 0)))
             (y (call-with-current-continuation (lambda (c) (set! cont c) 0))))
      (if cont
          (let ((c cont))
            (set! cont #f)
            (set! x 1)
            (set! y 1)
            (c 0))
          (+ x y)))))

;; Al Petrofsky — letrec initializer returns twice
(conformance-test "1.2 letrec double return" #t
  (letrec ((x (call/cc list)) (y (call/cc list)))
    (cond ((procedure? x) (x (pair? y)))
          ((procedure? y) (y (pair? x))))
    (let ((x (car x)) (y (car y)))
      (and (call/cc x) (call/cc y) (call/cc x)))))

;; Alan Bawden — letrec + call/cc = set!
(conformance-test "1.3 letrec call/cc eq" #t
  (letrec ((x (call-with-current-continuation
               (lambda (c)
                 (list #t c)))))
    (if (car x)
        ((cadr x) (list #f (lambda () x)))
        (eq? x ((cadr x))))))

;;; Section 2: Proper call/cc and procedure application

;; Al Petrofsky — call/cc in operator position
(conformance-test "2.1 call/cc in operator" 1
  (call/cc (lambda (c) (0 (c 1)))))

;;; Section 3: Hygienic macros (require let-syntax — skipped)

(conformance-test "3.1 hygienic let-syntax" 4 0)
(conformance-test "3.2 let-syntax define interaction" 2 0)
(conformance-test "3.3 nested let-syntax hygiene" 1 0)
(conformance-test "3.4 empty syntax-rules" 1 0)

;;; Section 4: No identifiers are reserved

;; Brian M. Moore — shadowing lambda
(conformance-test "4.1 shadow lambda" '(x)
  ((lambda lambda lambda) 'x))

;; Shadowing begin — begin as function returns args as list
(conformance-test "4.2 shadow begin" '(1 2 3)
  ((lambda (begin) (begin 1 2 3)) (lambda lambda lambda)))

;; Shadowing quote
(conformance-test "4.3 shadow quote" #f
  (let ((quote -)) (eqv? '1 1)))

;;; Section 5: #f/() distinctness

;; Scott Miller
(conformance-test "5.1 eq #f/nil" #f
  (eq? #f '()))

;; ECE already distinguishes #f (*scheme-false*) from '() (CL nil)
(conformance-test "5.2 eqv #f/nil" #f
  (eqv? #f '()))

(conformance-test "5.3 equal #f/nil" #f
  (equal? #f '()))

;;; Section 6: string->symbol case sensitivity

;; Jens Axel Sogaard
(conformance-test "6.1 string->symbol case" #f
  (eq? (string->symbol "f") (string->symbol "F")))

;;; Section 7: First class continuations

;; Scott Miller — multi-continuation capture
(conformance-test "7.1 multi-continuation forward" 28
  (let ((r #f) (a #f) (b #f) (c #f) (i 0))
    (set! r (+ 1 (+ 2 (+ 3 (call/cc (lambda (k) (set! a k) 4))))
               (+ 5 (+ 6 (call/cc (lambda (k) (set! b k) 7))))))
    (if (not c)
        (set! c a))
    (set! i (+ i 1))
    (case i
      ((1) (a 5))
      ((2) (b 8))
      ((3) (a 6))
      ((4) (c 4)))
    r))

;; Same test, reverse order
(conformance-test "7.2 multi-continuation reverse" 28
  (let ((r #f) (a #f) (b #f) (c #f) (i 0))
    (set! r (+ 1 (+ 2 (+ 3 (call/cc (lambda (k) (set! a k) 4))))
               (+ 5 (+ 6 (call/cc (lambda (k) (set! b k) 7))))))
    (if (not c)
        (set! c a))
    (set! i (+ i 1))
    (case i
      ((1) (b 8))
      ((2) (a 5))
      ((3) (b 7))
      ((4) (c 4)))
    r))

;; Yin-yang puzzle (modified to terminate)
(conformance-test "7.4 yin-yang puzzle" '(10 9 8 7 6 5 4 3 2 1 0)
  (let ((x '())
        (y 0))
    (call/cc
     (lambda (escape)
       (let* ((yin ((lambda (foo)
                      (set! x (cons y x))
                      (if (= y 10)
                          (escape x)
                          (begin
                            (set! y 0)
                            foo)))
                    (call/cc (lambda (bar) bar))))
              (yang ((lambda (foo)
                       (set! y (+ y 1))
                       foo)
                     (call/cc (lambda (baz) baz)))))
         (yin yang))))))

;;; Section 8: Miscellaneous

;; Al Petrofsky — named let with -
(conformance-test "8.1 named let with -" -1
  (let - ((n (- 1))) n))

;; append sharing
(conformance-test "8.2 append sharing" '(1 2 3 4 1 2 3 4 5)
  (let ((ls (list 1 2 3 4)))
    (append ls ls '(5))))

;; let-syntax scope (requires let-syntax — skipped)
(conformance-test "8.3 let-syntax scope" 1 0)
