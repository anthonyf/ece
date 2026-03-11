(require :asdf)

(in-package :asdf-user)


(initialize-source-registry
 '(:source-registry
   (:tree (:here))
   :inherit-configuration))

(defsystem "ece"
    :version "0.1.0"
    :author "Anthony Fairchild"
    :license "MIT"
    :description "A Scheme-like language with serializable continuations and full TCO"
    :depends-on ()
    :serial t
    :components ((:module "src"
                          :components
                          ((:file "runtime")
                           (:file "boot" :depends-on ("runtime"))
                           (:static-file "prelude.scm"))))
    :in-order-to ((test-op (test-op "ece/tests"))))

(defsystem "ece/cold"
    :description "Cold-boot ECE from source (for bootstrap image generation)"
    :serial t
    :components ((:module "src"
                          :components
                          ((:file "runtime")
                           (:file "compiler" :depends-on ("runtime"))
                           (:static-file "prelude.scm")
                           (:static-file "compaction.scm")))))

(defsystem "ece/tests"
    :author ""
    :license ""
    :depends-on ("rove")
    :description "Test system for ece"
    :components ((:module "tests"
                          :components ((:file "ece"))))
    :perform (test-op (op c) (symbol-call :rove :run c)))
