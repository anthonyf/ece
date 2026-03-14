;;; Error and assert tests

(test "assert passes on truthy" (lambda ()
  (assert #t)
  (assert-true #t)))

(test "assert-error on division by zero" (lambda ()
  (assert-error (/ 1 0))))

(test "assert-error on unbound variable" (lambda ()
  (assert-error this-variable-does-not-exist-12345)))

(test "error signaling" (lambda ()
  (assert-error (error "something went wrong"))))
