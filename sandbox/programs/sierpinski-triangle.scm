;;; Sierpinski Triangle via chaos game
(define-module (sandbox sierpinski-triangle)
  (import (ece browser canvas))
  (export start plot)

  (define w (canvas-width))
  (define h (canvas-height))

  ;; Three vertices
  (define v1x (* 0.5 w))
  (define v1y 20)
  (define v2x 20)
  (define v2y (- h 20))
  (define v3x (- w 20))
  (define v3y (- h 20))

  (define px (* 0.5 w))
  (define py (* 0.5 h))
  (define total 0)

  (define (plot batch)
    (canvas-set-fill-color 100 200 255)
    (let go ((n batch))
      (when (> n 0)
        (set! total (+ total 1))
        (let* ((r (random 3))
               (vx (cond ((= r 0) v1x) ((= r 1) v2x) (else v3x)))
               (vy (cond ((= r 0) v1y) ((= r 1) v2y) (else v3y))))
          (set! px (* 0.5 (+ px vx)))
          (set! py (* 0.5 (+ py vy)))
          (canvas-fill-rect px py 1 1)
          (go (- n 1)))))
    (when (< total 30000)
      (yield)
      (plot batch)))

  (define (start)
    (canvas-clear)
    (plot 500))

  (start))
