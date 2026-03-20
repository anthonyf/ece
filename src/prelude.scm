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
      #f
      (if (equal? x (car lst))
          lst
          (member x (cdr lst)))))

(define (assoc key alist)
  (if (null? alist)
      #f
      (if (equal? key (car (car alist)))
          (car alist)
          (assoc key (cdr alist)))))

;; ---- Derived predicates ----

(define (not x) (if x #f #t))

(define (zero? n) (= n 0))
(define (even? n) (= (modulo n 2) 0))
(define (odd? n) (not (even? n)))
(define (positive? n) (> n 0))
(define (negative? n) (< n 0))

(define (boolean? x) (if (eq? x #t) #t (if (eq? x #f) #t #f)))

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
      #f
      (if (pred (car lst))
          #t
          (any pred (cdr lst)))))

(define (every pred lst)
  (if (null? lst)
      #t
      (if (pred (car lst))
          (every pred (cdr lst))
          #f)))

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
      #f
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
      #t
      (if (null? (cdr args))
          (car args)
          `(if ,(car args)
               (and ,@(cdr args))
               #f))))

(define-macro (or . args)
  (if (null? args)
      #f
      (if (null? (cdr args))
          (car args)
          (let ((temp (gensym)))
            `(let ((,temp ,(car args)))
               (if ,temp
                   ,temp
                   (or ,@(cdr args))))))))

(define-macro (when test . body)
  `(if ,test (begin ,@body)))

(define-macro (unless test . body)
  `(if (not ,test) (begin ,@body)))

(define-macro (letrec bindings . body)
  `(let ,(map (lambda (b) (list (car b) (quote ()))) bindings)
     ,@(map (lambda (b) `(set ,(car b) ,(cadr b))) bindings)
     ,@body))

(define-macro (case key . clauses)
  (define (expand-clauses k clauses)
    (if (null? clauses)
        #f
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
   ((eq? val #t) 1)
   ((eq? val #f) 2)
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

;; Insert into HAMT, returns (new-root . added?) where added? is #t if key was new
(define (hamt-insert root key val hash depth)
  (cond
   ;; Empty trie — create single-entry node
   ((null? root)
    (let ((bit (hamt-bit hash depth))
          (vec (make-vector 1)))
      (vector-set! vec 0 (cons key val))
      (cons (list :hamt-node bit vec) #t)))
   ;; Internal node
   ((eq? (car root) :hamt-node)
    (let* ((bitmap (car (cdr root)))
           (vec (car (cdr (cdr root))))
           (bit (hamt-bit hash depth))
           (idx (hamt-compressed-index bitmap bit)))
      (if (= (bitwise-and bitmap bit) 0)
          ;; Slot empty — insert new leaf
          (let ((new-vec (vector-insert vec idx (cons key val))))
            (cons (list :hamt-node (bitwise-or bitmap bit) new-vec) #t))
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
                (if existing
                    ;; Update existing in collision
                    (let ((new-alist (map (lambda (pair)
                                            (if (equal? (car pair) key)
                                                (cons key val) pair))
                                          alist)))
                      (cons (list :hamt-node bitmap
                                  (vector-copy-set vec idx (list :hamt-collision new-alist)))
                            #f))
                    ;; Add to collision
                    (cons (list :hamt-node bitmap
                                (vector-copy-set vec idx
                                                 (list :hamt-collision (cons (cons key val) alist))))
                          #t))))
             ;; Leaf — check if same key
             ((and (pair? entry) (equal? (car entry) key))
              ;; Update value
              (cons (list :hamt-node bitmap (vector-copy-set vec idx (cons key val)))
                    #f))
             ;; Leaf — different key, expand to subtrie
             ((pair? entry)
              (let* ((existing-hash (hash-code (car entry)))
                     (child (hamt-make-two-node entry existing-hash (cons key val) hash (+ depth 1))))
                (cons (list :hamt-node bitmap (vector-copy-set vec idx child))
                      #t)))
             (else (cons root #f)))))))
   ;; Collision node at root (rare)
   ((eq? (car root) :hamt-collision)
    (let* ((alist (car (cdr root)))
           (existing (assoc key alist)))
      (if existing
          (cons (list :hamt-collision
                      (map (lambda (pair)
                             (if (equal? (car pair) key) (cons key val) pair))
                           alist))
                #f)
          (cons (list :hamt-collision (cons (cons key val) alist))
                #t))))
   (else (cons root #f))))

;; Remove from HAMT, returns (new-root . removed?) where removed? is #t if key was found
(define (hamt-remove root key hash depth)
  (cond
   ((null? root) (cons root #f))
   ;; Internal node
   ((eq? (car root) :hamt-node)
    (let* ((bitmap (car (cdr root)))
           (vec (car (cdr (cdr root))))
           (bit (hamt-bit hash depth))
           (idx (hamt-compressed-index bitmap bit)))
      (if (= (bitwise-and bitmap bit) 0)
          ;; Key not present
          (cons root #f)
          (let ((entry (vector-ref vec idx)))
            (cond
             ;; Child node — recurse
             ((and (pair? entry) (eq? (car entry) :hamt-node))
              (let ((result (hamt-remove entry key hash (+ depth 1))))
                (if (not (cdr result))
                    (cons root #f)  ;; not found
                    (let ((child (car result)))
                      (if (null? child)
                          ;; Child became empty — remove slot
                          (if (= (vector-length vec) 1)
                              (cons '() #t)
                              (cons (list :hamt-node
                                          (bitwise-and bitmap (bitwise-not bit))
                                          (vector-remove vec idx))
                                    #t))
                          ;; Replace child
                          (cons (list :hamt-node bitmap (vector-copy-set vec idx child))
                                #t))))))
             ;; Collision node
             ((and (pair? entry) (eq? (car entry) :hamt-collision))
              (let* ((alist (car (cdr entry)))
                     (new-alist (filter (lambda (pair) (not (equal? (car pair) key))) alist)))
                (if (= (length alist) (length new-alist))
                    (cons root #f)  ;; key not in collision
                    (if (= (length new-alist) 1)
                        ;; Collapse collision to leaf
                        (cons (list :hamt-node bitmap
                                    (vector-copy-set vec idx (car new-alist)))
                              #t)
                        (cons (list :hamt-node bitmap
                                    (vector-copy-set vec idx
                                                     (list :hamt-collision new-alist)))
                              #t)))))
             ;; Leaf — check if matching key
             ((and (pair? entry) (equal? (car entry) key))
              (if (= (vector-length vec) 1)
                  (cons '() #t)  ;; node becomes empty
                  (cons (list :hamt-node
                              (bitwise-and bitmap (bitwise-not bit))
                              (vector-remove vec idx))
                        #t)))
             ;; Leaf — different key
             (else (cons root #f)))))))
   ;; Collision node at root
   ((eq? (car root) :hamt-collision)
    (let* ((alist (car (cdr root)))
           (new-alist (filter (lambda (pair) (not (equal? (car pair) key))) alist)))
      (if (= (length alist) (length new-alist))
          (cons root #f)
          (if (null? new-alist)
              (cons '() #t)
              (if (= (length new-alist) 1)
                  ;; Promote single entry — wrap in a node
                  (let* ((leaf (car new-alist))
                         (h (hash-code (car leaf)))
                         (bit (hamt-bit h depth))
                         (vec (make-vector 1)))
                    (vector-set! vec 0 leaf)
                    (cons (list :hamt-node bit vec) #t))
                  (cons (list :hamt-collision new-alist) #t))))))
   (else (cons root #f))))

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
      (if (eq? (car x) :hash-table) #t #f)
      #f))

(define (hash-ref ht key . default)
  (let ((result (hamt-lookup (cdr (cdr ht)) key (hash-code key) 0)))
    (if (eq? result *hamt-not-found*)
        (if (null? default) #f (car default))
        result)))

(define (hash-has-key? ht key)
  (let ((result (hamt-lookup (cdr (cdr ht)) key (hash-code key) 0)))
    (if (eq? result *hamt-not-found*) #f #t)))

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
  (set! *random-state* seed))

(define (xorshift32 state)
  (let* ((s1 (bitwise-xor state (arithmetic-shift state 13)))
         (s2 (bitwise-xor s1 (arithmetic-shift s1 -17)))
         (s3 (bitwise-xor s2 (arithmetic-shift s2 5))))
    (bitwise-and s3 4294967295)))

(define (random n)
  (set! *random-state* (xorshift32 *random-state*))
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

;; ---- dynamic-wind (R7RS) ----
;; Winding stack: list of (before . after) pairs, innermost first.

(define *winding-stack* '())

(define (do-winds! from to)
  "Transition from winding stack FROM to TO.
   Calls after thunks for exited extents, before thunks for entered extents."
  (if (eq? from to)
      ()
      (begin
        (define (shared-tail a b)
          (cond ((eq? a b) a)
                ((> (length a) (length b))
                 (shared-tail (cdr a) b))
                ((< (length a) (length b))
                 (shared-tail a (cdr b)))
                (else (shared-tail (cdr a) (cdr b)))))
        (define common (shared-tail from to))
        ;; Unwind: call after thunks for exited extents (innermost first)
        (define (unwind ws)
          (when (not (eq? ws common))
            (set! *winding-stack* (cdr ws))
            ((cdr (car ws)))  ;; after thunk
            (unwind (cdr ws))))
        (unwind from)
        ;; Rewind: call before thunks for entered extents (outermost first)
        (define (rewind ws)
          (when (not (eq? ws common))
            (rewind (cdr ws))
            ((car (car ws)))  ;; before thunk
            (set! *winding-stack* (cons (car ws) *winding-stack*))))
        (rewind to))))

(define (dynamic-wind before thunk after)
  "R7RS dynamic-wind: call before, thunk, after with proper winding."
  (before)
  (set! *winding-stack* (cons (cons before after) *winding-stack*))
  (let ((result (thunk)))
    (set! *winding-stack* (cdr *winding-stack*))
    (after)
    result))

;; ---- call/cc: winding-aware continuation capture (R7RS) ----

(define-macro (call/cc receiver)
  (let ((saved (gensym))
        (raw-k (gensym))
        (val (gensym)))
    `(let ((,saved *winding-stack*))
       (%raw-call/cc (lambda (,raw-k)
                       (,receiver (lambda (,val)
                                    (do-winds! *winding-stack* ,saved)
                                    (,raw-k ,val))))))))

(define (call-with-current-continuation receiver)
  (call/cc receiver))

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
               (,param ,old #t)
               ,result))))))

;; ---- Error objects (R7RS) ----

(define-record error-object message irritants)

;; ---- Exception handling (R7RS) ----

(define *current-exception-handler* '())

(define (raise obj)
  "Raise an exception. Invoke the current handler or fall through to CL."
  (if (null? *current-exception-handler*)
      ;; No handler: fall through to CL error system
      (if (error-object? obj)
          (%raw-error (error-object-message obj))
          (%raw-error (write-to-string obj)))
      (let ((handler *current-exception-handler*))
        (handler obj)
        ;; If handler returns, it's a non-continuable exception error
        (%raw-error "exception handler returned on non-continuable exception"))))

(define (with-exception-handler handler thunk)
  "Install HANDLER as exception handler for the dynamic extent of THUNK."
  (let ((old-handler *current-exception-handler*))
    (dynamic-wind
        (lambda () (set! *current-exception-handler* handler))
        thunk
        (lambda () (set! *current-exception-handler* old-handler)))))

(define (error msg . irritants)
  "Create an error object and raise it."
  (raise (make-error-object msg irritants)))

;; ---- guard macro (R7RS) ----

(define-macro (guard var-and-clauses . body)
  (let ((var (car var-and-clauses))
        (clauses (cdr var-and-clauses))
        (guard-k (gensym))
        (condition (gensym))
        (prev-handler (gensym)))
    (define (has-else? clauses)
      (if (null? clauses) #f
          (if (eq? (caar clauses) 'else) #t
              (has-else? (cdr clauses)))))
    (let ((full-clauses
           (if (has-else? clauses)
               clauses
               ;; Re-raise goes to previous handler directly, not through raise
               ;; (which would call the current guard's handler again)
               (append clauses
                       (list `(else (if (null? ,prev-handler)
                                        (%raw-error (if (error-object? ,condition)
                                                        (error-object-message ,condition)
                                                        "unhandled exception"))
                                        (,prev-handler ,condition))))))))
      `(let ((,prev-handler *current-exception-handler*))
         (call/cc (lambda (,guard-k)
                    (with-exception-handler
                     (lambda (,condition)
                       (,guard-k
                        (let ((,var ,condition))
                          (cond ,@full-clauses))))
                     (lambda () ,@body))))))))

;; assert macro: signal error if condition is falsy
(define-macro (assert expr . rest)
  (if (null? rest)
      `(if (not ,expr) (error "Assertion failed") ())
      `(if (not ,expr) (error ,(car rest)) ())))

;; ---- Value Serialization ----
;; Serialize/deserialize any ECE value to/from s-expression strings.
;; Handles shared structure via %ser/def/%ser/ref tags.

(define (serialize-value value)
  "Serialize VALUE to an s-expression string. Handles all ECE types,
shared structure, and global env sentinel."
  ;; Pass 1: count object occurrences by identity for shared-structure detection.
  ;; Uses an eq hash table mapping objects to visit counts.
  (define seen (%eq-hash-table))
  (define global-frame (%global-env-frame))

  (define (scan obj)
    (cond
     ;; Skip atoms (numbers, strings, chars, booleans, symbols, nil)
     ((or (number? obj) (string? obj) (char? obj)
          (eq? obj #t) (eq? obj #f) (null? obj) (symbol? obj))
      '())
     ;; Compound: check if already visited
     (else
      (define count (%eq-hash-ref seen obj))
      (if count
          (%eq-hash-set! seen obj (+ count 1))
          (begin
            (%eq-hash-set! seen obj 1)
            (cond
             ;; Global env frame — don't scan into it
             ((eq? obj global-frame) '())
             ;; Hash frame — don't scan CL hash table internals
             ((%hash-frame? obj) '())
             ;; Vector
             ((vector? obj)
              (define len (vector-length obj))
              (define (scan-vec i)
                (when (< i len) (scan (vector-ref obj i)) (scan-vec (+ i 1))))
              (scan-vec 0))
             ;; Pair/list
             ((pair? obj) (scan (car obj)) (scan (cdr obj)))
             ;; Other compound (compiled-procedure, continuation, etc.)
             ;; These are list-tagged, so the pair? branch handles them
             (else '())))))))

  (scan value)

  ;; Pass 2: serialize with #:def/#:ref for shared objects.
  (define next-id 0)
  (define refs (%eq-hash-table))  ;; obj -> assigned ref ID (only for shared)

  (define (ser obj)
    (cond
     ;; nil
     ((null? obj) "()")
     ;; booleans
     ((eq? obj #t) "#t")
     ((eq? obj #f) "#f")
     ;; numbers
     ((number? obj) (write-to-string-flat obj))
     ;; characters
     ((char? obj) (write-to-string-flat obj))
     ;; strings — use write-to-string-flat for proper escaping
     ((string? obj) (write-to-string-flat obj))
     ;; symbols — use symbol->string for case-preserving output
     ((symbol? obj) (symbol->string obj))
     ;; compound: check for shared structure
     (else
      (define existing-ref (%eq-hash-ref refs obj))
      (if existing-ref
          ;; Already emitted — back-reference
          (string-append "(%ser/ref " (write-to-string-flat existing-ref) ")")
          ;; First visit of compound object
          (begin
            (define count (%eq-hash-ref seen obj))
            (define id (if (and count (> count 1))
                           (begin
                             (define this-id next-id)
                             (set! next-id (+ next-id 1))
                             (%eq-hash-set! refs obj this-id)
                             this-id)
                           #f))
            (define serialized (ser-compound obj))
            (if id
                (string-append "(%ser/def " (write-to-string-flat id) " " serialized ")")
                serialized))))))

  (define (ser-compound obj)
    (cond
     ;; Global env frame sentinel
     ((eq? obj global-frame) "(%ser/global-env)")
     ;; Hash frame sentinel — shouldn't normally be serialized directly
     ((%hash-frame? obj) "(%ser/hash-frame)")
     ;; Hash table (:hash-table count . root)
     ((and (pair? obj) (eq? (car obj) :hash-table))
      (define entries (map (lambda (k) (cons k (hash-ref obj k))) (hash-keys obj)))
      (string-append "(%ser/hash-table"
                     (apply string-append
                            (map (lambda (kv)
                                   (string-append " (" (ser (car kv)) " " (ser (cdr kv)) ")"))
                                 entries))
                     ")"))
     ;; Parameter
     ((and (pair? obj) (eq? (car obj) 'parameter))
      (define cell (cadr obj))
      (string-append "(%ser/parameter " (ser (car cell)) " " (ser (cdr cell)) ")"))
     ;; Compiled procedure
     ((and (pair? obj) (eq? (car obj) 'compiled-procedure))
      (define entry (cadr obj))
      (define env (caddr obj))
      (string-append "(%ser/compiled-procedure" (ser-entry entry) " " (ser env) ")"))
     ;; Continuation
     ((and (pair? obj) (eq? (car obj) 'continuation))
      (define stack (cadr obj))
      (define cont (caddr obj))
      (string-append "(%ser/continuation" (ser stack) " " (ser-entry cont) ")"))
     ;; Primitive
     ((and (pair? obj) (eq? (car obj) 'primitive))
      (define id-or-name (cadr obj))
      (define name (if (number? id-or-name)
                       (%primitive-name id-or-name)
                       id-or-name))
      (string-append "(%ser/primitive" (write-to-string-flat name) ")"))
     ;; Vector
     ((vector? obj)
      (define len (vector-length obj))
      (define (vec-items i)
        (if (>= i len) ""
            (string-append " " (ser (vector-ref obj i)) (vec-items (+ i 1)))))
      (string-append "(%ser/vector" (vec-items 0) ")"))
     ;; Regular pair/list
     ((pair? obj) (ser-pair obj))
     ;; Fallback
     (else (write-to-string-flat obj))))

  (define (ser-entry entry)
    "Serialize a space-qualified entry address or bare integer."
    (if (pair? entry)
        (string-append "(" (write-to-string-flat (car entry))
                       " . " (write-to-string-flat (cdr entry)) ")")
        (write-to-string-flat entry)))

  (define (ser-pair obj)
    "Serialize a pair, detecting proper lists for compact output."
    (define (proper-list? x)
      (cond ((null? x) #t)
            ((not (pair? x)) #f)
            ;; If tail is shared, stop — don't follow into shared structure
            ((and (%eq-hash-ref seen (cdr x))
                  (> (%eq-hash-ref seen (cdr x)) 1)
                  (%eq-hash-ref refs (cdr x)))
             #f)
            (else (proper-list? (cdr x)))))
    (if (proper-list? obj)
        ;; Proper list
        (string-append "("
                       (let loop ((xs obj) (first #t))
                         (if (null? xs) ")"
                             (string-append (if first "" " ")
                                            (ser (car xs))
                                            (loop (cdr xs) #f)))))
        ;; Dotted pair
        (string-append "(" (ser (car obj)) " . " (ser (cdr obj)) ")")))

  ;; Run serialization
  (ser value))

(define (deserialize-value form)
  "Deserialize a value from a parsed s-expression FORM (already read by ECE reader).
Reconstructs tagged types and resolves #:def/#:ref references."
  (define ref-table (%eq-hash-table))

  (define (deser form)
    (cond
     ;; Atoms pass through
     ((or (number? form) (string? form) (char? form)
          (eq? form #t) (eq? form #f) (null? form) (symbol? form))
      form)
     ;; Tagged forms
     ((and (pair? form) (symbol? (car form)))
      (define tag (symbol->string (car form)))
      (cond
       ;; Back-reference
       ((string=? tag "%ser/ref")
        (%eq-hash-ref ref-table (cadr form)))
       ;; Definition (shared structure)
       ((string=? tag "%ser/def")
        (define id (cadr form))
        (define val (deser (caddr form)))
        (%eq-hash-set! ref-table id val)
        val)
       ;; Global env sentinel
       ((string=? tag "%ser/global-env")
        (%global-env-frame))
       ;; Hash frame sentinel
       ((string=? tag "%ser/hash-frame")
        (%global-env-frame))  ;; best approximation
       ;; Hash table
       ((string=? tag "%ser/hash-table")
        (define entries (cdr form))
        (define ht (hash-table))
        (for-each (lambda (kv) (hash-set! ht (deser (car kv)) (deser (cadr kv))))
                  entries)
        ht)
       ;; Parameter
       ((string=? tag "%ser/parameter")
        (define val (deser (cadr form)))
        (define converter (deser (caddr form)))
        (list 'parameter (cons val converter)))
       ;; Compiled procedure
       ((string=? tag "%ser/compiled-procedure")
        (define entry (cadr form))
        (define env (deser (caddr form)))
        (list 'compiled-procedure entry env))
       ;; Continuation
       ((string=? tag "%ser/continuation")
        (define stack (deser (cadr form)))
        (define cont (caddr form))
        (list 'continuation stack cont))
       ;; Primitive by name
       ((string=? tag "%ser/primitive")
        (define name (cadr form))
        (define id (%primitive-id name))
        (if id
            (list 'primitive id)
            (list 'primitive name)))
       ;; Vector
       ((string=? tag "%ser/vector")
        (list->vector (map deser (cdr form))))
       ;; Regular list/pair — deser elements
       (else (deser-pair form))))
     ;; Non-tagged pair — deser elements
     ((pair? form) (deser-pair form))
     ;; Fallback
     (else form)))

  (define (deser-pair form)
    (if (pair? form)
        (cons (deser (car form)) (deser (cdr form)))
        (deser form)))

  (deser form))

(define (save-continuation! filename value)
  "Serialize VALUE to FILENAME. Returns #t."
  (define port (open-output-file filename))
  (define s (serialize-value value))
  (define len (string-length s))
  (define (write-loop i)
    (when (< i len)
      (write-char (string-ref s i) port)
      (write-loop (+ i 1))))
  (write-loop 0)
  (write-char #\newline port)
  (close-output-port port)
  #t)

(define (load-continuation filename)
  "Deserialize a value from FILENAME. Returns the deserialized value."
  (define port (open-input-file filename))
  (define form (ece-scheme-read port))
  (close-input-port port)
  (deserialize-value form))
