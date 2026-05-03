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

(geiser-custom--defcustom geiser-ece-dev-server-port 8080
  "Default port used by `geiser-ece-dev-start'."
  :type 'integer
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-dev-poll-interval-ms 250
  "Default ece-serve file-watch poll interval used by `geiser-ece-dev-start'."
  :type 'integer
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-dev-server-token nil
  "Dev token printed by ece-serve for editor/browser live development."
  :type '(choice (const nil) string)
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-dev-timeout-ms 8000
  "Milliseconds ece-serve should wait for a browser eval result."
  :type 'integer
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-dev-result-buffer "*ECE Browser Eval*"
  "Buffer used for multiline or long browser eval results."
  :type 'string
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-dev-server-buffer "*ECE Serve*"
  "Process buffer used by `geiser-ece-dev-start'."
  :type 'string
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

(defvar geiser-ece-dev--server-process nil
  "Current ece-serve process started by `geiser-ece-dev-start'.")

(defvar geiser-ece-dev--pending-url nil
  "Dev server URL parsed from the current ece-serve process output.")

(defvar geiser-ece-dev--pending-token nil
  "Dev token parsed from the current ece-serve process output.")

(defvar geiser-ece-dev--startup-output nil
  "ece-serve startup output accumulated until URL/token discovery completes.")

(defvar geiser-ece-dev--server-ready nil
  "Non-nil once the current managed ece-serve process is configured.")

(defvar geiser-ece-dev--source-buffer nil
  "Buffer that started the current managed ece-serve process.")

(defun geiser-ece--dev-server-base-url ()
  "Return `geiser-ece-dev-server-url' without a trailing slash."
  (string-remove-suffix "/" geiser-ece-dev-server-url))

(defun geiser-ece--dev-server-binary ()
  "Return the ece-serve binary path."
  (or (let ((repl (geiser-ece--binary)))
        (when (and repl (string-match-p "ece-repl\\'" repl))
          (let ((candidate
                 (expand-file-name "ece-serve"
                                   (file-name-directory repl))))
            (when (file-executable-p candidate)
              candidate))))
      (let ((dir (file-name-directory (or load-file-name buffer-file-name ""))))
        (when dir
          (let ((candidate
                 (expand-file-name "bin/ece-serve"
                                   (file-name-directory
                                    (directory-file-name dir)))))
            (when (file-executable-p candidate)
              candidate))))
      (executable-find "ece-serve")))

(defun geiser-ece--dev-server-live-p ()
  "Return non-nil when the managed ece-serve process is live."
  (and geiser-ece-dev--server-process
       (process-live-p geiser-ece-dev--server-process)))

(defun geiser-ece--dev-server-output-filter (proc output)
  "Collect ece-serve PROC OUTPUT and discover URL/token settings."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (let ((inhibit-read-only t))
        (goto-char (point-max))
        (insert output))))
  (unless geiser-ece-dev--server-ready
    (setq geiser-ece-dev--startup-output
          (concat geiser-ece-dev--startup-output output))
    (when (and (not geiser-ece-dev--pending-url)
               (string-match "Dev server: \\(http://[^[:space:]\n]+\\)"
                             geiser-ece-dev--startup-output))
      (setq geiser-ece-dev--pending-url
            (match-string 1 geiser-ece-dev--startup-output)))
    (when (and (not geiser-ece-dev--pending-token)
               (string-match "Dev token: \\([^[:space:]\n]+\\)"
                             geiser-ece-dev--startup-output))
      (setq geiser-ece-dev--pending-token
            (match-string 1 geiser-ece-dev--startup-output))))
  (when (and geiser-ece-dev--pending-url
             geiser-ece-dev--pending-token
             (not geiser-ece-dev--server-ready))
    (setq geiser-ece-dev-server-url
          (string-remove-suffix "/" geiser-ece-dev--pending-url))
    (setq geiser-ece-dev-server-token geiser-ece-dev--pending-token)
    (setq geiser-ece-dev--server-ready t)
    (setq geiser-ece-dev--startup-output nil)
    (when (buffer-live-p geiser-ece-dev--source-buffer)
      (with-current-buffer geiser-ece-dev--source-buffer
        (geiser-ece-dev-mode 1)))
    (message "ECE dev server ready at %s" geiser-ece-dev-server-url)))

(defun geiser-ece--dev-server-sentinel (proc event)
  "Report ece-serve PROC lifecycle EVENT."
  (unless (process-live-p proc)
    (when (eq proc geiser-ece-dev--server-process)
      (setq geiser-ece-dev--server-process nil))
    (unless (string= event "finished\n")
      (message "ECE dev server exited: %s" (string-trim event)))))

(defun geiser-ece--dev-require-connected ()
  "Signal unless ece-serve connection settings are usable."
  (unless (and geiser-ece-dev-server-url
               (not (string-empty-p geiser-ece-dev-server-url)))
    (error "Set geiser-ece-dev-server-url to the ece-serve URL"))
  (unless (and geiser-ece-dev-server-token
               (not (string-empty-p geiser-ece-dev-server-token)))
    (error "Run geiser-ece-dev-connect with the token printed by ece-serve")))

(defun geiser-ece--dev-post (endpoint body &optional source-path wait-result)
  "POST BODY to ece-serve ENDPOINT.
When SOURCE-PATH is non-nil, pass it as X-ECE-Path so the browser dev
client can report where the source came from. When WAIT-RESULT is non-nil,
ask ece-serve to return the browser eval result/error JSON."
  (require 'url)
  (require 'json)
  (geiser-ece--dev-require-connected)
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          (append '(("Content-Type" . "text/plain; charset=utf-8"))
                  `(("X-ECE-Dev-Token" . ,geiser-ece-dev-server-token))
                  (when source-path
                    `(("X-ECE-Path" . ,source-path)))
                  (when wait-result
                    `(("X-ECE-Wait-Result" . "1")
                      ("X-ECE-Timeout-Ms" . ,(number-to-string geiser-ece-dev-timeout-ms))))))
         (url-request-data (encode-coding-string body 'utf-8))
         (url (concat (geiser-ece--dev-server-base-url) endpoint))
         (buffer (url-retrieve-synchronously
                  url t t (+ 2 (/ geiser-ece-dev-timeout-ms 1000.0)))))
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

(defun geiser-ece--dev-display-result (payload fallback)
  "Display browser eval PAYLOAD, using FALLBACK when it has no result text."
  (let ((text (geiser-ece--dev-result-message payload fallback)))
    (if (or (string-match-p "\n" text)
            (> (length text) 90))
        (with-current-buffer (get-buffer-create geiser-ece-dev-result-buffer)
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert text)
            (goto-char (point-min))
            (special-mode))
          (display-buffer (current-buffer))
          (message "ECE browser result in %s" geiser-ece-dev-result-buffer))
      (message "%s" text))))

(defun geiser-ece--dev-source-path ()
  "Return the source path to report to ece-serve for the current buffer."
  (or buffer-file-name (buffer-name)))

(defun geiser-ece--dev-eval-source (source fallback)
  "Send SOURCE to ece-serve for browser-side evaluation and display the result."
  (geiser-ece--dev-display-result
   (geiser-ece--dev-post "/__ece_dev/eval-source"
                         source
                         (geiser-ece--dev-source-path)
                         t)
   fallback))

;;;###autoload
(defun geiser-ece-dev-connect (url token)
  "Set the ece-serve URL and dev TOKEN for live browser development."
  (interactive
   (let ((url (read-string "ece-serve URL: " geiser-ece-dev-server-url)))
     (list url
           (read-passwd "ece-serve dev token: "
                        nil
                        geiser-ece-dev-server-token))))
  (setq geiser-ece-dev-server-url (string-remove-suffix "/" url))
  (setq geiser-ece-dev-server-token token)
  (message "ECE dev connected to %s" geiser-ece-dev-server-url))

;;;###autoload
(defun geiser-ece-dev-status ()
  "Show current ece-serve live browser development settings."
  (interactive)
  (message "ECE dev URL: %s; token: %s"
           (or geiser-ece-dev-server-url "unset")
           (if (and geiser-ece-dev-server-token
                    (not (string-empty-p geiser-ece-dev-server-token)))
               "set"
             "unset")))

;;;###autoload
(defun geiser-ece-dev-open-browser ()
  "Open the configured ece-serve URL in a browser."
  (interactive)
  (require 'browse-url)
  (browse-url (geiser-ece--dev-server-base-url)))

;;;###autoload
(defun geiser-ece-dev-start (entry-file &optional port)
  "Start ece-serve for ENTRY-FILE and configure browser dev integration.
When PORT is nil, use `geiser-ece-dev-server-port'. Interactively, a prefix
argument prompts for the port. The dev token is generated by ece-serve and
parsed from its startup output."
  (interactive
   (let ((entry-file (read-file-name "ECE entry file: "
                                     nil nil t
                                     (when buffer-file-name
                                       (file-name-nondirectory buffer-file-name)))))
     (list entry-file
           (when current-prefix-arg
             (read-number "ECE dev server port: "
                          geiser-ece-dev-server-port)))))
  (when (geiser-ece--dev-server-live-p)
    (error "ece-serve is already running; use geiser-ece-dev-stop first"))
  (let ((binary (geiser-ece--dev-server-binary)))
    (unless binary
      (error "Could not find ece-serve; build ECE or customize geiser-ece-binary"))
    (let* ((listen-port (or port geiser-ece-dev-server-port))
           (buffer (get-buffer-create geiser-ece-dev-server-buffer))
           (args (list (expand-file-name entry-file)
                       "--port" (number-to-string listen-port)
                       "--poll-interval"
                       (number-to-string geiser-ece-dev-poll-interval-ms))))
      (setq geiser-ece-dev--pending-url nil)
      (setq geiser-ece-dev--pending-token nil)
      (setq geiser-ece-dev--startup-output nil)
      (setq geiser-ece-dev--server-ready nil)
      (setq geiser-ece-dev--source-buffer (current-buffer))
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert
           (format "$ %s\n\n"
                   (mapconcat #'shell-quote-argument
                              (cons binary args)
                              " ")))))
      (setq geiser-ece-dev--server-process
            (apply #'start-process "ece-serve" buffer binary args))
      (set-process-filter geiser-ece-dev--server-process
                          #'geiser-ece--dev-server-output-filter)
      (set-process-sentinel geiser-ece-dev--server-process
                            #'geiser-ece--dev-server-sentinel)
      (message "Starting ece-serve on port %s..." listen-port))))

;;;###autoload
(defun geiser-ece-dev-stop ()
  "Stop the ece-serve process started by `geiser-ece-dev-start'."
  (interactive)
  (if (geiser-ece--dev-server-live-p)
      (progn
        (delete-process geiser-ece-dev--server-process)
        (setq geiser-ece-dev--server-process nil)
        (message "Stopped ece-serve"))
    (message "No managed ece-serve process is running")))

;;;###autoload
(defun geiser-ece-dev-eval-region (start end)
  "Send the active region to ece-serve for browser-side evaluation."
  (interactive "r")
  (geiser-ece--dev-eval-source
   (buffer-substring-no-properties start end)
   "Sent region to ece-serve"))

;;;###autoload
(defun geiser-ece-dev-eval-last-sexp ()
  "Send the expression before point to ece-serve for browser-side evaluation."
  (interactive)
  (let ((end (point))
        beg)
    (save-excursion
      (backward-sexp)
      (setq beg (point)))
    (geiser-ece-dev-eval-region beg end)))

;;;###autoload
(defun geiser-ece-dev-eval-definition ()
  "Send the top-level definition at point to ece-serve for browser eval."
  (interactive)
  (let ((bounds (or (bounds-of-thing-at-point 'defun)
                    (save-excursion
                      (beginning-of-defun)
                      (let ((beg (point)))
                        (end-of-defun)
                        (cons beg (point)))))))
    (unless bounds
      (error "No definition at point"))
    (geiser-ece-dev-eval-region (car bounds) (cdr bounds))))

;;;###autoload
(defun geiser-ece-dev-load-buffer ()
  "Send the current buffer contents to ece-serve for browser-side evaluation."
  (interactive)
  (geiser-ece--dev-eval-source
   (buffer-substring-no-properties (point-min) (point-max))
   "Sent buffer to ece-serve"))

;;;###autoload
(defun geiser-ece-dev-save-buffer-and-reload ()
  "Save the current file for ece-serve watcher reload."
  (interactive)
  (unless buffer-file-name
    (error "Current buffer is not visiting a file"))
  (save-buffer)
  (message "Saved %s; ece-serve watcher will rebuild and reload the browser"
           buffer-file-name))

;;;###autoload
(defun geiser-ece-dev-reload-file ()
  "Save the current file and send its source to ece-serve for browser eval."
  (interactive)
  (unless buffer-file-name
    (error "Current buffer is not visiting a file"))
  (when (buffer-modified-p)
    (save-buffer))
  (geiser-ece--dev-display-result
   (geiser-ece--dev-post "/__ece_dev/eval-source"
                         (buffer-substring-no-properties (point-min) (point-max))
                         buffer-file-name
                         t)
   (format "Sent %s to ece-serve" buffer-file-name)))

(defvar geiser-ece-dev-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-z S") #'geiser-ece-dev-start)
    (define-key map (kbd "C-c C-z K") #'geiser-ece-dev-stop)
    (define-key map (kbd "C-c C-z c") #'geiser-ece-dev-connect)
    (define-key map (kbd "C-c C-z o") #'geiser-ece-dev-open-browser)
    (define-key map (kbd "C-c C-z ?") #'geiser-ece-dev-status)
    (define-key map (kbd "C-c C-z e") #'geiser-ece-dev-eval-last-sexp)
    (define-key map (kbd "C-c C-z r") #'geiser-ece-dev-eval-region)
    (define-key map (kbd "C-c C-z d") #'geiser-ece-dev-eval-definition)
    (define-key map (kbd "C-c C-z b") #'geiser-ece-dev-load-buffer)
    (define-key map (kbd "C-c C-z l") #'geiser-ece-dev-reload-file)
    (define-key map (kbd "C-c C-z s") #'geiser-ece-dev-save-buffer-and-reload)
    map)
  "Keymap for `geiser-ece-dev-mode'.")

;;;###autoload
(define-minor-mode geiser-ece-dev-mode
  "Minor mode for live browser development through ece-serve."
  :lighter " ECE-Dev"
  :keymap geiser-ece-dev-mode-map)

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
