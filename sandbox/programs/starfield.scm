;;; Starfield — stars flying outward from center
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

(draw)
