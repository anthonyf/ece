;;; Higher-order function tests — map, filter, reduce, for-each, compose, any, every

(test "map" (lambda ()
  (assert-equal (map (lambda (x) (+ x 1)) '(1 2 3)) '(2 3 4))
  (assert-equal (map car '((1 2) (3 4) (5 6))) '(1 3 5))
  (assert-equal (map (lambda (x) x) '()) '())))

(test "filter" (lambda ()
  (assert-equal (filter even? '(1 2 3 4 5 6)) '(2 4 6))
  (assert-equal (filter (lambda (x) (> x 3)) '(1 2 3 4 5)) '(4 5))
  (assert-equal (filter even? '()) '())))

(test "reduce" (lambda ()
  (assert-equal (reduce + 0 '(1 2 3 4 5)) 15)
  (assert-equal (reduce (lambda (acc x) (cons x acc)) '() '(1 2 3)) '(3 2 1))))

(test "for-each" (lambda ()
  (assert-equal (for-each (lambda (x) x) '(1 2 3)) '())))

(test "fold" (lambda ()
  (assert-equal (fold + 0 (list 1 2 3 4)) 10)
  (assert-equal (fold-left + 0 (list 1 2 3)) 6)
  (assert-equal (fold-right cons (list) (list 1 2 3)) '(1 2 3))))

(test "any" (lambda ()
  (assert-true (any odd? (list 2 3 4)))
  (assert-true (not (any odd? (list 2 4 6))))
  (assert-true (not (any odd? (list))))))

(test "every" (lambda ()
  (assert-true (every even? (list 2 4 6)))
  (assert-true (not (every even? (list 2 3 6))))
  (assert-true (every even? (list)))))

(test "compose" (lambda ()
  (assert-equal ((compose car cdr) (list 1 2 3)) 2)))

(test "identity" (lambda ()
  (assert-equal (identity 42) 42)
  (assert-equal (map identity (list 1 2 3)) '(1 2 3))))

(test "range" (lambda ()
  (assert-equal (range 5) '(0 1 2 3 4))
  (assert-equal (range 0) '())
  (assert-equal (range 1) '(0))))

(test "collect" (lambda ()
  (assert-equal (collect (x (range 5)) (* x x)) '(0 1 4 9 16))
  (assert-equal (collect (s (list "a" "b" "c")) (string-append s "!")) '("a!" "b!" "c!"))))

(test "apply" (lambda ()
  (assert-equal (apply + '(1 2 3)) 6)
  (assert-equal (apply (lambda (x y) (+ x y)) '(3 4)) 7)))
