(require :asdf)

(in-package :asdf-user)


(initialize-source-registry
 '(:source-registry
   (:tree (:here))
   :inherit-configuration))

(defsystem "ece"
  :version "0.1.0"
  :author ""
  :license ""
  :description ""
  :depends-on ("uiop"
	       "alexandria")
  :serial t
  :components ((:module "src"
		:components
		((:file "main"))))
  :in-order-to ((test-op (test-op "ece/tests"))))

(defsystem "ece/tests"
  :author ""
  :license ""
  :depends-on ("rove")
  :description "Test system for ece"
  :components ((:module "tests"
		:components ((:file "main"))))
  :perform (test-op (op c) (symbol-call :rove :run c)))
