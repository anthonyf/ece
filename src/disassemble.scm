;;; ECE Disassembler
;;; Prints the register-machine instructions of a compiled procedure to
;;; the current output port. Supports compiled-procedure values, bare
;;; code-objects, and symbols (resolved as global bindings).

(define (dis/spaces n)
  (if (<= n 0) "" (string-append " " (dis/spaces (- n 1)))))

(define (dis/pad-left s width)
  (let ((len (string-length s)))
    (if (>= len width) s
        (string-append (dis/spaces (- width len)) s))))

(define (dis/max-width pcs)
  (let loop ((lst pcs) (w 1))
    (if (null? lst) w
        (loop (cdr lst)
              (max w (string-length (number->string (car lst))))))))

;; Resolve a (goto|branch (label L)) target to a PC via CO's own label
;; table. Returns #f for any other instruction shape (fall-through cases,
;; register-valued gotos, etc.).
(define (dis/co-branch-target-pc co instr)
  (cond
   ((not (pair? instr)) #f)
   ((or (eq? (car instr) 'goto) (eq? (car instr) 'branch))
    (let ((target (cadr instr)))
      (if (and (pair? target) (eq? (car target) 'label))
          (code-object-label-ref co (cadr target))
          #f)))
   (else #f)))

(define (dis/label-target-pc labels instr)
  (cond
   ((not (pair? instr)) #f)
   ((or (eq? (car instr) 'goto) (eq? (car instr) 'branch))
    (let ((target (cadr instr)))
      (if (and (pair? target) (eq? (car target) 'label))
          (let loop ((rest labels))
            (cond
             ((null? rest) #f)
             ((eq? (car (car rest)) (cadr target)) (cdr (car rest)))
             (else (loop (cdr rest)))))
          #f)))
   (else #f)))

(define (dis/hex-digit n)
  (substring "0123456789ABCDEF" n (+ n 1)))

(define (dis/byte->hex b)
  (string-append (dis/hex-digit (quotient b 16))
                 (dis/hex-digit (modulo b 16))))

(define (dis/take-bytes bytes limit)
  (let loop ((rest bytes) (n limit) (acc '()))
    (if (or (null? rest) (= n 0))
        (reverse acc)
        (loop (cdr rest) (- n 1) (cons (car rest) acc)))))

(define (dis/bytes->hex bytes)
  (let ((shown (dis/take-bytes bytes 18)))
    (let loop ((rest shown) (acc ""))
      (if (null? rest)
          (if (> (length bytes) 18)
              (string-append acc " ...")
              acc)
          (loop (cdr rest)
                (if (string=? acc "")
                    (dis/byte->hex (car rest))
                    (string-append acc " " (dis/byte->hex (car rest)))))))))

(define (dis/option options key default)
  (cond
   ((null? options) default)
   ((and (pair? (cdr options)) (eq? (car options) key))
    (cadr options))
   ((null? (cdr options)) default)
   (else (dis/option (cddr options) key default))))

(define (dis/byte-prefix? bytes prefix)
  (cond
   ((null? prefix) #t)
   ((null? bytes) #f)
   ((= (car bytes) (car prefix))
    (dis/byte-prefix? (cdr bytes) (cdr prefix)))
   (else #f)))

(define (dis/file-supported?)
  (and (platform-has? 'open-input-file)
       (platform-has? 'open-binary-input-file)
       (platform-has? 'read-byte)))

(define (dis/entry-name entry)
  (or (archive/plist-get (cdr entry) ':name) '<anonymous>))

(define (dis/entry-labels entry)
  (or (archive/plist-get (cdr entry) ':labels) '()))

(define (dis/entry-instructions entry)
  (or (archive/plist-get (cdr entry) ':instructions) '()))

(define (dis/instruction-count instrs)
  (length instrs))

(define (dis/display-archive-instruction pc instr labels width with-hex?)
  (display " ")
  (display (dis/pad-left (number->string pc) width))
  (display ":  ")
  (when with-hex?
    (let ((hex (dis/bytes->hex (bca/encode-instruction instr))))
      (display (dis/pad-left hex 28))
      (display "  ")))
  (display (write-to-string-flat instr))
  (let ((target (dis/label-target-pc labels instr)))
    (when target
      (display "  ; → pc ")
      (display target)))
  (newline))

(define (dis/disassemble-archive-entry entry index with-hex?)
  (let* ((instrs (dis/entry-instructions entry))
         (labels (dis/entry-labels entry))
         (len (dis/instruction-count instrs))
         (name (dis/entry-name entry))
         (width (dis/max-width (if (= len 0) '(0) (list (- len 1))))))
    (display "; entry ")
    (display index)
    (display ", ")
    (display name)
    (display "  (code-object, ")
    (display len)
    (display " instructions)")
    (newline)
    (let loop ((pc 0) (rest instrs))
      (when (pair? rest)
        (for-each (lambda (label)
                    (when (= (cdr label) pc)
                      (display "(label ")
                      (display (car label))
                      (display ")")
                      (newline)))
                  labels)
        (dis/display-archive-instruction
         pc (car rest) labels width with-hex?)
        (loop (+ pc 1) (cdr rest))))))

(define (dis/display-archive-section archive with-hex?)
  (let* ((fields (cdr archive))
         (file (archive/plist-get fields ':file))
         (unit-id (archive/plist-get fields ':unit-id))
         (kind (archive/plist-get fields ':kind))
         (entries (or (archive/plist-get fields ':entries) '())))
    (display "; archive ")
    (if file (display file) (display "<unknown>"))
    (when unit-id
      (display ", unit ")
      (display (write-to-string-flat unit-id)))
    (when kind
      (display ", kind ")
      (display kind))
    (display ", ")
    (display (length entries))
    (display " code objects")
    (newline)
    (let loop ((idx 0) (rest entries))
      (when (pair? rest)
        (dis/disassemble-archive-entry (car rest) idx with-hex?)
        (loop (+ idx 1) (cdr rest))))))

(define (dis/read-text-archives path)
  (let ((port (open-input-file path)))
    (let loop ((acc '()))
      (let ((archive (read-archive-section-form port)))
        (if (eof? archive)
            (begin
              (close-input-port port)
              (reverse acc))
            (loop (cons archive acc)))))))

(define (dis/read-binary-file-if-magic path)
  (let ((port (open-binary-input-file path))
        (magic-len (length bca/magic-bytes)))
    (let read-prefix ((n magic-len) (acc '()))
      (if (= n 0)
          (let ((prefix (reverse acc)))
            (if (dis/byte-prefix? prefix bca/magic-bytes)
                (let read-rest ((bytes acc))
                  (let ((b (read-byte port)))
                    (if (eof? b)
                        (begin
                          (close-input-port port)
                          (cons #t (reverse bytes)))
                        (read-rest (cons b bytes)))))
                (begin
                  (close-input-port port)
                  (cons #f '()))))
          (let ((b (read-byte port)))
            (if (eof? b)
                (begin
                  (close-input-port port)
                  (cons #f '()))
                (read-prefix (- n 1) (cons b acc))))))))

(define (dis/read-file-archives path)
  (let ((binary-file (dis/read-binary-file-if-magic path)))
    (if (car binary-file)
        (let* ((decoded (bca/read-archive (cdr binary-file)))
               (sections (archive/plist-get (cdr (car decoded)) ':sections)))
          (cons #t sections))
        (cons #f (dis/read-text-archives path)))))

;; §10: code-object disassembler — trivial iteration, no reachability walk
;; needed because the code-object's instructions ARE the procedure's body.
(define (dis/disassemble-code-object co)
  (let* ((len (code-object-length co))
         (instrs (code-object-instructions co))
         (label-entries (code-object-label-entries co))
         (name (or (code-object-name co) '<anonymous>))
         (width (dis/max-width (if (= len 0) '(0) (list (- len 1))))))
    (display "; ")
    (display name)
    (display "  (code-object, ")
    (display len)
    (display " instructions)")
    (newline)
    (let loop ((pc 0))
      (when (< pc len)
        ;; Inline labels at this pc
        (for-each (lambda (entry)
                    (when (= (cdr entry) pc)
                      (display "(label ")
                      (display (car entry))
                      (display ")")
                      (newline)))
                  label-entries)
        (let ((instr (vector-ref instrs pc)))
          (display " ")
          (display (dis/pad-left (number->string pc) width))
          (display ":  ")
          (display (write-to-string-flat instr))
          (let ((target (dis/co-branch-target-pc co instr)))
            (when target
              (display "  ; → pc ")
              (display target)))
          (newline))
        (loop (+ pc 1))))))

;; Disassemble a compiled procedure. Phase G1 retired the legacy
;; (space-id . pc) closure entry — every compiled procedure now carries a
;; code-object (either bare or paired with a PC), so the reachability walk
;; that used to handle the space-keyed case is gone.
(define (dis/disassemble-compiled proc)
  (let ((entry (compiled-procedure-entry proc)))
    (cond
     ;; §7.1 shape: bare code-object entry.
     ((code-object? entry) (dis/disassemble-code-object entry))
     ;; Transitional (code-obj . pc) shape.
     ((and (pair? entry) (code-object? (car entry)))
      (dis/disassemble-code-object (car entry)))
     (else
      (display "; unrecognized compiled-procedure entry shape: ")
      (display (write-to-string-flat entry))
      (newline)))))

(define (dis/report-non-compiled val name)
  (let ((show (or name (write-to-string-flat val))))
    (cond
     ((primitive? val)
      (display "; ")
      (display show)
      (display " is a host primitive; no bytecode available.")
      (newline))
     ((continuation? val)
      (display "; ")
      (display show)
      (display " is a continuation; disassembling continuations is not supported.")
      (newline))
     (else
      (display "; ")
      (display show)
      (display " is not a compiled procedure.")
      (newline)))))

(define (dis/lookup-global sym)
  (let ((ht (cdr (%global-env-frame))))
    (if (%eq-hash-has-key? ht sym)
        (cons #t (%eq-hash-ref ht sym))
        (cons #f #f))))

;; `disassemble` reaches into `*global-env*` via `(cdr (%global-env-frame))`
;; and `%eq-hash-has-key?`/`%eq-hash-keys` — all CL-only today. On other
;; runtimes we print a clear "not supported" message instead of erroring.
(define (dis/supported?)
  (and (platform-has? '%eq-hash-has-key?)
       (platform-has? '%eq-hash-keys)))

(define (disassemble x)
  (cond
   ((not (dis/supported?))
    (display "; disassemble: not supported on this runtime (requires CL host)")
    (newline))
   ;; §10: accept code-objects directly.
   ((code-object? x) (dis/disassemble-code-object x))
   ((compiled-procedure? x) (dis/disassemble-compiled x))
   ((symbol? x)
    (let ((lookup (dis/lookup-global x)))
      (cond
       ((not (car lookup))
        (display "; no global binding for ")
        (display x)
        (newline))
       ((compiled-procedure? (cdr lookup))
        (dis/disassemble-compiled (cdr lookup)))
       (else (dis/report-non-compiled (cdr lookup) x)))))
   (else (dis/report-non-compiled x #f))))

(define (disassemble-file path . options)
  "Disassemble a printed or binary .ecec archive file.
Pass :with-hex #t to include encoded instruction bytes for binary archives."
  (if (not (dis/file-supported?))
      (begin
        (display "; disassemble-file: not supported on this runtime (requires file I/O)")
        (newline))
      (let* ((with-hex? (dis/option options ':with-hex #f))
             (decoded (dis/read-file-archives path))
             (binary? (car decoded))
             (archives (cdr decoded)))
        (display "; disassemble-file ")
        (display path)
        (display (if binary? " (binary .ecec)" " (printed .ecec)"))
        (newline)
        (let loop ((rest archives))
          (when (pair? rest)
            (dis/display-archive-section
             (car rest)
             (and binary? with-hex?))
            (loop (cdr rest)))))))
