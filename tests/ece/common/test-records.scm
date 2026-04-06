;;; Record tests — define-record constructor, predicate, accessors

(test "record constructor" (lambda ()
  (define-record point x y)
  (define p (make-point 10 20))
  (assert-true (point? p))
  (assert-equal (point-x p) 10)
  (assert-equal (point-y p) 20)))

(test "record predicate" (lambda ()
  (define-record point x y)
  (assert-true (point? (make-point 1 2)))
  (assert-true (not (point? 42)))
  (assert-true (not (point? '(1 2))))))

(test "record mutation" (lambda ()
  (define-record point x y)
  (define p (make-point 10 20))
  (set-point-x! p 99)
  (assert-equal (point-x p) 99)
  (assert-equal (point-y p) 20)))

(test "record functional update" (lambda ()
  (define-record point x y)
  (define p (make-point 10 20))
  (define p2 (point-with-x p 99))
  (assert-equal (point-x p2) 99)
  ;; original unchanged
  (assert-equal (point-x p) 10)))

(test "record copy" (lambda ()
  (define-record point x y)
  (define p (make-point 10 20))
  (define p2 (copy-point p))
  (assert-equal (point-x p2) 10)
  (assert-equal (point-y p2) 20)
  ;; copy is independent
  (set-point-x! p2 99)
  (assert-equal (point-x p) 10)))

(test "record backed by hash-table" (lambda ()
  (define-record point x y)
  (assert-true (hash-table? (make-point 10 20)))))

(test "multiple record types" (lambda ()
  (define-record point x y)
  (define-record rect width height)
  (define r (make-rect 100 50))
  (assert-true (rect? r))
  (assert-equal (rect-width r) 100)
  (assert-true (not (point? r)))))
