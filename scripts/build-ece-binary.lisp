;;; build-ece-binary.lisp — Build the `bin/ece` native binary.
;;;
;;; Run via: qlot exec sbcl --non-interactive --load scripts/build-ece-binary.lisp
;;;
;;; All logic lives in ECE. This script's job is only to:
;;;   1. Load :ece (which boots the VM from bootstrap.ecec)
;;;   2. Invoke save-lisp-and-die with a minimal :toplevel shim that calls
;;;      ece-main on argv after loading $ECE_HOME/ece-main.ecec.

(asdf:load-system :ece)

(in-package :ece)

;; Bake ece-main into the image so startup is instant (same pattern as bootstrap).
(ece:evaluate
 (ece::downcase-ece-symbols
  '(load-bundle "share/ece/ece-main.ecec")))

(sb-ext:save-lisp-and-die
 "bin/ece"
 :executable t
 :compression nil
 :save-runtime-options t
 :toplevel
 (lambda ()
   (ece:evaluate
    '(ece-main (command-line)))))
