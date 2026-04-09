;;; Demo 3: Multiple checkpoints (CL REPL, optional extension of Demo 2)

;; "Continuations are just values — you can store as many as you want"
(define checkpoints '())

(define (save-checkpoint! label)
  (call/cc (lambda (k)
             (set! checkpoints
                   (cons (cons label k) checkpoints))
             (display (string-append "Saved: " label "\n")))))

(save-checkpoint! "before-puzzle")
;; Saved: before-puzzle

(display "You solve the puzzle.\n")

(save-checkpoint! "after-puzzle")
;; Saved: after-puzzle

(display "You open the door.\n")

;; "Now I can jump back to any checkpoint by name"
((cdr (assoc "before-puzzle" checkpoints)) #f)
;; Saved: before-puzzle   (re-saves, then continues)
;; You solve the puzzle.
;; Saved: after-puzzle
;; You open the door.
