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
