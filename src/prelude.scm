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

;; ---- Hash table operations (platform-native) ----
;; Hash tables are backed by platform primitives (%make-hash-table, hash-ref,
;; hash-set!, etc.). The HAMT implementation is available as a library in
;; lib/hamt.scm for users who need persistent/immutable hash maps.

;; hash-table constructor: create platform hash table from key-value pairs
(define (hash-table . pairs)
  (let build ((remaining pairs) (ht (%make-hash-table)))
    (if (null? remaining)
        ht
        (begin
          (hash-set! ht (car remaining) (car (cdr remaining)))
          (build (cdr (cdr remaining)) ht)))))

;; hash-set (functional): copy and mutate
(define (hash-set ht key val)
  (let ((new (%make-hash-table)))
    (for-each (lambda (k) (hash-set! new k (hash-ref ht k)))
              (hash-keys ht))
    (hash-set! new key val)
    new))

;; make-parameter wrapper: apply optional converter to initial value.
;; The raw primitive (ID 88) just stores the value. This wrapper calls
;; the converter before passing the result to the primitive.
(define %raw-make-parameter make-parameter)
(define (make-parameter init . rest)
  (if (null? rest)
      (%raw-make-parameter init)
      (%raw-make-parameter ((car rest) init) (car rest))))

;; yield: cooperative multitasking via continuations.
;; Captures the current continuation, stores it for JS, and causes the
;; executor to return. JS can resume by invoking the stored continuation.
(define (yield)
  (call/cc (lambda (k) (%yield! k))))

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

;; ---- String evaluation ----
;; Evaluate all expressions from a source string using ECE's own reader.

(define (eval-string str)
  "Read and evaluate all expressions from STR for side effects."
  (let ((port (open-input-string str)))
    (let loop ()
      (let ((expr (read port)))
        (unless (eof? expr)
          (eval expr)
          (loop))))))

(define (eval-string-last str)
  "Read and evaluate all expressions from STR, return last value."
  (let ((port (open-input-string str)))
    (let loop ((result (if #f #f)))  ;; void initial
      (let ((expr (read port)))
        (if (eof? expr)
            result
            (loop (eval expr)))))))

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
  (let* ((port (open-output-file filename))
         (s (serialize-value value)))
    (let loop ((i 0))
      (when (< i (string-length s))
        (write-char (string-ref s i) port)
        (loop (+ i 1))))
    (write-char #\newline port)
    (close-output-port port)
    #t))

(define (load-continuation filename)
  "Deserialize a value from FILENAME. Returns the deserialized value."
  (let* ((port (open-input-file filename))
         (form (ece-scheme-read port)))
    (close-input-port port)
    (deserialize-value form)))
