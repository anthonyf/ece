;;; Analog clock with hour, minute, second hands
(define-module (sandbox analog-clock)
  (import (ece browser canvas))
  (export start draw-clock)

  (define w (canvas-width))
  (define h (canvas-height))
  (define cx (arithmetic-shift w -1))
  (define cy (arithmetic-shift h -1))
  (define radius (- (arithmetic-shift (if (< w h) w h) -1) 30))

  ;; pre-computed: pi/6 and pi/2
  (define pi-over-6 0.5236)
  (define pi-over-2 1.5708)

  (define (draw-clock)
    (canvas-clear)

    ;; Hour marks
    (canvas-set-fill-color 180 180 180)
    (let marks ((i 0))
      (when (< i 12)
        (let* ((a (- (* i pi-over-6) pi-over-2)))
          (canvas-fill-circle
            (+ cx (* radius (cos a)))
            (+ cy (* radius (sin a)))
            4)
          (marks (+ i 1)))))

    ;; Wall clock time -> hand angles
    (let* ((ms (wall-clock-ms))
           ;; Second hand: full rotation every 60s
           (sec-frac (modulo ms 60000))
           (sa (- (* sec-frac 0.0001047) pi-over-2))
           ;; Minute hand: full rotation every 60min
           (min-frac (modulo ms 3600000))
           (ma (- (* min-frac 0.00000175) pi-over-2))
           ;; Hour hand: full rotation every 12h
           (hr-frac (modulo ms 43200000))
           (ha (- (* hr-frac 0.000000145) pi-over-2)))

      ;; Draw hand as a thin solid rectangle along the angle
      (define (hand angle len r g b thickness)
        (canvas-set-fill-color r g b)
        (let* ((half (arithmetic-shift thickness -1))
               (dx (cos angle))
               (dy (sin angle)))
          (let step ((t 0))
            (when (< t len)
              (canvas-fill-rect
                (- (+ cx (* t dx)) half)
                (- (+ cy (* t dy)) half)
                thickness thickness)
              (step (+ t 2))))))

      (hand ha (* radius 0.5) 220 220 220 6)
      (hand ma (* radius 0.7) 180 180 255 4)
      (hand sa (* radius 0.85) 255 80 80 2)

      ;; Center dot
      (canvas-set-fill-color 255 255 255)
      (canvas-fill-circle cx cy 5)

      (yield)
      (draw-clock)))

  (define (start)
    (draw-clock))

  (start))
