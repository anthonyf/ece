;;; geiser-ece.scm — Scheme-side support for the Geiser emacs backend.
;;;
;;; The Geiser protocol is handled in two layers:
;;;
;;; 1. REPL layer (ece-main.scm): In --geiser mode, the REPL captures
;;;    current-output-port to a string during evaluation, formats the
;;;    result as a chibi-style alist `((result "...") (output . "..."))`,
;;;    and writes it via write-to-string-flat. This is the wire protocol.
;;;
;;; 2. Helper layer (this file): provides `geiser-no-values` and the
;;;    completions handler. Eval and load-file are handled inline by the
;;;    REPL's --geiser mode (see %geiser-eval-and-respond in ece-main.scm).
;;;
;;; The elisp side (`emacs/geiser-ece.el`) formats `C-x C-e` as a raw
;;; expression (not wrapped in `(geiser:eval ...)`), and `C-c C-l` as
;;; `(load "/abs/path.scm")` directly. Using hyphen names (not colons)
;;; because ECE's reader doesn't handle CL pipe-escape syntax, which
;;; compile-file-to-port emits for colon-containing symbols.

(define (geiser-no-values) #f)

(define (string-prefix? prefix str)
  (let ((plen (string-length prefix))
        (slen (string-length str)))
    (and (<= plen slen)
         (string=? prefix (substring str 0 plen)))))

(define (sort-strings lst)
  (define (merge a b)
    (cond
     ((null? a) b)
     ((null? b) a)
     ((string<? (car a) (car b))
      (cons (car a) (merge (cdr a) b)))
     (else
      (cons (car b) (merge a (cdr b))))))
  (define (merge-sort xs)
    (if (or (null? xs) (null? (cdr xs)))
        xs
        (let ((mid (quotient (length xs) 2)))
          (let take-left ((rest xs) (n mid) (acc '()))
            (if (= n 0)
                (merge (merge-sort (reverse acc))
                       (merge-sort rest))
                (take-left (cdr rest) (- n 1) (cons (car rest) acc)))))))
  (merge-sort lst))

(define (geiser-completions prefix . rest)
  (let ((syms (%global-env-symbols)))
    (sort-strings
     (filter (lambda (s) (string-prefix? prefix s)) syms))))

(define (geiser-autodoc ids . rest)
  (let ((syms (%global-env-symbols)))
    (define (safe-lookup sym)
      (let ((name (symbol->string sym)))
        (if (member name syms)
            (eval sym)
            #f)))
    (define (format-one-autodoc id)
      (let* ((sym (if (symbol? id) id (string->symbol (write-to-string id))))
             (val (safe-lookup sym)))
        (if (and val (procedure? val))
            (let ((params (%procedure-params val)))
              (if (pair? params)
                  (let* ((names (car params))
                         (rest-flag (cdr params)))
                    (if (= rest-flag 1)
                        (let* ((required (let drop-last ((xs names) (acc '()))
                                           (if (null? (cdr xs))
                                               (reverse acc)
                                               (drop-last (cdr xs) (cons (car xs) acc)))))
                               (rest-name (let last-elem ((xs names))
                                            (if (null? (cdr xs)) (car xs) (last-elem (cdr xs))))))
                          (list sym
                                (list 'args
                                      (cons 'required (map string->symbol required))
                                      (list 'optional)
                                      (list 'key)
                                      (list 'rest (string->symbol rest-name)))))
                        (list sym
                              (list 'args
                                    (cons 'required (map string->symbol names))
                                    (list 'optional)
                                    (list 'key)
                                    (list 'rest)))))
                  #f))
            #f)))
    (let loop ((remaining ids) (result '()))
      (if (null? remaining)
          (reverse result)
          (let ((entry (format-one-autodoc (car remaining))))
            (loop (cdr remaining)
                  (if entry (cons entry result) result)))))))
