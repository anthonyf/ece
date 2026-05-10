;;; ECE Browser Canvas module
;;; Module exports for canvas helpers in browser-lib.scm.

(define-module (ece browser canvas)
  (import (ece browser dom))
  (export canvas-element-id
          canvas-set-element-id!
          canvas-reset-context!
          canvas-context
          canvas-clear
          canvas-set-fill-color
          canvas-fill-rect
          canvas-fill-circle
          canvas-draw-text
          canvas-width
          canvas-height
          clear!
          set-fill-color!
          fill-rect!
          fill-circle!
          draw-text!
          width
          height)

  (define canvas-element-id (%global-ref canvas-element-id))
  (define canvas-set-element-id! (%global-ref canvas-set-element-id!))
  (define canvas-reset-context! (%global-ref canvas-reset-context!))
  (define canvas-context (%global-ref canvas-context))
  (define canvas-clear (%global-ref canvas-clear))
  (define canvas-set-fill-color (%global-ref canvas-set-fill-color))
  (define canvas-fill-rect (%global-ref canvas-fill-rect))
  (define canvas-fill-circle (%global-ref canvas-fill-circle))
  (define canvas-draw-text (%global-ref canvas-draw-text))
  (define canvas-width (%global-ref canvas-width))
  (define canvas-height (%global-ref canvas-height))

  (define clear! canvas-clear)
  (define set-fill-color! canvas-set-fill-color)
  (define fill-rect! canvas-fill-rect)
  (define fill-circle! canvas-fill-circle)
  (define draw-text! canvas-draw-text)
  (define width canvas-width)
  (define height canvas-height))
