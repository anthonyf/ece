;;; End-to-end SHA-1 + Base64 round-trip: RFC 6455 WebSocket handshake.
;;;
;;; CL-only because SHA-1 currently relies on 32-bit integer arithmetic
;;; that exceeds the WASM runtime's 30-bit fixnum range. When the WASM
;;; runtime is updated so bitwise-or / bitwise-xor / bitwise-not /
;;; arithmetic-shift all handle large integers via the same
;;; to-f64/safe-trunc-i32 path that bitwise-and already uses, this test
;;; can move back to tests/ece/common/test-base64.scm.

(test "base64(sha1(websocket-key || magic)) matches RFC 6455 §1.3" (lambda ()
  (assert-equal
    (bytes->base64
      (sha1-string "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")))
