;; ---- Value Serialization Tests ----

;; Test helpers: save/load via serialize!/deserialize + file ports
(define (test-save! filename value)
  (call-with-output-file filename (lambda (port) (serialize! value port))))
(define (test-load filename)
  (call-with-input-file filename deserialize))

(define (assert-unserializable-wind-error thunk expected-index)
  (define raised #f)
  (define index #f)
  (guard (e ((ece-serialization-unserializable-wind-error? e)
             (set! raised #t)
             (set! index (ece-serialization-unserializable-wind-error-index e))))
    (thunk))
  (assert-equal raised #t)
  (if expected-index
      (assert-equal index expected-index)
      (assert (number? index) "wind error should include a frame index")))

(define *serialization-wind-log* '())

(define (serialization-wind-before)
  (set! *serialization-wind-log*
        (cons 'before *serialization-wind-log*)))

(define (serialization-wind-after)
  (set! *serialization-wind-log*
        (cons 'after *serialization-wind-log*)))

(test "serialize plain number" (lambda ()
  (assert-equal (serialize-value 42) "42")))

(test "serialize string" (lambda ()
  (assert-equal (serialize-value "hello") "\"hello\"")))

(test "serialize boolean" (lambda ()
  (assert-equal (serialize-value #t) "#t")
  (assert-equal (serialize-value #f) "#f")))

(test "serialize nil" (lambda ()
  (assert-equal (serialize-value '()) "()")))

(test "serialize symbol" (lambda ()
  (assert-equal (serialize-value 'foo) "foo")))

(test "round-trip plain values" (lambda ()
  (test-save! ".tmp/ece-rt-plain.dat" 42)
  (assert-equal (test-load ".tmp/ece-rt-plain.dat") 42)
  (test-save! ".tmp/ece-rt-plain.dat" "hello world")
  (assert-equal (test-load ".tmp/ece-rt-plain.dat") "hello world")
  (test-save! ".tmp/ece-rt-plain.dat" #t)
  (assert-equal (test-load ".tmp/ece-rt-plain.dat") #t)))

(test "round-trip list" (lambda ()
  (test-save! ".tmp/ece-rt-list.dat" (list 1 "two" #t 'four))
  (define result (test-load ".tmp/ece-rt-list.dat"))
  (assert-equal (car result) 1)
  (assert-equal (cadr result) "two")
  (assert-equal (caddr result) #t)
  (assert-equal (cadddr result) 'four)))

(test "round-trip dotted pair" (lambda ()
  (test-save! ".tmp/ece-rt-pair.dat" (cons 'a 'b))
  (define result (test-load ".tmp/ece-rt-pair.dat"))
  (assert-equal (car result) 'a)
  (assert-equal (cdr result) 'b)))

(test "round-trip vector" (lambda ()
  (test-save! ".tmp/ece-rt-vec.dat" (vector 10 20 30))
  (define v (test-load ".tmp/ece-rt-vec.dat"))
  (assert (vector? v))
  (assert-equal (vector-ref v 0) 10)
  (assert-equal (vector-ref v 1) 20)
  (assert-equal (vector-ref v 2) 30)))

(test "round-trip hash table" (lambda ()
  (define ht (hash-table 'a 1 'b 2))
  (test-save! ".tmp/ece-rt-ht.dat" ht)
  (define loaded (test-load ".tmp/ece-rt-ht.dat"))
  (assert (hash-table? loaded) "loaded should be a hash table")
  (assert-equal (hash-ref loaded 'a) 1)
  (assert-equal (hash-ref loaded 'b) 2)))

(test "round-trip compiled procedure" (lambda ()
  (define (test-sq x) (* x x))
  (test-save! ".tmp/ece-rt-fn.dat" test-sq)
  (define loaded (test-load ".tmp/ece-rt-fn.dat"))
  (assert-equal (loaded 7) 49)))

(test "serialize! writes without error" (lambda ()
  (test-save! ".tmp/ece-rt-ret.dat" 42)
  (assert-equal (test-load ".tmp/ece-rt-ret.dat") 42)))

;; Continuations captured inside the test runner include its output-capture
;; parameterize frame, which closes over a port. That continuation is not
;; losslessly serializable, so serialization must fail instead of stripping the
;; wind frame.
(test "continuation with port wind frame is rejected" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set! k cont) 0))
  (assert-unserializable-wind-error
   (lambda () (test-save! ".tmp/ece-rt-cont.dat" k))
   #f)))

(test "serialize-value rejects unsafe continuation winds" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set! k cont) 0))
  (assert-unserializable-wind-error
   (lambda () (serialize-value k))
   #f)))

(test "unsafe continuation with state is rejected" (lambda ()
  (define state (hash-table 'room "kitchen" 'inventory (list "key" "torch") 'health 100))
  (define k #f)
  (%raw-call/cc (lambda (cont) (set! k cont) 0))
  (assert-unserializable-wind-error
   (lambda () (serialize-value k))
   #f)))

(test "serializable wind frames survive continuation round-trip" (lambda ()
  (set! *serialization-wind-log* '())
  (define k (%make-continuation '() 'done
                                (list (cons serialization-wind-before
                                            serialization-wind-after))))
  (define loaded (deserialize-value (read (open-input-string (serialize-value k)))))
  (assert (continuation? loaded) "loaded should be a continuation")
  (define winds (continuation-winds loaded))
  (assert (pair? winds) "loaded continuation should retain wind frames")
  (assert (compiled-procedure? (car (car winds))) "before thunk should be restored")
  (assert (compiled-procedure? (cdr (car winds))) "after thunk should be restored")
  (assert-equal (cdr winds) '())))

(test "unserializable wind frames are rejected" (lambda ()
  (define port (open-output-string))
  ;; This malformed wind frame intentionally puts a host port directly in the
  ;; wind stack. It exercises the serializer's losslessness guard without
  ;; depending on closure environment shape.
  (define k (%make-continuation '() 'done (list (cons port port))))
  (assert-unserializable-wind-error
   (lambda () (serialize-value k))
   0)))

(test "round-trip parameter value" (lambda ()
  (define p (make-parameter 42))
  (p 99)
  (test-save! ".tmp/ece-rt-param.dat" p)
  (define loaded (test-load ".tmp/ece-rt-param.dat"))
  (assert (parameter? loaded) "loaded should be a parameter")
  (assert-equal (loaded) 99)))

(test "round-trip parameter with converter" (lambda ()
  (define p (make-parameter "hello" string-length))
  (test-save! ".tmp/ece-rt-param-conv.dat" p)
  (define loaded (test-load ".tmp/ece-rt-param-conv.dat"))
  (assert (parameter? loaded) "loaded should be a parameter")
  (assert-equal (loaded) 5)
  ;; converter should also be preserved
  (loaded "world")
  (assert-equal (loaded) 5)))

(test "parameter in lexical scope captured by continuation" (lambda ()
  (define p (make-parameter 10))
  (define k #f)
  (p 42)
  (%raw-call/cc (lambda (cont) (set! k cont) 0))
  (assert-unserializable-wind-error
   (lambda () (test-save! ".tmp/ece-rt-param-cont.dat" (list p k)))
   #f)))

(test "mutated parameter survives round-trip" (lambda ()
  (define p (make-parameter 0))
  (p 1)
  (p 2)
  (p 42)
  (test-save! ".tmp/ece-rt-param-mut.dat" p)
  (define loaded (test-load ".tmp/ece-rt-param-mut.dat"))
  (assert-equal (loaded) 42)
  ;; mutating loaded doesn't affect original
  (loaded 999)
  (assert-equal (loaded) 999)
  (assert-equal (p) 42)))

;; --- Cyclic Serialization Tests ---

(test "round-trip letrec self-referencing closure" (lambda ()
  (define f (letrec ((f (lambda (x) (if (= x 0) 1 (* x (f (- x 1))))))) f))
  (test-save! ".tmp/ece-rt-letrec-self.dat" f)
  (define loaded (test-load ".tmp/ece-rt-letrec-self.dat"))
  (assert-equal (loaded 5) 120)
  (assert-equal (loaded 0) 1)))

(test "round-trip mutually recursive closures" (lambda ()
  (define fns
    (letrec ((even? (lambda (n) (if (= n 0) #t (odd? (- n 1)))))
             (odd?  (lambda (n) (if (= n 0) #f (even? (- n 1))))))
      (list even? odd?)))
  (test-save! ".tmp/ece-rt-mutual.dat" fns)
  (define loaded (test-load ".tmp/ece-rt-mutual.dat"))
  (define loaded-even? (car loaded))
  (define loaded-odd? (cadr loaded))
  (assert-equal (loaded-even? 0) #t)
  (assert-equal (loaded-even? 1) #f)
  (assert-equal (loaded-even? 4) #t)
  (assert-equal (loaded-odd? 0) #f)
  (assert-equal (loaded-odd? 1) #t)
  (assert-equal (loaded-odd? 5) #t)))

(test "round-trip recursive define in let body via call/cc" (lambda ()
  (define k #f)
  (let ()
    (define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
    (%raw-call/cc (lambda (cont) (set! k cont) 0))
    (assert-equal (fact 5) 120))
  (assert-unserializable-wind-error
   (lambda () (test-save! ".tmp/ece-rt-rec-cont.dat" k))
   #f)))

(test "non-cyclic shared structure still works" (lambda ()
  ;; Verify existing non-cyclic round-trips still work
  (define (test-sq x) (* x x))
  (test-save! ".tmp/ece-rt-shared.dat" test-sq)
  (define loaded (test-load ".tmp/ece-rt-shared.dat"))
  (assert-equal (loaded 7) 49)
  (assert-equal (loaded 3) 9)))

;; --- Lexical State Pattern (game-like save/load) ---

(test "lexical state pattern: multiple params in function scope" (lambda ()
  ;; External pure function — not serialized
  (define (apply-damage hp amount) (- hp amount))

  (define (run-game)
    ;; All mutable state is lexical
    (define room (make-parameter "kitchen"))
    (define hp (make-parameter 100))
    (define inventory (make-parameter '()))

    ;; Mutate state
    (room "dungeon")
    (hp (apply-damage (hp) 30))
    (inventory (list "key" "torch"))

    ;; Capture continuation
    (define k #f)
    (%raw-call/cc (lambda (c) (set! k c) 0))

    ;; Return state + continuation for testing
    (list (room) (hp) (inventory) k))

  (define result (run-game))
  (assert-equal (car result) "dungeon")
  (assert-equal (cadr result) 70)
  (assert-equal (caddr result) (list "key" "torch"))
  ;; The captured continuation includes the test runner's output port wind
  ;; frame, so strict serialization rejects it instead of silently dropping it.
  (define k (cadddr result))
  (assert-unserializable-wind-error
   (lambda () (serialize-value k))
   #f)))

(test "lexical state pattern: save and load preserves all state" (lambda ()
  (define (run-game)
    (define room (make-parameter "kitchen"))
    (define hp (make-parameter 100))
    (define inventory (make-parameter '()))
    (room "dungeon")
    (hp 70)
    (inventory (list "key" "torch"))
    (define k #f)
    (%raw-call/cc (lambda (c) (set! k c) 0))
    (list (room) (hp) (inventory) k))
  (define result (run-game))
  (assert-unserializable-wind-error
   (lambda () (test-save! ".tmp/ece-rt-lexical-state.dat" result))
   #f)))

(test "lexical state pattern: external functions work with lexical params" (lambda ()
  ;; External function receives values, not parameters
  (define (format-status room hp)
    (string-append room ":" (number->string hp)))

  (define (run-game)
    (define room (make-parameter "start"))
    (define hp (make-parameter 100))
    (room "cave")
    (hp 50)
    ;; Pass parameter VALUES to external function
    (format-status (room) (hp)))

  (assert-equal (run-game) "cave:50")))

(test "lexical state pattern: parameter with converter in function scope" (lambda ()
  (define (run-game)
    ;; Parameter with converter ensures hp is always integer
    (define hp (make-parameter 100))
    (hp 70)
    (test-save! ".tmp/ece-rt-lexical-conv.dat" hp)
    (define loaded (test-load ".tmp/ece-rt-lexical-conv.dat"))
    (assert (parameter? loaded))
    (assert-equal (loaded) 70))
  (run-game)))

(test "round-trip continuation with parameter state" (lambda ()
  (define room (make-parameter "start"))
  (define k #f)
  (room "cave")
  (%raw-call/cc (lambda (c) (set! k c) 0))
  (assert-unserializable-wind-error
   (lambda () (test-save! ".tmp/ece-rt-revert.dat" (list (room) k)))
   #f)))

(test "round-trip continuation with multiple parameters" (lambda ()
  (define room (make-parameter "start"))
  (define hp (make-parameter 100))
  (define k #f)
  (room "dungeon")
  (hp 50)
  (%raw-call/cc (lambda (c) (set! k c) 0))
  (assert-unserializable-wind-error
   (lambda () (test-save! ".tmp/ece-rt-multi-revert.dat" (list (room) (hp) k)))
   #f)))

(test "%ser/co-ref fails with typed error when archive absent" (lambda ()
  ;; Fabricate a blob that references an archive stem that isn't
  ;; registered. The deserializer must surface this via the typed
  ;; ece-deser-missing-archive-error record so callers can catch the
  ;; specific class (not a generic error) and prompt the user.
  (define blob "(%ser/co-ref fake-archive-xyz 0)")
  (define raised #f)
  (define stem #f)
  (define idx #f)
  (guard (e ((ece-deser-missing-archive-error? e)
             (set! raised #t)
             (set! stem (ece-deser-missing-archive-error-stem e))
             (set! idx (ece-deser-missing-archive-error-index e))))
    (let ((port (open-input-string blob)))
      (deserialize port)))
  (assert-equal raised #t)
  (assert-equal stem 'fake-archive-xyz)
  (assert-equal idx 0)))

(test "%ser/co-ref includes archive fingerprint when available" (lambda ()
  (let* ((entry (compiled-procedure-entry reverse))
         (co (if (pair? entry) (car entry) entry))
         (ref (ser/code-object->sexp co)))
    (assert-equal (car ref) '%ser/co-ref)
    (assert-equal 4 (length ref))
    (assert (number? (cadddr ref))
            "archive co-ref should include numeric fingerprint")
    (assert-true (eq? (deserialize-value ref) co)))))

(test "%ser/co-ref without fingerprint remains loadable" (lambda ()
  (let* ((entry (compiled-procedure-entry reverse))
         (co (if (pair? entry) (car entry) entry))
         (key (code-object-archive-key co))
         (legacy-ref (list '%ser/co-ref (car key) (cdr key))))
    (assert-true (eq? (deserialize-value legacy-ref) co)))))

(test "%ser/co-ref rejects archive fingerprint mismatch" (lambda ()
  (let* ((entry (compiled-procedure-entry reverse))
         (co (if (pair? entry) (car entry) entry))
         (key (code-object-archive-key co))
         (bad-ref (list '%ser/co-ref (car key) (cdr key) -1))
         (raised #f)
         (stem #f)
         (idx #f)
         (expected #f)
         (actual #f))
    (guard (e ((ece-deser-archive-mismatch-error? e)
               (set! raised #t)
               (set! stem (ece-deser-archive-mismatch-error-stem e))
               (set! idx (ece-deser-archive-mismatch-error-index e))
               (set! expected (ece-deser-archive-mismatch-error-expected e))
               (set! actual (ece-deser-archive-mismatch-error-actual e))))
      (deserialize-value bad-ref))
    (assert-equal raised #t)
    (assert-equal stem (car key))
    (assert-equal idx (cdr key))
    (assert-equal expected -1)
    (assert (number? actual) "actual fingerprint should be reported"))))
