;;; ECE Standard Prelude
;;; Pure ECE definitions loaded automatically at system initialization.

;; ---- List accessors (compositions of car/cdr) ----

(define (cadr x) (car (cdr x)))
(define (caddr x) (car (cdr (cdr x))))
(define (caar x) (car (car x)))
(define (cddr x) (cdr (cdr x)))
(define (cdddr x) (cdr (cdr (cdr x))))
(define (cadddr x) (car (cdr (cdr (cdr x)))))

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

;; ---- Integer arithmetic ----
;; quotient/remainder use truncation (toward zero).
;; modulo uses floor (toward -∞). Replaces host primitive 4.

(define (quotient a b)
  (if (= b 0) (error "/: division by zero")
      (truncate (/ a b))))
(define (remainder a b)
  (if (= b 0) (error "/: division by zero")
      (- a (* (quotient a b) b))))
(define (modulo a b)
  (if (= b 0) (error "/: division by zero")
      (- a (* (floor (/ a b)) b))))

(define (number->string n)
  (if (not (integer? n))
      (number->string (truncate n))
      (if (< n 0)
          (string-append "-" (number->string (- 0 n)))
          (if (< n 10)
              (string (integer->char (+ n 48)))
              (string-append (number->string (quotient n 10))
                             (string (integer->char (+ (modulo n 10) 48))))))))

(define (string->number s)
  (let ((len (string-length s)))
    (if (= len 0) #f
        (let* ((start (if (or (char=? (string-ref s 0) #\-)
                              (char=? (string-ref s 0) #\+))
                          1 0))
               (neg (char=? (string-ref s 0) #\-)))
          (if (= start len) #f
              (%parse-digits s start len neg))))))

(define (%parse-digits s start len neg)
  (let loop ((i start) (acc 0))
    (if (= i len)
        (if neg (- 0 acc) acc)
        (let ((ch (string-ref s i)))
          (if (char=? ch #\.)
              (%parse-frac s (+ i 1) len acc neg)
              (let ((d (- (char->integer ch) 48)))
                (if (or (< d 0) (> d 9))
                    #f
                    (loop (+ i 1) (+ (* acc 10) d)))))))))

(define (%parse-frac s start len int-part neg)
  (if (= start len) #f
      (let loop ((i start) (frac 0) (divisor 1))
        (if (= i len)
            (let ((result (exact->inexact (+ int-part (/ frac divisor)))))
              (if neg (- 0 result) result))
            (let ((d (- (char->integer (string-ref s i)) 48)))
              (if (or (< d 0) (> d 9))
                  #f
                  (loop (+ i 1) (+ (* frac 10) d) (* divisor 10))))))))

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

;; ---- Rounding ----

(define (ceiling x)
  (if (integer? x) x (+ (floor x) 1)))

(define (round x)
  (let ((f (floor x)))
    (let ((diff (- x f)))
      (cond
       ((< diff 0.5) f)
       ((> diff 0.5) (+ f 1))
       ((even? f) f)
       (else (+ f 1))))))

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

;; ---- Vector/list conversions ----

(define (vector->list vec)
  (let loop ((i (- (vector-length vec) 1)) (acc '()))
    (if (< i 0) acc
        (loop (- i 1) (cons (vector-ref vec i) acc)))))

(define (list->vector lst)
  (let* ((len (length lst))
         (vec (make-vector len)))
    (let loop ((i 0) (rest lst))
      (if (= i len) vec
          (begin (vector-set! vec i (car rest))
                 (loop (+ i 1) (cdr rest)))))))

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
  (if (and (symbol? bindings) (not (null? bindings)))
      ;; Named let: (let name ((var init) ...) body...)
      ;; Inits evaluate outside letrec scope so the name doesn't shadow
      ;; outer bindings (e.g., (let - ((n (- 1))) n) → n = -1).
      `((letrec ((,bindings (lambda ,(map car (car body)) ,@(cdr body))))
          ,bindings)
        ,@(map cadr (car body)))
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
  (define (zip-sets vs ts)
    (if (null? vs) '()
        (cons (list 'set! (car vs) (car ts))
              (zip-sets (cdr vs) (cdr ts)))))
  (let ((vars (map car bindings))
        (inits (map cadr bindings))
        (tmps (map (lambda (b) (gensym)) bindings)))
    `(let ,(map (lambda (v) (list v '())) vars)
       ((lambda ,tmps ,@(zip-sets vars tmps) ,@body)
        ,@inits))))

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

;; R7RS current ports as parameter objects. Initial values wrap the
;; host's standard output/input streams (captured once at boot).
;; parameterize rebinds these for dynamic-extent output capture.
(define current-output-port (make-parameter (%initial-output-port)))
(define current-input-port  (make-parameter (%initial-input-port)))

;; R7RS write procedures: optional port defaults to current-output-port.
;; The low-level primitives require an explicit port with no fallback.
(define (display obj . port)
  (%display-to-port obj (if (null? port) (current-output-port) (car port))))

(define (write obj . port)
  (%write-to-port obj (if (null? port) (current-output-port) (car port))))

(define (newline . port)
  (%newline-to-port (if (null? port) (current-output-port) (car port))))

(define (write-char ch . port)
  (%write-char-to-port ch (if (null? port) (current-output-port) (car port))))

(define (write-string str . port)
  (%write-string-to-port str (if (null? port) (current-output-port) (car port))))

;; R7RS read procedures: optional port defaults to current-input-port.
;; We capture the original primitive, then shadow the name with a wrapper.
(define %raw-read-char read-char)
(define (read-char . port)
  (if (null? port)
      (%raw-read-char (current-input-port))
      (%raw-read-char (car port))))

(define %raw-peek-char peek-char)
(define (peek-char . port)
  (if (null? port)
      (%raw-peek-char (current-input-port))
      (%raw-peek-char (car port))))

(define %raw-read-line read-line)
(define (read-line . port)
  (if (null? port)
      (%raw-read-line (current-input-port))
      (%raw-read-line (car port))))

(define %raw-char-ready? char-ready?)
(define (char-ready? . port)
  (if (null? port)
      (%raw-char-ready? (current-input-port))
      (%raw-char-ready? (car port))))

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

;; ---- Character predicates ----
;; Implemented in ECE via char->integer range checks.

(define (char-whitespace? ch)
  (let ((code (char->integer ch)))
    (or (= code 32) (= code 9) (= code 10) (= code 13))))

(define (char-alphabetic? ch)
  (let ((code (char->integer ch)))
    (or (and (>= code 65) (<= code 90))
        (and (>= code 97) (<= code 122)))))

(define (char-numeric? ch)
  (let ((code (char->integer ch)))
    (and (>= code 48) (<= code 57))))

(define (char=? a b) (= (char->integer a) (char->integer b)))
(define (char<? a b) (< (char->integer a) (char->integer b)))

;; ---- Equality ----

(define (eqv? x y)
  (cond
   ((eq? x y) #t)
   ((and (number? x) (number? y)) (= x y))
   (else #f)))

(define (equal? x y)
  (cond
   ((eq? x y) #t)
   ((and (pair? x) (pair? y))
    (and (equal? (car x) (car y))
         (equal? (cdr x) (cdr y))))
   ((and (vector? x) (vector? y))
    (and (= (vector-length x) (vector-length y))
         (let loop ((i 0))
           (or (= i (vector-length x))
               (and (equal? (vector-ref x i) (vector-ref y i))
                    (loop (+ i 1)))))))
   ((and (string? x) (string? y)) (string=? x y))
   ((and (number? x) (number? y)) (= x y))
   (else #f)))

;; ---- Gensym ----

(define %gensym-counter 0)
(define (gensym)
  (set! %gensym-counter (+ %gensym-counter 1))
  (string->symbol (string-append "g" (number->string %gensym-counter))))

;; ---- String operations ----
;; Implemented in ECE using core string primitives.

(define (string=? a b)
  (and (= (string-length a) (string-length b))
       (let loop ((i 0))
         (or (= i (string-length a))
             (and (char=? (string-ref a i) (string-ref b i))
                  (loop (+ i 1)))))))

(define (string<? a b)
  (let ((la (string-length a)) (lb (string-length b)))
    (let loop ((i 0))
      (cond
       ((= i la) (< la lb))
       ((= i lb) #f)
       ((char<? (string-ref a i) (string-ref b i)) #t)
       ((char<? (string-ref b i) (string-ref a i)) #f)
       (else (loop (+ i 1)))))))

(define (string>? a b) (string<? b a))

(define (string-downcase s)
  (let* ((len (string-length s))
         (result (make-vector len #\space)))
    (let loop ((i 0))
      (if (>= i len)
          (let build ((j 0) (acc ""))
            (if (>= j len) acc
                (build (+ j 1) (string-append acc (string (vector-ref result j))))))
          (let* ((ch (string-ref s i))
                 (code (char->integer ch)))
            (vector-set! result i
                         (if (and (>= code 65) (<= code 90))
                             (integer->char (+ code 32))
                             ch))
            (loop (+ i 1)))))))

(define (string-upcase s)
  (let* ((len (string-length s))
         (result (make-vector len #\space)))
    (let loop ((i 0))
      (if (>= i len)
          (let build ((j 0) (acc ""))
            (if (>= j len) acc
                (build (+ j 1) (string-append acc (string (vector-ref result j))))))
          (let* ((ch (string-ref s i))
                 (code (char->integer ch)))
            (vector-set! result i
                         (if (and (>= code 97) (<= code 122))
                             (integer->char (- code 32))
                             ch))
            (loop (+ i 1)))))))

(define (string-trim s)
  (let ((len (string-length s)))
    (let find-start ((i 0))
      (cond
       ((>= i len) "")
       ((char-whitespace? (string-ref s i)) (find-start (+ i 1)))
       (else
        (let find-end ((j (- len 1)))
          (cond
           ((char-whitespace? (string-ref s j)) (find-end (- j 1)))
           (else (substring s i (+ j 1))))))))))

(define (string-contains? s sub)
  (let ((slen (string-length s))
        (sublen (string-length sub)))
    (if (= sublen 0) #t
        (let loop ((i 0))
          (cond
           ((> (+ i sublen) slen) #f)
           ((string=? (substring s i (+ i sublen)) sub) #t)
           (else (loop (+ i 1))))))))

(define (string-split s . rest)
  (let* ((delim (if (null? rest) " "
                    (if (char? (car rest)) (string (car rest)) (car rest))))
         (slen (string-length s))
         (dlen (string-length delim)))
    (if (= dlen 0) (list s)
        (let loop ((i 0) (start 0) (acc '()))
          (cond
           ((> (+ i dlen) slen)
            (reverse (cons (substring s start slen) acc)))
           ((string=? (substring s i (+ i dlen)) delim)
            (loop (+ i dlen) (+ i dlen)
                  (cons (substring s start i) acc)))
           (else (loop (+ i 1) start acc)))))))

(define (string-join lst sep)
  (if (null? lst) ""
      (let loop ((rest (cdr lst)) (acc (car lst)))
        (if (null? rest) acc
            (loop (cdr rest)
                  (string-append acc sep (car rest)))))))

(define (print x)
  (display x)
  (newline))

;; R7RS file port convenience functions
(define (call-with-input-file filename proc)
  (let ((port (open-input-file filename)))
    (let ((result (proc port)))
      (close-input-port port)
      result)))

(define (call-with-output-file filename proc)
  (let ((port (open-output-file filename)))
    (let ((result (proc port)))
      (close-output-port port)
      result)))

;; R7RS with-*-file: open file, rebind current-*-port via parameterize,
;; run thunk, close port. Built on the ECE parameter so that calls to
;; (read-char), (display ...), etc. inside the thunk honor the rebinding.
(define (with-input-from-file filename thunk)
  (let ((port (open-input-file filename)))
    (let ((result (parameterize ((current-input-port port)) (thunk))))
      (close-input-port port)
      result)))

(define (with-output-to-file filename thunk)
  (let ((port (open-output-file filename)))
    (let ((result (parameterize ((current-output-port port)) (thunk))))
      (close-output-port port)
      result)))

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
;; Winding is handled at invoke time by the executor's do-continuation-winds
;; operation (in the compiler's continuation branch). No wrapper lambda needed.
;; call/cc is a first-class procedure (R7RS), not a macro.

(define (call/cc receiver)
  (%raw-call/cc receiver))

(define call-with-current-continuation call/cc)

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

;; parameterize: dynamic rebinding of parameter objects (R7RS / SRFI-39).
;; Uses dynamic-wind so that non-local exits (raise, continuation escape,
;; unhandled errors) restore the parameter to its prior value.
(define-macro (parameterize bindings . body)
  (if (null? bindings)
      `(begin ,@body)
      (let ((param (car (car bindings)))
            (val (cadr (car bindings)))
            (rest (cdr bindings)))
        (let ((old (gensym)) (new (gensym)))
          `(let ((,old (,param)))
             ;; Apply converter once by round-tripping through the parameter.
             (,param ,val)
             (let ((,new (,param)))
               (,param ,old #t)
               (dynamic-wind
                   (lambda () (,param ,new #t))
                   (lambda () (parameterize ,rest ,@body))
                   (lambda () (,param ,old #t)))))))))

;; ---- Output/input capture macros (R7RS) ----

;; Rebinds current-output-port to a fresh string port for the body,
;; then returns the accumulated string.
(define-macro (with-output-to-string . body)
  (let ((p (gensym)))
    `(let ((,p (open-output-string)))
       (parameterize ((current-output-port ,p)) ,@body)
       (get-output-string ,p))))

;; Rebinds current-input-port to a fresh input port over STR
;; for the dynamic extent of the body.
(define-macro (with-input-from-string str . body)
  (let ((p (gensym)))
    `(let ((,p (open-input-string ,str)))
       (parameterize ((current-input-port ,p)) ,@body))))

;; Rebinds current-output-port to a caller-supplied port for the body.
(define-macro (with-output-to-port port . body)
  `(parameterize ((current-output-port ,port)) ,@body))

;; Rebinds current-input-port to a caller-supplied port for the body.
(define-macro (with-input-from-port port . body)
  `(parameterize ((current-input-port ,port)) ,@body))

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
             ;; Compiled procedure — scan env
             ((compiled-procedure? obj) (scan (compiled-procedure-env obj)))
             ;; Continuation — scan stack, conts, and winds
             ((continuation? obj)
              (scan (continuation-stack obj))
              (scan (continuation-conts obj))
              (scan (continuation-winds obj)))
             ;; Primitive — no sub-structure to scan
             ((primitive? obj) '())
             ;; Env frame (WASM GC struct — not a vector, so needs its own branch)
             ((%env-frame? obj)
              (for-each scan (%env-frame-vals obj)))
             ;; Pair/list
             ((pair? obj) (scan (car obj)) (scan (cdr obj)))
             ;; Other compound
             (else '())))))))

  (scan value)

  ;; Pass 2: serialize to a string output port (O(n) — each token written once).
  (define next-id 0)
  (define refs (%eq-hash-table))  ;; obj -> assigned ref ID (only for shared)
  (define port (open-output-string))

  (define (emit str) (display str port))

  (define (ser obj)
    (cond
     ;; nil
     ((null? obj) (emit "()"))
     ;; booleans
     ((eq? obj #t) (emit "#t"))
     ((eq? obj #f) (emit "#f"))
     ;; numbers
     ((number? obj) (emit (write-to-string-flat obj)))
     ;; characters
     ((char? obj) (emit (write-to-string-flat obj)))
     ;; strings — use write-to-string-flat for proper escaping
     ((string? obj) (emit (write-to-string-flat obj)))
     ;; symbols — use symbol->string for case-preserving output
     ((symbol? obj) (emit (symbol->string obj)))
     ;; compound: check for shared structure
     (else
      (define existing-ref (%eq-hash-ref refs obj))
      (if existing-ref
          ;; Already emitted — back-reference
          (begin (emit "(%ser/ref ")
                 (emit (write-to-string-flat existing-ref))
                 (emit ")"))
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
            (if id
                (begin (emit "(%ser/def ")
                       (emit (write-to-string-flat id))
                       (emit " ")
                       (ser-compound obj)
                       (emit ")"))
                (ser-compound obj)))))))

  (define (ser-compound obj)
    (cond
     ;; Global env frame sentinel
     ((eq? obj global-frame) (emit "(%ser/global-env)"))
     ;; Hash frame sentinel — shouldn't normally be serialized directly
     ((%hash-frame? obj) (emit "(%ser/hash-frame)"))
     ;; Hash table (:hash-table count . root)
     ((and (pair? obj) (eq? (car obj) :hash-table))
      (define entries (map (lambda (k) (cons k (hash-ref obj k))) (hash-keys obj)))
      (emit "(%ser/hash-table")
      (for-each (lambda (kv)
                  (emit " (") (ser (car kv)) (emit " ") (ser (cdr kv)) (emit ")"))
                entries)
      (emit ")"))
     ;; Parameter
     ((and (pair? obj) (eq? (car obj) 'parameter))
      (define cell (cadr obj))
      (emit "(%ser/parameter ") (ser (car cell)) (emit " ") (ser (cdr cell)) (emit ")"))
     ;; Compiled procedure (WasmGC struct or CL tagged pair)
     ((compiled-procedure? obj)
      (define entry (compiled-procedure-entry obj))
      (define env (compiled-procedure-env obj))
      (emit "(%ser/compiled-procedure") (ser-entry entry) (emit " ") (ser env) (emit ")"))
     ;; Continuation (WasmGC struct or CL tagged pair)
     ((continuation? obj)
      (define stack (continuation-stack obj))
      (define cont (continuation-conts obj))
      (define winds (continuation-winds obj))
      (emit "(%ser/continuation") (ser stack) (emit " ") (ser-entry cont) (emit " ") (ser winds) (emit ")"))
     ;; Primitive (WasmGC struct or CL tagged pair)
     ((primitive? obj)
      (define id (%primitive-id-of obj))
      (define name (%primitive-name id))
      (emit "(%ser/primitive ")
      (if name (emit (symbol->string name)) (emit (number->string id)))
      (emit ")"))
     ;; Vector
     ((vector? obj)
      (define len (vector-length obj))
      (emit "(%ser/vector")
      (define (vec-items i)
        (when (< i len) (emit " ") (ser (vector-ref obj i)) (vec-items (+ i 1))))
      (vec-items 0)
      (emit ")"))
     ;; Env frame (WASM GC struct — not a vector, so needs its own branch)
     ((%env-frame? obj)
      (define vals (%env-frame-vals obj))
      (emit "(%ser/env-frame () ")
      (ser vals) (emit " #f)"))
     ;; Regular pair/list
     ((pair? obj) (ser-pair obj))
     ;; Fallback
     (else (emit (write-to-string-flat obj)))))

  (define (ser-entry entry)
    "Serialize a space-qualified entry address or bare integer."
    (if (pair? entry)
        (begin (emit "(") (emit (write-to-string-flat (car entry)))
               (emit " . ") (emit (write-to-string-flat (cdr entry))) (emit ")"))
        (emit (write-to-string-flat entry))))

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
        (begin
          (emit "(")
          (let loop ((xs obj) (first #t))
            (when (not (null? xs))
              (when (not first) (emit " "))
              (ser (car xs))
              (loop (cdr xs) #f)))
          (emit ")"))
        ;; Dotted pair
        (begin (emit "(") (ser (car obj)) (emit " . ") (ser (cdr obj)) (emit ")"))))

  ;; Run serialization and extract result
  (ser value)
  (get-output-string port))

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
        (define body (caddr form))
        ;; Pre-allocate-and-patch for pair bodies to support cyclic structures.
        ;; A cons placeholder is stored in ref-table BEFORE recursing, so
        ;; %ser/ref back-references resolve during cycle deserialization.
        ;; After deser, if the result is a pair (compiled-procedure, continuation,
        ;; env pair), patch the placeholder. If non-pair (vector, hash-table),
        ;; replace in ref-table directly (non-pair types don't form cycles).
        (if (pair? body)
            (let ((placeholder (cons #f #f)))
              (%eq-hash-set! ref-table id placeholder)
              (let ((result (deser body)))
                (if (pair? result)
                    (begin (set-car! placeholder (car result))
                           (set-cdr! placeholder (cdr result))
                           placeholder)
                    ;; Non-pair result (vector, etc.) — no cycle through this
                    (begin (%eq-hash-set! ref-table id result)
                           result))))
            ;; Non-pair body (atom) — direct deser, no cycles possible
            (let ((val (deser body)))
              (%eq-hash-set! ref-table id val)
              val)))
       ;; Global env sentinel
       ((string=? tag "%ser/global-env")
        (%global-env-frame))
       ;; Hash frame sentinel
       ((string=? tag "%ser/hash-frame")
        (%global-env-frame))  ;; best approximation
       ;; Env frame
       ((string=? tag "%ser/env-frame")
        (define names (deser (cadr form)))
        (define vals (deser (caddr form)))
        (define enc (deser (car (cdr (cdr (cdr form))))))
        (%make-env-frame names vals (if (or (null? enc) (eq? enc #f)) '() enc)))
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
        (%make-compiled-procedure entry env))
       ;; Continuation
       ((string=? tag "%ser/continuation")
        (define stack (deser (cadr form)))
        (define cont (caddr form))
        (define winds (if (null? (cdddr form)) '() (deser (car (cdddr form)))))
        (%make-continuation stack cont winds))
       ;; Primitive by name or numeric ID
       ((string=? tag "%ser/primitive")
        (define name-or-id (cadr form))
        (define id (if (number? name-or-id)
                       name-or-id
                       (%primitive-id name-or-id)))
        (%make-primitive (if id id 0)))
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
        ;; Force left-to-right: process car before cdr so %ser/def
        ;; stores into ref-table before %ser/ref reads from it.
        (let ((a (deser (car form))))
          (cons a (deser (cdr form))))
        (deser form)))

  (deser form))

(define (serialize! obj port)
  "Serialize OBJ to PORT in a form that deserialize can reconstruct.
Handles all ECE types including continuations, compiled procedures,
env-frames, and shared structure."
  (display (serialize-value obj) port)
  (newline port))

(define (deserialize port)
  "Read and reconstruct a value from PORT (written by serialize!)."
  (deserialize-value (ece-scheme-read port)))

;; ---- File-based save/load (R7RS style) ----

(define (save filename obj)
  "Serialize OBJ to FILENAME. The file can be restored with load-saved."
  (call-with-output-file filename
    (lambda (port) (serialize! obj port))))

(define (load-saved filename)
  "Deserialize and return the value saved to FILENAME by save."
  (call-with-input-file filename
    (lambda (port) (deserialize port))))

(define (save-continuation! filename)
  "Capture the current continuation and save it to FILENAME.
Returns #t on the initial save, and the restored value on reload.
Usage: (if (save-continuation! \"save.dat\") 'saved 'restored)"
  (call/cc
   (lambda (k)
     (save filename k)
     #t)))
