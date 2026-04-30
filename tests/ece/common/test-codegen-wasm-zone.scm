;;; Tests for register-machine WASM native-zone generation.

(define (wasm-zone-test-error-message thunk)
  (guard (e (#t (if (error-object? e)
                    (error-object-message e)
                    "non-error-object")))
    (thunk)
    #f))

(define (wasm-zone-test-substring-count s needle)
  (let ((slen (string-length s))
        (nlen (string-length needle)))
    (let loop ((i 0) (count 0))
      (cond ((> (+ i nlen) slen) count)
            ((string=? (substring s i (+ i nlen)) needle)
             (loop (+ i 1) (+ count 1)))
            (else
             (loop (+ i 1) count))))))

(define (wasm-zone-test-constant-co value)
  (let ((co (%make-code-object)))
    (%code-object-push-instruction! co (list 'assign 'val (list 'const value)))
    (%code-object-push-instruction! co (list 'halt))
    co))

(define (wasm-zone-test-prefix-bailout-co)
  (let ((co (%make-code-object)))
    (%code-object-push-instruction! co (list 'assign 'val (list 'const 88)))
    (%code-object-push-instruction! co (list 'assign 'proc (list 'reg 'val)))
    (%code-object-push-instruction! co
                                    (list 'perform
                                          (list 'op 'define-variable!)
                                          (list 'const 'generated-bail-value)
                                          (list 'reg 'val)
                                          (list 'reg 'env)))
    (%code-object-push-instruction! co (list 'halt))
    co))

(define (wasm-zone-test-list-prefix-co)
  (let ((co (%make-code-object)))
    (%code-object-push-instruction! co (list 'assign 'val (list 'const 5)))
    (%code-object-push-instruction! co (list 'assign 'argl (list 'op 'list)
                                             (list 'reg 'val)))
    (%code-object-push-instruction! co (list 'assign 'val (list 'const 3)))
    (%code-object-push-instruction! co (list 'assign 'argl (list 'op 'cons)
                                             (list 'reg 'val)
                                             (list 'reg 'argl)))
    (%code-object-push-instruction! co
                                    (list 'perform
                                          (list 'op 'define-variable!)
                                          (list 'const 'generated-list-value)
                                          (list 'reg 'argl)
                                          (list 'reg 'env)))
    (%code-object-push-instruction! co (list 'halt))
    co))

(define (wasm-zone-test-bundle-cos)
  (vector
   (wasm-zone-test-constant-co 7)
   (mc-compile-to-code-object '(+ 1 2))
   (wasm-zone-test-list-prefix-co)))

(test "codegen-wasm-zone: emits a register-machine fixnum return zone" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (wat (generate-register-machine-wasm-zone co "zone_0")))
    (assert-true (string? wat))
    (assert-true (string-contains? wat "(export \"zone_0\")"))
    (assert-true (string-contains? wat "(param \$pc i32)"))
    (assert-true (string-contains? wat "(local.set \$val"))
    (assert-true (string-contains? wat "(call \$h_fixnum (i32.const 42))"))
    (assert-true (string-contains? wat "(i32.const 2)")))))

(test "codegen-wasm-zone: emits direct nil constant assignments" (lambda ()
  (let ((wat (generate-register-machine-wasm-zone
              (wasm-zone-test-constant-co '())
              "zone_nil")))
    (assert-true (string? wat))
    (assert-true (string-contains? wat "(export \"zone_nil\")"))
    (assert-true (string-contains? wat "(import \"ece\" \"h_nil\""))
    (assert-true (string-contains? wat "(local.set \$val (call \$h_nil))")))))

(test "codegen-wasm-zone: emits register assignments and prefix bailout" (lambda ()
  (let ((wat (generate-register-machine-wasm-zone
              (wasm-zone-test-prefix-bailout-co)
              "zone_prefix")))
    (assert-true (string? wat))
    (assert-true (string-contains? wat "(local.set \$val (call \$h_fixnum (i32.const 88)))"))
    (assert-true (string-contains? wat "(local.set \$proc (local.get \$val))"))
    (assert-true (>= (wasm-zone-test-substring-count wat "(i32.const 2)") 2)))))

(test "codegen-wasm-zone: emits list and cons operation assignments" (lambda ()
  (let ((wat (generate-register-machine-wasm-zone
              (wasm-zone-test-list-prefix-co)
              "zone_list")))
    (assert-true (string? wat))
    (assert-true (string-contains? wat "(import \"ece\" \"h_nil\""))
    (assert-true (string-contains? wat "(import \"ece\" \"h_cons\""))
    (assert-true (string-contains? wat "(local.set \$argl (call \$h_cons (local.get \$val) (call \$h_nil)))"))
    (assert-true (string-contains? wat "(local.set \$argl (call \$h_cons (local.get \$val) (local.get \$argl)))"))
    (assert-true (>= (wasm-zone-test-substring-count wat "(i32.const 4)") 1)))))

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

(test "codegen-wasm-zone: emits bundle WAT and manifest for supported entries" (lambda ()
  (let* ((bundle
          (generate-register-machine-wasm-zone-bundle
           'bundle-unit
           (wasm-zone-test-bundle-cos)
           "bundle-zones.wasm"))
         (wat (wasm-zone-bundle-wat bundle))
         (manifest (wasm-zone-bundle-manifest bundle))
         (entries (native-zone-manifest-entries manifest))
         (first (car entries))
         (second (cadr entries)))
    (assert-true (string? wat))
    (assert-true (string-contains? wat "(export \"zone_0\")"))
    (assert-true (not (string-contains? wat "(export \"zone_1\")")))
    (assert-true (string-contains? wat "(export \"zone_2\")"))
    (assert-equal (native-zone-manifest-unit-id manifest) 'bundle-unit)
    (assert-equal (native-zone-manifest-module-url manifest)
                  "bundle-zones.wasm")
    (assert-equal (length entries) 2)
    (assert-equal (native-zone-entry-index first) 0)
    (assert-equal (native-zone-entry-export-name first) "zone_0")
    (assert-equal (native-zone-entry-index second) 2)
    (assert-equal (native-zone-entry-export-name second) "zone_2"))))
