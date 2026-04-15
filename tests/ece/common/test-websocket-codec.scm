;;; Unit tests for src/websocket-codec.scm — RFC 6455 subset handshake
;;; + frame codec. Pure functions against fixed byte fixtures.

(define (ws-test/repeat-char ch n)
  "Build an N-character string consisting of CH repeated. Used for
frame-length boundary tests since ECE doesn't expose make-string."
  (let ((p (open-output-string)))
    (let loop ((i 0))
      (cond
       ((>= i n) (get-output-string p))
       (else (write-char ch p) (loop (+ i 1)))))))

;; ── RFC 6455 §4.2.2 accept-key computation ──────────────────────────────

(test "ws-codec: compute-accept-key matches RFC 6455 §1.3" (lambda ()
  ;; The canonical RFC 6455 §1.3 example.
  (assert-equal (ws-compute-accept-key "dGhlIHNhbXBsZSBub25jZQ==")
                "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")))

;; ── Text frame encode: short payload ────────────────────────────────────

(test "ws-codec: encode-text-frame for \"Hello\"" (lambda ()
  ;; FIN=1 opcode=1 → 129 ; MASK=0 len=5 → 5 ; payload = "Hello" bytes.
  (assert-equal (ws-encode-text-frame "Hello")
                '(129 5 72 101 108 108 111))))

(test "ws-codec: encode-text-frame for empty string" (lambda ()
  (assert-equal (ws-encode-text-frame "") '(129 0))))

(test "ws-codec: encode-text-frame for 125-byte boundary" (lambda ()
  (let* ((text (ws-test/repeat-char #\a 125))
         (frame (ws-encode-text-frame text)))
    ;; Byte 0 = FIN+opcode=129, byte 1 = 125 (still 7-bit), then 125 'a's.
    (assert-equal (car frame) 129)
    (assert-equal (car (cdr frame)) 125)
    (assert-equal (length frame) 127))))

;; ── Text frame encode: 16-bit length ────────────────────────────────────

(test "ws-codec: encode-text-frame for 126-byte payload uses 16-bit length" (lambda ()
  (let* ((text (ws-test/repeat-char #\b 126))
         (frame (ws-encode-text-frame text)))
    ;; Byte 0 = 129, byte 1 = 126 (signal 16-bit), bytes 2-3 = 0x00 0x7E = 0 126
    (assert-equal (car frame) 129)
    (assert-equal (car (cdr frame)) 126)
    (assert-equal (car (cdr (cdr frame))) 0)
    (assert-equal (car (cdr (cdr (cdr frame)))) 126)
    (assert-equal (length frame) 130))))  ; 2 header + 2 length + 126 payload

(test "ws-codec: encode-text-frame for 1000-byte payload" (lambda ()
  (let* ((text (ws-test/repeat-char #\c 1000))
         (frame (ws-encode-text-frame text)))
    ;; 1000 = 0x03E8 → big-endian bytes 3 232
    (assert-equal (car frame) 129)
    (assert-equal (car (cdr frame)) 126)
    (assert-equal (car (cdr (cdr frame))) 3)
    (assert-equal (car (cdr (cdr (cdr frame)))) 232)
    (assert-equal (length frame) 1004))))

;; ── Text frame encode: 64-bit length ────────────────────────────────────

(test "ws-codec: encode-text-frame for 65536-byte payload uses 64-bit length" (lambda ()
  (let* ((text (ws-test/repeat-char #\d 65536))
         (frame (ws-encode-text-frame text)))
    ;; Byte 0 = 129, byte 1 = 127 (signal 64-bit),
    ;; bytes 2-5 = 0 (upper 32 bits), bytes 6-9 = 0 1 0 0 (lower 32 bits = 65536)
    (assert-equal (car frame) 129)
    (assert-equal (car (cdr frame)) 127)
    ;; Upper 32 bits all zero
    (assert-equal (car (cdr (cdr frame))) 0)
    (assert-equal (car (cdr (cdr (cdr frame)))) 0)
    (assert-equal (car (cdr (cdr (cdr (cdr frame))))) 0)
    (assert-equal (car (cdr (cdr (cdr (cdr (cdr frame)))))) 0)
    ;; Lower 32 bits: 0 1 0 0 = 0x00010000 = 65536
    (assert-equal (car (cdr (cdr (cdr (cdr (cdr (cdr frame))))))) 0)
    (assert-equal (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr frame)))))))) 1)
    (assert-equal (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr frame))))))))) 0)
    (assert-equal (length frame) (+ 10 65536)))))  ; 2 + 8 + 65536

;; ── Close / pong frame encoders ─────────────────────────────────────────

(test "ws-codec: encode-close-frame is FIN+opcode=8 with empty payload" (lambda ()
  ;; 0x88 = 136
  (assert-equal (ws-encode-close-frame) '(136 0))))

(test "ws-codec: encode-pong-frame echoes the ping payload" (lambda ()
  ;; 0x8A = 138
  (assert-equal (ws-encode-pong-frame '(72 105 33)) '(138 3 72 105 33))))

(test "ws-codec: encode-pong-frame with empty payload" (lambda ()
  (assert-equal (ws-encode-pong-frame '()) '(138 0))))

;; ── Frame decoder: RFC 6455 §5.7 masked text example ───────────────────

(test "ws-codec: decode masked \"Hello\" text frame (RFC 6455 §5.7)" (lambda ()
  ;; RFC 6455 §5.7 "A single-frame masked text message":
  ;; bytes: 0x81 0x85 0x37 0xfa 0x21 0x3d 0x7f 0x9f 0x4d 0x51 0x58
  ;;      = 129 133 55 250 33 61 127 159 77 81 88
  (let* ((frame-bytes '(129 133 55 250 33 61 127 159 77 81 88))
         (frame (ws-decode-frame frame-bytes)))
    (assert-true (ws-frame? frame))
    (assert-equal (ws-frame-opcode frame) 1)  ; text
    (assert-equal (ws-frame-payload-text frame) "Hello")
    (assert-equal (ws-frame-total-length frame) 11))))

;; ── Frame decoder: incomplete inputs ────────────────────────────────────

(test "ws-codec: decode returns 'incomplete for too-short input" (lambda ()
  (assert-equal (ws-decode-frame '()) 'incomplete)
  (assert-equal (ws-decode-frame '(129)) 'incomplete)
  ;; Claims 5-byte payload, mask key + partial payload missing:
  (assert-equal (ws-decode-frame '(129 133)) 'incomplete)
  (assert-equal (ws-decode-frame '(129 133 55 250 33 61 127)) 'incomplete)))

;; ── Frame decoder: malformed inputs ────────────────────────────────────

(test "ws-codec: decode rejects a fragmented frame (FIN=0)" (lambda ()
  ;; byte 0 = 0x01 = opcode=1, FIN=0
  (assert-equal (ws-decode-frame '(1 133 55 250 33 61 127 159 77 81 88))
                'malformed)))

(test "ws-codec: decode rejects an unmasked client frame" (lambda ()
  ;; byte 0 = 129 (FIN+text), byte 1 = 5 (no MASK bit), then "Hello" plain.
  (assert-equal (ws-decode-frame '(129 5 72 101 108 108 111))
                'malformed)))

(test "ws-codec: decode rejects an unsupported opcode" (lambda ()
  ;; byte 0 = 0x8F = FIN + opcode=0xF (reserved). Masked, zero-length.
  (assert-equal (ws-decode-frame '(143 128 0 0 0 0))
                'malformed)))

;; ── Frame decoder: close and ping echo ──────────────────────────────────

(test "ws-codec: decode a masked close frame" (lambda ()
  ;; byte 0 = 0x88 = FIN+close, byte 1 = 0x80 (MASK, len=0), mask key (any 4 bytes).
  (let ((frame (ws-decode-frame '(136 128 1 2 3 4))))
    (assert-true (ws-frame? frame))
    (assert-equal (ws-frame-opcode frame) 8)
    (assert-equal (ws-frame-payload-bytes frame) '())
    (assert-equal (ws-frame-total-length frame) 6))))

(test "ws-codec: decode a masked ping frame with payload" (lambda ()
  ;; byte 0 = 0x89 = FIN+ping, byte 1 = 0x83 (MASK, len=3),
  ;; mask key (0x01 0x02 0x03 0x04), masked payload.
  ;; plaintext 65 66 67 XOR mask = 64 64 64
  ;;    65 XOR 0x01 = 64
  ;;    66 XOR 0x02 = 64
  ;;    67 XOR 0x03 = 64
  (let ((frame (ws-decode-frame '(137 131 1 2 3 4 64 64 64))))
    (assert-true (ws-frame? frame))
    (assert-equal (ws-frame-opcode frame) 9)
    (assert-equal (ws-frame-payload-bytes frame) '(65 66 67))
    (assert-equal (ws-frame-total-length frame) 9))))

;; ── Round-trip: send-encode then parse mentally against the fixture ───

(test "ws-codec: encode-text-frame round-trip through byte introspection" (lambda ()
  ;; We can't decode a server-sent frame because the decoder enforces
  ;; MASK=1 for client frames. Instead, verify the encoding piecewise.
  (let ((f (ws-encode-text-frame "ECE")))
    ;; FIN+text
    (assert-equal (car f) 129)
    ;; 7-bit length 3
    (assert-equal (car (cdr f)) 3)
    ;; Payload = "ECE" bytes
    (assert-equal (cdr (cdr f)) '(69 67 69)))))
