;;; geiser-ece.scm — Scheme-side support for the Geiser emacs backend.
;;;
;;; The Geiser protocol is handled in two layers:
;;;
;;; 1. REPL layer (ece-main.scm): In --geiser mode, the REPL captures
;;;    current-output-port to a string during evaluation, formats the
;;;    result as a chibi-style alist `((result "...") (output . "..."))`,
;;;    and writes it via write-to-string-flat. This is the wire protocol.
;;;
;;; 2. Helper layer (this file): provides `geiser-no-values` and stub
;;;    handlers for feature probes that Geiser's elisp side might send.
;;;    Eval and load-file are handled inline by the REPL's --geiser mode
;;;    (see %geiser-eval-and-respond in ece-main.scm).
;;;
;;; The elisp side (`emacs/geiser-ece.el`) formats `C-x C-e` as a raw
;;; expression (not wrapped in `(geiser:eval ...)`), and `C-c C-l` as
;;; `(load "/abs/path.scm")` directly. Using hyphen names (not colons)
;;; because ECE's reader doesn't handle CL pipe-escape syntax, which
;;; compile-file-to-port emits for colon-containing symbols.
;;;
;;; See openspec/changes/geiser-ece-day-1/design.md for full rationale.

(define (geiser-no-values) #f)

;; Day-1 stubs for features Geiser probes during connection setup.
(define (geiser-completions prefix . rest)
  '())

(define (geiser-autodoc ids . rest)
  '())
