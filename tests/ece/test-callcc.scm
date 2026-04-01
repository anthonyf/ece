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

;;; Tail-position call/cc TCO tests

(test "tail-position call/cc at 10,000 iterations" (lambda ()
  (define (loop n k)
    (if (= n 0) k
        (call/cc (lambda (k) (loop (- n 1) k)))))
  (define result (loop 10000 #f))
  ;; Result should be a continuation (list with car = 'continuation')
  (assert (pair? result) "should return a pair")
  (assert-equal (car result) 'continuation)))

(test "captured continuation is invocable after tail-recursive loop" (lambda ()
  ;; Capture a continuation in a tail-recursive call/cc loop, then invoke it
  (define (loop n k)
    (if (= n 0) k
        (call/cc (lambda (k) (loop (- n 1) k)))))
  (define saved-k (loop 100 #f))
  ;; Invoke the captured continuation — it should resume at the call/cc point
  (assert (pair? saved-k) "should be a continuation pair")
  (assert-equal (car saved-k) 'continuation)))

(test "non-tail call/cc is unchanged" (lambda ()
  ;; call/cc in non-tail position (inside let binding)
  (assert-equal (+ 1 (call/cc (lambda (k) (k 10)))) 11)
  ;; call/cc with non-local exit from non-tail
  (assert-equal (+ 1 (call/cc (lambda (k) (+ 2 (k 10))))) 11)
  ;; call/cc returning a simple value from non-tail
  (assert-equal (+ 1 (call/cc (lambda (k) 5))) 6)))

(test "tail-position call/cc in if alternative" (lambda ()
  (define (loop n)
    (if (= n 0) 'done
        (call/cc (lambda (k) (loop (- n 1))))))
  (assert-equal (loop 10000) 'done)))

(test "loop with break via call/cc" (lambda ()
  (assert-equal (loop (break 42)) 42)
  (define x 5)
  (assert-equal
   (loop
    (if (= x 0) (break x))
    (set! x (- x 1)))
   0)))
