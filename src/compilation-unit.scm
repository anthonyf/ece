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
  "Assemble and execute a compiled unit, returning the result.
§5.2: assembles into a fresh code-object and runs via execute-code-object."
  (let ((co (assemble-into-code-object
             (%make-code-object)
             (append (strip-source-locations
                      (compiled-unit-instructions unit))
                     '((halt))))))
    (execute-code-object co)))

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
      (define (define-syntax-to-define-macro expr)
        (let ((name (cadr expr))
              (transformer-expr (caddr expr)))
          (if (and (pair? transformer-expr)
                   (eq? (car transformer-expr) 'syntax-rules))
              (let ((literals (cadr transformer-expr))
                    (clauses (cddr transformer-expr)))
                (list 'define-macro
                      (cons name '%syntax-args)
                      (list 'syntax-rules-expand
                            (list 'quote literals)
                            (list 'quote clauses)
                            (list 'cons
                                  (list 'quote name)
                                  '%syntax-args))))
              (error "define-syntax: only syntax-rules transformers are supported"))))
      (define (maybe-expand-define-syntax expr)
        "If EXPR is (define-syntax ...), expand to (define-macro ...) so it gets
       compile-time execution and load-time set-macro! treatment."
        (if (and (pair? expr) (eq? (car expr) 'define-syntax))
            (if (get-macro 'define-syntax)
                (mc-expand-macro-at-compile-time
                 (get-macro 'define-syntax) (cdr expr))
                (define-syntax-to-define-macro expr))
            expr))
      (define (documentation-registration name kind doc signature)
        (list 'set-documentation!
              (list 'quote name)
              (list 'quote kind)
              doc
              :signature
              (list 'quote signature)))
      (define (define-macro/doc-form? expr)
        (and (pair? expr) (eq? (car expr) 'define-macro/doc)))
      (define (define-syntax/doc-form? expr)
        (and (pair? expr) (eq? (car expr) 'define-syntax/doc)))
      (define (define-macro/doc-valid? expr)
        (and (pair? (cdr expr))
             (pair? (cadr expr))
             (pair? (cddr expr))))
      (define (define-syntax/doc-valid? expr)
        (and (pair? (cdr expr))
             (pair? (cddr expr))
             (pair? (cdddr expr))
             (null? (cdr (cdddr expr)))))
      (define (define-macro/doc->define-macro expr)
        (if (define-macro/doc-valid? expr)
            (cons 'define-macro (cons (cadr expr) (cdddr expr)))
            (error "define-macro/doc: expected (define-macro/doc (name args...) doc body ...)")))
      (define (define-syntax/doc->define-syntax expr)
        (if (define-syntax/doc-valid? expr)
            (list 'define-syntax (cadr expr) (cadddr expr))
            (error "define-syntax/doc: expected (define-syntax/doc name doc transformer)")))
      (define (prepare-top-level-form expr)
        (cond
         ((define-macro/doc-form? expr)
          (let* ((macro-expr (define-macro/doc->define-macro expr))
                 (name (car (cadr macro-expr)))
                 (doc (caddr expr))
                 (runtime-form
                  (list 'begin
                        (define-macro-to-set-macro macro-expr)
                        (documentation-registration name
                                                    'macro
                                                    doc
                                                    (cadr macro-expr))
                        (list 'quote name))))
            (mc-compile-and-go macro-expr)
            (cons runtime-form name)))
         ((define-syntax/doc-form? expr)
          (let* ((syntax-expr (define-syntax/doc->define-syntax expr))
                 (macro-expr (maybe-expand-define-syntax syntax-expr))
                 (name (cadr expr))
                 (doc (caddr expr))
                 (runtime-form
                  (list 'begin
                        (define-macro-to-set-macro macro-expr)
                        (documentation-registration name 'syntax doc name)
                        (list 'quote name))))
            (mc-compile-and-go macro-expr)
            (cons runtime-form name)))
         (else
          (let ((expanded (maybe-expand-define-syntax expr)))
            (when (and (pair? expanded) (eq? (car expanded) 'define-macro))
              (mc-compile-and-go expanded))
            (cons (if (and (pair? expanded) (eq? (car expanded) 'define-macro))
                      (define-macro-to-set-macro expanded)
                      expanded)
                  (if (and (pair? expanded) (eq? (car expanded) 'define-macro))
                      (if (pair? (cadr expanded)) (car (cadr expanded)) (cadr expanded))
                      #f)))))))
      (define (read-loop units macros)
        (let ((expr (ece-scheme-read in)))
          (if (eof? expr)
              (begin (close-input-port in) (cons units macros))
              (let* ((prepared (prepare-top-level-form expr))
                     (form (car prepared))
                     (macro-name (cdr prepared)))
                (read-loop
                 (cons (compile-form form) units)
                 (if macro-name
                     (cons macro-name macros)
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
        space-name)))

(define (compile-file filename)
  "Compile all forms in FILENAME, write compiled units to a .ecec file
in the §8 archive format. Returns the output filename."
  (let* ((output-name
          (string-append (filename-strip-extension filename ".scm") ".ecec"))
         (out (open-output-file output-name)))
    (compile-file-to-archive filename out)
    (close-output-port out)
    output-name))

(define (compile-system/sexp filenames output-path)
  "Compile FILENAMES into a printed .ecec archive bundle at OUTPUT-PATH.
This is the current default developer-facing representation."
  (let ((out (open-output-file output-path)))
    (let loop ((files filenames))
      (when (pair? files)
        (compile-file-to-archive (car files) out)
        (loop (cdr files))))
    (close-output-port out)
    output-path))

(define (compile-system/binary filenames output-path)
  "Compile FILENAMES into a binary .ecec archive bundle at OUTPUT-PATH."
  (let ((out (open-binary-output-file output-path)))
    (if (null? filenames)
        (bca/write-bytes-to-port
         (bca/encode-header 0 bca/default-archive-version)
         out)
        (let ((first-archive (compile-file->archive (car filenames))))
          (bca/write-bytes-to-port
           (bca/encode-header
            (length filenames)
            (archive/plist-get (cdr first-archive) ':version))
           out)
          (bca/write-bytes-to-port
           (bca/encode-archive-section first-archive)
           out)
          (let loop ((files (cdr filenames)))
            (when (pair? files)
              (bca/write-bytes-to-port
               (bca/encode-archive-section (compile-file->archive (car files)))
               out)
              (loop (cdr files))))))
    (close-output-port out)
    output-path))

(define (compile-system filenames output-path)
  "Compile a list of .scm FILENAMES into a single printed .ecec archive bundle
at OUTPUT-PATH. Each file is compiled to a code-object archive (§8 format);
the bundle is the concatenation of those archives. Returns OUTPUT-PATH."
  (compile-system/sexp filenames output-path))

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

(define (read-archive-section-form port)
  "Read one ecec archive section from PORT. Expects (:ecec-archive ...).
Returns the archive form, or eof if no more sections. Legacy
(ecec-header ...) files were retired in §9.3 — if one is encountered,
signals an error pointing at `make bootstrap` for regeneration."
  (let ((head (ece-scheme-read port)))
    (cond
     ((eof? head) head)
     ;; Accept both new (:ecec-archive) and legacy (ecec-archive) during
     ;; the transition.
     ((and (pair? head)
           (or (eq? (car head) ':ecec-archive)
               (eq? (car head) 'ecec-archive)))
      head)
     (else
      (error "read-archive-section-form: expected (:ecec-archive ...). Run `make bootstrap` to regenerate.")))))

(define (load-section-from-port port)
  "Load one ecec archive section from PORT. Expects (:ecec-archive ...).
Returns the init's result, or eof if no more sections."
  (let ((archive (read-archive-section-form port)))
    (if (eof? archive)
        archive
        (load-archive-section-form archive))))

(define (load-archive-section-form archive)
  "Archive-format path: ARCHIVE is the parsed (:ecec-archive ...) form.
Rebuild code-objects and execute the selected init entry."
  (archive/load-materialized-section
   (archive/materialize-section archive)
   #f))

(define (archive/materialize-section archive)
  "Parse ARCHIVE into a section descriptor with normalized metadata and code."
  (let* ((unit (archive/unit-metadata archive))
         (cos (archive-sexp->code-objects archive)))
    (list ':archive archive ':unit unit ':cos cos)))

(define (archive/section-unit section)
  (archive/plist-get section ':unit))

(define (archive/section-cos section)
  (archive/plist-get section ':cos))

(define (archive/section-module? section)
  (archive/module-kind?
   (archive/plist-get (archive/section-unit section) ':kind)))

(define (archive/registered-unit unit-id)
  (hash-ref *archive-units* (archive/unit-key unit-id) #f))

(define (archive/ensure-registered-unit! unit cos)
  "Return UNIT's existing record, or register it when absent."
  (let* ((unit-id (archive/plist-get unit ':unit-id))
         (existing (archive/registered-unit unit-id)))
    (if existing
        existing
        (archive/register-unit! unit cos))))

(define (archive/register-bundle-section! section)
  "Register SECTION's unit for bundle-wide module graph resolution.
Module duplicate unit ids stay hard errors. File units are recorded when
absent so an explicit module-shaped import can fail as a non-module import
rather than as a missing unit, without making repeated file loads fatal."
  (let* ((unit (archive/section-unit section))
         (cos (archive/section-cos section))
         (unit-id (archive/plist-get unit ':unit-id)))
    (if (archive/section-module? section)
        (archive/register-unit! unit cos)
        (when (not (archive/registered-unit unit-id))
          (hash-set! *archive-units*
                     (archive/unit-key unit-id)
                     (archive/make-unit-record unit cos))))))

(define (archive/load-materialized-section section bundle-registered?)
  "Execute or instantiate SECTION. When BUNDLE-REGISTERED? is true, module
records have already been registered during the bundle discovery pass."
  (let ((unit (archive/section-unit section))
        (cos (archive/section-cos section)))
    (if (archive/section-module? section)
        (archive/module-instance-result
         (archive/instantiate-module!
          (if bundle-registered?
              (archive/ensure-registered-unit! unit cos)
              (archive/register-unit! unit cos))))
        (let ((init (archive/select-init-code-object
                     (archive/plist-get section ':archive)
                     cos)))
          (execute-code-object init)))))

(define (load-compiled filename)
  "Load and execute compiled code from a .ecec file (first section only).
For multi-space bundles, only the first section is loaded. Accepts printed
and binary archive files."
  (let ((binary-archives (bca/read-file-archives-if-binary filename)))
    (if binary-archives
        (if (null? binary-archives)
            #f
            (load-archive-section-form (car binary-archives)))
        (let ((port (open-input-file filename)))
          (let ((result (load-section-from-port port)))
            (close-input-port port)
            result)))))

(define (load-bundle filename)
  "Load and execute all sections from a .ecec bundle file.
The bundle is discovered first so module units can be imported regardless of
section order. File sections still execute sequentially in bundle order.
Accepts printed and binary archive files. Returns the result of the last
section."
  (define (load-materialized-sections sections)
    (for-each archive/register-bundle-section! sections)
    (let loop ((rest sections) (last-result #f))
      (if (null? rest)
          last-result
          (loop (cdr rest)
                (archive/load-materialized-section (car rest) #t)))))
  (let ((binary-archives (bca/read-file-archives-if-binary filename)))
    (if binary-archives
        (load-materialized-sections
         (map archive/materialize-section binary-archives))
        (let ((port (open-input-file filename)))
          (define (read-sections sections)
            (let ((archive (read-archive-section-form port)))
              (if (eof? archive)
                  (reverse sections)
                  (read-sections
                   (cons (archive/materialize-section archive) sections)))))
          (let ((sections (read-sections '())))
            (close-input-port port)
            (load-materialized-sections sections))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §8: .ecec archive format (version 2)
;;;
;;; Shape:
;;;   (:ecec-archive
;;;     :version 2
;;;     :kind <optional, default :file>
;;;     :file "foo.scm"
;;;     :unit-id <optional-explicit-unit-id>
;;;     :phase <optional, default 0>
;;;     :imports <optional, default ()>
;;;     :exports <optional, default :all>
;;;     :init <optional, default 0>
;;;     :entries ((:code-object :name %init :instructions (...) ...)
;;;               (:code-object :name add1 :instructions (...) ...)
;;;              ...))
;;;
;;; Tag symbols use the ECE keyword spelling (`:foo`). During the keyword-
;;; format transition, readers still accept legacy plain-symbol tags via
;;; archive/plist-get and load-section-from-port.
;;;
;;; - Entry 0 is the file's init code-object (top-level forms, merged).
;;; - Entries 1..N are nested lambdas hoisted to archive level.
;;; - Inner references use (const (co-ref N)) — second pass at load time
;;;   patches these to the actual code-object values.
;;; - resolved-instructions rebuilt at load via resolve-operations.
;;; ─────────────────────────────────────────────────────────────────────────

(define (archive/plist-get plist key)
  "Walk a keyword-tagged plist, return value after KEY or #f.
During the keyword-format transition this also accepts the legacy
plain-symbol form of KEY (KEY minus the leading colon) so old-format
archives still load. Simplify to a strict eq? once every .ecec is in
the keyword format."
  (cond
   ((null? plist) #f)
   ((null? (cdr plist)) #f)
   ((eq? (car plist) key) (cadr plist))
   ((archive/key-matches-legacy? (car plist) key) (cadr plist))
   (else (archive/plist-get (cddr plist) key))))

(define (archive/plist-has-key? plist key)
  "Return #t when PLIST contains KEY. Uses the same legacy key matching as
archive/plist-get so metadata defaults work for both current and transition
archive spellings."
  (cond
   ((null? plist) #f)
   ((null? (cdr plist)) #f)
   ((eq? (car plist) key) #t)
   ((archive/key-matches-legacy? (car plist) key) #t)
   (else (archive/plist-has-key? (cddr plist) key))))

(define (archive/key-matches-legacy? sym key)
  "Return #t when SYM is the plain-symbol form of a keyword KEY (KEY minus
the leading colon). Only fires when KEY starts with #\\:."
  (and (symbol? sym)
       (symbol? key)
       (let ((kn (symbol->string key)))
         (and (> (string-length kn) 0)
              (char=? (string-ref kn 0) #\:)
              (string=? (symbol->string sym)
                        (substring kn 1 (string-length kn)))))))

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
    (list ':code-object
          ':name (code-object-name co)
          ':arity (code-object-arity co)
          ':source-loc (code-object-source-loc co)
          ':labels (code-object-label-entries co)
          ':instructions rewritten)))

(define (archive/optional-field metadata key)
  "Return (KEY VALUE) when METADATA contains KEY, otherwise ()."
  (if (archive/plist-has-key? metadata key)
      (list key (archive/plist-get metadata key))
      '()))

(define (archive/field-or-default fields key default)
  "Return FIELDS[KEY] when present, otherwise DEFAULT. Unlike `or`, this
preserves explicit #f values so validators can reject malformed metadata
instead of silently defaulting it."
  (if (archive/plist-has-key? fields key)
      (archive/plist-get fields key)
      default))

(define (code-object->archive-sexp top-co filename . maybe-metadata)
  "Build the full archive s-expression from TOP-CO (and all reachable
code-objects) for FILENAME. Optional metadata is a plist containing any of
:kind, :unit-id, :phase, :imports, :exports, or :init. Current file archive
callers omit it, preserving the existing emitted shape."
  (let* ((all-cos (archive/collect-reachable top-co))
         (co-map (%make-hash-table))
         (metadata (if (null? maybe-metadata) '() (car maybe-metadata))))
    (let loop ((cos all-cos) (idx 0))
      (when (pair? cos)
        (hash-set! co-map (car cos) idx)
        (loop (cdr cos) (+ idx 1))))
    (append
     (list ':ecec-archive ':version 2)
     (archive/optional-field metadata ':kind)
     (list ':file filename)
     (archive/optional-field metadata ':unit-id)
     (archive/optional-field metadata ':phase)
     (archive/optional-field metadata ':imports)
     (archive/optional-field metadata ':exports)
     (archive/optional-field metadata ':init)
     (list
      ':entries
      (let loop ((cos all-cos) (acc '()))
        (if (null? cos) (reverse acc)
            (loop (cdr cos)
                  (cons (archive/code-object->entry (car cos) co-map) acc))))))))

(define (archive/file-stem-from-field file-field)
  "Derive the archive stem symbol from the FILE-FIELD string in the
archive wrapper. Returns #f when absent or not a string. Strips any
extension (matches CL archive-file-stem-symbol)."
  (if (string? file-field)
      (let ((len (string-length file-field)))
        (let loop ((i (- len 1)))
          (cond
           ((< i 0) (string->symbol file-field))
           ((char=? (string-ref file-field i) #\.)
            (string->symbol (substring file-field 0 i)))
           (else (loop (- i 1))))))
      #f))

(define (archive/unit-id archive)
  "Return ARCHIVE's semantic unit identity. Current version-2 file
archives synthesize this from :file; future module archives can provide
:unit-id explicitly without changing code-object registry mechanics.
String unit ids are treated as legacy file stems and normalized to symbols."
  (let ((unit-id (archive/plist-get (cdr archive) ':unit-id)))
    (cond
     ((string? unit-id) (string->symbol unit-id))
     (unit-id unit-id)
     (else
      (archive/file-stem-from-field
       (archive/plist-get (cdr archive) ':file))))))

(define (archive/unit-metadata archive)
  "Return normalized archive-unit metadata for ARCHIVE as a plist.
This is the Phase 2 boundary between raw archive sections and future module
registries: file archives default to current semantics, while module-shaped
archives can already carry kind, imports, exports, phase, and init metadata."
  (let ((fields (cdr archive)))
    (list ':kind (archive/field-or-default fields ':kind ':file)
          ':unit-id (archive/unit-id archive)
          ':phase (archive/field-or-default fields ':phase 0)
          ':imports (archive/field-or-default fields ':imports '())
          ':exports (archive/field-or-default fields ':exports ':all)
          ':init (archive/field-or-default fields ':init 0)
          ':file (archive/plist-get fields ':file)
          ':entries (archive/plist-get fields ':entries))))

(define (archive/unit-init-index archive)
  "Return ARCHIVE's init entry index, defaulting to 0 for current archives."
  (archive/plist-get (archive/unit-metadata archive) ':init))

(define (archive/validate-init-index init count)
  "Validate INIT as a code-object index for COUNT archive entries."
  (if (and (integer? init) (>= init 0) (< init count))
      init
      (error (string-append
              "Invalid .ecec archive init index: "
              (write-to-string init)
              " for "
              (number->string count)
              " entries."))))

(define (archive/select-init-code-object archive cos)
  "Return ARCHIVE's selected init code-object from COS, after validating
the metadata-selected index."
  (vector-ref cos
              (archive/validate-init-index
               (archive/unit-init-index archive)
               (vector-length cos))))

(define *archive-units* (%make-hash-table))
(define *module-instances* (%make-hash-table))

(define (archive/unit-key unit-id)
  "Return a stable hash key for UNIT-ID. ECE hash tables are eq?-keyed, so
structured module ids use an interned symbol derived from their flat archive
spelling as the registry key."
  (string->symbol (write-to-string-flat unit-id)))

(define (archive/module-kind? kind)
  "Return #t when KIND names a module archive unit."
  (eq? kind ':module))

(define (archive/module-unit-id? value)
  "Return #t when VALUE has the normalized (module <name> <phase>) shape."
  (and (pair? value) (eq? (car value) 'module)))

(define (archive/module-import-spec? value)
  "Return #t when VALUE is a normalized module import spec."
  (and (pair? value) (eq? (car value) ':module)))

(define (archive/module-import-target import)
  "Return IMPORT's target module name or unit id."
  (if (archive/module-import-spec? import)
      (archive/plist-get import ':module)
      import))

(define (archive/normalize-module-import-id import phase)
  "Normalize IMPORT to a module archive unit id. Phase 3 accepts a normalized
`(:module <target> ...)` import spec, a full `(module <name> <phase>)` unit id,
or the short module name `<name>`."
  (let ((target (archive/module-import-target import)))
    (if (archive/module-unit-id? target)
        target
        (list 'module target phase))))

(define (archive/import-symbol-member? name names)
  "Return #t when NAME appears in NAMES."
  (cond
   ((null? names) #f)
   ((eq? name (car names)) #t)
   (else (archive/import-symbol-member? name (cdr names)))))

(define (archive/import-rename-target name renames)
  "Return NAME's local rename target from RENAMES, or NAME when unrenamed."
  (cond
   ((null? renames) name)
   ((and (pair? (car renames))
         (eq? name (car (car renames))))
    (cadr (car renames)))
   (else (archive/import-rename-target name (cdr renames)))))

(define (archive/import-spec-field import key default)
  "Return KEY from normalized IMPORT spec, or DEFAULT for bare imports."
  (if (archive/module-import-spec? import)
      (if (archive/plist-has-key? import key)
          (archive/plist-get import key)
          default)
      default))

(define (archive/make-unit-record unit cos)
  "Create a mutable archive-unit record as a hash table."
  (let ((record (%make-hash-table)))
    (hash-set! record ':unit-id (archive/plist-get unit ':unit-id))
    (hash-set! record ':kind (archive/plist-get unit ':kind))
    (hash-set! record ':phase (archive/plist-get unit ':phase))
    (hash-set! record ':imports (archive/plist-get unit ':imports))
    (hash-set! record ':exports (archive/plist-get unit ':exports))
    (hash-set! record ':init (archive/validate-init-index
                              (archive/plist-get unit ':init)
                              (vector-length cos)))
    (hash-set! record ':cos cos)
    (hash-set! record ':state ':registered)
    record))

(define (archive/register-unit! unit cos)
  "Register UNIT and COS. Duplicate unit ids are rejected so module identity
stays unambiguous."
  (let ((unit-id (archive/plist-get unit ':unit-id)))
    (when (hash-has-key? *archive-units* (archive/unit-key unit-id))
      (error (string-append "Duplicate archive unit id: "
                            (write-to-string unit-id)
                            ".")))
    (let ((record (archive/make-unit-record unit cos)))
      (hash-set! *archive-units* (archive/unit-key unit-id) record)
      record)))

(define (archive/module-instance-result instance)
  "Return INSTANCE's init result."
  (hash-ref instance ':result #f))

(define (archive/module-instance-exports instance)
  "Return INSTANCE's export table."
  (hash-ref instance ':exports #f))

(define (archive/module-instance-documentation instance)
  "Return INSTANCE's export documentation table."
  (hash-ref instance ':documentation #f))

(define (archive/module-instance module . maybe-phase)
  "Return MODULE's instance, instantiating its registered unit if needed.
MODULE may be a short module name such as (game app) or a normalized
(module <name> <phase>) unit id. MAYBE-PHASE defaults to 0 for short names."
  (let* ((phase (if (null? maybe-phase) 0 (car maybe-phase)))
         (unit-id (archive/normalize-module-import-id module phase))
         (key (archive/unit-key unit-id))
         (existing (hash-ref *module-instances* key #f)))
    (if existing
        existing
        (let ((unit (hash-ref *archive-units* key #f)))
          (when (not unit)
            (error (string-append "Module not found: "
                                  (write-to-string unit-id)
                                  ".")))
          (archive/instantiate-module! unit)))))

(define (archive/module-export module export-name . maybe-phase)
  "Return EXPORT-NAME from MODULE, instantiating MODULE if needed."
  (when (not (symbol? export-name))
    (error "module export name must be a symbol" export-name))
  (let* ((phase (if (null? maybe-phase) 0 (car maybe-phase)))
         (unit-id (archive/normalize-module-import-id module phase))
         (instance (archive/module-instance unit-id))
         (exports (archive/module-instance-exports instance)))
    (when (not (hash-has-key? exports export-name))
      (error (string-append "Module entry export not found: "
                            (write-to-string export-name)
                            " in "
                            (write-to-string unit-id)
                            ".")))
    (hash-ref exports export-name)))

(define (run-module-export module export-name . args)
  "Run MODULE's exported procedure EXPORT-NAME with ARGS."
  (let ((value (archive/module-export module export-name)))
    (when (not (procedure? value))
      (error (string-append "Module entry export is not callable: "
                            (write-to-string export-name)
                            ".")))
    (apply value args)))

(define (module-documentation-entry module export-name . options)
  "Return MODULE's documentation entry for exported EXPORT-NAME, or #f.
Signals an error when EXPORT-NAME is not exported by MODULE."
  (when (not (symbol? export-name))
    (error "module documentation export name must be a symbol" export-name))
  (let* ((phase (documentation/option options :phase 0))
         (kind (documentation/option options :kind #f))
         (unit-id (archive/normalize-module-import-id module phase))
         (instance (archive/module-instance unit-id))
         (exports (archive/module-instance-exports instance))
         (export-docs (archive/module-instance-documentation instance)))
    (when (not (hash-has-key? exports export-name))
      (error (string-append "Module documentation export not found: "
                            (write-to-string export-name)
                            " in "
                            (write-to-string unit-id)
                            ".")))
    (if kind
        (documentation-entry export-name :kind kind :module unit-id)
        (hash-ref export-docs export-name #f))))

(define (module-documentation module export-name . options)
  "Return MODULE's documentation summary for exported EXPORT-NAME, or #f.
Signals an error when EXPORT-NAME is not exported by MODULE."
  (let ((entry (apply module-documentation-entry
                      (cons module (cons export-name options)))))
    (if entry
        (hash-ref entry :summary #f)
        #f)))

(define (archive/module-env-table env)
  "Return the private hash table from a module environment."
  (cdr (car env)))

(define (archive/make-module-env imported-exports)
  "Create a private module environment seeded with IMPORTED-EXPORTS."
  (let ((table (%make-hash-table)))
    (for-each
     (lambda (name)
       (hash-set! table name (hash-ref imported-exports name)))
     (hash-keys imported-exports))
    (cons (cons ':hash-frame table) *global-env*)))

(define (archive/module-instance-for-import import phase importer-id)
  "Resolve and instantiate IMPORT for IMPORTER-ID."
  (let* ((unit-id (archive/normalize-module-import-id import phase))
         (unit (hash-ref *archive-units* (archive/unit-key unit-id) #f)))
    (when (not unit)
      (error (string-append "Module import not found: "
                            (write-to-string unit-id)
                            " imported by "
                            (write-to-string importer-id)
                            ".")))
    (archive/instantiate-module! unit)))

(define (archive/collect-module-imports unit)
  "Instantiate UNIT's imports and return a hash table of imported bindings."
  (let ((bindings (%make-hash-table))
        (providers (%make-hash-table)))
    (define (validate-exported-names! unit-id importer-id exports names context)
      (for-each
       (lambda (name)
         (when (not (hash-has-key? exports name))
           (error (string-append "Module import "
                                 (write-to-string unit-id)
                                 " in "
                                 (write-to-string importer-id)
                                 " "
                                 context
                                 " missing export "
                                 (write-to-string name)
                                 "."))))
       names))
    (define (import-name? name only except)
      (and (or (not only)
               (archive/import-symbol-member? name only))
           (not (archive/import-symbol-member? name except))))
    (define (record-import! local-name value provider-id importer-id)
      (when (hash-has-key? bindings local-name)
        (error (string-append "Ambiguous import "
                              (write-to-string local-name)
                              " in "
                              (write-to-string importer-id)
                              ": provided by "
                              (write-to-string (hash-ref providers local-name))
                              " and "
                              (write-to-string provider-id)
                              ".")))
      (hash-set! bindings local-name value)
      (hash-set! providers local-name provider-id))
    (for-each
     (lambda (import)
       (let* ((unit-id (archive/normalize-module-import-id
                        import
                        (hash-ref unit ':phase)))
              (only (archive/import-spec-field import ':only #f))
              (except (archive/import-spec-field import ':except '()))
              (renames (archive/import-spec-field import ':rename '()))
              (importer-id (hash-ref unit ':unit-id))
              (instance
               (archive/module-instance-for-import
                import
                (hash-ref unit ':phase)
                importer-id))
              (exports (archive/module-instance-exports instance)))
         (when only
           (validate-exported-names!
            unit-id importer-id exports only "only list names"))
         (validate-exported-names!
          unit-id importer-id exports except "except list names")
         (validate-exported-names!
          unit-id
          importer-id
          exports
          (let loop ((rest renames) (acc '()))
            (if (null? rest)
                (reverse acc)
                (loop (cdr rest) (cons (car (car rest)) acc))))
          "rename list names")
         (for-each
          (lambda (exported-name)
            (when (import-name? exported-name only except)
              (let ((local-name
                     (archive/import-rename-target exported-name renames)))
                (record-import!
                 local-name
                 (hash-ref exports exported-name)
                 unit-id
                 importer-id))))
          (hash-keys exports))))
     (hash-ref unit ':imports))
    bindings))

(define (archive/capture-module-exports unit env)
  "Capture UNIT's declared exports from ENV."
  (let ((declared (hash-ref unit ':exports))
        (table (archive/module-env-table env))
        (exports (%make-hash-table)))
    (if (eq? declared ':all)
        (for-each
         (lambda (name)
           (hash-set! exports name (hash-ref table name)))
         (hash-keys table))
        (for-each
         (lambda (name)
           (when (not (hash-has-key? table name))
             (error (string-append "Module "
                                   (write-to-string (hash-ref unit ':unit-id))
                                   " declared missing export "
                                   (write-to-string name)
                                   ".")))
           (hash-set! exports name (hash-ref table name)))
         declared))
    exports))

(define (archive/capture-module-export-documentation unit exports)
  "Capture documentation entries for UNIT's declared EXPORTS."
  (let ((unit-id (hash-ref unit ':unit-id))
        (export-docs (%make-hash-table)))
    (for-each
     (lambda (name)
       (let ((entry (documentation-entry name :module unit-id)))
         (when entry
           (hash-set! export-docs name entry))))
     (hash-keys exports))
    export-docs))

(define (archive/execute-module-init unit init env)
  "Execute UNIT's INIT code with documentation scoped to UNIT."
  (let ((previous (current-documentation-module))
        (unit-id (hash-ref unit ':unit-id)))
    (dynamic-wind
     (lambda () (set-current-documentation-module! unit-id))
     (lambda () (execute-code-object init env))
     (lambda () (set-current-documentation-module! previous)))))

(define (archive/instantiate-module! unit)
  "Instantiate UNIT once, recursively initializing imports first."
  (let ((state (hash-ref unit ':state)))
    (cond
     ((eq? state ':initialized)
      (hash-ref unit ':instance))
     ((eq? state ':initializing)
      (error (string-append "Module import cycle involving "
                            (write-to-string (hash-ref unit ':unit-id))
                            ".")))
     (else
      (when (not (archive/module-kind? (hash-ref unit ':kind)))
        (error (string-append "Import "
                              (write-to-string (hash-ref unit ':unit-id))
                              " does not name a module archive unit.")))
      (hash-set! unit ':state ':initializing)
      (let* ((imports (archive/collect-module-imports unit))
             (env (archive/make-module-env imports))
             (cos (hash-ref unit ':cos))
             (init (vector-ref cos (hash-ref unit ':init)))
             (result (archive/execute-module-init unit init env))
             (exports (archive/capture-module-exports unit env))
             (export-docs
              (archive/capture-module-export-documentation unit exports))
             (instance (%make-hash-table)))
        (hash-set! instance ':unit-id (hash-ref unit ':unit-id))
        (hash-set! instance ':env env)
        (hash-set! instance ':exports exports)
        (hash-set! instance ':documentation export-docs)
        (hash-set! instance ':result result)
        (hash-set! unit ':env env)
        (hash-set! unit ':documentation export-docs)
        (hash-set! unit ':result result)
        (hash-set! unit ':instance instance)
        (hash-set! unit ':state ':initialized)
        (hash-set! *module-instances*
                   (archive/unit-key (hash-ref unit ':unit-id))
                   instance)
        instance)))))

(define (archive/code-object-key unit-id index)
  "Return the registry key for code-object INDEX in UNIT-ID."
  (cons unit-id index))

(define (archive-sexp->code-objects archive)
  "Parse an archive s-expression (as read from disk). Returns the vector
of code-objects. Current file archives use entry 0 as the init code-object;
module-shaped archives may select another init entry with :init. Raises on
version mismatch. Stamps archive-key = (unit-id . index) on each code-object
so the serializer can emit by-reference forms."
  (let* ((unit (archive/unit-metadata archive))
         (version (archive/plist-get (cdr archive) ':version))
         (entries (archive/plist-get unit ':entries))
         (unit-id (archive/plist-get unit ':unit-id)))
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
            (when (archive/plist-get fields ':name)
              (%code-object-set-name! co (archive/plist-get fields ':name)))
            (when (archive/plist-get fields ':arity)
              (%code-object-set-arity! co (archive/plist-get fields ':arity)))
            (when (archive/plist-get fields ':source-loc)
              (%code-object-set-source-loc! co (archive/plist-get fields ':source-loc)))
            (for-each (lambda (pair)
                        (%code-object-set-label! co (car pair) (cdr pair)))
                      (archive/plist-get fields ':labels))
            (when unit-id
              (%code-object-set-archive-key!
               co (archive/code-object-key unit-id i)))
            (vector-set! cos i co))
          (loop (+ i 1))))
      ;; Pass 2: push instructions (with (co-ref N) patched to code-objects).
      (let loop ((i 0))
        (when (< i n)
          (let* ((entry (vector-ref entries-vec i))
                 (co (vector-ref cos i))
                 (raw-instrs (archive/plist-get (cdr entry) ':instructions)))
            (for-each (lambda (instr)
                        (%code-object-push-instruction!
                         co (archive/patch-co-refs instr cos)))
                      raw-instrs))
          (loop (+ i 1))))
      cos)))

(define (load-archive-from-port port)
  "Read an archive from PORT, build all code-objects, execute the init
entry selected by metadata. Returns the init's result."
  (let ((archive (ece-scheme-read port)))
    (load-archive-section-form archive)))

(define (load-archive filename)
  "Load and execute a code-object archive from FILENAME. Returns the
result of the init code-object."
  (let ((port (open-input-file filename)))
    (let ((result (load-archive-from-port port)))
      (close-input-port port)
      result)))

(define (module/source-form? expr)
  "Return #t when EXPR is a source-level define-module form."
  (and (pair? expr) (eq? (car expr) 'define-module)))

(define (module/symbol-list? value)
  "Return #t when VALUE is a proper list of symbols."
  (cond
   ((null? value) #t)
   ((and (pair? value) (symbol? (car value)))
    (module/symbol-list? (cdr value)))
   (else #f)))

(define (module/source-name? value)
  "Return #t when VALUE is a non-empty module name such as (game inventory)."
  (and (pair? value) (module/symbol-list? value)))

(define (module/import-form? expr)
  "Return #t when EXPR is a module import declaration."
  (and (pair? expr) (eq? (car expr) 'import)))

(define (module/export-form? expr)
  "Return #t when EXPR is a module export declaration."
  (and (pair? expr) (eq? (car expr) 'export)))

(define (module/append-reversed items acc)
  "Prepend ITEMS to ACC while preserving ITEMS' order after ACC is reversed."
  (let loop ((rest items) (result acc))
    (if (null? rest)
        result
        (loop (cdr rest) (cons (car rest) result)))))

(define (module/plain-import? value)
  "Return #t when VALUE is a direct module import target."
  (or (module/source-name? value)
      (archive/module-unit-id? value)))

(define (module/rename-list? value)
  "Return #t when VALUE is a proper list of (exported local) symbol pairs."
  (cond
   ((null? value) #t)
   ((and (pair? value)
         (pair? (car value))
         (symbol? (car (car value)))
         (pair? (cdr (car value)))
         (symbol? (cadr (car value)))
         (null? (cddr (car value))))
    (module/rename-list? (cdr value)))
   (else #f)))

(define (module/normalize-import import)
  "Normalize one source import declaration for archive metadata."
  (cond
   ((module/plain-import? import) import)
   ((and (pair? import) (eq? (car import) 'only))
    (when (or (not (pair? (cdr import)))
              (not (module/plain-import? (cadr import)))
              (not (module/symbol-list? (cddr import))))
      (error "define-module: expected (only <module> <symbol> ...) import"))
    (list ':module (cadr import) ':only (cddr import)))
   ((and (pair? import) (eq? (car import) 'except))
    (when (or (not (pair? (cdr import)))
              (not (module/plain-import? (cadr import)))
              (not (module/symbol-list? (cddr import))))
      (error "define-module: expected (except <module> <symbol> ...) import"))
    (list ':module (cadr import) ':except (cddr import)))
   ((and (pair? import) (eq? (car import) 'rename))
    (when (or (not (pair? (cdr import)))
              (not (module/plain-import? (cadr import)))
              (not (module/rename-list? (cddr import))))
      (error "define-module: expected (rename <module> (<from> <to>) ...) import"))
    (list ':module (cadr import) ':rename (cddr import)))
   (else
    (error "define-module: imports must be module names, (module <name> <phase>) unit ids, or only/except/rename specs"))))

(define (module/normalize-imports imports)
  "Normalize a proper list of source imports."
  (let loop ((rest imports) (acc '()))
    (if (null? rest)
        (reverse acc)
        (loop (cdr rest)
              (cons (module/normalize-import (car rest)) acc)))))

(define (module/parse-define-module form)
  "Parse a source-level define-module form into a plist:
:name, :imports, :exports, and :body. Phase 4 deliberately accepts only
static value imports/exports and one module per source file."
  (when (or (not (pair? (cdr form)))
            (not (module/source-name? (cadr form))))
    (error "define-module: expected (define-module (<name> ...) ...)"))
  (let ((name (cadr form)))
    (let loop ((forms (cddr form))
               (imports '())
               (exports '())
               (body '())
               (body-started? #f))
      (cond
       ((null? forms)
        (list ':name name
              ':imports (reverse imports)
              ':exports (reverse exports)
              ':body (reverse body)))
       ((module/import-form? (car forms))
        (when body-started?
          (error "define-module: import declarations must precede body forms"))
        (loop (cdr forms)
              (module/append-reversed
               (module/normalize-imports (cdr (car forms)))
               imports)
              exports
              body
              #f))
       ((module/export-form? (car forms))
        (when body-started?
          (error "define-module: export declarations must precede body forms"))
        (when (not (module/symbol-list? (cdr (car forms))))
          (error "define-module: exports must be symbols"))
        (loop (cdr forms)
              imports
              (module/append-reversed (cdr (car forms)) exports)
              body
              #f))
       (else
        (loop (cdr forms)
              imports
              exports
              (cons (car forms) body)
              #t))))))

(define (compile-file->archive-result filename)
  "Compile all forms in FILENAME via mc-compile-to-code-object.
Returns (TOP-CO . ARCHIVE), where ARCHIVE is the §8 archive form. A file
containing one top-level define-module form emits a :module archive section."
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
      (define (define-syntax-to-define-macro expr)
        (let ((name (cadr expr))
              (transformer-expr (caddr expr)))
          (if (and (pair? transformer-expr)
                   (eq? (car transformer-expr) 'syntax-rules))
              (let ((literals (cadr transformer-expr))
                    (clauses (cddr transformer-expr)))
                (list 'define-macro
                      (cons name '%syntax-args)
                      (list 'syntax-rules-expand
                            (list 'quote literals)
                            (list 'quote clauses)
                            (list 'cons
                                  (list 'quote name)
                                  '%syntax-args))))
              (error "define-syntax: only syntax-rules transformers are supported"))))
      (define (maybe-expand-define-syntax expr)
        (if (and (pair? expr) (eq? (car expr) 'define-syntax))
            (if (get-macro 'define-syntax)
                (mc-expand-macro-at-compile-time
                 (get-macro 'define-syntax) (cdr expr))
                (define-syntax-to-define-macro expr))
            expr))
      (define (documentation-registration name kind doc signature)
        (list 'set-documentation!
              (list 'quote name)
              (list 'quote kind)
              doc
              :signature
              (list 'quote signature)))
      (define (define-macro/doc-form? expr)
        (and (pair? expr) (eq? (car expr) 'define-macro/doc)))
      (define (define-syntax/doc-form? expr)
        (and (pair? expr) (eq? (car expr) 'define-syntax/doc)))
      (define (define-macro/doc-valid? expr)
        (and (pair? (cdr expr))
             (pair? (cadr expr))
             (pair? (cddr expr))))
      (define (define-syntax/doc-valid? expr)
        (and (pair? (cdr expr))
             (pair? (cddr expr))
             (pair? (cdddr expr))
             (null? (cdr (cdddr expr)))))
      (define (define-macro/doc->define-macro expr)
        (if (define-macro/doc-valid? expr)
            (cons 'define-macro (cons (cadr expr) (cdddr expr)))
            (error "define-macro/doc: expected (define-macro/doc (name args...) doc body ...)")))
      (define (define-syntax/doc->define-syntax expr)
        (if (define-syntax/doc-valid? expr)
            (list 'define-syntax (cadr expr) (cadddr expr))
            (error "define-syntax/doc: expected (define-syntax/doc name doc transformer)")))
      (define (prepare-form expr)
        (cond
         ((define-macro/doc-form? expr)
          (let* ((macro-expr (define-macro/doc->define-macro expr))
                 (name (car (cadr macro-expr)))
                 (doc (caddr expr)))
            (mc-compile-and-go macro-expr)
            (list 'begin
                  (define-macro-to-set-macro macro-expr)
                  (documentation-registration name 'macro doc (cadr macro-expr))
                  (list 'quote name))))
         ((define-syntax/doc-form? expr)
          (let* ((syntax-expr (define-syntax/doc->define-syntax expr))
                 (macro-expr (maybe-expand-define-syntax syntax-expr))
                 (name (cadr expr))
                 (doc (caddr expr)))
            (mc-compile-and-go macro-expr)
            (list 'begin
                  (define-macro-to-set-macro macro-expr)
                  (documentation-registration name 'syntax doc name)
                  (list 'quote name))))
         (else
          (let ((expanded (maybe-expand-define-syntax expr)))
            (when (and (pair? expanded) (eq? (car expanded) 'define-macro))
              (mc-compile-and-go expanded))
            (if (and (pair? expanded) (eq? (car expanded) 'define-macro))
                (define-macro-to-set-macro expanded)
                expanded)))))
      (define (prepare-forms forms)
        (let loop ((rest forms) (acc '()))
          (if (null? rest)
              (reverse acc)
              (loop (cdr rest)
                    (cons (prepare-form (car rest)) acc)))))
      (define (read-loop forms)
        (let ((expr (ece-scheme-read in)))
          (if (eof? expr)
              (begin (close-input-port in) (reverse forms))
              (read-loop (cons expr forms)))))
      (define (module-form forms)
        (let loop ((rest forms) (found #f))
          (cond
           ((null? rest) found)
           ((module/source-form? (car rest))
            (when found
              (error "define-module: only one module form is allowed per file"))
            (loop (cdr rest) (car rest)))
           (else (loop (cdr rest) found)))))
      (let* ((raw-forms (read-loop '()))
             (module (module-form raw-forms))
             (module-data
              (if module (module/parse-define-module module) #f))
             (forms
              (if module
                  (begin
                    (when (or (pair? (cdr raw-forms))
                              (not (module/source-form? (car raw-forms))))
                      (error "define-module: module files may contain only the module form"))
                    (prepare-forms (archive/plist-get module-data ':body)))
                  (prepare-forms raw-forms)))
             (metadata
              (if module
                  (let ((name (archive/plist-get module-data ':name)))
                    (list ':kind ':module
                          ':unit-id (list 'module name 0)
                          ':phase 0
                          ':imports (archive/plist-get module-data ':imports)
                          ':exports (archive/plist-get module-data ':exports)))
                  '()))
             ;; Wrap all forms in (begin ...) so mc-compile-to-code-object
             ;; gets a single expression. define-variable! side effects
             ;; sequence correctly inside begin.
             (top-co (mc-compile-to-code-object (cons 'begin forms))))
        ;; NOTE: we intentionally DO NOT populate code-object-source-loc
        ;; per-code-object here. Source origin is recorded once at the
        ;; archive level via the `file` field in the archive wrapper
        ;; (see `code-object->archive-sexp` below). Stamping a list-shaped
        ;; source-loc on every code-object broke the WASM loader's
        ;; cast in `$%code-object-set-source-loc!`. Per-PC source-map
        ;; tracking is diagnostics roadmap thread 5 — a separate proposal.
        (let ((archive (code-object->archive-sexp top-co basename metadata)))
          (set! *source-locations* (%make-hash-table))
          (set! *source-file-name* #f)
          (cons top-co archive))))))

(define (compile-file->archive filename)
  "Compile FILENAME and return its §8 archive form without writing a file."
  (cdr (compile-file->archive-result filename)))

(define (compile-file-to-archive filename output-port)
  "Compile all forms in FILENAME and write the resulting printed archive to
OUTPUT-PORT. Returns the top-level code object for compatibility with older
tests and tooling."
  (let* ((result (compile-file->archive-result filename))
         (archive (cdr result)))
    (write-string-to-port (write-to-string-flat archive) output-port)
    (write-char #\newline output-port)
    (car result)))

(define (compile-file-archive filename)
  "Compile FILENAME to a .ecec archive file. Returns the output filename."
  (let* ((output-name
          (string-append (filename-strip-extension filename ".scm") ".ecec"))
         (out (open-output-file output-name)))
    (compile-file-to-archive filename out)
    (close-output-port out)
    output-name))

(define (compile-file/sexp filename)
  "Compile FILENAME to a printed .ecec archive file. Returns the output path."
  (compile-file-archive filename))

(define (compile-file/binary filename)
  "Compile FILENAME to a binary .ecec archive file. Returns the output path."
  (let ((output-name
         (string-append (filename-strip-extension filename ".scm") ".ecec")))
    (bca/write-bytes-to-file
     (bca/encode-archive (compile-file->archive filename))
     output-name)))

;;; -------------------------------------------------------------------------
;;; Binary compiled archive codec, phase 1
;;;
;;; This is the first small slice of the binary .ecec plan: stable byte
;;; helpers, header detection, a compact datum codec, and instruction encoding.
;;; It intentionally works on byte lists so the format can be tested before the
;;; runtime loaders switch from text archives.
;;; -------------------------------------------------------------------------

(define bca/magic-bytes '(69 67 69 67 0 66 73 78)) ; "ECEC\0BIN"
(define bca/codec-version 1)
(define bca/default-archive-version 2)

(define bca/tag-nil 1)
(define bca/tag-true 2)
(define bca/tag-false 3)
(define bca/tag-integer 4)
(define bca/tag-symbol 5)
(define bca/tag-string 6)
(define bca/tag-cons 7)
(define bca/tag-vector 8)
(define bca/tag-co-ref 9)
(define bca/tag-character 10)
(define bca/tag-float64 11)
(define bca/tag-string32 12)

(define bca/instr-assign 1)
(define bca/instr-test 2)
(define bca/instr-perform 3)
(define bca/instr-save 4)
(define bca/instr-restore 5)
(define bca/instr-goto 6)
(define bca/instr-branch 7)
(define bca/instr-halt 8)

(define bca/operand-reg 1)
(define bca/operand-const 2)
(define bca/operand-op 3)
(define bca/operand-label 4)

(define bca/section-archive 1)

(define (bca/check-byte b who)
  (when (not (and (integer? b) (>= b 0) (< b 256)))
    (error (string-append who ": expected byte") b)))

(define (bca/prepend-bytes bytes tail)
  (let loop ((rest (reverse bytes)) (acc tail))
    (if (null? rest)
        acc
        (loop (cdr rest) (cons (car rest) acc)))))

(define (bca/append-byte-chunks chunks)
  (let loop ((rest (reverse chunks)) (acc '()))
    (if (null? rest)
        acc
        (loop (cdr rest) (bca/prepend-bytes (car rest) acc)))))

(define (bca/encode-u8 n)
  (bca/check-byte n "bca/encode-u8")
  (list n))

(define (bca/encode-u16 n)
  (when (not (and (integer? n) (>= n 0) (< n 65536)))
    (error "bca/encode-u16: expected unsigned 16-bit integer" n))
  (list (quotient n 256)
        (modulo n 256)))

(define (bca/encode-u32 n)
  (when (not (and (integer? n)
                  (>= n 0)
                  (< (quotient n 65536) 65536)))
    (error "bca/encode-u32: expected unsigned 32-bit integer" n))
  (let* ((b0 (quotient n 16777216))
         (r0 (modulo n 16777216))
         (b1 (quotient r0 65536))
         (r1 (modulo r0 65536))
         (b2 (quotient r1 256))
         (b3 (modulo r1 256)))
    (list b0 b1 b2 b3)))

(define (bca/encode-float64 n)
  (let ((bytes (%float64->bytes n)))
    (when (not (= (length bytes) 8))
      (error "bca/encode-float64: expected eight bytes from host"))
    (for-each (lambda (b) (bca/check-byte b "bca/encode-float64")) bytes)
    (append (list bca/tag-float64) bytes)))

(define (bca/read-float64 bytes)
  (let loop ((i 0) (tail bytes) (acc '()))
    (if (= i 8)
        (cons (%bytes->float64 (reverse acc)) tail)
        (let ((r (bca/read-u8 tail)))
          (loop (+ i 1) (cdr r) (cons (car r) acc))))))

(define (bca/read-u8 bytes)
  (when (null? bytes)
    (error "bca/read-u8: truncated input"))
  (bca/check-byte (car bytes) "bca/read-u8")
  (cons (car bytes) (cdr bytes)))

(define (bca/read-u16 bytes)
  (let* ((r0 (bca/read-u8 bytes))
         (r1 (bca/read-u8 (cdr r0))))
    (cons (+ (* (car r0) 256) (car r1))
          (cdr r1))))

(define (bca/read-u32 bytes)
  (let* ((r0 (bca/read-u8 bytes))
         (r1 (bca/read-u8 (cdr r0)))
         (r2 (bca/read-u8 (cdr r1)))
         (r3 (bca/read-u8 (cdr r2))))
    (cons (+ (* (car r0) 16777216)
             (* (car r1) 65536)
             (* (car r2) 256)
             (car r3))
          (cdr r3))))

(define (bca/string->bytes s)
  (let ((len (string-length s)))
    (let loop ((i 0) (acc '()))
      (if (= i len)
          (reverse acc)
          (let ((b (char->integer (string-ref s i))))
            (when (not (and (integer? b) (>= b 0) (< b 256)))
              (error
               "bca/string->bytes: binary archives currently support only byte-valued characters"
               s))
            (loop (+ i 1) (cons b acc)))))))

(define (bca/byte-string? s)
  (let ((len (string-length s)))
    (let loop ((i 0))
      (cond
       ((= i len) #t)
       (else
        (let ((b (char->integer (string-ref s i))))
          (if (and (integer? b) (>= b 0) (< b 256))
              (loop (+ i 1))
              #f)))))))

(define (bca/bytes->string bytes)
  (let ((out (open-output-string)))
    (let loop ((rest bytes))
      (if (null? rest)
          (get-output-string out)
          (begin
            (bca/check-byte (car rest) "bca/bytes->string")
            (write-char (integer->char (car rest)) out)
            (loop (cdr rest)))))))

(define (bca/has-at-least? bytes count)
  (cond
   ((= count 0) #t)
   ((null? bytes) #f)
   (else (bca/has-at-least? (cdr bytes) (- count 1)))))

(define (bca/encode-byte-string s)
  (let ((bytes (bca/string->bytes s)))
    (append (bca/encode-u32 (length bytes)) bytes)))

(define (bca/encode-string32 s)
  (let ((len (string-length s)))
    (let loop ((i 0) (chunks (list (bca/encode-u32 len)
                                   (list bca/tag-string32))))
      (if (= i len)
          (bca/append-byte-chunks (reverse chunks))
          (loop (+ i 1)
                (cons (bca/encode-u32
                       (char->integer (string-ref s i)))
                      chunks))))))

(define (bca/read-byte-string bytes)
  (let* ((len-result (bca/read-u32 bytes))
         (len (car len-result)))
    (when (not (bca/has-at-least? (cdr len-result) len))
      (error "bca/read-byte-string: length exceeds remaining bytes" len))
    (let loop ((i 0) (rest (cdr len-result)) (acc '()))
      (if (= i len)
          (cons (bca/bytes->string (reverse acc)) rest)
          (let ((r (bca/read-u8 rest)))
            (loop (+ i 1) (cdr r) (cons (car r) acc)))))))

(define (bca/read-string32 bytes)
  (let* ((len-result (bca/read-u32 bytes))
         (len (car len-result)))
    (when (not (bca/has-at-least? (cdr len-result) (* len 4)))
      (error "bca/read-string32: length exceeds remaining bytes" len))
    (let loop ((i 0) (rest (cdr len-result)) (out (open-output-string)))
      (if (= i len)
          (cons (get-output-string out) rest)
          (let ((r (bca/read-u32 rest)))
            (write-char (integer->char (car r)) out)
            (loop (+ i 1) (cdr r) out))))))

(define (bca/encode-header section-count . maybe-archive-version)
  (let ((archive-version
         (if (null? maybe-archive-version)
             bca/default-archive-version
             (car maybe-archive-version))))
    (append bca/magic-bytes
            (bca/encode-u16 bca/codec-version)
            (bca/encode-u16 archive-version)
            (bca/encode-u32 0)
            (bca/encode-u32 section-count))))

(define (bca/read-magic bytes)
  (let loop ((expected bca/magic-bytes) (rest bytes))
    (cond
     ((null? expected) rest)
     ((null? rest) (error "bca/read-header: truncated magic"))
     ((= (car expected) (car rest))
      (loop (cdr expected) (cdr rest)))
     (else (error "bca/read-header: bad binary archive magic")))))

(define (bca/read-header bytes)
  (let* ((after-magic (bca/read-magic bytes))
         (codec (bca/read-u16 after-magic))
         (archive-version (bca/read-u16 (cdr codec)))
         (flags (bca/read-u32 (cdr archive-version)))
         (section-count (bca/read-u32 (cdr flags))))
    (cons (list ':binary-archive
                ':codec-version (car codec)
                ':archive-version (car archive-version)
                ':flags (car flags)
                ':section-count (car section-count))
          (cdr section-count))))

(define (bca/encode-optional-datum value present?)
  (if present?
      (append (list 1) (bca/encode-datum value))
      (list 0)))

(define (bca/read-optional-datum bytes)
  (let ((present (bca/read-u8 bytes)))
    (cond
     ((= (car present) 0) (cons (cons #f #f) (cdr present)))
     ((= (car present) 1)
      (let ((datum (bca/read-datum (cdr present))))
        (cons (cons #t (car datum)) (cdr datum))))
     (else (error "bca/read-optional-datum: invalid presence byte"
                  (car present))))))

(define (bca/optional-datum-present? decoded)
  (car decoded))

(define (bca/optional-datum-value decoded)
  (cdr decoded))

(define (bca/encode-archive-field archive-fields key)
  (bca/encode-optional-datum
   (archive/plist-get archive-fields key)
   (archive/plist-has-key? archive-fields key)))

(define (bca/append-archive-field fields key decoded)
  (if (bca/optional-datum-present? decoded)
      (append fields (list key (bca/optional-datum-value decoded)))
      fields))

(define (bca/register-id reg)
  (cond
   ((eq? reg 'val) 0)
   ((eq? reg 'env) 1)
   ((eq? reg 'proc) 2)
   ((eq? reg 'argl) 3)
   ((eq? reg 'continue) 4)
   ((eq? reg 'stack) 5)
   (else (error "bca/register-id: unknown register" reg))))

(define (bca/id->register id)
  (cond
   ((= id 0) 'val)
   ((= id 1) 'env)
   ((= id 2) 'proc)
   ((= id 3) 'argl)
   ((= id 4) 'continue)
   ((= id 5) 'stack)
   (else (error "bca/id->register: unknown register id" id))))

(define (bca/operation-id op)
  (cond
   ((eq? op 'lookup-variable-value) 0)
   ((eq? op 'lookup-global-variable) 1)
   ((eq? op 'set-variable-value!) 2)
   ((eq? op 'define-variable!) 3)
   ((eq? op 'extend-environment) 4)
   ((eq? op 'lexical-ref) 5)
   ((eq? op 'lexical-set!) 6)
   ((eq? op 'make-compiled-procedure) 7)
   ((eq? op 'compiled-procedure-entry) 8)
   ((eq? op 'compiled-procedure-env) 9)
   ((eq? op 'primitive-procedure?) 10)
   ((eq? op 'continuation?) 11)
   ((eq? op 'parameter?) 12)
   ((eq? op 'apply-primitive-procedure) 13)
   ((eq? op 'apply-parameter) 14)
   ((eq? op 'parameter-ref) 15)
   ((eq? op 'parameter-set!) 16)
   ((eq? op 'parameter-raw-set!) 17)
   ((eq? op 'capture-continuation) 18)
   ((eq? op 'do-continuation-winds) 19)
   ((eq? op 'continuation-stack) 20)
   ((eq? op 'continuation-conts) 21)
   ((eq? op 'false?) 22)
   ((eq? op 'list) 23)
   ((eq? op 'cons) 24)
   ((eq? op 'car) 25)
   ((eq? op 'cdr) 26)
   (else (error "bca/operation-id: unknown operation" op))))

(define (bca/id->operation id)
  (cond
   ((= id 0) 'lookup-variable-value)
   ((= id 1) 'lookup-global-variable)
   ((= id 2) 'set-variable-value!)
   ((= id 3) 'define-variable!)
   ((= id 4) 'extend-environment)
   ((= id 5) 'lexical-ref)
   ((= id 6) 'lexical-set!)
   ((= id 7) 'make-compiled-procedure)
   ((= id 8) 'compiled-procedure-entry)
   ((= id 9) 'compiled-procedure-env)
   ((= id 10) 'primitive-procedure?)
   ((= id 11) 'continuation?)
   ((= id 12) 'parameter?)
   ((= id 13) 'apply-primitive-procedure)
   ((= id 14) 'apply-parameter)
   ((= id 15) 'parameter-ref)
   ((= id 16) 'parameter-set!)
   ((= id 17) 'parameter-raw-set!)
   ((= id 18) 'capture-continuation)
   ((= id 19) 'do-continuation-winds)
   ((= id 20) 'continuation-stack)
   ((= id 21) 'continuation-conts)
   ((= id 22) 'false?)
   ((= id 23) 'list)
   ((= id 24) 'cons)
   ((= id 25) 'car)
   ((= id 26) 'cdr)
   (else (error "bca/id->operation: unknown operation id" id))))

(define (bca/unsupported-datum-message datum)
  (string-append
   "bca/encode-datum: unsupported datum type "
   (cond
    ((code-object? datum) "code-object")
    ((hash-table? datum) "hash-table")
    ((vector? datum) "vector")
    ((pair? datum) "pair")
    ((symbol? datum) "symbol")
    ((keyword? datum) "keyword")
    ((char? datum) "char")
    ((string? datum) "string")
    ((integer? datum) "integer")
    ((number? datum) "number")
    (else "unknown"))))

(define (bca/encode-datum datum)
  (cond
   ((null? datum) (list bca/tag-nil))
   ((eq? datum #t) (list bca/tag-true))
   ((eq? datum #f) (list bca/tag-false))
   ((integer? datum)
    (append (list bca/tag-integer (if (< datum 0) 1 0))
            (bca/encode-u32 (if (< datum 0) (- 0 datum) datum))))
   ((number? datum)
    (bca/encode-float64 datum))
   ((char? datum)
    (append (list bca/tag-character)
            (bca/encode-u32 (char->integer datum))))
   ((symbol? datum)
    (append (list bca/tag-symbol)
            (bca/encode-byte-string (symbol->string datum))))
   ((string? datum)
    (if (bca/byte-string? datum)
        (append (list bca/tag-string)
                (bca/encode-byte-string datum))
        (bca/encode-string32 datum)))
   ((vector? datum)
    (let ((n (vector-length datum)))
      (let loop ((i 0) (chunks (list (bca/encode-u32 n)
                                     (list bca/tag-vector))))
        (if (= i n)
            (bca/append-byte-chunks (reverse chunks))
            (loop (+ i 1)
                  (cons (bca/encode-datum (vector-ref datum i))
                        chunks))))))
   ((and (pair? datum) (eq? (car datum) 'co-ref))
    (append (list bca/tag-co-ref)
            (bca/encode-u32 (cadr datum))))
   ((pair? datum)
    (append (list bca/tag-cons)
            (bca/encode-datum (car datum))
            (bca/encode-datum (cdr datum))))
   (else (error (bca/unsupported-datum-message datum)))))

(define (bca/read-datum bytes)
  (let* ((tag-result (bca/read-u8 bytes))
         (tag (car tag-result))
         (rest (cdr tag-result)))
    (cond
     ((= tag bca/tag-nil) (cons '() rest))
     ((= tag bca/tag-true) (cons #t rest))
     ((= tag bca/tag-false) (cons #f rest))
     ((= tag bca/tag-integer)
      (let* ((sign-result (bca/read-u8 rest))
             (sign (car sign-result)))
        (when (not (or (= sign 0) (= sign 1)))
          (error "bca/read-datum: invalid integer sign byte" sign))
        (let* ((mag-result (bca/read-u32 (cdr sign-result)))
               (mag (car mag-result)))
          (cons (if (= sign 1) (- 0 mag) mag)
                (cdr mag-result)))))
     ((= tag bca/tag-symbol)
      (let ((r (bca/read-byte-string rest)))
        (cons (string->symbol (car r)) (cdr r))))
     ((= tag bca/tag-string)
      (bca/read-byte-string rest))
     ((= tag bca/tag-string32)
      (bca/read-string32 rest))
     ((= tag bca/tag-vector)
      (let* ((len-result (bca/read-u32 rest))
             (len (car len-result)))
        (when (not (bca/has-at-least? (cdr len-result) len))
          (error "bca/read-datum: vector length exceeds remaining bytes" len))
        (let ((vec (make-vector len)))
          (let loop ((i 0) (tail (cdr len-result)))
            (if (= i len)
                (cons vec tail)
                (let ((item (bca/read-datum tail)))
                  (vector-set! vec i (car item))
                  (loop (+ i 1) (cdr item))))))))
     ((= tag bca/tag-co-ref)
      (let ((r (bca/read-u32 rest)))
        (cons (list 'co-ref (car r)) (cdr r))))
     ((= tag bca/tag-character)
      (let ((r (bca/read-u32 rest)))
        (cons (integer->char (car r)) (cdr r))))
     ((= tag bca/tag-float64)
      (bca/read-float64 rest))
     ((= tag bca/tag-cons)
      (let* ((head (bca/read-datum rest))
             (tail (bca/read-datum (cdr head))))
        (cons (cons (car head) (car tail)) (cdr tail))))
     (else (error "bca/read-datum: unknown datum tag" tag)))))

(define (bca/encode-operand operand)
  (cond
   ((and (pair? operand) (eq? (car operand) 'reg))
    (append (list bca/operand-reg)
            (bca/encode-u8 (bca/register-id (cadr operand)))))
   ((and (pair? operand) (eq? (car operand) 'const))
    (append (list bca/operand-const)
            (bca/encode-datum (cadr operand))))
   ((and (pair? operand) (eq? (car operand) 'op))
    (append (list bca/operand-op)
            (bca/encode-u16 (bca/operation-id (cadr operand)))))
   ((and (pair? operand) (eq? (car operand) 'label))
    (append (list bca/operand-label)
            (bca/encode-datum (cadr operand))))
   (else (error "bca/encode-operand: unsupported operand" operand))))

(define (bca/read-operand bytes)
  (let* ((tag-result (bca/read-u8 bytes))
         (tag (car tag-result))
         (rest (cdr tag-result)))
    (cond
     ((= tag bca/operand-reg)
      (let ((id (bca/read-u8 rest)))
        (cons (list 'reg (bca/id->register (car id))) (cdr id))))
     ((= tag bca/operand-const)
      (let ((datum (bca/read-datum rest)))
        (cons (list 'const (car datum)) (cdr datum))))
     ((= tag bca/operand-op)
      (let ((id (bca/read-u16 rest)))
        (cons (list 'op (bca/id->operation (car id))) (cdr id))))
     ((= tag bca/operand-label)
      (let ((datum (bca/read-datum rest)))
        (cons (list 'label (car datum)) (cdr datum))))
     (else (error "bca/read-operand: unknown operand tag" tag)))))

(define (bca/encode-operand-list operands)
  (let loop ((rest operands)
             (acc (bca/encode-u16 (length operands))))
    (if (null? rest)
        acc
        (loop (cdr rest) (append acc (bca/encode-operand (car rest)))))))

(define (bca/read-operand-list bytes)
  (let* ((len-result (bca/read-u16 bytes))
         (len (car len-result)))
    (let loop ((i 0) (tail (cdr len-result)) (acc '()))
      (if (= i len)
          (cons (reverse acc) tail)
          (let ((operand (bca/read-operand tail)))
            (loop (+ i 1) (cdr operand) (cons (car operand) acc)))))))

(define (bca/encode-instruction instr)
  (cond
   ((and (pair? instr) (eq? (car instr) 'assign))
    (append (list bca/instr-assign)
            (bca/encode-u8 (bca/register-id (cadr instr)))
            (bca/encode-operand (caddr instr))
            (bca/encode-operand-list (cdddr instr))))
   ((and (pair? instr) (eq? (car instr) 'test))
    (append (list bca/instr-test)
            (bca/encode-operand (cadr instr))
            (bca/encode-operand-list (cddr instr))))
   ((and (pair? instr) (eq? (car instr) 'perform))
    (append (list bca/instr-perform)
            (bca/encode-operand (cadr instr))
            (bca/encode-operand-list (cddr instr))))
   ((and (pair? instr) (eq? (car instr) 'save))
    (append (list bca/instr-save)
            (bca/encode-u8 (bca/register-id (cadr instr)))))
   ((and (pair? instr) (eq? (car instr) 'restore))
    (append (list bca/instr-restore)
            (bca/encode-u8 (bca/register-id (cadr instr)))))
   ((and (pair? instr) (eq? (car instr) 'goto))
    (append (list bca/instr-goto)
            (bca/encode-operand (cadr instr))))
   ((and (pair? instr) (eq? (car instr) 'branch))
    (append (list bca/instr-branch)
            (bca/encode-operand (cadr instr))))
   ((and (pair? instr) (eq? (car instr) 'halt))
    (list bca/instr-halt))
   (else (error "bca/encode-instruction: unsupported instruction" instr))))

(define (bca/read-instruction bytes)
  (let* ((tag-result (bca/read-u8 bytes))
         (tag (car tag-result))
         (rest (cdr tag-result)))
    (cond
     ((= tag bca/instr-assign)
      (let* ((target (bca/read-u8 rest))
             (source (bca/read-operand (cdr target)))
             (operands (bca/read-operand-list (cdr source))))
        (cons (append (list 'assign
                            (bca/id->register (car target))
                            (car source))
                      (car operands))
              (cdr operands))))
     ((= tag bca/instr-test)
      (let* ((source (bca/read-operand rest))
             (operands (bca/read-operand-list (cdr source))))
        (cons (append (list 'test (car source)) (car operands))
              (cdr operands))))
     ((= tag bca/instr-perform)
      (let* ((source (bca/read-operand rest))
             (operands (bca/read-operand-list (cdr source))))
        (cons (append (list 'perform (car source)) (car operands))
              (cdr operands))))
     ((= tag bca/instr-save)
      (let ((target (bca/read-u8 rest)))
        (cons (list 'save (bca/id->register (car target))) (cdr target))))
     ((= tag bca/instr-restore)
      (let ((target (bca/read-u8 rest)))
        (cons (list 'restore (bca/id->register (car target))) (cdr target))))
     ((= tag bca/instr-goto)
      (let ((dest (bca/read-operand rest)))
        (cons (list 'goto (car dest)) (cdr dest))))
     ((= tag bca/instr-branch)
      (let ((dest (bca/read-operand rest)))
        (cons (list 'branch (car dest)) (cdr dest))))
     ((= tag bca/instr-halt)
      (cons '(halt) rest))
     (else (error "bca/read-instruction: unknown instruction tag" tag)))))

(define (bca/encode-instruction-list instrs)
  (let loop ((rest instrs)
             (chunks (list (bca/encode-u32 (length instrs)))))
    (if (null? rest)
        (bca/append-byte-chunks (reverse chunks))
        (loop (cdr rest)
              (cons (bca/encode-instruction (car rest)) chunks)))))

(define (bca/read-instruction-list bytes)
  (let* ((len-result (bca/read-u32 bytes))
         (len (car len-result)))
    (let loop ((i 0) (tail (cdr len-result)) (acc '()))
      (if (= i len)
          (cons (reverse acc) tail)
          (let ((instr (bca/read-instruction tail)))
            (loop (+ i 1) (cdr instr) (cons (car instr) acc)))))))

(define (bca/encode-code-object-entry entry)
  (let ((fields (cdr entry)))
    (append
     (bca/encode-archive-field fields ':name)
     (bca/encode-archive-field fields ':arity)
     (bca/encode-archive-field fields ':source-loc)
     (bca/encode-datum (archive/plist-get fields ':labels))
     (bca/encode-instruction-list
      (archive/plist-get fields ':instructions)))))

(define (bca/read-code-object-entry bytes)
  (let* ((name (bca/read-optional-datum bytes))
         (arity (bca/read-optional-datum (cdr name)))
         (source-loc (bca/read-optional-datum (cdr arity)))
         (labels (bca/read-datum (cdr source-loc)))
         (instrs (bca/read-instruction-list (cdr labels))))
    (cons (append
           (bca/append-archive-field
            (bca/append-archive-field
             (bca/append-archive-field
              (list ':code-object)
              ':name
              (car name))
             ':arity
             (car arity))
            ':source-loc
            (car source-loc))
           (list ':labels (car labels)
                 ':instructions (car instrs)))
          (cdr instrs))))

(define (bca/encode-code-object-entries entries)
  (let loop ((rest entries)
             (acc (bca/encode-u32 (length entries))))
    (if (null? rest)
        acc
        (loop (cdr rest)
              (append acc (bca/encode-code-object-entry (car rest)))))))

(define (bca/read-code-object-entries bytes)
  (let* ((len-result (bca/read-u32 bytes))
         (len (car len-result)))
    (let loop ((i 0) (tail (cdr len-result)) (acc '()))
      (if (= i len)
          (cons (reverse acc) tail)
          (let ((entry (bca/read-code-object-entry tail)))
            (loop (+ i 1) (cdr entry) (cons (car entry) acc)))))))

(define (bca/encode-archive-section archive)
  (let ((fields (cdr archive)))
    (append
     (list bca/section-archive)
     (bca/encode-u16 (archive/plist-get fields ':version))
     (bca/encode-archive-field fields ':kind)
     (bca/encode-archive-field fields ':file)
     (bca/encode-archive-field fields ':unit-id)
     (bca/encode-archive-field fields ':phase)
     (bca/encode-archive-field fields ':imports)
     (bca/encode-archive-field fields ':exports)
     (bca/encode-archive-field fields ':init)
     (bca/encode-code-object-entries
      (archive/plist-get fields ':entries)))))

(define (bca/read-archive-section bytes)
  (let* ((section-tag (bca/read-u8 bytes))
         (version (bca/read-u16 (cdr section-tag)))
         (kind (bca/read-optional-datum (cdr version)))
         (file (bca/read-optional-datum (cdr kind)))
         (unit-id (bca/read-optional-datum (cdr file)))
         (phase (bca/read-optional-datum (cdr unit-id)))
         (imports (bca/read-optional-datum (cdr phase)))
         (exports (bca/read-optional-datum (cdr imports)))
         (init (bca/read-optional-datum (cdr exports)))
         (entries (bca/read-code-object-entries (cdr init))))
    (when (not (= (car section-tag) bca/section-archive))
      (error "bca/read-archive-section: unknown section tag"
             (car section-tag)))
    (cons (append
           (list ':ecec-archive ':version (car version))
           (bca/append-archive-field '() ':kind (car kind))
           (bca/append-archive-field '() ':file (car file))
           (bca/append-archive-field '() ':unit-id (car unit-id))
           (bca/append-archive-field '() ':phase (car phase))
           (bca/append-archive-field '() ':imports (car imports))
           (bca/append-archive-field '() ':exports (car exports))
           (bca/append-archive-field '() ':init (car init))
           (list ':entries (car entries)))
          (cdr entries))))

(define (bca/encode-archive-bundle archives)
  (let ((archive-version
         (if (null? archives)
             bca/default-archive-version
             (archive/plist-get (cdr (car archives)) ':version))))
    (let loop ((rest archives)
               (acc (bca/encode-header (length archives) archive-version)))
      (if (null? rest)
          acc
          (loop (cdr rest)
                (append acc (bca/encode-archive-section (car rest))))))))

(define (bca/encode-archive archive)
  (bca/encode-archive-bundle (list archive)))

(define (bca/read-archive bytes)
  (let* ((header (bca/read-header bytes))
         (section-count (archive/plist-get (cdr (car header)) ':section-count)))
    (let loop ((i 0) (tail (cdr header)) (acc '()))
      (if (= i section-count)
          (cons (list ':binary-archive
                      ':header (car header)
                      ':sections (reverse acc))
                tail)
          (let ((section (bca/read-archive-section tail)))
            (loop (+ i 1) (cdr section) (cons (car section) acc)))))))

(define (bca/write-bytes-to-port bytes port)
  (for-each (lambda (b) (write-byte b port)) bytes))

(define (bca/write-bytes-to-file bytes path)
  (let ((out (open-binary-output-file path)))
    (bca/write-bytes-to-port bytes out)
    (close-output-port out)
    path))

(define (bca/read-bytes-from-file path)
  (let ((in (open-binary-input-file path)))
    (let loop ((acc '()))
      (let ((b (read-byte in)))
        (if (eof? b)
            (begin
              (close-input-port in)
              (reverse acc))
            (loop (cons b acc)))))))

(define (bca/byte-prefix? bytes prefix)
  (cond
   ((null? prefix) #t)
   ((null? bytes) #f)
   ((= (car bytes) (car prefix))
    (bca/byte-prefix? (cdr bytes) (cdr prefix)))
   (else #f)))

(define (bca/binary-archive-bytes? bytes)
  (bca/byte-prefix? bytes bca/magic-bytes))

(define (bca/read-byte-prefix-from-file path count)
  (let ((in (open-binary-input-file path)))
    (let loop ((remaining count) (acc '()))
      (if (= remaining 0)
          (begin
            (close-input-port in)
            (reverse acc))
          (let ((b (read-byte in)))
            (if (eof? b)
                (begin
                  (close-input-port in)
                  (reverse acc))
                (loop (- remaining 1) (cons b acc))))))))

(define (bca/read-file-archives-if-binary path)
  "Return decoded archive sections when PATH is a binary .ecec file.
Return #f when PATH does not start with the binary archive magic bytes."
  (let ((prefix
         (bca/read-byte-prefix-from-file path (length bca/magic-bytes))))
    (if (bca/binary-archive-bytes? prefix)
        (let* ((bytes (bca/read-bytes-from-file path))
               (decoded (bca/read-archive bytes))
               (payload (car decoded)))
          (when (not (null? (cdr decoded)))
            (error "bca/read-file-archives-if-binary: trailing bytes after archive"
                   path))
          (archive/plist-get (cdr payload) ':sections))
        #f)))
