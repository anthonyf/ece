;;; String tests — string ops, comparisons, interpolation

(test "string self-evaluation" (lambda ()
  (assert-equal "hello" "hello")
  (assert-equal "" "")))

(test "string-length" (lambda ()
  (assert-equal (string-length "hello") 5)
  (assert-equal (string-length "") 0)))

(test "string-ref" (lambda ()
  (assert-equal (string-ref "hello" 0) #\h)
  (assert-equal (string-ref "hello" 4) #\o)))

(test "string-append" (lambda ()
  (assert-equal (string-append "hello" " world") "hello world")
  (assert-equal (string-append "" "x") "x")
  (assert-equal (string-append "a" "b" "c") "abc")))

(test "substring" (lambda ()
  (assert-equal (substring "hello world" 0 5) "hello")
  (assert-equal (substring "hello" 0 0) "")))

(test "string comparisons" (lambda ()
  (assert-true (string=? "hello" "hello"))
  (assert-true (not (string=? "hello" "world")))
  (assert-true (string<? "abc" "abd"))
  (assert-true (string>? "abd" "abc"))))

(test "string-contains?" (lambda ()
  (assert-true (string-contains? "hello world" "world"))
  (assert-true (not (string-contains? "hello world" "xyz")))
  (assert-true (string-contains? "hello" ""))))

(test "string case conversion" (lambda ()
  (assert-equal (string-downcase "Hello World") "hello world")
  (assert-equal (string-upcase "Hello World") "HELLO WORLD")))

(test "string-split" (lambda ()
  (assert-equal (string-split "hello world") '("hello" "world"))
  (assert-equal (string-split "a,b,c" #\,) '("a" "b" "c"))))

(test "string-trim" (lambda ()
  (assert-equal (string-trim "  hello  ") "hello")))

(test "string-join" (lambda ()
  (assert-equal (string-join (list "a" "b" "c") ", ") "a, b, c")
  (assert-equal (string-join (list "a" "b" "c") "") "abc")))

(test "string/number conversion" (lambda ()
  (assert-equal (string->number "42") 42)
  (assert-equal (string->number "-7") -7)
  (assert-equal (string->number "3.14") 3.14)
  (assert-equal (number->string 42) "42")))

(test "string/symbol conversion" (lambda ()
  (assert-equal (string->symbol "hello") 'hello)
  (assert-equal (symbol->string 'hello) "hello")))

(test "string interpolation" (lambda ()
  (define name "world")
  (assert-equal "hello $name" "hello world")
  (define n 42)
  (assert-equal "value: $n" "value: 42")))
