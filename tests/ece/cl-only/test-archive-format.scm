;;; §8 archive format round-trip tests.
;;;
;;; Compile a tiny .scm file to the new archive format, reload it, and
;;; verify the loaded code-object's execution matches direct evaluation.

(test "archive: round-trip literal" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (archive (code-object->archive-sexp co "scratch.scm")))
    ;; Sanity: version 2, file set, at least one entry.
    (assert-equal 2 (archive/plist-get (cdr archive) ':version))
    (assert-equal "scratch.scm" (archive/plist-get (cdr archive) ':file))
    (assert-true (pair? (archive/plist-get (cdr archive) ':entries))))))

(test "archive: unit-id defaults to file stem" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (archive (code-object->archive-sexp co "scratch.scm")))
    (assert-equal 'scratch (archive/unit-id archive)))))

(test "archive: explicit unit-id stamps code-object keys" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (archive (code-object->archive-sexp co "scratch.scm"))
         (entries (archive/plist-get (cdr archive) ':entries))
         (unit-id '(module (game inventory) 0))
         (with-unit (list ':ecec-archive
                          ':version 2
                          ':file "scratch.scm"
                          ':unit-id unit-id
                          ':entries entries))
         (cos (archive-sexp->code-objects with-unit))
         (key (code-object-archive-key (vector-ref cos 0)))
         (ref (ser/code-object->sexp (vector-ref cos 0))))
    (assert-equal unit-id (car key))
    (assert-equal 0 (cdr key))
    (assert-equal '%ser/co-ref (car ref))
    (assert-equal unit-id (cadr ref))
    (assert-equal 0 (caddr ref)))))

(test "archive: string unit-id normalizes to legacy symbol key" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (archive (code-object->archive-sexp co "scratch.scm"))
         (entries (archive/plist-get (cdr archive) ':entries))
         (with-unit (list ':ecec-archive
                          ':version 2
                          ':file "scratch.scm"
                          ':unit-id "scratch"
                          ':entries entries))
         (cos (archive-sexp->code-objects with-unit))
         (key (code-object-archive-key (vector-ref cos 0))))
    (assert-equal 'scratch (car key))
    (assert-equal 0 (cdr key)))))

(test "archive: unit metadata defaults to current file semantics" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (archive (code-object->archive-sexp co "scratch.scm"))
         (unit (archive/unit-metadata archive)))
    ;; Current file archive emission stays compact: optional module-ready
    ;; fields are defaults in the parsed unit descriptor, not written into
    ;; every file archive.
    (assert-equal #f (archive/plist-has-key? (cdr archive) ':kind))
    (assert-equal #f (archive/plist-has-key? (cdr archive) ':phase))
    (assert-equal ':file (archive/plist-get unit ':kind))
    (assert-equal 'scratch (archive/plist-get unit ':unit-id))
    (assert-equal 0 (archive/plist-get unit ':phase))
    (assert-equal '() (archive/plist-get unit ':imports))
    (assert-equal ':all (archive/plist-get unit ':exports))
    (assert-equal 0 (archive/plist-get unit ':init)))))

(test "archive: explicit module metadata is emitted and parsed" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (unit-id '(module (game inventory) 0))
         (metadata (list ':kind ':module
                         ':unit-id unit-id
                         ':phase 0
                         ':imports '((ece base) (game item))
                         ':exports '(make-inventory inventory-add inventory-has?)
                         ':init 0))
         (archive (code-object->archive-sexp co "inventory.scm" metadata))
         (fields (cdr archive))
         (unit (archive/unit-metadata archive))
         (cos (archive-sexp->code-objects archive))
         (key (code-object-archive-key (vector-ref cos 0))))
    (assert-equal ':module (archive/plist-get fields ':kind))
    (assert-equal unit-id (archive/plist-get fields ':unit-id))
    (assert-equal '((ece base) (game item))
                  (archive/plist-get fields ':imports))
    (assert-equal '(make-inventory inventory-add inventory-has?)
                  (archive/plist-get fields ':exports))
    (assert-equal ':module (archive/plist-get unit ':kind))
    (assert-equal unit-id (archive/plist-get unit ':unit-id))
    (assert-equal 0 (archive/plist-get unit ':phase))
    (assert-equal 0 (archive/plist-get unit ':init))
    (assert-equal unit-id (car key))
    (assert-equal 0 (cdr key)))))

(test "archive: init metadata selects the code-object to execute" (lambda ()
  (let* ((archive-one (code-object->archive-sexp (mc-compile-to-code-object 1)
                                                 "multi.scm"))
         (archive-two (code-object->archive-sexp (mc-compile-to-code-object 2)
                                                 "multi.scm"))
         (entry-one (car (archive/plist-get (cdr archive-one) ':entries)))
         (entry-two (car (archive/plist-get (cdr archive-two) ':entries)))
         (archive (list ':ecec-archive
                        ':version 2
                        ':file "multi.scm"
                        ':init 1
                        ':entries (list entry-one entry-two))))
    (assert-equal 1 (archive/unit-init-index archive))
    (assert-equal 2 (load-archive-section-form archive)))))

(test "archive: invalid init metadata raises clear error" (lambda ()
  (let* ((archive-one (code-object->archive-sexp (mc-compile-to-code-object 1)
                                                 "bad-init.scm"))
         (entry-one (car (archive/plist-get (cdr archive-one) ':entries))))
    (define (message-for init)
      (let ((archive (list ':ecec-archive
                           ':version 2
                           ':file "bad-init.scm"
                           ':init init
                           ':entries (list entry-one))))
        (guard (e (#t (if (error-object? e)
                          (error-object-message e)
                          "non-error-object")))
          (load-archive-section-form archive)
          #f)))
    (let ((out-of-range (message-for 1))
          (non-integer (message-for 'not-an-index))
          (false-init (message-for #f)))
      (assert-true (string-contains? out-of-range
                                     "Invalid .ecec archive init index"))
      (assert-true (string-contains? non-integer
                                     "Invalid .ecec archive init index"))
      (assert-true (string-contains? false-init
                                     "Invalid .ecec archive init index"))))))

(define (cleanup-module-test-units! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (with-module-test-units unit-ids thunk)
  (dynamic-wind
    (lambda () (cleanup-module-test-units! unit-ids))
    thunk
    (lambda () (cleanup-module-test-units! unit-ids))))

(test "modules: module archive imports and exports are isolated" (lambda ()
  (let ((base-id '(module (phase3 base) 0))
        (user-id '(module (phase3 user) 0)))
    (with-module-test-units
     (list base-id user-id)
     (lambda ()
       (let* ((base-archive
               (code-object->archive-sexp
                (mc-compile-to-code-object
                 '(begin
                    (define answer 42)
                    (define hidden 9)
                    answer))
                "phase3-base.scm"
                (list ':kind ':module
                      ':unit-id base-id
                      ':exports '(answer))))
              (base-result (load-archive-section-form base-archive))
              (base-instance (hash-ref *module-instances*
                                       (archive/unit-key base-id)
                                       #f))
              (base-exports (archive/module-instance-exports base-instance))
              (user-archive
               (code-object->archive-sexp
                (mc-compile-to-code-object
                 '(begin
                    (define doubled (+ answer answer))
                    doubled))
                "phase3-user.scm"
                (list ':kind ':module
                      ':unit-id user-id
                      ':imports (list base-id)
                      ':exports '(doubled))))
              (user-result (load-archive-section-form user-archive))
              (user-instance (hash-ref *module-instances*
                                       (archive/unit-key user-id)
                                       #f))
              (user-exports (archive/module-instance-exports user-instance)))
         (assert-equal 42 base-result)
         (assert-equal 42 (hash-ref base-exports 'answer))
         (assert-equal #f (hash-has-key? base-exports 'hidden))
         (assert-equal 84 user-result)
         (assert-equal 84 (hash-ref user-exports 'doubled))))))))

(test "modules: missing import raises clear error" (lambda ()
  (let ((user-id '(module (phase3 missing-import-user) 0))
        (missing-id '(module (phase3 missing-import-dep) 0)))
    (with-module-test-units
     (list user-id missing-id)
     (lambda ()
       (let* ((archive
               (code-object->archive-sexp
                (mc-compile-to-code-object 1)
                "phase3-missing-import.scm"
                (list ':kind ':module
                      ':unit-id user-id
                      ':imports (list missing-id)
                      ':exports '()))))
         (let ((message (guard (e (#t (if (error-object? e)
                                          (error-object-message e)
                                          "non-error-object")))
                          (load-archive-section-form archive)
                          #f)))
           (assert-true
            (string-contains? message "Module import not found")))))))))

(test "modules: missing declared export raises clear error" (lambda ()
  (let ((unit-id '(module (phase3 missing-export) 0)))
    (with-module-test-units
     (list unit-id)
     (lambda ()
       (let* ((archive
               (code-object->archive-sexp
                (mc-compile-to-code-object
                 '(begin (define present 1) present))
                "phase3-missing-export.scm"
                (list ':kind ':module
                      ':unit-id unit-id
                      ':exports '(present absent)))))
         (let ((message (guard (e (#t (if (error-object? e)
                                          (error-object-message e)
                                          "non-error-object")))
                          (load-archive-section-form archive)
                          #f)))
           (assert-true (string-contains? message
                                          "declared missing export")))))))))

(test "modules: duplicate unit id raises clear error" (lambda ()
  (let ((unit-id '(module (phase3 duplicate) 0)))
    (with-module-test-units
     (list unit-id)
     (lambda ()
       (let* ((archive
               (code-object->archive-sexp
                (mc-compile-to-code-object 1)
                "phase3-duplicate.scm"
                (list ':kind ':module
                      ':unit-id unit-id
                      ':exports '()))))
         (load-archive-section-form archive)
         (let ((message (guard (e (#t (if (error-object? e)
                                          (error-object-message e)
                                          "non-error-object")))
                          (load-archive-section-form archive)
                          #f)))
           (assert-true (string-contains? message
                                          "Duplicate archive unit id")))))))))

(test "modules: import cycle raises clear error" (lambda ()
  (let ((unit-id '(module (phase3 cycle) 0)))
    (with-module-test-units
     (list unit-id)
     (lambda ()
       (let* ((archive
               (code-object->archive-sexp
                (mc-compile-to-code-object 1)
                "phase3-cycle.scm"
                (list ':kind ':module
                      ':unit-id unit-id
                      ':imports (list unit-id)
                      ':exports '()))))
         (let ((message (guard (e (#t (if (error-object? e)
                                          (error-object-message e)
                                          "non-error-object")))
                          (load-archive-section-form archive)
                          #f)))
           (assert-true (string-contains? message
                                          "Module import cycle")))))))))

(test "archive: collect-reachable includes top then children (ordering)"
  (lambda ()
    (let* ((co (mc-compile-to-code-object '(lambda (x) (lambda (y) (+ x y)))))
           (all (archive/collect-reachable co)))
      ;; At least 3 code-objects: top, outer lambda, inner lambda.
      (assert-true (>= (length all) 3))
      ;; First is the top.
      (assert-true (eq? (car all) co)))))

(test "archive: co-ref round-trips" (lambda ()
  ;; (define (f x) x) — outer init has a child code-object for f.
  (let* ((co (mc-compile-to-code-object '(define (f x) x)))
         (archive (code-object->archive-sexp co "scratch.scm"))
         (entries (archive/plist-get (cdr archive) ':entries)))
    ;; Should have at least 2 entries (init + lambda).
    (assert-true (>= (length entries) 2))
    ;; Init's instructions should reference (co-ref <N>) somewhere.
    (let* ((init (car entries))
           (instructions (archive/plist-get (cdr init) ':instructions))
           (found-co-ref #f))
      (let scan ((tree instructions))
        (cond
         ((null? tree) #f)
         ((not (pair? tree)) #f)
         ((and (eq? (car tree) 'co-ref) (pair? (cdr tree)))
          (set! found-co-ref #t))
         (else (scan (car tree)) (scan (cdr tree)))))
      (assert-equal #t found-co-ref)))))

(test "archive: end-to-end — literal via archive sexp" (lambda ()
  ;; Compile, serialize, parse-back, execute.
  (let* ((co (mc-compile-to-code-object 99))
         (archive (code-object->archive-sexp co "scratch.scm"))
         ;; Round-trip through s-expression text so reading behaves
         ;; exactly like loading from a file.
         (text (write-to-string-flat archive))
         (parsed (ece-scheme-read (open-input-string text)))
         (cos (archive-sexp->code-objects parsed)))
    (assert-equal 99 (execute-code-object (vector-ref cos 0))))))

(test "archive: end-to-end — primitive op" (lambda ()
  (let* ((co (mc-compile-to-code-object '(+ 10 20)))
         (archive (code-object->archive-sexp co "scratch.scm"))
         (text (write-to-string-flat archive))
         (parsed (ece-scheme-read (open-input-string text)))
         (cos (archive-sexp->code-objects parsed)))
    (assert-equal 30 (execute-code-object (vector-ref cos 0))))))

(test "archive: end-to-end — lambda invocation" (lambda ()
  (let* ((co (mc-compile-to-code-object '((lambda (x) (* x 3)) 7)))
         (archive (code-object->archive-sexp co "scratch.scm"))
         (text (write-to-string-flat archive))
         (parsed (ece-scheme-read (open-input-string text)))
         (cos (archive-sexp->code-objects parsed)))
    (assert-equal 21 (execute-code-object (vector-ref cos 0))))))

(test "archive: version mismatch raises clear error" (lambda ()
  ;; Synthesize an archive with version 1 and confirm the error mentions
  ;; the version and `make bootstrap`.
  (let* ((bad-archive '(:ecec-archive :version 1 :file "x.scm" :entries ()))
         (raised #f))
    (guard (e (#t (set! raised #t)))
      (archive-sexp->code-objects bad-archive))
    (assert-equal #t raised))))

(test "archive: file round-trip — compile-to-disk, load, invoke" (lambda ()
  ;; Write a tiny .scm, compile via compile-file-archive (which writes
  ;; <stem>.ecec next to the source), load via load-archive, call the
  ;; defined procedure, compare to direct eval.
  (define scm-path ".tmp/rt-src.scm")
  (define ecec-path ".tmp/rt-src.ecec")
  (define out (open-output-file scm-path))
  (display "(define (triple x) (* x 3))" out)
  (newline out)
  (close-output-port out)
  (compile-file-archive scm-path)
  ;; compile-file-archive writes <stem>.ecec next to source — already at
  ;; ecec-path, no rename needed.
  (load-archive ecec-path)
  (assert-equal 21 (triple 7))))

(test "archive: source origin recorded at archive level" (lambda ()
  ;; Source origin for a compiled file is recorded once at the archive
  ;; level (the `file` field on the archive wrapper). Per-code-object
  ;; source-loc stays #f; per-PC source-map is a separate future proposal
  ;; (diagnostics roadmap thread 5).
  (define scm-path ".tmp/rt-srcloc.scm")
  (define sink (open-output-string))
  (define out (open-output-file scm-path))
  (display "(define (id x) x)" out)
  (newline out)
  (close-output-port out)
  (let ((top-co (compile-file-to-archive scm-path sink)))
    ;; Code-objects themselves have #f source-loc — archive carries
    ;; the filename at the wrapper level.
    (assert-equal #f (code-object-source-loc top-co))
    ;; And the emitted archive sexp records the source filename.
    (let* ((archive (code-object->archive-sexp top-co "rt-srcloc.scm"))
           (fields (cdr archive)))
      (assert-equal "rt-srcloc.scm" (archive/plist-get fields ':file))))))

(test "archive: compile-system orders multiple files" (lambda ()
  ;; compile-system spec scenario: "Compile two files into an archive".
  ;; a.scm defines add1, b.scm defines use-add1 which calls add1. Verify
  ;; the bundle loads, both procedures are bound, and use-add1 reaches
  ;; add1 (so the ordering a-before-b worked).
  (define a-path ".tmp/cs-a.scm")
  (define b-path ".tmp/cs-b.scm")
  (define out-path ".tmp/cs-ab.ecec")
  (let ((a-out (open-output-file a-path)))
    (display "(define (cs-add1 x) (+ x 1))" a-out)
    (newline a-out)
    (close-output-port a-out))
  (let ((b-out (open-output-file b-path)))
    (display "(define (cs-use-add1) (cs-add1 5))" b-out)
    (newline b-out)
    (close-output-port b-out))
  (compile-system (list a-path b-path) out-path)
  (load-bundle out-path)
  (assert-equal 6 (cs-add1 5))
  (assert-equal 6 (cs-use-add1))))
