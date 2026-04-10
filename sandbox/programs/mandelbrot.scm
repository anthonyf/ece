;;; Mandelbrot Set — progressive scanline renderer
(define w (canvas-width))
(define h (canvas-height))

;; Complex plane bounds
(define real-min -2.5)
(define real-max 1.0)
(define imag-min -1.2)
(define imag-max 1.2)
(define real-range (- real-max real-min))
(define imag-range (- imag-max imag-min))

(define max-iter 100)

;; Shared iteration variables
(define zr 0.0)
(define zi 0.0)
(define zr2 0.0)
(define zi2 0.0)
(define iter-count 0)
(define cr 0.0)
(define ci 0.0)
(define col-x 0)
(define t 0)

(define (mandelbrot)
  (set! zr 0.0)
  (set! zi 0.0)
  (set! iter-count 0)
  (define (step)
    (when (< iter-count max-iter)
      (set! zr2 (* zr zr))
      (set! zi2 (* zi zi))
      (when (not (> (+ zr2 zi2) 4.0))
        (set! zi (+ (* 2.0 zr zi) ci))
        (set! zr (+ (- zr2 zi2) cr))
        (set! iter-count (+ iter-count 1))
        (step))))
  (step)
  iter-count)

(define (iter->color n)
  (if (= n max-iter)
      (canvas-set-fill-color 0 0 0)
      (begin
        (set! t (* n 3))
        (canvas-set-fill-color
         (modulo (* t 7) 256)
         (modulo (* t 5) 256)
         (modulo (* t 11) 256)))))

(define (render-row y)
  (set! ci (+ imag-min (* (/ y h) imag-range)))
  (set! col-x 0)
  (define (col-step)
    (when (< col-x w)
      (set! cr (+ real-min (* (/ col-x w) real-range)))
      (iter->color (mandelbrot))
      (canvas-fill-rect col-x y 1 1)
      (set! col-x (+ col-x 1))
      (col-step)))
  (col-step))

(canvas-clear)

(define (render y)
  (when (< y h)
    (render-row y)
    (yield)
    (render (+ y 1))))

(render 0)
