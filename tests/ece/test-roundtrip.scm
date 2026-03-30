;;; Serialize/deserialize round-trip tests
;;; Verifies that values survive serialize → read → deserialize cycles.

(test "round-trip: fixnum" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value 42)))) 42)))

(test "round-trip: symbol" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value 'foo)))) 'foo)))

(test "round-trip: booleans" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value #t)))) #t)
  (assert-equal (deserialize-value (read (open-input-string (serialize-value #f)))) #f)))

(test "round-trip: nil" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value '())))) '())))

(test "round-trip: dotted pair" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value (cons 1 2))))) (cons 1 2))))

(test "round-trip: proper list" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value (list 1 2 3))))) (list 1 2 3))))

(test "round-trip: nested list" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value (list (list 1 2) (list 3 4))))))
                (list (list 1 2) (list 3 4)))))

(test "round-trip: string" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value "hello world")))) "hello world")))

(test "round-trip: vector" (lambda ()
  (assert-equal (deserialize-value (read (open-input-string (serialize-value (vector 1 2 3))))) (vector 1 2 3))))

(test "write-to-string-flat quotes strings" (lambda ()
  (assert-equal (write-to-string-flat "hello") "\"hello\"")))

(test "write-to-string does not quote strings" (lambda ()
  (assert-equal (write-to-string "hello") "hello")))

;; --- write vs display semantics ---
;; write-to-string (prim 67) = display mode (no string quoting)
;; write-to-string-flat (prim 136) = write mode (quotes strings)

(test "write-to-string-flat quotes strings in lists" (lambda ()
  (assert-equal (write-to-string-flat (list "a" "b")) "(\"a\" \"b\")")))

(test "round-trip: shared structure" (lambda ()
  (let* ((x (list 1 2))
         (v (list x x)))
    (assert-equal (deserialize-value (read (open-input-string (serialize-value v)))) v))))

(test "equal?: vectors same" (lambda ()
  (assert-true (equal? (vector 1 2 3) (vector 1 2 3)))))

(test "equal?: vectors different elements" (lambda ()
  (assert-true (not (equal? (vector 1 2 3) (vector 1 2 4))))))

(test "equal?: vectors different lengths" (lambda ()
  (assert-true (not (equal? (vector 1 2) (vector 1 2 3))))))

(test "equal?: nested vectors" (lambda ()
  (assert-true (equal? (vector (list 1 2) (list 3 4)) (vector (list 1 2) (list 3 4))))))

;; --- Named-let regression tests ---
;; These test patterns that previously crashed due to frame-append bugs.

(test "named-let as function argument" (lambda ()
  (assert-equal
    (string-append "("
      (let loop ((xs (list 1 2)) (first #t))
        (if (null? xs) ")"
            (string-append (if first "" " ")
                           (write-to-string-flat (car xs))
                           (loop (cdr xs) #f)))))
    "(1 2)")))

(test "named-let with hoisted define in enclosing scope" (lambda ()
  (let ((obj (list 1 2)))
    (define (helper x) x)
    (assert-equal
      (string-append "("
        (let loop ((xs obj) (first #t))
          (if (null? xs) ")"
              (string-append (if first "" " ")
                             (write-to-string-flat (car xs))
                             (loop (cdr xs) #f)))))
      "(1 2)"))))

;; --- Top-level define regression (env-leak fix) ---

(define (round-trip v)
  (deserialize-value (read (open-input-string (serialize-value v)))))

(test "top-level define: call from thunk 1" (lambda ()
  (assert-equal (round-trip 42) 42)))

(test "top-level define: call from thunk 2" (lambda ()
  (assert-equal (round-trip (list 1 2 3)) (list 1 2 3))))

(test "top-level define: call from thunk 3" (lambda ()
  (assert-equal (round-trip (cons 'a 'b)) (cons 'a 'b))))

;; --- Continuation save/load ---

(test "env-frame round-trip" (lambda ()
  (let* ((f (%make-env-frame (quote (x y)) (list 10 20) (quote ())))
         (s (serialize-value f))
         (f2 (deserialize-value (read (open-input-string s)))))
    (assert-true (%env-frame? f2))
    (assert-equal (%env-frame-vals f2) (list 10 20)))))

;; Continuation serialize!/deserialize round-trip is in wasm-test-runner.scm
;; (runs as bare top-level code at runtime, not during compile-file)
