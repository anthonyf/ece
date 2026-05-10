;;; Tests for the browser canvas module.

(define (browser-canvas/test-cleanup! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (browser-canvas/write-file filename text)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda () (display text port))
     (lambda () (when port (close-output-port port))))))

(define browser-canvas/module-unit-ids
  '((module (ece browser dom) 0)
    (module (ece browser canvas) 0)))

(define browser-canvas/modules-loaded? #f)

(define (browser-canvas/ensure-modules!)
  (when (not browser-canvas/modules-loaded?)
    (browser-canvas/test-cleanup! browser-canvas/module-unit-ids)
    (compile-system
     (list "src/browser-lib.scm" "src/browser-dom.scm" "src/browser-canvas.scm")
     ".tmp/browser-canvas-modules.ecec")
    (load-bundle ".tmp/browser-canvas-modules.ecec")
    (set! browser-canvas/modules-loaded? #t)))

(test "browser canvas: exports compatibility and short drawing names" (lambda ()
  (browser-canvas/ensure-modules!)
  (for-each
   (lambda (name)
     (assert-true
      (procedure? (archive/module-export '(ece browser canvas) name))))
   '(canvas-clear
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
     height))))

(test "browser canvas: defaults to the sandbox canvas element id" (lambda ()
  (browser-canvas/ensure-modules!)
  (let ((element-id (archive/module-export '(ece browser canvas) 'canvas-element-id))
        (set-element-id! (archive/module-export '(ece browser canvas) 'canvas-set-element-id!)))
    (dynamic-wind
     (lambda () (set-element-id! "sandbox-canvas"))
     (lambda ()
       (assert-equal (element-id) "sandbox-canvas")
       (assert-equal (set-element-id! "game-canvas") "game-canvas")
       (assert-equal (element-id) "game-canvas"))
     (lambda () (set-element-id! "sandbox-canvas"))))))

(test "browser canvas: imported aliases work in app modules" (lambda ()
  (browser-canvas/ensure-modules!)
  (let ((unit-id '(module (browser-canvas test-app) 0))
        (source ".tmp/browser-canvas-test-app.scm")
        (bundle ".tmp/browser-canvas-test-app.ecec"))
    (dynamic-wind
     (lambda () (browser-canvas/test-cleanup! (list unit-id)))
     (lambda ()
       (browser-canvas/write-file
        source
        "(define-module (browser-canvas test-app)\n  (import (ece browser canvas))\n  (export ready?)\n  (define ready? (and (procedure? clear!)\n                      (procedure? set-fill-color!)\n                      (procedure? width))))\n")
       (compile-system (list source) bundle)
       (load-bundle bundle)
       (assert-true
        (archive/module-export '(browser-canvas test-app) 'ready?)))
     (lambda () (browser-canvas/test-cleanup! (list unit-id)))))))
