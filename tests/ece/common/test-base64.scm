;;; Base64 encoding tests — RFC 4648 test vectors + WebSocket handshake
;;; round-trip through sha1 + base64.

(define (string->bytes s)
  (let loop ((i 0) (acc '()))
    (if (< i (string-length s))
        (loop (+ i 1) (cons (char->integer (string-ref s i)) acc))
        (reverse acc))))

(test "base64 empty" (lambda ()
  (assert-equal (base64-encode-bytes '()) "")))

(test "base64 of 'f'" (lambda ()
  (assert-equal (base64-encode-bytes (string->bytes "f")) "Zg==")))

(test "base64 of 'fo'" (lambda ()
  (assert-equal (base64-encode-bytes (string->bytes "fo")) "Zm8=")))

(test "base64 of 'foo'" (lambda ()
  (assert-equal (base64-encode-bytes (string->bytes "foo")) "Zm9v")))

(test "base64 of 'foob'" (lambda ()
  (assert-equal (base64-encode-bytes (string->bytes "foob")) "Zm9vYg==")))

(test "base64 of 'fooba'" (lambda ()
  (assert-equal (base64-encode-bytes (string->bytes "fooba")) "Zm9vYmE=")))

(test "base64 of 'foobar'" (lambda ()
  (assert-equal (base64-encode-bytes (string->bytes "foobar")) "Zm9vYmFy")))

(test "base64 of RFC 6455 WebSocket handshake sha1 digest" (lambda ()
  ;; End-to-end check from the WebSocket RFC example:
  ;;   key        = "dGhlIHNhbXBsZSBub25jZQ=="
  ;;   concat     = key || "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  ;;   sha1 hex   = b37a4f2cc0624f1690f64606cf3859456b2fc4ea
  ;;   base64     = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
  (assert-equal
    (base64-encode-bytes
      (sha1-string "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")))
