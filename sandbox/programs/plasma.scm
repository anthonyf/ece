;;; Plasma — animated sine-wave color field
(define w (canvas-width))
(define h (canvas-height))

(define block 4)
(define cols (/ w block))
(define rows (/ h block))

(define time 0.0)

(define (plasma-value x y t)
  (+ (sin (+ (* x 0.05) t))
     (sin (+ (* y 0.07) (* t 1.3)))
     (sin (+ (* (+ x y) 0.04) (* t 0.7)))
     (sin (+ (* (sqrt (+ (* x x) (* y y))) 0.05) (* t 0.5)))))

(define (draw-frame)
  (let row-loop ((gy 0))
    (when (< gy rows)
      (let col-loop ((gx 0))
        (when (< gx cols)
          (let* ((px (* gx block))
                 (py (* gy block))
                 (v (plasma-value px py time))
                 (r (truncate (+ 128 (* 127 (sin (* v 3.14159))))))
                 (g (truncate (+ 128 (* 127 (sin (+ (* v 3.14159) 2.094))))))
                 (b (truncate (+ 128 (* 127 (sin (+ (* v 3.14159) 4.189)))))))
            (canvas-set-fill-color r g b)
            (canvas-fill-rect px py block block))
          (col-loop (+ gx 1))))
      (row-loop (+ gy 1)))))

(define (animate)
  (draw-frame)
  (set! time (+ time 0.1))
  (yield)
  (animate))

(animate)
