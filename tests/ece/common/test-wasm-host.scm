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
             :entries ((:index 0 :export "zone_0" :fingerprint "fp0")
                       (:index 7 :export "zone_7")))))
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
    (assert-equal "fp0" (native-zone-entry-fingerprint first))
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
    (assert-equal "wasm-host: native-zone manifest has duplicate :index"
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

(test "wasm-host: host capabilities are explicit stubs in phase 1" (lambda ()
  (let ((message
         (wasm-host-test-error-message
          (lambda () (fetch-text "app.ecec")))))
    (assert-equal
     "wasm-host: fetch-text requires browser WASM host capabilities that are not implemented yet"
     message))))
