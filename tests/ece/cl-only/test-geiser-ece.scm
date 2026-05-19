;;; Geiser backend unit tests (CL-only)
;;; Tests the alist response formatting, output capture, and helper functions.
;;; Subprocess integration tests live in tests/ece.lisp (Rove).

;; ---- Test geiser-no-values ----

(test "geiser-no-values returns #f"
  (lambda ()
    (assert-equal (geiser-no-values) #f)))

;; ---- Test geiser-completions ----
;; (stub-era "returns empty" test removed — real handler returns results now)

;; ---- Test %procedure-params ----

(define (test-proc-for-params a b) (+ a b))

(test "%procedure-params returns metadata for defined procedure"
  (lambda ()
    (let ((params (%procedure-params test-proc-for-params)))
      (assert (pair? params) "returns a pair")
      (assert-equal (car params) '("a" "b"))
      (assert-equal (cdr params) 0))))

(test "%procedure-params returns #f for non-procedures"
  (lambda ()
    (assert-equal (%procedure-params 42) #f)))

(test "%procedure-params returns arity for host primitives"
  (lambda ()
    (let ((params (%procedure-params car)))
      (assert (pair? params) "returns a pair for primitive")
      (assert-equal (length (car params)) 1)
      (assert-equal (cdr params) 0))))

;; ---- Test geiser-autodoc ----

(test "geiser-autodoc returns non-empty alist for known function"
  (lambda ()
    (let ((result (geiser-autodoc '(map))))
      (assert (pair? result) "non-empty for map")
      (assert (pair? (car result)) "first entry is a pair"))))

(test "geiser-autodoc returns empty list for unknowns"
  (lambda ()
    (assert-equal (geiser-autodoc '(zzz-nonexistent)) '())))

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

;; ---- Test geiser-symbol-location ----

(when (platform-has? 'open-output-file)

(test "geiser-symbol-location finds registered source definition"
  (lambda ()
    (let ((path ".tmp/geiser-location-test.scm"))
      (let ((out (open-output-file path)))
        (display ";; leading line\n" out)
        (display "(define (geiser-location-target x) x)\n" out)
        (close-output-port out))
      (set! *geiser-source-files* '())
      (set! *geiser-source-index* (%make-hash-table))
      (geiser-register-source-file! path)
      (assert (hash-ref *geiser-source-index* 'geiser-location-target #f)
              "indexes source location")
      (let ((loc (geiser-symbol-location 'geiser-location-target)))
        (assert (pair? loc) "returns a location alist")
        (assert-equal (cdr (assoc "name" loc)) "geiser-location-target")
        (assert-equal (cdr (assoc "file" loc)) path)
        (assert-equal (cdr (assoc "line" loc)) 2)
        (assert-equal (cdr (assoc "column" loc)) 0)))))

(test "geiser/read-source-with-locations returns #f for missing source"
  (lambda ()
    (assert-equal (geiser/read-source-with-locations
                   ".tmp/geiser-missing-source-dir/missing.scm")
                  #f)))

(test "geiser-register-source-file refreshes source index"
  (lambda ()
    (let ((path ".tmp/geiser-location-refresh.scm"))
      (let ((out (open-output-file path)))
        (display "(define geiser-refresh-a 1)\n" out)
        (close-output-port out))
      (set! *geiser-source-files* '())
      (set! *geiser-source-index* (%make-hash-table))
      (geiser-register-source-file! path)
      (assert (geiser-symbol-location 'geiser-refresh-a)
              "indexes initial source definition")
      (let ((out (open-output-file path)))
        (display "(define geiser-refresh-b 2)\n" out)
        (close-output-port out))
      (geiser-register-source-file! path)
      (assert-equal (geiser-symbol-location 'geiser-refresh-a) #f)
      (let ((loc (geiser-symbol-location 'geiser-refresh-b)))
        (assert (pair? loc) "indexes refreshed source definition")
        (assert-equal (cdr (assoc "file" loc)) path)
        (assert-equal (cdr (assoc "line" loc)) 1)))))

(test "geiser-register-source-tree follows literal relative loads"
  (lambda ()
    (let ((main ".tmp/geiser-tree-main.scm")
          (lib ".tmp/geiser-tree-lib.scm"))
      (let ((out (open-output-file lib)))
        (display "(define geiser-tree-value 42)\n" out)
        (close-output-port out))
      (let ((out (open-output-file main)))
        (display "(load \"geiser-tree-lib.scm\")\n" out)
        (close-output-port out))
      (set! *geiser-source-files* '())
      (set! *geiser-source-index* (%make-hash-table))
      (geiser-register-source-tree! main)
      (let ((loc (geiser-symbol-location 'geiser-tree-value)))
        (assert (pair? loc) "returns a location from a loaded file")
        (assert-equal (cdr (assoc "file" loc)) lib)
        (assert-equal (cdr (assoc "line" loc)) 1)))))

) ;; end platform-has? guard
