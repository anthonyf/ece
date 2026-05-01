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
                   "--native-zones"
                   "app.scm"))))
    (assert-equal (list-ref parsed 0) "cl")
    (assert-equal (list-ref parsed 1) ".tmp/phase-b-build")
    (assert-equal (list-ref parsed 3) "(phase-b app)")
    (assert-equal (list-ref parsed 4) "main")
    (assert-equal (list-ref parsed 5) '("app.scm"))
    (assert-equal (list-ref parsed 7) #t))))

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

(test "validate-build-args: native zones are web-only" (lambda ()
  (assert-equal
   (build-args-error/native-zones "cl" ".tmp/phase-b-build" '("app.scm")
                                  #f #f #t)
   "Error: --native-zones is only supported with --target web")
  (assert-equal
   (build-args-error/native-zones "web" ".tmp/phase-b-build" '("app.scm")
                                  #f #f #t)
   #f)))

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

(test "ece-build: native-zone artifacts are emitted from app bundle" (lambda ()
  (let ((dir ".tmp/ece-build-native-zones")
        (source ".tmp/ece-build-native-zones-app.scm"))
    (%make-directory dir)
    (write-string-to-file "123\n" source)
    (compile-system (list source) (path-join dir "app.ecec"))
    (write-web-native-zone-artifacts (path-join dir "app.ecec") dir)
    (let ((wat (read-file-as-string (path-join dir "app-zones.wat")))
          (manifest (read-file-as-string (path-join dir "app-zones.manifest"))))
      (assert-true (string-contains? wat "(module"))
      (assert-true (string-contains? wat "(export \"unit_0_zone_0\")"))
      (assert-true (string-contains? manifest ":module-url \"app-zones.wasm\""))
      (assert-true (string-contains? manifest ":export \"unit_0_zone_0\""))))))
