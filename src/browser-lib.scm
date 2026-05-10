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

;; ── HTML rendering helpers ──

(define (html-keyword-name value)
  (let ((text (symbol->string value)))
    (substring text 1 (string-length text))))

(define (html-write-escape text port)
  (let ((str (cond
              ((string? text) text)
              ((number? text) (number->string text))
              ((symbol? text) (symbol->string text))
              (else (write-to-string-flat text)))))
    (let loop ((i 0))
      (when (< i (string-length str))
        (let* ((ch (string-ref str i))
               (code (char->integer ch)))
          (cond
           ((= code 38) (write-string "&amp;" port))
           ((= code 60) (write-string "&lt;" port))
           ((= code 62) (write-string "&gt;" port))
           ((= code 34) (write-string "&quot;" port))
           (else (write-char ch port)))
          (loop (+ i 1)))))))

(define (html-escape text)
  (let ((port (open-output-string)))
    (html-write-escape text port)
    (get-output-string port)))

(define (html-split-attrs items)
  (let loop ((rest items) (attrs '()))
    (cond
     ((and (pair? rest) (keyword? (car rest)))
      (when (null? (cdr rest))
        (error "html: attribute is missing a value" (car rest)))
      (loop (cddr rest)
            (cons (cons (html-keyword-name (car rest)) (cadr rest))
                  attrs)))
     (else (list (reverse attrs) rest)))))

(define (html-write-attr attr port)
  (let ((name (car attr))
        (value (cdr attr)))
    (cond
     ((eq? value #f) "")
     ((eq? value #t)
      (write-char #\space port)
      (write-string name port))
     (else
      (write-char #\space port)
      (write-string name port)
      (write-string "=\"" port)
      (html-write-escape value port)
      (write-char #\" port)))))

(define (html-render-attr attr)
  (let ((port (open-output-string)))
    (html-write-attr attr port)
    (get-output-string port)))

(define (html-write-attrs attrs port)
  (let loop ((rest attrs))
    (when (pair? rest)
      (html-write-attr (car rest) port)
      (loop (cdr rest)))))

(define (html-render-attrs attrs)
  (let ((port (open-output-string)))
    (html-write-attrs attrs port)
    (get-output-string port)))

(define (html-write-children children port)
  (let loop ((rest children))
    (when (pair? rest)
      (html-write-node (car rest) port)
      (loop (cdr rest)))))

(define (html-render-children children)
  (let ((port (open-output-string)))
    (html-write-children children port)
    (get-output-string port)))

(define (html-write-element form port)
  (when (not (keyword? (car form)))
    (error "html: element form must begin with a :tag symbol" form))
  (let* ((tag (html-keyword-name (car form)))
         (parts (html-split-attrs (cdr form)))
         (attrs (car parts))
         (children (cadr parts)))
    (write-char #\< port)
    (write-string tag port)
    (html-write-attrs attrs port)
    (write-char #\> port)
    (html-write-children children port)
    (write-string "</" port)
    (write-string tag port)
    (write-char #\> port)))

(define (html-render-element form)
  (let ((port (open-output-string)))
    (html-write-element form port)
    (get-output-string port)))

(define (html-write-node node port)
  (cond
   ((null? node) #f)
   ((pair? node) (html-write-element node port))
   (else (html-write-escape node port))))

(define (html-render node)
  (let ((port (open-output-string)))
    (html-write-node node port)
    (get-output-string port)))

(define (html-render-fragment nodes)
  (html-render-children nodes))

(define-macro (html . nodes)
  `(html-render-fragment ',nodes))

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

(define (sqrt x)
  (js-ref->number (js-call (js-math) "sqrt" (js-number x))))

;; ── Timing (via FFI) ──

(define (wall-clock-ms)
  (let* ((d (js-eval "new Date()"))
         (h (js-ref->number (js-call d "getHours")))
         (m (js-ref->number (js-call d "getMinutes")))
         (s (js-ref->number (js-call d "getSeconds")))
         (ms (js-ref->number (js-call d "getMilliseconds"))))
    (js-release! d)
    (+ (* (+ (* (+ (* h 60) m) 60) s) 1000) ms)))

;; ── Dev-server live update policy ──

(define (browser-dev-client/%error-message e)
  (if (error-object? e)
      (error-object-message e)
      (write-to-string-flat e)))

(define (browser-dev-client-handle-source-update path source)
  "Evaluate a source-update delivered by ece-serve. JavaScript owns the
WebSocket capability and passes decoded message fields here; ECE owns the
reload/evaluation policy and formats the user-facing status text."
  (let ((capture (open-output-string)))
    (guard
     (e (#t
         (let ((output (get-output-string capture)))
           (string-append
            (if (> (string-length output) 0)
                (string-append output "\n")
                "")
            ";; source update failed: "
            path
            "\nError: "
            (browser-dev-client/%error-message e)))))
     (let* ((value (parameterize ((current-output-port capture))
                     (eval-string-last source)))
            (output (get-output-string capture))
            (value-text (write-to-string-flat value)))
       (string-append
        (if (> (string-length output) 0)
            (string-append output "\n")
            "")
        ";; source updated: "
        path
        (if (> (string-length value-text) 0)
            (string-append "\n" value-text)
            ""))))))
