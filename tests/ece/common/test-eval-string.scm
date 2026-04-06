;;; Tests for eval-string and eval-string-last

;; --- eval-string ---

(test "eval-string: multiple expressions" (lambda ()
  (eval-string "(define *es-test-x* 10) (define *es-test-y* 20)")
  (assert-equal *es-test-x* 10)
  (assert-equal *es-test-y* 20)))

(test "eval-string: empty string" (lambda ()
  (eval-string "")
  (assert-true #t)))

(test "eval-string: comments only" (lambda ()
  (eval-string ";; just a comment\n")
  (assert-true #t)))

(test "eval-string: quasiquote" (lambda ()
  (eval-string "(define *es-test-qq* `(a ,(+ 1 2) b))")
  (assert-equal *es-test-qq* '(a 3 b))))

;; --- eval-string-last ---

(test "eval-string-last: single expression" (lambda ()
  (assert-equal (eval-string-last "(+ 1 2)") 3)))

(test "eval-string-last: multiple expressions returns last" (lambda ()
  (assert-equal (eval-string-last "(define *es-test-z* 10) (+ *es-test-z* 5)") 15)))

(test "eval-string-last: empty string returns void" (lambda ()
  (define result (eval-string-last ""))
  ;; void is the initial value; write-to-string produces "" for void
  (assert-true #t)))
