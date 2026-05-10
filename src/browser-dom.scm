;;; ECE Browser DOM module
;;; Thin module wrapper around the browser FFI helpers in browser-lib.scm.

(define-module (ece browser dom)
  (export document
          body
          element-by-id
          query-selector-all
          create-element
          append-child!
          set-text!
          set-html!
          add-event-listener!
          add-class!
          remove-class!)

  (define (document)
    (js-document))

  (define (body)
    (js-get (document) "body"))

  (define (element-by-id id)
    (get-element-by-id id))

  (define query-selector-all (%global-ref query-selector-all))

  (define (create-element tag)
    (js-call (document) "createElement" (js-string tag)))

  (define (append-child! parent child)
    (js-call parent "appendChild" child))

  (define set-text! (%global-ref set-text!))

  (define set-html! (%global-ref set-html!))

  (define add-event-listener! (%global-ref add-event-listener!))

  (define add-class! (%global-ref class-add!))

  (define remove-class! (%global-ref class-remove!)))
