;; Golden test: conditionals and boolean logic
(define (classify n)
  (cond
   ((< n 0) 'negative)
   ((= n 0) 'zero)
   (else 'positive)))

(define (safe-div a b)
  (and (not (= b 0)) (/ a b)))
