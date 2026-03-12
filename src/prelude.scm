;;; ECE Standard Prelude
;;; Pure ECE definitions loaded automatically at system initialization.

;; ---- List accessors (compositions of car/cdr) ----

(define (cadr x) (car (cdr x)))
(define (caddr x) (car (cdr (cdr x))))
(define (caar x) (car (car x)))
(define (cddr x) (cdr (cdr x)))

(define (list-ref lst n)
  (if (= n 0)
      (car lst)
      (list-ref (cdr lst) (- n 1))))

(define (list-tail lst n)
  (if (= n 0)
      lst
      (list-tail (cdr lst) (- n 1))))

;; ---- Core list functions ----

(define (reverse lst)
  (begin
    (define (iter rest acc)
      (if (null? rest)
          acc
          (iter (cdr rest) (cons (car rest) acc))))
    (iter lst (quote ()))))

(define (length lst)
  (begin
    (define (iter rest n)
      (if (null? rest)
          n
          (iter (cdr rest) (+ n 1))))
    (iter lst 0)))

(define (append a . rest)
  (if (null? rest)
      a
      (begin
        (define (append2 x y)
          (if (null? x) y (cons (car x) (append2 (cdr x) y))))
        (define (append-all lists)
          (if (null? (cdr lists))
              (car lists)
              (append2 (car lists) (append-all (cdr lists)))))
        (append-all (cons a rest)))))

(define (member x lst)
  (if (null? lst)
      (quote ())
      (if (equal? x (car lst))
          lst
          (member x (cdr lst)))))

(define (assoc key alist)
  (if (null? alist)
      (quote ())
      (if (equal? key (car (car alist)))
          (car alist)
          (assoc key (cdr alist)))))

;; ---- Derived predicates ----

(define (not x) (if x (quote ()) t))

(define (zero? n) (= n 0))
(define (even? n) (= (modulo n 2) 0))
(define (odd? n) (not (even? n)))
(define (positive? n) (> n 0))
(define (negative? n) (< n 0))

(define (boolean? x) (if (eq? x t) t (if (null? x) t (quote ()))))

(define (<= a b) (not (> a b)))
(define (>= a b) (not (< a b)))

;; ---- Higher-order functions ----

(define (map f lst)
  (begin
    (define (iter rest acc)
      (if (null? rest)
          (reverse acc)
          (iter (cdr rest) (cons (f (car rest)) acc))))
    (iter lst (quote ()))))

(define (reduce f init lst)
  (if (null? lst)
      init
      (reduce f (f init (car lst)) (cdr lst))))

(define (for-each f lst)
  (if (null? lst)
      (quote ())
      (begin (f (car lst))
             (for-each f (cdr lst)))))

(define (filter pred lst)
  (begin
    (define (iter rest acc)
      (if (null? rest)
          (reverse acc)
          (if (pred (car rest))
              (iter (cdr rest) (cons (car rest) acc))
              (iter (cdr rest) acc))))
    (iter lst (quote ()))))

;; ---- Math helpers ----

(define (abs n) (if (< n 0) (- 0 n) n))

(define (min first . rest)
  (begin
    (define (iter best remaining)
      (if (null? remaining)
          best
          (iter (if (< (car remaining) best) (car remaining) best)
                (cdr remaining))))
    (iter first rest)))

(define (max first . rest)
  (begin
    (define (iter best remaining)
      (if (null? remaining)
          best
          (iter (if (> (car remaining) best) (car remaining) best)
                (cdr remaining))))
    (iter first rest)))

;; List predicates
(define (any pred lst)
  (if (null? lst)
      ()
      (if (pred (car lst))
          t
          (any pred (cdr lst)))))

(define (every pred lst)
  (if (null? lst)
      t
      (if (pred (car lst))
          (every pred (cdr lst))
          ())))

;; Function composition
(define (compose f g)
  (lambda (x) (f (g x))))

(define (identity x) x)

;; List generation
(define (range n)
  (begin
    (define (iter i acc)
      (if (= i 0)
          acc
          (iter (- i 1) (cons (- i 1) acc))))
    (iter n (quote ()))))

;; Standard derived forms (macros)
(define-macro (cond . clauses)
  (if (null? clauses)
      (quote ())
      (if (eq? (caar clauses) (quote else))
          `(begin ,@(cdr (car clauses)))
          `(if ,(caar clauses)
               (begin ,@(cdr (car clauses)))
               (cond ,@(cdr clauses))))))

(define-macro (let bindings . body)
  (if (symbol? bindings)
      ;; Named let: (let name ((var init) ...) body...)
      ;; bindings is the name, (car body) is the actual bindings, (cdr body) is the real body
      `(begin (define (,bindings ,@(map car (car body))) ,@(cdr body))
              (,bindings ,@(map cadr (car body))))
      ;; Regular let: (let ((var init) ...) body...)
      (cons `(lambda ,(map car bindings)
               ,@body)
            (map cadr bindings))))

(define-macro (let* bindings . body)
  (if (null? bindings)
      `(begin ,@body)
      `(let (,(car bindings))
         (let* ,(cdr bindings) ,@body))))

(define-macro (and . args)
  (if (null? args)
      (quote t)
      (if (null? (cdr args))
          (car args)
          `(if ,(car args)
               (and ,@(cdr args))
               ()))))

(define-macro (or . args)
  (if (null? args)
      (quote ())
      (if (null? (cdr args))
          (car args)
          (let ((temp (gensym)))
            `(let ((,temp ,(car args)))
               (if ,temp
                   ,temp
                   (or ,@(cdr args))))))))

(define-macro (when test . body)
  `(if ,test (begin ,@body) ()))

(define-macro (unless test . body)
  `(if ,test () (begin ,@body)))

(define-macro (letrec bindings . body)
  `(let ,(map (lambda (b) (list (car b) (quote ()))) bindings)
     ,@(map (lambda (b) `(set ,(car b) ,(cadr b))) bindings)
     ,@body))

(define-macro (case key . clauses)
  (define (expand-clauses k clauses)
    (if (null? clauses)
        (quote ())
        (if (eq? (caar clauses) (quote else))
            `(begin ,@(cdr (car clauses)))
            `(if ,(if (null? (cdr (caar clauses)))
                      `(equal? ,k (quote ,(caar (car clauses))))
                      `(or ,@(map (lambda (d) `(equal? ,k (quote ,d)))
                                  (caar clauses))))
                 (begin ,@(cdr (car clauses)))
                 ,(expand-clauses k (cdr clauses))))))
  (define (temp) (gensym))
  ((lambda (g)
     `((lambda (,g) ,(expand-clauses g clauses)) ,key))
   (temp)))

(define-macro (do bindings test-and-result . body)
  (define (var-inits) (map (lambda (b) (list (car b) (cadr b))) bindings))
  (define (var-steps)
    (map (lambda (b)
           (if (null? (cddr b))
               (car b)
               (caddr b)))
         bindings))
  (define (test-expr) (car test-and-result))
  (define (result-exprs) (cdr test-and-result))
  (define (loop-name) (gensym))
  ((lambda (name)
     `(let ,name ,(var-inits)
           (if ,(test-expr)
               (begin ,@(if (null? (result-exprs)) (list (quote ())) (result-exprs)))
               (begin ,@body (,name ,@(var-steps))))))
   (loop-name)))

;; ---- HAMT internals ----
;; Hash Array Mapped Trie for O(~1) hash table operations.
;; Node types:
;;   ()                              — empty trie
;;   (:hamt-node bitmap entries-vec) — internal node (compact)
;;   (:hamt-collision alist)         — hash collision node
;;   (key . val)                     — leaf entry (inside nodes)

(define (popcount n)
  (define (loop n count)
    (if (= n 0) count
        (loop (bitwise-and n (- n 1)) (+ count 1))))
  (loop n 0))

(define *hamt-fnv-offset* 2166136261)
(define *hamt-fnv-prime* 16777619)
(define *hamt-mask32* 4294967295)

(define (hash-string-fnv s)
  (define (loop i h)
    (if (= i (string-length s))
        h
        (loop (+ i 1)
              (bitwise-and (+ (* (bitwise-xor h (char->integer (string-ref s i)))
                                 *hamt-fnv-prime*)
                              0)  ;; force evaluation order
                           *hamt-mask32*))))
  (loop 0 *hamt-fnv-offset*))

(define (hash-code val)
  (cond
   ((null? val) 0)
   ((number? val)
    (bitwise-and (if (< val 0)
                     (bitwise-xor (- 0 val) 2654435761)
                     (* val 2654435761))
                 *hamt-mask32*))
   ((symbol? val) (hash-string-fnv (symbol->string val)))
   ((string? val) (hash-string-fnv val))
   ((eq? val t) 1)
   ((pair? val)
    (bitwise-and
     (bitwise-xor (hash-code (car val))
                  (+ (* (hash-code (cdr val)) 31) 1))
     *hamt-mask32*))
   ((vector? val)
    (define (fold-vec i h)
      (if (= i (vector-length val))
          h
          (fold-vec (+ i 1)
                    (bitwise-and (bitwise-xor h (* (hash-code (vector-ref val i)) 31))
                                 *hamt-mask32*))))
    (fold-vec 0 *hamt-fnv-offset*))
   (else 0)))

(define (hamt-index hash depth)
  (bitwise-and (arithmetic-shift hash (- 0 (* depth 5))) 31))

(define (hamt-bit hash depth)
  (arithmetic-shift 1 (hamt-index hash depth)))

(define (hamt-compressed-index bitmap bit)
  (popcount (bitwise-and bitmap (- bit 1))))

(define *hamt-not-found* (list 'hamt-not-found))

(define (hamt-lookup root key hash depth)
  (cond
   ((null? root) *hamt-not-found*)
   ((eq? (car root) :hamt-node)
    (let* ((bitmap (car (cdr root)))
           (vec (car (cdr (cdr root))))
           (bit (hamt-bit hash depth)))
      (if (= (bitwise-and bitmap bit) 0)
          *hamt-not-found*
          (let ((idx (hamt-compressed-index bitmap bit))
                (entry (vector-ref vec (hamt-compressed-index bitmap bit))))
            (cond
             ;; child node
             ((and (pair? entry) (eq? (car entry) :hamt-node))
              (hamt-lookup entry key hash (+ depth 1)))
             ;; collision node
             ((and (pair? entry) (eq? (car entry) :hamt-collision))
              (let ((found (assoc key (car (cdr entry)))))
                (if (pair? found) (cdr found) *hamt-not-found*)))
             ;; leaf (key . val)
             ((and (pair? entry) (equal? (car entry) key))
              (cdr entry))
             (else *hamt-not-found*))))))
   ((eq? (car root) :hamt-collision)
    (let ((found (assoc key (car (cdr root)))))
      (if (pair? found) (cdr found) *hamt-not-found*)))
   (else *hamt-not-found*)))

;; Copy a vector, replacing one element
(define (vector-copy-set vec idx val)
  (let* ((len (vector-length vec))
         (new (make-vector len)))
    (define (copy i)
      (when (< i len)
        (vector-set! new i (if (= i idx) val (vector-ref vec i)))
        (copy (+ i 1))))
    (copy 0)
    new))

;; Copy a vector, inserting a new element at idx (shifting right)
(define (vector-insert vec idx val)
  (let* ((len (vector-length vec))
         (new (make-vector (+ len 1))))
    (define (copy-before i)
      (when (< i idx)
        (vector-set! new i (vector-ref vec i))
        (copy-before (+ i 1))))
    (define (copy-after i)
      (when (< i len)
        (vector-set! new (+ i 1) (vector-ref vec i))
        (copy-after (+ i 1))))
    (copy-before 0)
    (vector-set! new idx val)
    (copy-after idx)
    new))

;; Copy a vector, removing element at idx (shifting left)
(define (vector-remove vec idx)
  (let* ((len (vector-length vec))
         (new (make-vector (- len 1))))
    (define (copy-before i)
      (when (< i idx)
        (vector-set! new i (vector-ref vec i))
        (copy-before (+ i 1))))
    (define (copy-after i)
      (when (< i (- len 1))
        (vector-set! new i (vector-ref vec (+ i 1)))
        (copy-after (+ i 1))))
    (copy-before 0)
    (copy-after idx)
    new))

;; Create a two-entry HAMT node from two leaves that differ at this depth
(define (hamt-make-two-node leaf1 hash1 leaf2 hash2 depth)
  (let ((idx1 (hamt-index hash1 depth))
        (idx2 (hamt-index hash2 depth)))
    (if (= idx1 idx2)
        ;; Same index at this depth — recurse deeper
        (if (>= depth 6)
            ;; Max depth — collision node
            (list :hamt-collision (list leaf1 leaf2))
            (let ((child (hamt-make-two-node leaf1 hash1 leaf2 hash2 (+ depth 1))))
              (let ((bit (arithmetic-shift 1 idx1))
                    (vec (make-vector 1)))
                (vector-set! vec 0 child)
                (list :hamt-node bit vec))))
        ;; Different indices — create node with two entries
        (let* ((bit1 (arithmetic-shift 1 idx1))
               (bit2 (arithmetic-shift 1 idx2))
               (bitmap (bitwise-or bit1 bit2))
               (vec (make-vector 2)))
          (if (< idx1 idx2)
              (begin (vector-set! vec 0 leaf1) (vector-set! vec 1 leaf2))
              (begin (vector-set! vec 0 leaf2) (vector-set! vec 1 leaf1)))
          (list :hamt-node bitmap vec)))))

;; Insert into HAMT, returns (new-root . added?) where added? is t if key was new
(define (hamt-insert root key val hash depth)
  (cond
   ;; Empty trie — create single-entry node
   ((null? root)
    (let ((bit (hamt-bit hash depth))
          (vec (make-vector 1)))
      (vector-set! vec 0 (cons key val))
      (cons (list :hamt-node bit vec) t)))
   ;; Internal node
   ((eq? (car root) :hamt-node)
    (let* ((bitmap (car (cdr root)))
           (vec (car (cdr (cdr root))))
           (bit (hamt-bit hash depth))
           (idx (hamt-compressed-index bitmap bit)))
      (if (= (bitwise-and bitmap bit) 0)
          ;; Slot empty — insert new leaf
          (let ((new-vec (vector-insert vec idx (cons key val))))
            (cons (list :hamt-node (bitwise-or bitmap bit) new-vec) t))
          ;; Slot occupied
          (let ((entry (vector-ref vec idx)))
            (cond
             ;; Child node — recurse
             ((and (pair? entry) (eq? (car entry) :hamt-node))
              (let ((result (hamt-insert entry key val hash (+ depth 1))))
                (cons (list :hamt-node bitmap (vector-copy-set vec idx (car result)))
                      (cdr result))))
             ;; Collision node — add/update in collision
             ((and (pair? entry) (eq? (car entry) :hamt-collision))
              (let* ((alist (car (cdr entry)))
                     (existing (assoc key alist)))
                (if (pair? existing)
                    ;; Update existing in collision
                    (let ((new-alist (map (lambda (pair)
                                            (if (equal? (car pair) key)
                                                (cons key val) pair))
                                          alist)))
                      (cons (list :hamt-node bitmap
                                  (vector-copy-set vec idx (list :hamt-collision new-alist)))
                            ()))
                    ;; Add to collision
                    (cons (list :hamt-node bitmap
                                (vector-copy-set vec idx
                                                 (list :hamt-collision (cons (cons key val) alist))))
                          t))))
             ;; Leaf — check if same key
             ((and (pair? entry) (equal? (car entry) key))
              ;; Update value
              (cons (list :hamt-node bitmap (vector-copy-set vec idx (cons key val)))
                    ()))
             ;; Leaf — different key, expand to subtrie
             ((pair? entry)
              (let* ((existing-hash (hash-code (car entry)))
                     (child (hamt-make-two-node entry existing-hash (cons key val) hash (+ depth 1))))
                (cons (list :hamt-node bitmap (vector-copy-set vec idx child))
                      t)))
             (else (cons root ())))))))
   ;; Collision node at root (rare)
   ((eq? (car root) :hamt-collision)
    (let* ((alist (car (cdr root)))
           (existing (assoc key alist)))
      (if (pair? existing)
          (cons (list :hamt-collision
                      (map (lambda (pair)
                             (if (equal? (car pair) key) (cons key val) pair))
                           alist))
                ())
          (cons (list :hamt-collision (cons (cons key val) alist))
                t))))
   (else (cons root ()))))

;; Remove from HAMT, returns (new-root . removed?) where removed? is t if key was found
(define (hamt-remove root key hash depth)
  (cond
   ((null? root) (cons root ()))
   ;; Internal node
   ((eq? (car root) :hamt-node)
    (let* ((bitmap (car (cdr root)))
           (vec (car (cdr (cdr root))))
           (bit (hamt-bit hash depth))
           (idx (hamt-compressed-index bitmap bit)))
      (if (= (bitwise-and bitmap bit) 0)
          ;; Key not present
          (cons root ())
          (let ((entry (vector-ref vec idx)))
            (cond
             ;; Child node — recurse
             ((and (pair? entry) (eq? (car entry) :hamt-node))
              (let ((result (hamt-remove entry key hash (+ depth 1))))
                (if (null? (cdr result))
                    (cons root ())  ;; not found
                    (let ((child (car result)))
                      (if (null? child)
                          ;; Child became empty — remove slot
                          (if (= (vector-length vec) 1)
                              (cons '() t)
                              (cons (list :hamt-node
                                          (bitwise-and bitmap (bitwise-not bit))
                                          (vector-remove vec idx))
                                    t))
                          ;; Replace child
                          (cons (list :hamt-node bitmap (vector-copy-set vec idx child))
                                t))))))
             ;; Collision node
             ((and (pair? entry) (eq? (car entry) :hamt-collision))
              (let* ((alist (car (cdr entry)))
                     (new-alist (filter (lambda (pair) (not (equal? (car pair) key))) alist)))
                (if (= (length alist) (length new-alist))
                    (cons root ())  ;; key not in collision
                    (if (= (length new-alist) 1)
                        ;; Collapse collision to leaf
                        (cons (list :hamt-node bitmap
                                    (vector-copy-set vec idx (car new-alist)))
                              t)
                        (cons (list :hamt-node bitmap
                                    (vector-copy-set vec idx
                                                     (list :hamt-collision new-alist)))
                              t)))))
             ;; Leaf — check if matching key
             ((and (pair? entry) (equal? (car entry) key))
              (if (= (vector-length vec) 1)
                  (cons '() t)  ;; node becomes empty
                  (cons (list :hamt-node
                              (bitwise-and bitmap (bitwise-not bit))
                              (vector-remove vec idx))
                        t)))
             ;; Leaf — different key
             (else (cons root ())))))))
   ;; Collision node at root
   ((eq? (car root) :hamt-collision)
    (let* ((alist (car (cdr root)))
           (new-alist (filter (lambda (pair) (not (equal? (car pair) key))) alist)))
      (if (= (length alist) (length new-alist))
          (cons root ())
          (if (null? new-alist)
              (cons '() t)
              (if (= (length new-alist) 1)
                  ;; Promote single entry — wrap in a node
                  (let* ((leaf (car new-alist))
                         (h (hash-code (car leaf)))
                         (bit (hamt-bit h depth))
                         (vec (make-vector 1)))
                    (vector-set! vec 0 leaf)
                    (cons (list :hamt-node bit vec) t))
                  (cons (list :hamt-collision new-alist) t))))))
   (else (cons root ()))))

;; Fold over all (key . val) entries in a HAMT
(define (hamt-fold f init root)
  (cond
   ((null? root) init)
   ((eq? (car root) :hamt-node)
    (let ((vec (car (cdr (cdr root)))))
      (define (fold-vec i acc)
        (if (= i (vector-length vec))
            acc
            (let ((entry (vector-ref vec i)))
              (fold-vec (+ i 1)
                        (cond
                         ((and (pair? entry)
                               (or (eq? (car entry) :hamt-node)
                                   (eq? (car entry) :hamt-collision)))
                          (hamt-fold f acc entry))
                         ((pair? entry)
                          (f acc (car entry) (cdr entry)))
                         (else acc))))))
      (fold-vec 0 init)))
   ((eq? (car root) :hamt-collision)
    (reduce (lambda (acc pair) (f acc (car pair) (cdr pair)))
            init
            (car (cdr root))))
   (else init)))

;; ---- Hash table operations ----
;; Hash tables are HAMT-backed: (:hash-table count . hamt-root)
;; The wrapper cons cell's cdr is (count . hamt-root).
;; hash-set! mutates the wrapper's cdr to preserve identity.

(define (hash-table . pairs)
  (define (build remaining root count)
    (if (null? remaining)
        (cons :hash-table (cons count root))
        (let* ((key (car remaining))
               (val (car (cdr remaining)))
               (result (hamt-insert root key val (hash-code key) 0))
               (new-root (car result))
               (added? (cdr result)))
          (build (cdr (cdr remaining))
                 new-root
                 (if added? (+ count 1) count)))))
  (build pairs '() 0))

(define (hash-table? x)
  (if (pair? x)
      (if (eq? (car x) :hash-table) t (quote ()))
      (quote ())))

(define (hash-ref ht key . default)
  (let ((result (hamt-lookup (cdr (cdr ht)) key (hash-code key) 0)))
    (if (eq? result *hamt-not-found*)
        (if (null? default) (quote ()) (car default))
        result)))

(define (hash-has-key? ht key)
  (let ((result (hamt-lookup (cdr (cdr ht)) key (hash-code key) 0)))
    (if (eq? result *hamt-not-found*) (quote ()) t)))

(define (hash-keys ht)
  (hamt-fold (lambda (acc k v) (cons k acc)) '() (cdr (cdr ht))))

(define (hash-values ht)
  (hamt-fold (lambda (acc k v) (cons v acc)) '() (cdr (cdr ht))))

(define (hash-count ht)
  (car (cdr ht)))

(define (hash-set! ht key val)
  (let* ((root (cdr (cdr ht)))
         (count (car (cdr ht)))
         (result (hamt-insert root key val (hash-code key) 0))
         (new-root (car result))
         (added? (cdr result)))
    (set-cdr! ht (cons (if added? (+ count 1) count) new-root))
    ht))

(define (hash-set ht key val)
  (let* ((root (cdr (cdr ht)))
         (count (car (cdr ht)))
         (result (hamt-insert root key val (hash-code key) 0))
         (new-root (car result))
         (added? (cdr result)))
    (cons :hash-table (cons (if added? (+ count 1) count) new-root))))

(define (hash-remove! ht key)
  (let* ((root (cdr (cdr ht)))
         (count (car (cdr ht)))
         (result (hamt-remove root key (hash-code key) 0))
         (new-root (car result))
         (removed? (cdr result)))
    (when removed?
      (set-cdr! ht (cons (- count 1) new-root)))
    ht))

;; xorshift32 PRNG
(define *random-state* 12345)

(define (random-seed! seed)
  (set *random-state* seed))

(define (xorshift32 state)
  (let* ((s1 (bitwise-xor state (arithmetic-shift state 13)))
         (s2 (bitwise-xor s1 (arithmetic-shift s1 -17)))
         (s3 (bitwise-xor s2 (arithmetic-shift s2 5))))
    (bitwise-and s3 4294967295)))

(define (random n)
  (set *random-state* (xorshift32 *random-state*))
  (modulo *random-state* n))

;; define-record macro: generate record type definitions backed by hash tables
(define-macro (define-record name . fields)
  (let ((make-name (string->symbol
                    (string-append "make-" (symbol->string name))))
        (pred-name (string->symbol
                    (string-append (symbol->string name) "?")))
        (copy-name (string->symbol
                    (string-append "copy-" (symbol->string name)))))
    `(begin
       ;; Constructor
       (define (,make-name ,@fields)
         (hash-table ,@(apply append
                              (cons (list (quote 'type) (list 'quote name))
                                    (map (lambda (f)
                                           (list (list 'quote f) f))
                                         fields)))))
       ;; Predicate
       (define (,pred-name obj)
         (and (hash-table? obj)
              (eq? (hash-ref obj 'type) ',name)))
       ;; Accessors
       ,@(map (lambda (f)
                (let ((acc-name (string->symbol
                                 (string-append (symbol->string name)
                                                "-"
                                                (symbol->string f)))))
                  `(define (,acc-name obj)
                     (hash-ref obj ',f))))
              fields)
       ;; Mutators
       ,@(map (lambda (f)
                (let ((mut-name (string->symbol
                                 (string-append "set-"
                                                (symbol->string name)
                                                "-"
                                                (symbol->string f)
                                                "!"))))
                  `(define (,mut-name obj val)
                     (hash-set! obj ',f val))))
              fields)
       ;; Functional update accessors
       ,@(map (lambda (f)
                (let ((with-name (string->symbol
                                  (string-append (symbol->string name)
                                                 "-with-"
                                                 (symbol->string f)))))
                  `(define (,with-name obj val)
                     (hash-set obj ',f val))))
              fields)
       ;; Copy function
       (define (,copy-name obj)
         (hash-table ,@(apply append
                              (cons (list (quote 'type) (list 'quote name))
                                    (map (lambda (f)
                                           (list (list 'quote f)
                                                 (list (string->symbol
                                                        (string-append (symbol->string name)
                                                                       "-"
                                                                       (symbol->string f)))
                                                       'obj)))
                                         fields))))))))

;; clamp: constrain a number to a range
(define (clamp x low high)
  (min (max x low) high))

;; fold aliases for reduce
(define fold reduce)
(define fold-left reduce)

;; fold-right: right-to-left fold
(define (fold-right f init lst)
  (if (null? lst)
      init
      (f (car lst) (fold-right f init (cdr lst)))))

;; loop: infinite loop with break
(define-macro (loop . body)
  (let ((go-sym (gensym)))
    `(call/cc (lambda (break)
                (let ,go-sym () ,@body (,go-sym))))))

;; collect: concise list comprehension
(define-macro (collect binding . body)
  `(map (lambda (,(car binding)) ,@body) ,(cadr binding)))

;; Set operations (eq?-based, for symbol lists)
(define (union s1 s2)
  (cond ((null? s1) s2)
        ((member (car s1) s2) (union (cdr s1) s2))
        (else (cons (car s1) (union (cdr s1) s2)))))

(define (set-difference s1 s2)
  (cond ((null? s1) (quote ()))
        ((member (car s1) s2) (set-difference (cdr s1) s2))
        (else (cons (car s1) (set-difference (cdr s1) s2)))))

;; parameterize: dynamic rebinding of parameter objects (R7RS / SRFI-39)
(define-macro (parameterize bindings . body)
  (if (null? bindings)
      `(begin ,@body)
      (let ((param (car (car bindings)))
            (val (cadr (car bindings)))
            (rest (cdr bindings)))
        (let ((old (gensym)) (result (gensym)))
          `(let ((,old (,param)))
             (,param ,val)
             (let ((,result (parameterize ,rest ,@body)))
               (,param ,old t)
               ,result))))))

;; assert macro: signal error if condition is falsy
(define-macro (assert expr . rest)
  (if (null? rest)
      `(if (not ,expr) (error "Assertion failed") ())
      `(if (not ,expr) (error ,(car rest)) ())))
