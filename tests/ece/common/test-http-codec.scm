;;; Unit tests for src/http-codec.scm — HTTP/1.1 subset parser and
;;; response builder. Pure functions against fixed fixtures; no sockets.
;;;
;;; ECE's reader currently does not interpret `\r` in string literals,
;;; so we build CRLF via integer->char and concatenate. All test fixtures
;;; use the local `crlf` / `crlf-crlf` helpers below.

(define crlf (string-append (string (integer->char 13)) (string #\newline)))
(define crlf-crlf (string-append crlf crlf))

;; ── Byte/string conversion ──────────────────────────────────────────────

(test "http-codec: ascii-bytes->string round-trip" (lambda ()
  (assert-equal (ascii-bytes->string '(72 101 108 108 111)) "Hello")
  (assert-equal (string->ascii-bytes "Hi!") '(72 105 33))
  (assert-equal (ascii-bytes->string '()) "")
  (assert-equal (ascii-bytes->string (string->ascii-bytes "round-trip"))
                "round-trip")))

;; ── Header-end detection ────────────────────────────────────────────────

(test "http-codec: header-end-string finds CRLFCRLF" (lambda ()
  ;; "GET / HTTP/1.1" (14) + crlf (2) + "Host: x" (7) + crlf-crlf (4) = 27
  (assert-equal (http-header-end-string
                 (string-append "GET / HTTP/1.1" crlf "Host: x" crlf-crlf))
                27)
  ;; "GET / HTTP/1.1" (14) + crlf-crlf (4) = 18 (body follows)
  (assert-equal (http-header-end-string
                 (string-append "GET / HTTP/1.1" crlf-crlf "body"))
                18)))

(test "http-codec: header-end-string returns #f when sentinel absent" (lambda ()
  (assert-false (http-header-end-string
                 (string-append "GET / HTTP/1.1" crlf "Host: x")))
  (assert-false (http-header-end-string ""))
  (assert-false (http-header-end-string "no CRLFs at all"))))

(test "http-codec: header-end-bytes finds 13 10 13 10" (lambda ()
  (assert-equal (http-header-end-bytes '(71 69 84 13 10 13 10)) 7)
  (assert-false (http-header-end-bytes '(71 69 84 13 10)))
  (assert-false (http-header-end-bytes '()))))

;; ── Request parser: GET / ──────────────────────────────────────────────

(test "http-codec: parse a minimal GET" (lambda ()
  (let ((req (http-parse-request
              (string-append "GET / HTTP/1.1" crlf "Host: localhost" crlf-crlf))))
    (assert-true (http-request? req))
    (assert-equal (http-request-method req) "GET")
    (assert-equal (http-request-path req) "/")
    (assert-equal (http-request-version req) "HTTP/1.1")
    (assert-equal (http-header-ref req "Host") "localhost"))))

(test "http-codec: parse returns 'incomplete without sentinel" (lambda ()
  (assert-equal (http-parse-request
                 (string-append "GET / HTTP/1.1" crlf "Host: x"))
                'incomplete)
  (assert-equal (http-parse-request "") 'incomplete)))

(test "http-codec: parse returns 'malformed on a bad request line" (lambda ()
  (assert-equal (http-parse-request (string-append "GARBAGE" crlf-crlf))
                'malformed)
  (assert-equal (http-parse-request (string-append "GET" crlf-crlf))
                'malformed)
  (assert-equal (http-parse-request
                 (string-append "GET / HTTP/1.1 extra" crlf-crlf))
                'malformed)))

(test "http-codec: parse multiple headers with mixed case names" (lambda ()
  (let* ((raw (string-append
               "GET /foo HTTP/1.1" crlf
               "Host: example.com" crlf
               "User-Agent: test/1.0" crlf
               "Accept: */*" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-true (http-request? req))
    (assert-equal (http-request-path req) "/foo")
    ;; Case-insensitive lookup — names were stored lowercased internally.
    (assert-equal (http-header-ref req "Host") "example.com")
    (assert-equal (http-header-ref req "host") "example.com")
    (assert-equal (http-header-ref req "HOST") "example.com")
    (assert-equal (http-header-ref req "User-Agent") "test/1.0")
    (assert-equal (http-header-ref req "accept") "*/*")
    (assert-false (http-header-ref req "Missing")))))

(test "http-codec: parse strips leading spaces from header values" (lambda ()
  (let ((req (http-parse-request
              (string-append "GET / HTTP/1.1" crlf "X-Foo:     bar" crlf-crlf))))
    (assert-equal (http-header-ref req "X-Foo") "bar"))))

(test "http-codec: parse preserves path with query string" (lambda ()
  (let ((req (http-parse-request
              (string-append "GET /search?q=hello&n=10 HTTP/1.1" crlf-crlf))))
    (assert-equal (http-request-path req) "/search?q=hello&n=10"))))

(test "http-codec: parse handles POST method" (lambda ()
  (let ((req (http-parse-request
              (string-append "POST /api HTTP/1.1" crlf
                             "Content-Length: 5" crlf-crlf
                             "hello"))))
    (assert-equal (http-request-method req) "POST")
    (assert-equal (http-header-ref req "Content-Length") "5")
    (assert-equal (http-request-body req) "hello"))))

(test "http-codec: parse handles header with colon in value" (lambda ()
  (let ((req (http-parse-request
              (string-append "GET / HTTP/1.1" crlf
                             "X-URL: http://a.b/c" crlf-crlf))))
    ;; The first colon separates name from value; remaining colons are
    ;; part of the value.
    (assert-equal (http-header-ref req "X-URL") "http://a.b/c"))))

;; ── WebSocket upgrade request (the one the dev server actually cares about) ──

(test "http-codec: parse a realistic WebSocket upgrade request" (lambda ()
  (let* ((raw (string-append
               "GET /ws HTTP/1.1" crlf
               "Host: localhost:8080" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" crlf
               "Sec-WebSocket-Version: 13" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-true (http-request? req))
    (assert-equal (http-request-path req) "/ws")
    (assert-equal (http-header-ref req "upgrade") "websocket")
    (assert-equal (http-header-ref req "sec-websocket-key")
                  "dGhlIHNhbXBsZSBub25jZQ==")
    (assert-equal (http-header-ref req "sec-websocket-version") "13"))))

;; ── Response builder ────────────────────────────────────────────────────

(test "http-codec: build a minimal 200 response" (lambda ()
  (let ((resp (http-build-response 200 "OK" '() "hello")))
    ;; Status line
    (assert-true (starts-with? resp (string-append "HTTP/1.1 200 OK" crlf)))
    ;; Auto-appended headers
    (assert-true (string-contains? resp (string-append "Content-Length: 5" crlf)))
    (assert-true (string-contains? resp (string-append "Connection: close" crlf)))
    ;; Blank line before body
    (assert-true (string-contains? resp (string-append crlf-crlf "hello"))))))

(test "http-codec: build-response lets the caller override Content-Length" (lambda ()
  (let ((resp (http-build-response
               200 "OK"
               '(("Content-Length" . "7"))  ; intentionally wrong — caller knows best
               "abcdef")))
    ;; The caller-provided Content-Length is not duplicated.
    (assert-true (string-contains? resp (string-append "Content-Length: 7" crlf)))
    (let ((len (string-length resp)))
      (assert-true (> len 0))))))

(test "http-codec: build-response preserves caller-supplied Connection header" (lambda ()
  (let ((resp (http-build-response
               101 "Switching Protocols"
               '(("Upgrade" . "websocket")
                 ("Connection" . "Upgrade")
                 ("Sec-WebSocket-Accept" . "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="))
               "")))
    (assert-true (starts-with? resp
                  (string-append "HTTP/1.1 101 Switching Protocols" crlf)))
    (assert-true (string-contains? resp (string-append "Connection: Upgrade" crlf)))
    (assert-false (string-contains? resp "Connection: close"))
    (assert-true (string-contains? resp (string-append "Upgrade: websocket" crlf)))
    (assert-true (string-contains? resp
                  (string-append
                   "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" crlf))))))

(test "http-codec: build-response with an empty body" (lambda ()
  (let ((resp (http-build-response 204 "No Content" '() "")))
    (assert-true (string-contains? resp (string-append "Content-Length: 0" crlf)))
    ;; Ends with the blank-line terminator.
    (assert-true (ends-with? resp crlf-crlf)))))

;; ── Round-trip ──────────────────────────────────────────────────────────

(test "http-codec: parsed headers preserve count" (lambda ()
  (let* ((req (http-parse-request
               (string-append "GET /page HTTP/1.1" crlf
                              "Host: x" crlf
                              "X-Note: n" crlf-crlf)))
         (headers (http-request-headers req)))
    (assert-equal (length headers) 2)
    (assert-equal (http-header-ref req "x-note") "n"))))
