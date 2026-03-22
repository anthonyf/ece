;;; ECE Browser Library
;;; DOM access, event handling, and CSS helpers built on FFI primitives.
;;; Load after bootstrap on the browser platform.

;; ── Type conversion wrappers ──

(define (js-eval str) (%js-eval str))
(define (js-get obj prop) (%js-get obj prop))
(define (js-set! obj prop val) (%js-set! obj prop val))
(define (js-callback proc) (%js-callback proc))
(define (js-ref->number ref) (%js-ref->number ref))
(define (js-ref->string ref) (%js-ref->string ref))
(define (js-number n) (%js-number n))
(define (js-string s) (%js-string s))
(define (js-null? ref) (%js-null? ref))
(define (js-release! ref) (%js-release! ref))
(define (js-ref? val) (%js-ref? val))

;; ── Variadic js-call ──

(define (js-call obj method . args)
  (%js-call obj method args))

;; ── DOM access helpers ──

(define *js-document* #f)

(define (js-document)
  (when (not *js-document*)
    (set! *js-document* (js-eval "document")))
  *js-document*)

(define (get-element-by-id id)
  (js-call (js-document) "getElementById" (js-string id)))

(define (query-selector-all sel)
  (js-call (js-document) "querySelectorAll" (js-string sel)))

(define (set-text! el text)
  (js-set! el "textContent" (js-string text)))

(define (set-html! el html)
  (js-set! el "innerHTML" (js-string html)))

;; ── Event handling ──

(define (add-event-listener! el event handler)
  (js-call el "addEventListener"
           (js-string event)
           (js-callback handler)))

;; ── CSS class manipulation ──

(define (class-add! el cls)
  (js-call (js-get el "classList") "add" (js-string cls)))

(define (class-remove! el cls)
  (js-call (js-get el "classList") "remove" (js-string cls)))

;; ── Canvas (via FFI) ──

(define *canvas-ctx* #f)
(define *js-math* #f)

(define (canvas-ctx)
  (when (not *canvas-ctx*)
    (set! *canvas-ctx*
          (js-call (get-element-by-id "sandbox-canvas")
                   "getContext" (js-string "2d"))))
  *canvas-ctx*)

(define (canvas-clear)
  (let ((ctx (canvas-ctx)))
    (js-call ctx "clearRect"
             (js-number 0) (js-number 0)
             (js-get (js-get ctx "canvas") "width")
             (js-get (js-get ctx "canvas") "height"))))

(define (canvas-set-fill-color r g b)
  (js-set! (canvas-ctx) "fillStyle"
           (js-string (string-append "rgb("
                                     (number->string r) "," (number->string g) "," (number->string b) ")"))))

(define (canvas-fill-rect x y w h)
  (js-call (canvas-ctx) "fillRect"
           (js-number x) (js-number y) (js-number w) (js-number h)))

(define (canvas-fill-circle x y r)
  (let ((ctx (canvas-ctx)))
    (js-call ctx "beginPath")
    (js-call ctx "arc"
             (js-number x) (js-number y) (js-number r)
             (js-number 0) (js-number 6.283185307179586))
    (js-call ctx "fill")))

(define (canvas-draw-text x y str)
  (let ((ctx (canvas-ctx)))
    (js-set! ctx "font" (js-string "20px monospace"))
    (js-call ctx "fillText" (js-string str) (js-number x) (js-number y))))

(define (canvas-width)
  (js-ref->number (js-get (js-get (canvas-ctx) "canvas") "width")))

(define (canvas-height)
  (js-ref->number (js-get (js-get (canvas-ctx) "canvas") "height")))

;; ── Trig (via FFI to Math) ──

(define (js-math)
  (when (not *js-math*)
    (set! *js-math* (js-eval "Math")))
  *js-math*)

(define (sin x)
  (js-ref->number (js-call (js-math) "sin" (js-number x))))

(define (cos x)
  (js-ref->number (js-call (js-math) "cos" (js-number x))))

;; ── Timing (via FFI) ──

(define (wall-clock-ms)
  (let* ((d (js-eval "new Date()"))
         (h (js-ref->number (js-call d "getHours")))
         (m (js-ref->number (js-call d "getMinutes")))
         (s (js-ref->number (js-call d "getSeconds")))
         (ms (js-ref->number (js-call d "getMilliseconds"))))
    (js-release! d)
    (+ (* (+ (* (+ (* h 60) m) 60) s) 1000) ms)))
