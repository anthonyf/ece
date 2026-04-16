;;; Geiser backend unit tests (CL-only)
;;; Tests the alist response formatting, output capture, and helper functions.
;;; Subprocess integration tests live in tests/ece.lisp (Rove).

;; ---- Test geiser-no-values ----

(test "geiser-no-values returns #f"
  (lambda ()
    (assert-equal (geiser-no-values) #f)))

;; ---- Test geiser-completions ----
;; (stub-era "returns empty" test removed — real handler returns results now)

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

;; ---- Test %global-env-symbols ----

(test "%global-env-symbols returns a list of strings"
  (lambda ()
    (let ((syms (%global-env-symbols)))
      (assert (pair? syms) "returns a non-empty list")
      (assert (string? (car syms)) "elements are strings"))))

(test "%global-env-symbols includes known builtins"
  (lambda ()
    (let ((syms (%global-env-symbols)))
      (assert (member "map" syms) "includes map")
      (assert (member "+" syms) "includes +")
      (assert (member "car" syms) "includes car")
      (assert (member "cdr" syms) "includes cdr"))))

(define test-completion-xyz 1)

(test "%global-env-symbols includes user-defined globals"
  (lambda ()
    (let ((syms (%global-env-symbols)))
      (assert (member "test-completion-xyz" syms)
              "includes test-completion-xyz"))))

;; ---- Test geiser-completions ----

(test "geiser-completions prefix filtering"
  (lambda ()
    (let ((result (geiser-completions "string-")))
      (assert (pair? result) "non-empty for string- prefix")
      (assert (member "string-append" result) "includes string-append")
      (assert (member "string-length" result) "includes string-length")
      (let check ((xs result))
        (when (pair? xs)
          (assert (string-prefix? "string-" (car xs))
                  (string-append "starts with prefix: " (car xs)))
          (check (cdr xs))))
      (let sorted? ((xs result))
        (when (and (pair? xs) (pair? (cdr xs)))
          (assert (not (string<? (car (cdr xs)) (car xs)))
                  "result is sorted")
          (sorted? (cdr xs)))))))

(test "geiser-completions no match returns empty"
  (lambda ()
    (assert-equal (geiser-completions "zzz-nonexistent") '())))

(test "geiser-completions empty prefix returns all symbols"
  (lambda ()
    (let ((result (geiser-completions "")))
      (assert (pair? result) "non-empty for empty prefix")
      (assert (member "map" result) "includes map")
      (assert (member "+" result) "includes +")
      (assert (member "test-completion-xyz" result)
              "includes test-completion-xyz"))))
