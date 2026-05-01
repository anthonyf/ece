;;; Tests for src/wasm-host.scm native-zone manifest policy.

(define (wasm-host-test-error-message thunk)
  (guard (e (#t (if (error-object? e)
                    (error-object-message e)
                    "non-error-object")))
    (thunk)
    #f))

(test "wasm-host: validates native-zone manifest" (lambda ()
  (let* ((manifest
          (validate-native-zone-manifest
           '(:ece-native-zones
             :version 1
             :unit-id (module (game main) 0)
             :source "game/main.scm"
             :module-url "game-main-zones.wasm"
             :entries ((:index 0 :export "zone_0" :fingerprint 1234)
                       (:unit-id (module (game helper) 0)
                        :index 7
                        :export "zone_7")))))
         (entries (native-zone-manifest-entries manifest))
         (first (car entries))
         (second (cadr entries)))
    (assert-equal '(module (game main) 0)
                  (native-zone-manifest-unit-id manifest))
    (assert-equal "game/main.scm"
                  (native-zone-manifest-source manifest))
    (assert-equal "game-main-zones.wasm"
                  (native-zone-manifest-module-url manifest))
    (assert-equal 0 (native-zone-entry-index first))
    (assert-equal "zone_0" (native-zone-entry-export-name first))
    (assert-equal 1234 (native-zone-entry-fingerprint first))
    (assert-equal '(module (game main) 0)
                  (native-zone-entry-effective-unit-id manifest first))
    (assert-equal '(module (game helper) 0)
                  (native-zone-entry-unit-id second))
    (assert-equal '(module (game helper) 0)
                  (native-zone-entry-effective-unit-id manifest second))
    (assert-equal 7 (native-zone-entry-index second))
    (assert-equal "zone_7" (native-zone-entry-export-name second))
    (assert-equal #f (native-zone-entry-fingerprint second)))))

(test "wasm-host: parses native-zone manifest text" (lambda ()
  (let ((manifest
         (parse-native-zone-manifest
          "(:ece-native-zones :version 1 :unit-id (module (demo app) 0) :entries ((:index 2 :export \"zone_2\")))")))
    (assert-equal '(module (demo app) 0)
                  (native-zone-manifest-unit-id manifest))
    (assert-equal 2
                  (native-zone-entry-index
                   (car (native-zone-manifest-entries manifest)))))))

(test "wasm-host: rejects missing unit-id" (lambda ()
  (let ((message
         (wasm-host-test-error-message
          (lambda ()
            (validate-native-zone-manifest
             '(:ece-native-zones
               :version 1
               :entries ((:index 0 :export "zone_0"))))))))
    (assert-equal "wasm-host: native-zone manifest missing :unit-id"
                  message))))

(test "wasm-host: rejects malformed entries" (lambda ()
  (let ((message
         (wasm-host-test-error-message
          (lambda ()
            (validate-native-zone-manifest
             '(:ece-native-zones
               :version 1
               :unit-id app
               :entries ((:index -1 :export "zone_bad"))))))))
    (assert-equal
     "wasm-host: native-zone entry :index must be a non-negative integer"
     message))))

(test "wasm-host: rejects malformed native-zone fingerprints" (lambda ()
  (let ((message
         (wasm-host-test-error-message
          (lambda ()
            (validate-native-zone-manifest
             '(:ece-native-zones
               :version 1
               :unit-id app
               :entries ((:index 0
                         :export "zone_bad"
                         :fingerprint (not-stable)))))))))
    (assert-equal
     "wasm-host: native-zone entry :fingerprint must be an integer or string"
     message))))

(test "wasm-host: rejects duplicate co-indexes" (lambda ()
  (let ((message
         (wasm-host-test-error-message
          (lambda ()
            (validate-native-zone-manifest
             '(:ece-native-zones
               :version 1
               :unit-id app
               :entries ((:index 0 :export "zone_0")
                         (:index 0 :export "zone_0b"))))))))
    (assert-equal "wasm-host: native-zone manifest has duplicate (:unit-id, :index) entry"
                  message))))

(test "wasm-host: allows duplicate indexes for different entry unit ids" (lambda ()
  (let* ((manifest
          (validate-native-zone-manifest
           '(:ece-native-zones
             :version 1
             :unit-id app
             :entries ((:unit-id app-a :index 0 :export "zone_a_0")
                       (:unit-id app-b :index 0 :export "zone_b_0")))))
         (entries (native-zone-manifest-entries manifest)))
    (assert-equal 2 (length entries))
    (assert-equal 'app-a (native-zone-entry-unit-id (car entries)))
    (assert-equal 'app-b (native-zone-entry-unit-id (cadr entries))))))

(test "wasm-host: rejects entry unit-id #f" (lambda ()
  (let ((message
         (wasm-host-test-error-message
          (lambda ()
            (validate-native-zone-manifest
             '(:ece-native-zones
               :version 1
               :unit-id app
               :entries ((:unit-id #f :index 0 :export "zone_0"))))))))
    (assert-equal "wasm-host: native-zone entry :unit-id must not be #f"
                  message))))

(test "wasm-host: rejects improper manifest plists" (lambda ()
  (let ((manifest-message
         (wasm-host-test-error-message
          (lambda ()
            (validate-native-zone-manifest
             (cons ':ece-native-zones
                   (cons ':version (cons 1 'bad)))))))
        (entry-message
         (wasm-host-test-error-message
          (lambda ()
            (validate-native-zone-manifest
             (list ':ece-native-zones
                   ':version 1
                   ':unit-id 'app
                   ':entries
                   (list (cons ':index
                               (cons 0
                                     (cons ':export "zone_0"))))))))))
    (assert-equal "wasm-host: native-zone manifest must be a keyword plist"
                  manifest-message)
    (assert-equal "wasm-host: native-zone entry must be a keyword plist"
                  entry-message))))

(test "wasm-host: loader policy keeps host capabilities behind wrappers" (lambda ()
  (assert-true (procedure? fetch-text))
  (assert-true (procedure? fetch-bytes))
  (assert-true (procedure? wasm-instantiate))
  (assert-true (procedure? wasm-export))
  (assert-true (procedure? native-zone-imports))))

(test "wasm-host: missing host capability reports wasm-host error" (lambda ()
  (when (not (platform-has? '%wasm-fetch-text))
    (assert-equal
     "wasm-host: %wasm-fetch-text requires browser WASM host capabilities that are not implemented yet"
     (wasm-host-test-error-message (lambda () (fetch-text "missing.ecez")))))))

(test "wasm-host: reload-program requires paired native-zone URLs" (lambda ()
  (assert-equal
   "wasm-host: reload-program requires both native-zone module and manifest URLs"
   (wasm-host-test-error-message
    (lambda () (reload-program "app.ecec" "app-zones.wasm" #f))))))

(test "wasm-host: reload registration invalidates cached module instances" (lambda ()
  (let* ((unit-id '(module (reload stale) 0))
         (unit-key (archive/unit-key unit-id))
         (unit (list ':unit-id unit-id
                     ':kind ':module
                     ':phase 0
                     ':imports '()
                     ':exports '()
                     ':init 0))
         (section (list ':unit unit
                        ':cos (vector (mc-compile-to-code-object 1)))))
    (dynamic-wind
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))
     (lambda ()
       (hash-set! *module-instances* unit-key 'stale-instance)
       (wasm-host/register-reload-section! section)
       (assert-equal #f (hash-ref *module-instances* unit-key #f))
       (assert-true (archive/registered-unit unit-id)))
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))))))

(test "wasm-host: native-zone fingerprints validate loaded archive code" (lambda ()
  (let* ((unit-id '(module (native stale) 0))
         (unit-key (archive/unit-key unit-id))
         (co (mc-compile-to-code-object 7))
         (unit (list ':unit-id unit-id
                     ':kind ':module
                     ':phase 0
                     ':imports '()
                     ':exports '()
                     ':init 0))
         (record (archive/make-unit-record unit (vector co)))
         (fingerprint (ser/code-object-fingerprint co))
         (manifest (validate-native-zone-manifest
                    (list ':ece-native-zones
                          ':version 1
                          ':unit-id unit-id
                          ':entries
                          (list (list ':index 0
                                      ':export "zone_0"
                                      ':fingerprint fingerprint))))))
    (dynamic-wind
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))
     (lambda ()
       (hash-set! *archive-units* unit-key record)
       (assert-equal manifest
                     (validate-native-zone-fingerprints! manifest)))
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))))))

(test "wasm-host: native-zone fingerprints reject stale loaded archive code" (lambda ()
  (let* ((unit-id '(module (native stale-mismatch) 0))
         (unit-key (archive/unit-key unit-id))
         (archive-co (mc-compile-to-code-object 7))
         (unit (list ':unit-id unit-id
                     ':kind ':module
                     ':phase 0
                     ':imports '()
                     ':exports '()
                     ':init 0))
         (record (archive/make-unit-record unit (vector archive-co)))
         (stale-fingerprint (+ (ser/code-object-fingerprint archive-co) 1))
         (manifest (validate-native-zone-manifest
                    (list ':ece-native-zones
                          ':version 1
                          ':unit-id unit-id
                          ':entries
                          (list (list ':index 0
                                      ':export "zone_0"
                                      ':fingerprint stale-fingerprint))))))
    (dynamic-wind
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))
     (lambda ()
       (hash-set! *archive-units* unit-key record)
       (assert-equal
        (string-append
         "wasm-host: native-zone fingerprint mismatch for "
         (write-to-string-flat unit-id)
         " index 0: expected "
         (write-to-string-flat stale-fingerprint)
         " got "
         (write-to-string-flat (ser/code-object-fingerprint archive-co)))
        (wasm-host-test-error-message
         (lambda () (validate-native-zone-fingerprints! manifest)))))
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))))))

(test "wasm-host: native-zone fingerprints normalize string unit ids for archive lookup" (lambda ()
  (let* ((unit-id 'string-fingerprint-app)
         (unit-key (archive/unit-key unit-id))
         (archive-co (mc-compile-to-code-object 7))
         (unit (list ':unit-id unit-id
                     ':kind ':file
                     ':phase 0
                     ':imports '()
                     ':exports ':all
                     ':init 0))
         (record (archive/make-unit-record unit (vector archive-co)))
         (stale-fingerprint (+ (ser/code-object-fingerprint archive-co) 1))
         (manifest (validate-native-zone-manifest
                    (list ':ece-native-zones
                          ':version 1
                          ':unit-id "string-fingerprint-app"
                          ':entries
                          (list (list ':index 0
                                      ':export "zone_0"
                                      ':fingerprint stale-fingerprint))))))
    (dynamic-wind
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))
     (lambda ()
       (hash-set! *archive-units* unit-key record)
       (assert-equal
        (string-append
         "wasm-host: native-zone fingerprint mismatch for "
         "\"string-fingerprint-app\""
         " index 0: expected "
         (write-to-string-flat stale-fingerprint)
         " got "
         (write-to-string-flat (ser/code-object-fingerprint archive-co)))
        (wasm-host-test-error-message
         (lambda () (validate-native-zone-fingerprints! manifest)))))
     (lambda ()
       (hash-remove! *archive-units* unit-key)
       (hash-remove! *module-instances* unit-key))))))

(test "wasm-host: native-zone registry stores and overwrites refs" (lambda ()
  (let ((unit-id '(module (game main) 0))
        (same-unit-id (list 'module (list 'game 'main) 0)))
    (assert-equal 'zone-a (register-native-zone! unit-id 401 'zone-a))
    (assert-equal 'zone-a (native-zone-lookup same-unit-id 401))
    (assert-true (native-zone-registered? same-unit-id 401))
    (assert-equal 'zone-b (register-native-zone! same-unit-id 401 'zone-b))
    (assert-equal 'zone-b (native-zone-lookup unit-id 401)))))

(test "wasm-host: native-zone registry normalizes string unit ids" (lambda ()
  (assert-equal 'zone-string
                (register-native-zone! "app" 402 'zone-string))
  (assert-equal 'zone-string
                (native-zone-lookup 'app 402))))

(test "wasm-host: native-zone registry normalizes integral float indexes" (lambda ()
  (assert-equal 'zone-float-index
                (register-native-zone! 'float-index-app
                                       (exact->inexact 403)
                                       'zone-float-index))
  (assert-equal 'zone-float-index
                (native-zone-lookup 'float-index-app 403))))

(test "wasm-host: native-zone registry validates registration inputs" (lambda ()
  (let ((bad-index-message
         (wasm-host-test-error-message
          (lambda () (register-native-zone! 'app -1 'zone))))
        (large-index-message
         (wasm-host-test-error-message
          (lambda () (register-native-zone! 'app 1073741824 'zone))))
        (bad-unit-message
         (wasm-host-test-error-message
          (lambda () (register-native-zone! #f 0 'zone))))
        (bad-ref-message
         (wasm-host-test-error-message
          (lambda () (register-native-zone! 'app 0 #f)))))
    (assert-equal "wasm-host: native-zone co-index must be an integer in the range 0..1073741823"
                  bad-index-message)
    (assert-equal "wasm-host: native-zone co-index must be an integer in the range 0..1073741823"
                  large-index-message)
    (assert-equal "wasm-host: native-zone unit-id must not be #f"
                  bad-unit-message)
    (assert-equal "wasm-host: native-zone export-ref must not be #f"
                  bad-ref-message))))
