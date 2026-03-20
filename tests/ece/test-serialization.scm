;; ---- Value Serialization Tests ----

(test "serialize plain number" (lambda ()
  (assert-equal (serialize-value 42) "42")))

(test "serialize string" (lambda ()
  (assert-equal (serialize-value "hello") "\"hello\"")))

(test "serialize boolean" (lambda ()
  (assert-equal (serialize-value #t) "#t")
  (assert-equal (serialize-value #f) "#f")))

(test "serialize nil" (lambda ()
  (assert-equal (serialize-value '()) "()")))

(test "serialize symbol" (lambda ()
  (assert-equal (serialize-value 'foo) "FOO")))

(test "round-trip plain values" (lambda ()
  (save-continuation! "/tmp/ece-rt-plain.dat" 42)
  (assert-equal (load-continuation "/tmp/ece-rt-plain.dat") 42)
  (save-continuation! "/tmp/ece-rt-plain.dat" "hello world")
  (assert-equal (load-continuation "/tmp/ece-rt-plain.dat") "hello world")
  (save-continuation! "/tmp/ece-rt-plain.dat" #t)
  (assert-equal (load-continuation "/tmp/ece-rt-plain.dat") #t)))

(test "round-trip list" (lambda ()
  (save-continuation! "/tmp/ece-rt-list.dat" (list 1 "two" #t 'four))
  (define result (load-continuation "/tmp/ece-rt-list.dat"))
  (assert-equal (car result) 1)
  (assert-equal (cadr result) "two")
  (assert-equal (caddr result) #t)
  (assert-equal (cadddr result) 'four)))

(test "round-trip dotted pair" (lambda ()
  (save-continuation! "/tmp/ece-rt-pair.dat" (cons 'a 'b))
  (define result (load-continuation "/tmp/ece-rt-pair.dat"))
  (assert-equal (car result) 'a)
  (assert-equal (cdr result) 'b)))

(test "round-trip vector" (lambda ()
  (save-continuation! "/tmp/ece-rt-vec.dat" (vector 10 20 30))
  (define v (load-continuation "/tmp/ece-rt-vec.dat"))
  (assert (vector? v))
  (assert-equal (vector-ref v 0) 10)
  (assert-equal (vector-ref v 1) 20)
  (assert-equal (vector-ref v 2) 30)))

(test "round-trip hash table" (lambda ()
  (save-continuation! "/tmp/ece-rt-ht.dat" (hash-table 'name "Alice" 'age 30))
  (define ht (load-continuation "/tmp/ece-rt-ht.dat"))
  (assert (hash-table? ht))
  (assert-equal (hash-ref ht 'name) "Alice")
  (assert-equal (hash-ref ht 'age) 30)))

(test "round-trip compiled procedure" (lambda ()
  (define (test-sq x) (* x x))
  (save-continuation! "/tmp/ece-rt-fn.dat" test-sq)
  (define loaded (load-continuation "/tmp/ece-rt-fn.dat"))
  (assert-equal (loaded 7) 49)))

(test "save-continuation! returns #t" (lambda ()
  (assert-equal (save-continuation! "/tmp/ece-rt-ret.dat" 42) #t)))

(test "round-trip continuation" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set k cont)))
  (save-continuation! "/tmp/ece-rt-cont.dat" k)
  (define loaded (load-continuation "/tmp/ece-rt-cont.dat"))
  (assert (pair? loaded))
  (assert-equal (car loaded) 'continuation)))

(test "continuation serialization is compact" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set k cont) 0))
  (define size (string-length (serialize-value k)))
  ;; Trivial continuation should be well under 500 bytes
  (assert (< size 500) (string-append "continuation too large: " (number->string size) " bytes"))))

(test "continuation with state is compact" (lambda ()
  (define state (hash-table 'room "kitchen" 'inventory (list "key" "torch") 'health 100))
  (define k #f)
  (%raw-call/cc (lambda (cont) (set k cont) 0))
  (define size (string-length (serialize-value k)))
  ;; Continuation with game state should stay under 1KB
  (assert (< size 1000) (string-append "continuation+state too large: " (number->string size) " bytes"))))

(test "round-trip parameter value" (lambda ()
  (define p (make-parameter 42))
  (p 99)
  (save-continuation! "/tmp/ece-rt-param.dat" p)
  (define loaded (load-continuation "/tmp/ece-rt-param.dat"))
  (assert (parameter? loaded) "loaded should be a parameter")
  (assert-equal (loaded) 99)))

(test "round-trip parameter with converter" (lambda ()
  (define p (make-parameter "hello" string-length))
  (save-continuation! "/tmp/ece-rt-param-conv.dat" p)
  (define loaded (load-continuation "/tmp/ece-rt-param-conv.dat"))
  (assert (parameter? loaded) "loaded should be a parameter")
  (assert-equal (loaded) 5)
  ;; converter should also be preserved
  (loaded "world")
  (assert-equal (loaded) 5)))

(test "parameter in lexical scope captured by continuation" (lambda ()
  ;; Parameter in a let binding IS captured (unlike global define)
  (define result
    (let ((p (make-parameter "kitchen")))
      (p "dungeon")
      (define k #f)
      (%raw-call/cc (lambda (c) (set k c) 0))
      (save-continuation! "/tmp/ece-rt-param-lex.dat" k)
      (define loaded (load-continuation "/tmp/ece-rt-param-lex.dat"))
      ;; The continuation captured the env with p in lexical scope
      (assert (pair? loaded))
      (assert-equal (car loaded) 'continuation)
      (p)))
  (assert-equal result "dungeon")))

(test "mutated parameter survives round-trip" (lambda ()
  (define p (make-parameter 0))
  (p 1)
  (p 2)
  (p 42)
  (save-continuation! "/tmp/ece-rt-param-mut.dat" p)
  (define loaded (load-continuation "/tmp/ece-rt-param-mut.dat"))
  (assert-equal (loaded) 42)
  ;; mutating loaded doesn't affect original
  (loaded 999)
  (assert-equal (loaded) 999)
  (assert-equal (p) 42)))
