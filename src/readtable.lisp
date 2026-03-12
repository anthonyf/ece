(in-package :ece)

;;;; ========================================================================
;;;; ECE READTABLE
;;;; ========================================================================
;;;
;;; Custom CL readtable for reading ECE syntax: quasiquote, unquote,
;;; hash table literals, and string interpolation.
;;;
;;; Used by:
;;; - compiler.lisp (compile-file-ece) during cold bootstrap
;;; - Test code that embeds ECE expressions in CL forms
;;;
;;; NOT used by:
;;; - Image loading/saving (uses flat image format)
;;; - Runtime ECE reading (uses ECE-native reader from reader.scm)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *ece-readtable* (copy-readtable))

  (set-macro-character #\`
                       (lambda (stream char)
                         (declare (ignore char))
                         (list 'quasiquote (read stream t nil t)))
                       nil *ece-readtable*)

  (set-macro-character #\,
                       (lambda (stream char)
                         (declare (ignore char))
                         (if (eql (peek-char nil stream nil nil) #\@)
                             (progn (read-char stream)
                                    (list 'unquote-splicing (read stream t nil t)))
                             (list 'unquote (read stream t nil t))))
                       nil *ece-readtable*)

  ;; Hash table literal: {k1 v1 k2 v2 ...} → (hash-table (k1 . v1) (k2 . v2) ...)
  (set-macro-character #\{
                       (lambda (stream char)
                         (declare (ignore char))
                         (let* ((items (read-delimited-list #\} stream t))
                                (entries (loop for (k v) on items by #'cddr
                                               collect (cons k v))))
                           (cons :hash-table entries)))
                       nil *ece-readtable*)

  (set-macro-character #\}
                       (get-macro-character #\))
                       nil *ece-readtable*)

  ;; String interpolation: "Hello $name" → (string-append "Hello " (write-to-string name))
  ;; $var interpolates a variable, $(expr) interpolates an expression, $$ is literal $
  ;; Strings without $ are returned as plain strings.
  (defun ece-identifier-char-p (c)
    "Return T if C is a valid identifier character after $."
    (and c (or (alphanumericp c)
               (member c '(#\- #\? #\! #\* #\> #\< #\_ #\/)))))

  (set-macro-character #\"
                       (lambda (stream char)
                         (declare (ignore char))
                         (let ((segments '())
                               (buf (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
                           (flet ((flush-buf ()
                                    (when (> (length buf) 0)
                                      (push (copy-seq buf) segments)
                                      (setf (fill-pointer buf) 0))))
                             (loop
                              (let ((c (read-char stream t nil t)))
                                (cond
                                  ;; End of string
                                  ((eql c #\")
                                   (flush-buf)
                                   (let ((segs (nreverse segments)))
                                     (return
                                       (cond
                                         ;; Single literal string — return directly
                                         ((and (= (length segs) 1) (stringp (first segs)))
                                          (first segs))
                                         ;; Single non-string expression — wrap in write-to-string
                                         ((and (= (length segs) 1) (not (stringp (first segs))))
                                          (list 'write-to-string (first segs)))
                                         ;; Mixed — build (string-append ...) with write-to-string wrapping
                                         (t
                                          (cons 'string-append
                                                (mapcar (lambda (seg)
                                                          (if (stringp seg)
                                                              seg
                                                              (list 'write-to-string seg)))
                                                        segs)))))))
                                  ;; Backslash escape
                                  ((eql c #\\)
                                   (let ((next (read-char stream t nil t)))
                                     (case next
                                       (#\n (vector-push-extend #\Newline buf))
                                       (#\t (vector-push-extend #\Tab buf))
                                       (#\" (vector-push-extend #\" buf))
                                       (#\\ (vector-push-extend #\\ buf))
                                       (t (vector-push-extend next buf)))))
                                  ;; Dollar interpolation
                                  ((eql c #\$)
                                   (let ((next (peek-char nil stream t nil t)))
                                     (cond
                                       ;; $$ → literal $
                                       ((eql next #\$)
                                        (read-char stream t nil t)
                                        (vector-push-extend #\$ buf))
                                       ;; $(expr) → read s-expression
                                       ((eql next #\()
                                        (flush-buf)
                                        (push (read stream t nil t) segments))
                                       ;; $identifier → read symbol name
                                       ((ece-identifier-char-p next)
                                        (flush-buf)
                                        (let ((sym-buf (make-array 0 :element-type 'character
                                                                   :adjustable t :fill-pointer 0)))
                                          (loop for sc = (peek-char nil stream nil nil t)
                                                while (ece-identifier-char-p sc)
                                                do (vector-push-extend (read-char stream t nil t) sym-buf))
                                          (push (intern (string-upcase sym-buf) :ece) segments)))
                                       ;; $ followed by non-identifier → literal $
                                       (t (vector-push-extend #\$ buf)))))
                                  ;; Regular character
                                  (t (vector-push-extend c buf))))))))
                       nil *ece-readtable*))
