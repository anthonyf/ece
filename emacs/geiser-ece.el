;;; geiser-ece.el --- Geiser backend for ECE Scheme -*- lexical-binding: t -*-

;; Copyright (C) 2026 Anthony Fairchild

;; Author: Anthony Fairchild
;; URL: https://github.com/anthonyf/ece
;; Keywords: languages, scheme, ece, geiser
;; Package-Requires: ((emacs "25.1") (geiser "0.26"))

;;; Commentary:

;; Geiser backend for the ECE Scheme implementation.  Supports eval at
;; point (C-x C-e), load file (C-c C-l), REPL buffer with clean output,
;; symbol completions (C-M-i), and autodoc (eldoc-mode signature hints).
;; No jump-to-def yet.
;;
;; Usage: add to your init.el:
;;   (load "/path/to/ece/emacs/geiser-ece.el")
;;
;; Then M-x run-geiser, select `ece'.
;;
;; Design notes:
;;  - The wire protocol sends RAW Scheme forms for eval (not wrapped in
;;    geiser:eval).  For load-file, it sends `(load PATH)' directly.
;;    The --geiser REPL mode captures stdout during eval and emits a
;;    chibi-style alist response: ((result "...") (output . "..."))
;;  - Version detection uses `bin/ece-repl -V' (the version-command slot).
;;
;; See openspec/changes/geiser-ece-day-1/ for full design rationale.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
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

(geiser-custom--defcustom geiser-ece-dev-server-url "http://127.0.0.1:8080"
  "Base URL for an ece-serve process used by live browser development."
  :type 'string
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-dev-server-token nil
  "Dev token printed by ece-serve for editor/browser live development."
  :type '(choice (const nil) string)
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

(defun geiser-ece--output-filter (output)
  "Clean up raw alist wire protocol in the REPL buffer.
Parses ((result \"...\") (output . \"...\")) responses and displays
just the result value, with any side-effect output prepended.
Preserves trailing text (e.g., the prompt) after the parsed alist."
  (if (and (boundp 'comint-redirect-completed)
           (not comint-redirect-completed))
      output
  (condition-case nil
      (let* ((read-result (read-from-string output))
             (parsed (car read-result))
             (end-pos (cdr read-result))
             (remaining (string-trim-left (substring output end-pos)))
             (result-entry (assq 'result parsed))
             (output-entry (assq 'output parsed)))
        (if (and result-entry output-entry)
            (let ((result-str (cadr result-entry))
                  (output-str (cdr output-entry)))
              (concat
               (if (and output-str (not (string= output-str "")))
                   (concat output-str "\n")
                 "")
               (if (and result-str (not (string= result-str ""))
                        (not (string-prefix-p "(compiled-procedure " result-str))
                        (not (string-prefix-p "(primitive " result-str)))
                   (concat result-str "\n")
                 "")
               remaining))
          output))
    (error output))))

(defun geiser-ece--startup (_remote)
  "Actions run after the ECE REPL process starts."
  (add-hook 'comint-preoutput-filter-functions
            #'geiser-ece--output-filter nil t))

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

(defun geiser-ece--find-module (&optional _module)
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

;;; Completions (direct REPL query, bypasses geiser-eval--send/wait)

(defun geiser-ece--repl-buffer ()
  "Find the live ECE Geiser REPL buffer."
  (cl-loop for buf in (buffer-list)
           when (and (string-match-p "\\*Geiser Ece REPL\\*" (buffer-name buf))
                     (get-buffer-process buf)
                     (process-live-p (get-buffer-process buf)))
           return buf))

(defun geiser-ece--sync-completions (prefix)
  "Query the ECE REPL for completions matching PREFIX."
  (let* ((repl-buf (geiser-ece--repl-buffer))
         (proc (and repl-buf (get-buffer-process repl-buf))))
    (when proc
      (let ((output-buf (generate-new-buffer " *ece-comp*")))
        (unwind-protect
            (with-timeout (5 nil)
              (with-current-buffer repl-buf
                (comint-redirect-send-command-to-process
                 (format "(geiser-completions %S)" prefix)
                 output-buf proc nil t)
                (while (and (process-live-p proc)
                            (not comint-redirect-completed))
                  (accept-process-output proc 0.1))
                (when (and (process-live-p proc) comint-redirect-completed)
                  (with-current-buffer output-buf
                    (goto-char (point-min))
                    (condition-case nil
                        (let* ((response (read (current-buffer)))
                               (result-str (cadr (assq 'result response))))
                          (when (and result-str (not (string= result-str "")))
                            (car (read-from-string result-str))))
                      (error nil))))))
          (kill-buffer output-buf))))))

(defun geiser-ece--complete-at-point ()
  "Completion-at-point function for ECE Scheme buffers."
  (when (geiser-ece--repl-buffer)
    (let ((end (point))
          (beg (save-excursion
                 (with-syntax-table scheme-mode-syntax-table
                   (skip-syntax-backward "^-()> ")
                   (point)))))
      (when (> end beg)
        (let* ((prefix (buffer-substring-no-properties beg end))
               (completions (geiser-ece--sync-completions prefix)))
          (when completions
            (list beg end completions :exclusive 'no)))))))

(defun geiser-ece--setup-completion ()
  "Add ECE completion to `completion-at-point-functions'."
  (add-hook 'completion-at-point-functions
            #'geiser-ece--complete-at-point nil t))

(add-hook 'geiser-mode-hook #'geiser-ece--setup-completion)
(add-hook 'geiser-repl-mode-hook #'geiser-ece--setup-completion)

;;; Autodoc (direct REPL query, same comint-redirect pattern as completions)

(defun geiser-ece--sync-autodoc (symbol-name)
  "Query the ECE REPL for autodoc on SYMBOL-NAME."
  (when (and symbol-name
             (string-match-p "\\`[^()\";\n\t ]+\\'" symbol-name))
    (let* ((repl-buf (geiser-ece--repl-buffer))
           (proc (and repl-buf (get-buffer-process repl-buf))))
      (when proc
        (let ((output-buf (generate-new-buffer " *ece-autodoc*")))
          (unwind-protect
              (with-timeout (3 nil)
                (with-current-buffer repl-buf
                  (comint-redirect-send-command-to-process
                   (format "(geiser-autodoc '(%s))" symbol-name)
                   output-buf proc nil t)
                  (while (and (process-live-p proc)
                              (not comint-redirect-completed))
                    (accept-process-output proc 0.1))
                  (when (and (process-live-p proc) comint-redirect-completed)
                    (with-current-buffer output-buf
                      (goto-char (point-min))
                      (condition-case nil
                          (let* ((response (read (current-buffer)))
                                 (result-str (cadr (assq 'result response))))
                            (when (and result-str (not (string= result-str ""))
                                       (not (string= result-str "()")))
                              (car (read-from-string result-str))))
                        (error nil))))))
            (kill-buffer output-buf)))))))

(defun geiser-ece--function-at-point ()
  "Return the name of the function at or around point."
  (save-excursion
    (let ((ppss (syntax-ppss)))
      (when (> (nth 0 ppss) 0)
        (goto-char (nth 1 ppss))
        (forward-char 1)
        (let ((sym-start (point)))
          (with-syntax-table scheme-mode-syntax-table
            (skip-syntax-forward "^-()> "))
          (when (> (point) sym-start)
            (buffer-substring-no-properties sym-start (point))))))))

(defun geiser-ece--format-autodoc (autodoc-result)
  "Format AUTODOC-RESULT as an eldoc string."
  (when autodoc-result
    (let* ((entry (car autodoc-result))
           (name (car entry))
           (args-spec (cadr entry))
           (required (cdr (assq 'required (cdr args-spec))))
           (rest-arg (cadr (assq 'rest (cdr args-spec))))
           (parts (mapcar #'symbol-name required)))
      (when rest-arg
        (setq parts (append parts (list "." (symbol-name rest-arg)))))
      (let ((args (mapconcat #'identity parts " ")))
        (if (string-empty-p args)
            (format "(%s)" name)
          (format "(%s %s)" name args))))))

(defun geiser-ece--eldoc-function (&optional callback &rest _)
  "Eldoc function for ECE Scheme.
Works with both `eldoc-documentation-functions' (Emacs 28+)
and the legacy `eldoc-documentation-function' API."
  (let ((fn-name (geiser-ece--function-at-point)))
    (when fn-name
      (let ((doc (geiser-ece--format-autodoc
                  (geiser-ece--sync-autodoc fn-name))))
        (when doc
          (if callback
              (funcall callback doc)
            doc))))))

(defun geiser-ece--setup-eldoc ()
  "Set up eldoc for ECE Scheme buffers."
  (if (boundp 'eldoc-documentation-functions)
      (add-hook 'eldoc-documentation-functions
                #'geiser-ece--eldoc-function nil t)
    (setq-local eldoc-documentation-function #'geiser-ece--eldoc-function)))

(add-hook 'geiser-mode-hook #'geiser-ece--setup-eldoc)
(add-hook 'geiser-repl-mode-hook #'geiser-ece--setup-eldoc)

;;; ece-serve browser dev integration

(defun geiser-ece--dev-post (endpoint body &optional source-path wait-result)
  "POST BODY to ece-serve ENDPOINT.
When SOURCE-PATH is non-nil, pass it as X-ECE-Path so the browser dev
client can report where the source came from. When WAIT-RESULT is non-nil,
ask ece-serve to return the browser eval result/error JSON."
  (require 'url)
  (require 'json)
  (unless (and geiser-ece-dev-server-token
               (not (string-empty-p geiser-ece-dev-server-token)))
    (error "Set geiser-ece-dev-server-token to the token printed by ece-serve"))
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          (append '(("Content-Type" . "text/plain; charset=utf-8"))
                  `(("X-ECE-Dev-Token" . ,geiser-ece-dev-server-token))
                  (when source-path
                    `(("X-ECE-Path" . ,source-path)))
                  (when wait-result
                    '(("X-ECE-Wait-Result" . "1")))))
         (url-request-data (encode-coding-string body 'utf-8))
         (url (concat (string-remove-suffix "/" geiser-ece-dev-server-url)
                      endpoint))
         (buffer (url-retrieve-synchronously url t t 8)))
    (unless buffer
      (error "ece-serve did not respond at %s" url))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (let ((ok (looking-at "HTTP/[0-9.]+ 2[0-9][0-9]"))
                (status (buffer-substring-no-properties
                         (line-beginning-position)
                         (line-end-position))))
            (re-search-forward "\r?\n\r?\n" nil t)
            (let ((json-object-type 'alist)
                  (json-array-type 'list)
                  (json-false :false))
              (let ((payload
                     (condition-case nil
                         (json-read)
                       (error nil))))
                (unless ok
                  (let ((err (or (cdr (assq 'error payload)) status)))
                    (error "ece-serve command failed: %s" err)))
                payload))))
      (kill-buffer buffer))))

(defun geiser-ece--dev-result-message (payload fallback)
  "Return a concise user message for ece-serve browser result PAYLOAD."
  (let ((ok (cdr (assq 'ok payload)))
        (result (cdr (assq 'result payload)))
        (error-text (cdr (assq 'error payload))))
    (cond
     ((eq ok :false)
      (format "ECE browser eval failed: %s" (or error-text "unknown error")))
     ((and result (not (string-empty-p result)))
      result)
     (t fallback))))

;;;###autoload
(defun geiser-ece-dev-eval-region (start end)
  "Send the active region to ece-serve for browser-side evaluation."
  (interactive "r")
  (message "%s"
           (geiser-ece--dev-result-message
            (geiser-ece--dev-post "/__ece_dev/eval-source"
                                  (buffer-substring-no-properties start end)
                                  (or buffer-file-name (buffer-name))
                                  t)
            "Sent region to ece-serve")))

;;;###autoload
(defun geiser-ece-dev-load-buffer ()
  "Send the current buffer contents to ece-serve for browser-side evaluation."
  (interactive)
  (message "%s"
           (geiser-ece--dev-result-message
            (geiser-ece--dev-post "/__ece_dev/eval-source"
                                  (buffer-substring-no-properties (point-min) (point-max))
                                  (or buffer-file-name (buffer-name))
                                  t)
            "Sent buffer to ece-serve")))

;;;###autoload
(defun geiser-ece-dev-reload-file ()
  "Save the current file and send its source to ece-serve."
  (interactive)
  (unless buffer-file-name
    (error "Current buffer is not visiting a file"))
  (when (buffer-modified-p)
    (save-buffer))
  (message "%s"
           (geiser-ece--dev-result-message
            (geiser-ece--dev-post "/__ece_dev/eval-source"
                                  (buffer-substring-no-properties (point-min) (point-max))
                                  buffer-file-name
                                  t)
            (format "Sent %s to ece-serve" buffer-file-name))))

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
