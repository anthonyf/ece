;;; json.scm — Minimal JSON encoder for ece-serve's source-update envelope.
;;;
;;; Scope: encoder only, no decoder. Supports the value types the dev
;;; server's WebSocket broadcast needs — strings (with full RFC 8259
;;; string escaping for the ASCII control range plus `"`, `\`, `\n`,
;;; `\r`, `\t`, `\b`, `\f`), integers, booleans (#t / #f), JSON null
;;; (the keyword :null or the symbol 'null), arrays (Scheme lists), and
;;; objects (alists with string keys). Unicode beyond ASCII is
;;; emitted as-is — the dev server's traffic is UTF-8 source text, and
;;; RFC 8259 permits UTF-8 literals in strings.
;;;
;;; ─────────────────────────────────────────────────────────────────────
;;; API
;;; ─────────────────────────────────────────────────────────────────────
;;;
;;;  (json-encode v)
;;;      — encode VALUE as a JSON string. Dispatches on type:
;;;        string → quoted + escaped
;;;        integer → decimal representation
;;;        #t / #f → "true" / "false"
;;;        'null / :null / '() (R7RS empty list used as JSON null) → "null"
;;;        pair whose CAR is a pair → object (alist)
;;;        pair whose CAR is not a pair → array (list)
;;;
;;;        Note: the disambiguation of empty list vs empty array uses
;;;        '() for null and a single-element list like '("foo") for an
;;;        array. If a caller wants to force "[]" they must call
;;;        json-encode-array directly on '().
;;;
;;;  (json-encode-string s)   — quote and escape a string literal
;;;  (json-encode-object alist) — encode an alist as a JSON object
;;;  (json-encode-array list)  — encode a list as a JSON array

;; ---- String escaping ----

(define (%json-escape-char ch port)
  "Write the JSON-escaped form of CH to PORT. Handles the six named
escapes plus the ASCII control range via \\u00XX, and passes through
non-control characters verbatim."
  (let ((code (char->integer ch)))
    (cond
     ((= code 34)  (display "\\\"" port))  ; "
     ((= code 92)  (display "\\\\" port))  ; \
     ((= code 8)   (display "\\b" port))   ; backspace
     ((= code 9)   (display "\\t" port))   ; tab
     ((= code 10)  (display "\\n" port))   ; LF
     ((= code 12)  (display "\\f" port))   ; FF
     ((= code 13)  (display "\\r" port))   ; CR
     ((< code 32)
      ;; Control character: emit \u00XX via a two-digit hex string.
      (display "\\u00" port)
      (display (%json-hex-byte code) port))
     (else
      (write-char ch port)))))

(define (%json-hex-byte n)
  "Return a two-character lowercase hex string for byte N in [0, 255]."
  (string-append (%json-hex-nibble (quotient n 16))
                 (%json-hex-nibble (modulo n 16))))

(define (%json-hex-nibble n)
  "Return a one-character hex string for a nibble in [0, 15]."
  (cond
   ((< n 10) (string (integer->char (+ 48 n))))          ; 0-9 → '0'-'9'
   (else (string (integer->char (+ 97 (- n 10)))))))     ; 10-15 → 'a'-'f'

(define (json-encode-string s)
  "Encode string S as a JSON string literal: surrounded by double quotes
with required characters escaped. The result is an ASCII-safe string
that can be concatenated into a larger JSON document."
  (let ((out (open-output-string)))
    (write-char #\" out)
    (let ((len (string-length s)))
      (let loop ((i 0))
        (cond
         ((>= i len) (write-char #\" out) (get-output-string out))
         (else
          (%json-escape-char (string-ref s i) out)
          (loop (+ i 1))))))))

;; ---- Value-type dispatch ----

(define (json-encode v)
  "Encode V as a JSON string. See module header for the supported value
types. Object-vs-array dispatch rule: if V's first element is itself
a pair whose CAR is a string (i.e. an alist entry like (\"key\" . val)
or (\"key\" val1 val2)), V is encoded as an object; any other pair
encodes as an array. Callers that want to force an empty `[]` or `{}`
must call `json-encode-array` or `json-encode-object` directly on '()
— bare '() in json-encode produces `\"null\"`.

Rejects non-integer numbers (floats) with an error — the module is
scoped to the value types the ece-serve source-update envelope needs,
and floats introduce formatting ambiguity (inf/NaN, precision, etc.)
that isn't worth resolving in a dev-server JSON encoder."
  (cond
   ((eq? v #t) "true")
   ((eq? v #f) "false")
   ((null? v) "null")
   ((eq? v 'null) "null")
   ((string? v) (json-encode-string v))
   ((integer? v) (number->string v))
   ((number? v)
    (error "json-encode: non-integer numbers are out of scope for this encoder"))
   ((pair? v)
    (if (%json-looks-like-alist? v)
        (json-encode-object v)
        (json-encode-array v)))
   (else
    (error (string-append "json-encode: unsupported value type — "
                          (write-to-string-safe v))))))

(define (%json-looks-like-alist? v)
  "Test whether V's first element is a pair (dotted or proper) whose
CAR is a string. This distinguishes alists like `(('key' . 1))` or
`(('key' 1 2))` — encoded as objects — from plain lists of lists like
`((1 2) (3 4))`, whose first element is a pair but whose CAR is an
integer and so falls through to array encoding."
  (and (pair? v)
       (pair? (car v))
       (string? (car (car v)))))

(define (json-encode-array items)
  "Encode ITEMS (a list) as a JSON array."
  (let ((out (open-output-string)))
    (write-char #\[ out)
    (let loop ((rest items) (first? #t))
      (cond
       ((null? rest)
        (write-char #\] out)
        (get-output-string out))
       (else
        (when (not first?) (write-char #\, out))
        (display (json-encode (car rest)) out)
        (loop (cdr rest) #f))))))

(define (json-encode-object alist)
  "Encode ALIST (a list of (string . value) pairs) as a JSON object.
Keys must be strings; non-string keys raise an error."
  (let ((out (open-output-string)))
    (write-char #\{ out)
    (let loop ((rest alist) (first? #t))
      (cond
       ((null? rest)
        (write-char #\} out)
        (get-output-string out))
       (else
        (let* ((entry (car rest))
               (key (car entry))
               (value (cdr entry)))
          (when (not (string? key))
            (error "json-encode-object: keys must be strings"))
          (when (not first?) (write-char #\, out))
          (display (json-encode-string key) out)
          (write-char #\: out)
          (display (json-encode value) out)
          (loop (cdr rest) #f)))))))

;; Helper for the ece-serve source-update envelope: used from
;; ece-serve.scm to avoid duplicating the shape in multiple places.
(define (json-source-update path source)
  "Build the JSON envelope {\"type\": \"source-update\", \"path\": PATH,
\"source\": SOURCE} that ece-serve broadcasts over WebSocket on each
file-change event. PATH and SOURCE must be strings."
  (json-encode-object
   (list (cons "type" "source-update")
         (cons "path" path)
         (cons "source" source))))
