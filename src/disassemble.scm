;;; ECE Disassembler
;;; Prints the reachable register-machine instructions of a compiled
;;; procedure to the current output port. Supports compiled-procedure
;;; values and symbols (resolved as global bindings).

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

(define (dis/insert-sorted n lst)
  (cond ((null? lst) (list n))
        ((< n (car lst)) (cons n lst))
        ((= n (car lst)) lst)
        (else (cons (car lst) (dis/insert-sorted n (cdr lst))))))

(define (dis/sort-ascending lst)
  (if (null? lst) '()
      (dis/insert-sorted (car lst) (dis/sort-ascending (cdr lst)))))

(define (dis/min-of-list lst)
  (let loop ((rest (cdr lst)) (m (car lst)))
    (if (null? rest) m
        (loop (cdr rest) (if (< (car rest) m) (car rest) m)))))

(define (dis/max-of-list lst)
  (let loop ((rest (cdr lst)) (m (car lst)))
    (if (null? rest) m
        (loop (cdr rest) (if (> (car rest) m) (car rest) m)))))

;; Control-flow successors for INSTR at PC within SPACE-ID.
;; Returns a list of target PCs (0, 1, or 2 elements). A missing label
;; target yields the empty list for that branch.
(define (dis/successors space-id pc instr)
  (cond
   ((not (pair? instr)) (list (+ pc 1)))
   ((eq? (car instr) 'goto)
    (let ((target (cadr instr)))
      (if (and (pair? target) (eq? (car target) 'label))
          (let ((dest (%space-label-ref space-id (cadr target))))
            (if dest (list dest) '()))
          '())))
   ((eq? (car instr) 'branch)
    (let ((target (cadr instr))
          (fall (+ pc 1)))
      (if (and (pair? target) (eq? (car target) 'label))
          (let ((dest (%space-label-ref space-id (cadr target))))
            (if dest (list dest fall) (list fall)))
          (list fall))))
   ;; assign / test / save / restore / perform all fall through to pc+1.
   ;; A new instruction head with different control-flow would slip through
   ;; here silently; add an explicit case when one appears.
   (else (list (+ pc 1)))))

;; Reachability walk: returns an eq-hash-table whose keys are the
;; reached PCs (values #t). Bounded by %space-instruction-length.
(define (dis/reached-pcs space-id entry-pc)
  (let ((visited (%eq-hash-table))
        (limit (%space-instruction-length space-id)))
    (define (walk worklist)
      (cond
       ((null? worklist) 'done)
       (else
        (let ((pc (car worklist))
              (rest (cdr worklist)))
          (cond
           ((not (integer? pc)) (walk rest))
           ((< pc 0) (walk rest))
           ((>= pc limit) (walk rest))
           ((%eq-hash-has-key? visited pc) (walk rest))
           (else
            (%eq-hash-set! visited pc #t)
            (let* ((instr (%space-source-ref space-id pc))
                   (succs (dis/successors space-id pc instr)))
              (walk (append succs rest)))))))))
    (walk (list entry-pc))
    visited))

;; Build a PC → list-of-label-names map (as an eq hash) restricted to
;; labels whose PC is in REACHED.
(define (dis/labels-at space-id reached)
  (let ((out (%eq-hash-table)))
    (for-each
     (lambda (pair)
       (let ((name (car pair))
             (pc (cdr pair)))
         (when (%eq-hash-has-key? reached pc)
           (let ((cur (%eq-hash-ref out pc)))
             (%eq-hash-set! out pc
                            (cons name (if cur cur '())))))))
     (%space-label-entries space-id))
    out))

;; Labels whose PC falls in [min,max] of the reached set but which
;; themselves were not reached.
(define (dis/unreached-labels-in-span space-id reached)
  (let* ((pcs (%eq-hash-keys reached))
         (lo (if (null? pcs) 0 (dis/min-of-list pcs)))
         (hi (if (null? pcs) -1 (dis/max-of-list pcs)))
         (unreached '()))
    (for-each
     (lambda (pair)
       (let ((name (car pair))
             (pc (cdr pair)))
         (when (and (>= pc lo) (<= pc hi)
                    (not (%eq-hash-has-key? reached pc)))
           (set! unreached (cons (cons name pc) unreached)))))
     (%space-label-entries space-id))
    unreached))

(define (dis/branch-target-pc space-id instr)
  (cond
   ((not (pair? instr)) #f)
   ((or (eq? (car instr) 'goto) (eq? (car instr) 'branch))
    (let ((target (cadr instr)))
      (if (and (pair? target) (eq? (car target) 'label))
          (%space-label-ref space-id (cadr target))
          #f)))
   (else #f)))

(define (dis/header-name entry)
  (or (%procedure-name-ref entry) "<anonymous>"))

(define (dis/print-header name space-id pc unreached)
  (display "; disassembly of ")
  (display name)
  (display " at ")
  (display space-id)
  (display ":")
  (display pc)
  (newline)
  (unless (null? unreached)
    (display "; unreached labels in span:")
    (for-each
     (lambda (entry)
       (display " ")
       (display (car entry))
       (display "@")
       (display (cdr entry)))
     unreached)
    (newline))
  (display ";")
  (newline))

(define (dis/print-instructions space-id reached labels-at)
  (let* ((pcs (dis/sort-ascending (%eq-hash-keys reached)))
         (width (dis/max-width pcs)))
    (for-each
     (lambda (pc)
       (let ((labels (%eq-hash-ref labels-at pc))
             (instr (%space-source-ref space-id pc)))
         (when labels
           (for-each
            (lambda (label)
              (display (dis/spaces (+ width 2)))
              (display "(label ")
              (display label)
              (display ")")
              (newline))
            labels))
         (display " ")
         (display (dis/pad-left (number->string pc) width))
         (display ":  ")
         (display (write-to-string-flat instr))
         (let ((target (dis/branch-target-pc space-id instr)))
           (when target
             (display "  ; → pc ")
             (display target)))
         (newline)))
     pcs)))

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
                      (display (car entry))
                      (display ":")
                      (newline)))
                  label-entries)
        (display " ")
        (display (dis/pad-left (number->string pc) width))
        (display ":  ")
        (display (write-to-string-flat (vector-ref instrs pc)))
        (newline)
        (loop (+ pc 1))))))

(define (dis/disassemble-compiled proc)
  (let ((entry (compiled-procedure-entry proc)))
    (cond
     ;; §7.1 shape: bare code-object entry.
     ((code-object? entry) (dis/disassemble-code-object entry))
     ;; Transitional (code-obj . pc) shape.
     ((and (pair? entry) (code-object? (car entry)))
      (dis/disassemble-code-object (car entry)))
     ;; Legacy (space-id . pc) — reachability walk.
     (else
      (let* ((space-id (car entry))
             (pc (cdr entry))
             (name (dis/header-name entry))
             (reached (dis/reached-pcs space-id pc))
             (labels-at (dis/labels-at space-id reached))
             (unreached (dis/unreached-labels-in-span space-id reached)))
        (dis/print-header name space-id pc unreached)
        (dis/print-instructions space-id reached labels-at))))))

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
