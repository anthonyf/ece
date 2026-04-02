;; Golden test: tail call optimization
(define (loop-n n)
  (if (= n 0)
      'done
      (loop-n (- n 1))))

(define (fib-iter a b count)
  (if (= count 0)
      b
      (fib-iter (+ a b) a (- count 1))))
