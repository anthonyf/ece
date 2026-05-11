;;; CL-only documentation metadata tests.

(test "define-macro/doc rejects non-list specs" (lambda ()
  (assert-error-message
   (mc-expand-macro-at-compile-time
    (get-macro 'define-macro/doc)
    '(doc-bad-macro "Bad." 1))
   "define-macro/doc: expected (name args...)")))
