;;; Vector tests — make-vector, vector, vector-ref, vector-set!, vector-length, vector->list

(test "vector?" (lambda ()
  (assert-true (vector? #(1 2 3)))
  (assert-true (not (vector? '(1 2 3))))
  (assert-true (not (vector? 42)))))

(test "make-vector" (lambda ()
  (assert-equal (vector-length (make-vector 5)) 5)
  (define v (make-vector 3 42))
  (assert-equal (vector-ref v 0) 42)
  (assert-equal (vector-ref v 1) 42)
  (assert-equal (vector-ref v 2) 42)))

(test "vector constructor" (lambda ()
  (define v (vector 1 2 3))
  (assert-equal (vector-length v) 3)
  (assert-equal (vector-ref v 0) 1)
  (assert-equal (vector-ref v 1) 2)
  (assert-equal (vector-ref v 2) 3)))

(test "vector-ref" (lambda ()
  (assert-equal (vector-ref #(10 20 30) 0) 10)
  (assert-equal (vector-ref #(10 20 30) 2) 30)))

(test "vector-set!" (lambda ()
  (define v (vector 1 2 3))
  (vector-set! v 1 42)
  (assert-equal (vector-ref v 1) 42)))

(test "vector->list" (lambda ()
  (assert-equal (vector->list #(1 2 3)) '(1 2 3))
  (assert-equal (vector->list #()) '())))

(test "list->vector" (lambda ()
  (define v (list->vector '(1 2 3)))
  (assert-true (vector? v))
  (assert-equal (vector-ref v 0) 1)
  (assert-equal (vector-length v) 3)))
