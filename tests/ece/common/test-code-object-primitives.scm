;;; Code-object primitive parity tests (ids 241-249).
;;;
;;; Exercises the predicate and each accessor's availability on both CL and
;;; WASM runtimes. Construction tests for code objects arrive in a later
;;; stage of this change (once the compiler emits them); for now, the
;;; platform-agnostic contract is: `code-object?` is false on every value
;;; ECE currently produces, and every accessor primitive is registered.

(test "code-object? on standard values" (lambda ()
  (assert-equal #f (code-object? 42))
  (assert-equal #f (code-object? "string"))
  (assert-equal #f (code-object? 'symbol))
  (assert-equal #f (code-object? '()))
  (assert-equal #f (code-object? '(a b c)))
  (assert-equal #f (code-object? #t))
  (assert-equal #f (code-object? #f))
  (assert-equal #f (code-object? (lambda (x) x)))))

(test "code-object primitives registered on platform" (lambda ()
  (assert-equal #t (platform-has? 'code-object?))
  (assert-equal #t (platform-has? 'code-object-instructions))
  (assert-equal #t (platform-has? 'code-object-resolved-instructions))
  (assert-equal #t (platform-has? 'code-object-length))
  (assert-equal #t (platform-has? 'code-object-label-entries))
  (assert-equal #t (platform-has? 'code-object-label-ref))
  (assert-equal #t (platform-has? 'code-object-name))
  (assert-equal #t (platform-has? 'code-object-native-fn))
  (assert-equal #t (platform-has? 'code-object-source-loc))
  (assert-equal #t (platform-has? '%make-code-object))
  (assert-equal #t (platform-has? '%code-object-push-instruction!))
  (assert-equal #t (platform-has? '%code-object-set-label!))
  (assert-equal #t (platform-has? '%code-object-set-name!))
  (assert-equal #t (platform-has? '%code-object-set-arity!))
  (assert-equal #t (platform-has? '%code-object-set-source-loc!))))

(test "%make-code-object produces a fresh empty code object" (lambda ()
  (let ((co (%make-code-object)))
    (assert-equal #t (code-object? co))
    (assert-equal 0 (code-object-length co))
    (assert-equal #f (code-object-name co))
    (assert-equal #f (code-object-native-fn co))
    (assert-equal #f (code-object-source-loc co)))))

(test "%code-object-set-name! / arity / source-loc round-trip" (lambda ()
  (let ((co (%make-code-object)))
    (%code-object-set-name! co 'my-proc)
    (%code-object-set-arity! co 3)
    (%code-object-set-source-loc! co '("foo.scm" 1 1))
    (assert-equal 'my-proc (code-object-name co))
    (assert-equal '("foo.scm" 1 1) (code-object-source-loc co)))))

(test "%code-object-set-label! populates label table" (lambda ()
  (let ((co (%make-code-object)))
    (%code-object-set-label! co 'L1 0)
    (%code-object-set-label! co 'L2 5)
    (assert-equal 0 (code-object-label-ref co 'L1))
    (assert-equal 5 (code-object-label-ref co 'L2)))))

(test "fresh code objects are distinct (eq? false)" (lambda ()
  (let ((a (%make-code-object))
        (b (%make-code-object)))
    (assert-equal #f (eq? a b))
    (assert-equal #t (eq? a a)))))
