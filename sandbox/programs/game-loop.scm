;;; Bouncing ball with FPS counter
(define-module (sandbox game-loop)
  (import (ece browser canvas))
  (export start game-loop)

  (define x 100)
  (define y 100)
  (define dx 4)
  (define dy 3)
  (define frames 0)
  (define start-time (current-milliseconds))

  (define (game-loop)
    (clear!)

    ;; Move ball
    (set! x (+ x dx))
    (set! y (+ y dy))

    ;; Bounce off walls
    (when (or (> x (- (width) 15)) (< x 15))
      (set! dx (- 0 dx)))
    (when (or (> y (- (height) 15)) (< y 15))
      (set! dy (- 0 dy)))

    ;; Draw ball
    (set-fill-color! 50 200 100)
    (fill-circle! x y 15)

    ;; FPS counter
    (set! frames (+ frames 1))
    (let* ((elapsed (- (current-milliseconds) start-time))
           (fps (if (> elapsed 0)
                    (/ (* frames 1000) elapsed)
                    0)))
      (set-fill-color! 255 255 255)
      (draw-text! 10 24
        (string-append "FPS: " (number->string fps))))

    ;; Yield to browser, resume on next animation frame
    (yield)
    (game-loop))

  (define (start)
    (game-loop))

  (start))
