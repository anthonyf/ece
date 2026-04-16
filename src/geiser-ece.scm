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
;;;
;;; See openspec/changes/geiser-ece-day-1/design.md for full rationale.

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
  '())
