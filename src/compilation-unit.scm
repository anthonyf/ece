;;; ECE Compilation Units
;;; First-class compiled unit values: compile, inspect, execute, serialize.
;;; Loaded after compiler.scm and assembler.scm.

;;; Source-location tracking globals.
;;; Defined here (in addition to reader.scm and compiler.scm) because
;;; this file may be loaded before those are re-compiled during bootstrap.
(define *source-locations* (%make-hash-table))
(define *source-file-name* #f)
(define *current-source-location* #f)

;;; --- Compiled unit type ---

(define (compile-form expr)
  "Compile a single expression and return a compiled unit value."
  (set! *current-source-location* #f)
  (let ((compiled (mc-compile expr 'val 'next)))
    (list 'compiled-unit (mc-instructions compiled))))

(define (compiled-unit? obj)
  "Return #t if OBJ is a compiled unit."
  (and (pair? obj) (eq? (car obj) 'compiled-unit)))

(define (compiled-unit-instructions unit)
  "Return the flat instruction list from a compiled unit."
  (cadr unit))

(define (execute unit)
  "Assemble and execute a compiled unit, returning the result."
  (let ((start-pc (assemble-into-global (compiled-unit-instructions unit))))
    (execute-from-pc start-pc)))

;;; --- Serialization ---
;;; Uses write-to-string + write-char for port-directed output,
;;; since ECE's write/display don't accept port arguments.

(define (write-string-to-port str port)
  "Write each character of STR to PORT."
  (let loop ((i 0))
    (when (< i (string-length str))
      (write-char (string-ref str i) port)
      (loop (+ i 1)))))

(define (rename-labels instrs)
  "Rename gensym labels — currently identity (renaming deferred to golden tests)."
  instrs)

;;; --- Flat instruction list writing ---

(define (write-flat-instructions instrs port)
  "Write a flat instruction list to PORT, one instruction/label per line."
  (write-char #\( port)
  (let loop ((items instrs) (first? #t))
    (when (pair? items)
      (if first?
          (write-string-to-port (write-to-string-flat (car items)) port)
          (begin
            (write-char #\newline port)
            (write-char #\space port)
            (write-string-to-port (write-to-string-flat (car items)) port)))
      (loop (cdr items) #f)))
  (write-char #\) port)
  (write-char #\newline port))

;;; --- Merging compilation units ---

(define (merge-instruction-lists units)
  "Merge compiled units into a single flat instruction list with env-resets between units."
  (if (null? units)
      '()
      (let loop ((units units))
        (if (null? (cdr units))
            (compiled-unit-instructions (car units))
            (append (compiled-unit-instructions (car units))
                    (list '(assign env (op lookup-variable-value)
                                   (const *global-env*) (reg env)))
                    (loop (cdr units)))))))

(define (write-compiled-unit unit port)
  "Write a compiled unit to PORT with one instruction per line.
Labels are currently written as-is; deterministic gensym renaming is deferred."
  (let ((renamed (rename-labels (compiled-unit-instructions unit))))
    (write-flat-instructions renamed port)))

(define (read-compiled-unit port)
  "Read a compiled unit from PORT. Returns eof on end of input."
  (let ((instructions (ece-scheme-read port)))
    (if (eof? instructions)
        instructions
        (list 'compiled-unit instructions))))

;;; --- Source-map extraction ---

(define (extract-source-map instrs)
  "Extract source-map entries from instruction list containing source-location markers.
Returns (stripped-instrs . source-map-entries) where entries are (pc line col) triples
sorted by PC. Source-location markers are removed from the instruction list."
  (let loop ((items instrs) (pc 0) (stripped '()) (entries '()))
    (if (null? items)
        (cons (reverse stripped)
              (reverse entries))
        (let ((item (car items)))
          (cond
           ;; Source-location marker: record entry, don't increment PC
           ((and (pair? item) (eq? (car item) 'source-location))
            (loop (cdr items) pc stripped
                  (cons (list pc (caddr item) (cadddr item)) entries)))
           ;; Label: keep it, don't increment PC
           ((symbol? item)
            (loop (cdr items) pc (cons item stripped) entries))
           ;; Pseudo-instruction procedure-name: keep it, don't increment PC
           ((and (pair? item) (eq? (car item) 'procedure-name))
            (loop (cdr items) pc (cons item stripped) entries))
           ;; Pseudo-instruction procedure-params: keep it, don't increment PC
           ((and (pair? item) (eq? (car item) 'procedure-params))
            (loop (cdr items) pc (cons item stripped) entries))
           ;; Regular instruction: keep it, increment PC
           (else
            (loop (cdr items) (+ pc 1) (cons item stripped) entries)))))))

;;; --- File compilation and loading ---

(define (filename-strip-extension filename ext)
  "Strip EXT (e.g., \".scm\") from end of FILENAME if present."
  (let ((flen (string-length filename))
        (elen (string-length ext)))
    (if (and (> flen elen)
             (string=? (substring filename (- flen elen) flen) ext))
        (substring filename 0 (- flen elen))
        filename)))

(define (filename-basename filename)
  "Extract the basename from FILENAME (strip directory path)."
  (let loop ((i (- (string-length filename) 1)))
    (cond
     ((< i 0) filename)
     ((char=? (string-ref filename i) #\/)
      (substring filename (+ i 1) (string-length filename)))
     (else (loop (- i 1))))))

(define (compile-file-to-port filename port)
  "Compile all forms in FILENAME and write one ecec section (header + instructions)
to PORT. Macro definitions are executed at compile time so subsequent forms can
use them. Returns the space name symbol."
  (let* ((space-name
          (string->symbol (filename-strip-extension (filename-basename filename) ".scm")))
         (basename (filename-basename filename)))
    ;; Set up source location tracking for this file
    (set! *source-locations* (%make-hash-table))
    (set! *source-file-name* basename)
    (let ((in (open-input-file filename)))
      ;; Phase 1: compile all forms, track macros
      ;; Returns (units-reversed . macros-reversed)
      ;; For define-macro forms, we:
      ;;   1. Execute at compile time (so later forms can use the macro)
      ;;   2. Compile a set-macro! + lambda expression for the .ecec file
      ;;      (so macros are registered at load time, not just compile time)
      (define (define-macro-to-set-macro expr)
        "Transform (define-macro (name params...) body...) into
       (begin (set-macro! 'name (lambda (params...) body...)) 'name)"
        (let* ((name (if (pair? (cadr expr)) (car (cadr expr)) (cadr expr)))
               (params (if (pair? (cadr expr)) (cdr (cadr expr)) (list (cadr expr))))
               (body (cddr expr)))
          (list 'begin
                (list 'set-macro! (list 'quote name)
                      (cons 'lambda (cons params body)))
                (list 'quote name))))
      (define (maybe-expand-define-syntax expr)
        "If EXPR is (define-syntax ...), expand to (define-macro ...) so it gets
       compile-time execution and load-time set-macro! treatment."
        (if (and (pair? expr) (eq? (car expr) 'define-syntax)
                 (get-macro 'define-syntax))
            (mc-expand-macro-at-compile-time
             (get-macro 'define-syntax) (cdr expr))
            expr))
      (define (read-loop units macros)
        (let ((expr (maybe-expand-define-syntax (ece-scheme-read in))))
          (if (eof? expr)
              (begin (close-input-port in) (cons units macros))
              (begin
                ;; Track and execute macro definitions at compile time
                (when (and (pair? expr) (eq? (car expr) 'define-macro))
                  (mc-compile-and-go expr))
                (read-loop
                 (cons (compile-form
                        (if (and (pair? expr) (eq? (car expr) 'define-macro))
                            (define-macro-to-set-macro expr)
                            expr))
                       units)
                 (if (and (pair? expr) (eq? (car expr) 'define-macro))
                     (cons (if (pair? (cadr expr)) (car (cadr expr)) (cadr expr))
                           macros)
                     macros))))))
      (let* ((result (read-loop '() '()))
             (units (reverse (car result)))
             (macros-defined (reverse (cdr result)))
             ;; Phase 2: merge units, rename labels, extract source-map, write flat output
             (merged (merge-instruction-lists units))
             (renamed (rename-labels merged))
             (extracted (extract-source-map renamed))
             (clean-instrs (car extracted))
             (source-map-entries (cdr extracted)))
        ;; Write ecec-header with source-map
        (write-string-to-port
         (write-to-string-flat
          (if (null? source-map-entries)
              (list 'ecec-header
                    (list 'space space-name)
                    (list 'macros macros-defined))
              (list 'ecec-header
                    (list 'space space-name)
                    (list 'macros macros-defined)
                    (cons 'source-map (cons basename source-map-entries)))))
         port)
        (write-char #\newline port)
        (write-flat-instructions clean-instrs port)
        ;; Clean up source location tracking state
        (set! *source-locations* (%make-hash-table))
        (set! *source-file-name* #f)
        space-name))))

(define (compile-file filename)
  "Compile all forms in FILENAME, write compiled units to a .ecec file.
Emits an ecec-header with space name, macro list, and source-map,
followed by compiled units.
Returns the output filename."
  (let* ((output-name
          (string-append (filename-strip-extension filename ".scm") ".ecec"))
         (out (open-output-file output-name)))
    (compile-file-to-port filename out)
    (close-output-port out)
    output-name))

(define (compile-system filenames output-path)
  "Compile a list of .scm FILENAMES into a single .ecec archive bundle at
OUTPUT-PATH. Each file is compiled to a code-object archive (§8 format);
the bundle is the concatenation of those archives. Loaders iterate
sections via load-section-from-port, dispatching on each section's head
symbol (ecec-archive). Returns OUTPUT-PATH."
  (let ((out (open-output-file output-path)))
    (let loop ((files filenames))
      (when (pair? files)
        (compile-file-to-archive (car files) out)
        (loop (cdr files))))
    (close-output-port out)
    output-path))

;;; --- Source-map registration ---

(define *source-maps* (%make-hash-table))

(define (register-source-map! space-name source-map-field)
  "Register source-map entries from an ecec-header source-map field.
SPACE-NAME is a symbol, SOURCE-MAP-FIELD is (filename (pc line col) ...)."
  (when (and source-map-field (pair? (cdr source-map-field)))
    (let ((filename (car source-map-field))
          (ht (%make-hash-table)))
      (let loop ((entries (cdr source-map-field)))
        (when (pair? entries)
          (let ((entry (car entries)))
            (hash-set! ht (car entry) (list filename (cadr entry) (caddr entry))))
          (loop (cdr entries))))
      (hash-set! *source-maps* space-name ht))))

(define (resolve-source-location space-name pc)
  "Look up PC in source-map for SPACE-NAME. Returns (file line col) or #f."
  (let ((space-map (hash-ref *source-maps* space-name #f)))
    (if space-map
        (hash-ref space-map pc #f)
        #f)))

(define (load-section-from-port port)
  "Load one ecec section from PORT. Dispatches on the first form:
  - (ecec-header ...) → legacy space-based section, reads a second form
    with the compiled instructions and executes against a new space.
  - (ecec-archive ...) → §8 archive format, rebuilds code-objects and
    executes the init. Returns the init's result.
Returns eof if no more sections."
  (let ((head (ece-scheme-read port)))
    (cond
     ((eof? head) head)
     ((and (pair? head) (eq? (car head) 'ecec-archive))
      (load-archive-section-form head))
     (else
      (load-legacy-section-from-port head port)))))

(define (load-legacy-section-from-port header port)
  "Old-format path: HEADER is the already-read (ecec-header ...) form.
Read the instruction stream, register source-map, execute against a
fresh space. Compatibility shim retired in §9.3."
  (let* ((space-sym (cadr (assoc 'space (cdr header))))
         (source-map-field (let ((sm (assoc 'source-map (cdr header))))
                             (if sm (cdr sm) #f)))
         (prev-space (%current-space-id))
         (new-space (%create-space (symbol->string space-sym)))
         (instrs (ece-scheme-read port)))
    (when source-map-field
      (register-source-map! space-sym source-map-field))
    (%set-current-space-id! new-space)
    (let ((result (execute (list 'compiled-unit instrs))))
      (%set-current-space-id! prev-space)
      result)))

(define (load-archive-section-form archive)
  "Archive-format path: ARCHIVE is the parsed (ecec-archive ...) form.
Rebuild code-objects and execute the init."
  (let* ((cos (archive-sexp->code-objects archive))
         (init (vector-ref cos 0)))
    (execute-code-object init)))

(define (load-compiled filename)
  "Load and execute compiled code from a .ecec file (first section only).
For multi-space bundles, only the first section is loaded."
  (let ((port (open-input-file filename)))
    (let ((result (load-section-from-port port)))
      (close-input-port port)
      result)))

(define (load-bundle filename)
  "Load and execute all sections from a .ecec bundle file.
Each section creates a new space, registers its source-map, and executes
sequentially. Definitions from earlier sections are available to later ones.
Returns the result of the last section."
  (let ((port (open-input-file filename)))
    (let loop ((last-result #f))
      (let ((result (load-section-from-port port)))
        (if (eof? result)
            (begin (close-input-port port) last-result)
            (loop result))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §8: .ecec archive format (version 2)
;;;
;;; Shape:
;;;   (ecec-archive
;;;     version 2
;;;     file "foo.scm"
;;;     entries ((code-object name %init instructions (...) ...)
;;;              (code-object name add1 instructions (...) ...)
;;;              ...))
;;;
;;; Tag symbols are plain (no `:` prefix). A `:keyword` style would be
;;; cleaner visually but doesn't round-trip cleanly through the existing
;;; writer+reader pair: write-to-string-flat escapes ECE `:foo` symbols
;;; with pipes (CL reader rules), and re-reading via CL's read produces
;;; a CL keyword in the :keyword package instead of the ECE-package
;;; symbol the ECE reader would have produced from source. Fixing that
;;; requires coordinated changes to ece-print-flat + downcase-ece-symbols
;;; and is tracked separately; until then, plain symbols avoid the
;;; ambiguity.
;;;
;;; - Entry 0 is the file's init code-object (top-level forms, merged).
;;; - Entries 1..N are nested lambdas hoisted to archive level.
;;; - Inner references use (const (co-ref N)) — second pass at load time
;;;   patches these to the actual code-object values.
;;; - resolved-instructions rebuilt at load via resolve-operations.
;;; ─────────────────────────────────────────────────────────────────────────

(define (archive/plist-get plist key)
  "Walk a keyword-tagged plist, return value after KEY or #f."
  (cond
   ((null? plist) #f)
   ((null? (cdr plist)) #f)
   ((eq? (car plist) key) (cadr plist))
   (else (archive/plist-get (cddr plist) key))))

(define (archive/rewrite-co-refs tree co-map)
  "Walk TREE, replacing each `(const <code-object>)` with
`(const (co-ref ID))` using ID from CO-MAP."
  (cond
   ((null? tree) '())
   ((not (pair? tree)) tree)
   ;; (const <code-object>) → (const (co-ref ID))
   ((and (eq? (car tree) 'const)
         (pair? (cdr tree))
         (code-object? (cadr tree)))
    (list 'const (list 'co-ref (hash-ref co-map (cadr tree) #f))))
   (else
    (cons (archive/rewrite-co-refs (car tree) co-map)
          (archive/rewrite-co-refs (cdr tree) co-map)))))

(define (archive/patch-co-refs tree cos-vec)
  "Inverse of archive/rewrite-co-refs: replace `(const (co-ref N))` with
`(const <code-object-at-N>)` using the loaded entries vector."
  (cond
   ((null? tree) '())
   ((not (pair? tree)) tree)
   ((and (eq? (car tree) 'const)
         (pair? (cdr tree))
         (pair? (cadr tree))
         (eq? (car (cadr tree)) 'co-ref))
    (list 'const (vector-ref cos-vec (cadr (cadr tree)))))
   (else
    (cons (archive/patch-co-refs (car tree) cos-vec)
          (archive/patch-co-refs (cdr tree) cos-vec)))))

(define (archive/collect-reachable top-co)
  "Depth-first walk over TOP-CO's instruction tree, collecting all reachable
code-objects in DFS pre-order. `visit` recurses into each nested
code-object the moment it is first seen — that is DFS, not BFS. TOP-CO
is first. Each code-object appears exactly once. Discovery order is
identical to build-reachable-co-index-map in src/codegen-cl-inline.scm;
the two walks must stay in lockstep so archive-level codegen and ad-hoc
single-code-object codegen produce matching indices."
  (let ((seen (%make-hash-table))
        (order '()))
    (define (visit co)
      (when (not (hash-has-key? seen co))
        (hash-set! seen co #t)
        (set! order (cons co order))
        (let ((instrs (code-object-instructions co))
              (len (code-object-length co)))
          (let loop ((i 0))
            (when (< i len)
              (visit-tree (vector-ref instrs i))
              (loop (+ i 1)))))))
    (define (visit-tree tree)
      (cond
       ((null? tree) #f)
       ((not (pair? tree)) #f)
       ((and (eq? (car tree) 'const)
             (pair? (cdr tree))
             (code-object? (cadr tree)))
        (visit (cadr tree)))
       (else
        (visit-tree (car tree))
        (visit-tree (cdr tree)))))
    (visit top-co)
    (reverse order)))

(define (archive/code-object->entry co co-map)
  "Serialize CO to a (code-object :key val ...) entry form, rewriting
nested code-object constants to (co-ref N) via CO-MAP."
  (let* ((instrs (code-object-instructions co))
         (len (code-object-length co))
         (rewritten
          (let loop ((i 0) (acc '()))
            (if (>= i len) (reverse acc)
                (loop (+ i 1)
                      (cons (archive/rewrite-co-refs
                             (vector-ref instrs i) co-map)
                            acc))))))
    (list 'code-object
          'name (code-object-name co)
          'arity (code-object-arity co)
          'source-loc (code-object-source-loc co)
          'labels (code-object-label-entries co)
          'instructions rewritten)))

(define (code-object->archive-sexp top-co filename)
  "Build the full archive s-expression from TOP-CO (and all reachable
code-objects) for FILENAME."
  (let* ((all-cos (archive/collect-reachable top-co))
         (co-map (%make-hash-table)))
    (let loop ((cos all-cos) (idx 0))
      (when (pair? cos)
        (hash-set! co-map (car cos) idx)
        (loop (cdr cos) (+ idx 1))))
    (list 'ecec-archive
          'version 2
          'file filename
          'entries
          (let loop ((cos all-cos) (acc '()))
            (if (null? cos) (reverse acc)
                (loop (cdr cos)
                      (cons (archive/code-object->entry (car cos) co-map) acc)))))))

(define (archive-sexp->code-objects archive)
  "Parse an archive s-expression (as read from disk). Returns the vector
of code-objects. Entry 0 is the init code-object. Raises on version
mismatch."
  (let* ((version (archive/plist-get (cdr archive) 'version))
         (entries (archive/plist-get (cdr archive) 'entries)))
    (when (not (equal? version 2))
      (error (string-append
              "Unsupported .ecec archive version: "
              (if version (write-to-string version) "missing")
              ". Run `make bootstrap` to regenerate.")))
    (let* ((n (length entries))
           (cos (make-vector n))
           (entries-vec (list->vector entries)))
      ;; Pass 1: create code-objects + set metadata + set labels.
      (let loop ((i 0))
        (when (< i n)
          (let* ((entry (vector-ref entries-vec i))
                 (fields (cdr entry))
                 (co (%make-code-object)))
            (when (archive/plist-get fields 'name)
              (%code-object-set-name! co (archive/plist-get fields 'name)))
            (when (archive/plist-get fields 'arity)
              (%code-object-set-arity! co (archive/plist-get fields 'arity)))
            (when (archive/plist-get fields 'source-loc)
              (%code-object-set-source-loc! co (archive/plist-get fields 'source-loc)))
            (for-each (lambda (pair)
                        (%code-object-set-label! co (car pair) (cdr pair)))
                      (archive/plist-get fields 'labels))
            (vector-set! cos i co))
          (loop (+ i 1))))
      ;; Pass 2: push instructions (with (co-ref N) patched to code-objects).
      (let loop ((i 0))
        (when (< i n)
          (let* ((entry (vector-ref entries-vec i))
                 (co (vector-ref cos i))
                 (raw-instrs (archive/plist-get (cdr entry) 'instructions)))
            (for-each (lambda (instr)
                        (%code-object-push-instruction!
                         co (archive/patch-co-refs instr cos)))
                      raw-instrs))
          (loop (+ i 1))))
      cos)))

(define (load-archive-from-port port)
  "Read an archive from PORT, build all code-objects, execute the init
(entry 0). Returns the init's result."
  (let* ((archive (ece-scheme-read port))
         (cos (archive-sexp->code-objects archive))
         (init (vector-ref cos 0)))
    (execute-code-object init)))

(define (load-archive filename)
  "Load and execute a code-object archive from FILENAME. Returns the
result of the init code-object."
  (let ((port (open-input-file filename)))
    (let ((result (load-archive-from-port port)))
      (close-input-port port)
      result)))

(define (compile-file-to-archive filename output-port)
  "Compile all forms in FILENAME via mc-compile-to-code-object and
write the resulting code-object archive to OUTPUT-PORT. Mirrors
compile-file-to-port but produces the §8 archive format."
  (let ((basename (filename-basename filename)))
    (set! *source-locations* (%make-hash-table))
    (set! *source-file-name* basename)
    (let ((in (open-input-file filename)))
      ;; Same define-macro handling as compile-file-to-port: run at compile
      ;; time so later forms see the macro, then emit set-macro! for load.
      (define (define-macro-to-set-macro expr)
        (let* ((name (if (pair? (cadr expr)) (car (cadr expr)) (cadr expr)))
               (params (if (pair? (cadr expr)) (cdr (cadr expr)) (list (cadr expr))))
               (body (cddr expr)))
          (list 'begin
                (list 'set-macro! (list 'quote name)
                      (cons 'lambda (cons params body)))
                (list 'quote name))))
      (define (maybe-expand-define-syntax expr)
        (if (and (pair? expr) (eq? (car expr) 'define-syntax)
                 (get-macro 'define-syntax))
            (mc-expand-macro-at-compile-time
             (get-macro 'define-syntax) (cdr expr))
            expr))
      (define (read-loop forms)
        (let ((expr (maybe-expand-define-syntax (ece-scheme-read in))))
          (if (eof? expr)
              (begin (close-input-port in) (reverse forms))
              (begin
                (when (and (pair? expr) (eq? (car expr) 'define-macro))
                  (mc-compile-and-go expr))
                (read-loop
                 (cons (if (and (pair? expr) (eq? (car expr) 'define-macro))
                           (define-macro-to-set-macro expr)
                           expr)
                       forms))))))
      (let* ((forms (read-loop '()))
             ;; Wrap all forms in (begin ...) so mc-compile-to-code-object
             ;; gets a single expression. define-variable! side effects
             ;; sequence correctly inside begin.
             (top-co (mc-compile-to-code-object (cons 'begin forms)))
             (archive (code-object->archive-sexp top-co basename)))
        (write-string-to-port (write-to-string-flat archive) output-port)
        (write-char #\newline output-port)
        (set! *source-locations* (%make-hash-table))
        (set! *source-file-name* #f)
        top-co))))

(define (compile-file-archive filename)
  "Compile FILENAME to a .ecec archive file. Returns the output filename."
  (let* ((output-name
          (string-append (filename-strip-extension filename ".scm") ".ecec"))
         (out (open-output-file output-name)))
    (compile-file-to-archive filename out)
    (close-output-port out)
    output-name))
