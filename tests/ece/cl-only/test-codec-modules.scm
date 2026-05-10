;;; Tests for codec module boundaries.

(define (codec-modules/test-cleanup! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (codec-modules/write-file filename text)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda () (display text port))
     (lambda () (when port (close-output-port port))))))

(define codec-modules/unit-ids
  '((module (ece json) 0)
    (module (ece websocket codec) 0)))

(define codec-modules/modules-loaded? #f)

(define (codec-modules/ensure-modules!)
  (when (not codec-modules/modules-loaded?)
    (codec-modules/test-cleanup! codec-modules/unit-ids)
    (compile-system
     (list "src/base64.scm"
           "src/sha1.scm"
           "src/json.scm"
           "src/json-module.scm"
           "src/websocket-codec.scm"
           "src/websocket-codec-module.scm")
     ".tmp/codec-modules.ecec")
    (load-bundle ".tmp/codec-modules.ecec")
    (set! codec-modules/modules-loaded? #t)))

(test "codec modules: json exports public encoder operations" (lambda ()
  (codec-modules/ensure-modules!)
  (for-each
   (lambda (name)
     (assert-true
      (procedure? (archive/module-export '(ece json) name))))
   '(json-encode
     json-encode-string
     json-encode-object
     json-encode-array
     json-source-update
     json-eval-source
     json-program-reload))))

(test "codec modules: websocket exports public codec operations" (lambda ()
  (codec-modules/ensure-modules!)
  (for-each
   (lambda (name)
     (assert-true
      (procedure? (archive/module-export '(ece websocket codec) name))))
   '(ws-compute-accept-key
     ws-encode-text-frame
     ws-encode-close-frame
     ws-encode-ping-frame
     ws-encode-pong-frame
     ws-decode-frame
     ws-frame?
     ws-frame-opcode
     ws-frame-payload-bytes
     ws-frame-payload-text
     ws-frame-total-length))))

(test "codec modules: exported operations preserve codec behavior" (lambda ()
  (codec-modules/ensure-modules!)
  (let* ((json-object (archive/module-export '(ece json) 'json-encode-object))
         (ws-accept (archive/module-export '(ece websocket codec)
                                           'ws-compute-accept-key))
         (ws-decode (archive/module-export '(ece websocket codec)
                                           'ws-decode-frame))
         (ws-frame-text (archive/module-export '(ece websocket codec)
                                               'ws-frame-payload-text))
         (frame (ws-decode '(129 133 55 250 33 61 127 159 77 81 88))))
    (assert-equal
     (json-object '(("type" . "ready") ("count" . 2)))
     "{\"type\":\"ready\",\"count\":2}")
    (assert-equal
     (ws-accept "dGhlIHNhbXBsZSBub25jZQ==")
     "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")
    (assert-equal (ws-frame-text frame) "Hello"))))

(test "codec modules: imported names work in app modules" (lambda ()
  (codec-modules/ensure-modules!)
  (let ((unit-id '(module (codec-modules test-app) 0))
        (source ".tmp/codec-modules-test-app.scm")
        (bundle ".tmp/codec-modules-test-app.ecec"))
    (dynamic-wind
     (lambda () (codec-modules/test-cleanup! (list unit-id)))
     (lambda ()
       (codec-modules/write-file
        source
        "(define-module (codec-modules test-app)\n  (import (ece json) (ece websocket codec))\n  (export describe)\n  (define (describe)\n    (let ((frame (ws-decode-frame '(129 133 55 250 33 61 127 159 77 81 88))))\n      (json-encode-object\n       (list (cons \"message\" (ws-frame-payload-text frame))\n             (cons \"encoded\" (json-encode-array '(1 2 3))))))))\n")
       (compile-system (list source) bundle)
       (load-bundle bundle)
       (assert-equal
        ((archive/module-export '(codec-modules test-app) 'describe))
        "{\"message\":\"Hello\",\"encoded\":\"[1,2,3]\"}"))
     (lambda () (codec-modules/test-cleanup! (list unit-id)))))))
