;;; Tail-position call/cc TCO tests (CL-only)
;;; These tests exercise the tail-position call/cc compiler path which
;;; is not yet supported by the WASM runtime.

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
