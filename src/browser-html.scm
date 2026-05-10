;;; ECE Browser HTML module
;;; Module exports for the global browser HTML helpers in browser-lib.scm.

(define-module (ece browser html)
  (import (ece browser dom))
  (export html-render
          html-render-fragment
          html-escape
          render-html!)

  (define html-render (%global-ref html-render))
  (define html-render-fragment (%global-ref html-render-fragment))
  (define html-escape (%global-ref html-escape))

  (define (render-html! element node)
    (set-html! element (html-render node))))
