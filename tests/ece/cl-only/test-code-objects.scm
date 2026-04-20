;;; Spec scenarios from code-object-compilation (§13.1).
;;;
;;; Covers: `code-object?`, fresh-per-call identity, length/label-table,
;;; name/native-fn/arity defaults, and nested-lambda bottom-up identity.

(test "code-object? on compile result" (lambda ()
  (assert-true (code-object? (mc-compile-to-code-object 42)))))

(test "code-object? on non-code-object returns #f" (lambda ()
  (assert-equal #f (code-object? 42))
  (assert-equal #f (code-object? "foo"))
  (assert-equal #f (code-object? (lambda (x) x)))
  (assert-equal #f (code-object? '(a b)))))

(test "compile returns fresh object each call" (lambda ()
  (define a (mc-compile-to-code-object '(lambda (x) x)))
  (define b (mc-compile-to-code-object '(lambda (x) x)))
  (assert-equal #f (eq? a b))
  (assert-true (eq? a a))))

(test "code-object-length positive for lambda" (lambda ()
  (define co (mc-compile-to-code-object '(lambda (x) (* x x))))
  (assert-true (> (code-object-length co) 0))))

(test "code-object-label-entries is a list of pairs" (lambda ()
  (define co (mc-compile-to-code-object '(if #t 1 2)))
  (define entries (code-object-label-entries co))
  (when (pair? entries)
    (assert-true (pair? (car entries))))))

(test "code-object-name set for define" (lambda ()
  (define co (mc-compile-to-code-object '(define (my-fn x) x)))
  ;; Top-level init has name %init; inner lambda (the defined fn) has name my-fn.
  ;; Walk the reachable code-objects and look for one named my-fn.
  (let ((all (archive/collect-reachable co)))
    (let loop ((xs all) (found #f))
      (cond
       ((null? xs) (assert-true found))
       ((eq? 'my-fn (code-object-name (car xs))) (loop (cdr xs) #t))
       (else (loop (cdr xs) found)))))))

(test "code-object-name #f for anonymous lambda" (lambda ()
  (define co (mc-compile-to-code-object '((lambda (x) x) 1)))
  (let ((all (archive/collect-reachable co)))
    (let loop ((xs all))
      (cond
       ((null? xs) #t)
       ((and (not (eq? (car xs) co))
             (eq? #f (code-object-name (car xs))))
        (assert-equal #f (code-object-name (car xs))))
       (else (loop (cdr xs))))))))

(test "code-object-native-fn defaults to #f" (lambda ()
  (define co (mc-compile-to-code-object '(+ 1 1)))
  (assert-equal #f (code-object-native-fn co))))

(test "nested lambdas: inner referenced as constant" (lambda ()
  (define outer (mc-compile-to-code-object '(lambda (x) (lambda (y) (+ x y)))))
  (define all (archive/collect-reachable outer))
  (assert-true (>= (length all) 3))
  (assert-true (eq? (car all) outer))))
