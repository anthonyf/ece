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
  (define pi-over-30 0.10472)

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
           (total-seconds (quotient ms 1000))
           (second (modulo total-seconds 60))
           (minute (modulo (quotient total-seconds 60) 60))
           (hour (modulo (quotient total-seconds 3600) 12))
           (sa (- (* second pi-over-30) pi-over-2))
           (ma (- (* (+ minute (/ second 60)) pi-over-30) pi-over-2))
           (ha (- (* (+ hour (/ minute 60)) pi-over-6) pi-over-2)))

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
