;;; Tests for register-machine WASM native-zone generation.

(define (wasm-zone-test-error-message thunk)
  (guard (e (#t (if (error-object? e)
                    (error-object-message e)
                    "non-error-object")))
    (thunk)
    #f))

(define (wasm-zone-test-constant-co value)
  (let ((co (%make-code-object)))
    (%code-object-push-instruction! co (list 'assign 'val (list 'const value)))
    (%code-object-push-instruction! co (list 'halt))
    co))

(test "codegen-wasm-zone: emits a register-machine fixnum return zone" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (wat (generate-register-machine-wasm-zone co "zone_0")))
    (assert-true (string? wat))
    (assert-true (string-contains? wat "(export \"zone_0\")"))
    (assert-true (string-contains? wat "(param \$pc i32)"))
    (assert-true (string-contains? wat "(call \$h_fixnum (i32.const 42))"))
    (assert-true (string-contains? wat "(i32.const 2)")))))

(test "codegen-wasm-zone: unsupported code objects decline generation" (lambda ()
  (let ((co (mc-compile-to-code-object '(+ 1 2))))
    (assert-equal (generate-register-machine-wasm-zone co "zone_unsupported")
                  #f))))

(test "codegen-wasm-zone: constants must fit WASM fixnum immediate range" (lambda ()
  (assert-equal (generate-register-machine-wasm-zone
                 (wasm-zone-test-constant-co 1073741824)
                 "zone_too_large")
                #f)
  (assert-equal (generate-register-machine-wasm-zone
                 (wasm-zone-test-constant-co -1073741825)
                 "zone_too_small")
                #f)))

(test "codegen-wasm-zone: rejects unsafe export names" (lambda ()
  (let ((message
         (wasm-zone-test-error-message
          (lambda ()
            (generate-register-machine-wasm-zone
             (mc-compile-to-code-object 1)
             "bad\"name")))))
    (assert-equal
     "wasm-zone: native-zone export name must contain only letters, digits, _, -, or ."
     message))))

(test "codegen-wasm-zone: emits validated manifest metadata" (lambda ()
  (let* ((manifest
          (generate-register-machine-wasm-zone-manifest
           '(module (demo main) 0)
           3
           "zone_3"
           "demo-zones.wasm"))
         (entry (car (native-zone-manifest-entries manifest))))
    (assert-equal (native-zone-manifest-unit-id manifest)
                  '(module (demo main) 0))
    (assert-equal (native-zone-manifest-module-url manifest)
                  "demo-zones.wasm")
    (assert-equal (native-zone-entry-index entry) 3)
    (assert-equal (native-zone-entry-export-name entry) "zone_3"))))
