;;; ECE Assembler
;;; Pure per-code-object assembly. Each call writes into a fresh code-object;
;;; no shared state. Paired with `mc-compile-to-code-object` in the compiler.

;; Pure assembler — writes into a code-object, no shared state. Returns the
;; same code-object it was handed for chaining.
(define (assemble-into-code-object co instruction-list)
  (for-each
   (lambda (item)
     (cond
      ;; Labels are symbols — register at the current local PC.
      ((symbol? item)
       (%code-object-set-label! co item (code-object-length co)))
      ;; Pseudo-instructions whose effects now flow through the code-object
      ;; directly (set via %code-object-set-name!/arity! in the compiler).
      ((and (pair? item) (eq? (car item) 'procedure-name)) #f)
      ((and (pair? item) (eq? (car item) 'procedure-params)) #f)
      ;; Source-location markers are stripped by the compiler before we see them.
      ((and (pair? item) (eq? (car item) 'source-location)) #f)
      ;; Regular instruction — push to the code-object's vectors.
      (else
       (%code-object-push-instruction! co item))))
   instruction-list)
  co)

;; Redefine load to use the ECE reader + ECE compiler pipeline.
;; §5.2: each top-level form compiles to a fresh code-object via
;; mc-compile-and-go. No shared space is created per file any more.
(define (load filename)
  (let ((port (open-input-file filename)))
    (let loop ((result '()))
      (let ((expr (ece-scheme-read port)))
        (if (eof? expr)
            (begin
              (close-input-port port)
              result)
            (loop (mc-compile-and-go expr)))))))
