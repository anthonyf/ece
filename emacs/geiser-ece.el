;;; geiser-ece.el --- Geiser backend for ECE Scheme -*- lexical-binding: t -*-

;; Copyright (C) 2026 Anthony Fairchild

;; Author: Anthony Fairchild
;; URL: https://github.com/anthonyf/ece
;; Keywords: languages, scheme, ece, geiser
;; Package-Requires: ((emacs "25.1") (geiser "0.26"))

;;; Commentary:

;; Geiser backend for the ECE Scheme implementation.  Supports eval at
;; point (C-x C-e), load file (C-c C-l), REPL buffer with clean output,
;; symbol completions (C-M-i), autodoc (eldoc-mode signature hints), and
;; source-definition lookup for registered files.
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
(require 'comint)

(declare-function geiser "geiser-repl" (impl))
(declare-function geiser-mode "geiser-mode" (&optional arg))
(declare-function geiser-edit-symbol-at-point "geiser-edit" (&optional arg))
(declare-function geiser-pop-symbol-stack "geiser-edit" ())
(declare-function geiser-doc-symbol-at-point "geiser-doc" (&optional arg))
(declare-function geiser-repl--repl/impl "geiser-repl"
                  (impl &optional proj repls))
(declare-function geiser-repl--set-this-buffer-repl "geiser-repl"
                  (r &optional this))

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

(geiser-custom--defcustom geiser-ece-dev-project-file-name "ece.project"
  "File name used to discover an ECE project root for browser development."
  :type 'string
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

(geiser-custom--defcustom geiser-ece-dev-repl-buffer "*ECE Browser REPL*"
  "REPL buffer used for ece-serve browser development."
  :type 'string
  :group 'geiser-ece)

(geiser-custom--defcustom geiser-ece-dev-session-directory
  (let ((dir (file-name-directory (or load-file-name buffer-file-name ""))))
    (if dir
        (expand-file-name "../.tmp/ece-serve-sessions" dir)
      ".tmp/ece-serve-sessions"))
  "Directory where ece-serve writes local editor attach session files."
  :type 'directory
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

(defun geiser-ece--redirect-active-p ()
  "Return non-nil while comint is redirecting REPL output elsewhere."
  (and (boundp 'comint-redirect-output-buffer)
       comint-redirect-output-buffer
       (boundp 'comint-redirect-completed)
       (not comint-redirect-completed)))

(defun geiser-ece--wire-response-p (value)
  "Return non-nil when VALUE is an ECE Geiser wire response."
  (and (listp value)
       (assq 'result value)
       (assq 'output value)))

(defun geiser-ece--find-wire-response (output)
  "Find an ECE Geiser wire response inside OUTPUT.
Returns (START END VALUE), or nil when OUTPUT has no parseable response.
Comint can deliver prompt text and the response alist in the same chunk, so
the response is not guaranteed to start at character 0."
  (catch 'found
    (let ((pos 0))
      (while (string-match "((" output pos)
        (let ((start (match-beginning 0)))
          (condition-case nil
              (let* ((read-result (read-from-string output start))
                     (value (car read-result))
                     (end (cdr read-result)))
                (when (geiser-ece--wire-response-p value)
                  (throw 'found (list start end value))))
            (error nil))
          (setq pos (1+ start))))
      nil)))

(defun geiser-ece--format-wire-response (value)
  "Format parsed ECE Geiser wire response VALUE for REPL display."
  (let* ((result-entry (assq 'result value))
         (output-entry (assq 'output value))
         (result-str (and (consp (cdr result-entry))
                          (cadr result-entry)))
         (output-str (cdr output-entry)))
    (concat
     (if (and output-str (not (string= output-str "")))
         (concat output-str "\n")
       "")
     (if (and result-str (not (string= result-str ""))
              (not (string-prefix-p "(compiled-procedure " result-str))
              (not (string-prefix-p "(primitive " result-str)))
         (concat result-str "\n")
       ""))))

(defun geiser-ece--wire-response-tail (prefix formatted suffix)
  "Return SUFFIX text after replacing a wire response.
PREFIX is the text before the response in the same process chunk and FORMATTED
is the replacement response text. When FORMATTED is empty, preserve one newline
between an earlier prompt and the next prompt instead of collapsing them onto
one line."
  (let ((trimmed (string-trim-left suffix)))
    (if (and (string-empty-p formatted)
             (not (string-empty-p prefix))
             (string-match-p "\\`[ \t]*\r?\n" suffix))
        (concat "\n" trimmed)
      trimmed)))

(defun geiser-ece--filter-wire-responses (output)
  "Replace all ECE Geiser wire responses in OUTPUT with display text."
  (let ((rest output)
        (filtered ""))
    (while (let ((match (geiser-ece--find-wire-response rest)))
             (when match
               (let* ((start (nth 0 match))
                      (end (nth 1 match))
                      (value (nth 2 match))
                      (prefix (substring rest 0 start))
                      (formatted (geiser-ece--format-wire-response value))
                      (suffix (substring rest end)))
                 (setq filtered (concat filtered prefix formatted))
                 (setq rest
                       (geiser-ece--wire-response-tail
                        prefix formatted suffix))
                 t))))
    (concat filtered rest)))

(defun geiser-ece--output-filter (output)
  "Clean up raw alist wire protocol in the REPL buffer.
Parses ((result \"...\") (output . \"...\")) responses and displays
just the result value, with any side-effect output prepended.
Preserves surrounding text, such as prompts, from the same process chunk."
  (if (geiser-ece--redirect-active-p)
      output
    (geiser-ece--filter-wire-responses output)))

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
     (format "(begin (geiser-register-source-tree! %S) (load %S))"
             (car args)
             (car args)))
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
  (or (and (fboundp 'geiser-repl--repl/impl)
           (let ((buf (ignore-errors (geiser-repl--repl/impl 'ece))))
             (and (buffer-live-p buf)
                  (get-buffer-process buf)
                  (process-live-p (get-buffer-process buf))
                  buf)))
      (cl-loop for buf in (buffer-list)
               when (and (string-match-p "\\*Geiser Ece REPL\\*"
                                         (buffer-name buf))
                         (get-buffer-process buf)
                         (process-live-p (get-buffer-process buf)))
               return buf)))

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

(defvar geiser-ece-dev--entry-file nil
  "Current ece-serve entry source file, when known.")

(defvar geiser-ece-dev--ready-callbacks nil
  "Functions to call once the current ece-serve settings are ready.")

(defvar geiser-ece-dev-repl-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-z c") #'geiser-ece-dev-connect-repl)
    (define-key map (kbd "C-c C-z S") #'geiser-ece-dev-start-repl)
    (define-key map (kbd "C-c C-z o") #'geiser-ece-dev-open-browser)
    (define-key map (kbd "C-c C-z ?") #'geiser-ece-dev-status)
    (define-key map (kbd "M-.") #'geiser-edit-symbol-at-point)
    (define-key map (kbd "M-,") #'geiser-pop-symbol-stack)
    (define-key map (kbd "C-c C-d C-d") #'geiser-doc-symbol-at-point)
    map)
  "Keymap for `geiser-ece-dev-repl-mode'.")

(defun geiser-ece--live-geiser-repl-buffer (&optional source-buffer)
  "Return the live Geiser ECE REPL for SOURCE-BUFFER's project."
  (require 'geiser-repl)
  (let ((context (or source-buffer (current-buffer))))
    (when (buffer-live-p context)
      (with-current-buffer context
        (let ((buf (ignore-errors (geiser-repl--repl/impl 'ece))))
          (and (buffer-live-p buf)
               (get-buffer-process buf)
               (process-live-p (get-buffer-process buf))
               buf))))))

(defun geiser-ece--ensure-geiser-repl (&optional source-buffer)
  "Ensure SOURCE-BUFFER has a real Geiser ECE REPL."
  (require 'geiser-repl)
  (let ((context (or source-buffer (current-buffer))))
    (when (buffer-live-p context)
      (or (geiser-ece--live-geiser-repl-buffer context)
          (condition-case err
              (progn
                (save-window-excursion
                  (save-current-buffer
                    (with-current-buffer context
                      (geiser 'ece))))
                (geiser-ece--live-geiser-repl-buffer context))
            (error
             (message "ECE dev could not start Geiser REPL: %s"
                      (error-message-string err))
             nil))))))

(defun geiser-ece--associate-geiser-buffer (buffer &optional repl)
  "Mark BUFFER as ECE Scheme and associate it with REPL."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq-local geiser-scheme-implementation 'ece)
      (geiser-impl--set-buffer-implementation 'ece)
      (when (and repl (fboundp 'geiser-repl--set-this-buffer-repl))
        (geiser-repl--set-this-buffer-repl repl buffer)))))

(defun geiser-ece--register-source-tree (entry-file repl)
  "Register ENTRY-FILE and its literal loads with the Geiser REPL."
  (when (and entry-file (buffer-live-p repl))
    (with-current-buffer repl
      (ignore-errors
        (geiser-eval--send/wait
         (format "(geiser-register-source-tree! %S)"
                 (expand-file-name entry-file))
         3000)))))

(defun geiser-ece--dev-integrate-geiser (&optional buffer entry-file)
  "Enable normal Geiser metadata commands for BUFFER and ENTRY-FILE."
  (let ((buffer (or buffer (current-buffer))))
    (when (buffer-live-p buffer)
      (require 'geiser-mode)
      (require 'geiser-edit)
      (require 'geiser-doc)
      (let ((repl (geiser-ece--ensure-geiser-repl buffer)))
        (geiser-ece--associate-geiser-buffer buffer repl)
        (with-current-buffer buffer
          (unless (bound-and-true-p geiser-mode)
            (geiser-mode 1)))
        (when repl
          (geiser-ece--register-source-tree
           (or entry-file buffer-file-name)
           repl)
          (let ((dev-repl (get-buffer geiser-ece-dev-repl-buffer)))
            (when (buffer-live-p dev-repl)
              (geiser-ece--associate-geiser-buffer dev-repl repl))))))))

(defun geiser-ece--dev-schedule-geiser-integration (&optional buffer entry-file)
  "Schedule Geiser integration for BUFFER outside process filters."
  (when (buffer-live-p buffer)
    (run-at-time 0 nil
                 #'geiser-ece--dev-integrate-geiser
                 buffer
                 entry-file)))

(defun geiser-ece--dev-run-ready-callbacks ()
  "Run and clear callbacks waiting for ece-serve startup."
  (let ((callbacks (nreverse geiser-ece-dev--ready-callbacks)))
    (setq geiser-ece-dev--ready-callbacks nil)
    (dolist (callback callbacks)
      (funcall callback))))

(defun geiser-ece--dev-clear-ready-callbacks ()
  "Clear callbacks waiting for ece-serve startup."
  (setq geiser-ece-dev--ready-callbacks nil))

(defun geiser-ece--dev-after-ready (callback)
  "Run CALLBACK when ece-serve connection settings are ready."
  (if geiser-ece-dev--server-ready
      (funcall callback)
    (push callback geiser-ece-dev--ready-callbacks)))

(defun geiser-ece--dev-server-base-url ()
  "Return `geiser-ece-dev-server-url' without a trailing slash."
  (string-remove-suffix "/" (geiser-ece--dev-server-url)))

(defun geiser-ece--dev-nonempty-string (value)
  "Return VALUE when it is a non-empty string."
  (and (stringp value)
       (not (string-empty-p value))
       value))

(defun geiser-ece--dev-setting (symbol)
  "Return SYMBOL's buffer-local value, or its non-empty default value."
  (or (geiser-ece--dev-nonempty-string (symbol-value symbol))
      (geiser-ece--dev-nonempty-string (default-value symbol))))

(defun geiser-ece--dev-server-url ()
  "Return the active ece-serve URL."
  (geiser-ece--dev-setting 'geiser-ece-dev-server-url))

(defun geiser-ece--dev-server-token ()
  "Return the active ece-serve dev token."
  (geiser-ece--dev-setting 'geiser-ece-dev-server-token))

(defun geiser-ece--dev-set-server-url (url)
  "Set the active ece-serve URL globally and in the current buffer."
  (setq-default geiser-ece-dev-server-url url)
  (setq geiser-ece-dev-server-url url))

(defun geiser-ece--dev-set-server-token (token)
  "Set the active ece-serve TOKEN globally and in the current buffer."
  (setq-default geiser-ece-dev-server-token token)
  (setq geiser-ece-dev-server-token token))

(defun geiser-ece--dev-set-server-port (port)
  "Set the active ece-serve PORT globally and in the current buffer."
  (setq-default geiser-ece-dev-server-port port)
  (setq geiser-ece-dev-server-port port))

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
    (geiser-ece--dev-set-server-url
     (string-remove-suffix "/" geiser-ece-dev--pending-url))
    (geiser-ece--dev-set-server-token geiser-ece-dev--pending-token)
    (setq geiser-ece-dev--server-ready t)
    (setq geiser-ece-dev--startup-output nil)
    (when (buffer-live-p geiser-ece-dev--source-buffer)
      (with-current-buffer geiser-ece-dev--source-buffer
        (geiser-ece-dev-mode 1)))
    (geiser-ece--dev-schedule-geiser-integration
     geiser-ece-dev--source-buffer
     geiser-ece-dev--entry-file)
    (geiser-ece--dev-run-ready-callbacks)
    (message "ECE dev server ready at %s" geiser-ece-dev-server-url)))

(defun geiser-ece--dev-server-sentinel (proc event)
  "Report ece-serve PROC lifecycle EVENT."
  (unless (process-live-p proc)
    (when (eq proc geiser-ece-dev--server-process)
      (setq geiser-ece-dev--server-process nil)
      (unless geiser-ece-dev--server-ready
        (geiser-ece--dev-clear-ready-callbacks)))
    (unless (string= event "finished\n")
      (message "ECE dev server exited: %s" (string-trim event)))))

(defun geiser-ece--dev-require-connected ()
  "Signal unless ece-serve connection settings are usable."
  (unless (geiser-ece--dev-server-url)
    (error "Set geiser-ece-dev-server-url to the ece-serve URL"))
  (unless (geiser-ece--dev-server-token)
    (error "Run geiser-ece-dev-connect to discover the ece-serve token")))

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
                  `(("X-ECE-Dev-Token" . ,(geiser-ece--dev-server-token)))
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

(defun geiser-ece--dev-repl-result-text (payload fallback)
  "Return browser eval text for REPL PAYLOAD."
  (let ((text (geiser-ece--dev-result-message payload fallback)))
    (if (string-empty-p text) fallback text)))

(defun geiser-ece--dev-repl-insert (process text)
  "Insert TEXT at PROCESS mark in the browser dev REPL."
  (let ((buffer (process-buffer process)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (let ((inhibit-read-only t)
              (moving (= (point) (process-mark process))))
          (save-excursion
            (goto-char (process-mark process))
            (insert text)
            (set-marker (process-mark process) (point)))
          (when moving
            (goto-char (process-mark process))))))))

(defun geiser-ece--dev-repl-input-sender (process input)
  "Send browser dev REPL INPUT through ece-serve."
  (let ((source (string-trim input)))
    (cond
     ((string-empty-p source)
      (geiser-ece--dev-repl-insert process "ece-dev> "))
     ((member source '(",q" ",quit" "(exit)" "(quit)"))
      (geiser-ece--dev-repl-insert process ";; closing ECE browser REPL\n")
      (delete-process process))
     (t
      (let ((text
             (condition-case err
                 (geiser-ece--dev-repl-result-text
                  (geiser-ece--dev-post "/__ece_dev/eval-source"
                                        source
                                        "repl.scm"
                                        t)
                  "")
               (error (format "Error: %s" (error-message-string err))))))
        (geiser-ece--dev-repl-insert
         process
         (concat (unless (string-empty-p text)
                   (concat text "\n"))
                 "ece-dev> ")))))))

(define-derived-mode geiser-ece-dev-repl-mode comint-mode "ECE-Browser-REPL"
  "REPL mode for evaluating ECE forms in the browser through ece-serve."
  (setq-local comint-prompt-regexp "^ece-dev> ")
  (setq-local comint-input-sender #'geiser-ece--dev-repl-input-sender)
  (setq-local comint-process-echoes nil)
  (geiser-ece--associate-geiser-buffer
   (current-buffer)
   (geiser-ece--live-geiser-repl-buffer geiser-ece-dev--source-buffer))
  (geiser-ece--setup-completion)
  (geiser-ece--setup-eldoc))

(defun geiser-ece--dev-repl-process (buffer)
  "Create the backing process for browser dev REPL BUFFER."
  (if (fboundp 'make-pipe-process)
      (make-pipe-process :name "ece-browser-repl"
                         :buffer buffer
                         :noquery t)
    (start-process "ece-browser-repl" buffer "cat")))

(defun geiser-ece--dev-repl-buffer ()
  "Return the ECE browser dev REPL buffer, creating it if needed."
  (require 'comint)
  (let* ((buffer (get-buffer-create geiser-ece-dev-repl-buffer))
         (process (get-buffer-process buffer)))
    (unless (and process (process-live-p process))
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (erase-buffer))
        (let ((proc (geiser-ece--dev-repl-process buffer)))
          (set-marker (process-mark proc) (point-min))
          (geiser-ece-dev-repl-mode)
          (let ((inhibit-read-only t))
            (insert (format ";; connected to %s\n" (geiser-ece--dev-server-url)))
            (insert ";; evals run in the connected browser runtime\n")
            (insert "ece-dev> ")
            (set-marker (process-mark proc) (point))))))
    buffer))

;;;###autoload
(defun geiser-ece-dev-repl ()
  "Open an ece-serve browser REPL using the current dev connection."
  (interactive)
  (geiser-ece--dev-require-connected)
  (pop-to-buffer (geiser-ece--dev-repl-buffer)))

(defun geiser-ece--dev-entry-file-p (path)
  "Return non-nil when PATH is a usable ece-serve entry source file."
  (and path
       (file-regular-p path)
       (string-match-p "\\.scm\\'" path)))

(defun geiser-ece--dev-read-entry-file ()
  "Read and validate an ece-serve entry source file path."
  (let ((entry-file (read-file-name
                     "ECE entry .scm file: "
                     nil nil t
                     (when buffer-file-name
                       (file-name-nondirectory buffer-file-name))
                     #'geiser-ece--dev-entry-file-p)))
    (unless (geiser-ece--dev-entry-file-p entry-file)
      (error "ECE dev entry must be a regular .scm file, not a directory"))
    entry-file))

(defun geiser-ece--dev-current-entry-file ()
  "Return the current buffer's file as an ece-serve entry file."
  (unless buffer-file-name
    (error "Current buffer is not visiting an ECE .scm file"))
  (unless (geiser-ece--dev-entry-file-p buffer-file-name)
    (error "Current buffer is not visiting an ECE .scm file"))
  buffer-file-name)

(defun geiser-ece--dev-project-file-p (path)
  "Return non-nil when PATH is a usable ECE project file."
  (and path
       (file-regular-p path)
       (string= (file-name-nondirectory path)
                geiser-ece-dev-project-file-name)))

(defun geiser-ece--dev-current-project-file ()
  "Return the nearest ECE project file for the current buffer, or nil."
  (when buffer-file-name
    (let ((root (locate-dominating-file buffer-file-name
                                        geiser-ece-dev-project-file-name)))
      (when root
        (let ((project-file
               (expand-file-name geiser-ece-dev-project-file-name root)))
          (when (geiser-ece--dev-project-file-p project-file)
            project-file))))))

(defun geiser-ece--dev-read-project-file ()
  "Read and validate an ECE project file path."
  (let ((project-file
         (read-file-name
          "ECE project file: "
          nil nil t
          geiser-ece-dev-project-file-name
          #'geiser-ece--dev-project-file-p)))
    (unless (geiser-ece--dev-project-file-p project-file)
      (error "ECE project file must be named %s"
             geiser-ece-dev-project-file-name))
    project-file))

(defun geiser-ece--dev-session-files ()
  "Return readable ece-serve local attach session files."
  (let ((dir (expand-file-name geiser-ece-dev-session-directory)))
    (when (file-directory-p dir)
      (cl-remove-if-not
       #'file-readable-p
       (directory-files dir t "\\.sexp\\'")))))

(defun geiser-ece--dev-read-session (path)
  "Read and validate an ece-serve local attach session from PATH."
  (let ((session
         (condition-case err
             (let ((read-eval nil))
               (with-temp-buffer
                 (insert-file-contents path)
                 (goto-char (point-min))
                 (read (current-buffer))))
           (error
            (error "Could not read ece-serve session file %s: %s"
                   path (error-message-string err))))))
    (unless (and (consp session)
                 (equal (cdr (assoc "type" session)) "ece-serve-session"))
      (error "Not an ece-serve session file: %s" path))
    (let ((url (cdr (assoc "url" session)))
          (token (cdr (assoc "token" session))))
      (unless (and (stringp url)
                   (not (string-empty-p url))
                   (stringp token)
                   (not (string-empty-p token)))
        (error "Invalid ece-serve session file: %s" path))
      session)))

(defun geiser-ece--dev-session-get (session key)
  "Return string KEY from ece-serve attach SESSION."
  (or (cdr (assoc key session))
      (cdr (assq (intern key) session))))

(defun geiser-ece--dev-session-file-candidates (session)
  "Return local session file candidates advertised by discovery SESSION."
  (let* ((session-file (geiser-ece--dev-session-get session "session-file"))
         (entry (geiser-ece--dev-session-get session "entry"))
         (port (geiser-ece--dev-session-get session "port"))
         (candidates '()))
    (when (and (stringp session-file)
               (not (string-empty-p session-file)))
      (push session-file candidates)
      (when (and (not (file-name-absolute-p session-file))
                 (stringp entry)
                 (not (string-empty-p entry)))
        (push (expand-file-name session-file
                                (file-name-directory
                                 (expand-file-name entry)))
              candidates)))
    (when (integerp port)
      (push (expand-file-name
             (format "%s.sexp" port)
             geiser-ece-dev-session-directory)
            candidates))
    (delete-dups (delq nil (nreverse candidates)))))

(defun geiser-ece--dev-search-session-file (port)
  "Search nearby project roots for ece-serve session file PORT."
  (when (integerp port)
    (let* ((file-name (format "%s.sexp" port))
           (git-root (locate-dominating-file default-directory ".git"))
           (roots (delete-dups
                   (delq nil (list default-directory git-root)))))
      (catch 'found
        (dolist (root roots)
          (dolist (dir (geiser-ece--dev-session-search-dirs root))
            (let ((path (expand-file-name file-name dir)))
              (when (file-readable-p path)
                (throw 'found path)))))
        nil))))

(defun geiser-ece--dev-session-search-dirs (root)
  "Return bounded app-local session directories under ROOT."
  (let ((direct (expand-file-name ".tmp/ece-serve-sessions" root))
        (dirs '()))
    (when (file-directory-p direct)
      (push direct dirs))
    (when (file-directory-p root)
      (dolist (entry (ignore-errors (directory-files root t "\\`[^.]")))
        (let ((candidate
               (expand-file-name ".tmp/ece-serve-sessions" entry)))
          (when (file-directory-p candidate)
            (push candidate dirs)))))
    (delete-dups (nreverse dirs))))

(defun geiser-ece--dev-normalize-session (session source)
  "Validate and return ece-serve attach SESSION from SOURCE."
  (unless (and (consp session)
               (equal (geiser-ece--dev-session-get session "type")
                      "ece-serve-session"))
    (error "Not an ece-serve session response: %s" source))
  (let ((url (geiser-ece--dev-session-get session "url"))
        (token (geiser-ece--dev-session-get session "token")))
    (cond
     ((and (stringp url)
           (not (string-empty-p url))
           (stringp token)
           (not (string-empty-p token)))
      session)
     ((and (stringp url)
           (not (string-empty-p url)))
      (let ((path (or (cl-find-if #'file-readable-p
                                  (geiser-ece--dev-session-file-candidates session))
                      (geiser-ece--dev-search-session-file
                       (geiser-ece--dev-session-get session "port")))))
        (unless path
          (error "ece-serve session discovery did not include a readable token file: %s"
                 (mapconcat #'identity
                            (geiser-ece--dev-session-file-candidates session)
                            ", ")))
        (geiser-ece--dev-read-session path)))
     (t
      (error "Invalid ece-serve session response: %s" source)))))

(defun geiser-ece--dev-session-label (path)
  "Return a completion label for ece-serve session file PATH."
  (condition-case nil
      (let* ((session (geiser-ece--dev-read-session path))
             (port (geiser-ece--dev-session-get session "port"))
             (entry (geiser-ece--dev-session-get session "entry"))
             (url (geiser-ece--dev-session-get session "url")))
        (format "%s  %s  %s"
                (or port (file-name-base path))
                url
                (or entry "")))
    (error (file-name-nondirectory path))))

(defun geiser-ece--dev-select-session-file ()
  "Return an ece-serve session file selected for attach."
  (let ((files (geiser-ece--dev-session-files)))
    (cond
     ((null files)
      (read-file-name "ECE session file: "
                      geiser-ece-dev-session-directory nil t nil
                      (lambda (path)
                        (and (file-regular-p path)
                             (string-match-p "\\.sexp\\'" path)))))
     ((null (cdr files)) (car files))
     (t
      (let* ((choices
              (mapcar (lambda (path)
                        (cons (geiser-ece--dev-session-label path) path))
                      files))
             (label (completing-read "ECE session: " choices nil t)))
        (cdr (assoc label choices)))))))

(defun geiser-ece--dev-apply-session (session)
  "Apply ece-serve attach SESSION settings to the current Emacs session."
  (geiser-ece--dev-set-server-url
   (string-remove-suffix "/" (geiser-ece--dev-session-get session "url")))
  (geiser-ece--dev-set-server-token
   (geiser-ece--dev-session-get session "token"))
  (when (integerp (geiser-ece--dev-session-get session "port"))
    (geiser-ece--dev-set-server-port
     (geiser-ece--dev-session-get session "port")))
  (setq geiser-ece-dev--server-ready t)
  (setq geiser-ece-dev--source-buffer (current-buffer))
  (setq geiser-ece-dev--entry-file
        (geiser-ece--dev-session-get session "entry"))
  (geiser-ece-dev-mode 1)
  (geiser-ece--dev-schedule-geiser-integration
   (current-buffer)
   geiser-ece-dev--entry-file))

(defun geiser-ece--dev-json-get (url)
  "GET URL and return its JSON response as an alist."
  (require 'url)
  (require 'json)
  (let ((buffer
         (condition-case err
             (url-retrieve-synchronously url t t 5)
           (error
            (error "ece-serve session discovery failed at %s: %s"
                   url (error-message-string err))))))
    (unless buffer
      (error "ece-serve did not respond at %s" url))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (let ((ok (looking-at "HTTP/[0-9.]+ 2[0-9][0-9]"))
                (status (buffer-substring-no-properties
                         (line-beginning-position)
                         (line-end-position))))
            (unless (re-search-forward "\r?\n\r?\n" nil t)
              (error "ece-serve session discovery failed at %s: malformed HTTP response: %s"
                     url
                     (string-trim
                      (buffer-substring-no-properties
                       (point-min) (min (point-max) (+ (point-min) 200))))))
            (let ((json-object-type 'alist)
                  (json-array-type 'list)
                  (json-false :false))
              (let* ((body-start (point))
                     (payload
                      (condition-case nil
                          (json-read)
                        (error nil)))
                     (body
                      (string-trim
                       (buffer-substring-no-properties
                        body-start (min (point-max) (+ body-start 300))))))
                (unless ok
                  (let ((err (or (cdr (assq 'error payload))
                                 (and (> (length body) 0) body)
                                 status)))
                    (error "ece-serve session discovery failed: %s" err)))
                (unless payload
                  (error "ece-serve session discovery failed at %s: non-JSON response: %s"
                         url body))
                payload))))
      (kill-buffer buffer))))

(defun geiser-ece--dev-discovery-url (host port)
  "Return the session discovery URL for HOST and PORT.
HOST may be a bare host, a host:port pair, or a full http(s) URL."
  (let ((target (string-trim host))
        (port (or port geiser-ece-dev-server-port)))
    (cond
     ((string-match "\\`\\(https?://[^/:]+\\)/?\\'" target)
      (format "%s:%s/__ece_dev/session" (match-string 1 target) port))
     ((string-match-p "\\`https?://" target)
      (concat (string-remove-suffix "/" target) "/__ece_dev/session"))
     ((string-match "\\`\\([^/:]+\\):\\([0-9]+\\)\\'" target)
      (format "http://%s:%s/__ece_dev/session"
              (match-string 1 target)
              (match-string 2 target)))
     (t
      (format "http://%s:%s/__ece_dev/session" target port)))))

(defun geiser-ece--dev-target-includes-port-p (target)
  "Return non-nil when TARGET already includes an ece-serve port."
  (let ((target (string-trim target)))
    (or (string-match-p "\\`https?://.+:[0-9]+\\(?:/.*\\)?\\'" target)
        (string-match-p "\\`[^/:]+:[0-9]+\\'" target))))

(defun geiser-ece--dev-discover-session (host port)
  "Fetch ece-serve session metadata from HOST and PORT."
  (let ((url (geiser-ece--dev-discovery-url host port)))
    (geiser-ece--dev-normalize-session
     (geiser-ece--dev-json-get url)
     url)))

;;;###autoload
(defun geiser-ece-dev-connect (host port &optional token)
  "Connect to ece-serve on HOST and PORT for live browser development.
When TOKEN is non-nil, treat HOST as a full URL and configure manually."
  (interactive
   (let* ((target (read-string "ece-serve host or URL: " "127.0.0.1:8080"))
          (port (unless (geiser-ece--dev-target-includes-port-p target)
                  (read-number "ece-serve port: " 8080))))
     (list target port)))
  (if token
      (progn
        (geiser-ece--dev-set-server-url (string-remove-suffix "/" host))
        (geiser-ece--dev-set-server-token token)
        (setq geiser-ece-dev--server-ready t)
        (setq geiser-ece-dev--source-buffer (current-buffer))
        (setq geiser-ece-dev--entry-file buffer-file-name)
        (geiser-ece-dev-mode 1)
        (geiser-ece--dev-schedule-geiser-integration
         (current-buffer)
         geiser-ece-dev--entry-file)
        (message "ECE dev connected to %s" geiser-ece-dev-server-url))
    (let ((session (geiser-ece--dev-discover-session host port)))
      (geiser-ece--dev-apply-session session)
      (message "ECE dev connected to %s" geiser-ece-dev-server-url))))

;;;###autoload
(defun geiser-ece-dev-connect-repl (host port)
  "Connect to ece-serve on HOST and PORT, then open a browser REPL.
This is the Figwheel-style attach path: start ece-serve separately, open the
site in a browser, then run this command from Emacs."
  (interactive
   (let* ((target (read-string "ece-serve host or URL: " "127.0.0.1:8080"))
          (port (unless (geiser-ece--dev-target-includes-port-p target)
                  (read-number "ece-serve port: " 8080))))
     (list target port)))
  (geiser-ece-dev-connect host port)
  (geiser-ece-dev-repl))

;;;###autoload
(defun geiser-ece-dev-connect-manual (url token)
  "Set the ece-serve URL and dev TOKEN manually."
  (interactive
   (let ((url (read-string "ece-serve URL: " geiser-ece-dev-server-url)))
     (list url
           (read-passwd "ece-serve dev token: "
                        nil
                        geiser-ece-dev-server-token))))
  (geiser-ece-dev-connect url nil token))

;;;###autoload
(defun geiser-ece-dev-attach (&optional session-file)
  "Attach to an existing ece-serve process via its local SESSION-FILE.
Interactively, use the only session in `geiser-ece-dev-session-directory', or
prompt when there are several. This configures the dev URL/token without
displaying or prompting for the token."
  (interactive)
  (let* ((path (or session-file (geiser-ece--dev-select-session-file)))
         (session (geiser-ece--dev-read-session path)))
    (geiser-ece--dev-apply-session session)
    (message "ECE dev attached to %s" geiser-ece-dev-server-url)))

;;;###autoload
(defun geiser-ece-dev-status ()
  "Show current ece-serve live browser development settings."
  (interactive)
  (message "ECE dev URL: %s; token: %s"
           (or (geiser-ece--dev-server-url) "unset")
           (if (geiser-ece--dev-server-token)
               "set"
             "unset")))

;;;###autoload
(defun geiser-ece-dev-open-browser ()
  "Open the configured ece-serve URL in a browser."
  (interactive)
  (require 'browse-url)
  (browse-url (geiser-ece--dev-server-base-url)))

(defun geiser-ece--dev-start-process (args listen-port)
  "Start ece-serve with ARGS and configure process integration."
  (when (geiser-ece--dev-server-live-p)
    (error "ece-serve is already running; use geiser-ece-dev-stop first"))
  (let ((binary (geiser-ece--dev-server-binary)))
    (unless binary
      (error "Could not find ece-serve; build ECE or customize geiser-ece-binary"))
    (let ((buffer (get-buffer-create geiser-ece-dev-server-buffer)))
      (setq geiser-ece-dev--pending-url nil)
      (setq geiser-ece-dev--pending-token nil)
      (setq geiser-ece-dev--startup-output nil)
      (setq geiser-ece-dev--server-ready nil)
      (geiser-ece--dev-clear-ready-callbacks)
      (setq geiser-ece-dev--source-buffer (current-buffer))
      (setq geiser-ece-dev--entry-file (expand-file-name entry-file))
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
(defun geiser-ece-dev-start (entry-file &optional port)
  "Start ece-serve for ENTRY-FILE and configure browser dev integration.
When PORT is nil, use `geiser-ece-dev-server-port'. Interactively, a prefix
argument prompts for the port. The dev token is generated by ece-serve and
parsed from its startup output."
  (interactive
   (let ((entry-file (geiser-ece--dev-read-entry-file)))
     (list entry-file
           (when current-prefix-arg
             (read-number "ECE dev server port: "
                          geiser-ece-dev-server-port)))))
  (unless (geiser-ece--dev-entry-file-p entry-file)
    (error "ECE dev entry must be a regular .scm file, not a directory"))
  (let* ((listen-port (or port geiser-ece-dev-server-port))
         (args (list (expand-file-name entry-file)
                     "--port" (number-to-string listen-port)
                     "--poll-interval"
                     (number-to-string geiser-ece-dev-poll-interval-ms))))
    (geiser-ece--dev-start-process args listen-port)))

;;;###autoload
(defun geiser-ece-dev-start-project (project-file &optional port)
  "Start ece-serve for PROJECT-FILE and configure browser dev integration."
  (interactive
   (let ((project-file (geiser-ece--dev-read-project-file)))
     (list project-file
           (when current-prefix-arg
             (read-number "ECE dev server port: "
                          geiser-ece-dev-server-port)))))
  (unless (geiser-ece--dev-project-file-p project-file)
    (error "ECE project file must be named %s"
           geiser-ece-dev-project-file-name))
  (let* ((listen-port (or port geiser-ece-dev-server-port))
         (args (list "--project" (expand-file-name project-file)
                     "--port" (number-to-string listen-port)
                     "--poll-interval"
                     (number-to-string geiser-ece-dev-poll-interval-ms))))
    (geiser-ece--dev-start-process args listen-port)))

;;;###autoload
(defun geiser-ece-dev-start-repl (entry-file &optional port)
  "Start ece-serve for ENTRY-FILE, open the site, and open a browser REPL.
The REPL evals forms in the browser runtime through ece-serve. The browser must
connect before evals can return results; this command opens the configured URL
after ece-serve reports its dev URL and token."
  (interactive
   (let ((entry-file (geiser-ece--dev-read-entry-file)))
     (list entry-file
           (when current-prefix-arg
             (read-number "ECE dev server port: "
                          geiser-ece-dev-server-port)))))
  (geiser-ece-dev-start entry-file port)
  (geiser-ece--dev-after-ready
   (lambda ()
     (geiser-ece-dev-open-browser)
     (geiser-ece-dev-repl))))

;;;###autoload
(defun geiser-ece-dev-start-project-repl (project-file &optional port)
  "Start ece-serve for PROJECT-FILE, open the site, and open a browser REPL."
  (interactive
   (let ((project-file (geiser-ece--dev-read-project-file)))
     (list project-file
           (when current-prefix-arg
             (read-number "ECE dev server port: "
                          geiser-ece-dev-server-port)))))
  (geiser-ece-dev-start-project project-file port)
  (geiser-ece--dev-after-ready
   (lambda ()
     (geiser-ece-dev-open-browser)
     (geiser-ece-dev-repl))))

;;;###autoload
(defun geiser-ece-dev-start-current-file (&optional port)
  "Start ece-serve for the current ECE project or .scm file.
With a prefix argument, prompt for the port."
  (interactive
   (list (when current-prefix-arg
           (read-number "ECE dev server port: "
                        geiser-ece-dev-server-port))))
  (let ((project-file (geiser-ece--dev-current-project-file)))
    (if project-file
        (geiser-ece-dev-start-project project-file port)
      (geiser-ece-dev-start (geiser-ece--dev-current-entry-file) port))))

;;;###autoload
(defun geiser-ece-dev-jack-in (&optional port)
  "Start ece-serve for the current project or .scm file, then open REPL.
This is the one-command app startup path: if an `ece.project' file is found
above the current buffer, it supplies the entry/static roots. Otherwise the
current `.scm' file is treated as the entry file. With a prefix argument, prompt
for the port."
  (interactive
   (list (when current-prefix-arg
           (read-number "ECE dev server port: "
                        geiser-ece-dev-server-port))))
  (let ((project-file (geiser-ece--dev-current-project-file)))
    (if project-file
        (geiser-ece-dev-start-project-repl project-file port)
      (geiser-ece-dev-start-repl (geiser-ece--dev-current-entry-file) port))))

;;;###autoload
(defun geiser-ece-dev-stop ()
  "Stop the ece-serve process started by `geiser-ece-dev-start'."
  (interactive)
  (if (geiser-ece--dev-server-live-p)
      (progn
        (delete-process geiser-ece-dev--server-process)
        (setq geiser-ece-dev--server-process nil)
        (unless geiser-ece-dev--server-ready
          (geiser-ece--dev-clear-ready-callbacks))
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
(defun geiser-ece-dev-reload-entry ()
  "Save the current file and force ece-serve to rebuild/reload the entry app."
  (interactive)
  (unless buffer-file-name
    (error "Current buffer is not visiting a file"))
  (when (buffer-modified-p)
    (save-buffer))
  (geiser-ece--dev-display-result
   (geiser-ece--dev-post "/__ece_dev/reload-entry"
                         ""
                         buffer-file-name
                         nil)
   "Requested ece-serve app rebuild/reload"))

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
    (define-key map (kbd "C-c C-z R") #'geiser-ece-dev-start-repl)
    (define-key map (kbd "C-c C-z J") #'geiser-ece-dev-jack-in)
    (define-key map (kbd "C-c C-z K") #'geiser-ece-dev-stop)
    (define-key map (kbd "C-c C-z c") #'geiser-ece-dev-connect)
    (define-key map (kbd "C-c C-z C") #'geiser-ece-dev-connect-repl)
    (define-key map (kbd "C-c C-z a") #'geiser-ece-dev-attach)
    (define-key map (kbd "C-c C-z o") #'geiser-ece-dev-open-browser)
    (define-key map (kbd "C-c C-z ?") #'geiser-ece-dev-status)
    (define-key map (kbd "C-c C-z z") #'geiser-ece-dev-repl)
    (define-key map (kbd "C-c C-z e") #'geiser-ece-dev-eval-last-sexp)
    (define-key map (kbd "C-c C-z r") #'geiser-ece-dev-eval-region)
    (define-key map (kbd "C-c C-z d") #'geiser-ece-dev-eval-definition)
    (define-key map (kbd "C-c C-z b") #'geiser-ece-dev-load-buffer)
    (define-key map (kbd "C-c C-z l") #'geiser-ece-dev-reload-file)
    (define-key map (kbd "C-c C-z k") #'geiser-ece-dev-reload-entry)
    (define-key map (kbd "C-c C-z s") #'geiser-ece-dev-save-buffer-and-reload)
    (define-key map [remap geiser-eval-last-sexp]
                #'geiser-ece-dev-eval-last-sexp)
    (define-key map [remap geiser-eval-definition]
                #'geiser-ece-dev-eval-definition)
    (define-key map [remap geiser-eval-region]
                #'geiser-ece-dev-eval-region)
    (define-key map [remap geiser-eval-buffer]
                #'geiser-ece-dev-load-buffer)
    (define-key map [remap geiser-load-current-buffer]
                #'geiser-ece-dev-reload-entry)
    (define-key map [remap geiser-compile-current-buffer]
                #'geiser-ece-dev-reload-entry)
    (define-key map [remap geiser-load-file]
                #'geiser-ece-dev-reload-entry)
    (define-key map [remap geiser-compile-file]
                #'geiser-ece-dev-reload-entry)
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
