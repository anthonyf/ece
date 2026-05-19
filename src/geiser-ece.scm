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
;;;    completions, autodoc, and source-location handlers. Eval and load-file
;;;    are handled inline by the
;;;    REPL's --geiser mode (see %geiser-eval-and-respond in ece-main.scm).
;;;
;;; The elisp side (`emacs/geiser-ece.el`) formats `C-x C-e` as a raw
;;; expression (not wrapped in `(geiser:eval ...)`), and `C-c C-l` as
;;; `(load "/abs/path.scm")` directly. Using hyphen names (not colons)
;;; because ECE's reader doesn't handle CL pipe-escape syntax, which
;;; compile-file-to-port emits for colon-containing symbols.

(define (geiser-no-values) #f)

(define *geiser-source-files* '())

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

(define (geiser-register-source-file! path)
  "Remember PATH as source that Geiser may search for definitions."
  (when (and (string? path)
             (not (member path *geiser-source-files*)))
    (set! *geiser-source-files* (cons path *geiser-source-files*)))
  *geiser-source-files*)

(define (geiser/source-read-all-forms path)
  "Read every top-level form from PATH, returning an empty list on errors."
  (guard
   (e (#t '()))
   (let ((in (open-input-file path)))
     (dynamic-wind
         (lambda () #f)
         (lambda ()
           (let loop ((acc '()))
             (let ((form (read in)))
               (cond
                ((eof? form) (reverse acc))
                (else (loop (cons form acc)))))))
         (lambda () (close-input-port in))))))

(define (geiser/load-form? form)
  "Return #t when FORM is a literal-string `(load ...)' form."
  (and (pair? form)
       (eq? (car form) 'load)
       (pair? (cdr form))
       (string? (car (cdr form)))
       (null? (cdr (cdr form)))))

(define (geiser/resolve-relative target base-dir)
  "Resolve TARGET against BASE-DIR unless TARGET is already absolute."
  (cond
   ((and (> (string-length target) 0)
         (char=? (string-ref target 0) #\/))
    target)
   (else (path-join base-dir target))))

(define (geiser-register-source-tree! entry-path)
  "Remember ENTRY-PATH and literal-string transitive loads for Geiser."
  (let ((seen '())
        (result '()))
    (define (visit path)
      (cond
       ((member path seen) 'already-seen)
       (else
        (set! seen (cons path seen))
        (geiser-register-source-file! path)
        (set! result (cons path result))
        (when (%file-exists? path)
          (let ((base-dir (dirname path)))
            (for-each
             (lambda (form)
               (when (geiser/load-form? form)
                 (visit (geiser/resolve-relative (car (cdr form)) base-dir))))
             (geiser/source-read-all-forms path)))))))
    (visit entry-path)
    (reverse result)))

(define (geiser/definition-names form)
  "Return the top-level names introduced by FORM."
  (if (not (pair? form))
      '()
      (let ((head (car form)))
        (cond
         ((member head '(define define/doc define-macro define-macro/doc))
          (if (pair? (cdr form))
              (let ((spec (cadr form)))
                (cond
                 ((symbol? spec) (list spec))
                 ((and (pair? spec) (symbol? (car spec))) (list (car spec)))
                 (else '())))
              '()))
         ((member head '(define-syntax define-syntax/doc
                         define-record define-record/doc))
          (if (and (pair? (cdr form)) (symbol? (cadr form)))
              (list (cadr form))
              '()))
         ((eq? head 'define-values)
          (if (and (pair? (cdr form)) (list? (cadr form)))
              (filter symbol? (cadr form))
              '()))
         (else '())))))

(define (geiser/form-defines-symbol? form sym)
  (member sym (geiser/definition-names form)))

(define (geiser/read-source-with-locations path)
  "Read PATH with source-location tracking.
Returns (FORMS . LOCATIONS), where LOCATIONS maps form identity to
`(file line column)'. Returns #f if PATH cannot be read."
  (guard
   (e (#t #f))
   (let ((previous-file *source-file-name*)
         (previous-locations *source-locations*)
         (result #f))
     (dynamic-wind
         (lambda ()
           (set! *source-file-name* path)
           (set! *source-locations* (%make-hash-table)))
         (lambda ()
           (let ((forms (geiser/source-read-all-forms path)))
             (set! result (cons forms *source-locations*))
             result))
         (lambda ()
           (set! *source-file-name* previous-file)
           (set! *source-locations* previous-locations))))))

(define (geiser/location-alist name loc)
  "Return a Geiser location alist for NAME at LOC."
  (list (cons "name" (symbol->string name))
        (cons "file" (car loc))
        (cons "line" (cadr loc))
        (cons "column" (caddr loc))))

(define (geiser/find-symbol-location-in-file name path)
  "Find NAME's top-level source location in PATH, or #f."
  (let ((source (geiser/read-source-with-locations path)))
    (and source
         (let ((forms (car source))
               (locations (cdr source)))
           (let loop ((rest forms))
             (cond
              ((null? rest) #f)
              ((geiser/form-defines-symbol? (car rest) name)
               (let ((loc (hash-ref locations (car rest) #f)))
                 (if loc
                     (geiser/location-alist name loc)
                     (loop (cdr rest)))))
              (else (loop (cdr rest)))))))))

(define (geiser-symbol-location name . rest)
  "Return Geiser source location data for NAME, or #f if unknown."
  (let ((sym (if (symbol? name)
                 name
                 (string->symbol (write-to-string name)))))
    (let loop ((files *geiser-source-files*))
      (cond
       ((null? files) #f)
       (else
        (let ((loc (geiser/find-symbol-location-in-file sym (car files))))
          (if loc loc (loop (cdr files)))))))))

(define (geiser-module-location module . rest)
  "Return #f because ECE does not yet track module source locations."
  #f)
