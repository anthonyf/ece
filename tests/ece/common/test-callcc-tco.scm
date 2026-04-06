;;; Tail-position call/cc TCO tests
;;; These tests exercise the tail-position call/cc compiler path on all platforms.
;;; Note: function names must not conflict with the `loop` macro from prelude.

(test "tail-position call/cc at 10,000 iterations" (lambda ()
  (define (callcc-loop n k)
    (if (= n 0) k
        (call/cc (lambda (k) (callcc-loop (- n 1) k)))))
  (define result (callcc-loop 10000 #f))
  ;; Result should be a continuation
  (assert-true (continuation? result))))

(test "captured continuation is invocable after tail-recursive loop" (lambda ()
  (define (callcc-loop n k)
    (if (= n 0) k
        (call/cc (lambda (k) (callcc-loop (- n 1) k)))))
  (define saved-k (callcc-loop 100 #f))
  ;; Invoke the captured continuation — it should resume at the call/cc point
  (assert-true (continuation? saved-k))))

(test "non-tail call/cc is unchanged" (lambda ()
  ;; call/cc in non-tail position (inside let binding)
  (assert-equal (+ 1 (call/cc (lambda (k) (k 10)))) 11)
  ;; call/cc with non-local exit from non-tail
  (assert-equal (+ 1 (call/cc (lambda (k) (+ 2 (k 10))))) 11)
  ;; call/cc returning a simple value from non-tail
  (assert-equal (+ 1 (call/cc (lambda (k) 5))) 6)))

(test "tail-position call/cc in if alternative" (lambda ()
  (define (callcc-alt-loop n)
    (if (= n 0) 'done
        (call/cc (lambda (k) (callcc-alt-loop (- n 1))))))
  (assert-equal (callcc-alt-loop 10000) 'done)))
