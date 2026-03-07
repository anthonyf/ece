;;; if-lib.scm — Interactive Fiction library for ECE
;;; Load with: (load "if-lib.scm")

;; Display a numbered list of choices
;; choices is a list of (label . thunk) pairs
(define (display-choices choices n)
  (if (null? choices)
      (newline)
      (begin
        (display "  ")
        (display n)
        (display ". ")
        (display (car (car choices)))
        (newline)
        (display-choices (cdr choices) (+ n 1)))))

;; Main input loop: display menu, read selection, dispatch
(define (choose-loop choices)
  (display-choices choices 1)
  (display "> ")
  (let ((input (string->number (read-line))))
    (if (and input (> input 0) (<= input (length choices)))
        ((cdr (list-ref choices (- input 1))))
        (begin (display "Invalid choice. Try again.")
               (newline)
               (choose-loop choices)))))

;; Expand a single choose clause into a (label . thunk) or (() . ()) expression
(define-macro (expand-choice clause)
  (if (eq? (car clause) (quote when))
      ;; Guarded: (when guard ("label" action))
      (let ((guard (cadr clause))
            (label (car (caddr clause)))
            (action (cadr (caddr clause))))
        `(if ,guard
             (cons ,label (lambda () ,action))
             (cons () ())))
      ;; Unconditional: ("label" action)
      (let ((label (car clause))
            (action (cadr clause)))
        `(cons ,label (lambda () ,action)))))

;; Present choices, filter by guards, read selection, dispatch
(define-macro (choose . clauses)
  (let ((choices (gensym)))
    `(let ((,choices (filter car (list ,@(map (lambda (c) `(expand-choice ,c)) clauses)))))
       (choose-loop ,choices))))

;; Define a room: a zero-argument function that displays text and evaluates body
(define-macro (room name description . body)
  `(define (,name)
     (display ,description)
     (newline)
     ,@body))
