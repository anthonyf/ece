;; Format a Scheme file using standard Scheme indentation.
;; Usage: emacs --batch file.scm --load scripts/scheme-indent.el

(scheme-mode)
(setq indent-tabs-mode nil)
(setq make-backup-files nil)
(indent-region (point-min) (point-max))
(untabify (point-min) (point-max))
(save-buffer)
