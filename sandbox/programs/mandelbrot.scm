;;; Mandelbrot Set — progressive scanline renderer
(define w (canvas-width))
(define h (canvas-height))

;; Complex plane bounds
(define real-min -2.5)
(define real-max 1.0)
(define imag-min -1.2)
(define imag-max 1.2)

(define max-iter 100)

;; Map pixel to complex plane
(define (px->real x) (+ real-min (* (/ x w) (- real-max real-min))))
(define (px->imag y) (+ imag-min (* (/ y h) (- imag-max imag-min))))

;; Iterate z = z^2 + c, return iteration count
(define (mandelbrot cr ci)
  (let loop ((zr 0.0) (zi 0.0) (i 0))
    (if (= i max-iter)
        max-iter
        (let ((zr2 (* zr zr))
              (zi2 (* zi zi)))
          (if (> (+ zr2 zi2) 4.0)
              i
              (loop (+ (- zr2 zi2) cr)
                    (+ (* 2.0 zr zi) ci)
                    (+ i 1)))))))

;; Map iteration count to RGB color
(define (iter->color n)
  (if (= n max-iter)
      (begin (canvas-set-fill-color 0 0 0))
      (let ((t (* n 3)))
        (canvas-set-fill-color
         (modulo (* t 7) 256)
         (modulo (* t 5) 256)
         (modulo (* t 11) 256)))))

;; Render one row of pixels
(define (render-row y)
  (let col ((x 0))
    (when (< x w)
      (let ((n (mandelbrot (px->real x) (px->imag y))))
        (iter->color n)
        (canvas-fill-rect x y 1 1))
      (col (+ x 1)))))

;; Progressive rendering: row by row
(canvas-clear)

(define (render y)
  (when (< y h)
    (render-row y)
    (yield)
    (render (+ y 1))))

(render 0)
