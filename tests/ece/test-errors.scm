;;; Error and assert tests

(test "assert passes on truthy" (lambda ()
  (assert #t)
  (assert-true #t)))

(test "assert-error on division by zero" (lambda ()
  (assert-error (/ 1 0))))

;; Unbound variable errors are CL-level (not caught by guard on WASM)
(when (platform-has? 'try-eval)
  (test "assert-error on unbound variable" (lambda ()
    (assert-true
      (guard (e (#t #t))
        (eval (string->symbol "this-variable-does-not-exist-12345"))
        #f)))))

(test "error signaling" (lambda ()
  (assert-error (error "something went wrong"))))
