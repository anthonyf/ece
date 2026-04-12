;;;; bootstrap/primitives-auto.lisp
;;;;
;;;; AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND.
;;;;
;;;; Source: primitives.def + src/primitives.scm
;;;; Generator: src/codegen-cl.scm
;;;; Regenerate: make bootstrap
;;;;
;;;; This file contains one (defun ece-NAME ...) per core/cl
;;;; primitive. The CL runtime loads it during boot, after
;;;; helper definitions and before init-primitive-dispatch-tables.

(in-package :ece)

(defun ece-%chmod (path mode)
  (let* ((pkg (cl:find-package "SB-POSIX")) (chmod-fn (cl:and pkg (cl:find-symbol "CHMOD" pkg)))) (cl:when (cl:and chmod-fn (cl:fboundp chmod-fn)) (cl:funcall chmod-fn path mode)) cl:nil))

(defun ece-%create-repl-space! (name size)
  (cl:locally (cl:declare (cl:ignore name size)) cl:nil))

(defun ece-%create-space (name)
  (create-space name))

(defun ece-%current-space-id ()
  *current-space-id*)

(defun ece-%display-to-port (obj port)
  (let ((stream (ece-port-stream port))) (ece-output-to-stream obj stream (cl:function cl:princ)) (cl:finish-output stream) obj))

(defun ece-%env-frame-enclosing (frame)
  (cl:locally (cl:declare (cl:ignore frame)) cl:nil))

(defun ece-%env-frame-names (frame)
  (cl:locally (cl:declare (cl:ignore frame)) cl:nil))

(defun ece-%env-frame-vals (frame)
  (cl:coerce frame 'cl:list))

(defun ece-%env-frame? (x)
  (scheme-bool (cl:vectorp x)))

(defun ece-%eq-hash-has-key? (ht key)
  (cl:multiple-value-bind (val found) (cl:gethash key ht) (cl:declare (cl:ignore val)) (scheme-bool found)))

(defun ece-%eq-hash-keys (ht)
  (let ((keys '())) (cl:maphash (cl:lambda (k v) (cl:declare (cl:ignore v)) (cl:push k keys)) ht) keys))

(defun ece-%eq-hash-ref (ht key)
  (cl:multiple-value-bind (val found) (cl:gethash key ht) (cl:if found val *scheme-false*)))

(defun ece-%eq-hash-set! (ht key val)
  (cl:progn (cl:setf (cl:gethash key ht) val) ht))

(defun ece-%eq-hash-table ()
  (cl:make-hash-table :test 'cl:eq))

(defun ece-%exe-path ()
  (cl:namestring sb-ext:*runtime-pathname*))

(defun ece-%file-exists? (path)
  (scheme-bool (cl:probe-file path)))

(defun ece-%get-winding-stack ()
  (cl:or *cl-winding-stack* cl:nil))

(defun ece-%global-env-frame ()
  (cl:car *global-env*))

(defun ece-%hash-frame-entries (frame)
  (cl:progn (cl:unless (cl:and (cl:consp frame) (cl:hash-table-p (cl:cdr frame))) (cl:error "ece-%hash-frame-entries: expected (:hash-frame . <hash-table>), got ~S" frame)) (let ((entries '())) (cl:maphash (cl:lambda (k v) (cl:push (cl:cons k v) entries)) (cl:cdr frame)) entries)))

(defun ece-%hash-frame-set! (frame key val)
  (cl:progn (cl:setf (cl:gethash key (cl:cdr frame)) val) frame))

(defun ece-%hash-frame? (frame)
  (scheme-bool (hash-frame-p frame)))

(defun ece-%init-asm-syms (count)
  (cl:locally (cl:declare (cl:ignore count)) cl:nil))

(defun ece-%initial-input-port ()
  (ece-make-input-port (cl:make-synonym-stream 'cl:*standard-input*)))

(defun ece-%initial-output-port ()
  (ece-make-output-port (cl:make-synonym-stream 'cl:*standard-output*)))

(defun ece-%instruction-vector-length ()
  (cl:fill-pointer (compilation-space-resolved-instructions (get-space '|bootstrap|))))

(defun ece-%instruction-vector-push! (source-instr)
  (let* ((cs (get-space '|bootstrap|)) (instrs (compilation-space-instructions cs)) (resolved (compilation-space-resolved-instructions cs))) (cl:vector-push-extend source-instr instrs) (cl:vector-push-extend (resolve-operations source-instr) resolved) cl:nil))

(defun ece-%intern-ece (s)
  (cl:intern s :ece))

(defun ece-%label-table-entries ()
  (let ((entries '())) (cl:maphash (cl:lambda (label pc) (cl:push (cl:cons label pc) entries)) (compilation-space-label-table (get-space '|bootstrap|))) entries))

(defun ece-%label-table-ref (label)
  (cl:gethash label (compilation-space-label-table (get-space '|bootstrap|))))

(defun ece-%label-table-set! (label pc)
  (cl:progn (cl:setf (cl:gethash label (compilation-space-label-table (get-space '|bootstrap|))) pc) cl:nil))

(defun ece-%list-directory (path)
  (let ((dir (cl:if (cl:and (cl:stringp path) (cl:> (cl:length path) 0) (cl:not (cl:char= (cl:char path (cl:1- (cl:length path))) #\/))) (cl:concatenate 'cl:string path "/") path))) (cl:mapcar (cl:lambda (p) (let ((name (cl:file-namestring p))) (cl:if (cl:or (cl:null name) (cl:zerop (cl:length name))) (cl:car (cl:last (cl:pathname-directory p))) name))) (cl:directory (cl:concatenate 'cl:string dir "*.*")))))

(defun ece-%macro-table-entries ()
  (let ((entries '())) (cl:maphash (cl:lambda (name proc) (cl:push (cl:cons name proc) entries)) *compile-time-macros*) entries))

(defun ece-%make-compiled-procedure (entry env)
  (cl:list '|compiled-procedure| entry env))

(defun ece-%make-continuation (stack conts winds)
  (cl:list '|continuation| stack conts winds))

(defun ece-%make-directory (path)
  (cl:progn (cl:ensure-directories-exist (cl:if (cl:and (cl:stringp path) (cl:> (cl:length path) 0) (cl:not (cl:char= (cl:char path (cl:1- (cl:length path))) #\/))) (cl:concatenate 'cl:string path "/") path)) cl:nil))

(defun ece-%make-env-frame (names vals enclosing)
  (cl:locally (cl:declare (cl:ignore names enclosing)) (cl:coerce vals 'cl:simple-vector)))

(defun ece-%make-hash-frame ()
  (cl:cons :hash-frame (cl:make-hash-table :test 'cl:eq)))

(defun ece-%make-hash-table ()
  (cl:make-hash-table :test 'cl:eq))

(defun ece-%make-primitive (id)
  (cl:list '|primitive| id))

(defun ece-%newline-to-port (port)
  (let ((stream (ece-port-stream port))) (cl:terpri stream) (cl:finish-output stream) cl:nil))

(defun ece-%platform-primitives ()
  (let ((result '())) (cl:maphash (cl:lambda (id available) (cl:declare (cl:ignore available)) (let ((name (cl:aref *primitive-name-table* id))) (cl:when name (cl:push name result)))) *primitive-available-ids*) result))

(defun ece-%primitive-id (name)
  (cl:or (cl:gethash name *primitive-name-to-id*) *scheme-false*))

(defun ece-%primitive-id-of (prim)
  (cl:cadr prim))

(defun ece-%primitive-name (id)
  (cl:if (cl:and (cl:integerp id) (cl:< id (cl:length *primitive-name-table*))) (cl:or (cl:aref *primitive-name-table* id) *scheme-false*) *scheme-false*))

(defun ece-%procedure-name-set! (pc-or-qualified name)
  (cl:progn (cl:setf (cl:gethash pc-or-qualified *procedure-name-table*) name) cl:nil))

(defun ece-%raw-error (&rest args)
  (cl:apply (cl:function cl:error) args))

(defun ece-%register-primitive! (name id)
  (cl:locally (cl:declare (cl:ignore name id)) cl:nil))

(defun ece-%set-continuation-syms! (do-winds-sym winding-stack-sym)
  (cl:locally (cl:declare (cl:ignore do-winds-sym winding-stack-sym)) cl:nil))

(defun ece-%set-current-space-id! (space-id)
  (cl:setf *current-space-id* space-id))

(defun ece-%set-error-sym! (error-sym)
  (cl:locally (cl:declare (cl:ignore error-sym)) cl:nil))

(defun ece-%set-winding-stack! (val)
  (cl:progn (cl:setf *cl-winding-stack* val) cl:nil))

(defun ece-%space-count ()
  (cl:hash-table-count *space-registry*))

(defun ece-%space-instruction-length (space-id)
  (cl:fill-pointer (compilation-space-instructions (get-space space-id))))

(defun ece-%space-instruction-push! (space-id source-instr)
  (let* ((cs (get-space space-id)) (instrs (compilation-space-instructions cs)) (resolved (compilation-space-resolved-instructions cs))) (cl:vector-push-extend source-instr instrs) (cl:vector-push-extend (resolve-operations source-instr) resolved) cl:nil))

(defun ece-%space-label-entries (space-id)
  (let ((entries '())) (cl:maphash (cl:lambda (label pc) (cl:push (cl:cons label pc) entries)) (compilation-space-label-table (get-space space-id))) entries))

(defun ece-%space-label-ref (space-id label)
  (cl:gethash label (compilation-space-label-table (get-space space-id))))

(defun ece-%space-label-set! (space-id label local-pc)
  (cl:progn (cl:setf (cl:gethash label (compilation-space-label-table (get-space space-id))) local-pc) cl:nil))

(defun ece-%space-name (space-id)
  (compilation-space-name (get-space space-id)))

(defun ece-%space-source-ref (space-id index)
  (cl:aref (compilation-space-instructions (get-space space-id)) index))

(defun ece-%store-asm-sym (slot name)
  (cl:locally (cl:declare (cl:ignore slot name)) cl:nil))

(defun ece-%write-char-to-port (ch port)
  (let ((stream (ece-port-stream port))) (cl:write-char ch stream) (cl:finish-output stream) ch))

(defun ece-%write-string-to-port (str port)
  (let ((stream (ece-port-stream port))) (cl:write-string str stream) (cl:finish-output stream) str))

(defun ece-%write-to-port (obj port)
  (let ((stream (ece-port-stream port))) (ece-output-to-stream obj stream (cl:function cl:prin1)) (cl:finish-output stream) obj))

(defun ece-%yield! (k)
  k)

(defun ece-* (&rest args)
  (cl:apply (cl:function cl:*) args))

(defun ece-+ (&rest args)
  (cl:apply (cl:function cl:+) args))

(defun ece-- (&rest args)
  (cl:apply (cl:function cl:-) args))

(defun ece-/ (&rest args)
  (cl:apply (cl:function cl:/) args))

(defun ece-< (&rest args)
  (scheme-bool (cl:apply (cl:function cl:<) args)))

(defun ece-= (&rest args)
  (scheme-bool (cl:apply (cl:function cl:=) args)))

(defun ece-> (&rest args)
  (scheme-bool (cl:apply (cl:function cl:>) args)))

(defun ece-apply-compiled-procedure (proc args)
  (execute-compiled-call proc args))

(defun ece-arithmetic-shift (n shift)
  (cl:ash n shift))

(defun ece-bitwise-and (&rest args)
  (cl:apply (cl:function cl:logand) args))

(defun ece-bitwise-not (n)
  (cl:lognot n))

(defun ece-bitwise-or (&rest args)
  (cl:apply (cl:function cl:logior) args))

(defun ece-bitwise-xor (&rest args)
  (cl:apply (cl:function cl:logxor) args))

(defun ece-car (p)
  (cl:car p))

(defun ece-cdr (p)
  (cl:cdr p))

(defun ece-char->integer (ch)
  (cl:char-code ch))

(defun ece-char-ready? (port)
  (scheme-bool (cl:listen (ece-port-stream port))))

(defun ece-char? (x)
  (scheme-bool (cl:characterp x)))

(defun ece-close-input-port (port)
  (cl:progn (cl:close (ece-port-stream port)) cl:nil))

(defun ece-close-output-port (port)
  (cl:progn (cl:close (ece-port-stream port)) cl:nil))

(defun ece-command-line ()
  (cl:coerce sb-ext:*posix-argv* 'cl:list))

(defun ece-compiled-procedure-entry (proc)
  (cl:cadr proc))

(defun ece-compiled-procedure-env (proc)
  (cl:caddr proc))

(defun ece-compiled-procedure? (x)
  (scheme-bool (compiled-procedure-p x)))

(defun ece-cons (a d)
  (cl:cons a d))

(defun ece-continuation-conts (k)
  (cl:caddr k))

(defun ece-continuation-stack (k)
  (cl:cadr k))

(defun ece-continuation-winds (k)
  (continuation-winds k))

(defun ece-continuation? (x)
  (scheme-bool (continuation-p x)))

(defun ece-cos (x)
  (cl:cos x))

(defun ece-current-milliseconds ()
  (cl:truncate (cl:* (cl:/ (cl:get-internal-real-time) cl:internal-time-units-per-second) 1000)))

(defun ece-eof? (obj)
  (scheme-bool (cl:eq obj *eof-sentinel*)))

(defun ece-eq? (x y)
  (scheme-bool (cl:eq x y)))

(defun ece-exact->inexact (x)
  (cl:coerce x 'cl:single-float))

(defun ece-execute-from-pc (&rest args)
  (let ((start-pc (cl:car args)) (env (cl:if (cl:cdr args) (cl:cadr args) *global-env*))) (execute-instructions (qualified-space-id start-pc) (qualified-local-pc start-pc) env)))

(defun ece-exit (&rest args)
  (let ((code (cl:cond ((cl:null args) 0) ((cl:integerp (cl:car args)) (cl:car args)) ((scheme-false-p (cl:car args)) 1) ((cl:eq (cl:car args) cl:t) 0) (cl:t 0)))) (sb-ext:exit :code code)))

(defun ece-extend-environment (&rest args)
  (cl:apply (cl:function extend-environment) args))

(defun ece-floor (x)
  (cl:values (cl:floor x)))

(defun ece-get-environment-variable (name)
  (cl:or (sb-ext:posix-getenv name) *scheme-false*))

(defun ece-get-macro (name)
  (cl:or (cl:gethash name *compile-time-macros*) *scheme-false*))

(defun ece-get-output-string (port)
  (cl:get-output-stream-string (ece-port-stream port)))

(defun ece-hash-count (ht)
  (cl:hash-table-count ht))

(defun ece-hash-has-key? (ht key)
  (cl:multiple-value-bind (val found) (cl:gethash key ht) (cl:declare (cl:ignore val)) (scheme-bool found)))

(defun ece-hash-keys (ht)
  (let ((keys '())) (cl:maphash (cl:lambda (k v) (cl:declare (cl:ignore v)) (cl:push k keys)) ht) keys))

(defun ece-hash-ref (&rest args)
  (let ((ht (cl:car args)) (key (cl:cadr args)) (default (cl:cddr args))) (cl:multiple-value-bind (val found) (cl:gethash key ht) (cl:if found val (cl:if default (cl:car default) *scheme-false*)))))

(defun ece-hash-remove! (ht key)
  (cl:progn (cl:remhash key ht) *scheme-false*))

(defun ece-hash-set! (ht key val)
  (cl:progn (cl:setf (cl:gethash key ht) val) val))

(defun ece-hash-table? (x)
  (scheme-bool (cl:hash-table-p x)))

(defun ece-hash-values (ht)
  (let ((vals '())) (cl:maphash (cl:lambda (k v) (cl:declare (cl:ignore k)) (cl:push v vals)) ht) vals))

(defun ece-input-port? (x)
  (scheme-bool (cl:and (cl:consp x) (cl:eq (cl:car x) 'input-port))))

(defun ece-integer->char (n)
  (cl:code-char n))

(defun ece-integer? (x)
  (scheme-bool (cl:integerp x)))

(defun ece-keyword? (x)
  (scheme-bool (cl:and (cl:symbolp x) (let ((name (cl:symbol-name x))) (cl:and (cl:> (cl:length name) 1) (cl:char= (cl:char name 0) #\:))))))

(defun ece-make-parameter (&rest args)
  (cl:list 'parameter (cl:cons (cl:car args) (cl:if (cl:cdr args) (cl:cadr args) cl:nil))))

(defun ece-make-vector (&rest args)
  (cl:make-array (cl:car args) :initial-element (cl:if (cl:cdr args) (cl:cadr args) 0)))

(defun ece-null? (x)
  (scheme-bool (cl:null x)))

(defun ece-number? (x)
  (scheme-bool (cl:numberp x)))

(defun ece-open-binary-input-file (filename)
  (ece-make-input-port (cl:open filename :direction :input :element-type '(cl:unsigned-byte 8)) (cl:if (cl:stringp filename) filename (cl:namestring filename))))

(defun ece-open-binary-output-file (filename)
  (ece-make-output-port (cl:open filename :direction :output :element-type '(cl:unsigned-byte 8) :if-exists :supersede :if-does-not-exist :create) (cl:if (cl:stringp filename) filename (cl:namestring filename))))

(defun ece-open-input-file (filename)
  (ece-make-input-port (cl:open filename :direction :input) (cl:if (cl:stringp filename) filename (cl:namestring filename))))

(defun ece-open-input-string (str)
  (ece-make-input-port (cl:make-string-input-stream str)))

(defun ece-open-output-file (filename)
  (ece-make-output-port (cl:open filename :direction :output :if-exists :supersede :if-does-not-exist :create) (cl:if (cl:stringp filename) filename (cl:namestring filename))))

(defun ece-open-output-string ()
  (ece-make-output-port (cl:make-string-output-stream)))

(defun ece-output-port? (x)
  (scheme-bool (cl:and (cl:consp x) (cl:eq (cl:car x) 'output-port))))

(defun ece-pair? (x)
  (scheme-bool (cl:consp x)))

(defun ece-parameter? (x)
  (scheme-bool (cl:and (cl:listp x) (cl:eq (cl:car x) 'parameter))))

(defun ece-peek-char (port)
  (let ((ch (cl:peek-char cl:nil (ece-port-stream port) cl:nil cl:nil))) (cl:or ch *eof-sentinel*)))

(defun ece-platform-has? (name)
  (let ((id (cl:gethash name *primitive-name-to-id*))) (scheme-bool (cl:and id (cl:gethash id *primitive-available-ids*)))))

(defun ece-port-col (port)
  (cl:car (cl:cddddr port)))

(defun ece-port-line (port)
  (cl:cadddr port))

(defun ece-port? (x)
  (scheme-bool (cl:or (cl:and (cl:consp x) (cl:eq (cl:car x) 'input-port)) (cl:and (cl:consp x) (cl:eq (cl:car x) 'output-port)))))

(defun ece-primitive? (x)
  (scheme-bool (primitive-procedure-p x)))

(defun ece-procedure? (x)
  (scheme-bool (cl:or (compiled-procedure-p x) (primitive-procedure-p x) (continuation-p x))))

(defun ece-read-byte (port)
  (let ((b (cl:read-byte (ece-port-stream port) cl:nil *eof-sentinel*))) b))

(defun ece-read-char (port)
  (let* ((p port) (ch (cl:read-char (ece-port-stream p) cl:nil cl:nil))) (cl:when ch (cl:if (cl:char= ch #\Newline) (cl:progn (set-ece-port-line! p (cl:1+ (ece-port-line p))) (set-ece-port-col! p 0)) (set-ece-port-col! p (cl:1+ (ece-port-col p))))) (cl:or ch *eof-sentinel*)))

(defun ece-read-line (port)
  (let ((stream (ece-port-stream port))) (cl:multiple-value-bind (line missing-newline-p) (cl:read-line stream cl:nil cl:nil) (cl:declare (cl:ignore missing-newline-p)) (cl:or line *eof-sentinel*))))

(defun ece-set-car! (pair val)
  (cl:rplaca pair val))

(defun ece-set-cdr! (pair val)
  (cl:rplacd pair val))

(defun ece-set-macro! (name def)
  (cl:progn (cl:setf (cl:gethash name *compile-time-macros*) def) def))

(defun ece-sin (x)
  (cl:sin x))

(defun ece-sleep (seconds)
  (cl:progn (cl:sleep seconds) cl:nil))

(defun ece-sqrt (x)
  (cl:sqrt x))

(defun ece-string (ch)
  (cl:string ch))

(defun ece-string->symbol (s)
  (cl:intern s :ece))

(defun ece-string-append (&rest strings)
  (cl:apply (cl:function cl:concatenate) 'cl:string strings))

(defun ece-string-length (s)
  (cl:length s))

(defun ece-string-ref (s i)
  (cl:char s i))

(defun ece-string? (x)
  (scheme-bool (cl:stringp x)))

(defun ece-substring (s start end)
  (cl:subseq s start end))

(defun ece-symbol->string (s)
  (cl:symbol-name s))

(defun ece-symbol? (x)
  (scheme-bool (cl:and (cl:symbolp x) x)))

(defun ece-trace (name)
  (let ((original (lookup-variable-value name *global-env*))) (cl:when (cl:gethash name *traced-procedures*) (cl:return-from ece-trace name)) (cl:setf (cl:gethash name *traced-procedures*) original) (let ((wrapper-sym (cl:intern (cl:format cl:nil "TRACE-~A" name) :ece))) (cl:setf (cl:symbol-function wrapper-sym) (cl:lambda (cl:&rest args) (let ((indent (cl:make-string (cl:* 2 *trace-depth*) :initial-element #\Space))) (cl:format cl:t "~A(~A~{ ~S~})~%" indent name args) (cl:incf *trace-depth*) (let ((result (cl:if (compiled-procedure-p original) (execute-compiled-call original args) (apply-primitive-procedure original args)))) (cl:decf *trace-depth*) (cl:format cl:t "~A=> ~S~%" indent result) result)))) (set-variable-value! name (cl:list '|primitive| wrapper-sym) *global-env*)) name))

(defun ece-truncate (x)
  (cl:values (cl:truncate x)))

(defun ece-try-eval (expr)
  (cl:handler-case (evaluate expr) (cl:error (c) (cl:format cl:t "Error: ~A~%" c) (cl:finish-output) *eof-sentinel*)))

(defun ece-untrace (name)
  (let ((original (cl:gethash name *traced-procedures*))) (cl:when original (set-variable-value! name original *global-env*) (cl:remhash name *traced-procedures*)) name))

(defun ece-vector (&rest args)
  (cl:apply (cl:function cl:vector) args))

(defun ece-vector-length (vec)
  (cl:length vec))

(defun ece-vector-ref (vec idx)
  (cl:aref vec idx))

(defun ece-vector-set! (vec idx val)
  (cl:progn (cl:setf (cl:aref vec idx) val) val))

(defun ece-vector? (x)
  (scheme-bool (cl:and (cl:vectorp x) (cl:not (cl:stringp x)))))

(defun ece-wall-clock-ms ()
  (cl:multiple-value-bind (sec min hour) (cl:get-decoded-time) (cl:+ (cl:* hour 3600000) (cl:* min 60000) (cl:* sec 1000))))

(defun ece-with-input-from-file (filename thunk)
  (let ((port (ece-open-input-file filename))) (cl:unwind-protect (let ((cl:*standard-input* (ece-port-stream port))) (apply-ece-procedure thunk cl:nil)) (ece-close-input-port port))))

(defun ece-with-output-to-file (filename thunk)
  (let ((port (ece-open-output-file filename))) (cl:unwind-protect (let ((cl:*standard-output* (ece-port-stream port))) (apply-ece-procedure thunk cl:nil)) (ece-close-output-port port))))

(defun ece-write-byte (byte port)
  (cl:progn (cl:write-byte byte (ece-port-stream port)) byte))

(defun ece-write-to-string (x)
  (cl:cond ((scheme-false-p x) "#f") ((cl:eq x cl:t) "#t") ((cl:null x) "()") ((cl:or (compiled-procedure-p x) (primitive-procedure-p x)) (format-ece-proc x)) ((cl:hash-table-p x) (cl:with-output-to-string (s) (format-ece-hash-table x s (cl:lambda (v str) (ece-display-to-stream v str))))) (cl:t (cl:let ((cl:*print-circle* cl:t)) (cl:princ-to-string x)))))

(defun ece-write-to-string-flat (x)
  (let ((cl:*print-circle* cl:nil) (cl:*print-pretty* cl:nil) (cl:*package* (cl:find-package :ece)) (cl:*readtable* *preserve-readtable*)) (cl:with-output-to-string (s) (ece-print-flat x s))))

