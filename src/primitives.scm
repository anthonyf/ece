;;;; ECE Host Primitive Templates — source of truth for primitive implementations.
;;;;
;;;; Each (define-host-primitive (NAME . PARAMS) :KEY TEMPLATE ...) form
;;;; declares one primitive's implementation as a multi-target template. The
;;;; template body is a quasiquoted s-expression: (unquote NAME) marks
;;;; substitution slots for parameters.
;;;;
;;;; Targets currently consumed:
;;;;   :cl   — Common Lisp body, expanded into bootstrap/primitives-auto.lisp
;;;;
;;;; Targets authored ahead of time (no codegen yet):
;;;;   :wat  — WebAssembly Text body
;;;;   :js   — JavaScript body
;;;;
;;;; Regenerate the CL output with: make bootstrap (or `make bootstrap/primitives-auto.lisp`).
;;;; The codegen lives in src/codegen-cl.scm and runs through the existing ECE
;;;; interpreter — same path as compiling .scm to .ecec.
;;;;
;;;; Convention: this file does NOT contain the 24 ece-platform primitives
;;;; (they live in src/prelude.scm as plain (define ...) forms).
;;;;
;;;; Symbol conventions in templates:
;;;;   cl:foo      — Common Lisp built-in (resolved to common-lisp:foo)
;;;;   foo (bare)  — ECE-package helper or special var (e.g. scheme-bool,
;;;;                 *executing-code-obj*, *global-env*)
;;;;   ,name       — parameter substitution slot
;;;;   '|name|     — literal lowercase ECE symbol (case-preserved data tag)

;;; ─────────────────────────────────────────────────────────────────────────
;;; Arithmetic (ids 0-3)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (+ . args)
  :cl `(cl:apply (cl:function cl:+) ,args))

(define-host-primitive (- . args)
  :cl `(cl:apply (cl:function cl:-) ,args))

(define-host-primitive (* . args)
  :cl `(cl:apply (cl:function cl:*) ,args))

(define-host-primitive (/ . args)
  :cl `(cl:apply (cl:function cl:/) ,args))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Pair operations (ids 5-10)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (car p)
  :cl `(cl:car ,p))

(define-host-primitive (cdr p)
  :cl `(cl:cdr ,p))

(define-host-primitive (cons a d)
  :cl `(cl:cons ,a ,d))

;; list: implemented in src/prelude.scm.

(define-host-primitive (set-car! pair val)
  :cl `(cl:rplaca ,pair ,val))

(define-host-primitive (set-cdr! pair val)
  :cl `(cl:rplacd ,pair ,val))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Type predicates (ids 11-18) — all return scheme booleans
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (null? x)
  :cl `(scheme-bool (cl:null ,x)))

(define-host-primitive (pair? x)
  :cl `(scheme-bool (cl:consp ,x)))

(define-host-primitive (number? x)
  :cl `(scheme-bool (cl:numberp ,x)))

(define-host-primitive (string? x)
  :cl `(scheme-bool (cl:stringp ,x)))

(define-host-primitive (symbol? x)
  :cl `(scheme-bool (cl:and (cl:symbolp ,x) ,x)))

(define-host-primitive (integer? x)
  :cl `(scheme-bool
        (cl:or (cl:integerp ,x)
               (cl:and (cl:floatp ,x)
                       ;; ignore-errors handles NaN/infinity: (truncate inf)
                       ;; signals arithmetic-error, truncate of NaN too.
                       (cl:ignore-errors (cl:= ,x (cl:truncate ,x)))))))

(define-host-primitive (char? x)
  :cl `(scheme-bool (cl:characterp ,x)))

(define-host-primitive (vector? x)
  :cl `(scheme-bool (cl:and (cl:vectorp ,x) (cl:not (cl:stringp ,x)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Equality and comparison (ids 20, 22-24)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (eq? x y)
  :cl `(scheme-bool (cl:eq ,x ,y)))

(define-host-primitive (= . args)
  :cl `(scheme-bool (cl:apply (cl:function cl:=) ,args)))

(define-host-primitive (< . args)
  :cl `(scheme-bool (cl:apply (cl:function cl:<) ,args)))

(define-host-primitive (> . args)
  :cl `(scheme-bool (cl:apply (cl:function cl:>) ,args)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; String operations (ids 25-28, 31-32, 42)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (string-length s)
  :cl `(cl:length ,s))

(define-host-primitive (string-ref s i)
  :cl `(cl:char ,s ,i))

(define-host-primitive (string-append . strings)
  :cl `(cl:apply (cl:function cl:concatenate) (quote cl:string) ,strings))

(define-host-primitive (substring s start end)
  :cl `(cl:subseq ,s ,start ,end))

(define-host-primitive (string->symbol s)
  :cl `(cl:intern ,s :ece))

(define-host-primitive (symbol->string s)
  :cl `(cl:symbol-name ,s))

(define-host-primitive (string ch)
  :cl `(cl:string ,ch))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Character operations (ids 43-44)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (char->integer ch)
  :cl `(cl:char-code ,ch))

(define-host-primitive (integer->char n)
  :cl `(cl:code-char ,n))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Vector operations (ids 50-54)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (make-vector . args)
  :cl `(cl:make-array (cl:car ,args)
                      :initial-element
                      (cl:if (cl:cdr ,args) (cl:cadr ,args) 0)))

(define-host-primitive (vector . args)
  :cl `(cl:apply (cl:function cl:vector) ,args))

(define-host-primitive (vector-ref vec idx)
  :cl `(cl:aref ,vec ,idx))

(define-host-primitive (vector-set! vec idx val)
  :cl `(cl:progn (cl:setf (cl:aref ,vec ,idx) ,val) ,val))

(define-host-primitive (vector-length vec)
  :cl `(cl:length ,vec))

;;; ─────────────────────────────────────────────────────────────────────────
;;; I/O — character/line read (ids 60, 61, 63, 64, 65)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (read-char port)
  :cl `(let* ((p ,port)
              (ch (cl:read-char (ece-port-stream p) cl:nil cl:nil)))
         (cl:when ch
                  (cl:if (cl:char= ch #\Newline)
                         (cl:progn
                          (set-ece-port-line! p (cl:1+ (ece-port-line p)))
                          (set-ece-port-col! p 0))
                         (set-ece-port-col! p (cl:1+ (ece-port-col p)))))
         (cl:or ch *eof-sentinel*)))

(define-host-primitive (peek-char port)
  :cl `(let ((ch (cl:peek-char cl:nil (ece-port-stream ,port) cl:nil cl:nil)))
         (cl:or ch *eof-sentinel*)))

(define-host-primitive (read-line port)
  :cl `(let ((stream (ece-port-stream ,port)))
         (cl:multiple-value-bind (line missing-newline-p)
                                 (cl:read-line stream cl:nil cl:nil)
                                 (cl:declare (cl:ignore missing-newline-p))
                                 (cl:or line *eof-sentinel*))))

(define-host-primitive (char-ready? port)
  :cl `(scheme-bool (cl:listen (ece-port-stream ,port))))

(define-host-primitive (eof? obj)
  :cl `(scheme-bool (cl:eq ,obj *eof-sentinel*)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; write-to-string (id 67)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (write-to-string x)
  :cl `(cl:cond
        ((scheme-false-p ,x) "#f")
        ((cl:eq ,x cl:t) "#t")
        ((cl:null ,x) "()")
        ((cl:or (compiled-procedure-p ,x) (primitive-procedure-p ,x))
         (format-ece-proc ,x))
        ((cl:hash-table-p ,x)
         (cl:with-output-to-string (s)
                                   (format-ece-hash-table
                                    ,x s
                                    (cl:lambda (v str) (ece-display-to-stream v str)))))
        (cl:t (cl:let ((cl:*print-circle* cl:t))
                      (cl:princ-to-string ,x)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Port type predicates (ids 68-70)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (input-port? x)
  :cl `(scheme-bool (cl:and (cl:consp ,x) (cl:eq (cl:car ,x) (quote input-port)))))

(define-host-primitive (output-port? x)
  :cl `(scheme-bool (cl:and (cl:consp ,x) (cl:eq (cl:car ,x) (quote output-port)))))

(define-host-primitive (port? x)
  :cl `(scheme-bool (cl:or (cl:and (cl:consp ,x) (cl:eq (cl:car ,x) (quote input-port)))
                           (cl:and (cl:consp ,x) (cl:eq (cl:car ,x) (quote output-port))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; String/file ports (ids 73-75)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (open-input-string str)
  :cl `(ece-make-input-port (cl:make-string-input-stream ,str)))

(define-host-primitive (close-input-port port)
  :cl `(cl:progn (cl:close (ece-port-stream ,port)) cl:nil))

(define-host-primitive (close-output-port port)
  :cl `(cl:progn (cl:close (ece-port-stream ,port)) cl:nil))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Bitwise operations (ids 76-80)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (bitwise-and . args)
  :cl `(cl:apply (cl:function cl:logand) ,args))

(define-host-primitive (bitwise-or . args)
  :cl `(cl:apply (cl:function cl:logior) ,args))

(define-host-primitive (bitwise-xor . args)
  :cl `(cl:apply (cl:function cl:logxor) ,args))

(define-host-primitive (bitwise-not n)
  :cl `(cl:lognot ,n))

(define-host-primitive (arithmetic-shift n shift)
  :cl `(cl:ash ,n ,shift))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Error / misc (ids 81, 83, 84)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%raw-error . args)
  :cl `(cl:apply (cl:function cl:error) ,args))

(define-host-primitive (sleep seconds)
  :cl `(cl:progn (cl:sleep ,seconds) cl:nil))

(define-host-primitive (clear-screen)
  :cl `(cl:progn
        (cl:format cl:t "~c[2J~c[H"
                   (cl:code-char 27) (cl:code-char 27))
        (cl:finish-output)
        cl:nil))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Compiler support (ids 85-91)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (execute-from-pc . args)
  :cl `(let ((start-pc (cl:car ,args))
             (env (cl:if (cl:cdr ,args) (cl:cadr ,args) *global-env*)))
         (cl:cond
          ;; Bare code-object → run from its pc 0
          ((code-object-p start-pc)
           (execute-instructions start-pc 0 env))
          ;; (code-obj . pc) pair
          ((cl:and (cl:consp start-pc) (code-object-p (cl:car start-pc)))
           (execute-instructions (cl:car start-pc) (cl:cdr start-pc) env))
          ;; Legacy (space-id . pc) pair or bare integer
          (cl:t
           (execute-instructions (qualified-space-id start-pc)
                                 (qualified-local-pc start-pc)
                                 env)))))

(define-host-primitive (get-macro name)
  :cl `(cl:or (cl:gethash ,name *compile-time-macros*) *scheme-false*))

(define-host-primitive (set-macro! name def)
  :cl `(cl:progn (cl:setf (cl:gethash ,name *compile-time-macros*) ,def) ,def))

(define-host-primitive (make-parameter . args)
  :cl `(cl:list (quote parameter)
                (cl:cons (cl:car ,args)
                         (cl:if (cl:cdr ,args) (cl:cadr ,args) cl:nil))))

(define-host-primitive (apply-compiled-procedure proc args)
  :cl `(execute-compiled-call ,proc ,args))

(define-host-primitive (try-eval expr)
  :cl `(cl:handler-case
        (evaluate ,expr)
        (cl:error (c)
                  (cl:format cl:t "Error: ~A~%" c)
                  (cl:finish-output)
                  *eof-sentinel*)))

(define-host-primitive (extend-environment . args)
  :cl `(cl:apply (cl:function extend-environment) ,args))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Instruction-vector / assembler (ids 92-97)
;;;
;;; The bootstrap-space assembler primitives (%instruction-vector-length,
;;; %instruction-vector-push!, %label-table-set!, %label-table-ref) retired
;;; alongside the compilation-space struct in Phase F of the
;;; per-procedure-code-objects change. Their ids (93-96) stay reserved
;;; in primitives.def — callers were removed together with
;;; `assemble-into-global` in Phase G1, but we keep the registrations
;;; so that stale archives surface a clear error instead of a primitive
;;; mismatch. The :cl bodies below raise "retired primitive".
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%intern-ece s)
  :cl `(cl:intern ,s :ece))

(define-host-primitive (%instruction-vector-length)
  :cl `(cl:error "Primitive %instruction-vector-length is retired; bootstrap-space assembler path removed in per-procedure-code-objects."))

(define-host-primitive (%instruction-vector-push! source-instr)
  :cl `(cl:progn
        (cl:declare (cl:ignore ,source-instr))
        (cl:error "Primitive %instruction-vector-push! is retired; bootstrap-space assembler path removed in per-procedure-code-objects.")))

(define-host-primitive (%label-table-set! label pc)
  :cl `(cl:progn
        (cl:declare (cl:ignore ,label ,pc))
        (cl:error "Primitive %label-table-set! is retired; bootstrap-space assembler path removed in per-procedure-code-objects.")))

(define-host-primitive (%label-table-ref label)
  :cl `(cl:progn
        (cl:declare (cl:ignore ,label))
        (cl:error "Primitive %label-table-ref is retired; bootstrap-space assembler path removed in per-procedure-code-objects.")))

;;; %procedure-name-set! (97) and %procedure-name-ref (240) retired in
;;; per-procedure-code-objects §11.2: procedure names now live on the
;;; code-object struct (set at compile time via %code-object-set-name!;
;;; read via code-object-name). The *procedure-name-table* side table
;;; retires with this commit. IDs 97 and 240 stay reserved.

;;; ─────────────────────────────────────────────────────────────────────────
;;; Platform discovery (ids 98-99)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (platform-has? name)
  :cl `(let ((id (cl:gethash ,name *primitive-name-to-id*)))
         (scheme-bool (cl:and id (cl:gethash id *primitive-available-ids*)))))

(define-host-primitive (%platform-primitives)
  :cl `(let ((result (quote ())))
         (cl:maphash (cl:lambda (id available)
                                (cl:declare (cl:ignore available))
                                (let ((name (cl:aref *primitive-name-table* id)))
                                  (cl:when name (cl:push name result))))
                     *primitive-available-ids*)
         result))

;;; ─────────────────────────────────────────────────────────────────────────
;;; File I/O (ids 100-105)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (open-input-file filename)
  :cl `(ece-make-input-port
        (cl:open ,filename :direction :input)
        (cl:if (cl:stringp ,filename) ,filename (cl:namestring ,filename))))

(define-host-primitive (open-output-file filename)
  :cl `(ece-make-output-port
        (cl:open ,filename :direction :output
                 :if-exists :supersede
                 :if-does-not-exist :create)
        (cl:if (cl:stringp ,filename) ,filename (cl:namestring ,filename))))

(define-host-primitive (with-input-from-file filename thunk)
  :cl `(let ((port (ece-open-input-file ,filename)))
         (cl:unwind-protect
          (let ((cl:*standard-input* (ece-port-stream port)))
            (apply-ece-procedure ,thunk cl:nil))
          (ece-close-input-port port))))

(define-host-primitive (with-output-to-file filename thunk)
  :cl `(let ((port (ece-open-output-file ,filename)))
         (cl:unwind-protect
          (let ((cl:*standard-output* (ece-port-stream port)))
            (apply-ece-procedure ,thunk cl:nil))
          (ece-close-output-port port))))

(define-host-primitive (write-byte byte port)
  :cl `(cl:progn (cl:write-byte ,byte (ece-port-stream ,port)) ,byte))

(define-host-primitive (open-binary-output-file filename)
  :cl `(ece-make-output-port
        (cl:open ,filename :direction :output
                 :element-type (quote (cl:unsigned-byte 8))
                 :if-exists :supersede
                 :if-does-not-exist :create)
        (cl:if (cl:stringp ,filename) ,filename (cl:namestring ,filename))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Tracing (ids 106-107)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (trace name)
  :cl `(let ((original (lookup-variable-value ,name *global-env*)))
         (cl:when (cl:gethash ,name *traced-procedures*)
                  (cl:return-from ece-trace ,name))
         (cl:setf (cl:gethash ,name *traced-procedures*) original)
         (let ((wrapper-sym (cl:intern (cl:format cl:nil "TRACE-~A" ,name) :ece)))
           (cl:setf (cl:symbol-function wrapper-sym)
                    (cl:lambda (cl:&rest args)
                               (let ((indent (cl:make-string (cl:* 2 *trace-depth*)
                                                             :initial-element #\Space)))
                                 (cl:format cl:t "~A(~A~{ ~S~})~%" indent ,name args)
                                 (cl:incf *trace-depth*)
                                 (let ((result
                                        (cl:if (compiled-procedure-p original)
                                               (execute-compiled-call original args)
                                               (apply-primitive-procedure original args))))
                                   (cl:decf *trace-depth*)
                                   (cl:format cl:t "~A=> ~S~%" indent result)
                                   result))))
           (set-variable-value! ,name (cl:list (quote |primitive|) wrapper-sym) *global-env*))
         ,name))

(define-host-primitive (untrace name)
  :cl `(let ((original (cl:gethash ,name *traced-procedures*)))
         (cl:when original
                  (set-variable-value! ,name original *global-env*)
                  (cl:remhash ,name *traced-procedures*))
         ,name))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Integer rounding (ids 108-110)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (truncate x)
  :cl `(cl:values (cl:truncate ,x)))

(define-host-primitive (floor x)
  :cl `(cl:values (cl:floor ,x)))

(define-host-primitive (exact->inexact x)
  :cl `(cl:coerce ,x (quote cl:single-float)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Compiler/macro table introspection (ids 112-114)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%label-table-entries)
  :cl `(cl:error "Primitive %label-table-entries is retired; bootstrap-space label table removed in per-procedure-code-objects."))

(define-host-primitive (%macro-table-entries)
  :cl `(let ((entries (quote ())))
         (cl:maphash (cl:lambda (name proc) (cl:push (cl:cons name proc) entries))
                     *compile-time-macros*)
         entries))

(define-host-primitive (parameter? x)
  :cl `(scheme-bool (cl:and (cl:listp ,x) (cl:eq (cl:car ,x) (quote parameter)))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Eq hash tables (ids 116-120)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%eq-hash-table)
  :cl `(cl:make-hash-table :test (quote cl:eq)))

(define-host-primitive (%eq-hash-ref ht key)
  :cl `(cl:multiple-value-bind (val found) (cl:gethash ,key ,ht)
                               (cl:if found val *scheme-false*)))

(define-host-primitive (%eq-hash-set! ht key val)
  :cl `(cl:progn (cl:setf (cl:gethash ,key ,ht) ,val) ,ht))

(define-host-primitive (%eq-hash-has-key? ht key)
  :cl `(cl:multiple-value-bind (val found) (cl:gethash ,key ,ht)
                               (cl:declare (cl:ignore val))
                               (scheme-bool found)))

(define-host-primitive (%eq-hash-keys ht)
  :cl `(let ((keys (quote ())))
         (cl:maphash (cl:lambda (k v) (cl:declare (cl:ignore v)) (cl:push k keys)) ,ht)
         keys))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Hash-table frames (ids 121-124)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%hash-frame? frame)
  :cl `(scheme-bool (hash-frame-p ,frame)))

(define-host-primitive (%hash-frame-entries frame)
  :cl `(cl:progn
        (cl:unless (cl:and (cl:consp ,frame) (cl:hash-table-p (cl:cdr ,frame)))
                   (cl:error "ece-%hash-frame-entries: expected (:hash-frame . <hash-table>), got ~S" ,frame))
        (let ((entries (quote ())))
          (cl:maphash (cl:lambda (k v) (cl:push (cl:cons k v) entries)) (cl:cdr ,frame))
          entries)))

(define-host-primitive (%make-hash-frame)
  :cl `(cl:cons :hash-frame (cl:make-hash-table :test (quote cl:eq))))

(define-host-primitive (%hash-frame-set! frame key val)
  :cl `(cl:progn (cl:setf (cl:gethash ,key (cl:cdr ,frame)) ,val) ,frame))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Compilation spaces (retired — Phase F, per-procedure-code-objects)
;;; IDs 125-135 remain reserved in primitives.def. The compiler and
;;; assembler now operate on per-procedure code-objects (see ids
;;; 241-249/254-257 below).
;;; ─────────────────────────────────────────────────────────────────────────

;;; ─────────────────────────────────────────────────────────────────────────
;;; Code objects (ids 241-249)
;;; ─────────────────────────────────────────────────────────────────────────
;;; Accessors on the per-procedure compilation unit. Mirrors the %space-*
;;; primitives but keyed on a code-object value instead of a space-id symbol.

(define-host-primitive (code-object? x)
  :cl `(scheme-bool (code-object-p ,x)))

(define-host-primitive (code-object-instructions co)
  :cl `(code-object-source-instructions ,co))

(define-host-primitive (code-object-resolved-instructions co)
  :cl `(code-object-resolved-instructions ,co))

(define-host-primitive (code-object-length co)
  :cl `(cl:fill-pointer (code-object-source-instructions ,co)))

(define-host-primitive (code-object-label-entries co)
  :cl `(let ((entries (quote ())))
         (cl:maphash (cl:lambda (label pc) (cl:push (cl:cons label pc) entries))
                     (code-object-labels ,co))
         entries))

(define-host-primitive (code-object-label-ref co label)
  :cl `(cl:gethash ,label (code-object-labels ,co)))

(define-host-primitive (code-object-name co)
  :cl `(cl:or (code-object-name ,co) *scheme-false*))

(define-host-primitive (code-object-native-fn co)
  :cl `(cl:or (code-object-native-fn ,co) *scheme-false*))

(define-host-primitive (code-object-source-loc co)
  :cl `(cl:or (code-object-source-loc ,co) *scheme-false*))

;;; Constructors / mutators (ids 250-255) — used by the compiler when
;;; building a code-object bottom-up. Metadata setters follow the
;;; `set-<slot>!` convention; accessors stay read-only above.

(define-host-primitive (%make-code-object)
  :cl `(make-code-object))

(define-host-primitive (%code-object-push-instruction! co source-instr)
  :cl `(cl:progn
        (cl:vector-push-extend ,source-instr (code-object-source-instructions ,co))
        (cl:vector-push-extend (resolve-operations ,source-instr)
                               (code-object-resolved-instructions ,co))
        cl:nil))

(define-host-primitive (%code-object-set-label! co label local-pc)
  :cl `(cl:progn
        (cl:setf (cl:gethash ,label (code-object-labels ,co)) ,local-pc)
        cl:nil))

(define-host-primitive (%code-object-set-name! co name)
  :cl `(cl:progn (cl:setf (code-object-name ,co) ,name) cl:nil))

(define-host-primitive (%code-object-set-arity! co arity)
  :cl `(cl:progn (cl:setf (code-object-arity ,co) ,arity) cl:nil))

(define-host-primitive (%code-object-set-source-loc! co loc)
  :cl `(cl:progn (cl:setf (code-object-source-loc ,co) ,loc) cl:nil))

(define-host-primitive (execute-code-object . args)
  :cl `(let ((co (cl:car ,args))
             (env (cl:if (cl:cdr ,args) (cl:cadr ,args) *global-env*)))
         (execute-instructions co 0 env)))

(define-host-primitive (code-object-arity co)
  :cl `(cl:or (code-object-arity ,co) *scheme-false*))

(define-host-primitive (code-object-archive-key co)
  :cl `(cl:or (code-object-archive-key ,co) *scheme-false*))

(define-host-primitive (%code-object-set-archive-key! co key)
  :cl `(cl:progn (cl:setf (code-object-archive-key ,co)
                          (cl:if (cl:eq ,key *scheme-false*) cl:nil ,key))
                 cl:nil))

(define-host-primitive (%archive-co-lookup stem index)
  :cl `(cl:or (cl:gethash (cl:cons ,stem ,index) *archive-code-objects*)
              *scheme-false*))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Serialization (id 136)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (write-to-string-flat x)
  :cl `(let ((cl:*print-circle* cl:nil)
             (cl:*print-pretty* cl:nil)
             (cl:*package* (cl:find-package :ece))
             (cl:*readtable* *preserve-readtable*))
         (cl:with-output-to-string (s)
                                   (ece-print-flat ,x s))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Keyword test (id 137)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (keyword? x)
  :cl `(scheme-bool (cl:and (cl:symbolp ,x)
                            (let ((name (cl:symbol-name ,x)))
                              (cl:and (cl:> (cl:length name) 1)
                                      (cl:char= (cl:char name 0) #\:))))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Primitive name/id introspection (ids 138-140)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%primitive-name id)
  :cl `(cl:if (cl:and (cl:integerp ,id) (cl:< ,id (cl:length *primitive-name-table*)))
              (cl:or (cl:aref *primitive-name-table* ,id) *scheme-false*)
              *scheme-false*))

(define-host-primitive (%primitive-id name)
  :cl `(cl:or (cl:gethash ,name *primitive-name-to-id*) *scheme-false*))

(define-host-primitive (%global-env-frame)
  :cl `(cl:car *global-env*))

;;; ─────────────────────────────────────────────────────────────────────────
;;; User hash tables (ids 141-149)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%make-hash-table)
  :cl `(cl:make-hash-table :test (quote cl:eq)))

(define-host-primitive (hash-table? x)
  :cl `(scheme-bool (cl:hash-table-p ,x)))

(define-host-primitive (hash-ref . args)
  :cl `(let ((ht (cl:car ,args))
             (key (cl:cadr ,args))
             (default (cl:cddr ,args)))
         (cl:multiple-value-bind (val found) (cl:gethash key ht)
                                 (cl:if found val
                                        (cl:if default (cl:car default) *scheme-false*)))))

(define-host-primitive (hash-set! ht key val)
  :cl `(cl:progn (cl:setf (cl:gethash ,key ,ht) ,val) ,val))

(define-host-primitive (hash-remove! ht key)
  :cl `(cl:progn (cl:remhash ,key ,ht) *scheme-false*))

(define-host-primitive (hash-has-key? ht key)
  :cl `(cl:multiple-value-bind (val found) (cl:gethash ,key ,ht)
                               (cl:declare (cl:ignore val))
                               (scheme-bool found)))

(define-host-primitive (hash-keys ht)
  :cl `(let ((keys (quote ())))
         (cl:maphash (cl:lambda (k v) (cl:declare (cl:ignore v)) (cl:push k keys)) ,ht)
         keys))

(define-host-primitive (hash-values ht)
  :cl `(let ((vals (quote ())))
         (cl:maphash (cl:lambda (k v) (cl:declare (cl:ignore k)) (cl:push v vals)) ,ht)
         vals))

(define-host-primitive (hash-count ht)
  :cl `(cl:hash-table-count ,ht))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Yield / time (ids 150-154, 196)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%yield! k)
  :cl `,k)

(define-host-primitive (current-milliseconds)
  :cl `(cl:truncate (cl:* (cl:/ (cl:get-internal-real-time)
                                cl:internal-time-units-per-second)
                          1000)))

(define-host-primitive (sin x)
  :cl `(cl:sin ,x))

(define-host-primitive (cos x)
  :cl `(cl:cos ,x))

(define-host-primitive (sqrt x)
  :cl `(cl:sqrt ,x))

(define-host-primitive (wall-clock-ms)
  :cl `(cl:multiple-value-bind (sec min hour) (cl:get-decoded-time)
                               (cl:+ (cl:* hour 3600000) (cl:* min 60000) (cl:* sec 1000))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Type introspection / save-load support (ids 155-165, 228)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (compiled-procedure? x)
  :cl `(scheme-bool (compiled-procedure-p ,x)))

(define-host-primitive (continuation? x)
  :cl `(scheme-bool (continuation-p ,x)))

(define-host-primitive (primitive? x)
  :cl `(scheme-bool (primitive-procedure-p ,x)))

(define-host-primitive (procedure? x)
  :cl `(scheme-bool (cl:or (compiled-procedure-p ,x)
                           (primitive-procedure-p ,x)
                           (continuation-p ,x))))

(define-host-primitive (compiled-procedure-entry proc)
  :cl `(cl:cadr ,proc))

(define-host-primitive (compiled-procedure-env proc)
  :cl `(cl:caddr ,proc))

(define-host-primitive (continuation-stack k)
  :cl `(cl:cadr ,k))

(define-host-primitive (continuation-conts k)
  :cl `(cl:caddr ,k))

(define-host-primitive (%primitive-id-of prim)
  :cl `(cl:cadr ,prim))

(define-host-primitive (%make-compiled-procedure entry env)
  :cl `(cl:list (quote |compiled-procedure|) ,entry ,env))

(define-host-primitive (%make-continuation stack conts winds)
  :cl `(cl:list (quote |continuation|) ,stack ,conts ,winds))

(define-host-primitive (%make-primitive id)
  :cl `(cl:list (quote |primitive|) ,id))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Env-frame introspection (ids 166-170)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%env-frame? x)
  :cl `(scheme-bool (cl:vectorp ,x)))

(define-host-primitive (%env-frame-names frame)
  :cl `(cl:locally (cl:declare (cl:ignore ,frame)) cl:nil))

(define-host-primitive (%env-frame-vals frame)
  :cl `(cl:coerce ,frame (quote cl:list)))

(define-host-primitive (%env-frame-enclosing frame)
  :cl `(cl:locally (cl:declare (cl:ignore ,frame)) cl:nil))

(define-host-primitive (%make-env-frame names vals enclosing)
  :cl `(cl:locally
        (cl:declare (cl:ignore ,names ,enclosing))
        (cl:coerce ,vals (quote cl:simple-vector))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Winding stack (ids 171-173)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%set-winding-stack! val)
  :cl `(cl:progn (cl:setf *cl-winding-stack* ,val) cl:nil))

(define-host-primitive (%get-winding-stack)
  :cl `(cl:or *cl-winding-stack* cl:nil))

(define-host-primitive (continuation-winds k)
  :cl `(continuation-winds ,k))

;;; ─────────────────────────────────────────────────────────────────────────
;;; String output ports (ids 175-178)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (open-output-string)
  :cl `(ece-make-output-port (cl:make-string-output-stream)))

(define-host-primitive (get-output-string port)
  :cl `(cl:get-output-stream-string (ece-port-stream ,port)))

(define-host-primitive (port-line port)
  :cl `(cl:cadddr ,port))

(define-host-primitive (port-col port)
  :cl `(cl:car (cl:cddddr ,port)))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Port-required write primitives (ids 179-185)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%display-to-port obj port)
  :cl `(let ((stream (ece-port-stream ,port)))
         (ece-output-to-stream ,obj stream (cl:function cl:princ))
         (cl:finish-output stream)
         ,obj))

(define-host-primitive (%write-to-port obj port)
  :cl `(let ((stream (ece-port-stream ,port)))
         (ece-output-to-stream ,obj stream (cl:function cl:prin1))
         (cl:finish-output stream)
         ,obj))

(define-host-primitive (%newline-to-port port)
  :cl `(let ((stream (ece-port-stream ,port)))
         (cl:terpri stream)
         (cl:finish-output stream)
         cl:nil))

(define-host-primitive (%write-char-to-port ch port)
  :cl `(let ((stream (ece-port-stream ,port)))
         (cl:write-char ,ch stream)
         (cl:finish-output stream)
         ,ch))

(define-host-primitive (%write-string-to-port str port)
  :cl `(let ((stream (ece-port-stream ,port)))
         (cl:write-string ,str stream)
         (cl:finish-output stream)
         ,str))

(define-host-primitive (%initial-output-port)
  :cl `(ece-make-output-port (cl:make-synonym-stream (quote cl:*standard-output*))))

(define-host-primitive (%initial-input-port)
  :cl `(ece-make-input-port (cl:make-synonym-stream (quote cl:*standard-input*))))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Process / file system (ids 186-195)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (command-line)
  :cl `(cl:coerce sb-ext:*posix-argv* (quote cl:list)))

(define-host-primitive (exit . args)
  :cl `(let ((code (cl:cond
                    ((cl:null ,args) 0)
                    ((cl:integerp (cl:car ,args)) (cl:car ,args))
                    ((scheme-false-p (cl:car ,args)) 1)
                    ((cl:eq (cl:car ,args) cl:t) 0)
                    (cl:t 0))))
         (sb-ext:exit :code code)))

(define-host-primitive (get-environment-variable name)
  :cl `(cl:or (sb-ext:posix-getenv ,name) *scheme-false*))

(define-host-primitive (%exe-path)
  :cl `(cl:namestring sb-ext:*runtime-pathname*))

(define-host-primitive (%list-directory path)
  :cl `(let ((dir (cl:if (cl:and (cl:stringp ,path)
                                 (cl:> (cl:length ,path) 0)
                                 (cl:not (cl:char= (cl:char ,path
                                                            (cl:1- (cl:length ,path)))
                                                   #\/)))
                         (cl:concatenate (quote cl:string) ,path "/")
                         ,path)))
         (cl:mapcar (cl:lambda (p)
                               (let ((name (cl:file-namestring p)))
                                 (cl:if (cl:or (cl:null name) (cl:zerop (cl:length name)))
                                        (cl:car (cl:last (cl:pathname-directory p)))
                                        name)))
                    (cl:directory (cl:concatenate (quote cl:string) dir "*.*")))))

(define-host-primitive (%file-exists? path)
  :cl `(scheme-bool (cl:probe-file ,path)))

(define-host-primitive (open-binary-input-file filename)
  :cl `(ece-make-input-port
        (cl:open ,filename :direction :input
                 :element-type (quote (cl:unsigned-byte 8)))
        (cl:if (cl:stringp ,filename) ,filename (cl:namestring ,filename))))

(define-host-primitive (read-byte port)
  :cl `(let ((b (cl:read-byte (ece-port-stream ,port) cl:nil *eof-sentinel*)))
         b))

(define-host-primitive (%make-directory path)
  :cl `(cl:progn
        (cl:ensure-directories-exist
         (cl:if (cl:and (cl:stringp ,path)
                        (cl:> (cl:length ,path) 0)
                        (cl:not (cl:char= (cl:char ,path
                                                   (cl:1- (cl:length ,path)))
                                          #\/)))
                (cl:concatenate (quote cl:string) ,path "/")
                ,path))
        cl:nil))

;; Restores the #+unix guard from the pre-migration handwritten version: on
;; non-Unix SBCL the SB-POSIX package isn't loaded, so we resolve CHMOD at
;; runtime via FIND-SYMBOL and no-op when it's unavailable.
(define-host-primitive (%chmod path mode)
  :cl `(let* ((pkg (cl:find-package "SB-POSIX"))
              (chmod-fn (cl:and pkg (cl:find-symbol "CHMOD" pkg))))
         (cl:when (cl:and chmod-fn (cl:fboundp chmod-fn))
                  (cl:funcall chmod-fn ,path ,mode))
         cl:nil))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Boot registration (ids 222-227) — no-ops on CL (already initialized)
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%register-primitive! name id)
  :cl `(cl:locally (cl:declare (cl:ignore ,name ,id)) cl:nil))

(define-host-primitive (%init-asm-syms count)
  :cl `(cl:locally (cl:declare (cl:ignore ,count)) cl:nil))

(define-host-primitive (%store-asm-sym slot name)
  :cl `(cl:locally (cl:declare (cl:ignore ,slot ,name)) cl:nil))

(define-host-primitive (%set-continuation-syms! do-winds-sym winding-stack-sym)
  :cl `(cl:locally (cl:declare (cl:ignore ,do-winds-sym ,winding-stack-sym)) cl:nil))

(define-host-primitive (%set-error-sym! error-sym)
  :cl `(cl:locally (cl:declare (cl:ignore ,error-sym)) cl:nil))

(define-host-primitive (%create-repl-space! name size)
  :cl `(cl:locally (cl:declare (cl:ignore ,name ,size)) cl:nil))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Dev-tooling (ids 229-236) — TCP sockets and file watching for `ece serve`
;;;
;;; CL-only. These are not portable to WASM and exist solely to support the
;;; `ece serve` dev server (see openspec/changes/ece-serve/). The non-blocking
;;; socket helpers wrap usocket; the polling file watcher uses file-write-date
;;; mtimes, which is portable across SBCL targets and good enough for an
;;; interactive dev loop. Helper defuns live in src/runtime.lisp.
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (tcp-listen port host)
  :cl `(usocket:socket-listen ,host ,port
                              :reuse-address cl:t
                              :element-type '(cl:unsigned-byte 8)))

(define-host-primitive (tcp-accept-nowait server)
  :cl `(cl:if (usocket:wait-for-input ,server :timeout 0 :ready-only cl:t)
              (usocket:socket-accept ,server :element-type '(cl:unsigned-byte 8))
              (scheme-bool cl:nil)))

(define-host-primitive (tcp-recv-nowait conn max-bytes)
  :cl `(ece-tcp-recv-nowait-impl ,conn ,max-bytes))

(define-host-primitive (tcp-send-nowait conn bytes)
  :cl `(ece-tcp-send-nowait-impl ,conn ,bytes))

(define-host-primitive (tcp-close handle)
  :cl `(cl:progn (usocket:socket-close ,handle) cl:nil))

(define-host-primitive (fs-watch-start paths)
  :cl `(ece-fs-watch-start-impl ,paths))

(define-host-primitive (fs-watch-poll watcher)
  :cl `(ece-fs-watch-poll-impl ,watcher))

(define-host-primitive (fs-watch-stop watcher)
  :cl `(ece-fs-watch-stop-impl ,watcher))

;;; ─────────────────────────────────────────────────────────────────────────
;;; Introspection (id 237+) — global environment inspection
;;; ─────────────────────────────────────────────────────────────────────────

(define-host-primitive (%global-env-symbols)
  :cl `(let ((keys '()))
         (cl:labels ((find-hf (e)
                              (cl:cond
                               ((cl:null e) cl:nil)
                               ((hash-frame-p (cl:car e)) (cl:car e))
                               (cl:t (find-hf (cl:cdr e))))))
                    (cl:let ((hf (find-hf *global-env*)))
                            (cl:when hf
                                     (cl:maphash (cl:lambda (k v)
                                                            (cl:declare (cl:ignore v))
                                                            (cl:push (cl:symbol-name k) keys))
                                                 (cl:cdr hf))))
                    keys)))

(define-host-primitive (%procedure-params-set! entry-addr params-info)
  ;; Retired in per-procedure-code-objects §11.2: parameter metadata now
  ;; lives on the code-object struct (set at compile time via
  ;; %code-object-set-arity!). The *procedure-params-table* side table
  ;; is gone; this stub is a no-op so stale callers don't crash boot.
  :cl `(cl:progn
        (cl:declare (cl:ignore ,entry-addr ,params-info))
        cl:nil))

(define-host-primitive (%procedure-params proc)
  :cl `(cl:cond
        ((compiled-procedure-p ,proc)
         ;; Archive-loaded code-objects carry arity in the struct itself
         ;; (%code-object-set-arity! at compile time). Post-§11.2, that is
         ;; the only path — the *procedure-params-table* side table retired
         ;; alongside %procedure-params-set!.
         (cl:let* ((entry (cl:cadr ,proc))
                   (co (cl:cond ((code-object-p entry) entry)
                                ((cl:and (cl:consp entry) (code-object-p (cl:car entry)))
                                 (cl:car entry))
                                (cl:t cl:nil)))
                   (params (cl:when co (code-object-arity co))))
                  (cl:or params *scheme-false*)))
        ((primitive-procedure-p ,proc)
         (cl:let* ((id (cl:cadr ,proc))
                   (entry (cl:find id *manifest-entries* :key (cl:function cl:first))))
                  (cl:if entry
                         (cl:let ((arity (cl:third entry)))
                                 (cl:if (cl:= arity -1)
                                        (cl:cons (cl:list "args") 1)
                                        (cl:let ((names cl:nil))
                                                (cl:dotimes (i arity)
                                                            (cl:push (cl:format cl:nil "arg~D" (cl:1+ i)) names))
                                                (cl:cons (cl:nreverse names) 0))))
                         *scheme-false*)))
        (cl:t *scheme-false*)))
