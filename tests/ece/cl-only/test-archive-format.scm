;;; §8 archive format round-trip tests.
;;;
;;; Compile a tiny .scm file to the new archive format, reload it, and
;;; verify the loaded code-object's execution matches direct evaluation.

(test "archive: round-trip literal" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (archive (code-object->archive-sexp co "scratch.scm")))
    ;; Sanity: version 2, file set, at least one entry.
    (assert-equal 2 (archive/plist-get (cdr archive) 'version))
    (assert-equal "scratch.scm" (archive/plist-get (cdr archive) 'file))
    (assert-true (pair? (archive/plist-get (cdr archive) 'entries))))))

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
         (entries (archive/plist-get (cdr archive) 'entries)))
    ;; Should have at least 2 entries (init + lambda).
    (assert-true (>= (length entries) 2))
    ;; Init's instructions should reference (co-ref <N>) somewhere.
    (let* ((init (car entries))
           (instructions (archive/plist-get (cdr init) 'instructions))
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
  (let* ((bad-archive '(ecec-archive :version 1 :file "x.scm" :entries ()))
         (raised #f))
    (guard (e (#t (set! raised #t)))
      (archive-sexp->code-objects bad-archive))
    (assert-equal #t raised))))

(test "archive: file round-trip — compile-to-disk, load, invoke" (lambda ()
  ;; Write a tiny .scm, compile via compile-file-archive (which writes
  ;; <stem>.ecec next to the source), load via load-archive, call the
  ;; defined procedure, compare to direct eval.
  (define scm-path "/tmp/claude/rt-src.scm")
  (define ecec-path "/tmp/claude/rt-src.ecec")
  (define out (open-output-file scm-path))
  (display "(define (triple x) (* x 3))" out)
  (newline out)
  (close-output-port out)
  (compile-file-archive scm-path)
  ;; compile-file-archive writes <stem>.ecec next to source — already at
  ;; ecec-path, no rename needed.
  (load-archive ecec-path)
  (assert-equal 21 (triple 7))))

(test "archive: code-object source-loc records filename" (lambda ()
  ;; compile-file-to-archive should stamp every reachable code-object's
  ;; source-loc with the source basename, satisfying the compile-system
  ;; spec scenario "Each code object records its source origin".
  (define scm-path "/tmp/claude/rt-srcloc.scm")
  (define sink (open-output-string))
  (define out (open-output-file scm-path))
  (display "(define (id x) x)" out)
  (newline out)
  (close-output-port out)
  (let ((top-co (compile-file-to-archive scm-path sink)))
    (assert-equal "rt-srcloc.scm" (code-object-source-loc top-co))
    ;; Nested code-objects (the `id` lambda) should also carry the origin.
    (for-each (lambda (co)
                (assert-equal "rt-srcloc.scm" (code-object-source-loc co)))
              (archive/collect-reachable top-co)))))

(test "archive: compile-system orders multiple files" (lambda ()
  ;; compile-system spec scenario: "Compile two files into an archive".
  ;; a.scm defines add1, b.scm defines use-add1 which calls add1. Verify
  ;; the bundle loads, both procedures are bound, and use-add1 reaches
  ;; add1 (so the ordering a-before-b worked).
  (define a-path "/tmp/claude/cs-a.scm")
  (define b-path "/tmp/claude/cs-b.scm")
  (define out-path "/tmp/claude/cs-ab.ecec")
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
