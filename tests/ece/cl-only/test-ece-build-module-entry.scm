;;; ece-build module entry-point tests.

(load "src/sdk-lib.scm")
(load "src/ece-main.scm")
(load "src/ece-build.scm")

(test "parse-build-args: module entry options" (lambda ()
  (let ((parsed (parse-build-args
                 '("--target" "cl"
                   "-o" ".tmp/phase-b-build"
                   "--module" "(phase-b app)"
                   "--entry" "main"
                   "app.scm"))))
    (assert-equal (list-ref parsed 0) "cl")
    (assert-equal (list-ref parsed 1) ".tmp/phase-b-build")
    (assert-equal (list-ref parsed 3) "(phase-b app)")
    (assert-equal (list-ref parsed 4) "main")
    (assert-equal (list-ref parsed 5) '("app.scm")))))

(test "validate-build-args: module entry options are CL-only" (lambda ()
  (assert-equal
   (build-args-error "web" ".tmp/phase-b-build" '("app.scm")
                     "(phase-b app)" "main")
   "Error: --module and --entry are only supported with --target cl")
  (assert-equal
   (build-args-error "test-page" ".tmp/phase-b-build" '("app.scm")
                     #f "main")
   "Error: --module and --entry are only supported with --target cl")
  (assert-equal
   (build-args-error "cl" ".tmp/phase-b-build" '("app.scm")
                     "(phase-b app)" #f)
   "Error: --module requires --entry")))

(test "ece-build: CL wrapper invokes selected module entry" (lambda ()
  (let ((path ".tmp/phase-b-run-wrapper"))
    (write-cl-run-wrapper path "(phase-b app)" "main")
    (let ((text (read-file-as-string path)))
      (assert-true (string-contains? text "exec ece --module '(phase-b app)'"))
      (assert-true (string-contains? text "--entry 'main'"))
      (assert-true (string-contains? text "app.ecec"))
      (assert-true (string-contains? text "--"))))))

(test "ece-build: CL wrapper forwards args after option terminator" (lambda ()
  (let ((path ".tmp/phase-b-run-wrapper-default"))
    (write-cl-run-wrapper path #f #f)
    (let ((text (read-file-as-string path)))
      (assert-true (string-contains? text "exec ece "))
      (assert-true (string-contains? text "app.ecec\" -- "))))))
