;;; base64.scm — Base64 encoding in pure ECE (RFC 4648)
;;;
;;; Used by ece-serve.scm for the WebSocket handshake response header
;;; Sec-WebSocket-Accept = base64(sha1(client-key || magic-guid)). Also a
;;; general reusable encoding utility.
;;;
;;; Public API:
;;;   (base64-encode-bytes byte-list)  → string
;;;
;;; Not implemented: base64 decoding, MIME-style line wrapping, URL-safe
;;; variants. Add them when a concrete use case materializes.

(define base64/alphabet
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

(define (base64/char idx)
  "Return the single-character string at index idx in the Base64 alphabet."
  (substring base64/alphabet idx (+ idx 1)))

(define (base64/encode-3 b0 b1 b2)
  "Encode three bytes as four Base64 characters (one full group)."
  (let ((n (bitwise-or
            (arithmetic-shift b0 16)
            (arithmetic-shift b1 8)
            b2)))
    (string-append
     (base64/char (bitwise-and (arithmetic-shift n -18) 63))
     (base64/char (bitwise-and (arithmetic-shift n -12) 63))
     (base64/char (bitwise-and (arithmetic-shift n -6) 63))
     (base64/char (bitwise-and n 63)))))

(define (base64/encode-2 b0 b1)
  "Encode two trailing bytes: three chars + one '=' padding."
  (let ((n (bitwise-or
            (arithmetic-shift b0 16)
            (arithmetic-shift b1 8))))
    (string-append
     (base64/char (bitwise-and (arithmetic-shift n -18) 63))
     (base64/char (bitwise-and (arithmetic-shift n -12) 63))
     (base64/char (bitwise-and (arithmetic-shift n -6) 63))
     "=")))

(define (base64/encode-1 b0)
  "Encode one trailing byte: two chars + two '=' padding."
  (let ((n (arithmetic-shift b0 16)))
    (string-append
     (base64/char (bitwise-and (arithmetic-shift n -18) 63))
     (base64/char (bitwise-and (arithmetic-shift n -12) 63))
     "==")))

(define (base64-encode-bytes bytes)
  "Encode a list of byte integers (0-255) as a Base64 string."
  (let loop ((xs bytes) (acc '()))
    (cond
     ((null? xs)
      (apply string-append (reverse acc)))
     ((null? (cdr xs))
      (loop '() (cons (base64/encode-1 (car xs)) acc)))
     ((null? (cddr xs))
      (loop '() (cons (base64/encode-2 (car xs) (cadr xs)) acc)))
     (else
      (loop (cdddr xs)
            (cons (base64/encode-3 (car xs) (cadr xs) (caddr xs)) acc))))))
