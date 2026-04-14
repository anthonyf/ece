;;; sha1.scm — SHA-1 hash function in pure ECE
;;;
;;; Implements SHA-1 per RFC 3174 / FIPS 180-1. Used by ece-serve.scm for
;;; the WebSocket handshake (RFC 6455 §4.2.2: Sec-WebSocket-Accept is
;;; base64(sha1(client-key || magic-guid))), and available as a general
;;; reusable crypto utility. Runs on both CL and WASM runtimes.
;;;
;;; Public API:
;;;   (sha1-string str)        → list of 20 bytes (integers 0-255)
;;;   (sha1-bytes byte-list)   → list of 20 bytes
;;;
;;; ── Security caveats ───────────────────────────────────────────────────
;;; Not a constant-time implementation. Not suitable for password hashing
;;; or other security-sensitive comparisons. SHA-1 itself is broken for
;;; collision resistance; its use here is confined to the WebSocket
;;; handshake where only the key-agreement property is relied on and the
;;; RFC mandates this specific algorithm.

;; ── 32-bit helpers ──────────────────────────────────────────────────────

(define sha1/mask32 4294967295)                 ; 2^32 - 1

(define (sha1/u32 x)
  (bitwise-and x sha1/mask32))

(define (sha1/u32+ a b)
  (sha1/u32 (+ a b)))

(define (sha1/rotl x n)
  "Rotate x left by n bits within a 32-bit word. The right-shifted
   contribution is masked with ((1 << n) - 1) so it carries exactly n
   bits from the top of x — this gives the same result on runtimes
   where arithmetic right shift sign-extends (WASM signed i32) as on
   runtimes where it zero-extends (CL non-negative bignum)."
  (let ((masked (sha1/u32 x)))
    (sha1/u32
     (bitwise-or
      (arithmetic-shift masked n)
      (bitwise-and (arithmetic-shift masked (- n 32))
                   (- (arithmetic-shift 1 n) 1))))))

;; ── Message padding ─────────────────────────────────────────────────────

(define (sha1/make-zero-list n)
  (if (<= n 0)
      '()
      (cons 0 (sha1/make-zero-list (- n 1)))))

(define (sha1/u64-be n)
  "Encode n as 8 big-endian bytes (most significant first)."
  (list
   (bitwise-and (arithmetic-shift n -56) 255)
   (bitwise-and (arithmetic-shift n -48) 255)
   (bitwise-and (arithmetic-shift n -40) 255)
   (bitwise-and (arithmetic-shift n -32) 255)
   (bitwise-and (arithmetic-shift n -24) 255)
   (bitwise-and (arithmetic-shift n -16) 255)
   (bitwise-and (arithmetic-shift n -8) 255)
   (bitwise-and n 255)))

(define (sha1/pad bytes)
  "FIPS 180-1 padding: append 0x80, enough zeros to leave 8 bytes until a
   multiple of 64, then the original length in bits as 8 big-endian bytes."
  (let* ((orig-len (length bytes))
         (bit-len (* orig-len 8))
         ;; We need orig-len + 1 (for 0x80) + zeros + 8 ≡ 0 (mod 64).
         ;; Solve for zeros, keeping it non-negative.
         (remainder (modulo (+ orig-len 1 8) 64))
         (zeros (if (= remainder 0) 0 (- 64 remainder))))
    (append bytes
            (list 128)                         ; 0x80
            (sha1/make-zero-list zeros)
            (sha1/u64-be bit-len))))

;; ── Block processing ────────────────────────────────────────────────────

(define (sha1/bytes->u32-be b0 b1 b2 b3)
  (sha1/u32
   (bitwise-or
    (arithmetic-shift b0 24)
    (bitwise-or
     (arithmetic-shift b1 16)
     (bitwise-or
      (arithmetic-shift b2 8)
      b3)))))

(define (sha1/fill-words! w block-vec start)
  "Fill the first 16 slots of the reusable 80-element schedule vector w
   with big-endian 32-bit words read from block-vec at byte offset start.
   The caller owns w and reuses it across blocks; this procedure mutates
   in place to avoid per-block allocation churn."
  (let loop ((i 0))
    (when (< i 16)
      (let ((off (+ start (* i 4))))
        (vector-set! w i
                     (sha1/bytes->u32-be
                      (vector-ref block-vec off)
                      (vector-ref block-vec (+ off 1))
                      (vector-ref block-vec (+ off 2))
                      (vector-ref block-vec (+ off 3)))))
      (loop (+ i 1)))))

(define (sha1/extend-words! w)
  "Extend the initial 16 words to 80 via the SHA-1 message schedule."
  (let loop ((t 16))
    (when (< t 80)
      (vector-set! w t
                   (sha1/rotl
                    (bitwise-xor
                     (vector-ref w (- t 3))
                     (vector-ref w (- t 8))
                     (vector-ref w (- t 14))
                     (vector-ref w (- t 16)))
                    1))
      (loop (+ t 1)))))

(define (sha1/f t b c d)
  "Round function per RFC 3174 §5."
  (cond
   ((<= t 19)
    (bitwise-or
     (bitwise-and b c)
     (bitwise-and (sha1/u32 (bitwise-not b)) d)))
   ((<= t 39)
    (bitwise-xor b c d))
   ((<= t 59)
    (bitwise-or
     (bitwise-and b c)
     (bitwise-and b d)
     (bitwise-and c d)))
   (else
    (bitwise-xor b c d))))

(define (sha1/k t)
  "Round constant per RFC 3174 §5."
  (cond
   ((<= t 19) 1518500249)     ; 0x5A827999
   ((<= t 39) 1859775393)     ; 0x6ED9EBA1
   ((<= t 59) 2400959708)     ; 0x8F1BBCDC
   (else      3395469782)))   ; 0xCA62C1D6

(define (sha1/process-block state w block-vec start)
  "Process one 64-byte block of block-vec starting at byte offset start.
   state is a 5-element vector (h0..h4), updated in place.
   w is the reusable 80-element schedule vector, allocated once by the
   caller and overwritten each block — the first 16 slots are filled from
   block-vec and the remaining 64 are computed by the message schedule."
  (sha1/fill-words! w block-vec start)
  (sha1/extend-words! w)
  (let loop ((t 0)
             (a (vector-ref state 0))
             (b (vector-ref state 1))
             (c (vector-ref state 2))
             (d (vector-ref state 3))
             (e (vector-ref state 4)))
    (if (< t 80)
        (let ((temp (sha1/u32+
                     (sha1/u32+
                      (sha1/u32+
                       (sha1/u32+ (sha1/rotl a 5)
                                  (sha1/f t b c d))
                       e)
                      (vector-ref w t))
                     (sha1/k t))))
          (loop (+ t 1)
                temp
                a
                (sha1/rotl b 30)
                c
                d))
        (begin
          (vector-set! state 0 (sha1/u32+ (vector-ref state 0) a))
          (vector-set! state 1 (sha1/u32+ (vector-ref state 1) b))
          (vector-set! state 2 (sha1/u32+ (vector-ref state 2) c))
          (vector-set! state 3 (sha1/u32+ (vector-ref state 3) d))
          (vector-set! state 4 (sha1/u32+ (vector-ref state 4) e))))))

;; ── Top-level API ───────────────────────────────────────────────────────

(define (sha1/u32->bytes-be n)
  (list
   (bitwise-and (arithmetic-shift n -24) 255)
   (bitwise-and (arithmetic-shift n -16) 255)
   (bitwise-and (arithmetic-shift n -8) 255)
   (bitwise-and n 255)))

(define (sha1/list->vector lst)
  (let* ((len (length lst))
         (v (make-vector len 0)))
    (let loop ((i 0) (xs lst))
      (if (pair? xs)
          (begin
            (vector-set! v i (car xs))
            (loop (+ i 1) (cdr xs)))
          v))))

(define (sha1-bytes bytes)
  "Compute SHA-1 of a list of integer bytes (0-255). Returns a 20-byte list.
   Allocates the 5-element state vector and the 80-element message schedule
   vector once up front and reuses them across all blocks of the input."
  (let* ((padded (sha1/pad bytes))
         (block-vec (sha1/list->vector padded))
         (total-len (vector-length block-vec))
         (state (make-vector 5 0))
         (w (make-vector 80 0)))
    (vector-set! state 0 1732584193)    ; 0x67452301
    (vector-set! state 1 4023233417)    ; 0xEFCDAB89
    (vector-set! state 2 2562383102)    ; 0x98BADCFE
    (vector-set! state 3 271733878)     ; 0x10325476
    (vector-set! state 4 3285377520)    ; 0xC3D2E1F0
    (let loop ((start 0))
      (if (>= start total-len)
          (append
           (sha1/u32->bytes-be (vector-ref state 0))
           (sha1/u32->bytes-be (vector-ref state 1))
           (sha1/u32->bytes-be (vector-ref state 2))
           (sha1/u32->bytes-be (vector-ref state 3))
           (sha1/u32->bytes-be (vector-ref state 4)))
          (begin
            (sha1/process-block state w block-vec start)
            (loop (+ start 64)))))))

(define (sha1-string str)
  "Compute SHA-1 of a string. Character code points are used directly as
   bytes; callers that need UTF-8 semantics must pre-encode non-ASCII."
  (sha1-bytes
   (let loop ((i 0) (acc '()))
     (if (< i (string-length str))
         (loop (+ i 1)
               (cons (char->integer (string-ref str i)) acc))
         (reverse acc)))))
