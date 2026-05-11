;;; syntax-rules.scm — R7RS hygienic pattern-matching macros for ECE
;;;
;;; Implements syntax-rules and define-syntax on top of define-macro.
;;; Provides gensym-based hygiene for introduced bindings.

;;; --- Utility helpers ---

(define (syntax-take lst n)
  (if (= n 0) '()
      (cons (car lst) (syntax-take (cdr lst) (- n 1)))))

(define (syntax-drop lst n)
  (if (= n 0) lst
      (syntax-drop (cdr lst) (- n 1))))

(define (syntax-unique lst)
  (if (null? lst) '()
      (if (member (car lst) (cdr lst))
          (syntax-unique (cdr lst))
          (cons (car lst) (syntax-unique (cdr lst))))))

;;; --- Match results ---
;;; A match-result is (regular-bindings . ellipsis-bindings)
;;; regular-bindings: ((name . value) ...)
;;; ellipsis-bindings: ((name . (val1 val2 ...)) ...)

(define (make-match-result regular ellipsis)
  (cons regular ellipsis))

(define (match-regular mr) (car mr))
(define (match-ellipsis mr) (cdr mr))

(define (empty-match) (cons '() '()))

(define (merge-matches a b)
  (if (or (not a) (not b)) #f
      (cons (append (car a) (car b))
            (append (cdr a) (cdr b)))))

;;; --- Pattern variable collection ---

(define (syntax-pattern-vars pattern literals)
  (cond
   ((eq? pattern '_) '())
   ((eq? pattern '...) '())
   ((and (symbol? pattern) (member pattern literals)) '())
   ((symbol? pattern) (list pattern))
   ((pair? pattern)
    (if (and (pair? (cdr pattern)) (eq? (cadr pattern) '...))
        (append (syntax-pattern-vars (car pattern) literals)
                (syntax-pattern-vars (cddr pattern) literals))
        (append (syntax-pattern-vars (car pattern) literals)
                (syntax-pattern-vars (cdr pattern) literals))))
   (else '())))

;;; --- Pattern matching ---

(define (syntax-match pattern expr literals)
  (cond
   ((eq? pattern '_) (empty-match))
   ((and (symbol? pattern) (member pattern literals))
    (if (eq? pattern expr) (empty-match) #f))
   ((symbol? pattern)
    (make-match-result (list (cons pattern expr)) '()))
   ((and (pair? pattern) (pair? expr))
    (syntax-match-list pattern expr literals))
   (else (if (equal? pattern expr) (empty-match) #f))))

(define (syntax-match-list pattern expr literals)
  (cond
   ((null? pattern)
    (if (null? expr) (empty-match) #f))
   ;; Dotted pair tail — pattern is a symbol, matches remaining expr
   ((not (pair? pattern))
    (syntax-match pattern expr literals))
   ;; Ellipsis: (pat ... rest-patterns...)
   ((and (pair? (cdr pattern)) (eq? (cadr pattern) '...))
    (let ((ellipsis-pat (car pattern))
          (rest-pattern (cddr pattern)))
      (if (null? rest-pattern)
          ;; Ellipsis consumes all remaining
          (syntax-match-ellipsis ellipsis-pat expr literals)
          ;; Ellipsis with trailing fixed elements
          (let ((n-trailing (length rest-pattern))
                (n-expr (if (pair? expr) (length expr) 0)))
            (let ((n-ellipsis (- n-expr n-trailing)))
              (if (< n-ellipsis 0)
                  #f
                  (merge-matches
                   (syntax-match-ellipsis ellipsis-pat
                                          (syntax-take expr n-ellipsis)
                                          literals)
                   (syntax-match-list rest-pattern
                                      (syntax-drop expr n-ellipsis)
                                      literals))))))))
   ;; Regular element
   (else
    (if (not (pair? expr))
        #f
        (merge-matches
         (syntax-match (car pattern) (car expr) literals)
         (syntax-match-list (cdr pattern) (cdr expr) literals))))))

(define (syntax-match-ellipsis pattern elts literals)
  (if (symbol? pattern)
      (cond
       ((eq? pattern '_) (empty-match))
       ((member pattern literals)
        (if (every (lambda (e) (eq? e pattern)) elts)
            (empty-match)
            #f))
       (else
        (make-match-result '() (list (cons pattern elts)))))
      ;; Sub-pattern: match each element and transpose
      (if (null? elts)
          ;; Zero matches: empty ellipsis bindings for all vars
          (let ((vars (syntax-pattern-vars pattern literals)))
            (make-match-result '()
                               (map (lambda (v) (cons v '())) vars)))
          (let ((results (map (lambda (e) (syntax-match pattern e literals))
                              elts)))
            (if (any not results)
                #f
                (syntax-transpose-matches results pattern literals))))))

(define (syntax-transpose-matches results pattern literals)
  (let ((var-names (syntax-pattern-vars pattern literals)))
    (make-match-result
     '()
     (map (lambda (var)
            (cons var
                  (map (lambda (r)
                         (let ((entry (assoc var (match-regular r))))
                           (if entry
                               (cdr entry)
                               (let ((e-entry (assoc var (match-ellipsis r))))
                                 (if e-entry
                                     (cdr e-entry)
                                     (error (string-append
                                             "syntax-rules: internal error transposing "
                                             (write-to-string var))))))))
                       results)))
          var-names))))

;;; --- Hygiene ---
;;; Find symbols introduced by a template in binding positions
;;; (let, let*, lambda, define) that are not pattern variables.

(define (syntax-find-introduced template pattern-vars)
  (syntax-unique (syntax-scan-introduced template pattern-vars)))

(define (syntax-scan-introduced tmpl pattern-vars)
  (if (not (pair? tmpl))
      '()
      (cond
       ;; (let ((var expr) ...) body ...) or (let name ((var expr) ...) body ...)
       ((eq? (car tmpl) 'let)
        (if (pair? (cdr tmpl))
            (if (symbol? (cadr tmpl))
                ;; Named let
                (if (and (pair? (cddr tmpl)) (pair? (car (cddr tmpl))))
                    (append
                     (syntax-bindings-introduced (car (cddr tmpl)) pattern-vars)
                     (syntax-scan-list (cdr (cddr tmpl)) pattern-vars))
                    '())
                ;; Regular let
                (if (pair? (cadr tmpl))
                    (append
                     (syntax-bindings-introduced (cadr tmpl) pattern-vars)
                     (syntax-scan-list (cddr tmpl) pattern-vars))
                    '()))
            '()))
       ;; (let* ((var expr) ...) body ...)
       ((eq? (car tmpl) 'let*)
        (if (and (pair? (cdr tmpl)) (pair? (cadr tmpl)))
            (append
             (syntax-bindings-introduced (cadr tmpl) pattern-vars)
             (syntax-scan-list (cddr tmpl) pattern-vars))
            '()))
       ;; (lambda params body ...)
       ((eq? (car tmpl) 'lambda)
        (if (pair? (cdr tmpl))
            (append
             (syntax-params-introduced (cadr tmpl) pattern-vars)
             (syntax-scan-list (cddr tmpl) pattern-vars))
            '()))
       ;; (define var expr) or (define (name params...) body ...)
       ((eq? (car tmpl) 'define)
        (if (pair? (cdr tmpl))
            (append
             (cond
              ((symbol? (cadr tmpl))
               (if (member (cadr tmpl) pattern-vars) '()
                   (list (cadr tmpl))))
              ((pair? (cadr tmpl))
               (append
                (if (and (symbol? (car (cadr tmpl)))
                         (not (member (car (cadr tmpl)) pattern-vars)))
                    (list (car (cadr tmpl)))
                    '())
                (syntax-params-introduced (cdr (cadr tmpl)) pattern-vars)))
              (else '()))
             (syntax-scan-list (cddr tmpl) pattern-vars))
            '()))
       ;; (let-syntax ((name transformer) ...) body ...) and letrec-syntax
       ((or (eq? (car tmpl) 'let-syntax)
            (eq? (car tmpl) 'letrec-syntax))
        (if (and (pair? (cdr tmpl)) (pair? (cadr tmpl)))
            (append
             (syntax-bindings-introduced (cadr tmpl) pattern-vars)
             (syntax-scan-list (cddr tmpl) pattern-vars))
            '()))
       ;; Other forms: recurse into car and cdr
       (else
        (append (syntax-scan-introduced (car tmpl) pattern-vars)
                (syntax-scan-introduced (cdr tmpl) pattern-vars))))))

(define (syntax-scan-list forms pattern-vars)
  (if (not (pair? forms)) '()
      (append (syntax-scan-introduced (car forms) pattern-vars)
              (syntax-scan-list (cdr forms) pattern-vars))))

(define (syntax-bindings-introduced bindings pattern-vars)
  (if (not (pair? bindings)) '()
      (append
       (if (and (pair? (car bindings))
                (symbol? (car (car bindings)))
                (not (member (car (car bindings)) pattern-vars)))
           (list (car (car bindings)))
           '())
       (syntax-bindings-introduced (cdr bindings) pattern-vars))))

(define (syntax-params-introduced params pattern-vars)
  (cond
   ((null? params) '())
   ((symbol? params)
    (if (member params pattern-vars) '() (list params)))
   ((pair? params)
    (append
     (if (and (symbol? (car params))
              (not (member (car params) pattern-vars)))
         (list (car params))
         '())
     (syntax-params-introduced (cdr params) pattern-vars)))
   (else '())))

;;; --- Template instantiation ---

(define (syntax-template-vars template pattern-vars)
  (cond
   ((and (symbol? template) (member template pattern-vars))
    (list template))
   ((pair? template)
    (if (and (pair? (cdr template)) (eq? (cadr template) '...))
        (append (syntax-template-vars (car template) pattern-vars)
                (syntax-template-vars (cddr template) pattern-vars))
        (append (syntax-template-vars (car template) pattern-vars)
                (syntax-template-vars (cdr template) pattern-vars))))
   (else '())))

(define (syntax-instantiate template mr pattern-vars rename-table)
  (cond
   ;; Symbol: substitute pattern var, rename introduced, or leave as-is
   ((symbol? template)
    (let ((regular-entry (assoc template (match-regular mr))))
      (if regular-entry
          (cdr regular-entry)
          (let ((rename-entry (assoc template rename-table)))
            (if rename-entry
                (cdr rename-entry)
                template)))))
   ;; Ellipsis: (elt-template ... rest...)
   ((and (pair? template)
         (pair? (cdr template))
         (eq? (cadr template) '...))
    (append
     (syntax-instantiate-ellipsis (car template) mr pattern-vars rename-table)
     (syntax-instantiate (cddr template) mr pattern-vars rename-table)))
   ;; %global-ref: pass through without recursing
   ((and (pair? template) (eq? (car template) '%global-ref))
    template)
   ;; Quasiquote: don't wrap inside (it's data), except inside unquote (code)
   ((and (pair? template) (eq? (car template) 'quasiquote))
    (list 'quasiquote
          (syntax-instantiate-qq (cadr template) mr pattern-vars rename-table)))
   ;; Nested syntax-rules: skip patterns, only process templates
   ((and (pair? template) (eq? (car template) 'syntax-rules))
    (syntax-instantiate-nested-syntax-rules template mr pattern-vars rename-table))
   ;; Regular pair (form): wrap free symbols in operator position only
   ((pair? template)
    (cons (syntax-instantiate-operator (car template) mr pattern-vars rename-table)
          (syntax-instantiate-args (cdr template) mr pattern-vars rename-table)))
   ;; Atom
   (else template)))

;; Process operator position — wrap free symbols in %global-ref for hygiene
(define (syntax-instantiate-operator expr mr pattern-vars rename-table)
  (cond
   ((mc-self-evaluating? expr) expr)  ;; #t, #f, numbers — don't wrap
   ((symbol? expr)
    (let ((regular-entry (assoc expr (match-regular mr))))
      (if regular-entry
          (cdr regular-entry)
          (let ((rename-entry (assoc expr rename-table)))
            (if rename-entry
                (cdr rename-entry)
                ;; Free symbol in operator position: wrap unless keyword/macro
                (if (or (member expr *mc-special-forms*)
                        (get-macro expr))
                    expr
                    (list '%global-ref expr)))))))
   ;; Non-symbol operator (e.g., (lambda ...) in ((lambda ...) args))
   (else (syntax-instantiate expr mr pattern-vars rename-table))))

;; Process argument list — each element is an expression, recurse without
;; wrapping the CDR CARs (they're arguments, not operators)
(define (syntax-instantiate-args args mr pattern-vars rename-table)
  (cond
   ((null? args) '())
   ;; Ellipsis: (elt ... rest...)
   ((and (pair? args) (pair? (cdr args)) (eq? (cadr args) '...))
    (append
     (syntax-instantiate-ellipsis (car args) mr pattern-vars rename-table)
     (syntax-instantiate-args (cddr args) mr pattern-vars rename-table)))
   ((pair? args)
    (cons (syntax-instantiate (car args) mr pattern-vars rename-table)
          (syntax-instantiate-args (cdr args) mr pattern-vars rename-table)))
   ;; Dotted pair rest or bare symbol
   (else (syntax-instantiate args mr pattern-vars rename-table))))

(define (syntax-instantiate-ellipsis elt-template mr pattern-vars rename-table)
  (let ((used-vars
         (filter (lambda (v) (assoc v (match-ellipsis mr)))
                 (syntax-template-vars elt-template pattern-vars))))
    (if (null? used-vars)
        '()
        (let ((n (length (cdr (assoc (car used-vars) (match-ellipsis mr))))))
          (let loop ((i 0) (result '()))
            (if (= i n)
                (reverse result)
                (let ((adjusted-mr
                       (make-match-result
                        (append
                         (match-regular mr)
                         (map (lambda (v)
                                (cons v (list-ref
                                         (cdr (assoc v (match-ellipsis mr)))
                                         i)))
                              used-vars))
                        (match-ellipsis mr))))
                  (loop (+ i 1)
                        (cons (syntax-instantiate elt-template adjusted-mr
                                                  pattern-vars rename-table)
                              result)))))))))

(define (syntax-instantiate-nested-syntax-rules form mr pattern-vars rename-table)
  ;; form = (syntax-rules (literals...) clause ...)
  ;; clause = (pattern template)
  ;; Patterns are match structures — leave unchanged.
  ;; Templates contain code — process for substitution and hygiene.
  (let ((literals (cadr form))
        (clauses (cddr form)))
    (cons 'syntax-rules
          (cons literals
                (syntax-instantiate-sr-clauses clauses mr pattern-vars rename-table)))))

(define (syntax-instantiate-sr-clauses clauses mr pattern-vars rename-table)
  (if (null? clauses)
      '()
      (cons (list (caar clauses)
                  (syntax-instantiate (cadr (car clauses)) mr pattern-vars rename-table))
            (syntax-instantiate-sr-clauses (cdr clauses) mr pattern-vars rename-table))))

;; Process inside quasiquote — substitute and rename but don't wrap operators.
;; Unquote/unquote-splicing switch back to normal mode (they contain code).
(define (syntax-instantiate-qq template mr pattern-vars rename-table)
  (cond
   ((symbol? template)
    (let ((regular-entry (assoc template (match-regular mr))))
      (if regular-entry
          (cdr regular-entry)
          (let ((rename-entry (assoc template rename-table)))
            (if rename-entry
                (cdr rename-entry)
                template)))))
   ;; Unquote: back to normal mode (code context)
   ((and (pair? template) (eq? (car template) 'unquote))
    (list 'unquote
          (syntax-instantiate (cadr template) mr pattern-vars rename-table)))
   ;; Unquote-splicing: back to normal mode
   ((and (pair? template) (eq? (car template) 'unquote-splicing))
    (list 'unquote-splicing
          (syntax-instantiate (cadr template) mr pattern-vars rename-table)))
   ;; Nested quasiquote: stay in qq mode
   ((and (pair? template) (eq? (car template) 'quasiquote))
    (list 'quasiquote
          (syntax-instantiate-qq (cadr template) mr pattern-vars rename-table)))
   ;; Regular pair: recurse in qq mode (no wrapping)
   ((pair? template)
    (cons (syntax-instantiate-qq (car template) mr pattern-vars rename-table)
          (syntax-instantiate-qq (cdr template) mr pattern-vars rename-table)))
   (else template)))

;;; --- Main expander ---

(define (syntax-rules-expand literals clauses form)
  (let try-clauses ((cls clauses))
    (if (null? cls)
        (error (string-append "syntax-rules: no matching clause for "
                              (write-to-string form)))
        (let ((pattern (car (car cls)))
              (template (cadr (car cls))))
          (let ((mr (syntax-match pattern form literals)))
            (if mr
                (let ((pattern-vars (syntax-pattern-vars pattern literals)))
                  (let ((introduced (syntax-find-introduced template pattern-vars)))
                    (let ((rename-table
                           (map (lambda (s) (cons s (gensym)))
                                introduced)))
                      (syntax-instantiate template mr pattern-vars rename-table))))
                (try-clauses (cdr cls))))))))

;;; --- define-syntax ---

(define-macro (define-syntax name transformer-expr)
  (if (and (pair? transformer-expr)
           (eq? (car transformer-expr) 'syntax-rules))
      (let ((literals (cadr transformer-expr))
            (clauses (cddr transformer-expr)))
        `(define-macro (,name . %syntax-args)
           (syntax-rules-expand ',literals
                                ',clauses
                                (cons ',name %syntax-args))))
      (error "define-syntax: only syntax-rules transformers are supported")))

(define-macro (define-syntax/doc name doc transformer-expr)
  `(begin
     (define-syntax ,name ,transformer-expr)
     (set-documentation! ',name 'syntax ,doc :signature ',name)
     ',name))
