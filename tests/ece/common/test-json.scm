;;; Unit tests for src/json.scm — minimal JSON encoder used by ece-serve.

;; ── Primitive value encoding ────────────────────────────────────────────

(test "json: booleans and null" (lambda ()
  (assert-equal (json-encode #t) "true")
  (assert-equal (json-encode #f) "false")
  (assert-equal (json-encode '()) "null")
  (assert-equal (json-encode 'null) "null")))

(test "json: integers" (lambda ()
  (assert-equal (json-encode 0) "0")
  (assert-equal (json-encode 42) "42")
  (assert-equal (json-encode -17) "-17")
  (assert-equal (json-encode 1073741823) "1073741823")))

;; ── String escaping ────────────────────────────────────────────────────

(test "json: empty string" (lambda ()
  (assert-equal (json-encode "") "\"\"")))

(test "json: plain ASCII string" (lambda ()
  (assert-equal (json-encode "hello") "\"hello\"")))

(test "json: escape double quote" (lambda ()
  (assert-equal (json-encode "he said \"hi\"")
                "\"he said \\\"hi\\\"\"")))

(test "json: escape backslash" (lambda ()
  (assert-equal (json-encode "a\\b")
                "\"a\\\\b\"")))

(test "json: escape LF and CR" (lambda ()
  ;; Build "line1\nline2\r\nline3" via char building since the reader
  ;; doesn't interpret \r in string literals.
  (let ((s (string-append "line1" (string (integer->char 10))
                          "line2" (string (integer->char 13))
                          (string (integer->char 10)) "line3")))
    (assert-equal (json-encode s)
                  "\"line1\\nline2\\r\\nline3\""))))

(test "json: escape tab and backspace and form-feed" (lambda ()
  (let ((s (string-append (string (integer->char 9))
                          (string (integer->char 8))
                          (string (integer->char 12)))))
    (assert-equal (json-encode s) "\"\\t\\b\\f\""))))

(test "json: low control characters use \\u00XX" (lambda ()
  ;; NUL (0) and bell (7) are low controls that have no named escape.
  (let ((s (string-append (string (integer->char 0))
                          (string (integer->char 7)))))
    (assert-equal (json-encode s) "\"\\u0000\\u0007\""))))

(test "json: char 31 uses \\u001f" (lambda ()
  (assert-equal (json-encode (string (integer->char 31)))
                "\"\\u001f\"")))

(test "json: char 32 (space) is literal" (lambda ()
  (assert-equal (json-encode " ") "\" \"")))

;; ── Arrays ─────────────────────────────────────────────────────────────

(test "json: array of integers" (lambda ()
  (assert-equal (json-encode-array '(1 2 3)) "[1,2,3]")))

(test "json: empty array via json-encode-array" (lambda ()
  ;; json-encode on '() returns null — but explicit json-encode-array
  ;; produces "[]" from an empty list.
  (assert-equal (json-encode-array '()) "[]")))

(test "json: array of strings" (lambda ()
  (assert-equal (json-encode '("a" "b" "c"))
                "[\"a\",\"b\",\"c\"]")))

(test "json: nested arrays" (lambda ()
  (assert-equal (json-encode '((1 2) (3 4)))
                "[[1,2],[3,4]]")))

(test "json: heterogeneous array" (lambda ()
  (assert-equal (json-encode '("hello" 42 #t))
                "[\"hello\",42,true]")))

;; ── Objects ────────────────────────────────────────────────────────────

(test "json: single-key object" (lambda ()
  (assert-equal (json-encode-object '(("name" . "ECE")))
                "{\"name\":\"ECE\"}")))

(test "json: multi-key object preserves alist order" (lambda ()
  (assert-equal (json-encode-object
                 '(("a" . 1) ("b" . 2) ("c" . 3)))
                "{\"a\":1,\"b\":2,\"c\":3}")))

(test "json: nested object" (lambda ()
  (assert-equal (json-encode-object
                 '(("outer" . (("inner" . 42)))))
                "{\"outer\":{\"inner\":42}}")))

(test "json: object with array value" (lambda ()
  (assert-equal (json-encode-object
                 '(("items" . ("a" "b" "c"))))
                "{\"items\":[\"a\",\"b\",\"c\"]}")))

(test "json: empty object" (lambda ()
  (assert-equal (json-encode-object '()) "{}")))

;; ── source-update envelope helper ──────────────────────────────────────

(test "json: source-update envelope" (lambda ()
  (let ((env (json-source-update "game.scm" "(display 1)")))
    (assert-equal env
      "{\"type\":\"source-update\",\"path\":\"game.scm\",\"source\":\"(display 1)\"}"))))

(test "json: source-update envelope escapes special chars in source" (lambda ()
  (let* ((src (string-append "(display \"hi\")"
                             (string (integer->char 10))
                             "(newline)"))
         (env (json-source-update "foo.scm" src)))
    ;; The source contains a literal " and a newline, both must be
    ;; escaped in the JSON envelope.
    (assert-equal env
      "{\"type\":\"source-update\",\"path\":\"foo.scm\",\"source\":\"(display \\\"hi\\\")\\n(newline)\"}"))))

(test "json: eval-source envelope" (lambda ()
  (let ((env (json-eval-source "scratch" "(+ 1 2)")))
    (assert-equal env
      "{\"type\":\"eval-source\",\"path\":\"scratch\",\"source\":\"(+ 1 2)\"}"))))
