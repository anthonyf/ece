;;; Type predicate and equality tests

(test "number?" (lambda ()
  (assert-true (number? 42))
  (assert-true (number? 3.14))
  (assert-true (not (number? "hello")))
  (assert-true (not (number? 'foo)))))

(test "string?" (lambda ()
  (assert-true (string? "hello"))
  (assert-true (string? ""))
  (assert-true (not (string? 42)))))

(test "symbol?" (lambda ()
  (assert-true (symbol? 'foo))
  (assert-true (not (symbol? 42)))
  (assert-true (not (symbol? "hello")))))

(test "boolean?" (lambda ()
  (assert-true (boolean? #t))
  (assert-true (boolean? #f))
  (assert-true (not (boolean? 42)))
  (assert-true (not (boolean? "hello")))))

(test "char?" (lambda ()
  (assert-true (char? #\a))
  (assert-true (not (char? "a")))
  (assert-true (not (char? 97)))))

(test "char operations" (lambda ()
  (assert-true (char=? #\a #\a))
  (assert-true (not (char=? #\a #\b)))
  (assert-true (char<? #\a #\b))
  (assert-equal (char->integer #\a) 97)
  (assert-equal (integer->char 97) #\a)))

(test "eq?" (lambda ()
  (assert-true (eq? 'a 'a))
  (assert-true (not (eq? 'a 'b)))))

(test "equal?" (lambda ()
  (assert-true (equal? '(1 2 3) '(1 2 3)))
  (assert-true (not (equal? '(1 2) '(1 3))))
  (assert-true (equal? "hello" "hello"))
  (assert-true (equal? 42 42))))

(test "write-to-string" (lambda ()
  (assert-equal (write-to-string 42) "42")
  (assert-equal (write-to-string "hello") "hello")
  (assert-equal (write-to-string '(1 2 3)) "(1 2 3)")))
