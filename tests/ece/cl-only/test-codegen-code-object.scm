;;; Codegen reads a code-object and emits a zone .lisp file with the same
;;; shape as the space-keyed path.
;;;
;;; The codegen module isn't loaded by default at test boot (it's only
;;; pulled in by the zone-generation target in the Makefile), so we load
;;; it plus its dependencies here.

(load "src/codegen-cl.scm")
(load "src/primitives.scm")
(load "src/codegen-cl-inline.scm")

(test "codegen: emits zone .lisp from a code-object" (lambda ()
  (define co (mc-compile-to-code-object '(lambda (x) (* x x))))
  (define tmp-path ".tmp/test-zone-from-co.lisp")
  (generate-zone-cl-for-code-object! co "test-square" tmp-path "test" 0)
  ;; Confirm the file exists and starts with the expected header.
  (define in (open-input-file tmp-path))
  (define line1 (read-line in))
  (close-input-port in)
  (assert-equal ";;;; .tmp/bootstrap-zones/test-square-zone.lisp" line1)))

(test "codegen: emitted zone contains a defun whose name matches" (lambda ()
  (define co (mc-compile-to-code-object '(+ 1 2)))
  (define tmp-path ".tmp/test-zone-addone.lisp")
  (generate-zone-cl-for-code-object! co "plan-b2-addone" tmp-path "test" 0)
  ;; read the file as a string and search for the defun token
  (define in (open-input-file tmp-path))
  (let loop ((saw-defun #f))
    (let ((line (read-line in)))
      (cond
       ((eof? line)
        (close-input-port in)
        (assert-equal #t saw-defun))
       ((string-contains? line "(defun zone-plan-b2-addone ")
        (loop #t))
       (else (loop saw-defun)))))))

(test "codegen: emitted zone registers under *archive-zone-fns*" (lambda ()
  (define co (mc-compile-to-code-object '(+ 1 2)))
  (define tmp-path ".tmp/test-zone-register.lisp")
  ;; co-key is an archive-index integer — matches what the archive loader
  ;; computes via archive-co-key (runtime.lisp).
  (generate-zone-cl-for-code-object! co "test-register" tmp-path "fixture" 7)
  ;; Confirm the file contains an *archive-zone-fns* setf form.
  (define in (open-input-file tmp-path))
  (let loop ((saw-register #f))
    (let ((line (read-line in)))
      (cond
       ((eof? line)
        (close-input-port in)
        (assert-equal #t saw-register))
       ((string-contains? line "*archive-zone-fns*")
        (loop #t))
       (else (loop saw-register)))))))

(test "codegen: generates zone shards from binary archive bundle" (lambda ()
  (let ((source ".tmp/test-zone-binary-src.scm")
        (bundle ".tmp/test-zone-binary.ecec")
        (out-dir ".tmp/test-zone-binary-zones"))
    (let ((out (open-output-file source)))
      (display "(define test-zone-binary-answer 44)" out)
      (newline out)
      (close-output-port out))
    (compile-system/binary (list source) bundle)
    (%make-directory out-dir)
    (let ((manifest (generate-all-zones-from-archive! bundle out-dir)))
      (assert-equal manifest ".tmp/test-zone-binary-zones/manifest.sexp")
      (let ((in (open-input-file manifest)))
        (let ((line1 (read-line in)))
          (close-input-port in)
          (assert-equal ";;;; manifest.sexp" line1)))
      (let ((in (open-input-file
                 ".tmp/test-zone-binary-zones/0-test-zone-binary-src-zones.lisp")))
        (let ((line1 (read-line in)))
          (close-input-port in)
          (assert-equal
           ";;;; .tmp/test-zone-binary-zones/0-test-zone-binary-src-zones.lisp"
           line1)))))))
