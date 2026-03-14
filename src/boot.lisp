(in-package :ece)

;;;; ========================================================================
;;;; BOOT — Load bootstrap image and provide evaluate/repl without compiler.lisp
;;;; ========================================================================

;;; Load the bootstrap image at ASDF load time
(ece-load-image (asdf:system-relative-pathname :ece "bootstrap/ece.image"))

;;; Expose *global-env* as an ECE variable so mc-compile-define-macro can reference it.
;;; The CL compiler handled define-macro directly using the CL defvar; the mc-compiler
;;; needs it as an ECE variable.
(define-variable! '*global-env* *global-env* *global-env*)

;;; evaluate: compile and execute EXPR via the metacircular compiler in the image.
;;; Matches the compiler.lisp signature exactly: (evaluate expr &optional env)
(defun evaluate (expr &optional (env *global-env* env-supplied-p))
  "Compile and execute EXPR in ENV using the metacircular compiler."
  (if env-supplied-p
      (mc-eval expr env)
      (mc-eval expr)))

;;; ece-try-eval: error-handling wrapper around evaluate.
;;; The image's (primitive ece-try-eval) binding resolves to this via symbol-function.
(defun ece-try-eval (expr)
  "Evaluate expr, catching errors. Prints the error and returns the EOF sentinel on failure."
  (handler-case
      (evaluate expr)
    (error (c)
      (format t "Error: ~A~%" c)
      (finish-output)
      *eof-sentinel*)))

;;; REPL: compile and run the REPL loop via the metacircular compiler.
(defun repl ()
  "Start the ECE REPL."
  (evaluate
   '(begin
     (define (repl-loop)
      (display "ece> ")
      (define input (read))
      (if (eof? input)
          (begin (newline) (display "Bye!") (newline))
          (begin
           (define result (try-eval input))
           (if (not (eof? result)) (begin (write result) (newline)) (quote ()))
           (repl-loop))))
     (repl-loop))))
