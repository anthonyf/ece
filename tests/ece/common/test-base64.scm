;;; Base64 encoding tests — RFC 4648 test vectors + WebSocket handshake
;;; round-trip through sha1 + base64.

(define (string->bytes s)
  (let loop ((i 0) (acc '()))
    (if (< i (string-length s))
        (loop (+ i 1) (cons (char->integer (string-ref s i)) acc))
        (reverse acc))))

(test "base64 empty" (lambda ()
  (assert-equal (bytes->base64 '()) "")))

(test "base64 of 'f'" (lambda ()
  (assert-equal (bytes->base64 (string->bytes "f")) "Zg==")))

(test "base64 of 'fo'" (lambda ()
  (assert-equal (bytes->base64 (string->bytes "fo")) "Zm8=")))

(test "base64 of 'foo'" (lambda ()
  (assert-equal (bytes->base64 (string->bytes "foo")) "Zm9v")))

(test "base64 of 'foob'" (lambda ()
  (assert-equal (bytes->base64 (string->bytes "foob")) "Zm9vYg==")))

(test "base64 of 'fooba'" (lambda ()
  (assert-equal (bytes->base64 (string->bytes "fooba")) "Zm9vYmE=")))

(test "base64 of 'foobar'" (lambda ()
  (assert-equal (bytes->base64 (string->bytes "foobar")) "Zm9vYmFy")))

;; NOTE: The end-to-end `base64(sha1(...))` WebSocket handshake test lives in
;; tests/ece/cl-only/test-sha1-base64-websocket.scm because SHA-1 currently
;; only produces correct results on the CL runtime (see src/sha1.scm header
;; for the WASM limitation).
