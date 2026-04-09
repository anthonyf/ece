;;; Demo 1: Basics + TCO (CL REPL, ~3 min)
;;; Start with: make repl

;; "Let me show you the language works"
(+ 1 2)
;; => 3

(define (square x) (* x x))
(square 12)
;; => 144

;; "Scheme has first-class functions — functions are values"
(map square '(1 2 3 4 5))
;; => (1 4 9 16 25)

(filter (lambda (x) (> x 10)) (map square '(1 2 3 4 5)))
;; => (16 25)

;; "Now tail call optimization — this calls itself a million times"
(define (countdown n)
  (if (= n 0) "done"
      (countdown (- n 1))))

(countdown 1000000)
;; => "done"

;; "No stack overflow. The compiler sees that countdown is the LAST
;;  thing the function does, so it reuses the stack frame.
;;  Recursion IS the loop."
