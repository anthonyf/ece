;;; Disassembler tests — disassemble of compiled procedures, symbols,
;;; primitives, non-procedures, and inner-lambda exclusion.

(define (dis-capture thunk)
  (with-output-to-string (thunk)))

(define (dis-write-text-file path text)
  (let ((port (open-output-file path)))
    (display text port)
    (close-output-port port)))

(define (dis-compile-archive source file)
  (code-object->archive-sexp
   (mc-compile-to-code-object (read (open-input-string source)))
   file))

(define (dis-with-temp-file path thunk)
  (dynamic-wind
    (lambda () #f)
    thunk
    (lambda ()
      ;; Best effort cleanup: overwrite with a tiny text file so repeated
      ;; local runs do not reuse stale binary contents if deletion is absent.
      (dis-write-text-file path ""))))

;; Shared fixture procedure used across several tests.
(define (dis-test-square x) (* x x))

(test "disassemble compiled procedure prints header and instructions" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble dis-test-square)))))
    (assert-true (string-contains? out "dis-test-square"))
    (assert-true (string-contains? out "(assign"))
    (assert-true (> (string-length out) 100)))))

(test "disassemble by symbol equals disassemble by value" (lambda ()
  (let ((by-value (dis-capture (lambda () (disassemble dis-test-square))))
        (by-symbol (dis-capture (lambda () (disassemble 'dis-test-square)))))
    (assert-equal by-value by-symbol))))

(test "disassemble unbound symbol reports missing binding" (lambda ()
  (let ((out (dis-capture
              (lambda () (disassemble 'dis-no-such-symbol-exists)))))
    (assert-true (string-contains? out "no global binding"))
    (assert-true (string-contains? out "dis-no-such-symbol-exists")))))

(test "disassemble primitive by symbol reports primitive" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble 'car)))))
    (assert-true (string-contains? out "primitive"))
    (assert-true (string-contains? out "car")))))

(test "disassemble primitive by value reports primitive" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble car)))))
    (assert-true (string-contains? out "primitive")))))

(test "disassemble integer reports not-a-procedure" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble 42)))))
    (assert-true (string-contains? out "not a compiled procedure"))
    (assert-true (string-contains? out "42")))))

(test "disassemble string reports not-a-procedure" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble "hello")))))
    (assert-true (string-contains? out "not a compiled procedure")))))

;; Inner-lambda exclusion: the outer body's reached set must skip over
;; instructions that belong only to the inner lambda.
(define (dis-test-outer)
  (let ((f (lambda (x) (cons x 'dis-inner-sentinel-value))))
    (f 1)))

(test "disassemble excludes inner lambda body" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble dis-test-outer)))))
    ;; The inner lambda puts 'dis-inner-sentinel-value as a (const ...)
    ;; into the instruction vector. Reachability should skip the inner
    ;; body, so this sentinel symbol should NOT appear on an instruction
    ;; line (it may appear in "unreached labels in span" if its label
    ;; falls inside the span, but not in an instruction).
    (assert-true (not (string-contains? out "dis-inner-sentinel-value"))))))

(test "disassemble annotates branch targets with PC" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble dis-test-square)))))
    ;; Square's compiled call dispatch emits branch-with-label; the
    ;; formatter should annotate with "; → pc <N>".
    (assert-true (string-contains? out "→ pc")))))

(test "disassemble emits pc-prefixed instruction lines" (lambda ()
  (let ((out (dis-capture (lambda () (disassemble dis-test-square)))))
    ;; Every disassembly should contain at least one instruction line
    ;; of the form "<pc>:  (...".
    (assert-true (string-contains? out ":  (assign")))))

(test "disassemble-file prints text archive instructions" (lambda ()
  (let ((path ".tmp/disassemble-text.ecec"))
    (dis-with-temp-file
     path
     (lambda ()
       (let ((archive (dis-compile-archive
                       "(begin (define dis-file-text-answer 12) dis-file-text-answer)"
                       "dis-file-text.scm")))
         (dis-write-text-file path (write-to-string-flat archive))
         (let ((out (dis-capture (lambda () (disassemble-file path)))))
           (assert-true (string-contains? out "printed .ecec"))
           (assert-true (string-contains? out "dis-file-text.scm"))
           (assert-true (string-contains? out "; entry 0"))
           (assert-true (string-contains? out ":  (assign")))))))))

(test "disassemble-file prints binary archive instructions" (lambda ()
  (let ((path ".tmp/disassemble-binary.ecec"))
    (dis-with-temp-file
     path
     (lambda ()
       (let* ((archive (dis-compile-archive
                        "(begin (define dis-file-binary-answer 34) dis-file-binary-answer)"
                        "dis-file-binary.scm"))
              (bytes (bca/encode-archive archive)))
         (bca/write-bytes-to-file bytes path)
         (let ((out (dis-capture (lambda () (disassemble-file path)))))
           (assert-true (string-contains? out "binary .ecec"))
           (assert-true (string-contains? out "dis-file-binary.scm"))
           (assert-true (string-contains? out "; entry 0"))
           (assert-true (string-contains? out ":  (assign")))))))))

(test "disassemble-file with hex shows binary instruction bytes" (lambda ()
  (let ((path ".tmp/disassemble-binary-hex.ecec"))
    (dis-with-temp-file
     path
     (lambda ()
       (let* ((archive (dis-compile-archive
                        "(begin (define dis-file-hex-answer 56) dis-file-hex-answer)"
                        "dis-file-hex.scm"))
              (bytes (bca/encode-archive archive)))
         (bca/write-bytes-to-file bytes path)
         (let ((out (dis-capture
                     (lambda () (disassemble-file path ':with-hex #t)))))
           (assert-true (string-contains? out "binary .ecec"))
           (assert-true (string-contains? out " 01 "))
           (assert-true (string-contains? out ":  "))
           (assert-true (string-contains? out "(assign")))))))))
