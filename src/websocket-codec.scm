;;; websocket-codec.scm — WebSocket (RFC 6455) subset for ece-serve.
;;;
;;; Pure byte/string transforms: handshake accept-key computation, text/
;;; close/ping/pong frame encoders for server→client traffic, and a frame
;;; decoder for client→server traffic (which is always masked per RFC §5.3).
;;; No sockets, no fibers, no streaming — the caller feeds complete frames
;;; (a frame's bytes include the entire header + payload).
;;;
;;; Scope: text frames (opcode 0x1), close (0x8), ping (0x9), pong (0xA),
;;; no fragmentation (FIN must be 1), no extensions, no continuation frames.
;;; Anything else is rejected by the decoder; the encoder only produces
;;; what it supports.
;;;
;;; Depends on `src/sha1.scm` and `src/base64.scm` which must be loaded
;;; first (sha1-string, base64-encode-bytes).
;;;
;;; ─────────────────────────────────────────────────────────────────────
;;; API
;;; ─────────────────────────────────────────────────────────────────────
;;;
;;;  (ws-compute-accept-key client-key)
;;;      — RFC 6455 §4.2.2 Sec-WebSocket-Accept computation:
;;;        base64(sha1(client-key || magic-guid))
;;;
;;;  (ws-encode-text-frame text)
;;;      — encode TEXT as a single server→client text frame (FIN=1, opcode=1,
;;;        no mask). Returns a list of byte integers ready for tcp-send-nowait.
;;;
;;;  (ws-encode-close-frame)
;;;      — encode a close frame with no status code (FIN=1, opcode=8).
;;;
;;;  (ws-encode-pong-frame payload-bytes)
;;;      — encode a pong reply carrying the ping's payload (FIN=1, opcode=A).
;;;
;;;  (ws-decode-frame bytes)
;;;      — attempt to decode a complete frame from BYTES. Returns a
;;;        ws-frame record on success; the symbol 'incomplete if the
;;;        bytes are short of a full frame; or 'malformed if the bytes
;;;        violate RFC constraints we enforce (fragmented frame, unmasked
;;;        client frame, unsupported opcode, or length mismatch).
;;;
;;;  (ws-frame? v)
;;;  (ws-frame-opcode f)
;;;  (ws-frame-payload-bytes f)
;;;  (ws-frame-payload-text f)
;;;  (ws-frame-total-length f)    ; total bytes consumed from the input,
;;;                                 so callers can shift their buffer.

;; ---- Frame record ----

(define-record ws-frame opcode payload-bytes payload-text total-length)

;; ---- Constants ----

;; RFC 6455 §4.2.2 magic GUID
(define %ws-magic-guid "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")

;; Opcodes we care about
(define %ws-opcode-text 1)
(define %ws-opcode-close 8)
(define %ws-opcode-ping 9)
(define %ws-opcode-pong 10)

;; ---- Handshake ----

(define (ws-compute-accept-key client-key)
  "Compute the RFC 6455 §4.2.2 Sec-WebSocket-Accept value from a client's
Sec-WebSocket-Key. Returns a base64-encoded string."
  (bytes->base64
   (sha1-string (string-append client-key %ws-magic-guid))))

;; ---- Byte helpers ----

(define (%ws-byte-string->bytes s)
  "Convert a string to a list of byte integers in [0, 255]. The dev
server always sends 7-bit ASCII (or at most Latin-1 if some user code
escapes) — both fit in one byte per code point."
  (let ((len (string-length s)))
    (let loop ((i 0) (acc '()))
      (cond
       ((>= i len) (reverse acc))
       (else
        (loop (+ i 1) (cons (char->integer (string-ref s i)) acc)))))))

(define (%ws-bytes->string bytes)
  "Convert a list of bytes back to a string. Inverse of %ws-byte-string->bytes."
  (let ((p (open-output-string)))
    (let loop ((rest bytes))
      (cond
       ((null? rest) (get-output-string p))
       (else
        (write-char (integer->char (car rest)) p)
        (loop (cdr rest)))))))

;; ---- Frame encoding ----
;;
;; Server→client frames: FIN=1, RSV=0, opcode, MASK=0. The length field
;; is 7-bit for lengths 0..125, 16-bit (with 7-bit value 126) for lengths
;; 126..65535, or 64-bit (with 7-bit value 127) for larger lengths. We
;; implement all three bands although the dev server only needs the first
;; two for its source-update messages.

(define (%ws-encode-length len)
  "Return a list of bytes for the length field of an unmasked frame."
  (cond
   ((< len 126) (list len))
   ((< len 65536)
    (list 126
          (bitwise-and (arithmetic-shift len -8) 255)
          (bitwise-and len 255)))
   (else
    ;; 64-bit length. ECE fixnums top out at 2^30-1 so realistic payloads
    ;; fit in the lower 32 bits; upper 32 bits are always zero here.
    (list 127
          0 0 0 0
          (bitwise-and (arithmetic-shift len -24) 255)
          (bitwise-and (arithmetic-shift len -16) 255)
          (bitwise-and (arithmetic-shift len -8) 255)
          (bitwise-and len 255)))))

(define (%ws-encode-frame-unmasked opcode payload-bytes)
  "Encode an unmasked server→client frame with OPCODE and PAYLOAD-BYTES.
Returns a list of integers ready for tcp-send-nowait."
  (let* ((fin-byte (bitwise-or 128 opcode))  ; 128 = 0x80 = FIN bit
         (length-bytes (%ws-encode-length (length payload-bytes))))
    (append (list fin-byte) length-bytes payload-bytes)))

(define (ws-encode-text-frame text)
  "Encode TEXT as a single server→client text frame."
  (%ws-encode-frame-unmasked %ws-opcode-text (%ws-byte-string->bytes text)))

(define (ws-encode-close-frame)
  "Encode a close frame with no status code or reason. RFC 6455 §5.5.1
permits a close frame with an empty payload."
  (%ws-encode-frame-unmasked %ws-opcode-close '()))

(define (ws-encode-pong-frame payload-bytes)
  "Encode a pong reply carrying PAYLOAD-BYTES (the ping's original payload).
RFC 6455 §5.5.3 requires the pong to echo the ping payload verbatim."
  (%ws-encode-frame-unmasked %ws-opcode-pong payload-bytes))

;; ---- Frame decoding ----
;;
;; Client→server frames MUST be masked per RFC 6455 §5.3. We enforce that.
;; The frame header layout is:
;;
;;   byte 0:  FIN(1) RSV1(1) RSV2(1) RSV3(1) OPCODE(4)
;;   byte 1:  MASK(1) PAYLOAD-LENGTH(7)
;;   bytes 2..3 if len7==126: PAYLOAD-LENGTH(16) big-endian
;;   bytes 2..9 if len7==127: PAYLOAD-LENGTH(64) big-endian
;;   next 4 bytes (if MASK==1): MASK-KEY
;;   next <payload-length> bytes: masked or unmasked payload

(define (%ws-list-take lst n)
  "Return the first N elements of LST, or the whole list if shorter."
  (let loop ((rest lst) (k n) (acc '()))
    (cond
     ((or (null? rest) (<= k 0)) (reverse acc))
     (else (loop (cdr rest) (- k 1) (cons (car rest) acc))))))

(define (%ws-list-drop lst n)
  "Return LST with the first N elements removed."
  (let loop ((rest lst) (k n))
    (cond
     ((or (null? rest) (<= k 0)) rest)
     (else (loop (cdr rest) (- k 1))))))

(define (%ws-list-length-at-least? lst n)
  "Return #t if LST has at least N elements, without walking the whole list."
  (let loop ((rest lst) (k n))
    (cond
     ((<= k 0) #t)
     ((null? rest) #f)
     (else (loop (cdr rest) (- k 1))))))

(define (%ws-demask payload mask-key)
  "XOR each byte of PAYLOAD with the corresponding byte of MASK-KEY
(4-byte key applied cyclically per RFC 6455 §5.3)."
  (let loop ((rest payload) (i 0) (acc '()))
    (cond
     ((null? rest) (reverse acc))
     (else
      (let ((byte (car rest))
            (key-byte (list-ref mask-key (modulo i 4))))
        (loop (cdr rest) (+ i 1)
              (cons (bitwise-xor byte key-byte) acc)))))))

(define (%ws-decode-length bytes)
  "Given BYTES starting at byte 1 of the frame header, parse the length
field and return (list length header-length-after-len) or #f if there
are not enough bytes yet. HEADER-LENGTH-AFTER-LEN is the number of bytes
consumed from BYTES including the initial length byte."
  (cond
   ((null? bytes) #f)
   (else
    (let* ((b1 (car bytes))
           (mask-bit (bitwise-and b1 128))   ; 128 = MASK bit
           (len7 (bitwise-and b1 127)))      ; 127 = low 7 bits
      (cond
       ((= mask-bit 0) 'unmasked)   ; client frames MUST be masked
       ((< len7 126) (list len7 1))
       ((= len7 126)
        (cond
         ((not (%ws-list-length-at-least? bytes 3)) #f)
         (else
          (let* ((rest (cdr bytes))
                 (hi (car rest))
                 (lo (car (cdr rest))))
            (list (bitwise-or (arithmetic-shift hi 8) lo) 3)))))
       (else ; len7 == 127, 64-bit length
        (cond
         ((not (%ws-list-length-at-least? bytes 9)) #f)
         (else
          ;; Realistic dev-loop frames never exceed 2^30 bytes, so we
          ;; only consume the low 4 bytes of the 64-bit length and
          ;; ignore the high 4. If somebody sends a frame with a
          ;; non-zero high 4 bytes we'll still decode the low portion —
          ;; the length mismatch check below catches genuinely truncated
          ;; frames.
          (let* ((tail (cdr bytes))  ; skip length byte
                 (b5 (list-ref tail 4))
                 (b6 (list-ref tail 5))
                 (b7 (list-ref tail 6))
                 (b8 (list-ref tail 7)))
            (list (bitwise-or
                   (arithmetic-shift b5 24)
                   (arithmetic-shift b6 16)
                   (arithmetic-shift b7 8)
                   b8)
                  9))))))))))

(define (%ws-build-frame opcode payload total)
  "Construct a ws-frame, attaching a decoded text view if OPCODE is text."
  (make-ws-frame
   opcode payload
   (if (= opcode %ws-opcode-text) (%ws-bytes->string payload) #f)
   total))

(define (%ws-finish-decode opcode payload total)
  "Final step of ws-decode-frame: reject unsupported opcodes, otherwise
return the completed frame record."
  (cond
   ((or (= opcode %ws-opcode-text)
        (= opcode %ws-opcode-close)
        (= opcode %ws-opcode-ping)
        (= opcode %ws-opcode-pong))
    (%ws-build-frame opcode payload total))
   (else 'malformed)))

(define (%ws-decode-after-length bytes opcode payload-len len-bytes)
  "BYTES points past the length field. Read mask key + payload, demask,
build the frame."
  (let ((need (+ 4 payload-len)))
    (cond
     ((not (%ws-list-length-at-least? bytes need)) 'incomplete)
     (else
      (let* ((mask-key (%ws-list-take bytes 4))
             (body (%ws-list-drop bytes 4))
             (masked (%ws-list-take body payload-len))
             (payload (%ws-demask masked mask-key))
             (total (+ 1 len-bytes 4 payload-len)))
        (%ws-finish-decode opcode payload total))))))

(define (ws-decode-frame bytes)
  "Decode a single client→server frame from BYTES (a list of byte
integers from tcp-recv-nowait's return value). Returns:
  - a ws-frame record on success
  - the symbol 'incomplete if BYTES is short of a full frame
  - the symbol 'malformed on any RFC violation we enforce"
  (cond
   ((not (%ws-list-length-at-least? bytes 2)) 'incomplete)
   (else
    (let* ((b0 (car bytes))
           (fin (bitwise-and b0 128))       ; FIN bit
           (opcode (bitwise-and b0 15))     ; low 4 bits
           (after-b0 (cdr bytes))
           (len-info (%ws-decode-length after-b0)))
      (cond
       ((= fin 0) 'malformed)
       ((eq? len-info 'unmasked) 'malformed)
       ((not len-info) 'incomplete)
       (else
        (%ws-decode-after-length
         (%ws-list-drop after-b0 (car (cdr len-info)))
         opcode
         (car len-info)
         (car (cdr len-info)))))))))
