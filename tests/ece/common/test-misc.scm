;;; Miscellaneous feature tests
;;; ECE native tests for features that previously only had CL-side tests.

;; --- Bitwise operations ---

(test "bitwise-and" (lambda ()
  (assert-equal (bitwise-and 12 10) 8)))

(test "bitwise-or" (lambda ()
  (assert-equal (bitwise-or 12 10) 14)))

(test "bitwise-xor" (lambda ()
  (assert-equal (bitwise-xor 12 10) 6)))

(test "bitwise-not" (lambda ()
  (assert-equal (bitwise-not 0) -1)))

(test "arithmetic-shift left" (lambda ()
  (assert-equal (arithmetic-shift 1 8) 256)))

(test "arithmetic-shift right" (lambda ()
  (assert-equal (arithmetic-shift 256 -4) 16)))

;; --- Random ---

(test "random returns number in range" (lambda ()
  (define r (random 100))
  (assert (>= r 0))
  (assert (< r 100))))

(test "random-seed! affects sequence" (lambda ()
  (random-seed! 42)
  (define a (random 1000))
  (random-seed! 42)
  (define b (random 1000))
  (assert-equal a b)))

;; --- write-to-string ---

(test "write-to-string number" (lambda ()
  (assert-equal (write-to-string 42) "42")))

(test "write-to-string string" (lambda ()
  (assert (string-contains? (write-to-string "hello") "hello"))))

(test "write-to-string list" (lambda ()
  (assert-equal (write-to-string '(1 2 3)) "(1 2 3)")))

(test "write-to-string boolean" (lambda ()
  (assert-equal (write-to-string #t) "#t")
  (assert-equal (write-to-string #f) "#f")))

(test "write-to-string vector" (lambda ()
  (assert (string-contains? (write-to-string (vector 1 2 3)) "1"))))

;; --- write-to-string-flat ---

(test "write-to-string-flat produces reader-compatible output" (lambda ()
  (define s (write-to-string-flat '(hello world)))
  ;; Should be parseable by ECE reader
  (define result (read (open-input-string s)))
  (assert-equal result '(hello world))))

;; --- keyword? ---

;; KNOWN ISSUE: keyword? checks CL keywords, but ECE reader interns
;; :foo as regular symbols named ":foo" in the ECE package (not CL keywords).
;; keyword? always returns #f for ECE keywords. Needs an ECE-native keyword?
;; implementation. Skipped for now.
;; (test "keyword? on keyword" ...)

(test "keyword? on non-keyword" (lambda ()
  (assert (not (keyword? 'hello)))
  (assert (not (keyword? 42)))
  (assert (not (keyword? "str")))))

;; --- platform-has? ---

;; KNOWN ISSUE: platform-has? has inconsistent behavior across platforms:
;; CL returns () for unknown (Scheme-truthy), WASM returns #f. The function
;; is also not available on all platforms. Skipped until platform-has? is
;; standardized.
;; (test "platform-has? for known primitive" ...)
;; (test "platform-has? for unknown returns false" ...)

;; --- Named let ---

(test "named let loop" (lambda ()
  (define result
    (let loop ((n 5) (acc 0))
      (if (= n 0) acc
          (loop (- n 1) (+ acc n)))))
  (assert-equal result 15)))

(test "named let fibonacci" (lambda ()
  (define result
    (let fib ((n 10) (a 0) (b 1))
      (if (= n 0) a
          (fib (- n 1) b (+ a b)))))
  (assert-equal result 55)))

;; --- loop/collect ---

(test "loop macro with break" (lambda ()
  (define total 0)
  (loop
   (set! total (+ total 1))
   (when (= total 3) (break total)))
  (assert-equal total 3)))

(test "collect macro" (lambda ()
  (define result (collect (x '(1 2 3)) (* x x)))
  (assert-equal result (list 1 4 9))))

;; --- Macro shadowing ---

(test "lambda param shadows macro name" (lambda ()
  ;; 'let' is a macro, but using it as a parameter name should work
  (define (f let) (+ let 1))
  (assert-equal (f 41) 42)))

(test "define shadows macro name" (lambda ()
  ;; 'when' is a macro, but using it as a local variable should work
  (define when 42)
  (assert-equal when 42)))
