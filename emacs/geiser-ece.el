;;; geiser-ece.el --- Geiser backend for ECE Scheme -*- lexical-binding: t -*-

;; Copyright (C) 2026 Anthony Fairchild

;; Author: Anthony Fairchild
;; URL: https://github.com/anthonyf/ece
;; Keywords: languages, scheme, ece, geiser
;; Package-Requires: ((emacs "25.1") (geiser "0.26"))

;;; Commentary:

;; Geiser backend for the ECE Scheme implementation.  Day 1 scope: eval at
;; point (C-x C-e), load file (C-c C-l), REPL buffer.  No completions,
;; autodoc, or jump-to-def yet.
;;
;; Usage: add to your init.el:
;;   (load "/path/to/ece/emacs/geiser-ece.el")
;;
;; Then M-x run-geiser, select `ece'.
;;
;; Design notes:
;;  - The wire protocol sends RAW Scheme forms (not wrapped in geiser:eval).
;;    The --geiser REPL mode captures stdout during eval and emits a
;;    chibi-style alist response: ((result "...") (output . "..."))
;;  - Version detection uses `bin/ece-repl -V' (the version-command slot).
;;  - Handler names use hyphens (geiser-load-file), not colons, because
;;    ECE's reader doesn't roundtrip colon-symbols through file compilation.
;;
;; See openspec/changes/geiser-ece-day-1/ for full design rationale.

;;; Code:

(require 'geiser-impl)
(require 'geiser-custom)
(require 'geiser-base)
(require 'geiser-eval)
(require 'geiser-syntax)
(require 'geiser-log)
(require 'compile)

;;; Customization

(defgroup geiser-ece nil
  "Customization for Geiser's ECE Scheme flavour."
  :group 'geiser)

(geiser-custom--defcustom geiser-ece-binary
  (or (executable-find "ece-repl")
      (let ((dir (file-name-directory (or load-file-name buffer-file-name ""))))
        (when dir
          (expand-file-name "bin/ece-repl" (file-name-directory (directory-file-name dir))))))
  "Name or path of the ECE REPL binary.
When not on PATH, derived from this file's location (emacs/../bin/ece-repl)."
  :type '(choice string (repeat string))
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-extra-keywords '()
  "Extra keywords highlighted in ECE Scheme buffers."
  :type '(repeat string)
  :group 'geiser-ece)

;;; Implementation

(defconst geiser-ece--prompt-regexp "ece> "
  "Regexp matching the ECE REPL prompt.")

(defun geiser-ece--binary ()
  "Return the ECE binary as a string."
  (if (listp geiser-ece-binary)
      (car geiser-ece-binary)
    geiser-ece-binary))

(defun geiser-ece--parameters ()
  "Return the command-line parameters for the ECE REPL subprocess."
  '("--geiser"))

(defun geiser-ece--version (binary)
  "Return the version string from BINARY."
  (car (process-lines binary "--version")))

(defun geiser-ece--startup (_remote)
  "Actions run after the ECE REPL process starts.")

(defun geiser-ece--geiser-procedure (proc &rest args)
  "Translate a Geiser request PROC with ARGS into a Scheme form string.
In ECE's Geiser mode the REPL handles eval/load directly:
  eval     -> raw form
  load-file -> (load PATH)
  no-values -> (geiser-no-values)"
  (cl-case proc
    ((eval compile)
     (let ((form (cadr args))
           (_module (car args)))
       (format "%s" form)))
    ((load-file compile-file)
     (format "(load %S)" (car args)))
    ((no-values)
     "(geiser-no-values)")
    (t
     (let ((form (mapconcat 'identity
                            (cons (format "geiser-%s" proc)
                                  (mapcar (lambda (a) (format "%S" a)) args))
                            " ")))
       (format "(%s)" form)))))

(defun geiser-ece--exit-command ()
  "(exit)")

(defun geiser-ece--import-command (_module)
  nil)

(defun geiser-ece--find-module ()
  nil)

(defun geiser-ece--symbol-begin (_module)
  (save-excursion (skip-syntax-backward "^'-()>") (point)))

(defun geiser-ece--keywords ()
  (append '("define-macro" "define-record" "define-syntax"
            "when" "unless" "guard" "parameterize"
            "with-exception-handler" "dynamic-wind"
            "call/cc" "call-with-current-continuation")
          geiser-ece-extra-keywords))

(defun geiser-ece--case-sensitive-p ()
  t)

;;; Registration

(define-geiser-implementation ece
  (binary geiser-ece--binary)
  (arglist geiser-ece--parameters)
  (version-command geiser-ece--version)
  (minimum-version "0.1")
  (repl-startup geiser-ece--startup)
  (prompt-regexp geiser-ece--prompt-regexp)
  (debugger-prompt-regexp nil)
  (marshall-procedure geiser-ece--geiser-procedure)
  (find-module geiser-ece--find-module)
  (exit-command geiser-ece--exit-command)
  (import-command geiser-ece--import-command)
  (find-symbol-begin geiser-ece--symbol-begin)
  (case-sensitive geiser-ece--case-sensitive-p))

;;;###autoload
(geiser-activate-implementation 'ece)

;;;###autoload
(autoload 'run-ece "geiser-ece" "Start a Geiser ECE Scheme REPL." t)

;;;###autoload
(autoload 'switch-to-ece "geiser-ece"
  "Start a Geiser ECE Scheme REPL, or switch to a running one." t)

(provide 'geiser-ece)

;;; geiser-ece.el ends here
