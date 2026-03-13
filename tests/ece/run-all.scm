;;; ECE Native Test Suite — Entry Point
;;; Loads the test framework and all test files, then runs all tests.

(load "tests/ece/test-framework.scm")

;; Data types & operations
(load "tests/ece/test-arithmetic.scm")
(load "tests/ece/test-lists.scm")
(load "tests/ece/test-strings.scm")
(load "tests/ece/test-vectors.scm")
(load "tests/ece/test-hash-tables.scm")
(load "tests/ece/test-types.scm")

;; Control flow & binding
(load "tests/ece/test-control-flow.scm")
(load "tests/ece/test-closures.scm")
(load "tests/ece/test-macros.scm")
(load "tests/ece/test-tco.scm")

;; Advanced features
(load "tests/ece/test-callcc.scm")
(load "tests/ece/test-higher-order.scm")
(load "tests/ece/test-records.scm")
(load "tests/ece/test-errors.scm")
(load "tests/ece/test-parameters.scm")

(run-tests)
