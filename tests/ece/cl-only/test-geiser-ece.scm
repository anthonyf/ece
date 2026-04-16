;;; Geiser backend unit tests (CL-only)
;;; Tests the alist response formatting, output capture, and helper functions.
;;; Subprocess integration tests live in tests/ece.lisp (Rove).

;; ---- Test geiser-no-values ----

(test "geiser-no-values returns #f"
  (lambda ()
    (assert-equal (geiser-no-values) #f)))

;; ---- Test geiser-completions stub ----

(test "geiser-completions returns empty list"
  (lambda ()
    (assert-equal (geiser-completions "foo") '())))

;; ---- Test geiser-autodoc stub ----

(test "geiser-autodoc returns empty list"
  (lambda ()
    (assert-equal (geiser-autodoc '(foo)) '())))

;; ---- Test alist formatting via write-to-string-flat ----

(test "geiser: write-to-string-flat formats alist correctly"
  (lambda ()
    (let ((alist (list (list 'result "3") (cons 'output ""))))
      (assert-equal (write-to-string-flat alist)
                    "((result \"3\") (output . \"\"))"))))

(test "geiser: write-to-string-flat formats alist with output"
  (lambda ()
    (let ((alist (list (list 'result "42") (cons 'output "hello"))))
      (assert-equal (write-to-string-flat alist)
                    "((result \"42\") (output . \"hello\"))"))))

;; ---- Test %geiser-eval-and-respond (inline REPL helper) ----

(when (platform-has? 'open-output-file)

(test "geiser: eval-and-respond captures successful eval"
  (lambda ()
    (let ((capture (open-output-string)))
      (parameterize ((current-output-port capture))
        (%geiser-eval-and-respond '(+ 1 2)))
      (let ((output (get-output-string capture)))
        (assert (string-contains? output "result") "has result field")
        (assert (string-contains? output "\"3\"") "result is 3")))))

(test "geiser: eval-and-respond captures display output"
  (lambda ()
    (let ((capture (open-output-string)))
      (parameterize ((current-output-port capture))
        (%geiser-eval-and-respond '(begin (display "hi") 42)))
      (let ((output (get-output-string capture)))
        (assert (string-contains? output "\"42\"") "result is 42")
        (assert (string-contains? output "hi") "output captures display")))))

) ;; end platform-has? guard
