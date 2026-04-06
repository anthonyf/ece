;;; List tests — cons, car, cdr, list, append, reverse, length, etc.

(test "cons, car, cdr" (lambda ()
  (assert-equal (car (cons 1 2)) 1)
  (assert-equal (cdr (cons 1 2)) 2)
  (assert-equal (car (cons 'a 'b)) 'a)))

(test "list construction" (lambda ()
  (assert-equal (list 1 2 3) '(1 2 3))
  (assert-equal (list) '())
  (assert-equal (list 'a) '(a))))

(test "null? and pair?" (lambda ()
  (assert-true (null? '()))
  (assert-true (not (null? '(1))))
  (assert-true (pair? (cons 1 2)))
  (assert-true (not (pair? 42)))
  (assert-true (not (pair? '())))))

(test "composite accessors" (lambda ()
  (assert-equal (cadr '(1 2 3)) 2)
  (assert-equal (caddr '(1 2 3)) 3)
  (assert-equal (caar '((a b) c)) 'a)
  (assert-equal (cddr '(1 2 3)) '(3))))

(test "append" (lambda ()
  (assert-equal (append '(1 2) '(3 4)) '(1 2 3 4))
  (assert-equal (append '() '(1 2)) '(1 2))
  (assert-equal (append '(1 2) '()) '(1 2))))

(test "reverse" (lambda ()
  (assert-equal (reverse '(1 2 3)) '(3 2 1))
  (assert-equal (reverse '()) '())
  (assert-equal (reverse '(a)) '(a))))

(test "length" (lambda ()
  (assert-equal (length '(a b c)) 3)
  (assert-equal (length '()) 0)
  (assert-equal (length '(x)) 1)))

(test "list-ref" (lambda ()
  (assert-equal (list-ref '(a b c d) 0) 'a)
  (assert-equal (list-ref '(a b c d) 2) 'c)
  (assert-equal (list-ref '(a b c d) 3) 'd)))

(test "list-tail" (lambda ()
  (assert-equal (list-tail '(a b c d) 0) '(a b c d))
  (assert-equal (list-tail '(a b c d) 2) '(c d))
  (assert-equal (list-tail '(a b c d) 4) '())))

(test "assoc" (lambda ()
  (assert-equal (assoc 'b '((a 1) (b 2) (c 3))) '(b 2))
  (assert-equal (assoc 'z '((a 1) (b 2))) #f)))

(test "member" (lambda ()
  (assert-equal (member 3 '(1 2 3 4 5)) '(3 4 5))
  (assert-equal (member 6 '(1 2 3 4 5)) #f)))

(test "not" (lambda ()
  (assert-true (not #f))
  (assert-true (not (not 42)))))
