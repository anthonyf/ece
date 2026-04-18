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
