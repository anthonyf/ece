(display "Hello from ECE")
(newline)

(define counter 0)

(define (tick)
  (set! counter (+ counter 1))
  (display "tick ")
  (display counter)
  (newline)
  counter)

(tick)
