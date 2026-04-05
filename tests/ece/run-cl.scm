;;; ECE CL-Only Tests — Tests that need CL-specific features
;;; (try-eval for error isolation, compile-file round-trips, etc.)

;; Compilation units (uses compile-form/execute CL kernel functions)
(load "tests/ece/test-compilation-units.scm")

;; Value serialization (uses save-continuation!/load-continuation)
(load "tests/ece/test-serialization.scm")

;; Source location tracking (uses compile-file, load-compiled)
(load "tests/ece/test-source-locations.scm")

;; ECE SDK: argv parser and path-helper coverage
(load "tests/ece/test-ece-main-args.scm")
(load "tests/ece/test-ece-test-runner.scm")
