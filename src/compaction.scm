;;; ECE Image Compaction
;;; Compacts the instruction vector by removing unreachable code blocks
;;; before saving an image. Ported from CL runtime to ECE.

;;; Helper: insertion sort for a list of numbers (ascending)
(define (sort-numbers lst)
  (define (insert x sorted)
    (if (null? sorted)
        (list x)
        (if (< x (car sorted))
            (cons x sorted)
            (cons (car sorted) (insert x (cdr sorted))))))
  (reduce (lambda (acc x) (insert x acc)) '() lst))

;;; Walk a value to collect entry PCs from compiled procedures and continuations.
;;; VISITED is an eq-based hash table (from %eq-hash-table).
;;; PCS is a regular ECE hash table (integer keys).
(define (collect-entry-pcs-from-value val pcs visited)
  (when (pair? val)
    (unless (%eq-hash-has-key? visited val)
      (%eq-hash-set! visited val t)
      (cond
       ;; compiled-procedure: (compiled-procedure entry-pc env)
       ((eq? (car val) 'compiled-procedure)
        (hash-set! pcs (car (cdr val)) t)
        (collect-entry-pcs-from-env (car (cdr (cdr val))) pcs visited))
       ;; continuation: (continuation stack continue-pc)
       ((eq? (car val) 'continuation)
        (for-each (lambda (item)
                    (collect-entry-pcs-from-value item pcs visited))
                  (car (cdr val))))
       ;; primitive: no PCs to collect
       ((eq? (car val) 'primitive) '())
       ;; generic list: walk car and cdr
       (else
        (collect-entry-pcs-from-value (car val) pcs visited)
        (collect-entry-pcs-from-value (cdr val) pcs visited))))))

;;; Walk all frames in an environment collecting entry PCs from values.
(define (collect-entry-pcs-from-env env pcs visited)
  (for-each
   (lambda (frame)
     (when (pair? frame)
       (unless (%eq-hash-has-key? visited frame)
         (%eq-hash-set! visited frame t)
         ;; cdr of frame = values list
         (for-each
          (lambda (val)
            (collect-entry-pcs-from-value val pcs visited))
          (cdr frame)))))
   env))

;;; Return sorted list of block boundary PCs from the procedure-name table.
(define (collect-block-boundaries)
  (sort-numbers
   (map car (%procedure-name-entries))))

;;; Collect entry PCs reachable from roots: global env and macro table.
;;; Returns an ECE hash table (pc -> t).
(define (collect-reachable-entry-pcs)
  (let ((pcs (hash-table))
        (visited (%eq-hash-table)))
    ;; From global env
    (collect-entry-pcs-from-env *global-env* pcs visited)
    ;; From macro table
    (for-each
     (lambda (entry)
       (collect-entry-pcs-from-value (cdr entry) pcs visited))
     (%macro-table-entries))
    pcs))

;;; Check if any PC in [start, end) is in the reachable-pcs hash set.
(define (block-contains-reachable-pc start end reachable-pcs)
  (let ((found '()))
    (for-each
     (lambda (pc)
       (when (and (>= pc start) (< pc end))
         (set found t)))
     (hash-keys reachable-pcs))
    found))

;;; Build list of all block ranges from boundaries.
;;; Prepend 0 if not already a boundary.
(define (build-all-block-ranges boundaries vector-length)
  (let ((all-starts (if (and (pair? boundaries) (= (car boundaries) 0))
                        boundaries
                        (cons 0 boundaries))))
    (define (build starts)
      (if (null? starts)
          '()
          (let ((start (car starts))
                (end (if (null? (cdr starts))
                         vector-length
                         (car (cdr starts)))))
            (cons (cons start end) (build (cdr starts))))))
    (build all-starts)))

;;; Mark reachable blocks: return list of (start . end) ranges for live blocks.
(define (mark-reachable-blocks boundaries reachable-pcs vector-length)
  (filter
   (lambda (range)
     (block-contains-reachable-pc (car range) (cdr range) reachable-pcs))
   (build-all-block-ranges boundaries vector-length)))

;;; Collect label names referenced by an instruction (recursive tree walk).
(define (collect-label-refs instr)
  (define refs '())
  (define (walk form)
    (when (pair? form)
      (if (eq? (car form) 'label)
          (set refs (cons (car (cdr form)) refs))
          (begin (walk (car form))
                 (walk (cdr form))))))
  (walk instr)
  refs)

;;; Find the block (start . end) that contains target-pc.
(define (find-block-for-pc target-pc boundaries vector-length)
  (if (>= target-pc vector-length)
      '()
      (let ((all-ranges (build-all-block-ranges boundaries vector-length)))
        (define (search ranges)
          (if (null? ranges)
              '()
              (let ((range (car ranges)))
                (if (and (>= target-pc (car range)) (< target-pc (cdr range)))
                    range
                    (search (cdr ranges))))))
        (search all-ranges))))

;;; Build a label-to-pc lookup hash table from label-table entries.
(define (build-label-lookup)
  (let ((lookup (hash-table)))
    (for-each
     (lambda (entry)
       (hash-set! lookup (car entry) (cdr entry)))
     (%label-table-entries))
    lookup))

;;; Transitively retain blocks referenced by labels in already-retained blocks.
(define (transitively-retain-blocks initial-ranges boundaries label-lookup vector-length)
  (let ((retained (hash-table))   ;; start-pc -> (start . end)
        (worklist initial-ranges))
    ;; Seed with initial ranges
    (for-each
     (lambda (range) (hash-set! retained (car range) range))
     initial-ranges)
    ;; Process worklist
    (define (process)
      (when (pair? worklist)
        (let ((range (car worklist)))
          (set worklist (cdr worklist))
          ;; Scan this block for label references
          (define (scan-pc pc)
            (when (< pc (cdr range))
              (let ((instr (%instruction-source-ref pc)))
                (for-each
                 (lambda (label-name)
                   (let ((target-pc (hash-ref label-lookup label-name)))
                     (when target-pc
                       (let ((block (find-block-for-pc target-pc boundaries vector-length)))
                         (when (and (pair? block) (not (hash-has-key? retained (car block))))
                           (hash-set! retained (car block) block)
                           (set worklist (cons block worklist)))))))
                 (collect-label-refs instr)))
              (scan-pc (+ pc 1))))
          (scan-pc (car range)))
        (process)))
    (process)
    ;; Return sorted ranges
    (let ((ranges (map (lambda (k) (hash-ref retained k))
                       (hash-keys retained))))
      (sort-ranges ranges))))

;;; Sort ranges by start PC (ascending).
(define (sort-ranges ranges)
  (define (insert range sorted)
    (if (null? sorted)
        (list range)
        (if (< (car range) (car (car sorted)))
            (cons range sorted)
            (cons (car sorted) (insert range (cdr sorted))))))
  (reduce (lambda (acc r) (insert r acc)) '() ranges))

;;; Compact instruction vector: copy live blocks into a new list.
;;; Returns (new-source-list . remap-table) where remap maps old-pc -> new-pc.
(define (compact-instruction-vector ranges)
  (let ((new-source '())
        (remap (hash-table))
        (new-pc 0))
    (for-each
     (lambda (range)
       (define (copy-pc old-pc)
         (when (< old-pc (cdr range))
           (set new-source (cons (%instruction-source-ref old-pc) new-source))
           (hash-set! remap old-pc new-pc)
           (set new-pc (+ new-pc 1))
           (copy-pc (+ old-pc 1))))
       (copy-pc (car range)))
     ranges)
    (cons (reverse new-source) remap)))

;;; Remap label table: produce new alist with remapped PCs, dropping dead labels.
(define (remap-label-table remap)
  (filter
   (lambda (entry) (pair? entry))
   (map (lambda (entry)
          (let ((new-pc (hash-ref remap (cdr entry))))
            (if new-pc
                (cons (car entry) new-pc)
                '())))
        (%label-table-entries))))

;;; Remap procedure-name table: produce new alist with remapped PCs.
(define (remap-procedure-name-table remap)
  (filter
   (lambda (entry) (pair? entry))
   (map (lambda (entry)
          (let ((new-pc (hash-ref remap (car entry))))
            (if new-pc
                (cons new-pc (cdr entry))
                '())))
        (%procedure-name-entries))))

;;; Deep-copy a value, remapping PCs in compiled procedures and continuations.
;;; VISITED is an eq-based hash table (from %eq-hash-table).
;;; REMAP is a regular ECE hash table (integer keys).
(define (deep-copy-and-remap value remap visited)
  (cond
   ((not (pair? value)) value)
   ((null? value) '())
   ((%eq-hash-has-key? visited value)
    (%eq-hash-ref visited value))
   ;; compiled-procedure
   ((eq? (car value) 'compiled-procedure)
    (let* ((old-pc (car (cdr value)))
           (new-pc (hash-ref remap old-pc))
           (copy (list 'compiled-procedure (if new-pc new-pc old-pc) '())))
      (%eq-hash-set! visited value copy)
      ;; Deep-copy the environment (third element)
      (set-car! (cdr (cdr copy))
                (deep-copy-and-remap (car (cdr (cdr value))) remap visited))
      copy))
   ;; continuation
   ((eq? (car value) 'continuation)
    (let ((copy (list 'continuation '() '())))
      (%eq-hash-set! visited value copy)
      ;; Deep-copy the stack (second element)
      (set-car! (cdr copy)
                (deep-copy-and-remap (car (cdr value)) remap visited))
      ;; Remap continue-pc (third element)
      (let ((old-cont-pc (car (cdr (cdr value)))))
        (set-car! (cdr (cdr copy))
                  (if (number? old-cont-pc)
                      (let ((new-pc (hash-ref remap old-cont-pc)))
                        (if new-pc new-pc old-cont-pc))
                      (deep-copy-and-remap old-cont-pc remap visited))))
      copy))
   ;; primitive — immutable, no PCs
   ((eq? (car value) 'primitive) value)
   ;; generic cons cell
   (else
    (let ((copy (cons '() '())))
      (%eq-hash-set! visited value copy)
      (set-car! copy (deep-copy-and-remap (car value) remap visited))
      (set-cdr! copy (deep-copy-and-remap (cdr value) remap visited))
      copy))))

;;; Deep-copy the global environment, remapping all PCs.
(define (deep-copy-and-remap-env env remap)
  (let ((visited (%eq-hash-table)))
    (deep-copy-and-remap env remap visited)))

;;; Deep-copy the macro table entries, remapping PCs in compiled transformers.
(define (deep-copy-and-remap-macros remap)
  (let ((visited (%eq-hash-table)))
    (map (lambda (entry)
           (cons (car entry)
                 (deep-copy-and-remap (cdr entry) remap visited)))
         (%macro-table-entries))))

;;; Main compaction orchestrator.
;;; Returns a list: (source-list labels-alist env macros-alist names-alist)
(define (compact-for-save)
  (let ((boundaries (collect-block-boundaries))
        (reachable-pcs (collect-reachable-entry-pcs))
        (vec-len (%instruction-source-length)))
    ;; If no boundaries, nothing to compact
    (if (null? boundaries)
        (list (let ((src '()))
                (define (collect-src i)
                  (when (< i vec-len)
                    (set src (cons (%instruction-source-ref i) src))
                    (collect-src (+ i 1))))
                (collect-src 0)
                (reverse src))
              (%label-table-entries)
              *global-env*
              (%macro-table-entries)
              (%procedure-name-entries))
        (let* ((initial-ranges (mark-reachable-blocks boundaries reachable-pcs vec-len))
               (label-lookup (build-label-lookup))
               (ranges (transitively-retain-blocks
                        initial-ranges boundaries label-lookup vec-len))
               (result (compact-instruction-vector ranges))
               (new-source (car result))
               (remap (cdr result)))
          (list new-source
                (remap-label-table remap)
                (deep-copy-and-remap-env *global-env* remap)
                (deep-copy-and-remap-macros remap)
                (remap-procedure-name-table remap))))))

;;; Save the ECE image to a file.
;;; Compacts the instruction vector then serializes via CL primitive.
(define (save-image! filename)
  (let ((c (compact-for-save)))
    (%write-image filename
                  (list (list-ref c 0)   ;; source instructions
                        (list-ref c 1)   ;; label table
                        (list-ref c 2)   ;; environment
                        (list-ref c 3)   ;; macro table
                        (list-ref c 4)   ;; procedure names
                        (%parameter-table-entries)
                        (%parameter-counter)))))
