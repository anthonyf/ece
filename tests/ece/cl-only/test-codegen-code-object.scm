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
  (define tmp-path "/tmp/claude/test-zone-from-co.lisp")
  (generate-zone-cl-for-code-object! co "test-square" tmp-path)
  ;; Confirm the file exists and starts with the expected header.
  (define in (open-input-file tmp-path))
  (define line1 (read-line in))
  (close-input-port in)
  (assert-equal ";;;; bootstrap/test-square-zone.lisp" line1)))

(test "codegen: emitted zone contains a defun whose name matches" (lambda ()
  (define co (mc-compile-to-code-object '(+ 1 2)))
  (define tmp-path "/tmp/claude/test-zone-addone.lisp")
  (generate-zone-cl-for-code-object! co "plan-b2-addone" tmp-path)
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
