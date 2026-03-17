;;; ECE Assembler
;;; Assembles instruction lists into the current compilation space.
;;; Replaces the CL assemble-into-global after bootstrap.

(define (ece-assemble-into-global instruction-list)
  "Append instructions to the current space, register labels. Return start PC."
  (define sid (%current-space-id))
  (define start-pc (%space-instruction-length sid))
  (for-each
   (lambda (item)
     (cond
      ;; Labels are symbols — register in space's label table at current PC
      ((symbol? item)
       (%space-label-set! sid item (%space-instruction-length sid)))
      ;; Pseudo-instruction: (procedure-name <label> <name>)
      ((and (pair? item) (eq? (car item) 'procedure-name))
       (let ((pc (%space-label-ref sid (cadr item))))
         (when pc
           (if (= sid 0)
               (%procedure-name-set! pc (caddr item))
               (%procedure-name-set! (cons sid pc) (caddr item))))))
      ;; Regular instruction — push to space's arrays
      (else
       (%space-instruction-push! sid item))))
   instruction-list)
  (if (= sid 0)
      start-pc
      (cons sid start-pc)))

;; Switchover: rebind assemble-into-global to the ECE implementation.
;; mc-compile-and-go calls assemble-into-global, so this makes it use
;; the ECE assembler for all subsequent compilations.
;; IMPORTANT: This must come BEFORE load redefinition — see note below.
(define assemble-into-global ece-assemble-into-global)

;; Redefine load to use the ECE reader + ECE compiler pipeline.
;; Creates a new compilation space per file and compiles all forms into it.
;; NOTE: Defined AFTER the assembler switchover because forms after
;; (define assemble-into-global ...) in the same file don't execute
;; when reloading assembler.scm (the ECE assembler takes over mid-file
;; and the executor state becomes inconsistent). The load body calls
;; mc-compile-and-go which calls assemble-into-global via env lookup,
;; so it picks up the ECE assembler after the switchover regardless.
(define (load filename)
  (define port (open-input-file filename))
  (define prev-space (%current-space-id))
  (define new-space (%create-space filename))
  (%set-current-space-id! new-space)
  (let loop ((result '()))
    (define expr (ece-scheme-read port))
    (if (eof? expr)
        (begin
          (close-input-port port)
          (%set-current-space-id! prev-space)
          result)
        (loop (mc-compile-and-go expr)))))
