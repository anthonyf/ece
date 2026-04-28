;;; ece-main argv parser tests.
;;;
;;; Loads src/sdk-lib.scm and src/ece-main.scm explicitly so tests can
;;; call parse-argv directly.

(load "src/sdk-lib.scm")
(load "src/ece-main.scm")

;; parse-argv returns (list interactive? help? version? extra-args steps).

(test "parse-argv: empty argv" (lambda ()
  (let ((parsed (parse-argv '())))
    (assert-equal (list-ref parsed 0) #f)        ; interactive?
    (assert-equal (list-ref parsed 1) #f)        ; help?
    (assert-equal (list-ref parsed 2) #f)        ; version?
    (assert-equal (list-ref parsed 3) '())       ; extra-args
    (assert-equal (list-ref parsed 4) '()))))    ; steps

(test "parse-argv: --version" (lambda ()
  (let ((parsed (parse-argv '("--version"))))
    (assert-equal (list-ref parsed 2) #t))))

(test "parse-argv: -V shortcut" (lambda ()
  (let ((parsed (parse-argv '("-V"))))
    (assert-equal (list-ref parsed 2) #t))))

(test "parse-argv: --help" (lambda ()
  (let ((parsed (parse-argv '("--help"))))
    (assert-equal (list-ref parsed 1) #t))))

(test "parse-argv: -h shortcut" (lambda ()
  (let ((parsed (parse-argv '("-h"))))
    (assert-equal (list-ref parsed 1) #t))))

(test "parse-argv: -i interactive" (lambda ()
  (let ((parsed (parse-argv '("-i"))))
    (assert-equal (list-ref parsed 0) #t))))

(test "parse-argv: --interactive" (lambda ()
  (let ((parsed (parse-argv '("--interactive"))))
    (assert-equal (list-ref parsed 0) #t))))

(test "parse-argv: positional file → load step" (lambda ()
  (let ((parsed (parse-argv '("main.scm"))))
    (assert-equal (list-ref parsed 4) '((load "main.scm"))))))

(test "parse-argv: --load FILE" (lambda ()
  (let ((parsed (parse-argv '("--load" "lib.scm"))))
    (assert-equal (list-ref parsed 4) '((load "lib.scm"))))))

(test "parse-argv: -e EXPR" (lambda ()
  (let ((parsed (parse-argv '("-e" "(+ 1 2)"))))
    (assert-equal (list-ref parsed 4) '((eval "(+ 1 2)"))))))

(test "parse-argv: --eval EXPR" (lambda ()
  (let ((parsed (parse-argv '("--eval" "(display 1)"))))
    (assert-equal (list-ref parsed 4) '((eval "(display 1)"))))))

(test "parse-argv: multiple steps in order" (lambda ()
  (let ((parsed (parse-argv '("--load" "a.scm" "-e" "(f)" "b.scm"))))
    (assert-equal (list-ref parsed 4)
                  '((load "a.scm") (eval "(f)") (load "b.scm"))))))

(test "parse-argv: -- ends option processing" (lambda ()
  (let ((parsed (parse-argv '("main.scm" "--" "--not-an-opt" "value"))))
    (assert-equal (list-ref parsed 4) '((load "main.scm")))
    (assert-equal (list-ref parsed 3) '("--not-an-opt" "value")))))

(test "parse-argv: -i with load" (lambda ()
  (let ((parsed (parse-argv '("-i" "init.scm"))))
    (assert-equal (list-ref parsed 0) #t)
    (assert-equal (list-ref parsed 4) '((load "init.scm"))))))

(test "parse-argv: module entry options" (lambda ()
  (let ((parsed (parse-argv '("--module" "(phase-b app)" "--entry" "main" "app.ecec"))))
    (assert-equal (list-ref parsed 4) '((load "app.ecec")))
    (assert-equal (list-ref parsed 6) '(phase-b app))
    (assert-equal (list-ref parsed 7) 'main))))
