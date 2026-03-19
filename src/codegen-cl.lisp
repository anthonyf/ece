;;;; codegen-cl.lisp — CL code generator for ECE compile-to-host
;;;;
;;;; Walks compilation space instruction arrays and emits CL defuns
;;;; containing tagbody forms with one label per PC. Each space gets
;;;; its own set of chunk functions. The generated code shares registers
;;;; with the interpreter via multiple-value return at zone boundaries.
;;;;
;;;; Usage:
;;;;   (ece::generate-compiled-space 0 "space-0.lisp")
;;;;   (ece::generate-all-spaces "output-dir/")
;;;;   (ece::load-compiled-zone "compiled-zone.lisp")

(in-package :ece)

;;; ============================================================
;;; CODEGEN: translate instruction vector → CL source
;;; ============================================================

(defun codegen-build-label-map (source-vector label-table)
  "Build a comprehensive label→PC map from a space's label table.
For labels referenced in instructions but missing from the table (can happen
after image compaction), we try to infer the target PC from instruction
context (e.g., MC-AFTER-CALL-N labels point to the instruction after a
call/return sequence). If inference fails, we log a warning and map the
label to the zone limit (forcing a zone exit)."
  (let ((label-map (make-hash-table :test 'eq))
        (limit (fill-pointer source-vector)))
    ;; Copy from label table
    (maphash (lambda (k v)
               (setf (gethash k label-map) v))
             label-table)
    ;; Scan for missing labels and try to infer their PCs
    (loop for i from 0 below limit
          for instr = (aref source-vector i)
          do (labels ((handle-label (x)
                        (when (and (consp x) (eq (car x) 'label))
                          (let ((sym (cadr x)))
                            (unless (gethash sym label-map)
                              (let ((target-pc nil))
                                (loop for j from (1+ i) below limit
                                      for next = (aref source-vector j)
                                      do (unless (member (car next) '(assign goto))
                                           (setf target-pc j)
                                           (return))
                                      when (eq (car next) 'goto)
                                      do (setf target-pc (1+ j))
                                      (return))
                                (if target-pc
                                    (progn
                                      (format t "codegen: inferred ~A → PC ~D~%" sym target-pc)
                                      (setf (gethash sym label-map) target-pc))
                                    (progn
                                      (format t "codegen WARNING: could not infer PC for label ~A at instruction ~D, mapping to zone exit~%" sym i)
                                      (setf (gethash sym label-map) limit)))))))))
               (case (car instr)
                 (assign (handle-label (caddr instr)))
                 (branch (handle-label (cadr instr)))
                 (goto (handle-label (cadr instr))))))
    label-map))

(defun codegen-resolve-label (label-sym label-map)
  "Resolve a label symbol to a PC, using the codegen's label map."
  (or (gethash label-sym label-map)
      (error "codegen: unknown label ~A (not in label table or recovered map)" label-sym)))

(defun codegen-emit-operand (operand stream op-name-to-index label-map)
  "Emit CL code for an instruction operand.
Returns a string representation of the CL expression."
  (ecase (car operand)
    (const
     (let ((val (cadr operand)))
       (cond
         ;; NIL (scheme false / empty list)
         ((null val) "nil")
         ;; Symbols need quoting
         ((symbolp val)
          (format nil "'~S" val))
         ;; Lists need quoting
         ((and (consp val) (not (null val)))
          (format nil "'~S" val))
         ;; Numbers, strings, etc. — self-evaluating
         (t (format nil "~S" val)))))
    (reg
     (let ((name (cadr operand)))
       (string-downcase (symbol-name name))))
    (label
     (let ((pc (codegen-resolve-label (cadr operand) label-map)))
       (format nil "~D" pc)))))

(defun codegen-emit-op-call (op-spec remaining-operands stream op-name-to-index label-map)
  "Emit a funcall to an operation. Returns the CL expression string.
OP-SPEC is (op name) from source instructions."
  (let* ((op-name (cadr op-spec))
         (idx (gethash op-name op-name-to-index))
         (args (loop for operand in remaining-operands
                     collect (codegen-emit-operand operand stream op-name-to-index label-map))))
    (unless idx
      (error "codegen: unknown operation ~A" op-name))
    (if args
        (format nil "(funcall (aref *compiled-zone-op-table* ~D) ~{~A~^ ~})"
                idx args)
        (format nil "(funcall (aref *compiled-zone-op-table* ~D))" idx))))

(defun codegen-emit-instruction (pc instr stream op-name-to-index limit label-map
                                 chunk-start chunk-end space-id)
  "Emit CL code for a single instruction at PC.
CHUNK-START and CHUNK-END define the local tagbody range. Jumps within
the chunk use (go LN). Jumps outside the chunk exit via return-from.
SPACE-ID is used to qualify continue-register labels."
  (flet ((in-chunk-p (target-pc)
           (and (>= target-pc chunk-start) (< target-pc chunk-end)))
         (emit-chunk-exit (target-pc)
           (format stream "     (setf pc ~D)~%" target-pc)
           (format stream "     (return-from ece-compiled-zone~%")
           (format stream "       (values pc val env proc argl continue stack))~%")))
    (case (car instr)
      (assign
       (let* ((target-sym (cadr instr))
              (target (string-downcase (symbol-name target-sym)))
              (source (caddr instr)))
         (case (car source)
           (const
            (format stream "     (setf ~A ~A)~%"
                    target (codegen-emit-operand source stream op-name-to-index label-map)))
           (reg
            (format stream "     (setf ~A ~A)~%"
                    target (codegen-emit-operand source stream op-name-to-index label-map)))
           (label
            (let ((resolved-pc (codegen-resolve-label (cadr source) label-map)))
              (if (eq target-sym 'continue)
                  ;; Continue register gets space-qualified address
                  (format stream "     (setf ~A (cons '~A ~D))~%"
                          target space-id resolved-pc)
                  (format stream "     (setf ~A ~D)~%"
                          target resolved-pc))))
           (op
            (let ((call-expr (codegen-emit-op-call source (cdddr instr) stream op-name-to-index label-map)))
              (format stream "     (let ((--result-- ~A))~%" call-expr)
              (format stream "       (if (ece-error-sentinel-p --result--)~%")
              (format stream "           (let ((error-fn (ignore-errors (lookup-variable-value 'error *global-env*))))~%")
              (format stream "             (if (and error-fn (compiled-procedure-p error-fn))~%")
              (format stream "                 (let* ((err-entry (compiled-procedure-entry error-fn))~%")
              (format stream "                        (err-space (qualified-space-id err-entry))~%")
              (format stream "                        (err-pc (qualified-local-pc err-entry)))~%")
              (format stream "                   (setf proc error-fn)~%")
              (format stream "                   (setf argl (cons (ece-error-sentinel-message --result--)~%")
              (format stream "                                    (ece-error-sentinel-irritants --result--)))~%")
              (format stream "                   (if (eq err-space '~A)~%" space-id)
              (format stream "                       (progn (setf pc err-pc)~%")
              (format stream "                              (cond ((and (>= pc ~D) (< pc ~D)) (go --entry-dispatch--))~%"
                      chunk-start chunk-end)
              (format stream "                                    (t (return-from ece-compiled-zone~%")
              (format stream "                                         (values pc val env proc argl continue stack)))))~%")
              ;; Error handler in different space — exit with qualified address
              (format stream "                       (progn (setf pc err-entry)~%")
              (format stream "                              (return-from ece-compiled-zone~%")
              (format stream "                                (values pc val env proc argl continue stack)))))~%")
              (format stream "                 (error \"~~A\" (ece-error-sentinel-message --result--))))~%")
              (format stream "           (setf ~A --result--)))~%" target)))
           (t (error "codegen: bad assign source ~A at PC ~D" source pc)))))

      (test
       (let ((op-spec (cadr instr)))
         (let ((call-expr (codegen-emit-op-call op-spec (cddr instr) stream op-name-to-index label-map)))
           (format stream "     (setf flag ~A)~%" call-expr))))

      (branch
       (let* ((label-sym (cadr (cadr instr)))
              (target-pc (codegen-resolve-label label-sym label-map)))
         (cond
           ((in-chunk-p target-pc)
            (format stream "     (when flag (go L~D))~%" target-pc))
           (t
            (format stream "     (when flag~%")
            (emit-chunk-exit target-pc)
            (format stream "     )~%")))))

      (goto
       (let ((dest (cadr instr)))
         (ecase (car dest)
           (label
            (let* ((label-sym (cadr dest))
                   (target-pc (codegen-resolve-label label-sym label-map)))
              (if (in-chunk-p target-pc)
                  (format stream "     (go L~D)~%" target-pc)
                  (emit-chunk-exit target-pc))))
           (reg
            (let ((reg-name (string-downcase (symbol-name (cadr dest)))))
              ;; Register may hold a space-qualified address (cons space-id . pc)
              ;; or a bare integer (backward compat)
              (format stream "     (let ((--addr-- ~A))~%" reg-name)
              (format stream "       (cond~%")
              ;; Qualified address, same space → extract local pc
              (format stream "         ((and (consp --addr--) (eq (car --addr--) '~A))~%" space-id)
              (format stream "          (setf pc (cdr --addr--))~%")
              (format stream "          (if (and (>= pc ~D) (< pc ~D))~%" chunk-start chunk-end)
              (format stream "              (go --entry-dispatch--)~%")
              (format stream "              (return-from ece-compiled-zone~%")
              (format stream "                (values pc val env proc argl continue stack))))~%")
              ;; Qualified address, different space → exit with full address
              (format stream "         ((consp --addr--)~%")
              (format stream "          (setf pc --addr--)~%")
              (format stream "          (return-from ece-compiled-zone~%")
              (format stream "            (values pc val env proc argl continue stack)))~%")
              ;; Bare integer → use directly
              (format stream "         (t~%")
              (format stream "          (setf pc --addr--)~%")
              (format stream "          (if (and (>= pc ~D) (< pc ~D))~%" chunk-start chunk-end)
              (format stream "              (go --entry-dispatch--)~%")
              (format stream "              (return-from ece-compiled-zone~%")
              (format stream "                (values pc val env proc argl continue stack))))))~%"))))))

      (save
       (let ((reg-name (string-downcase (symbol-name (cadr instr)))))
         (format stream "     (push ~A stack)~%" reg-name)))

      (restore
       (let ((reg-name (string-downcase (symbol-name (cadr instr)))))
         (format stream "     (setf ~A (pop stack))~%" reg-name)))

      (perform
       (let ((op-spec (cadr instr)))
         (let ((call-expr (codegen-emit-op-call op-spec (cddr instr) stream op-name-to-index label-map)))
           (format stream "     ~A~%" call-expr))))

      (t (error "codegen: unknown instruction type ~A at PC ~D" (car instr) pc)))))

(defun codegen-build-op-name-index (source-vector)
  "Build a hash table mapping operation names to indices from a source instruction vector.
Returns (values op-name-to-index op-names-list)."
  (let ((op-name-to-index (make-hash-table :test 'eq))
        (op-names nil)
        (next-idx 0))
    (loop for i from 0 below (fill-pointer source-vector)
          for instr = (aref source-vector i)
          do (case (car instr)
               (assign
                (let ((source (caddr instr)))
                  (when (and (consp source) (eq (car source) 'op))
                    (let ((name (cadr source)))
                      (unless (gethash name op-name-to-index)
                        (setf (gethash name op-name-to-index) next-idx)
                        (push name op-names)
                        (incf next-idx))))))
               ((test perform)
                (let ((op-spec (cadr instr)))
                  (when (and (consp op-spec) (eq (car op-spec) 'op))
                    (let ((name (cadr op-spec)))
                      (unless (gethash name op-name-to-index)
                        (setf (gethash name op-name-to-index) next-idx)
                        (push name op-names)
                        (incf next-idx))))))))
    (values op-name-to-index (nreverse op-names))))

(defun generate-compiled-space (space-id filename)
  "Generate a CL source file containing the compiled zone function for SPACE-ID."
  (let* ((cs (get-space space-id))
         (source-vector (compilation-space-instructions cs))
         (label-table (compilation-space-label-table cs))
         (limit (fill-pointer source-vector)))
    (multiple-value-bind (op-name-to-index op-names) (codegen-build-op-name-index source-vector)
      (let ((label-map (codegen-build-label-map source-vector label-table)))
        (with-open-file (stream filename :direction :output :if-exists :supersede)
          (format stream ";;;; Generated compiled zone for space ~A (~A) — DO NOT EDIT~%"
                  space-id (compilation-space-name cs))
          (format stream ";;;; Generated from ~D instructions with ~D operations~%~%"
                  limit (length op-names))
          (format stream "(in-package :ece)~%~%")

          ;; Emit operation table initialization
          (format stream ";;; Operation table: maps index → CL function~%")
          (format stream "(build-compiled-zone-op-table '(~{~A~^ ~}))~%~%"
                  op-names)

          ;; Emit chunk functions
          (let ((chunk-size 4000))
            (loop for chunk-start from 0 below limit by chunk-size
                  for chunk-end = (min (+ chunk-start chunk-size) limit)
                  for chunk-id = (floor chunk-start chunk-size)
                  do (format stream "(defun ece-compiled-chunk-~D (pc val env proc argl continue stack)~%"
                             chunk-id)
                  (format stream "  (declare (optimize (speed 3) (safety 1)))~%")
                  (format stream "  (let ((flag nil))~%")
                  (format stream "    (block ece-compiled-zone~%")
                  (format stream "      (tagbody~%")
                  ;; Entry dispatch
                  (format stream "       --entry-dispatch--~%")
                  (format stream "        (case pc~%")
                  (loop for i from chunk-start below chunk-end
                        do (format stream "          (~D (go L~D))~%" i i))
                  (format stream "          (t (return-from ece-compiled-zone~%")
                  (format stream "               (values pc val env proc argl continue stack))))~%")
                  ;; Emit instructions
                  (loop for i from chunk-start below chunk-end
                        for instr = (aref source-vector i)
                        do (format stream "       L~D~%" i)
                        (codegen-emit-instruction i instr stream op-name-to-index limit label-map
                                                  chunk-start chunk-end space-id))
                  ;; Fall through
                  (format stream "       (setf pc ~D)~%" chunk-end)
                  (format stream "       (return-from ece-compiled-zone~%")
                  (format stream "         (values pc val env proc argl continue stack))))~%")
                  (format stream "    val))~%~%"))

            ;; Emit dispatch function
            (let ((num-chunks (ceiling limit chunk-size)))
              (format stream "(defun ece-compiled-zone (pc val env proc argl continue stack)~%")
              (format stream "  (loop~%")
              (format stream "    (if (>= pc ~D)~%" limit)
              (format stream "        (return (values pc val env proc argl continue stack)))~%")
              (format stream "    (let ((chunk (floor pc ~D)))~%" chunk-size)
              (format stream "      (multiple-value-setq (pc val env proc argl continue stack)~%")
              (format stream "        (case chunk~%")
              (loop for c from 0 below num-chunks
                    do (format stream "          (~D (ece-compiled-chunk-~D pc val env proc argl continue stack))~%"
                               c c))
              (format stream "          (t (return (values pc val env proc argl continue stack))))))~%")
              (format stream "    ;; If PC moved outside compiled zone, exit~%")
              (format stream "    (when (>= pc ~D)~%" limit)
              (format stream "      (return (values pc val env proc argl continue stack)))))~%~%")))

          ;; Set the compiled zone limit
          (format stream "(setf *compiled-zone-limit* ~D)~%" limit)
          (format stream "(setf *compiled-zone-function* #'ece-compiled-zone)~%")
          (format stream "(format t \"Compiled zone loaded: space ~A (~A), ~D instructions, ~D operations~~%%\")~%"
                  space-id (compilation-space-name cs) limit (length op-names)))

        (format t "Generated compiled zone: ~A (space ~A, ~D instructions, ~D operations)~%"
                filename space-id limit (length op-names))))))

;;; Backward-compatible wrapper — generates for bootstrap space
(defun generate-compiled-zone (filename &key (space-id 'bootstrap))
  "Generate a CL source file containing the compiled zone function.
Defaults to bootstrap space. Use generate-compiled-space for explicit space-id."
  (generate-compiled-space space-id filename))

(defun load-compiled-zone (filename)
  "Load a generated compiled zone file."
  (load (compile-file filename)))

;;; ============================================================
;;; MANIFEST: space registry metadata
;;; ============================================================

(defun generate-space-manifest (filename)
  "Generate a manifest file listing all spaces with metadata.
The manifest is a CL readable s-expression: a list of plists, one per space."
  (let ((num-spaces (hash-table-count *space-registry*)))
    (with-open-file (stream filename :direction :output :if-exists :supersede)
      (format stream ";;;; ECE Space Manifest — DO NOT EDIT~%")
      (format stream ";;;; ~D space~:P~%~%" num-spaces)
      (format stream "(~%")
      (maphash (lambda (sym cs)
                 (format stream " (:space-id ~A :name ~S :instruction-count ~D)~%"
                         sym
                         (compilation-space-name cs)
                         (fill-pointer (compilation-space-instructions cs))))
               *space-registry*)
      (format stream ")~%"))
    (format t "Generated manifest: ~A (~D spaces)~%" filename num-spaces)))

;;; ============================================================
;;; GENERATE ALL: emit per-space files + manifest + shared op table
;;; ============================================================

(defun codegen-build-global-op-name-index ()
  "Build a unified operation name index across all spaces.
Returns (values op-name-to-index op-names-list)."
  (let ((op-name-to-index (make-hash-table :test 'eq))
        (op-names nil)
        (next-idx 0))
    (maphash (lambda (sid cs)
               (declare (ignore sid))
               (let ((sv (compilation-space-instructions cs)))
                 (loop for i from 0 below (fill-pointer sv)
                       for instr = (aref sv i)
                       do (case (car instr)
                            (assign
                             (let ((source (caddr instr)))
                               (when (and (consp source) (eq (car source) 'op))
                                 (let ((name (cadr source)))
                                   (unless (gethash name op-name-to-index)
                                     (setf (gethash name op-name-to-index) next-idx)
                                     (push name op-names)
                                     (incf next-idx))))))
                            ((test perform)
                             (let ((op-spec (cadr instr)))
                               (when (and (consp op-spec) (eq (car op-spec) 'op))
                                 (let ((name (cadr op-spec)))
                                   (unless (gethash name op-name-to-index)
                                     (setf (gethash name op-name-to-index) next-idx)
                                     (push name op-names)
                                     (incf next-idx))))))))))
             *space-registry*)
    (values op-name-to-index (nreverse op-names))))

(defun generate-op-table-file (filename)
  "Generate a shared operation table initialization file for all spaces."
  (multiple-value-bind (op-name-to-index op-names) (codegen-build-global-op-name-index)
    (declare (ignore op-name-to-index))
    (with-open-file (stream filename :direction :output :if-exists :supersede)
      (format stream ";;;; ECE Shared Operation Table — DO NOT EDIT~%")
      (format stream ";;;; ~D operations across all spaces~%~%" (length op-names))
      (format stream "(in-package :ece)~%~%")
      (format stream ";;; Operation table: maps index → CL function~%")
      (format stream "(build-compiled-zone-op-table '(~{~A~^ ~}))~%"
              op-names))
    (format t "Generated op table: ~A (~D operations)~%" filename (length op-names))))

(defun generate-all-spaces (output-dir)
  "Generate compiled zone files for all spaces, a shared operation table,
and a manifest. OUTPUT-DIR must end with a slash."
  (ensure-directories-exist output-dir)
  (let ((num-spaces (hash-table-count *space-registry*)))
    ;; Generate shared op table
    (generate-op-table-file (format nil "~Aop-table.lisp" output-dir))
    ;; Generate per-space files
    (maphash (lambda (sym cs)
               (declare (ignore cs))
               (let ((filename (format nil "~Aspace-~A.lisp" output-dir sym)))
                 (generate-compiled-space sym filename)))
             *space-registry*)
    ;; Generate manifest
    (generate-space-manifest (format nil "~Amanifest.sexp" output-dir))
    (format t "Generated ~D space file~:P + op-table + manifest in ~A~%" num-spaces output-dir)))
