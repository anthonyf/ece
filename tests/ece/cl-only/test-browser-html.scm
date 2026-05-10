;;; Tests for the browser HTML module.

(define (browser-html/test-cleanup! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (browser-html/write-file filename text)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda () (display text port))
     (lambda () (when port (close-output-port port))))))

(define browser-html/module-unit-ids
  '((module (ece browser dom) 0)
    (module (ece browser html) 0)))

(define browser-html/modules-loaded? #f)

(define (browser-html/ensure-modules!)
  (when (not browser-html/modules-loaded?)
    (browser-html/test-cleanup! browser-html/module-unit-ids)
    (compile-system
     (list "src/browser-lib.scm" "src/browser-dom.scm" "src/browser-html.scm")
     ".tmp/browser-html-modules.ecec")
    (load-bundle ".tmp/browser-html-modules.ecec")
    (set! browser-html/modules-loaded? #t)))

(test "browser html: renders element trees" (lambda ()
  (browser-html/ensure-modules!)
  (let ((render-fragment
         (archive/module-export '(ece browser html) 'html-render-fragment)))
    (assert-equal
     (render-fragment
      '((:main :id "app"
         (:canvas :id "sandbox-canvas")
         (:p "Hello & <ECE>"))))
     "<main id=\"app\"><canvas id=\"sandbox-canvas\"></canvas><p>Hello &amp; &lt;ECE&gt;</p></main>"))))

(test "browser html: renders boolean and omitted attributes" (lambda ()
  (browser-html/ensure-modules!)
  (let ((render
         (archive/module-export '(ece browser html) 'html-render)))
    (assert-equal
     (render '(:button :disabled #t :data-hidden #f "Save"))
     "<button disabled>Save</button>"))))

(test "browser html: escapes attribute values" (lambda ()
  (browser-html/ensure-modules!)
  (let ((render
         (archive/module-export '(ece browser html) 'html-render)))
    (assert-equal
     (render '(:input :value "a \"quoted\" & <tag>"))
     "<input value=\"a &quot;quoted&quot; &amp; &lt;tag&gt;\"></input>"))))

(test "browser html: html macro renders a quoted fragment" (lambda ()
  (browser-html/ensure-modules!)
  (assert-equal
   (eval-string-last "(html (:p :class \"notice\" \"ready\"))")
   "<p class=\"notice\">ready</p>")))

(test "browser html: imported module export works in app modules" (lambda ()
  (browser-html/ensure-modules!)
  (let ((unit-id '(module (browser-html test-app) 0))
        (source ".tmp/browser-html-test-app.scm")
        (bundle ".tmp/browser-html-test-app.ecec"))
    (dynamic-wind
     (lambda () (browser-html/test-cleanup! (list unit-id)))
     (lambda ()
       (browser-html/write-file
        source
        "(define-module (browser-html test-app)\n  (import (ece browser html))\n  (export page)\n  (define page (html-render '(:section :id \"root\" (:h1 \"ECE\"))))\n  page)\n")
       (compile-system (list source) bundle)
       (load-bundle bundle)
       (assert-equal
        (archive/module-export '(browser-html test-app) 'page)
        "<section id=\"root\"><h1>ECE</h1></section>"))
     (lambda () (browser-html/test-cleanup! (list unit-id)))))))
