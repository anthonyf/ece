;;; Variadic dispatch for bitwise-and, bitwise-or, and bitwise-xor.
;;;
;;; The CL side implements these primitives as (cl:apply cl:logand ...)
;;; which is genuinely variadic. Prior to the wasm-variadic-bitwise-ops
;;; change, the WASM runtime's primitive dispatch for 76/77/78 only read
;;; arg1 and arg2 from the args list, silently dropping the third and
;;; subsequent arguments. This caused SHA-1 to produce wrong digests for
;;; any input whose message schedule happened to include a 3- or 4-way
;;; XOR — which is every input. PR #150 shipped a nested-binary
;;; workaround in src/sha1.scm; this test file is the regression net
;;; that ensures the underlying dispatch now handles any arg count.
;;;
;;; Coverage rubric for each primitive:
;;;   - 0 args  (identity element)
;;;   - 1 arg   (returns the argument)
;;;   - 2 args  (matches prior binary behaviour)
;;;   - 3 args  (catches the silent-drop bug)
;;;   - 4 args  (SHA-1 message-schedule shape)
;;;   - mixed fixnum + float-box inputs
;;;   - large unsigned values compared via byte extraction for portability

;; ── bitwise-and ─────────────────────────────────────────────────────────

(test "bitwise-and: zero args returns identity -1" (lambda ()
  (assert-equal (bitwise-and) -1)))

(test "bitwise-and: one arg returns the arg" (lambda ()
  (assert-equal (bitwise-and 42) 42)
  (assert-equal (bitwise-and 0) 0)
  (assert-equal (bitwise-and -1) -1)))

(test "bitwise-and: two args matches prior binary behaviour" (lambda ()
  (assert-equal (bitwise-and 12 10) 8)
  (assert-equal (bitwise-and 255 15) 15)))

(test "bitwise-and: three args folds correctly" (lambda ()
  ;; 7 & 11 & 13 = 0b0111 & 0b1011 & 0b1101 = 0b0001 = 1
  (assert-equal (bitwise-and 7 11 13) 1)
  ;; All bits present in each
  (assert-equal (bitwise-and 255 255 255) 255)
  ;; One arg zeroes the result
  (assert-equal (bitwise-and 255 0 255) 0)))

(test "bitwise-and: four args folds correctly" (lambda ()
  ;; 0xFF & 0x0F & 0x07 & 0x03 = 0x03 = 3
  (assert-equal (bitwise-and 255 15 7 3) 3)))

(test "bitwise-and: mixed fixnum + large-positive float-box (3 args)" (lambda ()
  ;; 0x5A827999 & 0xFFFF & 0xFF = 0x99 = 153
  (assert-equal (bitwise-and 1518500249 65535 255) 153)))

;; ── bitwise-or ──────────────────────────────────────────────────────────

(test "bitwise-or: zero args returns identity 0" (lambda ()
  (assert-equal (bitwise-or) 0)))

(test "bitwise-or: one arg returns the arg" (lambda ()
  (assert-equal (bitwise-or 42) 42)
  (assert-equal (bitwise-or 0) 0)
  (assert-equal (bitwise-or -1) -1)))

(test "bitwise-or: two args matches prior binary behaviour" (lambda ()
  (assert-equal (bitwise-or 12 10) 14)
  (assert-equal (bitwise-or 0 255) 255)))

(test "bitwise-or: three args folds correctly" (lambda ()
  ;; 1 | 2 | 4 = 7
  (assert-equal (bitwise-or 1 2 4) 7)
  ;; Each arg contributes its own byte
  (assert-equal (bitwise-or 1 256 65536) 65793)))

(test "bitwise-or: four args folds correctly" (lambda ()
  ;; 1 | 2 | 4 | 8 = 15
  (assert-equal (bitwise-or 1 2 4 8) 15)))

(test "bitwise-or: mixed fixnum + float-box (3 args)" (lambda ()
  ;; 0x01000000 | 0x00010000 | 0x00000100 = 0x01010100 = 16843008
  (assert-equal (bitwise-or 16777216 65536 256) 16843008)))

;; ── bitwise-xor ─────────────────────────────────────────────────────────

(test "bitwise-xor: zero args returns identity 0" (lambda ()
  (assert-equal (bitwise-xor) 0)))

(test "bitwise-xor: one arg returns the arg" (lambda ()
  (assert-equal (bitwise-xor 42) 42)
  (assert-equal (bitwise-xor 0) 0)
  (assert-equal (bitwise-xor -1) -1)))

(test "bitwise-xor: two args matches prior binary behaviour" (lambda ()
  (assert-equal (bitwise-xor 12 10) 6)
  (assert-equal (bitwise-xor 255 255) 0)))

(test "bitwise-xor: three args folds correctly (the pre-fix bug)" (lambda ()
  ;; 5 XOR 3 = 6, then 6 XOR 6 = 0. Pre-fix WASM silently dropped the
  ;; third argument and returned 6.
  (assert-equal (bitwise-xor 5 3 6) 0)
  ;; A canonical 3-way XOR: a XOR a XOR b = b.
  (assert-equal (bitwise-xor 42 42 77) 77)))

(test "bitwise-xor: four args folds correctly" (lambda ()
  ;; 1 XOR 2 XOR 4 XOR 8 — disjoint bits — = 15
  (assert-equal (bitwise-xor 1 2 4 8) 15)
  ;; Pairs cancel: (a XOR b XOR a XOR b) = 0
  (assert-equal (bitwise-xor 123 456 123 456) 0)))

;; ── SHA-1 message-schedule shape ────────────────────────────────────────
;; The four SHA-1 round constants, XORed together, produce a bit pattern
;; whose byte-wise representation is portable across runtimes even when
;; the intermediate i32 value has bit 31 set. Compare via byte extraction.

(test "bitwise-xor: 4-way XOR of SHA-1 round constants (byte check)" (lambda ()
  ;; 0x5A827999 XOR 0x6ED9EBA1 XOR 0x8F1BBCDC XOR 0xCA62C1D6
  ;;   = 0x345B9238 XOR 0x8F1BBCDC = 0xBB402EE4
  ;;   = 0xBB402EE4 XOR 0xCA62C1D6 = 0x7122EF32
  ;; Bytes LSB-first: 0x32, 0xEF, 0x22, 0x71 = 50, 239, 34, 113.
  (let ((v (bitwise-xor 1518500249 1859775393 2400959708 3395469782)))
    (assert-equal (bitwise-and v 255) 50)
    (assert-equal (bitwise-and (arithmetic-shift v -8) 255) 239)
    (assert-equal (bitwise-and (arithmetic-shift v -16) 255) 34)
    (assert-equal (bitwise-and (arithmetic-shift v -24) 255) 113))))

(test "bitwise-xor: 3-way XOR used in sha1/f rounds 20-39 shape" (lambda ()
  ;; Canonical SHA-1 f2/f4: (b XOR c XOR d). Check bytes so the test is
  ;; portable even when the i32 result has bit 31 set.
  ;; 0x67452301 XOR 0xEFCDAB89 XOR 0x98BADCFE
  ;;   = 0x88888888 XOR 0x98BADCFE = 0x10325476
  ;; Bytes LSB-first: 0x76, 0x54, 0x32, 0x10 = 118, 84, 50, 16.
  (let ((v (bitwise-xor 1732584193 4023233417 2562383102)))
    (assert-equal (bitwise-and v 255) 118)
    (assert-equal (bitwise-and (arithmetic-shift v -8) 255) 84)
    (assert-equal (bitwise-and (arithmetic-shift v -16) 255) 50)
    (assert-equal (bitwise-and (arithmetic-shift v -24) 255) 16))))
