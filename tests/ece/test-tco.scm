;;; Tail call optimization tests — verify no stack overflow at 100k+ iterations

(test "TCO direct tail recursion" (lambda ()
  (define (countdown n)
    (if (= n 0) 0 (countdown (- n 1))))
  (assert-equal (countdown 100000) 0)))

(test "TCO in if" (lambda ()
  (define (tco-if n)
    (if (= n 0) 'done (tco-if (- n 1))))
  (assert-equal (tco-if 100000) 'done)))

(test "TCO in begin" (lambda ()
  (define (tco-begin n)
    (begin
      (if (= n 0) 'done (tco-begin (- n 1)))))
  (assert-equal (tco-begin 100000) 'done)))

(test "TCO in cond" (lambda ()
  (define (tco-cond n)
    (cond ((= n 0) 'done)
          (t (tco-cond (- n 1)))))
  (assert-equal (tco-cond 100000) 'done)))

(test "TCO in and" (lambda ()
  (define (tco-and n)
    (and t (if (= n 0) 'done (tco-and (- n 1)))))
  (assert-equal (tco-and 100000) 'done)))

(test "TCO in or" (lambda ()
  (define (tco-or n)
    (or '() (if (= n 0) 'done (tco-or (- n 1)))))
  (assert-equal (tco-or 100000) 'done)))

(test "TCO in when" (lambda ()
  (define (tco-when n)
    (when t (if (= n 0) 'done (tco-when (- n 1)))))
  (assert-equal (tco-when 100000) 'done)))

(test "TCO in unless" (lambda ()
  (define (tco-unless n)
    (unless '() (if (= n 0) 'done (tco-unless (- n 1)))))
  (assert-equal (tco-unless 100000) 'done)))

(test "TCO in let" (lambda ()
  (define (tco-let n)
    (let ((x n))
      (if (= x 0) 'done (tco-let (- x 1)))))
  (assert-equal (tco-let 100000) 'done)))

(test "TCO in let*" (lambda ()
  (define (tco-let* n)
    (let* ((x n))
      (if (= x 0) 'done (tco-let* (- x 1)))))
  (assert-equal (tco-let* 100000) 'done)))

(test "TCO in named let" (lambda ()
  (assert-equal
   (let loop ((n 100000))
     (if (= n 0) 'done (loop (- n 1))))
   'done)))
