;;; Tests for the browser dev module.

(define (browser-dev/test-cleanup! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (browser-dev/write-file filename text)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda () (display text port))
     (lambda () (when port (close-output-port port))))))

(define browser-dev/module-unit-ids
  '((module (ece browser dev) 0)))

(define browser-dev/modules-loaded? #f)

(define (browser-dev/ensure-modules!)
  (when (not browser-dev/modules-loaded?)
    (browser-dev/test-cleanup! browser-dev/module-unit-ids)
    (compile-system
     (list "src/browser-lib.scm" "src/browser-dev.scm")
     ".tmp/browser-dev-modules.ecec")
    (load-bundle ".tmp/browser-dev-modules.ecec")
    (set! browser-dev/modules-loaded? #t)))

(test "browser dev: exports live update policy names" (lambda ()
  (browser-dev/ensure-modules!)
  (for-each
   (lambda (name)
     (assert-true
      (procedure? (archive/module-export '(ece browser dev) name))))
   '(dev-client-error-message
     handle-source-update
     browser-dev-client/%error-message
     browser-dev-client-handle-source-update))))

(test "browser dev: source update captures output and result" (lambda ()
  (browser-dev/ensure-modules!)
  (let* ((handle-source-update
          (archive/module-export '(ece browser dev) 'handle-source-update))
         (text
          (handle-source-update
           "demo.scm"
           "(begin (display \"Hello from module\") 42)")))
    (assert-true (string-contains? text "Hello from module"))
    (assert-true (string-contains? text ";; source updated: demo.scm"))
    (assert-true (string-contains? text "42")))))

(test "browser dev: source update reports handled evaluation errors" (lambda ()
  (browser-dev/ensure-modules!)
  (let* ((handle-source-update
          (archive/module-export '(ece browser dev) 'handle-source-update))
         (text
          (handle-source-update
           "broken.scm"
           "(begin (display \"before failure\") missing-browser-dev-symbol)")))
    (assert-true (string-contains? text "before failure"))
    (assert-true (string-contains? text ";; source update failed: broken.scm"))
    (assert-true (string-contains? text "Error:")))))

(test "browser dev: imported aliases work in app modules" (lambda ()
  (browser-dev/ensure-modules!)
  (let ((unit-id '(module (browser-dev test-app) 0))
        (source ".tmp/browser-dev-test-app.scm")
        (bundle ".tmp/browser-dev-test-app.ecec"))
    (dynamic-wind
     (lambda () (browser-dev/test-cleanup! (list unit-id)))
     (lambda ()
       (browser-dev/write-file
        source
        "(define-module (browser-dev test-app)\n  (import (ece browser dev))\n  (export ready?)\n  (define ready? (and (procedure? handle-source-update)\n                      (procedure? dev-client-error-message))))\n")
       (compile-system (list source) bundle)
       (load-bundle bundle)
       (assert-true
        (archive/module-export '(browser-dev test-app) 'ready?)))
     (lambda () (browser-dev/test-cleanup! (list unit-id)))))))
