;;; Tests for `mc-compile-to-code-object` — the pure compile entry point.
;;;
;;; CL-only during the coexistence phase because the WASM runtime stubs
;;; %code-object-push-instruction! (real storage arrives with the executor
;;; switch in §6). The CL runtime has a complete implementation, so the
;;; full contract is exercised here.

(test "mc-compile-to-code-object returns a code-object" (lambda ()
  (let ((co (mc-compile-to-code-object 42)))
    (assert-equal #t (code-object? co)))))

(test "fresh code-object per call (not shared)" (lambda ()
  (let ((a (mc-compile-to-code-object 1))
        (b (mc-compile-to-code-object 2)))
    (assert-equal #f (eq? a b)))))

(test "instructions end with (halt)" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (instrs (code-object-instructions co))
         (last (vector-ref instrs (- (code-object-length co) 1))))
    (assert-equal '(halt) last))))

(test "source instructions include an assignment for a literal" (lambda ()
  (let* ((co (mc-compile-to-code-object 42))
         (len (code-object-length co)))
    ;; Expect at least one instruction before the halt.
    (assert-equal #t (> len 1)))))

(test "compiled lambda contains make-compiled-procedure" (lambda ()
  (let* ((co (mc-compile-to-code-object '(lambda (x) (+ x 1))))
         (instrs (code-object-instructions co))
         (len (code-object-length co))
         (found #f))
    (let loop ((i 0))
      (when (< i len)
        (let ((instr (vector-ref instrs i)))
          (when (and (pair? instr)
                     (eq? (car instr) 'assign)
                     (pair? (caddr instr))
                     (eq? (car (caddr instr)) 'op)
                     (eq? (cadr (caddr instr)) 'make-compiled-procedure))
            (set! found #t)))
        (loop (+ i 1))))
    (assert-equal #t found))))

(test "labels registered in code-object's label table" (lambda ()
  (let* ((co (mc-compile-to-code-object '(if #t 1 2)))
         (entries (code-object-label-entries co)))
    ;; if/then/else generates labels; table should be non-empty.
    (assert-equal #t (pair? entries)))))

(test "pure compile does not mutate current space" (lambda ()
  (let* ((sid (%current-space-id))
         (before (%space-instruction-length sid)))
    (mc-compile-to-code-object '(+ 1 2))
    (let ((after (%space-instruction-length sid)))
      (assert-equal before after)))))

(test "idempotence: same expr yields same shape" (lambda ()
  ;; Labels gensym globally, so instruction lists aren't equal? across
  ;; runs. The structural contract: distinct objects, same instruction
  ;; count, same number of labels.
  (let* ((expr '(if (> x 0) (+ x 1) (- x 1)))
         (a (mc-compile-to-code-object expr))
         (b (mc-compile-to-code-object expr)))
    (assert-equal #f (eq? a b))
    (assert-equal (code-object-length a) (code-object-length b))
    (assert-equal (length (code-object-label-entries a))
                  (length (code-object-label-entries b))))))

(test "assemble-into-code-object returns the object it was given" (lambda ()
  (let* ((co (%make-code-object))
         (result (assemble-into-code-object co '((halt)))))
    (assert-equal #t (eq? co result)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; End-to-end execution via execute-code-object (§6 on CL, coexistence phase).
;;; ─────────────────────────────────────────────────────────────────────────

(test "execute-code-object runs a self-evaluating expression" (lambda ()
  (assert-equal 42 (execute-code-object (mc-compile-to-code-object 42)))))

(test "execute-code-object runs primitive arithmetic" (lambda ()
  (assert-equal 3 (execute-code-object (mc-compile-to-code-object '(+ 1 2))))
  (assert-equal 42 (execute-code-object (mc-compile-to-code-object '(* 6 7))))))

(test "execute-code-object runs nested arithmetic" (lambda ()
  (assert-equal 10 (execute-code-object
                    (mc-compile-to-code-object '(+ (* 2 3) (- 6 2)))))))

(test "execute-code-object runs if/then/else" (lambda ()
  (assert-equal 'yes (execute-code-object
                      (mc-compile-to-code-object '(if (> 3 1) 'yes 'no))))
  (assert-equal 'no (execute-code-object
                     (mc-compile-to-code-object '(if (> 1 3) 'yes 'no))))))

(test "execute-code-object runs a lambda call" (lambda ()
  (assert-equal 5 (execute-code-object
                   (mc-compile-to-code-object '((lambda (x) (+ x 1)) 4))))))

(test "execute-code-object runs let forms" (lambda ()
  (assert-equal 7 (execute-code-object
                   (mc-compile-to-code-object '(let ((x 3) (y 4)) (+ x y)))))))

(test "execute-code-object runs recursive call via letrec" (lambda ()
  ;; Factorial of 5 via letrec — exercises closure + recursion + tail calls.
  (assert-equal 120 (execute-code-object
                     (mc-compile-to-code-object
                      '(letrec ((fact (lambda (n)
                                        (if (= n 0) 1 (* n (fact (- n 1)))))))
                         (fact 5)))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §4.2: bottom-up lambda emission — make-compiled-procedure references
;;; the inner body as a (const <code-object>) operand, not a (label ...).
;;; ─────────────────────────────────────────────────────────────────────────

(test "lambda compile emits (const <code-object>) in bottom-up mode" (lambda ()
  (let* ((co (mc-compile-to-code-object '(lambda (x) (+ x 1))))
         (instrs (code-object-instructions co))
         (len (code-object-length co))
         (found #f))
    (let loop ((i 0))
      (when (< i len)
        (let ((instr (vector-ref instrs i)))
          (when (and (pair? instr)
                     (eq? (car instr) 'assign)
                     (pair? (caddr instr))
                     (eq? (car (caddr instr)) 'op)
                     (eq? (cadr (caddr instr)) 'make-compiled-procedure))
            ;; Inspect the operand after the op — should be (const <code-obj>).
            (let ((entry-operand (cadddr instr)))
              (when (and (pair? entry-operand)
                         (eq? (car entry-operand) 'const)
                         (code-object? (cadr entry-operand)))
                (set! found #t)))))
        (loop (+ i 1))))
    (assert-equal #t found))))

(test "label-based mode still emits (label ...) entry" (lambda ()
  ;; The default mc-compile-and-go path uses the label shape so bootstrap
  ;; and compile-file can serialize to .ecec. Exercised implicitly by the
  ;; whole test suite; here we assert the operand shape explicitly.
  (let* ((seq (mc-compile '(lambda (x) x) 'val 'next))
         (instrs (mc-instructions seq))
         (found #f))
    (for-each (lambda (instr)
                (when (and (pair? instr)
                           (eq? (car instr) 'assign)
                           (pair? (caddr instr))
                           (eq? (car (caddr instr)) 'op)
                           (eq? (cadr (caddr instr)) 'make-compiled-procedure))
                  (let ((entry-operand (cadddr instr)))
                    (when (and (pair? entry-operand)
                               (eq? (car entry-operand) 'label))
                      (set! found #t)))))
              instrs)
    (assert-equal #t found))))

(test "bottom-up lambda: nested lambdas each get their own code-object" (lambda ()
  ;; (lambda (x) (lambda (y) (+ x y))) — inner code-obj references outer env.
  (let* ((co (mc-compile-to-code-object '(lambda (x) (lambda (y) (+ x y)))))
         (outer-instrs (code-object-instructions co))
         (outer-len (code-object-length co))
         (outer-co #f))
    ;; Find the outer make-compiled-procedure's code-object constant.
    (let loop ((i 0))
      (when (< i outer-len)
        (let ((instr (vector-ref outer-instrs i)))
          (when (and (pair? instr)
                     (eq? (car instr) 'assign)
                     (pair? (caddr instr))
                     (eq? (car (caddr instr)) 'op)
                     (eq? (cadr (caddr instr)) 'make-compiled-procedure))
            (let ((entry-operand (cadddr instr)))
              (when (and (pair? entry-operand)
                         (eq? (car entry-operand) 'const)
                         (code-object? (cadr entry-operand)))
                (set! outer-co (cadr entry-operand)))))
          (loop (+ i 1)))))
    ;; The outer code-object body should itself contain a nested make-compiled-procedure
    ;; whose entry is ANOTHER code-object.
    (assert-true outer-co)
    (let* ((inner-instrs (code-object-instructions outer-co))
           (inner-len (code-object-length outer-co))
           (inner-found #f))
      (let loop ((i 0))
        (when (< i inner-len)
          (let ((instr (vector-ref inner-instrs i)))
            (when (and (pair? instr)
                       (eq? (car instr) 'assign)
                       (pair? (caddr instr))
                       (eq? (car (caddr instr)) 'op)
                       (eq? (cadr (caddr instr)) 'make-compiled-procedure))
              (let ((entry-operand (cadddr instr)))
                (when (and (pair? entry-operand)
                           (eq? (car entry-operand) 'const)
                           (code-object? (cadr entry-operand)))
                  (set! inner-found #t)))))
          (loop (+ i 1))))
      (assert-equal #t inner-found)))))

(test "bottom-up lambda: higher-order returns work end-to-end" (lambda ()
  (assert-equal 7 (execute-code-object
                   (mc-compile-to-code-object
                    '((lambda (x) ((lambda (y) (+ x y)) 3)) 4))))
  (assert-equal 25 (execute-code-object
                    (mc-compile-to-code-object
                     '(((lambda (x) (lambda (y) (* x y))) 5) 5))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §4.3/§4.4/§4.5: procedure name & arity flow onto the inner code-object
;;; at compile time in the bottom-up path. No pseudo-instruction needed —
;;; the compiler holds the code-object value in hand.
;;; ─────────────────────────────────────────────────────────────────────────

(define (find-child-code-object co)
  "Return the first code-object referenced as a (const ...) operand of a
make-compiled-procedure instruction inside CO, or #f if none."
  (let ((instrs (code-object-instructions co))
        (len (code-object-length co))
        (found #f))
    (let loop ((i 0))
      (when (< i len)
        (let ((instr (vector-ref instrs i)))
          (when (and (pair? instr)
                     (eq? (car instr) 'assign)
                     (pair? (caddr instr))
                     (eq? (car (caddr instr)) 'op)
                     (eq? (cadr (caddr instr)) 'make-compiled-procedure))
            (let ((operand (cadddr instr)))
              (when (and (pair? operand)
                         (eq? (car operand) 'const)
                         (code-object? (cadr operand))
                         (not found))
                (set! found (cadr operand))))))
        (loop (+ i 1))))
    found))

(test "define threads procedure name onto the inner code-object" (lambda ()
  (let* ((outer (mc-compile-to-code-object '(define (add1 x) (+ x 1))))
         (inner (find-child-code-object outer)))
    (assert-true inner)
    (assert-equal 'add1 (code-object-name inner)))))

(test "define threads arity info onto the inner code-object" (lambda ()
  (let* ((outer (mc-compile-to-code-object '(define (add1 x) (+ x 1))))
         (inner (find-child-code-object outer))
         (arity (code-object-arity inner)))
    ;; extract-lambda-params returns (param-names . rest-flag)
    (assert-true (pair? arity))
    (assert-equal '("x") (car arity))
    (assert-equal 0 (cdr arity)))))

(test "variadic define: arity records rest flag" (lambda ()
  (let* ((outer (mc-compile-to-code-object '(define (f . args) args)))
         (inner (find-child-code-object outer))
         (arity (code-object-arity inner)))
    (assert-true (pair? arity))
    (assert-equal 1 (cdr arity)))))

(test "anonymous lambda: no name threaded" (lambda ()
  (let* ((outer (mc-compile-to-code-object '(lambda (x) x)))
         (inner (find-child-code-object outer)))
    (assert-true inner)
    (assert-equal #f (code-object-name inner)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §6.4: execute-from-pc accepts code-objects and (code-obj . pc) pairs
;;; in addition to the legacy (space-id . pc) shape.
;;; ─────────────────────────────────────────────────────────────────────────

(test "execute-from-pc accepts bare code-object (pc 0 implied)" (lambda ()
  (let ((co (mc-compile-to-code-object '(+ 2 3))))
    (assert-equal 5 (execute-from-pc co)))))

(test "execute-from-pc accepts (code-obj . 0) pair" (lambda ()
  (let ((co (mc-compile-to-code-object '(* 6 7))))
    (assert-equal 42 (execute-from-pc (cons co 0))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §6.5: when a code-object's native-fn slot holds a procedure, the
;;; executor dispatches to it directly (no hash lookup). Populating the
;;; slot is out of scope here; this test just validates plumbing.
;;; ─────────────────────────────────────────────────────────────────────────

(test "default native-fn is #f (dispatch falls through to bytecode)" (lambda ()
  (let ((co (mc-compile-to-code-object '(+ 1 2))))
    (assert-equal #f (code-object-native-fn co))
    ;; Still executable via bytecode path.
    (assert-equal 3 (execute-code-object co)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §7.1/§7.2: code-object-based closures store the code-object directly
;;; in the entry slot (no `(code-obj . 0)` wrapper). compiled-procedure-entry
;;; returns the code-object itself.
;;; ─────────────────────────────────────────────────────────────────────────

(test "closure entry for a bottom-up lambda is a bare code-object" (lambda ()
  ;; Build a closure via (lambda ...) → compile → execute → closure value
  ;; ends up in val. We can't capture that easily, but we can directly
  ;; invoke the returned closure and check its entry.
  (let* ((co (mc-compile-to-code-object '(lambda (x) (+ x 1))))
         (proc (execute-code-object co))
         (entry (compiled-procedure-entry proc)))
    (assert-equal #t (code-object? entry)))))

(test "bottom-up closure invocation works end-to-end" (lambda ()
  ;; The closure stores a bare code-obj; call it and check the body runs.
  (let* ((co (mc-compile-to-code-object '(lambda (x) (* x x))))
         (f (execute-code-object co)))
    (assert-equal 25 (f 5)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §10: disassemble accepts a code-object directly, using the
;;; straightforward iterate-0..length path (no reachability walk).
;;; ─────────────────────────────────────────────────────────────────────────

(test "disassemble on a code-object prints the body" (lambda ()
  (let* ((co (mc-compile-to-code-object '(+ 1 2)))
         (out (with-output-to-string (disassemble co))))
    (assert-true (string-contains? out "code-object"))
    (assert-true (string-contains? out "(assign"))
    ;; Must end in a halt for top-level compile output.
    (assert-true (string-contains? out "(halt)")))))

(test "disassemble on a code-object-backed closure prints the inner body"
  (lambda ()
    (let* ((co (mc-compile-to-code-object '(define (add1 x) (+ x 1))))
           (_ (execute-code-object co))
           (inner (find-child-code-object co))
           (out (with-output-to-string (disassemble inner))))
      (assert-true (string-contains? out "add1"))
      (assert-true (string-contains? out "(assign")))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; §13.5 (partial): regression coverage for common idioms through the
;;; bottom-up pipeline. Kept small so CI cost stays low.
;;; ─────────────────────────────────────────────────────────────────────────

(test "fib(10) via mc-compile-to-code-object: self-recursion" (lambda ()
  (assert-equal 55 (execute-code-object
                    (mc-compile-to-code-object
                     '(letrec ((fib (lambda (n)
                                      (if (< n 2) n
                                          (+ (fib (- n 1)) (fib (- n 2)))))))
                        (fib 10)))))))

(test "mutual recursion: even? / odd?" (lambda ()
  (assert-equal #t (execute-code-object
                    (mc-compile-to-code-object
                     '(letrec ((e? (lambda (n) (if (= n 0) #t (o? (- n 1)))))
                               (o? (lambda (n) (if (= n 0) #f (e? (- n 1))))))
                        (e? 20)))))))

(test "higher-order: map over a small list" (lambda ()
  (assert-equal '(2 4 6 8) (execute-code-object
                            (mc-compile-to-code-object
                             '(map (lambda (x) (* x 2)) '(1 2 3 4)))))))

(test "deep let* chaining (20 bindings)" (lambda ()
  (assert-equal 210 (execute-code-object
                     (mc-compile-to-code-object
                      '(let* ((a 1) (b (+ a 1)) (c (+ b 1)) (d (+ c 1))
                              (e (+ d 1)) (f (+ e 1)) (g (+ f 1))
                              (h (+ g 1)) (i (+ h 1)) (j (+ i 1))
                              (k (+ j 1)) (l (+ k 1)) (m (+ l 1))
                              (n (+ m 1)) (o (+ n 1)) (p (+ o 1))
                              (q (+ p 1)) (r (+ q 1)) (s (+ r 1))
                              (t (+ s 1)))
                         (+ a b c d e f g h i j k l m n o p q r s t)))))))

(test "internal define (body starts with defines)" (lambda ()
  (assert-equal 42 (execute-code-object
                    (mc-compile-to-code-object
                     '((lambda ()
                         (define x 7)
                         (define y 6)
                         (* x y))))))))

(test "call/cc through code-object: escape from loop" (lambda ()
  ;; Simple escape: call/cc returns immediately when the cont is invoked.
  (assert-equal 'escaped
                (execute-code-object
                 (mc-compile-to-code-object
                  '(call/cc (lambda (k) (k 'escaped) 'unreached)))))))

(test "variadic arguments (. rest)" (lambda ()
  (assert-equal '(a b c)
                (execute-code-object
                 (mc-compile-to-code-object
                  '((lambda args args) 'a 'b 'c))))))

(test "parity: same expression via mc-compile-and-go and mc-compile-to-code-object"
  (lambda ()
    ;; Any pure, side-effect-free expression should give the same answer.
    (let ((expr '(+ (* 3 4) (- 10 5))))
      (assert-equal (eval expr)
                    (execute-code-object (mc-compile-to-code-object expr))))))
