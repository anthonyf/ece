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

(test "round-trip: shared structure" (lambda ()
  (let* ((x (list 1 2))
         (v (list x x)))
    (assert-equal (deserialize-value (read (open-input-string (serialize-value v)))) v))))

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

;; Note: top-level define + multiple calls from separate compilation units
;; crashes when the define appears late in a large .ecec file (Bug 3).
;; That's a separate frame-append/global-env issue, not named-let related.
