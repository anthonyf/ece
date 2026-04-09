;;; Demo 2: call/cc (CL REPL, ~4 min)

;; "call/cc captures the entire program state as a value"
(define saved #f)

(define (adventure)
  (display "You enter a dark cave.\n")
  (call/cc (lambda (k)
             (set! saved k)))
  (display "A dragon appears!\n")
  (display "You are eaten. Game over.\n"))

(adventure)
;; You enter a dark cave.
;; A dragon appears!
;; You are eaten. Game over.

;; "Now I restore from the checkpoint"
(saved #f)
;; A dragon appears!
;; You are eaten. Game over.

;; "It resumed from INSIDE the function.
;;  The cave entrance is gone — we jumped back mid-execution.
;;  This is how save/restore works in an interactive fiction game."
