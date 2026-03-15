;;; ECE Image Compaction
;;; Compacts the instruction vector by removing unreachable code blocks
;;; before saving an image. Ported from CL runtime to ECE.
;;;
;;; All internal hash tables use %eq-hash-* (CL-backed O(1)) instead of
;;; ECE's alist-based hash tables to handle large instruction vectors.

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
;;; PCS is also an eq-based hash table (integer keys).
(define (collect-entry-pcs-from-value val pcs visited)
  (cond
   ;; Vector frame (from lexical addressing) — walk each element
   ((vector? val)
    (define (walk-vec i)
      (when (< i (vector-length val))
        (collect-entry-pcs-from-value (vector-ref val i) pcs visited)
        (walk-vec (+ i 1))))
    (walk-vec 0))
   ;; Pairs: compiled-procedure, continuation, primitive, or generic cons
   ((pair? val)
    (unless (%eq-hash-has-key? visited val)
      (%eq-hash-set! visited val t)
      (cond
       ;; compiled-procedure: (compiled-procedure entry-pc env)
       ((eq? (car val) 'compiled-procedure)
        (%eq-hash-set! pcs (car (cdr val)) t)
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
        (collect-entry-pcs-from-value (cdr val) pcs visited)))))))

;;; Walk all frames in an environment collecting entry PCs from values.
(define (collect-entry-pcs-from-env env pcs visited)
  (for-each
   (lambda (frame)
     (cond
      ;; Vector frame (from lexical addressing) — walk each slot
      ((vector? frame)
       (define (walk-vec i)
         (when (< i (vector-length frame))
           (collect-entry-pcs-from-value (vector-ref frame i) pcs visited)
           (walk-vec (+ i 1))))
       (walk-vec 0))
      ;; List-based frame — walk values list
      ((pair? frame)
       (unless (%eq-hash-has-key? visited frame)
         (%eq-hash-set! visited frame t)
         (for-each
          (lambda (val)
            (collect-entry-pcs-from-value val pcs visited))
          (cdr frame))))))
   env))

;;; Return sorted list of block boundary PCs from the procedure-name table.
(define (collect-block-boundaries)
  (sort-numbers
   (map car (%procedure-name-entries))))

;;; Collect entry PCs reachable from roots: global env and macro table.
;;; Returns an %eq-hash-table (pc -> t).
(define (collect-reachable-entry-pcs)
  (let ((pcs (%eq-hash-table))
        (visited (%eq-hash-table)))
    ;; From global env
    (collect-entry-pcs-from-env *global-env* pcs visited)
    ;; From macro table
    (for-each
     (lambda (entry)
       (collect-entry-pcs-from-value (cdr entry) pcs visited))
     (%macro-table-entries))
    pcs))

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

;;; Mark reachable blocks: for each reachable PC, find its block.
;;; Returns list of (start . end) ranges for live blocks.
(define (mark-reachable-blocks all-ranges reachable-pcs pc-to-block)
  (let ((result (%eq-hash-table)))   ;; start-pc -> range, deduplicates
    (for-each
     (lambda (pc)
       (let ((range (find-block-for-pc-fast pc pc-to-block)))
         (when (pair? range)
           (%eq-hash-set! result (car range) range))))
     (%eq-hash-keys reachable-pcs))
    ;; Collect values
    (map (lambda (k) (%eq-hash-ref result k))
         (%eq-hash-keys result))))

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
;;; Uses pre-computed all-ranges list.
(define (find-block-for-pc target-pc all-ranges)
  (if (null? all-ranges)
      '()
      (let ((range (car all-ranges)))
        (if (and (>= target-pc (car range)) (< target-pc (cdr range)))
            range
            (find-block-for-pc target-pc (cdr all-ranges))))))

;;; Build a hash table mapping every PC in every range to its block.
;;; This pre-computes the answer for all possible target PCs, making
;;; subsequent lookups O(1). With ~50K instructions this is affordable.
(define (build-pc-to-block-table all-ranges)
  (let ((table (%eq-hash-table)))
    (for-each
     (lambda (range)
       (define (fill pc)
         (when (< pc (cdr range))
           (%eq-hash-set! table pc range)
           (fill (+ pc 1))))
       (fill (car range)))
     all-ranges)
    table))

;;; O(1) block lookup using pre-built table.
(define (find-block-for-pc-fast target-pc pc-to-block)
  (let ((result (%eq-hash-ref pc-to-block target-pc)))
    (if result result '())))

;;; Build a label-to-pc lookup hash table from label-table entries.
;;; Uses %eq-hash for O(1) lookup.
(define (build-label-lookup)
  (let ((lookup (%eq-hash-table)))
    (for-each
     (lambda (entry)
       (%eq-hash-set! lookup (car entry) (cdr entry)))
     (%label-table-entries))
    lookup))

;;; Add edges from one block to all blocks it references via labels.
;;; Scans instructions in [start, end) for label references.
;;; Only ASSIGN, GOTO, and BRANCH instructions can contain label references;
;;; SAVE, RESTORE, TEST, and PERFORM never do.
(define (add-block-edges! graph src-start start end pc-to-block label-lookup)
  (define (scan-pc pc)
    (when (< pc end)
      (let ((instr (%instruction-source-ref pc)))
        (when (pair? instr)
          (let ((opcode (car instr)))
            (when (or (eq? opcode 'assign)
                      (eq? opcode 'goto)
                      (eq? opcode 'branch))
              (for-each
               (lambda (label-name)
                 (let ((target-pc (%eq-hash-ref label-lookup label-name)))
                   (when target-pc
                     (let ((target-block (find-block-for-pc-fast target-pc pc-to-block)))
                       (when (pair? target-block)
                         (let ((target-start (car target-block))
                               (existing (%eq-hash-ref graph src-start)))
                           (%eq-hash-set! graph src-start
                                          (cons target-start
                                                (if existing existing '())))))))))
               (collect-label-refs instr))))))
      (scan-pc (+ pc 1))))
  (scan-pc start))

;;; Build a block adjacency graph: block-start -> list of referenced block-starts.
;;; Does a single pass over all instructions, collecting label references and
;;; mapping them to target blocks. This moves the expensive instruction scanning
;;; out of the transitive retention loop.
(define (build-block-adjacency-graph all-ranges pc-to-block label-lookup)
  (let ((graph (%eq-hash-table)))
    (for-each
     (lambda (range)
       (add-block-edges! graph (car range) (car range) (cdr range)
                         pc-to-block label-lookup))
     all-ranges)
    graph))

;;; Transitively retain blocks using pre-built adjacency graph.
;;; BFS from initial live blocks following graph edges.
;;; START-TO-RANGE maps block-start -> (start . end).
(define (transitively-retain-blocks initial-ranges block-graph start-to-range)
  (let ((retained (%eq-hash-table))   ;; start-pc -> (start . end)
        (worklist '()))
    ;; Seed with initial ranges
    (for-each
     (lambda (range)
       (%eq-hash-set! retained (car range) range)
       (set worklist (cons (car range) worklist)))
     initial-ranges)
    ;; BFS: follow adjacency edges
    (define (process)
      (when (pair? worklist)
        (let ((block-start (car worklist)))
          (set worklist (cdr worklist))
          ;; Visit all blocks referenced by this block
          (let ((neighbors (%eq-hash-ref block-graph block-start)))
            (when neighbors
              (for-each
               (lambda (target-start)
                 (unless (%eq-hash-has-key? retained target-start)
                   (let ((target-range (%eq-hash-ref start-to-range target-start)))
                     (when target-range
                       (%eq-hash-set! retained target-start target-range)
                       (set worklist (cons target-start worklist))))))
               neighbors))))
        (process)))
    (process)
    ;; Return sorted ranges
    (let ((ranges (map (lambda (k) (%eq-hash-ref retained k))
                       (%eq-hash-keys retained))))
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
;;; Returns (new-source-list . remap-table) where remap is an %eq-hash-table.
(define (compact-instruction-vector ranges)
  (let ((new-source '())
        (remap (%eq-hash-table))
        (new-pc 0))
    (for-each
     (lambda (range)
       (define (copy-pc old-pc)
         (when (< old-pc (cdr range))
           (set new-source (cons (%instruction-source-ref old-pc) new-source))
           (%eq-hash-set! remap old-pc new-pc)
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
          (let ((new-pc (%eq-hash-ref remap (cdr entry))))
            (if new-pc
                (cons (car entry) new-pc)
                '())))
        (%label-table-entries))))

;;; Remap procedure-name table: produce new alist with remapped PCs.
(define (remap-procedure-name-table remap)
  (filter
   (lambda (entry) (pair? entry))
   (map (lambda (entry)
          (let ((new-pc (%eq-hash-ref remap (car entry))))
            (if new-pc
                (cons new-pc (cdr entry))
                '())))
        (%procedure-name-entries))))

;;; Deep-copy a value, remapping PCs in compiled procedures and continuations.
;;; VISITED is an eq-based hash table (from %eq-hash-table).
;;; REMAP is also an %eq-hash-table (integer keys).
(define (deep-copy-and-remap value remap visited)
  (cond
   ((vector? value)
    ;; Vector frame (from lexical addressing) — deep-copy each element
    (let ((len (vector-length value))
          (copy (make-vector (vector-length value))))
      (define (copy-elements i)
        (when (< i len)
          (vector-set! copy i (deep-copy-and-remap (vector-ref value i) remap visited))
          (copy-elements (+ i 1))))
      (copy-elements 0)
      copy))
   ((not (pair? value)) value)
   ((null? value) '())
   ((%eq-hash-has-key? visited value)
    (%eq-hash-ref visited value))
   ;; compiled-procedure
   ((eq? (car value) 'compiled-procedure)
    (let* ((old-pc (car (cdr value)))
           (new-pc (%eq-hash-ref remap old-pc))
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
                      (let ((new-pc (%eq-hash-ref remap old-cont-pc)))
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
        (let* ((all-ranges (build-all-block-ranges boundaries vec-len))
               (pc-to-block (build-pc-to-block-table all-ranges))
               (initial-ranges (mark-reachable-blocks all-ranges reachable-pcs pc-to-block))
               (label-lookup (build-label-lookup))
               (block-graph (build-block-adjacency-graph all-ranges pc-to-block label-lookup))
               (start-to-range (let ((tbl (%eq-hash-table)))
                                 (for-each (lambda (r) (%eq-hash-set! tbl (car r) r))
                                           all-ranges)
                                 tbl))
               (ranges (transitively-retain-blocks
                        initial-ranges block-graph start-to-range))
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
