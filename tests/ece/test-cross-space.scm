;;; Cross-space execution tests
;;; Verify functions calling across compilation spaces work correctly.

(test "user code calls prelude function (map)" (lambda ()
  (assert-equal (map (lambda (x) (* x x)) (list 1 2 3)) (list 1 4 9))))

(test "user code calls prelude function (filter)" (lambda ()
  (assert-equal (filter (lambda (x) (> x 2)) (list 1 2 3 4 5)) (list 3 4 5))))

(test "user code calls compiler function (eval)" (lambda ()
  (assert-equal (eval '(+ 10 20)) 30)))

(test "continuation captured in user code returns across spaces" (lambda ()
  (define result
    (+ 1 (call/cc (lambda (k) (k 41)))))
  (assert-equal result 42)))

(test "load .scm file and call function from it" (lambda ()
  ;; Write a temp .scm file
  (define port (open-output-file "/tmp/ece-test-cross-space.scm"))
  (define code "(define (cross-space-add a b) (+ a b))\n")
  (define len (string-length code))
  (define (write-loop i)
    (when (< i len)
      (write-char (string-ref code i) port)
      (write-loop (+ i 1))))
  (write-loop 0)
  (close-output-port port)
  ;; Load it (creates a new space)
  (load "/tmp/ece-test-cross-space.scm")
  ;; Call the function (cross-space call)
  (assert-equal (cross-space-add 10 32) 42)))
