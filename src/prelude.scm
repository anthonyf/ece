;;; ECE Standard Prelude
;;; Pure ECE definitions loaded automatically at system initialization.

;; Higher-order functions
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

;; fmt: concatenate args as strings
(define (fmt . args)
  (apply string-append
         (map (lambda (a) (if (string? a) a (write-to-string a))) args)))

;; print-text: display formatted text
(define (print-text . args)
  (display (apply fmt args)))

;; lines: join arguments with newlines, returns a string
(define (lines . args)
  (if (null? args)
      ""
      (apply string-append
             (map (lambda (a)
                    (string-append (if (string? a) a (write-to-string a)) "\n"))
                  args))))

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

;; assert macro: signal error if condition is falsy
(define-macro (assert expr . rest)
  (if (null? rest)
      `(if (not ,expr) (error "Assertion failed") ())
      `(if (not ,expr) (error ,(car rest)) ())))
