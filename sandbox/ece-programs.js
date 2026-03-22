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
  },
  {
    name: "Sierpinski Triangle",
    source: `;;; Sierpinski Triangle via chaos game
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

(canvas-clear)

(define (plot batch)
  (canvas-set-fill-color 100 200 255)
  (define (go n)
    (when (> n 0)
      (set! total (+ total 1))
      (define r (random 3))
      (define vx (cond ((= r 0) v1x) ((= r 1) v2x) (else v3x)))
      (define vy (cond ((= r 0) v1y) ((= r 1) v2y) (else v3y)))
      (set! px (* 0.5 (+ px vx)))
      (set! py (* 0.5 (+ py vy)))
      (canvas-fill-rect px py 1 1)
      (go (- n 1))))
  (go batch)
  (when (< total 30000)
    (yield)
    (plot batch)))

(plot 500)`
  },
  {
    name: "Starfield",
    source: `;;; Starfield — stars flying outward from center
(define w (canvas-width))
(define h (canvas-height))
(define cx (* 0.5 w))
(define cy (* 0.5 h))
(define n 250)

;; Each star: angle (fixed), distance (grows each frame)
(define star-angle (make-vector n 0))
(define star-dist  (make-vector n 0))
(define star-speed (make-vector n 0))

;; Initialize with random angles and staggered distances
(define (init-star i)
  (vector-set! star-angle i (* (random 6283) 0.001))
  (vector-set! star-dist  i (random 400))
  (vector-set! star-speed i (+ 2 (random 4))))

(define (init i)
  (when (< i n) (init-star i) (init (+ i 1))))
(init 0)

(define (draw)
  (canvas-clear)

  (define (update i)
    (when (< i n)
      (define d (+ (vector-ref star-dist i) (vector-ref star-speed i)))
      (define a (vector-ref star-angle i))
      (define px (+ cx (* d (cos a))))
      (define py (+ cy (* d (sin a))))

      ;; Off screen? Reset to center with new angle
      (when (or (< px -10) (> px (+ w 10)) (< py -10) (> py (+ h 10)))
        (set! d 0)
        (vector-set! star-angle i (* (random 6283) 0.001))
        (vector-set! star-speed i (+ 2 (random 4))))
      (vector-set! star-dist i d)

      ;; Draw: brightness and size grow with distance
      (define bright (+ 60 (arithmetic-shift d -1)))
      (when (> bright 255) (set! bright 255))
      (define sz (+ 2 (arithmetic-shift d -7)))
      (canvas-set-fill-color bright bright bright)
      (canvas-fill-rect px py sz sz)
      (update (+ i 1))))

  (update 0)
  (yield)
  (draw))

(draw)`
  },
  {
    name: "Analog Clock",
    source: `;;; Analog clock with hour, minute, second hands
(define w (canvas-width))
(define h (canvas-height))
(define cx (arithmetic-shift w -1))
(define cy (arithmetic-shift h -1))
(define radius (- (arithmetic-shift (if (< w h) w h) -1) 30))

;; pre-computed: pi/6 and pi/2
(define pi-over-6 0.5236)
(define pi-over-2 1.5708)
(define pi-over-30 0.10472)

(define (draw-clock)
  (canvas-clear)

  ;; Hour marks
  (canvas-set-fill-color 180 180 180)
  (define (marks i)
    (when (< i 12)
      (define a (- (* i pi-over-6) pi-over-2))
      (canvas-fill-circle
        (+ cx (* radius (cos a)))
        (+ cy (* radius (sin a)))
        4)
      (marks (+ i 1))))
  (marks 0)

  ;; Wall clock time (ms since midnight)
  (define ms (wall-clock-ms))

  ;; Second hand: full rotation every 60s = 60000ms
  (define sec-frac (modulo ms 60000))
  (define sa (- (* sec-frac 0.0001047) pi-over-2))

  ;; Minute hand: full rotation every 60min = 3600000ms
  (define min-frac (modulo ms 3600000))
  (define ma (- (* min-frac 0.00000175) pi-over-2))

  ;; Hour hand: full rotation every 12h = 43200000ms
  (define hr-frac (modulo ms 43200000))
  (define ha (- (* hr-frac 0.000000145) pi-over-2))

  ;; Draw hand as a thin solid rectangle along the angle
  (define (hand angle len r g b thickness)
    (canvas-set-fill-color r g b)
    (define half (arithmetic-shift thickness -1))
    (define dx (cos angle))
    (define dy (sin angle))
    (define (step t)
      (when (< t len)
        (canvas-fill-rect
          (- (+ cx (* t dx)) half)
          (- (+ cy (* t dy)) half)
          thickness thickness)
        (step (+ t 2))))
    (step 0))

  (hand ha (* radius 0.5) 220 220 220 6)
  (hand ma (* radius 0.7) 180 180 255 4)
  (hand sa (* radius 0.85) 255 80 80 2)

  ;; Center dot
  (canvas-set-fill-color 255 255 255)
  (canvas-fill-circle cx cy 5)

  (yield)
  (draw-clock))

(draw-clock)`
  }
];
