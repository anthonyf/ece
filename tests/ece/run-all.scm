;;; ECE Native Test Suite — Entry Point
;;; Loads common (platform-independent) + CL-specific tests, then runs all.

;; Common tests (core primitives only — run on any host)
(load "tests/ece/run-common.scm")

;; CL-only tests (file I/O, compilation units, serialization)
(load "tests/ece/run-cl.scm")

(run-tests)
