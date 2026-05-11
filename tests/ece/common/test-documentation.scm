;;; Documentation metadata tests - registry APIs and define/doc.

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
