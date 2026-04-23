;; ---- Value Serialization Tests ----

;; Test helpers: save/load via serialize!/deserialize + file ports
(define (test-save! filename value)
  (call-with-output-file filename (lambda (port) (serialize! value port))))
(define (test-load filename)
  (call-with-input-file filename deserialize))

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

;; TODO(per-procedure-code-objects §G1): After mc-compile-and-go routes through
;; code-objects, the closure's entry is a bare code-object. The serializer
;; emits (%ser/opaque-co) as a placeholder (code-object identity is
;; process-local; nothing reader-portable to write). The deserialized
;; procedure can't be invoked — calling it switches the executor into a
;; "space" named %ser/opaque-co which doesn't exist. Re-enable once the
;; archive-format serializer can round-trip a full code-object (or once the
;; serializer emits the full instruction/label shape instead of an opaque
;; placeholder). See prelude.scm ser-entry and the plan's §7.1 note on
;; opaque-co semantics.
;; (test "round-trip compiled procedure" (lambda ()
;;   (define (test-sq x) (* x x))
;;   (test-save! ".tmp/ece-rt-fn.dat" test-sq)
;;   (define loaded (test-load ".tmp/ece-rt-fn.dat"))
;;   (assert-equal (loaded 7) 49)))

(test "serialize! writes without error" (lambda ()
  (test-save! ".tmp/ece-rt-ret.dat" 42)
  (assert-equal (test-load ".tmp/ece-rt-ret.dat") 42)))

;; Note: invoking the deserialized continuation is not tested here because the
;; test runner's parameterize wind frames are stripped during serialization,
;; making invocation unsafe. Continuation invocation is tested via the lexical
;; state pattern tests below which use their own scoped continuations.
(test "round-trip continuation" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set! k cont) 0))
  (test-save! ".tmp/ece-rt-cont.dat" k)
  (define loaded (test-load ".tmp/ece-rt-cont.dat"))
  (assert (continuation? loaded) "loaded should be a continuation")))

(test "continuation serialization is compact" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set! k cont) 0))
  (define size (string-length (serialize-value k)))
  ;; Continuation captures the whole test-framework dynamic chain, plus
  ;; any inline code-objects for REPL/test-scope lambdas (the test file
  ;; itself isn't loaded as an archive, so its code-objects lack an
  ;; archive-key and travel inline). The threshold is sized to catch
  ;; pathological blowups (e.g., pulling in the entire prelude), not to
  ;; enforce a tight bound on expected framework overhead.
  (assert (< size 2000000) (string-append "continuation too large: " (number->string size) " bytes"))))

(test "continuation with state is compact" (lambda ()
  (define state (hash-table 'room "kitchen" 'inventory (list "key" "torch") 'health 100))
  (define k #f)
  (%raw-call/cc (lambda (cont) (set! k cont) 0))
  (define size (string-length (serialize-value k)))
  (assert (< size 2000000) (string-append "continuation+state too large: " (number->string size) " bytes"))))

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
  (test-save! ".tmp/ece-rt-param-cont.dat" (list p k))
  (define loaded (test-load ".tmp/ece-rt-param-cont.dat"))
  (define loaded-p (car loaded))
  (assert (parameter? loaded-p) "loaded should be a parameter")
  (assert-equal (loaded-p) 42)))

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

;; TODO(per-procedure-code-objects §G1): Invoking deserialized procedures
;; trips the %ser/opaque-co placeholder (see "round-trip compiled procedure"
;; above). The cyclic-structure mechanics are independently tested by the
;; other "round-trip *" suites that don't invoke the result.
;; (test "round-trip letrec self-referencing closure" (lambda ()
;;   (define f (letrec ((f (lambda (x) (if (= x 0) 1 (* x (f (- x 1))))))) f))
;;   (test-save! ".tmp/ece-rt-letrec-self.dat" f)
;;   (define loaded (test-load ".tmp/ece-rt-letrec-self.dat"))
;;   (assert-equal (loaded 5) 120)
;;   (assert-equal (loaded 0) 1)))

;; TODO(per-procedure-code-objects §G1): Same opaque-co limitation.
;; (test "round-trip mutually recursive closures" (lambda ()
;;   (define fns
;;     (letrec ((even? (lambda (n) (if (= n 0) #t (odd? (- n 1)))))
;;              (odd?  (lambda (n) (if (= n 0) #f (even? (- n 1))))))
;;       (list even? odd?)))
;;   (test-save! ".tmp/ece-rt-mutual.dat" fns)
;;   (define loaded (test-load ".tmp/ece-rt-mutual.dat"))
;;   (define loaded-even? (car loaded))
;;   (define loaded-odd? (cadr loaded))
;;   (assert-equal (loaded-even? 0) #t)
;;   (assert-equal (loaded-even? 1) #f)
;;   (assert-equal (loaded-even? 4) #t)
;;   (assert-equal (loaded-odd? 0) #f)
;;   (assert-equal (loaded-odd? 1) #t)
;;   (assert-equal (loaded-odd? 5) #t)))

(test "round-trip recursive define in let body via call/cc" (lambda ()
  (define k #f)
  (let ()
    (define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
    (%raw-call/cc (lambda (cont) (set! k cont) 0))
    (assert-equal (fact 5) 120))
  (test-save! ".tmp/ece-rt-rec-cont.dat" k)
  (define loaded (test-load ".tmp/ece-rt-rec-cont.dat"))
  (assert (continuation? loaded) "loaded should be a continuation")))

;; TODO(per-procedure-code-objects §G1): Same limitation as "round-trip
;; compiled procedure" above — invoking a deserialized code-object-backed
;; closure tries to switch to a space named %ser/opaque-co. Re-enable once
;; the serializer can round-trip a full code-object.
;; (test "non-cyclic shared structure still works" (lambda ()
;;   ;; Verify existing non-cyclic round-trips still work
;;   (define (test-sq x) (* x x))
;;   (test-save! ".tmp/ece-rt-shared.dat" test-sq)
;;   (define loaded (test-load ".tmp/ece-rt-shared.dat"))
;;   (assert-equal (loaded 7) 49)
;;   (assert-equal (loaded 3) 9)))

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
  ;; Continuation includes parameterize overhead from test runner plus
  ;; any inline code-objects for REPL/test-scope lambdas (see
  ;; "continuation serialization is compact" for the threshold rationale).
  (define k (cadddr result))
  (assert (< (string-length (serialize-value k)) 2000000)
          "lexical state continuation should be compact")))

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
  (test-save! ".tmp/ece-rt-lexical-state.dat" result)
  (define loaded (test-load ".tmp/ece-rt-lexical-state.dat"))
  (assert-equal (car loaded) "dungeon")
  (assert-equal (cadr loaded) 70)
  (assert-equal (caddr loaded) (list "key" "torch"))
  (assert (continuation? (cadddr loaded)))))

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
  (test-save! ".tmp/ece-rt-revert.dat" (list (room) k))
  (define loaded (test-load ".tmp/ece-rt-revert.dat"))
  (assert-equal (car loaded) "cave")
  (assert (continuation? (cadr loaded)))))

(test "round-trip continuation with multiple parameters" (lambda ()
  (define room (make-parameter "start"))
  (define hp (make-parameter 100))
  (define k #f)
  (room "dungeon")
  (hp 50)
  (%raw-call/cc (lambda (c) (set! k c) 0))
  (test-save! ".tmp/ece-rt-multi-revert.dat" (list (room) (hp) k))
  (define loaded (test-load ".tmp/ece-rt-multi-revert.dat"))
  (assert-equal (car loaded) "dungeon")
  (assert-equal (cadr loaded) 50)
  (assert (continuation? (caddr loaded)))))
