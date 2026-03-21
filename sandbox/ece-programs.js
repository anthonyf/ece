// ECE Canned Programs
// Each entry: { name, source }
const ECE_PROGRAMS = [
  {
    name: "Hello World",
    source: `(display "Hello, World!")
(newline)`
  },
  {
    name: "Game Loop",
    source: `;;; Bouncing ball with FPS counter
(define x 100)
(define y 100)
(define dx 4)
(define dy 3)
(define frames 0)
(define start-time (current-milliseconds))

(define (game-loop)
  (canvas-clear)

  ;; Move ball
  (set! x (+ x dx))
  (set! y (+ y dy))

  ;; Bounce off walls
  (when (or (> x (- (canvas-width) 15)) (< x 15))
    (set! dx (- 0 dx)))
  (when (or (> y (- (canvas-height) 15)) (< y 15))
    (set! dy (- 0 dy)))

  ;; Draw ball
  (canvas-set-fill-color 50 200 100)
  (canvas-fill-circle x y 15)

  ;; FPS counter
  (set! frames (+ frames 1))
  (define elapsed (- (current-milliseconds) start-time))
  (define fps (if (> elapsed 0)
                  (/ (* frames 1000) elapsed)
                  0))
  (canvas-set-fill-color 255 255 255)
  (canvas-draw-text 10 24
    (string-append "FPS: " (number->string fps)))

  ;; Yield to browser, resume on next animation frame
  (yield)
  (game-loop))

(game-loop)`
  }
];
