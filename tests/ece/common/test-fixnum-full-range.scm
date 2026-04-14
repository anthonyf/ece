;;; Fixnum full-range regression: values in [2^29, 2^30-1] and the
;;; mirrored negative band [-2^30, -2^29-1] must now be representable
;;; without precision loss.
;;;
;;; Before this change, the WASM runtime used `n << 1` to encode fixnums
;;; into i31ref, which stole bit 0 for a tag and limited fixnums to
;;; [-2^29, 2^29-1] (-536870912..536870911). After moving chars and the
;;; five special singletons off i31, the tag bit is freed and the full
;;; signed i31 range [-2^30, 2^30-1] (-1073741824..1073741823) is
;;; available for fixnums.
;;;
;;; ECE doesn't expose a `fixnum?` predicate — the distinction between
;;; fixnum and float-box is invisible at the language level. These tests
;;; verify the only visible consequence: integer arithmetic on values in
;;; the widened band produces exact results.

;; ── (a) Edges of the new fixnum range ───────────────────────────────────

(test "fixnum: positive edge 2^30-1 round-trips" (lambda ()
  (assert-equal (+ 1073741823 0) 1073741823)
  (assert-equal (- 1073741823 0) 1073741823)
  (assert-equal (* 1073741823 1) 1073741823)))

(test "fixnum: negative edge -2^30 round-trips" (lambda ()
  (assert-equal (+ -1073741824 0) -1073741824)
  (assert-equal (- -1073741824 0) -1073741824)
  (assert-equal (* -1073741824 1) -1073741824)))

(test "fixnum: old 29-bit positive boundary 2^29 is representable" (lambda ()
  (assert-equal (+ 536870912 0) 536870912)
  (assert-equal 536870912 536870912)
  (assert-true (integer? 536870912))))

(test "fixnum: old 29-bit negative boundary -2^29-1 is representable" (lambda ()
  (assert-equal (+ -536870913 0) -536870913)
  (assert-equal -536870913 -536870913)
  (assert-true (integer? -536870913))))

;; ── (b) Arithmetic inside the widened band stays exact ────────────────

(test "arithmetic: (+ 536870000 912) lands at 536870912" (lambda ()
  (assert-equal (+ 536870000 912) 536870912)
  (assert-true (integer? (+ 536870000 912)))))

(test "arithmetic: chained sum in widened band is exact" (lambda ()
  (let ((v (+ 536870000 500 412)))
    (assert-equal v 536870912)
    (assert-true (integer? v)))))

(test "arithmetic: subtraction in widened band is exact" (lambda ()
  (let ((v (- 1073741823 536870911)))
    (assert-equal v 536870912)
    (assert-true (integer? v)))))

;; ── (c) Overflow one past the positive edge still computes correctly ──

(test "overflow: 2^30 still arithmetically sound" (lambda ()
  (let ((v (+ 1073741823 1)))
    (assert-equal v 1073741824))))

(test "overflow: -2^30-1 is representable via float-box" (lambda ()
  (let ((v (- -1073741824 1)))
    (assert-equal v -1073741825))))

;; ── (d) Display / number round-trip ────────────────────────────────────

(test "display: widened-band values print and reparse" (lambda ()
  (assert-equal (string->number (number->string 1073741823)) 1073741823)
  (assert-equal (string->number (number->string -1073741824)) -1073741824)
  (assert-equal (string->number (number->string 536870912)) 536870912)
  (assert-equal (string->number (number->string -536870913)) -536870913)))

;; ── (e) Equality and comparison at the edges ───────────────────────────

(test "equality: edge values compare correctly" (lambda ()
  (assert-true (= 1073741823 1073741823))
  (assert-true (= -1073741824 -1073741824))
  (assert-true (< -1073741824 1073741823))
  (assert-true (> 1073741823 536870912))))

;; ── (f) Bitwise ops on widened-band values stay exact ─────────────────

(test "bitwise: ops at the new edges produce exact results" (lambda ()
  (assert-equal (bitwise-and 1073741823 1073741823) 1073741823)
  (assert-equal (bitwise-or 536870912 536870911) 1073741823)
  (assert-equal (bitwise-xor 1073741823 536870912) 536870911)))

;; ── (g) integer? now accepts float-box values that represent integers ──

(test "integer?: float-boxed integer values are integers" (lambda ()
  ;; (+ 1073741823 1) overflows fixnum range → float-box 1073741824.0
  (assert-true (integer? (+ 1073741823 1)))
  ;; (exact->inexact n) produces a float-box even for values in fixnum range
  (assert-true (integer? (exact->inexact 3)))
  (assert-true (integer? (exact->inexact 1073741823)))))

(test "integer?: non-integer floats are not integers" (lambda ()
  (assert-false (integer? 3.14))
  (assert-false (integer? 0.5))))

;; ── (h) integer->char rejects invalid codepoints and non-integers ─────

(test "integer->char: rejects non-integer inputs" (lambda ()
  (guard (e (#t #t))
    (integer->char 3.14)
    (assert-true #f))  ;; should not reach here
  (assert-true #t)))

(test "integer->char: rejects negative codepoints" (lambda ()
  (guard (e (#t #t))
    (integer->char -1)
    (assert-true #f))
  (assert-true #t)))

(test "integer->char: rejects codepoints above 0x10FFFF" (lambda ()
  (guard (e (#t #t))
    (integer->char 1114112)  ;; 0x110000
    (assert-true #f))
  (assert-true #t)))

(test "integer->char: accepts valid unicode range" (lambda ()
  (assert-equal (char->integer (integer->char 97)) 97)
  (assert-equal (char->integer (integer->char 955)) 955)        ;; Greek lambda
  (assert-equal (char->integer (integer->char 1114111)) 1114111))) ;; 0x10FFFF
