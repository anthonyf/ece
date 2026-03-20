;;; ECE CL-Only Tests — Require CL platform primitives (IDs 100-199)
;;; These tests use file I/O (open-input-file, open-output-file, etc.)
;;; and are not expected to run on the WASM host.

;; Compilation units (uses file I/O for .ecec round-trips)
(load "tests/ece/test-compilation-units.scm")

;; Value serialization (uses file I/O for save/load)
(load "tests/ece/test-serialization.scm")

;; Cross-space loading (uses file I/O to load test files)
(load "tests/ece/test-cross-space.scm")

;; File I/O primitives
(load "tests/ece/test-file-io.scm")
