;;; ECE WebSocket codec module
;;; Module exports for the RFC 6455 codec helpers in websocket-codec.scm.

(define-module (ece websocket codec)
  (export ws-compute-accept-key
          ws-encode-text-frame
          ws-encode-close-frame
          ws-encode-ping-frame
          ws-encode-pong-frame
          ws-decode-frame
          ws-frame?
          ws-frame-opcode
          ws-frame-payload-bytes
          ws-frame-payload-text
          ws-frame-total-length)

  (define ws-compute-accept-key (%global-ref ws-compute-accept-key))
  (define ws-encode-text-frame (%global-ref ws-encode-text-frame))
  (define ws-encode-close-frame (%global-ref ws-encode-close-frame))
  (define ws-encode-ping-frame (%global-ref ws-encode-ping-frame))
  (define ws-encode-pong-frame (%global-ref ws-encode-pong-frame))
  (define ws-decode-frame (%global-ref ws-decode-frame))
  (define ws-frame? (%global-ref ws-frame?))
  (define ws-frame-opcode (%global-ref ws-frame-opcode))
  (define ws-frame-payload-bytes (%global-ref ws-frame-payload-bytes))
  (define ws-frame-payload-text (%global-ref ws-frame-payload-text))
  (define ws-frame-total-length (%global-ref ws-frame-total-length)))
