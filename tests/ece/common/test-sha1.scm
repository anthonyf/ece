;;; SHA-1 tests — RFC 3174 test vectors + the RFC 6455 WebSocket handshake
;;; example. SHA-1 is used in ece-serve.scm for the WebSocket Accept header.

;; Helper: turn a list of bytes into a lowercase hex string, so test
;; expectations match the RFC format.
(define (bytes->hex bytes)
  (define hexchars "0123456789abcdef")
  (let loop ((xs bytes) (acc '()))
    (if (null? xs)
        (apply string-append (reverse acc))
        (let ((b (car xs)))
          (loop (cdr xs)
                (cons (substring hexchars (bitwise-and b 15) (+ (bitwise-and b 15) 1))
                      (cons (substring hexchars (arithmetic-shift b -4) (+ (arithmetic-shift b -4) 1))
                            acc)))))))

(test "sha1 of empty string" (lambda ()
  (assert-equal
    (bytes->hex (sha1-string ""))
    "da39a3ee5e6b4b0d3255bfef95601890afd80709")))

(test "sha1 of 'abc'" (lambda ()
  ;; RFC 3174 test vector 1
  (assert-equal
    (bytes->hex (sha1-string "abc"))
    "a9993e364706816aba3e25717850c26c9cd0d89d")))

(test "sha1 of 448-bit message (two-block)" (lambda ()
  (assert-equal
    (bytes->hex (sha1-string "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"))
    "84983e441c3bd26ebaae4aa1f95129e5e54670f1")))

(test "sha1 produces 20 bytes" (lambda ()
  (assert-equal (length (sha1-string "hello world")) 20)))

(test "sha1 of RFC 6455 WebSocket handshake input" (lambda ()
  ;; RFC 6455 §1.3: Sec-WebSocket-Accept is derived from
  ;;   sha1("dGhlIHNhbXBsZSBub25jZQ==" || "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
  ;; and the expected base64-encoded result is "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=".
  ;; The intermediate SHA-1 digest here is derived from that round-trip;
  ;; test-base64.scm has the authoritative end-to-end check against the
  ;; RFC's final Sec-WebSocket-Accept string.
  (assert-equal
    (bytes->hex
      (sha1-string "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    "b37a4f2cc0624f1690f64606cf385945b2bec4ea")))
