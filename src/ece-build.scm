;;; ece-build.scm — Build an ECE application for web or CL targets.
;;;
;;; Dispatched via argv[0]=ece-build. Requires sdk-lib.scm + ece-main.scm
;;; to be loaded first (for path helpers and ece-home).

;; ---- File I/O helpers (pure ECE) ----

(define (read-file-as-bytes path)
  "Read PATH as a list of bytes (0-255) in order."
  (let ((port (open-binary-input-file path)))
    (let loop ((acc '()))
      (let ((b (read-byte port)))
        (if (eof? b)
            (begin (close-input-port port) (reverse acc))
            (loop (cons b acc)))))))

(define (copy-file-binary src dst)
  "Copy SRC to DST byte-for-byte. Works for binary files."
  (let ((in (open-binary-input-file src))
        (out (open-binary-output-file dst)))
    (let loop ()
      (let ((b (read-byte in)))
        (if (eof? b)
            (begin
              (close-input-port in)
              (close-output-port out))
            (begin
              (write-byte b out)
              (loop)))))))

(define (read-file-as-string path)
  "Read PATH as a string (entire contents). Uses an output-string port
to accumulate without quadratic allocation."
  (let ((in (open-input-file path))
        (sp (open-output-string)))
    (let loop ()
      (let ((ch (read-char in)))
        (cond
         ((eof? ch)
          (close-input-port in)
          (get-output-string sp))
         (else
          (%write-char-to-port ch sp)
          (loop)))))))

(define (write-string-to-file str path)
  "Write STR to PATH (overwriting)."
  (let ((out (open-output-file path)))
    (display str out)
    (close-output-port out)))

(define (copy-file-text src dst)
  "Copy SRC to DST via read-char/write-char, streaming (no full load)."
  (let ((in (open-input-file src))
        (out (open-output-file dst)))
    (let loop ()
      (let ((ch (read-char in)))
        (cond
         ((eof? ch)
          (close-input-port in)
          (close-output-port out))
         (else
          (%write-char-to-port ch out)
          (loop)))))))

(define (list->string chars)
  "Convert a list of characters to a string."
  (if (null? chars) ""
      (let ((sp (open-output-string)))
        (for-each (lambda (c) (%write-char-to-port c sp)) chars)
        (get-output-string sp))))

;; ---- Base64 encoding (pure ECE) ----

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

;; ---- Argument parsing ----

(define (parse-build-args argv)
  "Parse ece-build CLI args. Returns
 (list target output-dir standalone? source-files help?) or signals error."
  (let loop ((rest argv)
             (target #f)
             (output-dir #f)
             (standalone? #f)
             (sources '())
             (help? #f))
    (cond
     ((null? rest)
      (list target output-dir standalone? (reverse sources) help?))
     (else
      (let ((arg (car rest)))
        (cond
         ((or (string=? arg "-h") (string=? arg "--help"))
          (loop (cdr rest) target output-dir standalone? sources #t))
         ((string=? arg "--target")
          (if (null? (cdr rest))
              (begin
                (display "Error: --target requires an argument")
                (newline)
                (exit 1))
              (loop (cddr rest) (cadr rest) output-dir standalone? sources help?)))
         ((string=? arg "-o")
          (if (null? (cdr rest))
              (begin
                (display "Error: -o requires an argument")
                (newline)
                (exit 1))
              (loop (cddr rest) target (cadr rest) standalone? sources help?)))
         ((string=? arg "--standalone")
          (loop (cdr rest) target output-dir #t sources help?))
         ((starts-with? arg "-")
          (display "Error: Unknown option: ")
          (display arg)
          (newline)
          (exit 1))
         (else
          (loop (cdr rest) target output-dir standalone? (cons arg sources) help?))))))))

(define (ece-build-usage)
  (display "Usage: ece-build --target web|cl -o <dir> [--standalone] <source.scm> ...")
  (newline)
  (newline)
  (display "Options:")
  (newline)
  (display "  --target web|cl   Target platform (required)")
  (newline)
  (display "  -o <dir>          Output directory (required)")
  (newline)
  (display "  --standalone      Web: base64-encode all assets for file:// use")
  (newline)
  (display "  -h, --help        Show this help")
  (newline)
  (newline)
  (display "Arguments:")
  (newline)
  (display "  <source.scm> ...  One or more .scm source files in dependency order")
  (newline))

(define (validate-build-args target output-dir sources)
  (cond
   ((not target)
    (display "Error: --target is required")
    (newline)
    (ece-build-usage)
    (exit 1))
   ((and (not (string=? target "web")) (not (string=? target "cl")))
    (display "Error: --target must be 'web' or 'cl', got '")
    (display target)
    (display "'")
    (newline)
    (exit 1))
   ((not output-dir)
    (display "Error: -o is required")
    (newline)
    (ece-build-usage)
    (exit 1))
   ((null? sources)
    (display "Error: At least one source .scm file is required")
    (newline)
    (ece-build-usage)
    (exit 1)))
  ;; Validate source files exist
  (for-each
   (lambda (f)
     (when (not (%file-exists? f))
       (display "Error: Source file not found: ")
       (display f)
       (newline)
       (exit 1)))
   sources))

;; ---- Target: web ----

(define (generate-runtime-js home output-dir embedded-wasm?)
  "Write ece-runtime.js to OUTPUT-DIR. If EMBEDDED-WASM? is #t, includes
the WASM binary as a base64 constant (standalone mode)."
  (let* ((glue-path (path-join home "glue.js"))
         (prims-path (path-join home "primitives.json"))
         (wasm-path (path-join home "runtime.wasm"))
         (out-path (path-join output-dir "ece-runtime.js"))
         (prims-text (read-file-as-string prims-path))
         (glue-text (read-file-as-string glue-path))
         ;; Strip `module.exports = ...` lines and replace require('./primitives.json')
         (glue-cleaned (transform-glue-js glue-text)))
    (let ((out (open-output-file out-path)))
      (display "// ECE Runtime — auto-generated by ece-build" out)
      (newline out)
      (display "const ECE_PRIMITIVES = " out)
      (display prims-text out)
      (display ";" out)
      (newline out)
      (display glue-cleaned out)
      (newline out)
      (when embedded-wasm?
        (display "// runtime.wasm as base64" out)
        (newline out)
        (display "const ECE_WASM_BASE64 = \"" out)
        (display (file->base64 wasm-path) out)
        (display "\";" out)
        (newline out))
      (close-output-port out))))

(define (transform-glue-js text)
  "Remove module.exports line and substitute require('./primitives.json') ref.
Matches the sed expressions in the original shell script."
  ;; Drop any line containing 'module.exports'
  (let* ((lines (string-split text #\newline))
         (filtered
          (let loop ((ls lines) (acc '()))
            (cond
             ((null? ls) (reverse acc))
             ((string-contains? (car ls) "module.exports")
              (loop (cdr ls) acc))
             (else (loop (cdr ls) (cons (car ls) acc))))))
         (joined (string-join filtered "\n"))
         ;; Substitute require('./primitives.json') → ECE_PRIMITIVES
         (replaced (string-replace joined
                                   "require(\"./primitives.json\")"
                                   "ECE_PRIMITIVES")))
    replaced))

(define (string-replace s from to)
  "Replace every occurrence of FROM in S with TO."
  (let ((flen (string-length from)))
    (if (= flen 0) s
        (let loop ((i 0) (acc ""))
          (cond
           ((> (+ i flen) (string-length s))
            (string-append acc (substring s i (string-length s))))
           ((string=? (substring s i (+ i flen)) from)
            (loop (+ i flen) (string-append acc to)))
           (else
            (loop (+ i 1)
                  (string-append acc (substring s i (+ i 1))))))))))

(define (build-web-standalone home output-dir bundle-path)
  "Package as standalone web app (base64-encoded assets)."
  (display "Packaging for web (standalone)...")
  (newline)
  (let ((template (path-join home "templates" "web" "standalone.html"))
        (bootstrap-file (path-join home "bootstrap.ecec")))
    (when (not (%file-exists? template))
      (display "Error: Template not found: ")
      (display template)
      (newline)
      (exit 1))
    ;; Generate ece-runtime.js with embedded WASM
    (generate-runtime-js home output-dir #t)
    ;; Generate ece-bootstrap.js (bootstrap as base64)
    (let ((out (open-output-file (path-join output-dir "ece-bootstrap.js"))))
      (display "// ECE Bootstrap — auto-generated by ece-build" out)
      (newline out)
      (display "const ECE_BOOTSTRAP_BUNDLE = \"" out)
      (display (file->base64 bootstrap-file) out)
      (display "\";" out)
      (newline out)
      (close-output-port out))
    ;; Generate app.js (user bundle as base64)
    (let ((out (open-output-file (path-join output-dir "app.js"))))
      (display "// App bundle — auto-generated by ece-build" out)
      (newline out)
      (display "const ECE_APP_BUNDLE = \"" out)
      (display (file->base64 bundle-path) out)
      (display "\";" out)
      (newline out)
      (close-output-port out))
    ;; Copy index.html template
    (copy-file-text template (path-join output-dir "index.html"))
    (display "Standalone web app built in ")
    (display output-dir)
    (display "/")
    (newline)))

(define (build-web-server home output-dir bundle-path)
  "Package for web (server mode): raw files for HTTP serving."
  (display "Packaging for web (server mode)...")
  (newline)
  (let ((template (path-join home "templates" "web" "index.html"))
        (bootstrap-file (path-join home "bootstrap.ecec"))
        (wasm-file (path-join home "runtime.wasm")))
    (when (not (%file-exists? template))
      (display "Error: Template not found: ")
      (display template)
      (newline)
      (exit 1))
    (generate-runtime-js home output-dir #f)
    ;; Raw file copies
    (copy-file-binary wasm-file (path-join output-dir "runtime.wasm"))
    (copy-file-text bootstrap-file (path-join output-dir "bootstrap.ecec"))
    (copy-file-text template (path-join output-dir "index.html"))
    (display "Server-mode web app built in ")
    (display output-dir)
    (display "/")
    (newline)))

;; ---- Target: cl ----

(define (build-cl home output-dir bundle-path)
  "Package as CL target: just app.ecec + a run wrapper that execs ece."
  (display "Packaging for CL...")
  (newline)
  (let* ((template (path-join home "templates" "cl" "run.sh"))
         (out-path (path-join output-dir "run")))
    (when (not (%file-exists? template))
      (display "Error: Template not found: ")
      (display template)
      (newline)
      (exit 1))
    (copy-file-text template out-path)
    (%chmod out-path 493)  ; 0o755
    (display "CL app built in ")
    (display output-dir)
    (display "/")
    (newline)
    (display "Run with: ")
    (display output-dir)
    (display "/run")
    (newline)))

;; ---- Main entry point ----

(define (ece-build-main argv)
  "ece-build: compile .scm sources and package for the chosen target."
  (let* ((parsed (parse-build-args argv))
         (target (list-ref parsed 0))
         (output-dir (list-ref parsed 1))
         (standalone? (list-ref parsed 2))
         (sources (list-ref parsed 3))
         (help? (list-ref parsed 4)))
    (when help?
      (ece-build-usage)
      (exit 0))
    (validate-build-args target output-dir sources)
    ;; Ensure output directory exists
    (%make-directory output-dir)
    ;; Compile sources into a bundle
    (let ((bundle-path (path-join output-dir "app.ecec")))
      (display "Compiling ")
      (display (length sources))
      (display " file(s)...")
      (newline)
      (compile-system sources bundle-path)
      (display "Bundle: ")
      (display bundle-path)
      (newline)
      ;; Package for target
      (let ((home (ece-home)))
        (cond
         ((string=? target "web")
          (cond
           (standalone? (build-web-standalone home output-dir bundle-path))
           (else (build-web-server home output-dir bundle-path))))
         ((string=? target "cl")
          (build-cl home output-dir bundle-path)))))))
