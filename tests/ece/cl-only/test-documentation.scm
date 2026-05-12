;;; CL-only documentation metadata tests.

(define (documentation-module-test-cleanup! unit-ids)
  (for-each
   (lambda (unit-id)
     (let ((key (archive/unit-key unit-id)))
       (hash-remove! *archive-units* key)
       (hash-remove! *module-instances* key)))
   unit-ids))

(define (with-documentation-module-test-units* unit-ids thunk)
  (dynamic-wind
    (lambda () (documentation-module-test-cleanup! unit-ids))
    thunk
    (lambda () (documentation-module-test-cleanup! unit-ids))))

(define (write-documentation-module-test-file filename text)
  (let ((port #f))
    (dynamic-wind
     (lambda () (set! port (open-output-file filename)))
     (lambda () (display text port))
     (lambda () (when port (close-output-port port))))))

(test "define-macro/doc rejects non-list specs" (lambda ()
  (assert-error-message
   (mc-expand-macro-at-compile-time
    (get-macro 'define-macro/doc)
    '(doc-bad-macro "Bad." 1))
   "define-macro/doc: expected (name args...)")))

(test "module documentation is scoped by module export" (lambda ()
  (let ((left-id '(module (phase-d docs-left) 0))
        (right-id '(module (phase-d docs-right) 0))
        (left-path ".tmp/phase-d-docs-left.scm")
        (right-path ".tmp/phase-d-docs-right.scm")
        (bundle-path ".tmp/phase-d-docs.ecec"))
    (with-documentation-module-test-units*
     (list left-id right-id)
     (lambda ()
       (write-documentation-module-test-file
        left-path
        "(define-module (phase-d docs-left)\n  (export shared-doc-value)\n  (define/doc shared-doc-value \"Left exported value.\" 11)\n  shared-doc-value)\n")
       (write-documentation-module-test-file
        right-path
        "(define-module (phase-d docs-right)\n  (export shared-doc-value)\n  (define/doc (shared-doc-value x) \"Right exported procedure.\" (+ x 1))\n  shared-doc-value)\n")
       (compile-system (list left-path right-path) bundle-path)
       (load-bundle bundle-path)
       (let* ((left-instance (archive/module-instance '(phase-d docs-left)))
              (right-instance (archive/module-instance '(phase-d docs-right)))
              (left-docs (archive/module-instance-documentation left-instance))
              (right-docs (archive/module-instance-documentation right-instance))
              (left-entry (module-documentation-entry
                           '(phase-d docs-left)
                           'shared-doc-value))
              (right-entry (module-documentation-entry
                            '(phase-d docs-right)
                            'shared-doc-value)))
         (assert-equal (archive/module-export
                        '(phase-d docs-left)
                        'shared-doc-value)
                       11)
         (assert-equal ((archive/module-export
                         '(phase-d docs-right)
                         'shared-doc-value)
                        41)
                       42)
         (assert-equal (documentation 'shared-doc-value :kind 'value) #f)
         (assert-equal (documentation 'shared-doc-value
                                      :kind 'value
                                      :module left-id)
                       "Left exported value.")
         (assert-equal (documentation 'shared-doc-value
                                      :kind 'procedure
                                      :module right-id)
                       "Right exported procedure.")
         (assert-equal (module-documentation
                        '(phase-d docs-left)
                        'shared-doc-value)
                       "Left exported value.")
         (assert-equal (module-documentation
                        '(phase-d docs-right)
                        'shared-doc-value)
                       "Right exported procedure.")
         (assert-equal (module-documentation-entry
                        '(phase-d docs-right)
                        'shared-doc-value
                        :kind 'value)
                       #f)
         (assert-equal (hash-ref left-entry :module) left-id)
         (assert-equal (hash-ref right-entry :module) right-id)
         (assert-equal (hash-ref (hash-ref left-docs 'shared-doc-value)
                                 :summary)
                       "Left exported value.")
         (assert-equal (hash-ref (hash-ref right-docs 'shared-doc-value)
                                 :summary)
                       "Right exported procedure.")
         (assert-equal (current-documentation-module) #f)))))))
