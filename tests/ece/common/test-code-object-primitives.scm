;;; Phase 3: code-object primitives runtime-agnostic tests. Covers the
;;; platform-has? probes, the %make-code-object constructor, and the
;;; per-field accessors/mutators. Runs on both CL and WASM runtimes.

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

;;; §6.6 end-to-end: both runtimes compile and execute a code-object.
;;; The compile step uses mc-compile-to-code-object (bottom-up shape);
;;; the execute step uses execute-code-object.

(test "mc-compile-to-code-object + execute-code-object: literal" (lambda ()
  (assert-equal 42 (execute-code-object (mc-compile-to-code-object 42)))))

(test "mc-compile-to-code-object + execute-code-object: primitive op" (lambda ()
  (assert-equal 7 (execute-code-object (mc-compile-to-code-object '(+ 3 4))))))

(test "mc-compile-to-code-object + execute-code-object: quoted symbol" (lambda ()
  (assert-equal 'hello (execute-code-object (mc-compile-to-code-object ''hello)))))

(test "mc-compile-to-code-object + execute-code-object: if/else (TRUE)" (lambda ()
  (assert-equal 'big (execute-code-object
                      (mc-compile-to-code-object '(if (> 5 3) 'big 'small))))))

(test "mc-compile-to-code-object + execute-code-object: lambda call" (lambda ()
  (assert-equal 25 (execute-code-object
                    (mc-compile-to-code-object '((lambda (x) (* x x)) 5))))))
