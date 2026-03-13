;;; Control flow tests — if, cond, case, and, or, when, unless, do

(test "if true branch" (lambda ()
  (assert-equal (if (< 1 2) 10 20) 10)
  (assert-equal (if 1 42 0) 42)))

(test "if false branch" (lambda ()
  (assert-equal (if (> 1 2) 10 20) 20)
  (assert-equal (if '() 10 20) 20)))

(test "if omitted alternative" (lambda ()
  (assert-equal (if '() 42) '())
  (assert-equal (if 1 42) 42)))

(test "cond basic" (lambda ()
  (assert-equal (cond ((= 1 1) 10) ((= 2 3) 20)) 10)
  (assert-equal (cond ((= 1 2) 10) ((= 2 2) 20)) 20)))

(test "cond no match" (lambda ()
  (assert-equal (cond ((= 1 2) 10) ((= 3 4) 20)) '())))

(test "cond else" (lambda ()
  (assert-equal (cond ((= 1 2) 10) (else 99)) 99)))

(test "cond multi-expr body" (lambda ()
  (define x 0)
  (assert-equal (cond ((= 1 1) (set x 10) (+ x 5))) 15)))

(test "case basic" (lambda ()
  (assert-equal (case (+ 1 1) ((1) 10) ((2) 20) ((3) 30)) 20)
  (assert-equal (case 3 ((1 2) 'low) ((3 4) 'high)) 'high)))

(test "case else" (lambda ()
  (assert-equal (case 99 ((1) 'one) (else 'other)) 'other)))

(test "case no match" (lambda ()
  (assert-equal (case 5 ((1) 'one) ((2) 'two)) '())))

(test "and" (lambda ()
  (assert-equal (and 1 2 3) 3)
  (assert-equal (and 1 '() 3) '())
  (assert-equal (and) t)))

(test "or" (lambda ()
  (assert-equal (or '() 2 3) 2)
  (assert-equal (or '() '()) '())
  (assert-equal (or) '())))

(test "when" (lambda ()
  (assert-equal (when (= 1 1) 42) 42)
  (assert-equal (when (= 1 2) 42) '())))

(test "unless" (lambda ()
  (assert-equal (unless (= 1 2) 42) 42)
  (assert-equal (unless (= 1 1) 42) '())))

(test "do loop" (lambda ()
  (assert-equal (do ((i 0 (+ i 1))) ((= i 5) i)) 5)
  (assert-equal (do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum)) 10)))

(test "begin sequencing" (lambda ()
  (assert-equal (begin 42) 42)
  (assert-equal (begin 1 2 3) 3)
  (assert-equal (begin (+ 1 2) (* 3 4)) 12)))
