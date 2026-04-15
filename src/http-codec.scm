;;; http-codec.scm — HTTP/1.1 subset for the ece-serve dev server.
;;;
;;; Pure request parser + response builder. No sockets, no fibers, no
;;; streaming — the caller is responsible for accumulating bytes from
;;; tcp-recv-nowait until a full header block has arrived, then calling
;;; http-parse-request on the accumulated string.
;;;
;;; Scope intentionally narrow: the dev server only needs GET for static
;;; assets and the Upgrade: websocket dance. No chunked transfer encoding,
;;; no keep-alive, no content negotiation, no URL percent-decoding, no
;;; multipart bodies. If we ever need those, add them; until then, KISS.
;;;
;;; ─────────────────────────────────────────────────────────────────────
;;; API
;;; ─────────────────────────────────────────────────────────────────────
;;;
;;;  (ascii-bytes->string bytes)    — convert byte list [0,255] → string
;;;  (string->ascii-bytes s)        — convert string → byte list
;;;
;;;  (http-header-end-bytes bytes)  — find \r\n\r\n in a byte list,
;;;                                   return offset PAST the sentinel or #f
;;;  (http-header-end-string s)     — string version of the above
;;;
;;;  (http-parse-request s)         — parse a request string; returns
;;;                                   an http-request record, or 'incomplete
;;;                                   if the header block isn't terminated,
;;;                                   or 'malformed on parse failure
;;;
;;;  (http-request? v)              — predicate
;;;  (http-request-method req)      — "GET" / "POST" / ...
;;;  (http-request-path req)        — "/foo" / "/"
;;;  (http-request-version req)     — "HTTP/1.1"
;;;  (http-request-headers req)     — alist ((lowercased-name . value) ...)
;;;  (http-header-ref req name)     — case-insensitive lookup, #f if absent
;;;
;;;  (http-build-response status reason headers body)
;;;                                 — construct a response string.
;;;                                   status: integer (e.g. 200, 404)
;;;                                   reason: string (e.g. "OK")
;;;                                   headers: alist ((name . value) ...)
;;;                                   body: string (may be "")
;;;                                   returns a full HTTP response as a string.
;;;                                   Automatically sets Content-Length from
;;;                                   the body length and Connection: close.

;; ---- CRLF constants ----
;;
;; ECE's reader (src/reader.scm) currently handles `\n`, `\t`, `\\`, `\"`
;; in string literals but silently drops the backslash in `\r`, so a
;; literal "\r\n" produces the two-char sequence "r\n" — NOT CR+LF.
;; Until a future reader-update change adds `\r` support, build CR and
;; CRLF via `integer->char` so the wire format is correct.

(define %cr (integer->char 13))
(define %crlf (string-append (string %cr) (string #\newline)))
(define %crlf-crlf (string-append %crlf %crlf))

;; ---- Record ----

(define-record http-request method path version headers)

;; ---- Byte/string conversion helpers at the TCP boundary ----

(define (ascii-bytes->string bytes)
  "Convert a list of byte integers in [0, 255] to a string. HTTP headers
are ASCII so this is lossless; bytes outside that range still round-trip
as-is because ECE strings are code-point indexed."
  (let ((p (open-output-string)))
    (let loop ((rest bytes))
      (cond
       ((null? rest) (get-output-string p))
       (else
        (write-char (integer->char (car rest)) p)
        (loop (cdr rest)))))))

(define (string->ascii-bytes s)
  "Convert a string to a list of byte integers. Inverse of
ascii-bytes->string for ASCII inputs."
  (let ((len (string-length s)))
    (let loop ((i 0) (acc '()))
      (cond
       ((>= i len) (reverse acc))
       (else
        (loop (+ i 1) (cons (char->integer (string-ref s i)) acc)))))))

;; ---- Header block terminator detection ----
;;
;; The callers of http-parse-request accumulate bytes from tcp-recv-nowait
;; until \r\n\r\n is seen. These helpers locate that sentinel and return
;; the offset PAST it, so the caller knows where the body begins. Bytes
;; version is useful when the caller hasn't decoded to a string yet.

(define (http-header-end-bytes bytes)
  "Scan BYTES (a list of integers in [0,255]) for the 4-byte sequence
13 10 13 10 (\\r\\n\\r\\n). Return the byte offset past the terminator, or
#f if not present."
  (let loop ((rest bytes) (idx 0))
    (cond
     ((null? rest) #f)
     ((or (null? (cdr rest))
          (null? (cddr rest))
          (null? (cdddr rest))) #f)
     ((and (= (car rest) 13)
           (= (cadr rest) 10)
           (= (car (cddr rest)) 13)
           (= (cadr (cddr rest)) 10))
      (+ idx 4))
     (else (loop (cdr rest) (+ idx 1))))))

(define (http-header-end-string s)
  "String version of http-header-end-bytes. Returns the character offset
past the \\r\\n\\r\\n sentinel, or #f if not present."
  (let ((len (string-length s)))
    (let loop ((i 0))
      (cond
       ((> (+ i 4) len) #f)
       ((and (char=? (string-ref s i) %cr)
             (char=? (string-ref s (+ i 1)) #\newline)
             (char=? (string-ref s (+ i 2)) %cr)
             (char=? (string-ref s (+ i 3)) #\newline))
        (+ i 4))
       (else (loop (+ i 1)))))))

;; ---- Internal parse helpers ----

(define (%http-split-crlf s)
  "Split S on CRLF sequences. Returns a list of strings without any
CRLF bytes. Empty trailing strings are preserved; the caller strips
them if needed."
  (string-split s %crlf))

(define (%http-parse-request-line line)
  "Parse a request line like \"GET /index.html HTTP/1.1\". Returns a
3-element list (method path version) or the symbol 'malformed."
  (let ((parts (string-split line " ")))
    (cond
     ((or (null? parts) (null? (cdr parts)) (null? (cdr (cdr parts))))
      'malformed)
     ((not (null? (cdr (cdr (cdr parts))))) 'malformed)
     (else parts))))

(define (%http-find-colon s)
  "Return the index of the first #\\: in S, or -1 if not present."
  (let ((len (string-length s)))
    (let loop ((i 0))
      (cond
       ((>= i len) -1)
       ((char=? (string-ref s i) #\:) i)
       (else (loop (+ i 1)))))))

(define (%http-strip-leading-space s)
  "Drop leading spaces from S (HTTP header value convention)."
  (let ((len (string-length s)))
    (let loop ((i 0))
      (cond
       ((>= i len) "")
       ((char=? (string-ref s i) #\space) (loop (+ i 1)))
       (else (substring s i len))))))

(define (%http-parse-header-line line)
  "Parse a header line \"Name: value\". Returns a (lowercased-name . value)
pair or the symbol 'malformed."
  (let ((i (%http-find-colon line)))
    (cond
     ((< i 0) 'malformed)
     ((= i 0) 'malformed)
     (else
      (let ((name (string-downcase (substring line 0 i)))
            (value (%http-strip-leading-space
                    (substring line (+ i 1) (string-length line)))))
        (cons name value))))))

(define (%http-parse-header-lines lines)
  "Parse a list of header lines into an alist. Returns 'malformed if
any line is unparseable."
  (let loop ((rest lines) (acc '()))
    (cond
     ((null? rest) (reverse acc))
     ((string=? (car rest) "") (loop (cdr rest) acc)) ; tolerate blank
     (else
      (let ((parsed (%http-parse-header-line (car rest))))
        (cond
         ((eq? parsed 'malformed) 'malformed)
         (else (loop (cdr rest) (cons parsed acc)))))))))

;; ---- Request parser ----

(define (%http-build-request req-line headers)
  "Construct an http-request from a parsed request-line list and parsed
header alist. Factored out of http-parse-request so the nesting level
stays readable."
  (make-http-request
   (car req-line)
   (car (cdr req-line))
   (car (cdr (cdr req-line)))
   headers))

(define (http-parse-request s)
  "Parse a complete HTTP/1.1 request header block from string S.
Returns an http-request record on success; the symbol 'incomplete if
S does not yet contain a \\r\\n\\r\\n terminator; or 'malformed if the
request line or headers are not parseable."
  (let ((end (http-header-end-string s)))
    (if (not end)
        'incomplete
        ;; Drop the final \r\n\r\n so split doesn't produce trailing blanks.
        (let* ((header-block (substring s 0 (- end 4)))
               (lines (%http-split-crlf header-block)))
          (if (null? lines)
              'malformed
              (let ((req-line (%http-parse-request-line (car lines))))
                (if (eq? req-line 'malformed)
                    'malformed
                    (let ((headers (%http-parse-header-lines (cdr lines))))
                      (if (eq? headers 'malformed)
                          'malformed
                          (%http-build-request req-line headers))))))))))

;; ---- Case-insensitive header lookup ----

(define (http-header-ref req name)
  "Return the header value for NAME in REQ (case-insensitive), or #f
if the header is absent. NAME may be any case — the parser stores
lower-cased names internally."
  (let ((key (string-downcase name)))
    (let loop ((rest (http-request-headers req)))
      (cond
       ((null? rest) #f)
       ((string=? (car (car rest)) key) (cdr (car rest)))
       (else (loop (cdr rest)))))))

;; ---- Response builder ----
;;
;; Stage 1 always emits HTTP/1.1 with Connection: close. Content-Length
;; is computed from the body string length. Callers supply additional
;; headers (Content-Type, Sec-WebSocket-Accept, etc.) via the alist arg;
;; we append our bookkeeping headers if they aren't already present.

(define (%http-format-headers headers)
  "Render an alist of headers as a CRLF-terminated block. Each line
is \"Name: value\" followed by CRLF. Accumulates into an output-string
port so the total cost is linear in the header block size rather than
the quadratic cost of repeated string-append on a growing accumulator."
  (let ((out (open-output-string)))
    (let loop ((rest headers))
      (cond
       ((null? rest) (get-output-string out))
       (else
        (display (car (car rest)) out)
        (display ": " out)
        (display (cdr (car rest)) out)
        (display %crlf out)
        (loop (cdr rest)))))))

(define (%http-alist-has? headers name-lower)
  "True if HEADERS contains a (case-insensitive) entry for NAME-LOWER."
  (let loop ((rest headers))
    (cond
     ((null? rest) #f)
     ((string=? (string-downcase (car (car rest))) name-lower) #t)
     (else (loop (cdr rest))))))

(define (http-build-response status reason headers body)
  "Build a full HTTP/1.1 response string. STATUS is an integer, REASON
is a string (\"OK\", \"Not Found\", ...), HEADERS is an alist of
(name . value) pairs (case preserved on output), and BODY is a string
that becomes the message body.

Automatically appends Content-Length (computed from BODY) and
Connection: close if the caller hasn't already provided them."
  (let* ((with-length
          (if (%http-alist-has? headers "content-length")
              headers
              (append headers
                      (list (cons "Content-Length"
                                  (number->string (string-length body)))))))
         (with-conn
          (if (%http-alist-has? with-length "connection")
              with-length
              (append with-length (list (cons "Connection" "close"))))))
    (string-append
     "HTTP/1.1 " (number->string status) " " reason %crlf
     (%http-format-headers with-conn)
     %crlf
     body)))
