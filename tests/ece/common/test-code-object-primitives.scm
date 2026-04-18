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
  (assert-equal #t (platform-has? 'code-object-source-loc))))
