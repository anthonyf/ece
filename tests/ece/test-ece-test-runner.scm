;;; ece-test runner tests — exercises the pure-function layer.
;;;
;;; `run-one-test-file` uses test-lib.scm state via parameterize, which
;;; conflicts with test-framework.scm's global-state model. Integration
;;; testing for the full runner lives in the CL-side rove suite
;;; (tests/ece.lisp) where we can spawn subprocesses.

(load "src/sdk-lib.scm")

;; We deliberately don't load src/ece-test.scm at the top level — that
;; would pull in test-lib.scm which redefines `test` and `*tests*`.
;; Instead, re-implement the tiny predicate here so we can test the
;; string-matching logic in isolation.
(define (is-test-file-local? name)
  (and (starts-with? name "test-")
       (ends-with? name ".scm")))

(test "ece-test: is-test-file? accepts test-foo.scm" (lambda ()
  (assert-true (is-test-file-local? "test-foo.scm"))
  (assert-true (is-test-file-local? "test-a.scm"))))

(test "ece-test: is-test-file? rejects non-matching names" (lambda ()
  (assert-equal (is-test-file-local? "helper.scm") #f)
  (assert-equal (is-test-file-local? "not-test.scm") #f)
  (assert-equal (is-test-file-local? "test-foo.txt") #f)
  (assert-equal (is-test-file-local? "testfoo.scm") #f)))

;; Path helper tests (from sdk-lib)

(test "ece-test: path-join handles trailing slash" (lambda ()
  (assert-equal (path-join "a" "b") "a/b")
  (assert-equal (path-join "a/" "b") "a/b")
  (assert-equal (path-join "a/" "/b") "a/b")))

(test "ece-test: basename" (lambda ()
  (assert-equal (basename "/foo/bar/baz.scm") "baz.scm")
  (assert-equal (basename "ece-build") "ece-build")
  (assert-equal (basename "/bin/ece") "ece")))

(test "ece-test: dirname" (lambda ()
  (assert-equal (dirname "/foo/bar/baz.scm") "/foo/bar")
  (assert-equal (dirname "main.scm") ".")
  (assert-equal (dirname "/usr") "/")))

(test "ece-test: ends-with?" (lambda ()
  (assert-true (ends-with? "foo.scm" ".scm"))
  (assert-true (ends-with? "a.ecec" ".ecec"))
  (assert-equal (ends-with? "foo.scm" ".txt") #f)
  (assert-equal (ends-with? "x" ".longer") #f)))

(test "ece-test: starts-with?" (lambda ()
  (assert-true (starts-with? "test-foo" "test-"))
  (assert-equal (starts-with? "foo" "bar") #f)
  (assert-equal (starts-with? "x" "longer") #f)))

(test "ece-test: has-extension?" (lambda ()
  (assert-true (has-extension? "foo.scm" "scm"))
  (assert-true (has-extension? "bar.ecec" "ecec"))
  (assert-equal (has-extension? "foo.scm" "txt") #f)))
