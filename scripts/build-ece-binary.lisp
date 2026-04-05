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

(sb-ext:save-lisp-and-die
 "bin/ece"
 :executable t
 :compression nil
 :save-runtime-options t
 :toplevel
 (lambda ()
   (ece:evaluate
    '(begin
      (load-bundle (string-append (ece-home) "/ece-main.ecec"))
      (ece-main (command-line))))))
