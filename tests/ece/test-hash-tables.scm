;;; Hash table tests — make-hash-table, ref, set!, delete!, keys, values, literals

(test "hash-table?" (lambda ()
  (assert-true (hash-table? (hash-table 'a 1)))
  (assert-true (not (hash-table? 42)))
  (assert-true (not (hash-table? '(a 1))))))

(test "hash-table constructor" (lambda ()
  (define ht (hash-table 'a 1 'b 2))
  (assert-equal (hash-ref ht 'a) 1)
  (assert-equal (hash-ref ht 'b) 2)
  (assert-equal (hash-count ht) 2)))

(test "hash-table literal syntax" (lambda ()
  (define ht {name "Alice" age 30})
  (assert-true (hash-table? ht))
  (assert-equal (hash-ref ht 'name) "Alice")
  (assert-equal (hash-ref ht 'age) 30)))

(test "empty hash-table" (lambda ()
  (define ht {})
  (assert-true (hash-table? ht))
  (assert-equal (hash-count ht) 0)))

(test "hash-ref with default" (lambda ()
  (define ht (hash-table 'a 1))
  (assert-equal (hash-ref ht 'a) 1)
  (assert-equal (hash-ref ht 'missing "default") "default")))

(test "hash-has-key?" (lambda ()
  (define ht (hash-table 'name "Alice"))
  (assert-true (hash-has-key? ht 'name))
  (assert-true (not (hash-has-key? ht 'missing)))))

(test "hash-keys and hash-values" (lambda ()
  (define ht (hash-table 'a 1))
  (assert-true (member 'a (hash-keys ht)))
  (assert-true (member 1 (hash-values ht)))))

(test "hash-set! mutation" (lambda ()
  (define ht (hash-table 'a 1))
  (hash-set! ht 'a 2)
  (assert-equal (hash-ref ht 'a) 2)
  (hash-set! ht 'b 3)
  (assert-equal (hash-ref ht 'b) 3)))

(test "hash-set functional update" (lambda ()
  (define ht (hash-table 'a 1))
  (define ht2 (hash-set ht 'a 2))
  (assert-equal (hash-ref ht2 'a) 2)))

(test "hash-remove!" (lambda ()
  (define ht (hash-table 'a 1 'b 2))
  (hash-remove! ht 'a)
  (assert-true (not (hash-has-key? ht 'a)))
  (assert-true (hash-has-key? ht 'b))))
