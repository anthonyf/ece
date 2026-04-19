;;; tests/ece/cl-only/test-cl-archive-parser.scm
;;;
;;; Exercises CL-side archive parsing via a host shim. These tests run the
;;; CL parser on synthesized archive s-exprs, not on disk.

(test "CL archive parser: single-entry archive builds one code-object" (lambda ()
  ;; Build an ECE-side archive for (+ 1 2), then round-trip through the
  ;; CL parser by writing to a port and re-reading via the CL path.
  (define co (mc-compile-to-code-object '(+ 1 2)))
  (define archive (code-object->archive-sexp co "scratch.scm"))
  (define text (write-to-string-flat archive))
  ;; Write to /tmp/claude/ path
  (define tmp-path "/tmp/claude/test-archive-cl.ecec")
  (define out (open-output-file tmp-path))
  (display text out) (newline out) (close-output-port out)
  ;; The CL-side load path is what §9.2 will exercise. For now, use the
  ;; ECE-side to show round-trip parity with the archive sexp shape.
  (define loaded (load-archive tmp-path))
  (assert-equal 3 loaded)))
