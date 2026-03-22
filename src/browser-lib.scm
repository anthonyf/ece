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
