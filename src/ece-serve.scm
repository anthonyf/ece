;;; ece-serve.scm — Dev server for live-coding ECE programs from an external editor.
;;;
;;; `ece serve path/to/game.scm` brings up an HTTP + WebSocket server
;;; that (a) serves the sandbox static assets so the browser can load
;;; them, and (b) watches the program's `(load ...)` closure for
;;; modifications, rebuilds dev `.ecec` and native-zone artifacts, and
;;; pushes program-reload messages to connected WebSocket clients. The
;;; browser-side JavaScript remains a thin capability bridge; reload
;;; policy lives in wasm-host.scm.
;;;
;;; Architecture — four fiber roles cooperating through a single
;;; `src/scheduler.scm` instance:
;;;
;;;   * Accept fiber:            tcp-accept-nowait on the listen socket;
;;;                              spawns a per-connection handler for each
;;;                              new client.
;;;   * Per-connection handler:  accumulates bytes until the HTTP header
;;;                              block is complete, parses the request
;;;                              via src/http-codec.scm, dispatches by
;;;                              method/path. For static assets writes
;;;                              the response and closes. For a WebSocket
;;;                              upgrade, performs the RFC 6455 handshake
;;;                              and transitions to the WebSocket loop.
;;;   * WebSocket fiber:         handles incoming frames (close/ping/pong)
;;;                              and registers itself in a shared client
;;;                              list so the file-watch fiber can
;;;                              broadcast to it.
;;;   * File-watch fiber:        fs-watch-start on the program's (load)
;;;                              closure, poll periodically, rebuild a
;;;                              dev archive/native-zone artifacts, and
;;;                              broadcast a program-reload JSON message
;;;                              over every connected WebSocket client on
;;;                              each modification.
;;;
;;; The scheduler uses polling event sources (not true edge-triggered
;;; I/O) — each run of `scheduler-run!` polls tcp accept readiness and
;;; fs-watch changes. Fibers block on wait-for tags corresponding to
;;; their connection + operation.
;;;
;;; Dependencies: src/scheduler.scm, src/http-codec.scm,
;;; src/websocket-codec.scm, src/json.scm, src/sdk-lib.scm (path
;;; helpers), and the CL-only primitives from
;;; ece-serve-tcp-fs-primitives: tcp-listen, tcp-accept-nowait,
;;; tcp-recv-nowait, tcp-send-nowait, tcp-close, fs-watch-start,
;;; fs-watch-poll, fs-watch-stop, plus current-milliseconds for the
;;; timer-driven poll.

;; ---- File I/O helpers (local; not lifted to sdk-lib to keep this
;;      PR self-contained — a future cleanup can consolidate the
;;      read-file-as-string definitions in ece-build.scm and here.) ----

(define (ece-serve/read-file-as-string path)
  "Read PATH as a string. Uses an output-string port to accumulate in
linear time rather than quadratic string-append. Uses dynamic-wind to
guarantee the input port is closed even if read-char raises."
  (let ((in (open-input-file path))
        (out (open-output-string)))
    (dynamic-wind
        (lambda () #f)
        (lambda ()
          (let loop ()
            (let ((ch (read-char in)))
              (cond
               ((eof? ch) (get-output-string out))
               (else (write-char ch out) (loop))))))
        (lambda () (close-input-port in)))))

(define (ece-serve/read-file-as-bytes path)
  "Read PATH as a list of byte integers. Uses a binary input port so
the stream is not subject to character-set decoding — required for
.wasm / .png / opaque-blob payloads whose byte sequences are not
valid UTF-8 and would otherwise be corrupted (or outright rejected)
by a text-decoded read-char loop. Uses dynamic-wind to guarantee the
port is closed even if read-byte raises mid-stream."
  (let ((in (open-binary-input-file path)))
    (dynamic-wind
        (lambda () #f)
        (lambda ()
          (let loop ((acc '()))
            (let ((b (read-byte in)))
              (cond
               ((eof? b) (reverse acc))
               (else (loop (cons b acc)))))))
        (lambda () (close-input-port in)))))

(define (ece-serve/write-string-to-file text path)
  "Write TEXT to PATH, replacing any existing file."
  (let ((out (open-output-file path)))
    (dynamic-wind
        (lambda () #f)
        (lambda () (display text out))
        (lambda () (close-output-port out)))))

(define (ece-serve/write-sexp-to-file value path)
  "Write VALUE as a readable S-expression to PATH."
  (let ((out (open-output-file path)))
    (dynamic-wind
        (lambda () #f)
        (lambda ()
          (write value out)
          (newline out))
        (lambda () (close-output-port out)))))

;; ---- MIME type guessing from filename extension ----
;;
;; Minimal table for the dev server's static assets. Unknown
;; extensions fall back to application/octet-stream — browsers handle
;; that safely (they just won't auto-render).

(define (ece-serve/content-type-for path)
  "Return the Content-Type string for PATH based on its extension."
  (cond
   ((has-extension? path "html") "text/html; charset=utf-8")
   ((has-extension? path "js")   "application/javascript; charset=utf-8")
   ((has-extension? path "css")  "text/css; charset=utf-8")
   ((has-extension? path "json") "application/json; charset=utf-8")
   ((has-extension? path "wasm") "application/wasm")
   ((has-extension? path "wat")  "text/plain; charset=utf-8")
   ((has-extension? path "manifest") "text/plain; charset=utf-8")
   ((has-extension? path "ecec") "text/plain; charset=utf-8")
   ((has-extension? path "scm")  "text/plain; charset=utf-8")
   ((has-extension? path "ico")  "image/x-icon")
   ((has-extension? path "png")  "image/png")
   ((has-extension? path "svg")  "image/svg+xml")
   (else "application/octet-stream")))

(define (ece-serve/is-binary-content-type? ct)
  "Test whether CT is a content type whose bytes must not go through
a text-oriented (string) response path. Used by serve-static to pick
between http-build-response (string body) and build-binary-response
(byte-list body)."
  (or (string=? ct "application/wasm")
      (string=? ct "image/x-icon")
      (string=? ct "image/png")
      (string=? ct "application/octet-stream")))

;; ---- Static-file routing ----
;;
;; Path resolution rules:
;;   - "/" → sandbox/index.html
;;   - "/foo.js" → sandbox/foo.js
;;   - "/programs/starfield.scm" → sandbox/programs/starfield.scm
;;   - any path containing ".." is rejected with 400 (path traversal)
;;
;; Missing files return 404. Bad request returns 400. Static assets are
;; served with GET. Editor commands are accepted as localhost POSTs under
;; /__ece_dev/* only when they include this server's dev token; accepted
;; commands are relayed to connected browser WebSocket clients.

(define *ece-serve/sandbox-root* "sandbox")
(define *ece-serve/current-port* 8080)
(define *ece-serve/dev-ws-placeholder* "window.ECE_DEV_WS_URL = null;")
(define *ece-serve/dev-token* "test-token")
(define *ece-serve/artifact-url-prefix* "/__ece_dev/artifacts/")
(define *ece-serve/artifact-root* ".tmp/ece-serve-artifacts")
(define *ece-serve/artifact-bundle-name* "app.ecec")
(define *ece-serve/artifact-zone-wat-name* "app-zones.wat")
(define *ece-serve/artifact-zone-module-name* "app-zones.wasm")
(define *ece-serve/artifact-zone-manifest-name* "app-zones.manifest")
(define *ece-serve/session-root* ".tmp/ece-serve-sessions")

(define (ece-serve/resolve-path request-path)
  "Map an HTTP request path to a filesystem path under the sandbox
root. Returns a string path, or #f if the path is unsafe (contains
..) or empty."
  (cond
   ((or (not (string? request-path))
        (= (string-length request-path) 0))
    #f)
   ((not (char=? (string-ref request-path 0) #\/))
    #f)
   (else
    ;; Strip query string if present — we don't use it for routing.
    (let* ((qmark (ece-serve/%find-char request-path #\?))
           (clean (if (< qmark 0)
                      request-path
                      (substring request-path 0 qmark)))
           (rel (if (string=? clean "/")
                    "index.html"
                    (substring clean 1 (string-length clean)))))
      (cond
       ((string-contains? rel "..") #f)
       (else (path-join *ece-serve/sandbox-root* rel)))))))

(define (ece-serve/request-path-without-query request-path)
  "Return REQUEST-PATH without its query string."
  (let ((qmark (ece-serve/%find-char request-path #\?)))
    (if (< qmark 0)
        request-path
        (substring request-path 0 qmark))))

(define (ece-serve/dev-artifact-request-path? request-path)
  "Return #t when REQUEST-PATH targets the dev artifact namespace."
  (starts-with? (ece-serve/request-path-without-query request-path)
                *ece-serve/artifact-url-prefix*))

(define (ece-serve/resolve-dev-artifact-path request-path)
  "Map a /__ece_dev/artifacts/<file> request to the artifact directory.
Only single-segment artifact filenames are accepted."
  (let ((clean (ece-serve/request-path-without-query request-path)))
    (cond
     ((not (starts-with? clean *ece-serve/artifact-url-prefix*)) #f)
     (else
      (let ((rel (substring clean
                            (string-length *ece-serve/artifact-url-prefix*)
                            (string-length clean))))
        (cond
         ((= (string-length rel) 0) #f)
         ((string-contains? rel "..") #f)
         ((string-contains? rel "/") #f)
         ((string-contains? rel "\\") #f)
         (else (path-join *ece-serve/artifact-root* rel))))))))

(define (ece-serve/%find-char s ch)
  "Return the index of the first CH in S, or -1 if absent."
  (let ((len (string-length s)))
    (let loop ((i 0))
      (cond
       ((>= i len) -1)
       ((char=? (string-ref s i) ch) i)
       (else (loop (+ i 1)))))))

;; ---- Request → response dispatcher ----

(define (ece-serve/dispatch req . opts)
  "Given a parsed http-request REQ, return one of:
  - the symbol 'upgrade — caller should run the WebSocket handshake path
  - a response STRING — text content type; caller writes via %send-string
  - a response BYTE LIST — binary content type; caller writes via %send-bytes
The non-404/400 cases come from ece-serve/serve-static which chooses
between the two based on the resolved file's content type. 405 for
non-GET, 400 for path traversal, 404 for missing files — all text
string responses."
  (let ((clients-box (if (null? opts) #f (car opts)))
        (sched (if (or (null? opts) (null? (cdr opts))) #f (car (cdr opts)))))
    (cond
     ((and (string=? (http-request-method req) "POST")
           (ece-serve/editor-command-path? (http-request-path req)))
      (ece-serve/handle-editor-command req clients-box sched))
     ((not (string=? (http-request-method req) "GET"))
      (http-build-response 405 "Method Not Allowed" '() "Method Not Allowed"))
     ((ece-serve/dev-artifact-request-path? (http-request-path req))
      (ece-serve/serve-dev-artifact req))
     ((ece-serve/is-websocket-upgrade? req) 'upgrade)
     (else
      (ece-serve/serve-static req)))))

(define (ece-serve/editor-command-path? path)
  "Return #t if PATH is one of the localhost editor command endpoints."
  (or (string=? path "/__ece_dev/eval-source")
      (string=? path "/__ece_dev/program-reload")))

(define (ece-serve/editor-path-header req)
  "Return the editor-supplied source path header, or a stable fallback."
  (let ((path (http-header-ref req "x-ece-path")))
    (if (and path (> (string-length path) 0)) path "<editor>")))

(define (ece-serve/optional-header req name)
  "Return non-empty header NAME from REQ, or #f."
  (let ((value (http-header-ref req name)))
    (if (and value (> (string-length value) 0)) value #f)))

(define (ece-serve/valid-dev-token? token)
  "Return #t when TOKEN matches the per-server dev token."
  (and *ece-serve/dev-token*
       token
       (string=? token *ece-serve/dev-token*)))

(define (ece-serve/request-dev-token req)
  "Return the dev token supplied by REQ, if any."
  (http-header-ref req "x-ece-dev-token"))

(define (ece-serve/handle-editor-command req clients-box sched)
  "Handle a POST from an editor integration.
/__ece_dev/eval-source relays request body source text.
/__ece_dev/program-reload relays artifact URLs for browser-side archive reload."
  (cond
   ((not (ece-serve/valid-dev-token? (ece-serve/request-dev-token req)))
    (ece-serve/json-response 403 "Forbidden"
                             (list (cons "ok" #f)
                                   (cons "error" "invalid dev token"))))
   ((not clients-box)
    (ece-serve/json-response 500 "Internal Server Error"
                             (list (cons "ok" #f)
                                   (cons "error" "missing clients box"))))
   ((string=? (http-request-path req) "/__ece_dev/eval-source")
    (let ((request-id (ece-serve/editor-request-id req))
          (wait? (ece-serve/editor-wait-result? req)))
      (cond
       ((and wait? (null? (ece-serve/clients-list clients-box)))
        (ece-serve/json-response 503 "Service Unavailable"
                                 (list (cons "ok" #f)
                                       (cons "type" "eval-source")
                                       (cons "id" request-id)
                                       (cons "error" "no browser clients connected"))))
       (else
        (when wait?
          (ece-serve/dev-result-await! clients-box request-id))
        (ece-serve/broadcast-eval-source
         clients-box
         request-id
         (ece-serve/editor-path-header req)
         (http-request-body req))
        (cond
         (wait?
          (let ((result
                 (ece-serve/wait-for-dev-result
                  clients-box sched request-id
                  (ece-serve/editor-result-timeout-ms req))))
            (cond
             (result
              (ece-serve/json-text-response 200 "OK" result))
             (else
              (ece-serve/json-response 504 "Gateway Timeout"
                                       (list (cons "ok" #f)
                                             (cons "type" "eval-source")
                                             (cons "id" request-id)
                                             (cons "error" "timed out waiting for browser eval result")))))))
         (else
          (ece-serve/json-response 200 "OK"
                                   (list (cons "ok" #t)
                                         (cons "type" "eval-source")
                                         (cons "id" request-id)))))))))
   ((string=? (http-request-path req) "/__ece_dev/program-reload")
    (let ((archive-url (http-request-body req))
          (zone-module-url
           (ece-serve/optional-header req "x-ece-zone-module-url"))
          (manifest-url
           (ece-serve/optional-header req "x-ece-manifest-url")))
      (cond
       ((or (not (string? archive-url))
            (= (string-length archive-url) 0))
        (ece-serve/json-response 400 "Bad Request"
                                 (list (cons "ok" #f)
                                       (cons "error" "missing archive URL"))))
       ((or (and zone-module-url (not manifest-url))
            (and manifest-url (not zone-module-url)))
        (ece-serve/json-response 400 "Bad Request"
                                 (list (cons "ok" #f)
                                       (cons "error"
                                             "native-zone module and manifest URLs must be supplied together"))))
       (else
        (ece-serve/broadcast-program-reload
         clients-box
         archive-url
         zone-module-url
         manifest-url)
        (ece-serve/json-response 200 "OK"
                                 (list (cons "ok" #t)
                                       (cons "type" "program-reload")))))))
   (else
    (ece-serve/json-response 404 "Not Found"
                             (list (cons "ok" #f)
                                   (cons "error" "unknown editor command"))))))

(define (ece-serve/json-response status reason obj)
  "Build a JSON HTTP response with no-store semantics."
  (ece-serve/json-text-response status reason (json-encode-object obj)))

(define (ece-serve/json-text-response status reason text)
  "Build a JSON HTTP response with pre-encoded JSON TEXT."
  (http-build-response status reason
                       (list (cons "Content-Type" "application/json; charset=utf-8")
                             (cons "Cache-Control" "no-store"))
                       text))

(define *ece-serve/next-editor-request-id* 0)

(define (ece-serve/editor-request-id req)
  "Return the editor-supplied request id or allocate one."
  (let ((id (ece-serve/optional-header req "x-ece-request-id")))
    (cond
     (id id)
     (else
      (set! *ece-serve/next-editor-request-id*
            (+ *ece-serve/next-editor-request-id* 1))
      (string-append "eval-" (number->string *ece-serve/next-editor-request-id*))))))

(define (ece-serve/editor-wait-result? req)
  "Return #t when the editor wants the HTTP request to wait for browser eval."
  (let ((value (ece-serve/optional-header req "x-ece-wait-result")))
    (and value
         (or (string=? value "1")
             (string=? (string-downcase value) "true")))))

(define (ece-serve/editor-result-timeout-ms req)
  "Return the browser eval wait timeout requested by REQ, or the default."
  (let ((value (ece-serve/optional-header req "x-ece-timeout-ms")))
    (cond
     ((not value) 5000)
     (else
      (let ((parsed (string->number value)))
        (if (and parsed (integer? parsed) (> parsed 0))
            parsed
            5000))))))

(define (ece-serve/is-websocket-upgrade? req)
  "Detect an RFC 6455 WebSocket upgrade request. Returns #t only if ALL
of the required handshake headers are present and valid:
  - Upgrade: websocket (case-insensitive)
  - Connection containing 'upgrade' (case-insensitive)
  - Sec-WebSocket-Key: present (any non-empty value — the codec will
    base64+sha1 it against the magic GUID)
  - Sec-WebSocket-Version: exactly '13' per RFC 6455 §4.1
  - token query parameter matching this server's dev token

If any header is missing or invalid, returns #f and the caller falls
through to `ece-serve/serve-static`, which produces a 404 for `/ws`.
This is a safer default than letting a malformed upgrade attempt flow
into the handshake builder, where a #f Sec-WebSocket-Key would crash
`ws-compute-accept-key` via a string-append type error."
  (let ((upgrade (http-header-ref req "upgrade"))
        (connection (http-header-ref req "connection"))
        (key (http-header-ref req "sec-websocket-key"))
        (version (http-header-ref req "sec-websocket-version")))
    (and upgrade
         connection
         key
         (> (string-length key) 0)
         version
         (string=? (string-downcase upgrade) "websocket")
         (string-contains? (string-downcase connection) "upgrade")
         (string=? version "13")
         (ece-serve/ws-request-token-valid? req))))

(define (ece-serve/ws-request-token-valid? req)
  "Return #t if REQ's /ws query string contains this server's dev token."
  (ece-serve/valid-dev-token?
   (ece-serve/query-param (http-request-path req) "token")))

(define (ece-serve/query-param request-path name)
  "Return NAME's value from REQUEST-PATH's query string, or #f.
This tiny parser intentionally supports only the unescaped token values
ece-serve generates for its own dev WebSocket URL."
  (let ((qmark (ece-serve/%find-char request-path #\?)))
    (cond
     ((< qmark 0) #f)
     (else
      (let ((query (substring request-path (+ qmark 1)
                              (string-length request-path))))
        (let loop ((parts (string-split query "&")))
          (cond
           ((null? parts) #f)
           (else
            (let* ((part (car parts))
                   (eq-idx (ece-serve/%find-char part #\=)))
              (cond
               ((< eq-idx 0) (loop (cdr parts)))
               ((string=? (substring part 0 eq-idx) name)
                (substring part (+ eq-idx 1) (string-length part)))
               (else (loop (cdr parts)))))))))))))

(define (ece-serve/serve-static req)
  "Serve a static file from the sandbox root. Returns either a response
string (text content types, consumed via %send-string) OR a byte list
(binary content types like wasm/png/ico, consumed via %send-bytes).
The caller distinguishes via (string? result) at dispatch time.

Returns a 400/404 response STRING on miss (both are text)."
  (let ((fs-path (ece-serve/resolve-path (http-request-path req))))
    (cond
     ((not fs-path)
      (http-build-response 400 "Bad Request" '() "Bad Request"))
     ((not (%file-exists? fs-path))
      (http-build-response 404 "Not Found" '()
                           (string-append "Not Found: "
                                          (http-request-path req))))
     ;; %file-exists? returns true for directories on CL as well as for
     ;; regular files, and open-*-input-file on a directory raises a
     ;; host-level stream error that ECE's `guard` macro currently can
     ;; NOT catch — apply-primitive-procedure only converts CL
     ;; `division-by-zero` and `type-error` to sentinels, so stream /
     ;; file errors propagate at the CL level past ECE's exception
     ;; machinery and reach the CL top-level handler. Until that kernel
     ;; limitation is fixed, we avoid the problem here by rejecting any
     ;; path without a file extension as 404: every legitimate static
     ;; asset under `sandbox/` has an extension (html / js / wasm / ico
     ;; / png / css / scm / ecec), so "no extension" is a safe proxy
     ;; for "probably a directory or something we can't safely read."
     ((not (ece-serve/%has-any-extension? fs-path))
      (http-build-response 404 "Not Found" '()
                           (string-append "Not Found: "
                                          (http-request-path req))))
     (else
      (let ((content-type (ece-serve/content-type-for fs-path)))
        (cond
         ((ece-serve/is-binary-content-type? content-type)
          (ece-serve/build-binary-response
           content-type
           (ece-serve/read-file-as-bytes fs-path)))
         (else
          (let ((body (ece-serve/read-file-as-string fs-path)))
            (http-build-response 200 "OK"
                                 (list (cons "Content-Type" content-type)
                                       ;; Dev server — never cache. Hot
                                       ;; reload delivers source over
                                       ;; WebSocket; HTTP assets like
                                       ;; index.html should always be
                                       ;; fetched fresh so browser-reload
                                       ;; picks up manual edits.
                                       (cons "Cache-Control" "no-store"))
                                 (if (string=? fs-path
                                               (path-join *ece-serve/sandbox-root*
                                                          "index.html"))
                                     (ece-serve/inject-dev-ws-url body)
                                     body))))))))))

(define (ece-serve/serve-dev-artifact req)
  "Serve a generated dev artifact from *ece-serve/artifact-root*."
  (let ((fs-path (ece-serve/resolve-dev-artifact-path
                  (http-request-path req))))
    (cond
     ((not fs-path)
      (http-build-response 400 "Bad Request" '() "Bad Request"))
     ((not (%file-exists? fs-path))
      (http-build-response 404 "Not Found" '()
                           (string-append "Not Found: "
                                          (http-request-path req))))
     ((not (ece-serve/%has-any-extension? fs-path))
      (http-build-response 404 "Not Found" '()
                           (string-append "Not Found: "
                                          (http-request-path req))))
     (else
      (let ((content-type (ece-serve/content-type-for fs-path)))
        (cond
         ((ece-serve/is-binary-content-type? content-type)
          (ece-serve/build-binary-response
           content-type
           (ece-serve/read-file-as-bytes fs-path)))
         (else
          (http-build-response 200 "OK"
                               (list (cons "Content-Type" content-type)
                                     (cons "Cache-Control" "no-store"))
                               (ece-serve/read-file-as-string fs-path)))))))))

(define (ece-serve/dev-ws-url)
  "Return the WebSocket URL injected into sandbox/index.html."
  (ece-serve/dev-ws-url-for-port *ece-serve/current-port*))

(define (ece-serve/dev-ws-url-for-port port)
  "Return the WebSocket URL for PORT and the current dev token."
  (string-append "ws://127.0.0.1:"
                 (number->string port)
                 "/ws?token="
                 *ece-serve/dev-token*))

(define (ece-serve/generate-dev-token)
  "Generate a per-process dev token for browser and editor clients.
This is not a long-term authentication system; it prevents unrelated
browser origins from driving a developer's localhost ece-serve by
requiring an unguessable-ish token that is printed in the terminal and
injected only into same-origin sandbox HTML."
  (random-seed! (current-milliseconds))
  (let ((chars "0123456789abcdef"))
    (let loop ((n 32) (acc ""))
      (cond
       ((<= n 0) acc)
       (else
        (let ((i (random 16)))
          (loop (- n 1)
                (string-append acc (string (string-ref chars i))))))))))

(define (ece-serve/inject-dev-ws-url html)
  "Replace the standalone sandbox dev-server placeholder with this server's
WebSocket URL. If the placeholder is absent, return HTML unchanged so older
or hand-edited sandbox files still serve."
  (let ((idx (ece-serve/%string-index-of html *ece-serve/dev-ws-placeholder*)))
    (cond
     ((< idx 0) html)
     (else
      (string-append
       (substring html 0 idx)
       "window.ECE_DEV_WS_URL = \""
       (ece-serve/dev-ws-url)
       "\";"
       (substring html
                  (+ idx (string-length *ece-serve/dev-ws-placeholder*))
                  (string-length html)))))))

(define (ece-serve/%string-index-of haystack needle)
  "Return the first index of NEEDLE in HAYSTACK, or -1 if absent."
  (let ((h-len (string-length haystack))
        (n-len (string-length needle)))
    (cond
     ((= n-len 0) 0)
     ((> n-len h-len) -1)
     (else
      (let outer ((i 0))
        (cond
         ((> (+ i n-len) h-len) -1)
         (else
          (let inner ((j 0))
            (cond
             ((>= j n-len) i)
             ((char=? (string-ref haystack (+ i j))
                      (string-ref needle j))
              (inner (+ j 1)))
             (else (outer (+ i 1))))))))))))

(define (ece-serve/%json-skip-space s i)
  "Return the first index >= I in S that is not JSON whitespace."
  (let ((len (string-length s)))
    (let loop ((j i))
      (cond
       ((>= j len) j)
       ((or (char=? (string-ref s j) #\space)
            (char=? (string-ref s j) (integer->char 9))
            (char=? (string-ref s j) (integer->char 10))
            (char=? (string-ref s j) (integer->char 13)))
        (loop (+ j 1)))
       (else j)))))

(define (ece-serve/%json-hex-value ch)
  "Return CH's hex value, or -1 if CH is not a hex digit."
  (let ((n (char->integer ch)))
    (cond
     ((and (>= n 48) (<= n 57)) (- n 48))
     ((and (>= n 65) (<= n 70)) (+ 10 (- n 65)))
     ((and (>= n 97) (<= n 102)) (+ 10 (- n 97)))
     (else -1))))

(define (ece-serve/%json-read-string-at s start)
  "Read a JSON string beginning at START.
Returns (value . next-index), or #f if the string is malformed."
  (let ((len (string-length s)))
    (cond
     ((or (>= start len) (not (char=? (string-ref s start) #\"))) #f)
     (else
      (let ((out (open-output-string)))
        (let loop ((i (+ start 1)))
          (cond
           ((>= i len) #f)
           ((char=? (string-ref s i) #\")
            (cons (get-output-string out) (+ i 1)))
           ((char=? (string-ref s i) #\\)
            (cond
             ((>= (+ i 1) len) #f)
             (else
              (let ((esc (string-ref s (+ i 1))))
                (cond
                 ((char=? esc #\") (write-char #\" out) (loop (+ i 2)))
                 ((char=? esc #\\) (write-char #\\ out) (loop (+ i 2)))
                 ((char=? esc #\/) (write-char #\/ out) (loop (+ i 2)))
                 ((char=? esc #\b) (write-char (integer->char 8) out) (loop (+ i 2)))
                 ((char=? esc #\f) (write-char (integer->char 12) out) (loop (+ i 2)))
                 ((char=? esc #\n) (write-char (integer->char 10) out) (loop (+ i 2)))
                 ((char=? esc #\r) (write-char (integer->char 13) out) (loop (+ i 2)))
                 ((char=? esc #\t) (write-char (integer->char 9) out) (loop (+ i 2)))
                 ((char=? esc #\u)
                  (cond
                   ((>= (+ i 6) len) #f)
                   (else
                    (let ((h1 (ece-serve/%json-hex-value (string-ref s (+ i 2))))
                          (h2 (ece-serve/%json-hex-value (string-ref s (+ i 3))))
                          (h3 (ece-serve/%json-hex-value (string-ref s (+ i 4))))
                          (h4 (ece-serve/%json-hex-value (string-ref s (+ i 5)))))
                      (cond
                       ((or (< h1 0) (< h2 0) (< h3 0) (< h4 0)) #f)
                       (else
                        (write-char
                         (integer->char
                          (+ (* h1 4096) (* h2 256) (* h3 16) h4))
                         out)
                        (loop (+ i 6))))))))
                 (else #f))))))
           (else
            (write-char (string-ref s i) out)
            (loop (+ i 1))))))))))

(define (ece-serve/json-string-field raw key)
  "Return string field KEY from a small JSON object RAW, or #f.
This is intentionally a field extractor, not a general JSON decoder. It is
used only to match browser result frames to editor request ids."
  (let* ((needle (json-encode-string key))
         (idx (ece-serve/%string-index-of raw needle)))
    (cond
     ((< idx 0) #f)
     (else
      (let* ((after-key (+ idx (string-length needle)))
             (colon (ece-serve/%json-skip-space raw after-key)))
        (cond
         ((or (>= colon (string-length raw))
              (not (char=? (string-ref raw colon) #\:)))
          #f)
         (else
          (let* ((value-start
                  (ece-serve/%json-skip-space raw (+ colon 1)))
                 (parsed
                  (ece-serve/%json-read-string-at raw value-start)))
            (and parsed (car parsed))))))))))

(define (ece-serve/%has-any-extension? path)
  "Test whether PATH has a file extension: a `.` somewhere after the
last `/`. A directory like `sandbox/programs` returns #f. A file like
`sandbox/index.html` returns #t. Used by serve-static as a directory
rejection proxy — see the big comment at the call site."
  (let ((len (string-length path)))
    (let loop ((i (- len 1)))
      (cond
       ((< i 0) #f)
       ((char=? (string-ref path i) #\/) #f)
       ((char=? (string-ref path i) #\.)
        ;; Guard against hidden files: a leading `.` in the last
        ;; segment (e.g., `.gitignore`) isn't really an extension.
        ;; Require at least one non-`.` char before the dot.
        (and (> i 0)
             (not (char=? (string-ref path (- i 1)) #\/))))
       (else (loop (- i 1)))))))

(define (ece-serve/build-binary-response content-type body-bytes)
  "Build a 200 OK response for a binary body. Returns a list of byte
integers suitable for tcp-send-nowait. Unlike http-build-response, the
body is NOT coerced through a string — the bytes go out on the wire
verbatim, which is required for wasm / png / ico / opaque blobs where
character-set conversion would corrupt the payload.

Content-Length is computed from BODY-BYTES and Connection: close is
set automatically — same defaults as http-build-response."
  (let* ((body-len (length body-bytes))
         (headers (list (cons "Content-Type" content-type)
                        (cons "Content-Length" (number->string body-len))
                        (cons "Connection" "close")
                        ;; Dev server — never cache. See matching
                        ;; comment in serve-static's text path.
                        (cons "Cache-Control" "no-store")))
         ;; http-build-response with empty string body gives us a header
         ;; block ending in \r\n\r\n and nothing after; we then append
         ;; the raw bytes.
         (header-str (http-build-response 200 "OK" headers "")))
    (append (string->ascii-bytes header-str) body-bytes)))

;; ---- WebSocket upgrade handshake ----

(define (ece-serve/build-ws-upgrade-response req)
  "Build the RFC 6455 §4.2.2 101 Switching Protocols response for REQ.
The caller is expected to have already confirmed REQ is a WebSocket
upgrade request via ece-serve/is-websocket-upgrade?."
  (let* ((key (http-header-ref req "sec-websocket-key"))
         (accept (ws-compute-accept-key key)))
    (http-build-response
     101 "Switching Protocols"
     (list (cons "Upgrade" "websocket")
           (cons "Connection" "Upgrade")
           (cons "Sec-WebSocket-Accept" accept))
     "")))

;; ---- Transitive (load ...) walker ----
;;
;; The dev server watches the set of source files transitively reachable
;; from the entry program. The walker opens each file, scans its
;; top-level forms for `(load "literal-string")` forms, and recursively
;; walks their dependencies. Dynamic `(load <expr>)` forms with a
;; non-literal-string argument are silently skipped — they can't be
;; resolved statically. Forms that aren't lists or don't start with
;; 'load are ignored.

(define (ece-serve/walk-loads entry-path)
  "Return the transitive closure of literal-string (load ...) targets
reachable from ENTRY-PATH. The returned list always includes
ENTRY-PATH itself as its first element. Paths are resolved relative
to the directory of the form that contained the load."
  (let ((seen '())
        (result '()))
    (define (visit abs-path)
      (cond
       ((member abs-path seen) 'already-visited)
       ((not (%file-exists? abs-path)) 'missing)
       (else
        (set! seen (cons abs-path seen))
        (set! result (cons abs-path result))
        ;; A syntax error or I/O error reading a single file must not
        ;; kill the whole walk — the user may be mid-edit. Log-and-skip
        ;; so the file still ends up in the watch set (it's already in
        ;; `result`) even if we can't currently parse it.
        (guard
         (e (#t 'read-error))
         (let ((forms (ece-serve/%read-all-forms abs-path))
               (base-dir (dirname abs-path)))
           (for-each
            (lambda (form)
              (cond
               ((ece-serve/%load-form? form)
                (let ((target (car (cdr form))))
                  (cond
                   ((string? target)
                    (visit (ece-serve/%resolve-relative target base-dir))))))))
            forms))))))
    (visit entry-path)
    (reverse result)))

(define (ece-serve/%read-all-forms path)
  "Read every top-level form from PATH as a list. Returns '() on EOF.
Uses dynamic-wind so a parse error mid-file closes the port rather
than leaking it into the runtime's file-descriptor pool."
  (let ((in (open-input-file path)))
    (dynamic-wind
        (lambda () #f)
        (lambda ()
          (let loop ((acc '()))
            (let ((form (read in)))
              (cond
               ((eof? form) (reverse acc))
               (else (loop (cons form acc)))))))
        (lambda () (close-input-port in)))))

(define (ece-serve/%load-form? form)
  "Test whether FORM is `(load <anything>)`."
  (and (pair? form)
       (eq? (car form) 'load)
       (pair? (cdr form))
       (null? (cdr (cdr form)))))

(define (ece-serve/%resolve-relative target base-dir)
  "Resolve TARGET against BASE-DIR. If TARGET begins with `/`, it is
treated as an absolute path. Otherwise it is joined with BASE-DIR."
  (cond
   ((and (> (string-length target) 0)
         (char=? (string-ref target 0) #\/))
    target)
   (else (path-join base-dir target))))

;; ---- Fiber wakeup model ----
;;
;; The accept fiber waits on 'tcp-accept-ready. All per-connection
;; handlers (HTTP read, WebSocket read) wait on the shared
;; 'tcp-read-ready tag. The file-watch fiber waits on 'file-watch-timer.
;;
;; The event sources below notify each tag unconditionally on every
;; scheduler poll tick. This wakes every waiter on that tag at once
;; (scheduler uses tag-only matching in Stage 1), and each woken
;; fiber re-checks its own resource via the nonblocking primitive. If
;; the check still shows "would-block", the fiber yields again and
;; will wake on the next tick. This is coarser than per-resource
;; wakeup but has zero per-fiber state and is trivially correct.
;;
;; A future refinement (scheduler section 4/8 of the design doc)
;; would match on tag plus a handle so each fiber only wakes when
;; its own resource is ready. That's future work; for the dev server
;; the coarse wakeup is both simpler and plenty fast enough.

;; ---- Accept loop ----

(define (ece-serve/accept-loop sched server clients-box)
  "Accept loop: wait for the server socket to become readable, accept
all pending connections, spawn a handler fiber for each, then sleep
until the next notification. A transient accept error (EMFILE on a
busy machine, half-open connection vanishing between readiness and
the accept call) is caught inside the inner guard so the loop keeps
running and the server doesn't lose its accept capacity silently.
The wait-for call is deliberately outside the guard — a scheduler-
level error there should kill this fiber loudly."
  (let loop ()
    (guard
     (e (#t 'accept-error))
     (let inner ((conn (tcp-accept-nowait server)))
       (cond
        ((or (not conn) (eq? conn #f)) #f)
        (else
         (ece-serve/spawn-connection-handler sched conn clients-box)
         ;; Drain additional connections that arrived in the same tick.
         (inner (tcp-accept-nowait server))))))
    (wait-for sched 'tcp-accept-ready)
    (loop)))

(define (ece-serve/spawn-connection-handler sched conn clients-box)
  "Spawn a per-connection handler fiber that owns CONN for its lifetime.
The handler either serves a static asset + closes, or performs the
WebSocket upgrade and transitions to the WS message loop."
  (scheduler-spawn!
   sched
   (lambda ()
     (guard
      (e (#t
          ;; Defensive: any error in a handler crashes only that
          ;; fiber. Close the conn so we don't leak file descriptors.
          (ece-serve/%try-close conn)))
      (ece-serve/handle-connection sched conn clients-box)))))

(define (ece-serve/%try-close handle)
  "Close a TCP handle, swallowing any error from double-close."
  (guard (e (#t 'close-failed))
         (tcp-close handle)))

;; ---- Per-connection handler ----

(define (ece-serve/handle-connection sched conn clients-box)
  "Read the HTTP request header block from CONN, dispatch the request,
and either write a static response + close, or upgrade to WebSocket."
  (let ((raw (ece-serve/read-http-request sched conn)))
    (cond
     ((eq? raw 'closed)
      (ece-serve/%try-close conn))
     ((eq? raw 'malformed)
      (ece-serve/%send-string conn
                              (http-build-response 400 "Bad Request" '() "Malformed request"))
      (ece-serve/%try-close conn))
     (else
      (let ((req (http-parse-request raw)))
        (cond
         ((eq? req 'malformed)
          (ece-serve/%send-string conn
                                  (http-build-response 400 "Bad Request" '() "Malformed request"))
          (ece-serve/%try-close conn))
         (else
          (let ((result (ece-serve/dispatch req clients-box sched)))
            (cond
             ((eq? result 'upgrade)
              (ece-serve/upgrade-to-websocket sched conn req clients-box))
             ((string? result)
              (ece-serve/%send-string conn result)
              (ece-serve/%try-close conn))
             (else
              ;; Binary result (byte list) from serve-static for wasm /
              ;; image / octet-stream paths. Send verbatim without going
              ;; through string conversion.
              (ece-serve/%send-bytes conn result)
              (ece-serve/%try-close conn)))))))))))

(define (ece-serve/read-http-request sched conn)
  "Read bytes from CONN until a complete HTTP request has arrived.
For GET / WebSocket requests this means the header block; for POST
editor commands this means headers plus Content-Length bytes of body.
Returns the request as a string on success, the symbol 'closed if the
peer closed before the request completed, or 'malformed if the request
exceeds a sane byte limit (1 MiB — protects against slowloris-ish
pile-ups even on localhost) or has a bad Content-Length.

Chunks are kept in reverse order while reading. After each new chunk,
the accumulated bytes are flattened and checked for a complete request.
That is intentionally simple: the request size is capped at 1 MiB and
editor command bodies are expected to be small."
  (let ((max-bytes 1048576))
    (let loop ((chunks-rev '()) (byte-count 0))
      (cond
       ((> byte-count max-bytes) 'malformed)
       (else
        (let ((chunk (tcp-recv-nowait conn 4096)))
          (cond
           ((eq? chunk (ece-serve/%ece-would-block))
            ;; Nothing to read yet — yield until the poller wakes us.
            ;; Stage 1 uses a shared 'tcp-read-ready tag; every waiting
            ;; handler wakes on each poll and re-checks its own conn.
            (wait-for sched 'tcp-read-ready)
            (loop chunks-rev byte-count))
           ((eq? chunk (ece-serve/%ece-eof))
            ;; EOF without a terminator is always 'closed — every
            ;; successful-read branch already scans for the sentinel
            ;; and returns the string if it's present, so by the time
            ;; we hit EOF we know we haven't seen one.
            'closed)
           ((pair? chunk)
            (let* ((chunk-len (length chunk))
                   (new-byte-count (+ byte-count chunk-len))
                   (all-bytes (ece-serve/%flatten-chunks-in-order
                               (cons chunk chunks-rev)))
                   (complete (ece-serve/%complete-http-request all-bytes)))
              (cond
               ((> new-byte-count max-bytes) 'malformed)
               ((eq? complete 'malformed) 'malformed)
               (complete complete)
               (else
                (loop (cons chunk chunks-rev)
                      new-byte-count)))))
           (else (loop chunks-rev byte-count)))))))))

(define (ece-serve/%complete-http-request bytes)
  "Given accumulated request BYTES, return the complete request string
if all declared body bytes are present, #f if more bytes are needed,
or 'malformed if Content-Length is invalid."
  (let ((header-end (http-header-end-bytes bytes)))
    (cond
     ((not header-end) #f)
     (else
      (let* ((raw (ascii-bytes->string bytes))
             (req (http-parse-request raw)))
        (cond
         ((eq? req 'malformed) 'malformed)
         ((eq? req 'incomplete) #f)
         (else
          (let* ((len-str (http-header-ref req "content-length"))
                 (body-len (if len-str (string->number len-str) 0)))
            (cond
             ((or (not body-len) (not (integer? body-len)) (< body-len 0))
              'malformed)
             ((>= (length bytes) (+ header-end body-len))
              (ascii-bytes->string
               (ece-serve/%list-take bytes (+ header-end body-len))))
             (else #f))))))))))

(define (ece-serve/%list-take lst n)
  "Return the first N elements of LST, or all of LST if shorter."
  (let loop ((rest lst) (k n) (acc '()))
    (cond
     ((or (null? rest) (<= k 0)) (reverse acc))
     (else (loop (cdr rest) (- k 1) (cons (car rest) acc))))))

(define (ece-serve/%flatten-chunks-in-order chunks-rev)
  "Given a list of byte chunks in REVERSE order, return a flat byte
list in original order. Total work is O(sum(chunk lengths)) because
each `append` is O(length of its first arg), and we walk each chunk
exactly once."
  (let loop ((rest chunks-rev) (acc '()))
    (cond
     ((null? rest) acc)
     (else
      ;; rest is in reverse order, so prepending (car rest) to acc
      ;; (via append first=chunk) puts the chunks back in original
      ;; order by the time the loop terminates.
      (loop (cdr rest) (append (car rest) acc))))))

;; Cached references to the 'would-block / 'eof sentinels returned by
;; the tcp-recv-nowait primitive. Both are interned in the :ece package
;; at reader time, so a literal symbol here resolves to the same object
;; the CL-side primitive returns.
(define *ece-serve/would-block-sym* 'would-block)
(define *ece-serve/eof-sym*         'eof)

(define (ece-serve/%ece-would-block) *ece-serve/would-block-sym*)
(define (ece-serve/%ece-eof)         *ece-serve/eof-sym*)

(define (ece-serve/%send-string conn s)
  "Send a complete response string S to CONN as bytes."
  (tcp-send-nowait conn (string->ascii-bytes s)))

;; ---- WebSocket upgrade + message loop ----

(define (ece-serve/upgrade-to-websocket sched conn req clients-box)
  "Perform the RFC 6455 handshake on CONN for request REQ, then enter
the WebSocket message loop. Registers CONN in CLIENTS-BOX so the
file-watch fiber can broadcast to it."
  (let ((resp (ece-serve/build-ws-upgrade-response req)))
    (ece-serve/%send-string conn resp)
    (ece-serve/clients-add! clients-box conn)
    (ece-serve/websocket-loop sched conn clients-box)))

(define (ece-serve/websocket-loop sched conn clients-box)
  "WebSocket message loop for a single client CONN. Reads frames,
handles close / ping / pong, records browser result text frames, and
terminates on close or peer disconnect."
  (let loop ((buffered '()))
    (let ((chunk (tcp-recv-nowait conn 4096)))
      (cond
       ((eq? chunk (ece-serve/%ece-would-block))
        (wait-for sched 'tcp-read-ready)
        (loop buffered))
       ((eq? chunk (ece-serve/%ece-eof))
        (ece-serve/clients-remove! clients-box conn)
        (ece-serve/%try-close conn))
       ((pair? chunk)
        (let* ((combined (append buffered chunk))
               (frame (ws-decode-frame combined)))
          (cond
           ((eq? frame 'incomplete)
            (loop combined))
           ((eq? frame 'malformed)
            (ece-serve/clients-remove! clients-box conn)
            (ece-serve/%send-bytes conn (ws-encode-close-frame))
            (ece-serve/%try-close conn))
           (else
            (let ((op (ws-frame-opcode frame))
                  (total (ws-frame-total-length frame)))
              (cond
               ((= op 8) ; close
                (ece-serve/clients-remove! clients-box conn)
                (ece-serve/%send-bytes conn (ws-encode-close-frame))
                (ece-serve/%try-close conn))
               ((= op 9) ; ping
                (ece-serve/%send-bytes conn
                                       (ws-encode-pong-frame (ws-frame-payload-bytes frame)))
                (loop (ece-serve/%list-drop combined total)))
               ((= op 1) ; text
                (ece-serve/handle-browser-text-frame
                 sched clients-box (ws-frame-payload-text frame))
                (loop (ece-serve/%list-drop combined total)))
               (else
                (loop (ece-serve/%list-drop combined total)))))))))
       (else (loop buffered))))))

(define (ece-serve/%send-bytes conn bytes)
  "Send a byte list to CONN."
  (tcp-send-nowait conn bytes))

(define (ece-serve/%list-drop lst n)
  "Return LST with the first N elements removed."
  (let loop ((rest lst) (k n))
    (cond
     ((or (null? rest) (<= k 0)) rest)
     (else (loop (cdr rest) (- k 1))))))

;; ---- Clients box (shared state between handlers and file-watch fiber) ----

(define (ece-serve/make-clients-box)
  "Return a fresh clients box.
Slot 0 holds connected WebSocket clients. Slot 1 holds request ids currently
awaiting browser eval results. Slot 2 holds ((request-id . raw-json) ...).
Only request ids in the awaited set can store result JSON; late or unsolicited
browser result frames are ignored so long-running sessions do not leak memory."
  (vector '() '() '()))

(define (ece-serve/clients-list box)
  (vector-ref box 0))

(define (ece-serve/clients-add! box conn)
  (vector-set! box 0 (cons conn (ece-serve/clients-list box))))

(define (ece-serve/clients-remove! box conn)
  (vector-set! box 0
               (let loop ((rest (ece-serve/clients-list box)) (acc '()))
                 (cond
                  ((null? rest) (reverse acc))
                  ((eq? (car rest) conn) (loop (cdr rest) acc))
                  (else (loop (cdr rest) (cons (car rest) acc)))))))

(define (ece-serve/dev-results box)
  (vector-ref box 2))

(define (ece-serve/dev-awaited-ids box)
  (vector-ref box 1))

(define (ece-serve/dev-awaiting-result? box request-id)
  "Return #t if REQUEST-ID is currently expected by a waiting editor request."
  (let loop ((rest (ece-serve/dev-awaited-ids box)))
    (cond
     ((null? rest) #f)
     ((string=? (car rest) request-id) #t)
     (else (loop (cdr rest))))))

(define (ece-serve/dev-result-await! box request-id)
  "Mark REQUEST-ID as eligible to store one browser result."
  (when (not (ece-serve/dev-awaiting-result? box request-id))
    (vector-set! box 1
                 (cons request-id (ece-serve/dev-awaited-ids box)))))

(define (ece-serve/dev-result-ref box request-id)
  "Return the raw browser result JSON for REQUEST-ID, or #f."
  (let loop ((rest (ece-serve/dev-results box)))
    (cond
     ((null? rest) #f)
     ((string=? (car (car rest)) request-id) (cdr (car rest)))
     (else (loop (cdr rest))))))

(define (ece-serve/dev-result-put! box request-id raw-json)
  "Store RAW-JSON for REQUEST-ID only if an editor request is waiting for it."
  (when (ece-serve/dev-awaiting-result? box request-id)
    (vector-set!
     box 2
     (cons
      (cons request-id raw-json)
      (let loop ((rest (ece-serve/dev-results box)) (acc '()))
        (cond
         ((null? rest) (reverse acc))
         ((string=? (car (car rest)) request-id)
          (loop (cdr rest) acc))
         (else
          (loop (cdr rest) (cons (car rest) acc)))))))))

(define (ece-serve/dev-result-unawait! box request-id)
  "Remove REQUEST-ID from the awaited set."
  (vector-set!
   box 1
   (let loop ((rest (ece-serve/dev-awaited-ids box)) (acc '()))
     (cond
      ((null? rest) (reverse acc))
      ((string=? (car rest) request-id)
       (loop (cdr rest) acc))
      (else
       (loop (cdr rest) (cons (car rest) acc)))))))

(define (ece-serve/dev-result-remove! box request-id)
  "Remove any stored browser result and pending wait marker for REQUEST-ID."
  (ece-serve/dev-result-unawait! box request-id)
  (vector-set!
   box 2
   (let loop ((rest (ece-serve/dev-results box)) (acc '()))
     (cond
      ((null? rest) (reverse acc))
      ((string=? (car (car rest)) request-id)
       (loop (cdr rest) acc))
      (else
       (loop (cdr rest) (cons (car rest) acc)))))))

(define (ece-serve/handle-browser-text-frame sched clients-box raw)
  "Record browser eval result/error JSON frames.
Only the `type` and `id` fields are parsed here; the full browser JSON is
returned unchanged to the waiting editor request."
  (let ((type (ece-serve/json-string-field raw "type"))
        (request-id (ece-serve/json-string-field raw "id")))
    (when (and request-id
               (or (and type (string=? type "eval-result"))
                   (and type (string=? type "eval-error"))))
      (ece-serve/dev-result-put! clients-box request-id raw)
      (when sched
        (scheduler-notify! sched 'dev-result)))))

(define (ece-serve/wait-for-dev-result clients-box sched request-id timeout-ms)
  "Wait for REQUEST-ID to appear in CLIENTS-BOX and return its raw JSON.
Returns #f on timeout or when called without a scheduler."
  (cond
   ((not sched) #f)
   (else
    (let ((deadline (+ (current-milliseconds) timeout-ms)))
      (let loop ()
        (let ((result (ece-serve/dev-result-ref clients-box request-id)))
          (cond
           (result
            (ece-serve/dev-result-remove! clients-box request-id)
            result)
           ((>= (current-milliseconds) deadline)
            (ece-serve/dev-result-remove! clients-box request-id)
            #f)
           (else
            (wait-for sched 'dev-result)
            (loop)))))))))

;; ---- File-watch fiber ----

(define (ece-serve/ensure-artifact-root!)
  "Ensure the dev artifact directory exists."
  (when (not (%file-exists? ".tmp"))
    (%make-directory ".tmp"))
  (when (not (%file-exists? ".tmp/ece-serve-artifacts"))
    (%make-directory ".tmp/ece-serve-artifacts"))
  (when (not (%file-exists? *ece-serve/artifact-root*))
    (%make-directory *ece-serve/artifact-root*)))

(define (ece-serve/artifact-url filename)
  (string-append *ece-serve/artifact-url-prefix* filename))

(define (ece-serve/artifact-path filename)
  (path-join *ece-serve/artifact-root* filename))

(define (ece-serve/ensure-session-root!)
  "Ensure the local ece-serve session directory exists."
  (when (not (%file-exists? *ece-serve/session-root*))
    (%make-directory *ece-serve/session-root*)))

(define (ece-serve/session-path port)
  "Return the local editor attach session-file path for PORT."
  (path-join *ece-serve/session-root*
             (string-append (number->string port) ".sexp")))

(define (ece-serve/session-data entry-file port)
  "Return the local editor attach session S-expression for ENTRY-FILE and PORT."
  (list (cons "type" "ece-serve-session")
        (cons "version" 1)
        (cons "url" (string-append "http://127.0.0.1:" (number->string port)))
        (cons "ws-url" (ece-serve/dev-ws-url-for-port port))
        (cons "token" *ece-serve/dev-token*)
        (cons "entry" entry-file)
        (cons "port" port)
        (cons "started-at" (current-milliseconds))))

(define (ece-serve/write-session-file! entry-file port)
  "Write the local editor attach session file for ENTRY-FILE on PORT."
  (ece-serve/ensure-session-root!)
  (let ((path (ece-serve/session-path port)))
    (ece-serve/write-sexp-to-file
     (ece-serve/session-data entry-file port)
     path)
    (%chmod path 384)))

(define (ece-serve/artifact-source-list entry-file)
  "Return the source list used for a dev artifact build."
  (ece-serve/walk-loads entry-file))

(define (ece-serve/write-native-zone-artifacts! bundle-path)
  "Write native-zone WAT and manifest artifacts for BUNDLE-PATH."
  (let* ((bundle (generate-register-machine-wasm-zone-archive-file
                  bundle-path
                  *ece-serve/artifact-zone-module-name*))
         (wat-path (ece-serve/artifact-path
                    *ece-serve/artifact-zone-wat-name*))
         (manifest-path (ece-serve/artifact-path
                         *ece-serve/artifact-zone-manifest-name*)))
    (ece-serve/write-string-to-file (wasm-zone-bundle-wat bundle) wat-path)
    (ece-serve/write-string-to-file (wasm-zone-bundle-manifest-text bundle)
                                    manifest-path)
    bundle))

(define (ece-serve/build-program-artifacts! entry-file)
  "Compile ENTRY-FILE's literal load closure into dev reload artifacts.
Returns (ARCHIVE-URL ZONE-MODULE-URL MANIFEST-URL)."
  (ece-serve/ensure-artifact-root!)
  (let ((bundle-path (ece-serve/artifact-path
                      *ece-serve/artifact-bundle-name*))
        (wat-path (ece-serve/artifact-path
                   *ece-serve/artifact-zone-wat-name*))
        (wasm-path (ece-serve/artifact-path
                    *ece-serve/artifact-zone-module-name*)))
    (compile-system (ece-serve/artifact-source-list entry-file) bundle-path)
    (ece-serve/write-native-zone-artifacts! bundle-path)
    (when (not (wasm-as wat-path wasm-path))
      (error "wasm-as failed while building native-zone reload artifact"
             wat-path
             wasm-path))
    (list (ece-serve/artifact-url *ece-serve/artifact-bundle-name*)
          (ece-serve/artifact-url *ece-serve/artifact-zone-module-name*)
          (ece-serve/artifact-url *ece-serve/artifact-zone-manifest-name*))))

(define (ece-serve/build-program-artifact! entry-file)
  "Compile ENTRY-FILE's literal load closure and return its archive URL."
  (car (ece-serve/build-program-artifacts! entry-file)))

(define (ece-serve/broadcast-program-artifact-reload clients-box entry-file)
  "Rebuild ENTRY-FILE's dev artifacts and broadcast a program reload."
  (guard
   (e (#t
       (display "ece-serve: program reload build failed")
       (newline)
       'program-reload-build-error))
   (let ((urls (ece-serve/build-program-artifacts! entry-file)))
     (ece-serve/broadcast-program-reload clients-box
                                         (car urls)
                                         (cadr urls)
                                         (caddr urls)))))

(define (ece-serve/watch-loop sched watch-set clients-box poll-interval-ms entry-file)
  "Start an fs-watch on WATCH-SET and loop forever: every
poll-interval-ms, fs-watch-poll and rebuild/broadcast a program-reload message
over every connected WebSocket client when one or more watched paths changed.

Errors inside a single poll+broadcast iteration are caught and logged
without killing the fiber — transient filesystem errors (e.g., a file
missing briefly during an editor atomic-save rename) must not stop
the watch loop. The `wait-for` and `current-milliseconds` calls are
deliberately OUTSIDE the guard: if the scheduler itself errors, the
fiber exits and the server loses its live-reload capability, which is
a loud failure we want the top-level scheduler to surface.

No fs-watch-stop cleanup: the loop runs until the process exits, at
which point the OS reclaims all file descriptors."
  (let ((watcher (fs-watch-start watch-set)))
    (let loop ((last-ms (current-milliseconds)))
      (wait-for sched 'file-watch-timer)
      (let ((now (current-milliseconds)))
        (cond
         ((< (- now last-ms) poll-interval-ms)
          (loop last-ms))
         (else
          (guard
           (e (#t 'poll-iteration-error))
           (let ((changed (fs-watch-poll watcher)))
             (when (pair? changed)
               (ece-serve/broadcast-program-artifact-reload clients-box entry-file))))
          (loop now)))))))

(define (ece-serve/broadcast-source-update clients-box path)
  "Read PATH and send a source-update message to every connected WS
client. Errors on a single read (file transiently missing during
an editor atomic-save rename) are logged and swallowed — the next
poll picks up the stable version. A client whose send fails is
assumed disconnected and is removed from the clients box, so we
don't accumulate dead clients and waste a send-attempt per poll."
  (guard
   (e (#t 'read-error))
   (let* ((source (ece-serve/read-file-as-string path))
          (envelope (json-source-update path source)))
     (ece-serve/broadcast-json-envelope clients-box envelope))))

(define (ece-serve/broadcast-eval-source clients-box request-id path source)
  "Send an eval-source message to every connected browser client. This
is the editor-driven path: unlike source-update, SOURCE does not need
to be saved on disk first."
  (ece-serve/broadcast-json-envelope
   clients-box
   (json-eval-source path source request-id)))

(define (ece-serve/broadcast-program-reload clients-box archive-url
                                            zone-module-url manifest-url)
  "Send a program-reload message to every connected browser client.
The browser fetches ARCHIVE-URL and optional native-zone artifacts, then calls
ECE's reload-program policy in wasm-host.scm."
  (ece-serve/broadcast-json-envelope
   clients-box
   (json-program-reload archive-url zone-module-url manifest-url)))

(define (ece-serve/broadcast-json-envelope clients-box envelope)
  "Send JSON ENVELOPE as a WebSocket text frame to every connected
client. Dead clients are removed just like the file-watch path."
  (let ((frame (ws-encode-text-frame envelope)))
    (for-each
     (lambda (conn)
       (let ((ok?
              (guard (e (#t #f))
                     (ece-serve/%send-bytes conn frame)
                     #t)))
         (when (not ok?)
           (ece-serve/clients-remove! clients-box conn)
           (ece-serve/%try-close conn))))
     (ece-serve/clients-list clients-box))))

;; ---- Event sources ----
;;
;; Stage 1 uses coarse polling event sources: one fires on every run!
;; tick and wakes all fibers waiting on a tag. Per-fiber filtering
;; happens inside each handler by re-running its nonblocking primitive
;; and yielding again if still not ready. This is wasteful of CPU but
;; trivially correct and matches the "simple before fast" ethos.

(define (ece-serve/make-accept-source server)
  "Build an event source that notifies 'tcp-accept-ready on every
scheduler poll. The accept fiber re-checks via tcp-accept-nowait and
yields again if no connection is pending, so unconditionally notifying
is safe and trivially correct. Per-poll filtering would require
scheduler-level per-handle matching, which is future work."
  (lambda (sched)
    (scheduler-notify! sched 'tcp-accept-ready)))

(define (ece-serve/make-read-source)
  "Build an event source that notifies 'tcp-read-ready unconditionally
on every poll. Per-fiber filtering happens in the handler when it
re-checks its own connection via tcp-recv-nowait."
  (lambda (sched)
    (scheduler-notify! sched 'tcp-read-ready)))

(define (ece-serve/make-timer-source)
  "Build an event source that notifies 'file-watch-timer on every poll.
The file-watch fiber uses current-milliseconds to enforce its own
poll interval; waiting editor eval requests also use it as a timeout
heartbeat while they wait for browser result frames."
  (lambda (sched)
    (scheduler-notify! sched 'file-watch-timer)
    (scheduler-notify! sched 'dev-result)))

;; ---- Top-level entry ----

(define *ece-serve/default-port* 8080)
(define *ece-serve/default-poll-interval-ms* 250)

(define (ece-serve/%show v)
  "Format V as a readable string for use in error messages. Uses the
runtime's write so symbols, numbers, and strings round-trip sensibly.
Kept local so ece-serve.scm doesn't pull in the full prelude helper
surface."
  (let ((out (open-output-string)))
    (write v out)
    (get-output-string out)))

(define (ece-serve/parse-options opts)
  "Parse the keyword args passed to (ece-serve entry . opts). Returns
a record-like list (port poll-interval-ms dev-token). Options:
  :port INT          listen port (integer in [1, 65535], default 8080)
  :poll-interval INT ms between file-watch polls (non-negative integer,
                     default 250)
  :dev-token STRING  shared token for browser/editor dev commands

All values are validated and any failure raises an error that names
the offending option key (and value, where relevant) so programmatic
callers can diagnose the miscall without reading this source."
  (let loop ((rest opts) (port *ece-serve/default-port*)
             (interval *ece-serve/default-poll-interval-ms*)
             (dev-token #f))
    (cond
     ((null? rest) (list port interval dev-token))
     ((null? (cdr rest))
      (error (string-append "ece-serve: option "
                            (ece-serve/%show (car rest))
                            " given without a value")))
     (else
      (let ((key (car rest))
            (val (car (cdr rest)))
            (more (cdr (cdr rest))))
        (cond
         ((eq? key ':port)
          (cond
           ((and (integer? val) (>= val 1) (<= val 65535))
            (loop more val interval dev-token))
           (else
            (error (string-append
                    "ece-serve: :port must be an integer in [1, 65535], got "
                    (ece-serve/%show val))))))
         ((eq? key ':poll-interval)
          (cond
           ((and (integer? val) (>= val 0))
            (loop more port val dev-token))
           (else
            (error (string-append
                    "ece-serve: :poll-interval must be a non-negative integer, got "
                    (ece-serve/%show val))))))
         ((eq? key ':dev-token)
          (cond
           ((and (string? val) (> (string-length val) 0))
            (loop more port interval val))
           (else
            (error (string-append
                    "ece-serve: :dev-token must be a non-empty string, got "
                    (ece-serve/%show val))))))
         (else
          (error (string-append "ece-serve: unknown option "
                                (ece-serve/%show key))))))))))

(define (ece-serve entry-file . opts)
  "Start the dev server for ENTRY-FILE. Blocks until interrupted.
Options: :port (default 8080), :poll-interval (milliseconds, default 250),
and :dev-token (generated by default)."
  (cond
   ((not (%file-exists? entry-file))
    (error (string-append "ece-serve: entry file does not exist: " entry-file)))
   ((not (has-extension? entry-file "scm"))
    (error (string-append "ece-serve: entry file must be a .scm source file: "
                          entry-file)))
   (else
    (let* ((parsed (ece-serve/parse-options opts))
           (port (car parsed))
           (poll-interval (car (cdr parsed)))
           (dev-token (car (cdr (cdr parsed))))
           (sched (make-scheduler))
           (watch-set (ece-serve/walk-loads entry-file))
           (clients-box (ece-serve/make-clients-box))
           (server (tcp-listen port "127.0.0.1")))
      (set! *ece-serve/current-port* port)
      (set! *ece-serve/dev-token*
            (if dev-token dev-token (ece-serve/generate-dev-token)))
      (set! *ece-serve/artifact-root*
            (path-join ".tmp/ece-serve-artifacts" (number->string port)))
      (ece-serve/ensure-artifact-root!)
      (ece-serve/write-session-file! entry-file port)
      (display "Dev server: http://127.0.0.1:")
      (display port)
      (display "/")
      (newline)
      (display "Dev token: ")
      (display *ece-serve/dev-token*)
      (newline)
      (display "Watching ")
      (display (length watch-set))
      (display " file(s) from entry: ")
      (display entry-file)
      (newline)
      ;; Register event sources
      (scheduler-register-event-source! sched (ece-serve/make-accept-source server))
      (scheduler-register-event-source! sched (ece-serve/make-read-source))
      (scheduler-register-event-source! sched (ece-serve/make-timer-source))
      ;; Spawn the long-lived fibers
      (scheduler-spawn! sched
                        (lambda () (ece-serve/accept-loop sched server clients-box)))
      (scheduler-spawn! sched
                        (lambda ()
                          (ece-serve/watch-loop sched watch-set clients-box
                                                poll-interval entry-file)))
      ;; Run forever (until interrupted)
      (scheduler-run! sched)
      (tcp-close server)))))

;; ---- CLI entry point ----

(define (ece-serve-main argv)
  "CLI entry dispatched from src/ece-main.scm when argv[0] is ece-serve.
Parses --port / --poll-interval flags and a positional entry file,
then calls (ece-serve). Unknown flags print an error and exit."
  (let loop ((rest argv) (port *ece-serve/default-port*)
             (interval *ece-serve/default-poll-interval-ms*)
             (dev-token #f)
             (entry #f))
    (cond
     ((null? rest)
      (cond
       ((not entry)
        (display "Usage: ece-serve <entry.scm> [--port N] [--poll-interval N] [--dev-token TOKEN]")
        (newline)
        (exit 2))
       (else
        (ece-serve entry ':port port ':poll-interval interval ':dev-token
                   (if dev-token dev-token (ece-serve/generate-dev-token))))))
     (else
      (let ((arg (car rest)))
        (cond
         ((string=? arg "--port")
          (cond
           ((null? (cdr rest))
            (display "Error: --port requires an argument") (newline)
            (exit 2))
           (else
            (let ((n (string->number (car (cdr rest)))))
              (cond
               ((or (not n) (not (integer? n)) (< n 1) (> n 65535))
                (display "Error: --port value must be an integer in [1, 65535]")
                (newline)
                (exit 2))
               (else (loop (cdr (cdr rest)) n interval dev-token entry)))))))
         ((string=? arg "--poll-interval")
          (cond
           ((null? (cdr rest))
            (display "Error: --poll-interval requires an argument") (newline)
            (exit 2))
           (else
            (let ((n (string->number (car (cdr rest)))))
              (cond
               ((or (not n) (not (integer? n)) (< n 0))
                (display "Error: --poll-interval value must be an integer >= 0")
                (newline)
                (exit 2))
               (else (loop (cdr (cdr rest)) port n dev-token entry)))))))
         ((string=? arg "--dev-token")
          (cond
           ((null? (cdr rest))
            (display "Error: --dev-token requires an argument") (newline)
            (exit 2))
           ((= (string-length (car (cdr rest))) 0)
            (display "Error: --dev-token value must be non-empty")
            (newline)
            (exit 2))
           (else
            (loop (cdr (cdr rest)) port interval (car (cdr rest)) entry))))
         ((or (string=? arg "-h") (string=? arg "--help"))
          (display "Usage: ece-serve <entry.scm> [--port N] [--poll-interval N] [--dev-token TOKEN]")
          (newline)
          (display "  Dev server for ECE programs. Serves sandbox static assets")
          (newline)
          (display "  and broadcasts program-reload messages over WebSocket when")
          (newline)
          (display "  watched files change.")
          (newline)
          (exit 0))
         ((starts-with? arg "-")
          (display "Error: unknown option: ") (display arg) (newline)
          (exit 2))
         (else
          (loop (cdr rest) port interval dev-token arg))))))))

;; No custom gensym / intern helpers — ECE's prelude gensym is nullary
;; and returns a unique symbol, and literal quoted symbols in this file
;; resolve to the same :ece-package symbols that the CL-side primitives
;; intern via (intern "name" :ece).
