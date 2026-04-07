;;; Analog clock with hour, minute, second hands
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

(draw-clock)
