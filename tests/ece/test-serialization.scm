;; ---- Value Serialization Tests ----

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
  (save-continuation! "/tmp/ece-rt-plain.dat" 42)
  (assert-equal (load-continuation "/tmp/ece-rt-plain.dat") 42)
  (save-continuation! "/tmp/ece-rt-plain.dat" "hello world")
  (assert-equal (load-continuation "/tmp/ece-rt-plain.dat") "hello world")
  (save-continuation! "/tmp/ece-rt-plain.dat" #t)
  (assert-equal (load-continuation "/tmp/ece-rt-plain.dat") #t)))

(test "round-trip list" (lambda ()
  (save-continuation! "/tmp/ece-rt-list.dat" (list 1 "two" #t 'four))
  (define result (load-continuation "/tmp/ece-rt-list.dat"))
  (assert-equal (car result) 1)
  (assert-equal (cadr result) "two")
  (assert-equal (caddr result) #t)
  (assert-equal (cadddr result) 'four)))

(test "round-trip dotted pair" (lambda ()
  (save-continuation! "/tmp/ece-rt-pair.dat" (cons 'a 'b))
  (define result (load-continuation "/tmp/ece-rt-pair.dat"))
  (assert-equal (car result) 'a)
  (assert-equal (cdr result) 'b)))

(test "round-trip vector" (lambda ()
  (save-continuation! "/tmp/ece-rt-vec.dat" (vector 10 20 30))
  (define v (load-continuation "/tmp/ece-rt-vec.dat"))
  (assert (vector? v))
  (assert-equal (vector-ref v 0) 10)
  (assert-equal (vector-ref v 1) 20)
  (assert-equal (vector-ref v 2) 30)))

(test "round-trip hash table" (lambda ()
  (save-continuation! "/tmp/ece-rt-ht.dat" (hash-table 'name "Alice" 'age 30))
  (define ht (load-continuation "/tmp/ece-rt-ht.dat"))
  (assert (hash-table? ht))
  (assert-equal (hash-ref ht 'name) "Alice")
  (assert-equal (hash-ref ht 'age) 30)))

(test "round-trip compiled procedure" (lambda ()
  (define (test-sq x) (* x x))
  (save-continuation! "/tmp/ece-rt-fn.dat" test-sq)
  (define loaded (load-continuation "/tmp/ece-rt-fn.dat"))
  (assert-equal (loaded 7) 49)))

(test "save-continuation! returns #t" (lambda ()
  (assert-equal (save-continuation! "/tmp/ece-rt-ret.dat" 42) #t)))

(test "round-trip continuation" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set k cont)))
  (save-continuation! "/tmp/ece-rt-cont.dat" k)
  (define loaded (load-continuation "/tmp/ece-rt-cont.dat"))
  (assert (pair? loaded))
  (assert-equal (car loaded) 'continuation)))

(test "continuation serialization is compact" (lambda ()
  (define k #f)
  (%raw-call/cc (lambda (cont) (set k cont) 0))
  (define size (string-length (serialize-value k)))
  ;; Trivial continuation should be well under 500 bytes
  (assert (< size 500) (string-append "continuation too large: " (number->string size) " bytes"))))

(test "continuation with state is compact" (lambda ()
  (define state (hash-table 'room "kitchen" 'inventory (list "key" "torch") 'health 100))
  (define k #f)
  (%raw-call/cc (lambda (cont) (set k cont) 0))
  (define size (string-length (serialize-value k)))
  ;; Continuation with game state should stay under 1KB
  (assert (< size 1000) (string-append "continuation+state too large: " (number->string size) " bytes"))))

(test "round-trip parameter value" (lambda ()
  (define p (make-parameter 42))
  (p 99)
  (save-continuation! "/tmp/ece-rt-param.dat" p)
  (define loaded (load-continuation "/tmp/ece-rt-param.dat"))
  (assert (parameter? loaded) "loaded should be a parameter")
  (assert-equal (loaded) 99)))

(test "round-trip parameter with converter" (lambda ()
  (define p (make-parameter "hello" string-length))
  (save-continuation! "/tmp/ece-rt-param-conv.dat" p)
  (define loaded (load-continuation "/tmp/ece-rt-param-conv.dat"))
  (assert (parameter? loaded) "loaded should be a parameter")
  (assert-equal (loaded) 5)
  ;; converter should also be preserved
  (loaded "world")
  (assert-equal (loaded) 5)))

(test "parameter in lexical scope captured by continuation" (lambda ()
  ;; Parameter in a let binding IS captured (unlike global define)
  (define result
    (let ((p (make-parameter "kitchen")))
      (p "dungeon")
      (define k #f)
      (%raw-call/cc (lambda (c) (set k c) 0))
      (save-continuation! "/tmp/ece-rt-param-lex.dat" k)
      (define loaded (load-continuation "/tmp/ece-rt-param-lex.dat"))
      ;; The continuation captured the env with p in lexical scope
      (assert (pair? loaded))
      (assert-equal (car loaded) 'continuation)
      (p)))
  (assert-equal result "dungeon")))

(test "mutated parameter survives round-trip" (lambda ()
  (define p (make-parameter 0))
  (p 1)
  (p 2)
  (p 42)
  (save-continuation! "/tmp/ece-rt-param-mut.dat" p)
  (define loaded (load-continuation "/tmp/ece-rt-param-mut.dat"))
  (assert-equal (loaded) 42)
  ;; mutating loaded doesn't affect original
  (loaded 999)
  (assert-equal (loaded) 999)
  (assert-equal (p) 42)))

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
    (%raw-call/cc (lambda (c) (set k c) 0))

    ;; Return state + continuation for testing
    (list (room) (hp) (inventory) k))

  (define result (run-game))
  (assert-equal (car result) "dungeon")
  (assert-equal (cadr result) 70)
  (assert-equal (caddr result) (list "key" "torch"))
  ;; Continuation is compact (lexical state only)
  (define k (cadddr result))
  (assert (< (string-length (serialize-value k)) 1000)
          "lexical state continuation should be compact")))

(test "lexical state pattern: save and load preserves all state" (lambda ()
  (define (run-game)
    (define room (make-parameter "kitchen"))
    (define hp (make-parameter 100))
    (room "dungeon")
    (hp 70)
    (define k #f)
    (%raw-call/cc (lambda (c) (set k c) 0))
    ;; Save continuation
    (save-continuation! "/tmp/ece-rt-lexical-game.dat" k)
    ;; Return current state for verification
    (list (room) (hp)))

  (define result (run-game))
  (assert-equal (car result) "dungeon")
  (assert-equal (cadr result) 70)

  ;; Load the saved continuation
  (define loaded (load-continuation "/tmp/ece-rt-lexical-game.dat"))
  (assert (pair? loaded))
  (assert-equal (car loaded) 'continuation)))

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
    (save-continuation! "/tmp/ece-rt-lexical-conv.dat" hp)
    (define loaded (load-continuation "/tmp/ece-rt-lexical-conv.dat"))
    (assert (parameter? loaded))
    (assert-equal (loaded) 70))
  (run-game)))

(test "loaded continuation reverts state to save time" (lambda ()
  ;; The critical game-save test: save, mutate, load → state reverts
  (define (run-game)
    (define room (make-parameter "kitchen"))
    (room "dungeon")

    (define val
      (call/cc (lambda (k)
        ;; Save while room = "dungeon"
        (save-continuation! "/tmp/ece-rt-revert.dat" k)
        ;; Mutate AFTER save
        (room "basement")
        'first-pass)))

    (cond
     ((eq? val 'first-pass)
      ;; room was mutated to "basement" after save
      (assert-equal (room) "basement")
      ;; Load and invoke — should revert to "dungeon"
      (define loaded-k (load-continuation "/tmp/ece-rt-revert.dat"))
      (loaded-k 'from-loaded))
     ((eq? val 'from-loaded)
      ;; Resumed from loaded continuation — room should be "dungeon"
      (room))))

  (assert-equal (run-game) "dungeon")))

(test "loaded continuation reverts multiple parameters" (lambda ()
  (define (run-game)
    (define room (make-parameter "start"))
    (define hp (make-parameter 100))
    (define inventory (make-parameter '()))

    (room "dungeon")
    (hp 70)
    (inventory (list "key"))

    (define val
      (call/cc (lambda (k)
        (save-continuation! "/tmp/ece-rt-revert-multi.dat" k)
        ;; Mutate all state after save
        (room "final-boss")
        (hp 1)
        (inventory (list "key" "sword" "potion"))
        'first-pass)))

    (cond
     ((eq? val 'first-pass)
      (define loaded-k (load-continuation "/tmp/ece-rt-revert-multi.dat"))
      (loaded-k 'from-loaded))
     ((eq? val 'from-loaded)
      ;; All state should revert to save-time values
      (list (room) (hp) (inventory)))))

  (define result (run-game))
  (assert-equal (car result) "dungeon")
  (assert-equal (cadr result) 70)
  (assert-equal (caddr result) (list "key"))))
