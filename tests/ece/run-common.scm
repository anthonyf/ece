;;; ECE Common Test Suite — Platform-Independent Tests
;;; These tests use only core primitives (IDs 0-99) and run on any ECE host.

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
(load "tests/ece/test-syntax-rules.scm")
(load "tests/ece/test-tco.scm")

;; Advanced features
(load "tests/ece/test-callcc.scm")
(load "tests/ece/test-higher-order.scm")
(load "tests/ece/test-records.scm")
(load "tests/ece/test-errors.scm")
(load "tests/ece/test-parameters.scm")
(load "tests/ece/test-dynamic-wind.scm")
(load "tests/ece/test-guard.scm")
(load "tests/ece/test-error-messages.scm")

;; Comprehensive coverage
(load "tests/ece/test-mutation.scm")
(load "tests/ece/test-advanced-continuations.scm")
(load "tests/ece/test-misc.scm")

;; String evaluation
(load "tests/ece/test-eval-string.scm")

;; File I/O (filesystem on CL, localStorage on WASM)
(load "tests/ece/test-file-io.scm")

;; Serialization round-trips
(load "tests/ece/test-roundtrip.scm")

;; Cross-space function calls
(load "tests/ece/test-cross-space.scm")
