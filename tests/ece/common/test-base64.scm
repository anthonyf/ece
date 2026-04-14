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

(test "base64(sha1(websocket-key || magic)) matches RFC 6455 §1.3" (lambda ()
  ;; End-to-end SHA-1 + Base64 round-trip: the RFC 6455 WebSocket handshake
  ;; example. If this passes, both primitives are wired up correctly and
  ;; the bitwise-primitive chain used by SHA-1 is running cross-runtime.
  (assert-equal
    (bytes->base64
      (sha1-string "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")))
