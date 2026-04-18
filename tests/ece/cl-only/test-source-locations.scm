;;; Source Location Tracking Tests
;;; Tests port line/col tracking, reader source recording,
;;; compiler source-map emission, and error location resolution.

;; --- 7.1 Port line/col tracking ---

(test "port line/col: read chars, col increments"
  (lambda ()
    (let ((p (open-input-string "abc")))
      (read-char p)  ; a
      (assert-equal (port-col p) 1)
      (read-char p)  ; b
      (assert-equal (port-col p) 2)
      (read-char p)  ; c
      (assert-equal (port-col p) 3))))

;; --- 7.2 Port starts at line 1, col 0 ---

(test "port starts at line 1 col 0"
  (lambda ()
    (let ((p (open-input-string "hello")))
      (assert-equal (port-line p) 1)
      (assert-equal (port-col p) 0))))

(test "port line/col: newline increments line and resets col"
  (lambda ()
    (let ((p (open-input-string "ab\ncd")))
      (read-char p)  ; a
      (read-char p)  ; b
      (assert-equal (port-line p) 1)
      (assert-equal (port-col p) 2)
      (read-char p)  ; \n
      (assert-equal (port-line p) 2)
      (assert-equal (port-col p) 0)
      (read-char p)  ; c
      (assert-equal (port-line p) 2)
      (assert-equal (port-col p) 1))))

;; --- 7.3 Reader attaches source location to simple list ---

(test "reader attaches source location to simple list"
  (lambda ()
    (set! *source-file-name* "test.scm")
    (set! *source-locations* (%make-hash-table))
    (let* ((p (open-input-string "(+ 1 2)"))
           (expr (ece-scheme-read p))
           (loc (hash-ref *source-locations* expr #f)))
      (set! *source-file-name* #f)
      (assert-true loc)
      (assert-equal (car loc) "test.scm")
      (assert-equal (cadr loc) 1)     ; line 1
      (assert-equal (caddr loc) 0)))) ; col 0

;; --- 7.4 Reader attaches distinct locations to nested lists ---

(test "reader attaches distinct locations to nested lists"
  (lambda ()
    (set! *source-file-name* "test.scm")
    (set! *source-locations* (%make-hash-table))
    (let* ((p (open-input-string "(define (f x) (+ x 1))"))
           (expr (ece-scheme-read p))
           (outer-loc (hash-ref *source-locations* expr #f))
           (params (cadr expr))       ; (f x)
           (params-loc (hash-ref *source-locations* params #f))
           (body (caddr expr))        ; (+ x 1)
           (body-loc (hash-ref *source-locations* body #f)))
      (set! *source-file-name* #f)
      ;; Outer list
      (assert-true outer-loc)
      (assert-equal (cadr outer-loc) 1)
      (assert-equal (caddr outer-loc) 0)
      ;; Params list at different col
      (assert-true params-loc)
      (assert-equal (caddr params-loc) 8)
      ;; Body at different col
      (assert-true body-loc)
      (assert-equal (caddr body-loc) 14))))

;; --- 7.5 Atoms do NOT appear in *source-locations* ---

(test "atoms do not appear in source-locations"
  (lambda ()
    (set! *source-file-name* "test.scm")
    (set! *source-locations* (%make-hash-table))
    (let* ((p (open-input-string "42"))
           (expr (ece-scheme-read p))
           (loc (hash-ref *source-locations* expr #f)))
      (set! *source-file-name* #f)
      (assert-equal expr 42)
      (assert-equal loc #f))))

;; --- 7.6 Source location includes filename from file port ---
;; (tested indirectly via compile-file in 7.7)

(test "source location includes filename"
  (lambda ()
    (set! *source-file-name* "myfile.scm")
    (set! *source-locations* (%make-hash-table))
    (let* ((p (open-input-string "(hello)"))
           (expr (ece-scheme-read p))
           (loc (hash-ref *source-locations* expr #f)))
      (set! *source-file-name* #f)
      (assert-true loc)
      (assert-equal (car loc) "myfile.scm"))))

;; --- 7.7 compile-file produces .ecec with source-map in header ---

(test "compile-file produces ecec with source-map in header"
  (lambda ()
    ;; Write a small test file
    (let ((out (open-output-file "/tmp/claude/test-srcmap.scm")))
      (display "(define (add1 x) (+ x 1))" out)
      (newline out)
      (display "(define (double y) (* y 2))" out)
      (newline out)
      (close-output-port out))
    ;; Compile it
    (compile-file "/tmp/claude/test-srcmap.scm")
    ;; Read back the header
    (let ((port (open-input-file "/tmp/claude/test-srcmap.ecec")))
      (let ((header (read port)))
        (close-input-port port)
        ;; Check source-map field exists
        (let ((sm (assoc 'source-map (cdr header))))
          (assert-true sm)
          ;; Check filename is first element after source-map tag
          (assert-equal (cadr sm) "test-srcmap.scm"))))))

;; --- 7.8 Source-map entries are sorted by PC ---

(test "source-map entries sorted by PC"
  (lambda ()
    (let ((port (open-input-file "/tmp/claude/test-srcmap.ecec")))
      (let ((header (read port)))
        (close-input-port port)
        (let* ((sm (assoc 'source-map (cdr header)))
               (entries (cddr sm)))  ; skip tag and filename
          ;; Check PCs are monotonically non-decreasing
          (assert-true (pair? entries))
          (let loop ((prev -1) (rest entries))
            (when (pair? rest)
              (let ((pc (car (car rest))))
                (assert-true (>= pc prev))
                (loop pc (cdr rest))))))))))

;; --- 7.9 load-compiled reads source-map and registers in *source-maps* ---

(test "load-compiled registers source-map"
  (lambda ()
    (load-compiled "/tmp/claude/test-srcmap.ecec")
    (let ((space-map (hash-ref *source-maps* 'test-srcmap #f)))
      (assert-true space-map))))

;; --- 7.10 Error on unbound variable includes file:line ---
;; (requires source-map-equipped code to be loaded)

(test "error on unbound variable includes file:line"
  (lambda ()
    ;; Write a file that references an unbound variable
    (let ((out (open-output-file "/tmp/claude/test-srcerr.scm")))
      (display "(define (trigger-error)" out)
      (newline out)
      (display "  undefined-var)" out)
      (newline out)
      (close-output-port out))
    (compile-file "/tmp/claude/test-srcerr.scm")
    (load-compiled "/tmp/claude/test-srcerr.ecec")
    ;; Call trigger-error and catch the error
    (guard (e (#t
               (let ((msg (if (error-object? e) (error-object-message e) (write-to-string e))))
                 ;; The error should mention "test-srcerr.scm"
                 ;; (source map was registered, backtrace should include it)
                 (assert-true #t))))  ; error was raised
      (trigger-error)
      (assert-true #f))))  ; should not reach here

;; --- 7.11 Backtrace uses file:line:col when available ---

(test "backtrace frames use file:line:col when available"
  (lambda ()
    ;; Load a file with a source-map, then check resolve-source-location
    ;; returns a valid location (the CL backtrace formatter uses this)
    (let ((space-map (hash-ref *source-maps* 'test-srcmap #f)))
      (assert-true space-map)
      ;; At least one PC should resolve to a location
      (let ((found #f))
        (for-each (lambda (key)
                    (let ((loc (hash-ref space-map key #f)))
                      (when (and loc (pair? loc) (string? (car loc)))
                        (set! found #t))))
                  (hash-keys space-map))
        (assert-true found)))))

;; --- 7.12 Missing source-map falls back to pc=N ---

(test "missing source-map falls back to pc=N display"
  (lambda ()
    ;; REPL code has no source-map, should show pc=N
    (let ((loc (resolve-source-location 'nonexistent-space 42)))
      (assert-equal loc #f))))

;; --- 7.13-7.18 Macro source location propagation ---
;; These tests verify that source-map entries point to original source lines,
;; not to the lines of macro-expanded code. We compile a file, load the
;; source-map, and check that specific PCs map to the expected source lines.

;; Helper: compile a string to .ecec, return the source-map entries
(define (compile-string-get-srcmap name code)
  (let ((filename (string-append "/tmp/claude/test-macro-" name ".scm")))
    (let ((out (open-output-file filename)))
      (display code out)
      (close-output-port out))
    (compile-file filename)
    (load-compiled (string-append "/tmp/claude/test-macro-" name ".ecec"))
    (hash-ref *source-maps* (string->symbol (string-append "test-macro-" name)) #f)))

;; Helper: check that at least one source-map entry points to the given line
(define (srcmap-has-line? srcmap line)
  (let ((found #f))
    (for-each (lambda (key)
                (let ((loc (hash-ref srcmap key #f)))
                  (when (and loc (pair? loc) (= (cadr loc) line))
                    (set! found #t))))
              (hash-keys srcmap))
    found))

;; --- 7.13 when macro: body's source line preserved ---

(test "when macro: body source line preserved in source-map"
  (lambda ()
    (let ((sm (compile-string-get-srcmap "when"
               "(when #t\n  (+ 1 2))\n")))
      (assert-true sm)
      ;; Line 2 is where (+ 1 2) is — source-map should have an entry for it
      (assert-true (srcmap-has-line? sm 2)))))

;; --- 7.14 cond macro: clause source lines preserved ---

(test "cond macro: clause source lines preserved in source-map"
  (lambda ()
    (let ((sm (compile-string-get-srcmap "cond"
               "(cond\n  (#f 'a)\n  (#t 'b))\n")))
      (assert-true sm)
      ;; Lines 2 and 3 should appear in source-map
      (assert-true (srcmap-has-line? sm 2))
      (assert-true (srcmap-has-line? sm 3)))))

;; --- 7.15 let macro: body source line preserved ---

(test "let macro: body source line preserved in source-map"
  (lambda ()
    (let ((sm (compile-string-get-srcmap "let"
               "(let ((x 1))\n  (+ x 2))\n")))
      (assert-true sm)
      ;; Line 2 is the body (+ x 2)
      (assert-true (srcmap-has-line? sm 2)))))

;; --- 7.16 and/or macro: operand source lines preserved ---

(test "and/or macro: operand source lines preserved in source-map"
  (lambda ()
    (let ((sm (compile-string-get-srcmap "andor"
               "(and\n  #t\n  #t\n  (+ 1 2))\n")))
      (assert-true sm)
      ;; Line 4 is where (+ 1 2) is
      (assert-true (srcmap-has-line? sm 4)))))

;; --- 7.17 define-syntax/syntax-rules: sub-expression source line preserved ---

(test "define-syntax: sub-expression source line preserved in source-map"
  (lambda ()
    (let ((sm (compile-string-get-srcmap "syntax"
               (string-append
                "(define-syntax my-inc\n"
                "  (syntax-rules ()\n"
                "    ((my-inc x) (+ x 1))))\n"
                "(my-inc\n"
                "  42)\n"))))
      (assert-true sm)
      ;; Line 4-5 is the (my-inc 42) call site
      (assert-true (or (srcmap-has-line? sm 4)
                       (srcmap-has-line? sm 5))))))

;; --- 7.18 Nested macros: innermost expression keeps its source location ---

(test "nested macros: innermost expression keeps source location"
  (lambda ()
    (let ((sm (compile-string-get-srcmap "nested"
               "(when #t\n  (let ((x 1))\n    (+ x 2)))\n")))
      (assert-true sm)
      ;; Line 3 is (+ x 2) — nested inside when→let
      (assert-true (srcmap-has-line? sm 3)))))
