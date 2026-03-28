;;; Conformance Test Suite — Entry Point
;;; Loads framework and all conformance test suites, then prints results.

(load "tests/conformance/conformance-framework.scm")

;; R5RS pitfall tests (edge cases)
(load "tests/conformance/r5rs-pitfall.scm")

;; Chibi R5RS tests (core R5RS coverage)
(load "tests/conformance/chibi-r5rs.scm")

(conformance-summary)
