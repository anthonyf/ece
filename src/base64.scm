;;; base64.scm — Base64 encoding in pure ECE (RFC 4648)
;;;
;;; Single source of truth for Base64 encoding in the codebase.
;;; Used by:
;;;   - ece-build.scm's standalone web-app packager (inlines assets as
;;;     base64 data for file:// loads via `file->base64`)
;;;   - ece-serve.scm (pending) for the WebSocket handshake
;;;     `Sec-WebSocket-Accept = base64(sha1(key || magic))` per RFC 6455.
;;;
;;; Public API:
;;;   (bytes->base64 byte-list)  → string
;;;   (file->base64  path)       → string
;;;
;;; Both use an output-string port for linear-time accumulation (avoids
;;; the quadratic string-append cost that a list-join-at-the-end approach
;;; would have). `file->base64` streams directly from the binary port so
;;; large files don't build an intermediate byte list.
;;;
;;; Not implemented in this change: decoding, MIME-style line wrapping,
;;; URL-safe variant. Add them when a concrete use case materializes.

(define *b64-alphabet*
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

(define (b64-char i)
  (string-ref *b64-alphabet* i))

(define (bytes->base64 bytes)
  "Encode a list of bytes as a base64 string (no line wrapping).
Uses an output-string port for linear-time accumulation."
  (let ((sp (open-output-string)))
    (let loop ((rest bytes))
      (cond
       ((null? rest) (get-output-string sp))
       ((null? (cdr rest))
        ;; 1 byte remaining: encode as 2 chars + "=="
        (let* ((b0 (car rest))
               (v (arithmetic-shift b0 16)))
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -18) 63)) sp)
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -12) 63)) sp)
          (%write-char-to-port #\= sp)
          (%write-char-to-port #\= sp)
          (get-output-string sp)))
       ((null? (cddr rest))
        ;; 2 bytes remaining: encode as 3 chars + "="
        (let* ((b0 (car rest))
               (b1 (cadr rest))
               (v (bitwise-or (arithmetic-shift b0 16) (arithmetic-shift b1 8))))
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -18) 63)) sp)
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -12) 63)) sp)
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -6) 63)) sp)
          (%write-char-to-port #\= sp)
          (get-output-string sp)))
       (else
        ;; 3 bytes: encode as 4 chars
        (let* ((b0 (car rest))
               (b1 (cadr rest))
               (b2 (caddr rest))
               (v (bitwise-or (arithmetic-shift b0 16)
                              (bitwise-or (arithmetic-shift b1 8) b2))))
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -18) 63)) sp)
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -12) 63)) sp)
          (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -6) 63)) sp)
          (%write-char-to-port (b64-char (bitwise-and v 63)) sp)
          (loop (cdddr rest))))))))

(define (file->base64 path)
  "Read PATH (binary) and return its contents as a base64 string.
Streams through the file without building an intermediate byte list."
  (let ((in (open-binary-input-file path))
        (sp (open-output-string)))
    (let loop ()
      (let ((b0 (read-byte in)))
        (cond
         ((eof? b0)
          (close-input-port in)
          (get-output-string sp))
         (else
          (let ((b1 (read-byte in)))
            (cond
             ((eof? b1)
              ;; 1 byte remaining: 2 chars + "=="
              (let ((v (arithmetic-shift b0 16)))
                (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -18) 63)) sp)
                (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -12) 63)) sp)
                (%write-char-to-port #\= sp)
                (%write-char-to-port #\= sp)
                (close-input-port in)
                (get-output-string sp)))
             (else
              (let ((b2 (read-byte in)))
                (cond
                 ((eof? b2)
                  ;; 2 bytes remaining: 3 chars + "="
                  (let ((v (bitwise-or (arithmetic-shift b0 16) (arithmetic-shift b1 8))))
                    (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -18) 63)) sp)
                    (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -12) 63)) sp)
                    (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -6) 63)) sp)
                    (%write-char-to-port #\= sp)
                    (close-input-port in)
                    (get-output-string sp)))
                 (else
                  ;; 3 bytes: 4 chars
                  (let ((v (bitwise-or (arithmetic-shift b0 16)
                                       (bitwise-or (arithmetic-shift b1 8) b2))))
                    (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -18) 63)) sp)
                    (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -12) 63)) sp)
                    (%write-char-to-port (b64-char (bitwise-and (arithmetic-shift v -6) 63)) sp)
                    (%write-char-to-port (b64-char (bitwise-and v 63)) sp)
                    (loop))))))))))))))
