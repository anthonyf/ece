;; Golden test: call/cc
(define (escape-with-value)
  (call-with-current-continuation
   (lambda (k)
     (k 42)
     (error "should not reach here"))))
