;;; Continuation tests — call/cc non-local exit, continuation invocation

(test "call/cc simple value" (lambda ()
  (assert-equal (call/cc (lambda (k) 42)) 42)))

(test "call/cc non-local exit" (lambda ()
  (assert-equal (call/cc (lambda (k) (k 10) 20)) 10)))

(test "call/cc in arithmetic" (lambda ()
  (assert-equal (+ 1 (call/cc (lambda (k) (k 10)))) 11)))

(test "call/cc nested abandon" (lambda ()
  (assert-equal (+ 1 (call/cc (lambda (k) (+ 2 (k 10))))) 11)))

(test "call/cc variable as receiver" (lambda ()
  (define (f k) (k 99))
  (assert-equal (call/cc f) 99)))

(test "call/cc ignored continuation" (lambda ()
  (assert-equal (+ 1 (call/cc (lambda (k) 5))) 6)))

(test "loop with break via call/cc" (lambda ()
  (assert-equal (loop (break 42)) 42)
  (define x 5)
  (assert-equal
   (loop
    (if (= x 0) (break x))
    (set x (- x 1)))
   0)))
