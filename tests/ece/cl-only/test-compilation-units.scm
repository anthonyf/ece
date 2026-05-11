;;; Compilation unit tests — compile-form, execute, serialization, compile-file

;; Helper: write a string to a file using char-by-char output
(define (write-string-to-file filename str)
  (let ((port (open-output-file filename)))
    (define len (string-length str))
    (define (loop i)
      (when (< i len)
        (write-char (string-ref str i) port)
        (loop (+ i 1))))
    (loop 0)
    (close-output-port port)))

;; --- 5.1 compile-form / compiled-unit? / compiled-unit-instructions ---

(test "compile-form returns a compiled unit" (lambda ()
  (let ((unit (compile-form '(+ 1 2))))
    (assert-true (compiled-unit? unit)))))

(test "compiled-unit? rejects non-units" (lambda ()
  (assert-true (not (compiled-unit? 42)))
  (assert-true (not (compiled-unit? '(1 2 3))))
  (assert-true (not (compiled-unit? "hello")))))

(test "compiled-unit-instructions returns a list" (lambda ()
  (let ((unit (compile-form '(+ 1 2))))
    (assert-true (pair? (compiled-unit-instructions unit))))))

(test "compile-form handles definitions" (lambda ()
  (let ((unit (compile-form '(define compile-unit-test-var 99))))
    (assert-true (compiled-unit? unit)))))

;; --- 5.2 execute ---

(test "execute evaluates a simple expression" (lambda ()
  (assert-equal (execute (compile-form '(+ 1 2))) 3)))

(test "execute evaluates complex expressions" (lambda ()
  (assert-equal (execute (compile-form '(* 6 7))) 42)
  (assert-equal (execute (compile-form '(if #t 10 20))) 10)))

(test "execute defines in global environment" (lambda ()
  (execute (compile-form '(define cu-test-x 42)))
  (assert-equal cu-test-x 42)))

(test "execute: sequential units share global env" (lambda ()
  (execute (compile-form '(define cu-test-y 10)))
  (assert-equal (execute (compile-form '(+ cu-test-y 5))) 15)))

(test "execute: lambda and application" (lambda ()
  (execute (compile-form '(define cu-test-double (lambda (n) (* n 2)))))
  (assert-equal (execute (compile-form '(cu-test-double 21))) 42)))

;; --- 5.3 write/read round-trip ---

(test "write-compiled-unit / read-compiled-unit round-trip" (lambda ()
  (let ((unit (compile-form '(+ 1 2))))
    (let ((port (open-output-file ".tmp/ece-cu-roundtrip.ecec")))
      (write-compiled-unit unit port)
      (close-output-port port))
    (let ((port (open-input-file ".tmp/ece-cu-roundtrip.ecec")))
      (let ((loaded (read-compiled-unit port)))
        (close-input-port port)
        (assert-true (compiled-unit? loaded))
        (assert-equal (execute loaded) 3))))))

(test "round-trip with definition" (lambda ()
  (let ((unit (compile-form '(define cu-rt-test-var 42))))
    (let ((port (open-output-file ".tmp/ece-cu-rt-def.ecec")))
      (write-compiled-unit unit port)
      (close-output-port port))
    (let ((port (open-input-file ".tmp/ece-cu-rt-def.ecec")))
      (let ((loaded (read-compiled-unit port)))
        (close-input-port port)
        (assert-true (compiled-unit? loaded))
        (execute loaded)
        (assert-equal cu-rt-test-var 42))))))

(test "read-compiled-unit returns eof on empty" (lambda ()
  (let ((port (open-output-file ".tmp/ece-cu-empty.ecec")))
    (close-output-port port))
  (let ((port (open-input-file ".tmp/ece-cu-empty.ecec")))
    (let ((result (read-compiled-unit port)))
      (close-input-port port)
      (assert-true (eof? result))))))

;; --- 5.4 compile-file / load-compiled ---

(test "compile-file creates output file" (lambda ()
  ;; Write a small source file
  (write-string-to-file ".tmp/ece-cu-src.scm"
    "(define cu-from-file 123)\n(define cu-from-file-2 (* cu-from-file 2))\n")
  ;; Compile it
  (let ((output (compile-file ".tmp/ece-cu-src.scm")))
    (assert-equal output ".tmp/ece-cu-src.ecec"))))

(test "load-compiled executes compiled file" (lambda ()
  ;; Source file already compiled from previous test
  (load-compiled ".tmp/ece-cu-src.ecec")
  (assert-equal cu-from-file 123)
  (assert-equal cu-from-file-2 246)))

(test "compile-file with macros" (lambda ()
  ;; Write a file that defines and uses a macro
  (write-string-to-file ".tmp/ece-cu-macro.scm"
    "(define-macro (cu-test-swap a b) (list b a))\n(define cu-swap-result (cu-test-swap 10 -))\n")
  ;; Compile and load
  (compile-file ".tmp/ece-cu-macro.scm")
  (load-compiled ".tmp/ece-cu-macro.ecec")
  (assert-equal cu-swap-result -10)))

(test "compile-file rejects malformed define-syntax/doc arity" (lambda ()
  (write-string-to-file ".tmp/ece-cu-doc-syntax-bad.scm"
    "(define-syntax/doc bad-syntax \"Bad.\" (syntax-rules () ((_ x) x)) extra)\n")
  (assert-error-message
   (compile-file ".tmp/ece-cu-doc-syntax-bad.scm")
   "define-syntax/doc: expected (define-syntax/doc name doc transformer)")))

;; --- 5.5 equivalence with load ---

(test "load-compiled matches load behavior" (lambda ()
  ;; Write a source file
  (write-string-to-file ".tmp/ece-cu-equiv.scm"
    "(define cu-equiv-a 100)\n(define cu-equiv-b (+ cu-equiv-a 50))\n")
  ;; Compile and load
  (compile-file ".tmp/ece-cu-equiv.scm")
  (load-compiled ".tmp/ece-cu-equiv.ecec")
  ;; Check same as what load would produce
  (assert-equal cu-equiv-a 100)
  (assert-equal cu-equiv-b 150)))
