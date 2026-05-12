;;; Documentation metadata tests - registry APIs and define/doc.

(define (doc-test-entry-names entries)
  (map (lambda (entry) (hash-ref entry :name)) entries))

(test "documentation registry stores structured entries" (lambda ()
  (set-documentation! 'doc-registry-sample
                      'procedure
                      "Sample summary."
                      :signature '(doc-registry-sample x))
  (define entry (documentation-entry 'doc-registry-sample :kind 'procedure))
  (assert-true (hash-table? entry))
  (assert-equal (hash-ref entry :name) 'doc-registry-sample)
  (assert-equal (hash-ref entry :kind) 'procedure)
  (assert-equal (hash-ref entry :summary) "Sample summary.")
  (assert-equal (hash-ref entry :signature) '(doc-registry-sample x))
  (assert-equal (hash-ref entry :module) #f)
  (assert-equal (hash-ref entry :generated?) #f)))

(test "documentation lookup returns summary and signature" (lambda ()
  (set-documentation! 'doc-lookup-sample
                      'procedure
                      "Lookup summary."
                      :signature '(doc-lookup-sample item))
  (assert-equal (documentation 'doc-lookup-sample :kind 'procedure)
                "Lookup summary.")
  (assert-equal (documentation-signature 'doc-lookup-sample :kind 'procedure)
                '(doc-lookup-sample item))))

(test "documentation registry normalizes structured docs" (lambda ()
  (set-documentation! 'doc-structured-sample
                      'value
                      (hash-table :summary "Structured summary."
                                  :signature 'doc-structured-sample
                                  :generated? #t
                                  :examples '((doc-structured-sample))))
  (define entry (documentation-entry 'doc-structured-sample :kind 'value))
  (assert-true (hash-table? entry))
  (assert-equal (hash-ref entry :name) 'doc-structured-sample)
  (assert-equal (hash-ref entry :kind) 'value)
  (assert-equal (hash-ref entry :summary) "Structured summary.")
  (assert-equal (hash-ref entry :signature) 'doc-structured-sample)
  (assert-equal (hash-ref entry :module) #f)
  (assert-equal (hash-ref entry :generated?) #t)
  (assert-equal (hash-ref entry :examples) '((doc-structured-sample)))))

(test "documentation lookup honors module keys" (lambda ()
  (set-documentation! 'doc-module-option-sample
                      'procedure
                      "Option module summary."
                      :module 'doc-module-a)
  (set-documentation! 'doc-module-structured-sample
                      'value
                      (hash-table :summary "Structured module summary."
                                  :module 'doc-module-b))
  (assert-equal (documentation 'doc-module-option-sample :kind 'procedure) #f)
  (assert-equal (documentation 'doc-module-option-sample
                               :kind 'procedure
                               :module 'doc-module-a)
                "Option module summary.")
  (assert-equal (documentation 'doc-module-structured-sample :kind 'value) #f)
  (assert-equal (documentation 'doc-module-structured-sample
                               :kind 'value
                               :module 'doc-module-b)
                "Structured module summary.")
  (assert-equal (hash-ref (documentation-entry 'doc-module-structured-sample
                                               :kind 'value
                                               :module 'doc-module-b)
                          :module)
                'doc-module-b)))

(test "documentation lookup returns #f for missing entries" (lambda ()
  (assert-equal (documentation 'doc-missing-sample :kind 'procedure) #f)
  (assert-equal (documentation-signature 'doc-missing-sample :kind 'procedure) #f)
  (assert-equal (documentation-entry 'doc-missing-sample :kind 'procedure) #f)))

(test "documentation lookup can disambiguate by kind" (lambda ()
  (set-documentation! 'doc-kind-sample 'value "Value summary.")
  (set-documentation! 'doc-kind-sample 'procedure "Procedure summary.")
  (assert-equal (documentation 'doc-kind-sample) "Procedure summary.")
  (assert-equal (documentation 'doc-kind-sample :kind 'value) "Value summary.")
  (assert-equal (documentation 'doc-kind-sample :kind 'procedure)
                "Procedure summary.")))

(test "apropos searches names and summaries in deterministic order" (lambda ()
  (set-documentation! 'doc-tool-z
                      'procedure
                      "Special tooling helper."
                      :module 'doc-tooling-module
                      :signature '(doc-tool-z x))
  (set-documentation! 'doc-tool-a
                      'value
                      "Special tooling value."
                      :module 'doc-tooling-module
                      :signature 'doc-tool-a)
  (set-documentation! 'doc-tool-generated
                      'procedure
                      "Special generated helper."
                      :module 'doc-tooling-module
                      :generated? #t)
  (define special-matches #f)
  (define filtered-matches #f)
  (with-output-to-string
    (set! special-matches
          (apropos "special" :module 'doc-tooling-module)))
  (with-output-to-string
    (set! filtered-matches
          (apropos "generated"
                   :module 'doc-tooling-module
                   :include-generated? #f)))
  (assert-equal (doc-test-entry-names special-matches)
                '(doc-tool-a doc-tool-generated doc-tool-z))
  (assert-equal (doc-test-entry-names filtered-matches)
                '())))

(test "help prints and returns one documentation entry" (lambda ()
  (set-documentation! 'doc-help-sample
                      'procedure
                      "Help summary."
                      :signature '(doc-help-sample x))
  (define entry #f)
  (define output
    (with-output-to-string
      (set! entry (help 'doc-help-sample :kind 'procedure))))
  (assert-equal (hash-ref entry :name) 'doc-help-sample)
  (assert-true (string-contains? output "doc-help-sample procedure"))
  (assert-true (string-contains? output "Signature: (doc-help-sample x)"))
  (assert-true (string-contains? output "Help summary."))))

(test "help reports missing documentation" (lambda ()
  (define result 'not-run)
  (define output
    (with-output-to-string
      (set! result (help 'doc-help-missing :kind 'procedure))))
  (assert-equal result #f)
  (assert-true (string-contains?
                output
                "No documentation found for doc-help-missing."))))

(test "documentation-reference-markdown is deterministic" (lambda ()
  (set-documentation! 'doc-markdown-z
                      'procedure
                      "Zulu markdown."
                      :module 'doc-markdown-module
                      :signature '(doc-markdown-z x))
  (set-documentation! 'doc-markdown-a
                      'value
                      "Alpha markdown."
                      :module 'doc-markdown-module
                      :signature 'doc-markdown-a)
  (assert-equal
   (documentation-reference-markdown
    :module 'doc-markdown-module
    :title "Doc Test")
   "# Doc Test\n\n## doc-markdown-a\n\n- Kind: `value`\n- Module: `doc-markdown-module`\n- Signature: `doc-markdown-a`\n\nAlpha markdown.\n\n## doc-markdown-z\n\n- Kind: `procedure`\n- Module: `doc-markdown-module`\n- Signature: `(doc-markdown-z x)`\n\nZulu markdown.\n\n")))

(test "write-documentation-reference writes markdown" (lambda ()
  (set-documentation! 'doc-write-sample
                      'value
                      "Written markdown."
                      :module 'doc-write-module)
  (define path ".tmp/doc-reference-test.md")
  (assert-equal (write-documentation-reference
                 :filename path
                 :module 'doc-write-module
                 :title "Write Test")
                path)
  (assert-equal (call-with-input-file path
                  (lambda (port) (read-line port)))
                "# Write Test")))

(test "define/doc documents procedure definitions" (lambda ()
  (define/doc (doc-square x)
    "Return X squared."
    (* x x))
  (assert-equal (doc-square 5) 25)
  (assert-equal (documentation 'doc-square :kind 'procedure) "Return X squared.")
  (assert-equal (documentation-signature 'doc-square :kind 'procedure)
                '(doc-square x))))

(test "define/doc documents value definitions" (lambda ()
  (define/doc doc-answer
    "A documented value."
    42)
  (assert-equal doc-answer 42)
  (assert-equal (documentation 'doc-answer :kind 'value) "A documented value.")
  (assert-equal (documentation-signature 'doc-answer :kind 'value)
                'doc-answer)))

(test "define-macro/doc documents macros" (lambda ()
  (define-macro/doc (doc-unless test expr)
    "Evaluate EXPR when TEST is false."
    `(if (not ,test) ,expr))
  (define doc-unless-result 0)
  (doc-unless #f
    (set! doc-unless-result 17))
  (assert-equal doc-unless-result 17)
  (assert-equal (documentation 'doc-unless :kind 'macro)
                "Evaluate EXPR when TEST is false.")
  (assert-equal (documentation-signature 'doc-unless :kind 'macro)
                '(doc-unless test expr))))

(test "define-syntax/doc documents syntax forms" (lambda ()
  (define-syntax/doc doc-when
    "Evaluate BODY when TEST is true."
    (syntax-rules ()
      ((_ test body ...)
       (if test (begin body ...)))))
  (define doc-when-result 0)
  (doc-when #t
    (set! doc-when-result 23))
  (assert-equal doc-when-result 23)
  (assert-equal (documentation 'doc-when :kind 'syntax)
                "Evaluate BODY when TEST is true.")
  (assert-equal (documentation-signature 'doc-when :kind 'syntax)
                'doc-when)))

(test "define-record/doc documents records and generated bindings" (lambda ()
  (define-record/doc doc-point
    "A documented point."
    x y)
  (define record-entry (documentation-entry 'doc-point :kind 'record))
  (define constructor-entry (documentation-entry 'make-doc-point :kind 'procedure))
  (define predicate-entry (documentation-entry 'doc-point? :kind 'procedure))
  (define accessor-entry (documentation-entry 'doc-point-x :kind 'procedure))
  (define mutator-entry (documentation-entry 'set-doc-point-x! :kind 'procedure))
  (define wither-entry (documentation-entry 'doc-point-with-x :kind 'procedure))
  (define copy-entry (documentation-entry 'copy-doc-point :kind 'procedure))
  (assert-equal (documentation 'doc-point :kind 'record)
                "A documented point.")
  (assert-equal (documentation-signature 'doc-point :kind 'record)
                '(doc-point x y))
  (assert-equal (hash-ref record-entry :generated?) #f)
  (assert-equal (hash-ref record-entry :see-also)
                '(make-doc-point doc-point?
                  doc-point-x doc-point-y
                  set-doc-point-x! set-doc-point-y!
                  doc-point-with-x doc-point-with-y
                  copy-doc-point))
  (assert-equal (documentation 'make-doc-point :kind 'procedure)
                "Construct a doc-point record.")
  (assert-equal (documentation-signature 'make-doc-point :kind 'procedure)
                '(make-doc-point x y))
  (assert-equal (documentation-signature 'doc-point? :kind 'procedure)
                '(doc-point? obj))
  (assert-equal (documentation-signature 'doc-point-x :kind 'procedure)
                '(doc-point-x obj))
  (assert-equal (documentation-signature 'set-doc-point-x! :kind 'procedure)
                '(set-doc-point-x! obj val))
  (assert-equal (documentation-signature 'doc-point-with-x :kind 'procedure)
                '(doc-point-with-x obj val))
  (assert-equal (documentation-signature 'copy-doc-point :kind 'procedure)
                '(copy-doc-point obj))
  (assert-equal (hash-ref constructor-entry :generated?) #t)
  (assert-equal (hash-ref predicate-entry :generated?) #t)
  (assert-equal (hash-ref accessor-entry :generated?) #t)
  (assert-equal (hash-ref mutator-entry :generated?) #t)
  (assert-equal (hash-ref wither-entry :generated?) #t)
  (assert-equal (hash-ref copy-entry :generated?) #t)))

(test "define-record/doc preserves record behavior" (lambda ()
  (define-record/doc doc-rect
    "A documented rectangle."
    width height)
  (define rect (make-doc-rect 10 20))
  (assert-true (doc-rect? rect))
  (assert-equal (doc-rect-width rect) 10)
  (assert-equal (doc-rect-height rect) 20)
  (set-doc-rect-width! rect 30)
  (assert-equal (doc-rect-width rect) 30)
  (define taller (doc-rect-with-height rect 40))
  (assert-equal (doc-rect-height rect) 20)
  (assert-equal (doc-rect-height taller) 40)
  (define copied (copy-doc-rect taller))
  (set-doc-rect-width! copied 50)
  (assert-equal (doc-rect-width taller) 30)
  (assert-equal (doc-rect-width copied) 50)))
