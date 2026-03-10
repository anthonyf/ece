;;; ECE Assembler
;;; Assembles instruction lists into the global instruction vector.
;;; Replaces the CL assemble-into-global after bootstrap.

(define (ece-assemble-into-global instruction-list)
  "Append instructions to global vector, register labels. Return start PC."
  (define start-pc (%instruction-vector-length))
  (for-each
   (lambda (item)
     (cond
      ;; Labels are symbols — register in label table at current PC
      ((symbol? item)
       (%label-table-set! item (%instruction-vector-length)))
      ;; Pseudo-instruction: (procedure-name <label> <name>)
      ((and (pair? item) (eq? (car item) 'procedure-name))
       (let ((pc (%label-table-ref (cadr item))))
         (when pc
           (%procedure-name-set! pc (caddr item)))))
      ;; Regular instruction — push source + resolved form
      (else
       (%instruction-vector-push! item))))
   instruction-list)
  start-pc)

;; Switchover: rebind assemble-into-global to the ECE implementation.
;; mc-compile-and-go calls assemble-into-global, so this makes it use
;; the ECE assembler for all subsequent compilations.
(define assemble-into-global ece-assemble-into-global)

;; Redefine load to use the ECE reader + ECE compiler pipeline.
;; Opens the file as a port, reads with ece-scheme-read, compiles each form.
(define (load filename)
  (define port (open-input-file filename))
  (let loop ((result '()))
    (define expr (ece-scheme-read port))
    (if (eof? expr)
        (begin (close-input-port port) result)
        (loop (mc-compile-and-go expr)))))
