;;; Binary compiled archive codec tests.

(test "binary archive codec: header round-trip" (lambda ()
  (let* ((bytes (bca/encode-header 3))
         (decoded (bca/read-header bytes))
         (header (car decoded)))
    (assert-equal (archive/plist-get (cdr header) ':codec-version) 1)
    (assert-equal (archive/plist-get (cdr header) ':archive-version) 2)
    (assert-equal (archive/plist-get (cdr header) ':flags) 0)
    (assert-equal (archive/plist-get (cdr header) ':section-count) 3)
    (assert-equal (cdr decoded) '()))))

(test "binary archive codec: datum round-trip" (lambda ()
  (let* ((datum (list 'alpha
                      -42
                      "hello"
                      #t
                      #f
                      '()
                      (cons 'dotted 7)
                      (vector 'v 12 "x")
                      '(co-ref 2)))
         (decoded (bca/read-datum (bca/encode-datum datum))))
    (assert-equal (car decoded) datum)
    (assert-equal (cdr decoded) '()))))

(test "binary archive codec: rejects malformed datum headers" (lambda ()
  (assert-error-message
   (bca/read-datum (list bca/tag-integer 2 0 0 0 1))
   "bca/read-datum: invalid integer sign byte")
  (assert-error-message
   (bca/read-byte-string (list 0 0 0 5 65))
   "bca/read-byte-string: length exceeds remaining bytes")
  (assert-error-message
   (bca/read-datum (list bca/tag-vector 0 0 0 5 bca/tag-nil))
   "bca/read-datum: vector length exceeds remaining bytes")
  (assert-error-message
   (bca/string->bytes (string (integer->char 256)))
   "bca/string->bytes: binary archives currently support only byte-valued characters")))

(test "binary archive codec: assign instruction round-trip" (lambda ()
  (let* ((instr '(assign val
                         (op lookup-variable-value)
                         (const answer)
                         (reg env)))
         (decoded (bca/read-instruction (bca/encode-instruction instr))))
    (assert-equal (car decoded) instr)
    (assert-equal (cdr decoded) '()))))

(test "binary archive codec: control instruction round-trip" (lambda ()
  (let* ((instrs (list '(test (op false?) (reg val))
                       '(branch (label L1))
                       '(goto (reg continue))
                       '(save env)
                       '(restore env)
                       '(perform (op define-variable!)
                                 (const answer)
                                 (reg val)
                                 (reg env))
                       '(halt))))
    (for-each
     (lambda (instr)
       (let ((decoded (bca/read-instruction (bca/encode-instruction instr))))
         (assert-equal (car decoded) instr)
         (assert-equal (cdr decoded) '())))
     instrs))))

(test "binary archive codec: code-object entry round-trip" (lambda ()
  (let* ((archive (code-object->archive-sexp
                   (mc-compile-to-code-object 42)
                   "binary-entry.scm"))
         (entry (car (archive/plist-get (cdr archive) ':entries)))
         (decoded (bca/read-code-object-entry
                   (bca/encode-code-object-entry entry))))
    (assert-equal (car decoded) entry)
    (assert-equal (cdr decoded) '()))))

(test "binary archive codec: archive section round-trip" (lambda ()
  (let* ((archive (code-object->archive-sexp
                   (mc-compile-to-code-object 42)
                   "binary-section.scm"))
         (decoded (bca/read-archive-section
                   (bca/encode-archive-section archive))))
    (assert-equal (car decoded) archive)
    (assert-equal (cdr decoded) '())
    (assert-equal (load-archive-section-form (car decoded)) 42))))

(test "binary archive codec: archive metadata round-trip" (lambda ()
  (let* ((unit-id '(module (binary archive metadata) 0))
         (metadata (list ':kind ':module
                         ':unit-id unit-id
                         ':phase 0
                         ':imports '((ece base)
                                      (:module (binary dep) :only (answer)))
                         ':exports '(public)
                         ':init 0))
         (archive (code-object->archive-sexp
                   (mc-compile-to-code-object 42)
                   "binary-module.scm"
                   metadata))
         (decoded (bca/read-archive-section
                   (bca/encode-archive-section archive)))
         (fields (cdr (car decoded))))
    (assert-equal (car decoded) archive)
    (assert-equal (archive/plist-get fields ':kind) ':module)
    (assert-equal (archive/plist-get fields ':unit-id) unit-id)
    (assert-equal (archive/plist-get fields ':imports)
                  '((ece base)
                    (:module (binary dep) :only (answer))))
    (assert-equal (archive/plist-get fields ':exports) '(public))
    (assert-equal (cdr decoded) '()))))

(test "binary archive codec: full archive round-trip" (lambda ()
  (let* ((archive (code-object->archive-sexp
                   (mc-compile-to-code-object
                    '(begin (define answer 42) answer))
                   "binary-full.scm"))
         (bytes (bca/encode-archive archive))
         (decoded (bca/read-archive bytes))
         (payload (car decoded))
         (sections (archive/plist-get (cdr payload) ':sections)))
    (assert-equal (archive/plist-get
                   (cdr (archive/plist-get (cdr payload) ':header))
                   ':section-count)
                  1)
    (assert-equal (car sections) archive)
    (assert-equal (cdr decoded) '())
    (assert-equal (load-archive-section-form (car sections)) 42))))

(test "binary archive codec: archive bundle round-trip" (lambda ()
  (let* ((archive-a (code-object->archive-sexp
                     (mc-compile-to-code-object 1)
                     "binary-a.scm"))
         (archive-b (code-object->archive-sexp
                     (mc-compile-to-code-object 2)
                     "binary-b.scm"))
         (decoded (bca/read-archive
                   (bca/encode-archive-bundle (list archive-a archive-b))))
         (payload (car decoded))
         (sections (archive/plist-get (cdr payload) ':sections)))
    (assert-equal (archive/plist-get
                   (cdr (archive/plist-get (cdr payload) ':header))
                   ':section-count)
                  2)
    (assert-equal sections (list archive-a archive-b))
    (assert-equal (cdr decoded) '()))))
