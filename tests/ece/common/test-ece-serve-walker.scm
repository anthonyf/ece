;;; Unit tests for the transitive (load ...) walker in src/ece-serve.scm.
;;; Writes fixture files under .tmp/ece-serve-test/ and exercises the
;;; walker against them. Requires filesystem primitives (CL only).

(when (platform-has? 'open-output-file)

(define *walker-tmp-dir* ".tmp/ece-serve-test")

(define (walker-test/ensure-dir)
  (%make-directory *walker-tmp-dir*))

(define (walker-test/write path contents)
  "Write CONTENTS to PATH as text. Creates intermediate directories if
the path-join of *walker-tmp-dir* is a subdir."
  (walker-test/ensure-dir)
  (let ((out (open-output-file path)))
    (display contents out)
    (close-output-port out)))

(test "ece-serve/walk-loads: single file with no loads" (lambda ()
  (let ((p (path-join *walker-tmp-dir* "a.scm")))
    (walker-test/write p "(display 1)")
    (let ((result (ece-serve/walk-loads p)))
      (assert-equal result (list p))))))

(test "ece-serve/walk-loads: entry with one literal load" (lambda ()
  (let ((entry (path-join *walker-tmp-dir* "entry.scm"))
        (lib   (path-join *walker-tmp-dir* "lib.scm")))
    (walker-test/write lib "(define (foo) 1)")
    (walker-test/write entry "(load \"lib.scm\") (foo)")
    (let ((result (ece-serve/walk-loads entry)))
      (assert-equal (length result) 2)
      (assert-true (member entry result))
      (assert-true (member lib result))))))

(test "ece-serve/walk-loads: ignores dynamic (load expr) forms" (lambda ()
  (let ((entry (path-join *walker-tmp-dir* "dynamic.scm"))
        (lib   (path-join *walker-tmp-dir* "lib-dyn.scm")))
    (walker-test/write lib "1")
    (walker-test/write entry
      "(define p \"lib-dyn.scm\") (load p)")
    ;; Dynamic target (a variable reference, not a literal string) should
    ;; be skipped without failing. The walker returns just the entry.
    (let ((result (ece-serve/walk-loads entry)))
      (assert-equal result (list entry))))))

(test "ece-serve/walk-loads: transitive chain A → B → C" (lambda ()
  (let ((a (path-join *walker-tmp-dir* "a-chain.scm"))
        (b (path-join *walker-tmp-dir* "b-chain.scm"))
        (c (path-join *walker-tmp-dir* "c-chain.scm")))
    (walker-test/write c "(define z 3)")
    (walker-test/write b "(load \"c-chain.scm\") (define y 2)")
    (walker-test/write a "(load \"b-chain.scm\") (define x 1)")
    (let ((result (ece-serve/walk-loads a)))
      (assert-equal (length result) 3)
      (assert-true (member a result))
      (assert-true (member b result))
      (assert-true (member c result))))))

(test "ece-serve/walk-loads: cycle A → B → A does not loop forever" (lambda ()
  (let ((a (path-join *walker-tmp-dir* "cycle-a.scm"))
        (b (path-join *walker-tmp-dir* "cycle-b.scm")))
    (walker-test/write a "(load \"cycle-b.scm\")")
    (walker-test/write b "(load \"cycle-a.scm\")")
    (let ((result (ece-serve/walk-loads a)))
      (assert-equal (length result) 2)
      (assert-true (member a result))
      (assert-true (member b result))))))

(test "ece-serve/walk-loads: missing dependency is ignored" (lambda ()
  (let ((entry (path-join *walker-tmp-dir* "missing-dep.scm")))
    (walker-test/write entry "(load \"this-does-not-exist.scm\")")
    (let ((result (ece-serve/walk-loads entry)))
      ;; Entry is still reported even if its deps are missing.
      (assert-equal result (list entry))))))

(test "ece-serve/walk-loads: syntax error in a file does not crash walker" (lambda ()
  ;; Post-audit regression: a file with a parse error (unbalanced paren,
  ;; etc.) must not kill the walker — the user may be mid-edit. The
  ;; broken file should still appear in the result (it's on disk) but
  ;; its dependencies can't be parsed, so we just return what we have.
  (let ((entry (path-join *walker-tmp-dir* "syntax-error.scm")))
    (walker-test/write entry "(define x 1) (let (( ")  ; unbalanced
    (let ((result (ece-serve/walk-loads entry)))
      (assert-true (member entry result))))))

;; ── ece-serve/resolve-path dispatcher helper ──────────────────────────

(test "ece-serve/resolve-path: / maps to sandbox/index.html" (lambda ()
  (assert-equal (ece-serve/resolve-path "/") "sandbox/index.html")))

(test "ece-serve/resolve-path: /foo.js maps to sandbox/foo.js" (lambda ()
  (assert-equal (ece-serve/resolve-path "/foo.js") "sandbox/foo.js")))

(test "ece-serve/resolve-path: /programs/starfield.scm maps into programs/" (lambda ()
  (assert-equal (ece-serve/resolve-path "/programs/starfield.scm")
                "sandbox/programs/starfield.scm")))

(test "ece-serve/resolve-path: query string is stripped before resolving" (lambda ()
  (assert-equal (ece-serve/resolve-path "/foo.js?v=42") "sandbox/foo.js")))

(test "ece-serve/resolve-path: rejects path traversal attempts" (lambda ()
  (assert-false (ece-serve/resolve-path "/../etc/passwd"))
  (assert-false (ece-serve/resolve-path "/a/../../etc/passwd"))))

(test "ece-serve/resolve-path: rejects empty and non-absolute inputs" (lambda ()
  (assert-false (ece-serve/resolve-path ""))
  (assert-false (ece-serve/resolve-path "relative"))))

;; ── ece-serve/is-websocket-upgrade? detector ──────────────────────────

(test "ece-serve/is-websocket-upgrade?: accepts a RFC 6455 upgrade request" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws?token=test-token HTTP/1.1" crlf
               "Host: localhost" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" crlf
               "Sec-WebSocket-Version: 13" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-true (ece-serve/is-websocket-upgrade? req)))))

(test "ece-serve/is-websocket-upgrade?: accepts mixed-case Upgrade header" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws?token=test-token HTTP/1.1" crlf
               "Host: localhost" crlf
               "Upgrade: WebSocket" crlf  ; mixed case
               "Connection: keep-alive, Upgrade" crlf
               "Sec-WebSocket-Key: abc==" crlf
               "Sec-WebSocket-Version: 13" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-true (ece-serve/is-websocket-upgrade? req)))))

(test "ece-serve/is-websocket-upgrade?: rejects missing Sec-WebSocket-Key" (lambda ()
  ;; P0-1 regression: without a key, the handshake builder would crash
  ;; on (string-append #f magic-guid). is-websocket-upgrade? must return
  ;; #f so the caller falls through to serve-static → 404.
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws?token=test-token HTTP/1.1" crlf
               "Host: localhost" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Version: 13" crlf-crlf))  ; no key
         (req (http-parse-request raw)))
    (assert-false (ece-serve/is-websocket-upgrade? req)))))

(test "ece-serve/is-websocket-upgrade?: rejects wrong Sec-WebSocket-Version" (lambda ()
  ;; P1-1: RFC 6455 §4.1 requires version 13 exactly.
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws?token=test-token HTTP/1.1" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" crlf
               "Sec-WebSocket-Version: 12" crlf-crlf))  ; wrong version
         (req (http-parse-request raw)))
    (assert-false (ece-serve/is-websocket-upgrade? req)))))

(test "ece-serve/is-websocket-upgrade?: rejects missing Sec-WebSocket-Version" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws?token=test-token HTTP/1.1" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: abc==" crlf-crlf))  ; no version
         (req (http-parse-request raw)))
    (assert-false (ece-serve/is-websocket-upgrade? req)))))

(test "ece-serve/is-websocket-upgrade?: rejects empty Sec-WebSocket-Key" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws?token=test-token HTTP/1.1" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: " crlf
               "Sec-WebSocket-Version: 13" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-false (ece-serve/is-websocket-upgrade? req)))))

(test "ece-serve/is-websocket-upgrade?: rejects missing dev token" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws HTTP/1.1" crlf
               "Host: localhost" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" crlf
               "Sec-WebSocket-Version: 13" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-false (ece-serve/is-websocket-upgrade? req)))))

;; ── ece-serve/serve-static: binary content types return byte lists ────

(test "ece-serve/serve-static: .wasm returns a byte list (P0-2 regression)" (lambda ()
  ;; P0-2: previously serve-static routed all files through
  ;; read-file-as-string + http-build-response, corrupting binary
  ;; payloads like runtime.wasm. After the fix, binary content types
  ;; return a byte list that goes out unchanged on the wire.
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "GET /runtime.wasm HTTP/1.1" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/dispatch req)))
    (cond
     ;; If runtime.wasm isn't staged yet, dispatch returns a 404 string.
     ;; Otherwise it returns a byte list (not a string) with the wasm
     ;; magic bytes 0x00 'a' 's' 'm' inside the payload.
     ((string? resp)
      ;; Accept 404 as a valid outcome if the file hasn't been staged.
      (assert-true (string-contains? resp "HTTP/1.1 404")))
     (else
      (assert-true (pair? resp))
      ;; First bytes of a byte list start an HTTP status line.
      (assert-equal (car resp) 72)   ; 'H'
      (assert-equal (car (cdr resp)) 84) ; 'T'
      (assert-equal (car (cdr (cdr resp))) 84)  ; 'T'
      (assert-equal (car (cdr (cdr (cdr resp)))) 80)))))) ; 'P'

(test "ece-serve/read-file-as-bytes: round-trips non-ASCII bytes (binary-port regression)" (lambda ()
  ;; Pre-fix, read-file-as-bytes used open-input-file + read-char, which
  ;; is a TEXT port with UTF-8 decoding on SBCL. Bytes like 0xff or 0x80
  ;; aren't valid UTF-8 starters, so reading a .wasm file would either
  ;; error or emit corrupted code points. The fix switches to
  ;; open-binary-input-file + read-byte, which is lossless for any
  ;; byte in [0, 255]. This test proves it by writing a file with
  ;; explicitly non-ASCII bytes and checking round-trip equality.
  (walker-test/ensure-dir)
  (let ((path (path-join *walker-tmp-dir* "bin-probe.bin"))
        ;; WASM magic + a handful of high bytes + a null byte mid-stream.
        (expected (list 0 97 115 109 1 0 0 0 255 128 127 0 254)))
    (let ((out (open-binary-output-file path)))
      (for-each (lambda (b) (write-byte b out)) expected)
      (close-output-port out))
    (assert-equal (ece-serve/read-file-as-bytes path) expected))))

(test "ece-serve/read-file-as-bytes: reads wasm/runtime.wasm magic correctly" (lambda ()
  ;; End-to-end check against a real binary artefact the dev server
  ;; actually has to serve. Skips cleanly if the build hasn't produced
  ;; wasm/runtime.wasm yet (fresh clone, pre-`make wasm`).
  (cond
   ((not (%file-exists? "wasm/runtime.wasm"))
    (assert-true #t))  ; skip
   (else
    (let ((bytes (ece-serve/read-file-as-bytes "wasm/runtime.wasm")))
      ;; WASM magic: \x00 'a' 's' 'm' \x01 \x00 \x00 \x00
      (assert-equal (list-ref bytes 0) 0)
      (assert-equal (list-ref bytes 1) 97)   ; 'a'
      (assert-equal (list-ref bytes 2) 115)  ; 's'
      (assert-equal (list-ref bytes 3) 109)  ; 'm'
      (assert-equal (list-ref bytes 4) 1)
      (assert-equal (list-ref bytes 5) 0)
      (assert-equal (list-ref bytes 6) 0)
      (assert-equal (list-ref bytes 7) 0)
      (assert-true (> (length bytes) 100)))))))

(test "ece-serve/is-websocket-upgrade?: rejects plain GET" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "GET / HTTP/1.1" crlf "Host: x" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-false (ece-serve/is-websocket-upgrade? req)))))

;; ── ece-serve/content-type-for dispatch ───────────────────────────────

(test "ece-serve/content-type-for: html / js / css / wasm / default" (lambda ()
  (assert-equal (ece-serve/content-type-for "sandbox/index.html")
                "text/html; charset=utf-8")
  (assert-equal (ece-serve/content-type-for "sandbox/sandbox.js")
                "application/javascript; charset=utf-8")
  (assert-equal (ece-serve/content-type-for "sandbox/style.css")
                "text/css; charset=utf-8")
  (assert-equal (ece-serve/content-type-for "runtime.wasm")
                "application/wasm")
  (assert-equal (ece-serve/content-type-for "app-zones.wat")
                "text/plain; charset=utf-8")
  (assert-equal (ece-serve/content-type-for "app-zones.manifest")
                "text/plain; charset=utf-8")
  (assert-equal (ece-serve/content-type-for "whatever.bin")
                "application/octet-stream")))

;; ── ece-serve/dispatch end-to-end: static file routing ───────────────

(test "ece-serve/dispatch: GET / serves sandbox/index.html" (lambda ()
  ;; sandbox/index.html exists in the repository, so this test is
  ;; run against the real file rather than a fixture.
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "GET / HTTP/1.1" crlf "Host: localhost" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/dispatch req)))
    (assert-true (string? resp))
    (assert-true (starts-with? resp (string-append "HTTP/1.1 200 OK" crlf)))
    (assert-true (string-contains? resp "Content-Type: text/html"))
    ;; Post-audit: dev server must set no-store so manual reloads pick
    ;; up edits to sandbox/index.html instead of a browser cache.
    (assert-true (string-contains? resp "Cache-Control: no-store"))
    (assert-true (string-contains? resp "<!DOCTYPE html>"))
    (assert-true (string-contains? resp
                                   "window.ECE_DEV_WS_URL = \"ws://127.0.0.1:8080/ws?token=test-token\";")))))

(test "ece-serve/inject-dev-ws-url: injects current WebSocket URL" (lambda ()
  (let ((old *ece-serve/current-port*))
    (dynamic-wind
      (lambda () (set! *ece-serve/current-port* 8123))
      (lambda ()
        (let ((html (string-append "<script>"
                                   *ece-serve/dev-ws-placeholder*
                                   "</script>")))
          (assert-equal
           (ece-serve/inject-dev-ws-url html)
           "<script>window.ECE_DEV_WS_URL = \"ws://127.0.0.1:8123/ws?token=test-token\";</script>")))
      (lambda () (set! *ece-serve/current-port* old))))))

(test "ece-serve/dispatch: GET /nonexistent returns 404" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "GET /this-file-does-not-exist HTTP/1.1" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/dispatch req)))
    (assert-true (starts-with? resp (string-append "HTTP/1.1 404 Not Found" crlf))))))

(test "ece-serve/dispatch: POST returns 405" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "POST /api HTTP/1.1" crlf "Content-Length: 0" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/dispatch req)))
    (assert-true (starts-with? resp (string-append "HTTP/1.1 405 Method Not Allowed" crlf))))))

(test "ece-serve/dispatch: editor eval-source POST returns JSON OK" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (body "(define x 1)")
         (raw (string-append "POST /__ece_dev/eval-source HTTP/1.1" crlf
                             "Content-Length: " (number->string (string-length body)) crlf
                             "X-ECE-Dev-Token: test-token" crlf
                             "X-ECE-Path: scratch.scm" crlf-crlf
                             body))
         (req (http-parse-request raw))
         (clients (ece-serve/make-clients-box))
         (resp (ece-serve/dispatch req clients)))
    (assert-true (starts-with? resp (string-append "HTTP/1.1 200 OK" crlf)))
    (assert-true (string-contains? resp "Content-Type: application/json"))
    (assert-true (string-contains? resp "\"type\":\"eval-source\"")))))

(test "ece-serve/dispatch: editor eval-source POST rejects missing dev token" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (body "(define x 1)")
         (raw (string-append "POST /__ece_dev/eval-source HTTP/1.1" crlf
                             "Content-Length: " (number->string (string-length body)) crlf-crlf
                             body))
         (req (http-parse-request raw))
         (clients (ece-serve/make-clients-box))
         (resp (ece-serve/dispatch req clients)))
    (assert-true (starts-with? resp (string-append "HTTP/1.1 403 Forbidden" crlf)))
    (assert-true (string-contains? resp "invalid dev token")))))

(test "ece-serve/dispatch: /foo?query=bar strips query before resolving" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "GET /index.html?v=42 HTTP/1.1" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/dispatch req)))
    (assert-true (starts-with? resp (string-append "HTTP/1.1 200 OK" crlf))))))

(test "ece-serve/dispatch: path traversal attempt returns 400" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "GET /../etc/passwd HTTP/1.1" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/dispatch req)))
    (assert-true (starts-with? resp (string-append "HTTP/1.1 400 Bad Request" crlf))))))

(test "ece-serve/dispatch: WebSocket upgrade returns the symbol 'upgrade" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws?token=test-token HTTP/1.1" crlf
               "Host: localhost" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" crlf
               "Sec-WebSocket-Version: 13" crlf-crlf))
         (req (http-parse-request raw)))
    (assert-equal (ece-serve/dispatch req) 'upgrade))))

;; ── ece-serve/dispatch: directory path returns 404 (C6 Copilot regression) ───

(test "ece-serve/dispatch: GET /programs (directory) returns 404 not crash" (lambda ()
  ;; Pre-fix: %file-exists? returns #t for directories on CL; serve-static
  ;; then called open-*-input-file on the directory which raised a host
  ;; error, got swallowed by the connection handler's outer guard, and
  ;; closed the socket without an HTTP reply. Post-fix: serve-static has
  ;; a guard around the read+build path that returns 404 on any I/O error
  ;; so the client always gets a valid HTTP reply.
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append "GET /programs HTTP/1.1" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/dispatch req)))
    (assert-true (string? resp))
    (assert-true (starts-with? resp
                               (string-append "HTTP/1.1 404 Not Found" crlf))))))

;; ── ece-serve/parse-options validation (C2 Copilot regression) ───────

(test "ece-serve/parse-options: accepts valid :port + :poll-interval" (lambda ()
  (let ((result (ece-serve/parse-options (list ':port 9090 ':poll-interval 500))))
    (assert-equal (car result) 9090)
    (assert-equal (car (cdr result)) 500))))

(test "ece-serve/parse-options: accepts valid :dev-token" (lambda ()
  (let ((result (ece-serve/parse-options (list ':dev-token "abc123"))))
    (assert-equal (car (cdr (cdr result))) "abc123"))))

(test "ece-serve/parse-options: defaults when no options given" (lambda ()
  (let ((result (ece-serve/parse-options '())))
    (assert-equal (car result) 8080)
    (assert-equal (car (cdr result)) 250))))

(test "ece-serve/parse-options: rejects :port 0 and :port 65536" (lambda ()
  (let ((too-low  (guard (e (#t 'error)) (ece-serve/parse-options (list ':port 0))))
        (too-high (guard (e (#t 'error)) (ece-serve/parse-options (list ':port 65536)))))
    (assert-equal too-low 'error)
    (assert-equal too-high 'error))))

(test "ece-serve/parse-options: rejects non-integer :port" (lambda ()
  (let ((result (guard (e (#t 'error))
                       (ece-serve/parse-options (list ':port "not-a-number")))))
    (assert-equal result 'error))))

(test "ece-serve/parse-options: rejects negative :poll-interval" (lambda ()
  (let ((result (guard (e (#t 'error))
                       (ece-serve/parse-options (list ':poll-interval -1)))))
    (assert-equal result 'error))))

(test "ece-serve/parse-options: rejects unknown option" (lambda ()
  (let ((result (guard (e (#t 'error))
                       (ece-serve/parse-options (list ':bogus 42)))))
    (assert-equal result 'error))))

(test "ece-serve/parse-options: rejects dangling key with no value" (lambda ()
  (let ((result (guard (e (#t 'error))
                       (ece-serve/parse-options (list ':port)))))
    (assert-equal result 'error))))

;; ── ece-serve/build-ws-upgrade-response — full 101 envelope ──────────

(test "ece-serve/build-ws-upgrade-response uses RFC 6455 §1.3 accept-key" (lambda ()
  (let* ((crlf (string-append (string (integer->char 13)) (string #\newline)))
         (crlf-crlf (string-append crlf crlf))
         (raw (string-append
               "GET /ws HTTP/1.1" crlf
               "Host: localhost" crlf
               "Upgrade: websocket" crlf
               "Connection: Upgrade" crlf
               "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" crlf-crlf))
         (req (http-parse-request raw))
         (resp (ece-serve/build-ws-upgrade-response req)))
    (assert-true (starts-with? resp
                               (string-append "HTTP/1.1 101 Switching Protocols" crlf)))
    (assert-true (string-contains? resp "Upgrade: websocket"))
    (assert-true (string-contains? resp "Connection: Upgrade"))
    ;; The canonical RFC 6455 §1.3 example.
    (assert-true (string-contains? resp
                  "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")))))

;; End of when-guarded block
)
