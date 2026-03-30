;;; ECE WebAssembly Runtime
;;; =====================
;;; Hand-written WAT using WasmGC for the ECE register machine.
;;;
;;; Assembler: binaryen's wasm-as (--enable-gc)
;;; Build:     make wasm
;;;
;;; Architecture:
;;;   - 7 opcodes: assign, test, branch, goto, save, restore, perform
;;;   - 6 registers: val, env, proc, argl, continue, stack
;;;   - WasmGC-managed values (no custom GC)
;;;   - Primitives dispatched by stable numeric ID (primitives.def)

(module

  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 0: JS Imports (must precede all definitions)
  ;; ═══════════════════════════════════════════════════════════════════

  ;; I/O — delegated to JS glue
  (import "io" "display_string" (func $js-display-string (param i32)))  ;; length of UTF-16 chars in linear memory
  (import "io" "display_number" (func $js-display-number (param f64)))
  (import "io" "newline" (func $js-newline))

  ;; .ececb loading — JS fetches the bytes, passes them in
  (import "loader" "fetch_ececb" (func $js-fetch-ececb (param externref) (result externref)))
  (import "io" "trace_pc" (func $js-trace-pc (param i32 i32)))
  (import "io" "runtime_error" (func $js-runtime-error (param i32)))
  ;; Save/restore trace: pc, space-id, is-save(1)/is-restore(0), register-id, value-type, stack-depth
  (import "io" "trace_save_restore" (func $js-trace-sr (param i32 i32 i32 i32 i32 i32)))

  ;; Timing — performance.now() for current-milliseconds
  (import "timing" "performance_now" (func $js-performance-now (result i32)))

  ;; Canvas, math (sin/cos), and wall-clock-ms are now in browser-lib.scm via FFI

  ;; JavaScript FFI — generic JS interop
  (import "ffi" "eval" (func $js-ffi-eval (param i32 i32) (result i32)))
  (import "ffi" "get" (func $js-ffi-get (param i32 i32 i32) (result i32)))
  (import "ffi" "set" (func $js-ffi-set (param i32 i32 i32 i32)))
  (import "ffi" "call" (func $js-ffi-call (param i32 i32 i32 i32) (result i32)))
  (import "ffi" "callback" (func $js-ffi-callback (param i32) (result i32)))
  ;; Type conversion helpers
  (import "ffi" "to_number" (func $js-ffi-to-number (param i32) (result f64)))
  (import "ffi" "to_string" (func $js-ffi-to-string (param i32) (result i32)))
  (import "ffi" "from_number" (func $js-ffi-from-number (param f64) (result i32)))
  (import "ffi" "from_string" (func $js-ffi-from-string (param i32 i32) (result i32)))
  (import "ffi" "release" (func $js-ffi-release (param i32)))
  (import "ffi" "is_null" (func $js-ffi-is-null (param i32) (result i32)))

  ;; localStorage — file I/O backing store
  ;; storage_read: filename (UTF-16 in linear memory, len chars) → content length
  ;;   JS reads localStorage[filename], writes content to linear memory at offset 0, returns char count
  (import "storage" "read" (func $js-storage-read (param i32) (result i32)))
  ;; storage_write: filename len, content offset, content len → void
  ;;   JS reads filename from mem[0..fname_len], content from mem[fname_len*2..], writes to localStorage
  (import "storage" "write" (func $js-storage-write (param i32 i32 i32)))


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 1: WasmGC Type Definitions
  ;; ═══════════════════════════════════════════════════════════════════
  ;; All ECE values are (ref eq). Type predicates use ref.test.
  ;; Fixnums are i31ref (immediate, 31-bit signed, no allocation).

  ;; --- String (UTF-16) ---
  ;; Array of 16-bit code units. O(1) indexing for BMP characters.
  ;; Defined first because $symbol references it.
  (type $string (array (mut i16)))

  ;; --- Pair (cons cell) ---
  ;; Mutable car and cdr, the fundamental Lisp building block.
  (type $pair (struct
    (field $car (mut (ref null eq)))
    (field $cdr (mut (ref null eq)))))

  ;; --- Symbol ---
  ;; Interned: two symbols with the same name share the same ID.
  ;; Equality check is just i32 comparison on $id.
  (type $symbol (struct
    (field $id i32)
    (field $name (ref $string))))

  ;; --- Boxed float ---
  ;; f64 value wrapped in a GC struct (i31ref can't hold floats).
  (type $float-box (struct (field $val f64)))

  ;; --- Vector ---
  ;; Mutable array of ECE values.
  (type $vector (array (mut (ref null eq))))

  ;; --- Compiled procedure ---
  ;; Entry point is (space-id, pc) pair. Captures its definition env.
  (type $compiled-proc (struct
    (field $space i32)
    (field $pc i32)
    (field $env (ref null eq))))

  ;; --- Continuation ---
  ;; Captured by call/cc: the stack, return address, and winding stack at capture time.
  (type $continuation (struct
    (field $stack (ref null eq))
    (field $conts (ref null eq))
    (field $winds (ref null eq))))

  ;; --- Primitive ---
  ;; Just a numeric ID into the dispatch table (from primitives.def).
  (type $primitive (struct (field $id i32)))

  ;; --- Parameter (R7RS) ---
  ;; A mutable value cell. make-parameter creates one.
  (type $parameter (struct
    (field $value (mut (ref null eq)))))

  ;; --- Hash table ---
  ;; Keys and values stored as parallel arrays for simplicity.
  ;; TODO: Consider more efficient representation later.
  (type $hash-keys (array (mut (ref null eq))))
  (type $hash-vals (array (mut (ref null eq))))
  (type $hash-table (struct
    (field $keys (mut (ref $hash-keys)))
    (field $vals (mut (ref $hash-vals)))
    (field $count (mut i32))))

  ;; --- JS FFI reference ---
  ;; Opaque wrapper around an i32 index into the JS-side handle table.
  ;; The $tag field distinguishes this from $primitive (which also has a single i32),
  ;; preventing binaryen struct type deduplication.
  (type $js-ref (struct (field $idx i32) (field $tag i32)))

  ;; --- Port ---
  ;; Buffer-based I/O port. Used for file I/O (localStorage backing),
  ;; string ports, and console I/O.
  ;; dir: 0=input, 1=output. For output ports, $pos tracks write length.
  ;; For input ports, $pos tracks read position.
  (type $port-buf (array (mut i16)))  ;; growable UTF-16 buffer
  (type $port (struct
    (field $buf  (mut (ref null $port-buf)))  ;; content buffer
    (field $pos  (mut i32))                   ;; read pos (input) / write length (output)
    (field $cap  (mut i32))                   ;; buffer capacity
    (field $name (ref null $string))          ;; filename (null for string/console ports)
    (field $dir  i32)                         ;; 0=input, 1=output
    (field $open (mut i32))))                ;; 1=open, 0=closed

  ;; --- Environment frame ---
  ;; SICP-style: a frame holds variable values and a link to the
  ;; enclosing frame. Variable names stored for lookup-variable-value
  ;; (global access); lexical-ref uses depth+offset directly.
  (type $val-array (array (mut (ref null eq))))
  (type $env-frame (struct
    (field $names (mut (ref null eq)))     ;; list of symbols (for name lookup)
    (field $vals (mut (ref $val-array)))   ;; values by position
    (field $enclosing (ref null eq))))     ;; parent frame (immutable)


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 2: Singleton Constants
  ;; ═══════════════════════════════════════════════════════════════════
  ;; #t, #f, '(), eof, void — distinguished by identity (ref.eq).
  ;; Encoded as i31ref with specific tag values.
  ;;
  ;; Tag scheme for i31ref:
  ;;   bit 0 = 0  →  fixnum (value in bits 1-30, signed)
  ;;   bit 0 = 1  →  special immediate:
  ;;     0x01 = #f
  ;;     0x03 = #t
  ;;     0x05 = '() (nil)
  ;;     0x07 = eof
  ;;     0x09 = void
  ;;     0x0B+ = character (codepoint << 4 | 0x0B)
  ;;     0x0D+ = primitive ID (id << 4 | 0x0D)

  ;; --- Tag constants ---
  ;; Fixnums: value << 1 (bit 0 = 0)
  ;; Specials: specific odd values

  (global $false (ref eq) (ref.i31 (i32.const 1)))   ;; 0x01
  (global $true  (ref eq) (ref.i31 (i32.const 3)))   ;; 0x03
  (global $nil   (ref eq) (ref.i31 (i32.const 5)))   ;; 0x05
  (global $eof   (ref eq) (ref.i31 (i32.const 7)))   ;; 0x07
  (global $void  (ref eq) (ref.i31 (i32.const 9)))   ;; 0x09

  ;; Error message strings (UTF-16 arrays)
  ;; "Unbound variable: " (18 chars)
  (global $err-unbound-var (ref $string)
    (array.new_fixed $string 18
      (i32.const 85)(i32.const 110)(i32.const 98)(i32.const 111)(i32.const 117)(i32.const 110)
      (i32.const 100)(i32.const 32)(i32.const 118)(i32.const 97)(i32.const 114)(i32.const 105)
      (i32.const 97)(i32.const 98)(i32.const 108)(i32.const 101)(i32.const 58)(i32.const 32)))


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 3: Value Constructors and Accessors
  ;; ═══════════════════════════════════════════════════════════════════

  ;; --- Fixnum (i31ref, tagged with bit 0 = 0) ---

  (func $make-fixnum (param $n i32) (result (ref eq))
    ;; Encode: shift left 1 (bit 0 = 0 means fixnum)
    (ref.i31 (i32.shl (local.get $n) (i32.const 1)))
  )

  (func $fixnum-value (param $v (ref i31)) (result i32)
    ;; Decode: arithmetic shift right 1 (preserves sign)
    (i32.shr_s (i31.get_s (local.get $v)) (i32.const 1))
  )

  (func $is-fixnum (param $v (ref null eq)) (result i32)
    ;; A value is a fixnum if it's an i31ref AND bit 0 is 0
    (if (result i32) (ref.test (ref i31) (local.get $v))
      (then
        (i32.eqz (i32.and
          (i31.get_s (ref.cast (ref i31) (local.get $v)))
          (i32.const 1))))
      (else (i32.const 0)))
  )

  ;; --- Character (i31ref, tagged: codepoint << 4 | 0x0B) ---

  (func $make-char (param $cp i32) (result (ref eq))
    (ref.i31 (i32.or (i32.shl (local.get $cp) (i32.const 4)) (i32.const 11)))
  )

  (func $char-codepoint (param $v (ref i31)) (result i32)
    (i32.shr_u (i31.get_s (local.get $v)) (i32.const 4))
  )

  (func $is-char (param $v (ref null eq)) (result i32)
    ;; i31ref with low 4 bits = 0x0B
    (if (result i32) (ref.test (ref i31) (local.get $v))
      (then
        (i32.eq
          (i32.and (i31.get_s (ref.cast (ref i31) (local.get $v))) (i32.const 15))
          (i32.const 11)))
      (else (i32.const 0)))
  )

  ;; --- Pair ---

  (func $cons (param $car (ref null eq)) (param $cdr (ref null eq)) (result (ref $pair))
    (struct.new $pair (local.get $car) (local.get $cdr))
  )

  (func $car (param $p (ref $pair)) (result (ref null eq))
    (struct.get $pair $car (local.get $p))
  )

  (func $cdr (param $p (ref $pair)) (result (ref null eq))
    (struct.get $pair $cdr (local.get $p))
  )

  (func $set-car! (param $p (ref $pair)) (param $v (ref null eq))
    (struct.set $pair $car (local.get $p) (local.get $v))
  )

  (func $set-cdr! (param $p (ref $pair)) (param $v (ref null eq))
    (struct.set $pair $cdr (local.get $p) (local.get $v))
  )

  ;; --- Float ---

  (func $make-float (param $v f64) (result (ref $float-box))
    (struct.new $float-box (local.get $v))
  )

  (func $float-value (param $v (ref $float-box)) (result f64)
    (struct.get $float-box $val (local.get $v))
  )

  ;; --- Compiled procedure ---

  (func $make-compiled-proc (param $space i32) (param $pc i32) (param $env (ref null eq)) (result (ref $compiled-proc))
    (struct.new $compiled-proc (local.get $space) (local.get $pc) (local.get $env))
  )

  (func $compiled-proc-space (param $p (ref $compiled-proc)) (result i32)
    (struct.get $compiled-proc $space (local.get $p))
  )

  (func $compiled-proc-pc (param $p (ref $compiled-proc)) (result i32)
    (struct.get $compiled-proc $pc (local.get $p))
  )

  (func $compiled-proc-env (param $p (ref $compiled-proc)) (result (ref null eq))
    (struct.get $compiled-proc $env (local.get $p))
  )

  ;; --- Primitive ---

  (func $make-primitive (param $id i32) (result (ref $primitive))
    (struct.new $primitive (local.get $id))
  )

  (func $primitive-id (param $p (ref $primitive)) (result i32)
    (struct.get $primitive $id (local.get $p))
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 4: Type Predicates
  ;; ═══════════════════════════════════════════════════════════════════
  ;; Each returns i32 (0 or 1). Uses ref.test for heap types,
  ;; i31ref tag inspection for immediates.

  (func $is-pair (param $v (ref null eq)) (result i32)
    (ref.test (ref $pair) (local.get $v))
  )

  (func $is-null (param $v (ref null eq)) (result i32)
    ;; null = the $nil singleton
    (ref.eq (local.get $v) (global.get $nil))
  )

  (func $is-symbol (param $v (ref null eq)) (result i32)
    (ref.test (ref $symbol) (local.get $v))
  )

  (func $is-string (param $v (ref null eq)) (result i32)
    (ref.test (ref $string) (local.get $v))
  )

  (func $is-vector (param $v (ref null eq)) (result i32)
    (ref.test (ref $vector) (local.get $v))
  )

  (func $is-boolean (param $v (ref null eq)) (result i32)
    ;; #t or #f
    (i32.or
      (ref.eq (local.get $v) (global.get $true))
      (ref.eq (local.get $v) (global.get $false)))
  )

  (func $is-number (param $v (ref null eq)) (result i32)
    ;; fixnum or float-box
    (i32.or
      (call $is-fixnum (local.get $v))
      (ref.test (ref $float-box) (local.get $v)))
  )

  (func $is-integer (param $v (ref null eq)) (result i32)
    (call $is-fixnum (local.get $v))
  )

  (func $is-compiled-proc (param $v (ref null eq)) (result i32)
    (ref.test (ref $compiled-proc) (local.get $v))
  )

  (func $is-primitive (param $v (ref null eq)) (result i32)
    (ref.test (ref $primitive) (local.get $v))
  )

  (func $is-continuation (param $v (ref null eq)) (result i32)
    (ref.test (ref $continuation) (local.get $v))
  )

  (func $is-parameter (param $v (ref null eq)) (result i32)
    (ref.test (ref $parameter) (local.get $v))
  )

  (func $is-js-ref (param $v (ref null eq)) (result i32)
    (ref.test (ref $js-ref) (local.get $v))
  )

  (func $make-js-ref (param $idx i32) (result (ref $js-ref))
    (struct.new $js-ref (local.get $idx) (i32.const 0))
  )

  (func $js-ref-idx (param $v (ref $js-ref)) (result i32)
    (struct.get $js-ref $idx (local.get $v))
  )

  ;; Convert f64 to ECE number: fixnum if integer in range, float-box otherwise
  (func $f64-to-ece-number (param $v f64) (result (ref null eq))
    (local $i i32)
    ;; Check if f64 is an integer: trunc(v) == v and not NaN/Inf
    (if (f64.eq (f64.trunc (local.get $v)) (local.get $v))
      (then
        (local.set $i (i32.trunc_f64_s (local.get $v)))
        ;; Check fixnum range: -2^30 to 2^30-1
        (if (i32.and (i32.ge_s (local.get $i) (i32.const -1073741824))
                     (i32.le_s (local.get $i) (i32.const 1073741823)))
          (then (return (call $make-fixnum (local.get $i)))))))
    (struct.new $float-box (local.get $v))
  )

  (func $is-eof (param $v (ref null eq)) (result i32)
    (ref.eq (local.get $v) (global.get $eof))
  )

  ;; --- false? (the key test for conditional branching) ---
  ;; In Scheme, only #f is false. Everything else is true.
  (func $is-false (param $v (ref null eq)) (result i32)
    (ref.eq (local.get $v) (global.get $false))
  )

  ;; --- eq? ---
  ;; Identity equality: ref.eq for GC refs, value comparison for i31.
  (func $eq (param $a (ref null eq)) (param $b (ref null eq)) (result i32)
    (ref.eq (local.get $a) (local.get $b))
  )


  ;; --- Port constructors and predicates ---

  (func $make-input-port (param $buf (ref $port-buf)) (param $len i32)
                         (param $name (ref null $string)) (result (ref $port))
    (struct.new $port (local.get $buf) (i32.const 0) (local.get $len)
                      (local.get $name) (i32.const 0) (i32.const 1))
  )

  (func $make-output-port (param $name (ref null $string)) (result (ref $port))
    (struct.new $port
      (array.new_default $port-buf (i32.const 1024))
      (i32.const 0) (i32.const 1024)
      (local.get $name) (i32.const 1) (i32.const 1))
  )

  (func $is-port (param $v (ref null eq)) (result i32)
    (ref.test (ref $port) (local.get $v)))

  (func $is-input-port (param $v (ref null eq)) (result i32)
    (if (result i32) (ref.test (ref $port) (local.get $v))
      (then (i32.eqz (struct.get $port $dir (ref.cast (ref $port) (local.get $v)))))
      (else (i32.const 0))))

  (func $is-output-port (param $v (ref null eq)) (result i32)
    (if (result i32) (ref.test (ref $port) (local.get $v))
      (then (struct.get $port $dir (ref.cast (ref $port) (local.get $v))))
      (else (i32.const 0))))

  ;; Read one char from an input port. Returns eof sentinel at end.
  (func $port-read-char (param $p (ref $port)) (result (ref null eq))
    (local $pos i32)
    (local $buf (ref $port-buf))
    (local.set $pos (struct.get $port $pos (local.get $p)))
    (if (ref.is_null (struct.get $port $buf (local.get $p)))
      (then (return (global.get $eof))))
    (local.set $buf (ref.as_non_null (struct.get $port $buf (local.get $p))))
    (if (i32.ge_u (local.get $pos) (array.len (local.get $buf)))
      (then (return (global.get $eof))))
    (struct.set $port $pos (local.get $p) (i32.add (local.get $pos) (i32.const 1)))
    (call $make-char (array.get_u $port-buf (local.get $buf) (local.get $pos)))
  )

  ;; Peek one char without advancing.
  (func $port-peek-char (param $p (ref $port)) (result (ref null eq))
    (local $pos i32)
    (local $buf (ref $port-buf))
    (local.set $pos (struct.get $port $pos (local.get $p)))
    (if (ref.is_null (struct.get $port $buf (local.get $p)))
      (then (return (global.get $eof))))
    (local.set $buf (ref.as_non_null (struct.get $port $buf (local.get $p))))
    (if (i32.ge_u (local.get $pos) (array.len (local.get $buf)))
      (then (return (global.get $eof))))
    (call $make-char (array.get_u $port-buf (local.get $buf) (local.get $pos)))
  )

  ;; Write one char to an output port. Grows buffer if needed.
  (func $port-write-char (param $p (ref $port)) (param $ch i32)
    (local $pos i32)
    (local $cap i32)
    (local $buf (ref $port-buf))
    (local $new-buf (ref $port-buf))
    (local $i i32)
    (local.set $pos (struct.get $port $pos (local.get $p)))
    (local.set $cap (struct.get $port $cap (local.get $p)))
    (local.set $buf (ref.as_non_null (struct.get $port $buf (local.get $p))))
    ;; Grow if at capacity
    (if (i32.ge_u (local.get $pos) (local.get $cap))
      (then
        (local.set $cap (i32.mul (local.get $cap) (i32.const 2)))
        (local.set $new-buf (array.new_default $port-buf (local.get $cap)))
        (local.set $i (i32.const 0))
        (block $done (loop $copy
          (br_if $done (i32.ge_u (local.get $i) (local.get $pos)))
          (array.set $port-buf (local.get $new-buf) (local.get $i)
            (array.get_u $port-buf (local.get $buf) (local.get $i)))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy)))
        (struct.set $port $buf (local.get $p) (local.get $new-buf))
        (struct.set $port $cap (local.get $p) (local.get $cap))
        (local.set $buf (local.get $new-buf))))
    (array.set $port-buf (local.get $buf) (local.get $pos) (local.get $ch))
    (struct.set $port $pos (local.get $p) (i32.add (local.get $pos) (i32.const 1)))
  )

  ;; Read a line from an input port (scan for newline).
  (func $port-read-line (param $p (ref $port)) (result (ref null eq))
    (local $start i32) (local $pos i32) (local $len i32)
    (local $buf (ref $port-buf)) (local $result (ref $string)) (local $i i32)
    (if (ref.is_null (struct.get $port $buf (local.get $p)))
      (then (return (global.get $eof))))
    (local.set $buf (ref.as_non_null (struct.get $port $buf (local.get $p))))
    (local.set $start (struct.get $port $pos (local.get $p)))
    (local.set $pos (local.get $start))
    (local.set $len (array.len (local.get $buf)))
    (if (i32.ge_u (local.get $pos) (local.get $len))
      (then (return (global.get $eof))))
    ;; Scan for newline
    (block $found (loop $scan
      (br_if $found (i32.ge_u (local.get $pos) (local.get $len)))
      (br_if $found (i32.eq (array.get_u $port-buf (local.get $buf) (local.get $pos)) (i32.const 10)))
      (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
      (br $scan)))
    ;; Build result string [start, pos)
    (local.set $result (array.new_default $string (i32.sub (local.get $pos) (local.get $start))))
    (local.set $i (i32.const 0))
    (block $done (loop $copy
      (br_if $done (i32.ge_u (local.get $i) (i32.sub (local.get $pos) (local.get $start))))
      (array.set $string (local.get $result) (local.get $i)
        (array.get_u $port-buf (local.get $buf) (i32.add (local.get $start) (local.get $i))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $copy)))
    ;; Advance past newline if present
    (if (i32.and (i32.lt_u (local.get $pos) (local.get $len))
                 (i32.eq (array.get_u $port-buf (local.get $buf) (local.get $pos)) (i32.const 10)))
      (then (local.set $pos (i32.add (local.get $pos) (i32.const 1)))))
    (struct.set $port $pos (local.get $p) (local.get $pos))
    (local.get $result)
  )

  ;; Flush output port buffer to localStorage via JS.
  (func $port-flush-to-storage (param $p (ref $port))
    (local $name (ref $string))
    (local $buf (ref $port-buf))
    (local $name-len i32) (local $content-len i32) (local $i i32) (local $offset i32)
    (if (ref.is_null (struct.get $port $name (local.get $p))) (then (return)))
    (local.set $name (ref.as_non_null (struct.get $port $name (local.get $p))))
    (local.set $buf (ref.as_non_null (struct.get $port $buf (local.get $p))))
    (local.set $name-len (array.len (local.get $name)))
    (local.set $content-len (struct.get $port $pos (local.get $p)))
    ;; Write filename to linear memory at offset 0
    (local.set $i (i32.const 0))
    (block $d1 (loop $l1
      (br_if $d1 (i32.ge_u (local.get $i) (local.get $name-len)))
      (i32.store16 (i32.shl (local.get $i) (i32.const 1))
        (array.get_u $string (local.get $name) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l1)))
    ;; Write content after filename
    (local.set $offset (i32.shl (local.get $name-len) (i32.const 1)))
    (local.set $i (i32.const 0))
    (block $d2 (loop $l2
      (br_if $d2 (i32.ge_u (local.get $i) (local.get $content-len)))
      (i32.store16 (i32.add (local.get $offset) (i32.shl (local.get $i) (i32.const 1)))
        (array.get_u $port-buf (local.get $buf) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l2)))
    ;; Call JS storage_write(filename_len, content_offset, content_len)
    (call $js-storage-write (local.get $name-len) (local.get $offset) (local.get $content-len))
  )

  ;; Open input file: read from localStorage into a port buffer.
  (func $open-input-file (param $filename (ref $string)) (result (ref $port))
    (local $name-len i32) (local $content-len i32) (local $i i32)
    (local $buf (ref $port-buf))
    (local.set $name-len (array.len (local.get $filename)))
    ;; Write filename to linear memory
    (local.set $i (i32.const 0))
    (block $d (loop $l
      (br_if $d (i32.ge_u (local.get $i) (local.get $name-len)))
      (i32.store16 (i32.shl (local.get $i) (i32.const 1))
        (array.get_u $string (local.get $filename) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
    ;; Call JS to read from localStorage — returns content length
    ;; Content is written to linear memory at offset name_len*2
    (local.set $content-len (call $js-storage-read (local.get $name-len)))
    ;; Copy from linear memory into a port buffer
    (local.set $buf (array.new_default $port-buf (local.get $content-len)))
    (local.set $i (i32.const 0))
    (block $d2 (loop $l2
      (br_if $d2 (i32.ge_u (local.get $i) (local.get $content-len)))
      (array.set $port-buf (local.get $buf) (local.get $i)
        (i32.load16_u (i32.add
          (i32.shl (local.get $name-len) (i32.const 1))
          (i32.shl (local.get $i) (i32.const 1)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l2)))
    (call $make-input-port (local.get $buf) (local.get $content-len) (local.get $filename))
  )

  ;; Open input string: create port from ECE $string (no localStorage).
  (func $open-input-string-port (param $str (ref $string)) (result (ref $port))
    (local $len i32) (local $buf (ref $port-buf)) (local $i i32)
    (local.set $len (array.len (local.get $str)))
    (local.set $buf (array.new_default $port-buf (local.get $len)))
    ;; Copy $string (i16 array) into $port-buf (i16 array)
    (local.set $i (i32.const 0))
    (block $d (loop $l
      (br_if $d (i32.ge_u (local.get $i) (local.get $len)))
      (array.set $port-buf (local.get $buf) (local.get $i)
        (array.get_u $string (local.get $str) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
    (call $make-input-port (local.get $buf) (local.get $len) (ref.null $string))
  )

  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 5: Symbol Interning
  ;; ═══════════════════════════════════════════════════════════════════
  ;; Symbols are interned: string→symbol lookup returns the same $symbol
  ;; struct every time. Equality is by ID (integer), not string compare.
  ;;
  ;; Implementation: two parallel arrays (names and symbols), plus a
  ;; count. Linear scan for lookup — fine for the expected symbol count
  ;; (hundreds, not millions).

  ;; Type for the intern table arrays
  (type $sym-name-array (array (mut (ref null $string))))
  (type $sym-ref-array  (array (mut (ref null $symbol))))

  (global $sym-count    (mut i32) (i32.const 0))
  (global $sym-names    (mut (ref null $sym-name-array))
    (array.new_default $sym-name-array (i32.const 65536)))
  (global $sym-refs     (mut (ref null $sym-ref-array))
    (array.new_default $sym-ref-array (i32.const 65536)))

  ;; --- String equality (UTF-16 code unit comparison) ---
  (func $string-eq (param $a (ref $string)) (param $b (ref $string)) (result i32)
    (local $len i32)
    (local $i i32)
    ;; Different lengths → not equal
    (if (i32.ne (array.len (local.get $a)) (array.len (local.get $b)))
      (then (return (i32.const 0))))
    (local.set $len (array.len (local.get $a)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $loop
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (if (i32.ne
              (array.get_u $string (local.get $a) (local.get $i))
              (array.get_u $string (local.get $b) (local.get $i)))
          (then (return (i32.const 0))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (i32.const 1)
  )

  ;; --- Grow symbol intern arrays (double capacity) ---
  (func $grow-sym-arrays (param $old-names (ref $sym-name-array))
                          (param $old-refs (ref $sym-ref-array))
                          (result (ref $sym-name-array))
    (local $old-len i32)
    (local $new-len i32)
    (local $new-names (ref $sym-name-array))
    (local $new-refs (ref $sym-ref-array))
    (local $i i32)
    (local.set $old-len (array.len (local.get $old-names)))
    (local.set $new-len (i32.mul (local.get $old-len) (i32.const 2)))
    (local.set $new-names (array.new_default $sym-name-array (local.get $new-len)))
    (local.set $new-refs (array.new_default $sym-ref-array (local.get $new-len)))
    (local.set $i (i32.const 0))
    (block $done (loop $copy
      (br_if $done (i32.ge_u (local.get $i) (local.get $old-len)))
      (array.set $sym-name-array (local.get $new-names) (local.get $i)
        (array.get $sym-name-array (local.get $old-names) (local.get $i)))
      (array.set $sym-ref-array (local.get $new-refs) (local.get $i)
        (array.get $sym-ref-array (local.get $old-refs) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $copy)))
    (global.set $sym-names (local.get $new-names))
    (global.set $sym-refs (local.get $new-refs))
    (local.get $new-names))

  ;; --- Intern: look up or create a symbol for a given name ---
  (func $intern (param $name (ref $string)) (result (ref $symbol))
    (local $i i32)
    (local $sym (ref $symbol))
    (local $names (ref $sym-name-array))
    (local $refs (ref $sym-ref-array))
    (local $id i32)
    (local.set $names (ref.as_non_null (global.get $sym-names)))
    (local.set $refs  (ref.as_non_null (global.get $sym-refs)))
    ;; Linear scan for existing symbol
    (local.set $i (i32.const 0))
    (block $not-found
      (loop $scan
        (br_if $not-found (i32.ge_u (local.get $i) (global.get $sym-count)))
        (if (call $string-eq
              (local.get $name)
              (ref.as_non_null (array.get $sym-name-array (local.get $names) (local.get $i))))
          (then
            (return (ref.as_non_null
              (array.get $sym-ref-array (local.get $refs) (local.get $i))))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
    ;; Not found — create new symbol
    ;; Grow arrays if at capacity
    (if (i32.ge_u (global.get $sym-count) (array.len (local.get $names)))
      (then
        (local.set $names (call $grow-sym-arrays (local.get $names) (local.get $refs)))
        (local.set $refs (ref.as_non_null (global.get $sym-refs)))))
    (local.set $id (global.get $sym-count))
    (local.set $sym (struct.new $symbol (local.get $id) (local.get $name)))
    (array.set $sym-name-array (local.get $names) (local.get $id) (local.get $name))
    (array.set $sym-ref-array  (local.get $refs)  (local.get $id) (local.get $sym))
    (global.set $sym-count (i32.add (global.get $sym-count) (i32.const 1)))
    (local.get $sym)
  )

  ;; --- symbol->string ---
  (func $symbol-to-string (param $s (ref $symbol)) (result (ref $string))
    (struct.get $symbol $name (local.get $s))
  )

  ;; --- string->symbol (same as intern) ---
  (func $string-to-symbol (param $name (ref $string)) (result (ref $symbol))
    (call $intern (local.get $name))
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 6: Environment Operations
  ;; ═══════════════════════════════════════════════════════════════════
  ;; SICP frame-based environment model.
  ;; Each frame: (names, vals-array, enclosing-frame-or-null)
  ;; The compiler emits lexical-ref/set! with (depth, offset) for local
  ;; variables. Global access uses lookup-variable-value by name.

  ;; --- extend-environment ---
  ;; Create a new frame with given values, linked to enclosing env.
  ;; names: list of symbols (for name-based lookup)
  ;; vals:  list of values (converted to $val-array)
  ;; nvals: number of values (avoids counting the list)
  (func $extend-env (param $names (ref null eq)) (param $vals (ref null eq))
                    (param $enclosing (ref null eq)) (param $extra-slots i32)
                    (result (ref $env-frame))
    (local $arr (ref $val-array))
    (local $i i32)
    (local $cur-names (ref null eq))
    (local $cur-vals (ref null eq))
    (local $positional-count i32)
    (local $has-rest i32)
    (local $total i32)
    ;; Count positional parameters from NAMES list (not vals).
    ;; Names is (a b c) for regular params, or (a b . rest) for rest params.
    (local.set $cur-names (local.get $names))
    (local.set $positional-count (i32.const 0))
    (local.set $has-rest (i32.const 0))
    (block $counted
      (loop $count
        (br_if $counted (ref.is_null (local.get $cur-names)))
        (br_if $counted (call $is-null (local.get $cur-names)))
        (if (call $is-pair (local.get $cur-names))
          (then
            (local.set $positional-count (i32.add (local.get $positional-count) (i32.const 1)))
            (local.set $cur-names (call $cdr (ref.cast (ref $pair) (local.get $cur-names))))
            (br $count))
          (else
            ;; Dotted pair tail = rest parameter
            (local.set $has-rest (i32.const 1))))))
    ;; Total slots = positional + (1 if rest) + extra
    (local.set $total (i32.add
      (i32.add (local.get $positional-count) (local.get $has-rest))
      (local.get $extra-slots)))
    ;; Allocate values array
    (local.set $arr (array.new_default $val-array (local.get $total)))
    ;; Fill positional params from vals list
    (local.set $cur-vals (local.get $vals))
    (local.set $i (i32.const 0))
    (block $done
      (loop $fill
        (br_if $done (i32.ge_u (local.get $i) (local.get $positional-count)))
        (br_if $done (call $is-null (local.get $cur-vals)))
        (br_if $done (ref.is_null (local.get $cur-vals)))
        (array.set $val-array (local.get $arr) (local.get $i)
          (call $car (ref.cast (ref $pair) (local.get $cur-vals))))
        (local.set $cur-vals (call $cdr (ref.cast (ref $pair) (local.get $cur-vals))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $fill)))
    ;; If rest param, store remaining vals list in the next slot
    (if (local.get $has-rest)
      (then
        (array.set $val-array (local.get $arr) (local.get $positional-count)
          (local.get $cur-vals))))
    (struct.new $env-frame (local.get $names) (local.get $arr) (local.get $enclosing))
  )

  ;; --- lexical-ref (depth, offset) ---
  ;; Walk depth frames, return value at offset. The compiler guarantees
  ;; this is in bounds.
  (func $lexical-ref (param $depth i32) (param $offset i32)
                     (param $env (ref null eq)) (result (ref null eq))
    (local $frame (ref $env-frame))
    (local $d i32)
    (local $result (ref null eq))
    (local.set $frame (ref.cast (ref $env-frame) (local.get $env)))
    (local.set $d (local.get $depth))
    (block $at-depth
      (loop $walk
        (br_if $at-depth (i32.eqz (local.get $d)))
        (local.set $frame
          (ref.cast (ref $env-frame)
            (struct.get $env-frame $enclosing (local.get $frame))))
        (local.set $d (i32.sub (local.get $d) (i32.const 1)))
        (br $walk)))
    (local.set $result (array.get $val-array
      (struct.get $env-frame $vals (local.get $frame))
      (local.get $offset)))
    ;; Debug removed
    (local.get $result)
  )

  ;; --- lexical-set! (depth, offset, value) ---
  (func $lexical-set! (param $depth i32) (param $offset i32)
                      (param $value (ref null eq)) (param $env (ref null eq))
    (local $frame (ref $env-frame))
    (local $d i32)
    (local.set $frame (ref.cast (ref $env-frame) (local.get $env)))
    (local.set $d (local.get $depth))
    (block $at-depth
      (loop $walk
        (br_if $at-depth (i32.eqz (local.get $d)))
        (local.set $frame
          (ref.cast (ref $env-frame)
            (struct.get $env-frame $enclosing (local.get $frame))))
        (local.set $d (i32.sub (local.get $d) (i32.const 1)))
        (br $walk)))
    (array.set $val-array
      (struct.get $env-frame $vals (local.get $frame))
      (local.get $offset)
      (local.get $value))
  )

  ;; --- lookup-variable-value ---
  ;; Walk the frame chain, searching by symbol name. Used for global
  ;; variable access (the compiler uses lexical-ref for locals).
  (func $lookup-variable-value (param $name (ref $symbol)) (param $env (ref null eq))
                               (result (ref null eq))
    (local $frame (ref $env-frame))
    (local $names (ref null eq))
    (local $i i32)
    (local $len i32)
    (local $name-sym (ref $symbol))
    (local $cur (ref null eq))
    (block $not-found
      (loop $walk-frames
        ;; End of chain → not found
        (br_if $not-found (ref.is_null (local.get $env)))
        (br_if $not-found (call $is-null (local.get $env)))
        (local.set $frame (ref.cast (ref $env-frame) (local.get $env)))
        (local.set $names (struct.get $env-frame $names (local.get $frame)))
        (local.set $len (array.len (struct.get $env-frame $vals (local.get $frame))))
        ;; Scan this frame's names list
        (local.set $cur (local.get $names))
        (local.set $i (i32.const 0))
        (block $next-frame
          (loop $scan
            (br_if $next-frame (i32.ge_u (local.get $i) (local.get $len)))
            (br_if $next-frame (ref.is_null (local.get $cur)))
            (br_if $next-frame (call $is-null (local.get $cur)))
            ;; Compare symbol IDs
            (if (ref.test (ref $pair) (local.get $cur))
              (then
                (if (ref.test (ref $symbol) (call $car (ref.cast (ref $pair) (local.get $cur))))
                  (then
                    (local.set $name-sym
                      (ref.cast (ref $symbol)
                        (call $car (ref.cast (ref $pair) (local.get $cur)))))
                    (if (i32.eq
                          (struct.get $symbol $id (local.get $name))
                          (struct.get $symbol $id (local.get $name-sym)))
                      (then
                        (return (array.get $val-array
                          (struct.get $env-frame $vals (local.get $frame))
                          (local.get $i)))))))))
            (if (ref.test (ref $pair) (local.get $cur))
              (then
                (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur)))))
              (else
                (br $next-frame)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $scan)))
        ;; Move to enclosing frame
        (local.set $env (struct.get $env-frame $enclosing (local.get $frame)))
        (br $walk-frames)))
    ;; Not found — return null
    (ref.null eq)
  )

  ;; --- define-variable! ---
  ;; Add or update a binding in the first (innermost) frame.
  (func $define-variable! (param $name (ref $symbol)) (param $value (ref null eq))
                          (param $env (ref null eq))
    (local $frame (ref $env-frame))
    (local $names (ref null eq))
    (local $cur (ref null eq))
    (local $i i32)
    (local $len i32)
    (local $name-sym (ref $symbol))
    (local.set $frame (ref.cast (ref $env-frame) (local.get $env)))
    (local.set $names (struct.get $env-frame $names (local.get $frame)))
    (local.set $len (array.len (struct.get $env-frame $vals (local.get $frame))))
    ;; Search for existing binding
    (local.set $cur (local.get $names))
    (local.set $i (i32.const 0))
    (block $not-found
      (loop $scan
        (br_if $not-found (i32.ge_u (local.get $i) (local.get $len)))
        (br_if $not-found (ref.is_null (local.get $cur)))
        (br_if $not-found (call $is-null (local.get $cur)))
        (if (ref.test (ref $pair) (local.get $cur))
          (then
            (if (ref.test (ref $symbol) (call $car (ref.cast (ref $pair) (local.get $cur))))
              (then
                (local.set $name-sym
                  (ref.cast (ref $symbol)
                    (call $car (ref.cast (ref $pair) (local.get $cur)))))
                (if (i32.eq
                      (struct.get $symbol $id (local.get $name))
                      (struct.get $symbol $id (local.get $name-sym)))
                  (then
                    ;; Found — update in place
                    (array.set $val-array
                      (struct.get $env-frame $vals (local.get $frame))
                      (local.get $i)
                      (local.get $value))
                    (return)))))))
        (if (ref.test (ref $pair) (local.get $cur))
          (then
            (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur)))))
          (else (br $not-found)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
    ;; Not found — need to extend the frame.
    ;; Grow the vals array by creating a new one and copying.
    (call $frame-append (local.get $frame) (local.get $name) (local.get $value))
  )

  ;; --- Helper: append a binding to a frame ---
  ;; Adds a name+value pair to a frame while preserving pre-compiled
  ;; lexical-ref offsets.  The value is placed at the index that matches
  ;; the new name's position in the names list.
  ;;
  ;; Key subtlety: the compiler's extend-env creates frames where
  ;; vals.length may exceed names.length (extra-slots for hoisted defines).
  ;; We place the new value at index = names-count (the first slot without
  ;; a corresponding name).  If that index is within the existing vals
  ;; array, we reuse the slot; otherwise we grow the array.
  ;;
  ;; The original names list is NOT mutated (it may be shared).
  (func $frame-append (param $frame (ref $env-frame))
                      (param $name (ref $symbol)) (param $value (ref null eq))
    (local $old-vals (ref $val-array))
    (local $old-len i32)
    (local $names-count i32)
    (local $target-idx i32)
    (local $new-vals (ref $val-array))
    (local $i i32)
    (local $cur (ref null eq))
    (local $reversed (ref null eq))
    (local $new-names (ref null eq))
    (local.set $old-vals (struct.get $env-frame $vals (local.get $frame)))
    (local.set $old-len (array.len (local.get $old-vals)))
    ;; Count existing names
    (local.set $cur (struct.get $env-frame $names (local.get $frame)))
    (local.set $names-count (i32.const 0))
    (block $cnt-done
      (loop $cnt
        (br_if $cnt-done
          (i32.or (ref.is_null (local.get $cur)) (call $is-null (local.get $cur))))
        (if (call $is-pair (local.get $cur))
          (then
            (local.set $names-count (i32.add (local.get $names-count) (i32.const 1)))
            (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
            (br $cnt)))))
    ;; Target index = names-count (matches the position of the appended name)
    (local.set $target-idx (local.get $names-count))
    ;; If target is within existing array, reuse it; otherwise grow
    (if (i32.lt_u (local.get $target-idx) (local.get $old-len))
      (then
        ;; Reuse existing slot — no need to grow
        (array.set $val-array (local.get $old-vals)
          (local.get $target-idx) (local.get $value)))
      (else
        ;; Need to grow: create new array, copy old, place new value
        (local.set $new-vals (array.new_default $val-array
          (i32.add (local.get $target-idx) (i32.const 1))))
        (local.set $i (i32.const 0))
        (block $done
          (loop $copy
            (br_if $done (i32.ge_u (local.get $i) (local.get $old-len)))
            (array.set $val-array (local.get $new-vals)
              (local.get $i)
              (array.get $val-array (local.get $old-vals) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $copy)))
        (array.set $val-array (local.get $new-vals)
          (local.get $target-idx) (local.get $value))
        (struct.set $env-frame $vals (local.get $frame) (local.get $new-vals))))
    ;; Build fresh names list: (old1 old2 ... new-name)
    ;; Step 1: reverse old names into $reversed
    (local.set $cur (struct.get $env-frame $names (local.get $frame)))
    (local.set $reversed (global.get $nil))
    (block $rev-done
      (loop $rev
        (br_if $rev-done
          (i32.or (ref.is_null (local.get $cur)) (call $is-null (local.get $cur))))
        (local.set $reversed
          (call $cons
            (call $car (ref.cast (ref $pair) (local.get $cur)))
            (local.get $reversed)))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $rev)))
    ;; Step 2: fold reversed list onto (new-name) to get (old1 old2 ... new-name)
    (local.set $new-names (call $cons (local.get $name) (global.get $nil)))
    (block $build-done
      (loop $build
        (br_if $build-done
          (i32.or (ref.is_null (local.get $reversed)) (call $is-null (local.get $reversed))))
        (local.set $new-names
          (call $cons
            (call $car (ref.cast (ref $pair) (local.get $reversed)))
            (local.get $new-names)))
        (local.set $reversed (call $cdr (ref.cast (ref $pair) (local.get $reversed))))
        (br $build)))
    ;; Update names
    (struct.set $env-frame $names (local.get $frame) (local.get $new-names))
  )

  ;; --- set-variable-value! ---
  ;; Find and mutate existing binding in the frame chain. Error if not found.
  (func $set-variable-value! (param $name (ref $symbol)) (param $value (ref null eq))
                             (param $env (ref null eq))
    (local $frame (ref $env-frame))
    (local $cur (ref null eq))
    (local $i i32)
    (local $len i32)
    (local $name-sym (ref $symbol))
    (block $not-found
      (loop $walk-frames
        (br_if $not-found (ref.is_null (local.get $env)))
        (br_if $not-found (call $is-null (local.get $env)))
        (local.set $frame (ref.cast (ref $env-frame) (local.get $env)))
        (local.set $cur (struct.get $env-frame $names (local.get $frame)))
        (local.set $len (array.len (struct.get $env-frame $vals (local.get $frame))))
        (local.set $i (i32.const 0))
        (block $next-frame
          (loop $scan
            (br_if $next-frame (i32.ge_u (local.get $i) (local.get $len)))
            (br_if $next-frame (ref.is_null (local.get $cur)))
            (br_if $next-frame (call $is-null (local.get $cur)))
            (if (ref.test (ref $pair) (local.get $cur))
              (then
                (if (ref.test (ref $symbol) (call $car (ref.cast (ref $pair) (local.get $cur))))
                  (then
                    (local.set $name-sym
                      (ref.cast (ref $symbol)
                        (call $car (ref.cast (ref $pair) (local.get $cur)))))
                    (if (i32.eq
                          (struct.get $symbol $id (local.get $name))
                          (struct.get $symbol $id (local.get $name-sym)))
                      (then
                        (array.set $val-array
                          (struct.get $env-frame $vals (local.get $frame))
                          (local.get $i)
                          (local.get $value))
                        (return)))))))
            (if (ref.test (ref $pair) (local.get $cur))
              (then
                (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur)))))
              (else (br $next-frame)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $scan)))
        (local.set $env (struct.get $env-frame $enclosing (local.get $frame)))
        (br $walk-frames)))
    ;; Not found — variable doesn't exist yet (define-variable! handles this case)
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 7: Instruction Representation & Executor Loop
  ;; ═══════════════════════════════════════════════════════════════════
  ;;
  ;; Instruction encoding (loaded from .ececb):
  ;;   Each instruction is a $instr struct in a GC array.
  ;;   The opcode field determines the meaning of the other fields.
  ;;
  ;; Register IDs: 0=val 1=env 2=proc 3=argl 4=continue 5=stack
  ;;
  ;; Opcodes:
  ;;   0 = assign  (a=target-reg, b=source-type, c=source-arg, val=const/operands)
  ;;     source-type: 0=const 1=reg 2=label 3=op
  ;;   1 = test    (c=op-id, val=operand-list)
  ;;   2 = branch  (c=label-pc)
  ;;   3 = goto    (b=dest-type, c=label-pc or reg-id)
  ;;     dest-type: 0=label 1=reg
  ;;   4 = save    (a=reg-id)
  ;;   5 = restore (a=reg-id)
  ;;   6 = perform (c=op-id, val=operand-list)
  ;;   7 = label   (no-op, labels resolved to PCs at load time)

  ;; --- Instruction struct ---
  (type $instr (struct
    (field $opcode i32)
    (field $a i32)              ;; target register or save/restore register
    (field $b i32)              ;; source type or dest type
    (field $c i32)              ;; source reg/label-pc/op-id
    (field $val (ref null eq))  ;; constant value or operand list
  ))

  ;; --- Instruction vector per space ---
  (type $instr-vec (array (mut (ref null $instr))))

  ;; --- Compilation space ---
  (type $comp-space (struct
    (field $name (ref $symbol))
    (field $instrs (mut (ref $instr-vec)))  ;; mutable for grow
    (field $len (mut i32))              ;; used length (may be less than array length)
    (field $labels (mut (ref null eq))))) ;; label symbol → fixnum PC (hash-table or null)

  ;; --- Space registry (array of spaces, indexed by symbol ID) ---
  (type $space-array (array (mut (ref null $comp-space))))
  (global $spaces (mut (ref null $space-array))
    (array.new_default $space-array (i32.const 65536)))  ;; indexed by symbol ID (labels inflate count)
  (global $space-count (mut i32) (i32.const 0))

  ;; --- Register a space ---
  (func $register-space (param $space (ref $comp-space))
    (local $sym-id i32)
    (local $old-arr (ref $space-array))
    (local $new-arr (ref $space-array))
    (local $new-len i32)
    (local $i i32)
    (local.set $sym-id (struct.get $symbol $id
      (struct.get $comp-space $name (local.get $space))))
    ;; Grow array if sym-id exceeds current length
    (local.set $old-arr (ref.as_non_null (global.get $spaces)))
    (if (i32.ge_u (local.get $sym-id) (array.len (local.get $old-arr)))
      (then
        (local.set $new-len (i32.mul (array.len (local.get $old-arr)) (i32.const 2)))
        ;; Ensure new length covers sym-id
        (if (i32.ge_u (local.get $sym-id) (local.get $new-len))
          (then (local.set $new-len (i32.add (local.get $sym-id) (i32.const 1)))))
        (local.set $new-arr (array.new_default $space-array (local.get $new-len)))
        (local.set $i (i32.const 0))
        (block $done (loop $copy
          (br_if $done (i32.ge_u (local.get $i) (array.len (local.get $old-arr))))
          (array.set $space-array (local.get $new-arr) (local.get $i)
            (array.get $space-array (local.get $old-arr) (local.get $i)))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy)))
        (global.set $spaces (local.get $new-arr))
        (local.set $old-arr (local.get $new-arr))))
    (array.set $space-array
      (local.get $old-arr)
      (local.get $sym-id)
      (local.get $space))
    (global.set $space-count
      (i32.add (global.get $space-count) (i32.const 1)))
  )

  ;; --- Look up a space by symbol ID ---
  (func $get-space (param $sym-id i32) (result (ref $comp-space))
    (ref.as_non_null
      (array.get $space-array
        (ref.as_non_null (global.get $spaces))
        (local.get $sym-id)))
  )

  ;; --- Current assembler target space ---
  (global $current-space-id (mut i32) (i32.const 0))

  ;; --- Compile-time macro table (symbol → transformer) ---
  (global $macro-table (mut (ref null eq)) (ref.null eq))

  ;; --- Global environment (set during bootstrap) ---
  (global $global-env (mut (ref null eq)) (ref.null eq))

  ;; --- Pending registers for apply-compiled-procedure / call_ece_proc ---
  (global $execute-argl (mut (ref null eq)) (ref.null eq))
  (global $execute-proc (mut (ref null eq)) (ref.null eq))
  (global $execute-val (mut (ref null eq)) (ref.null eq))
  (global $execute-stack (mut (ref null eq)) (ref.null eq))

  ;; --- Pending instructions for deferred assembly ---
  ;; List of (space-id pc instr-list) triples, built during assembly.
  ;; Converted to $instr structs when execute-from-pc is called (all labels set).
  (global $pending-instrs (mut (ref null eq)) (ref.null eq))

  ;; --- Assembler symbol ID table ---
  ;; Slots: 0-6 = instr types (assign,test,branch,goto,save,restore,perform)
  ;;        7-12 = register names (val,env,proc,argl,continue,stack)
  ;;        13-16 = source types (const,reg,label,op)
  ;;        17-38 = operation names (op-id = slot - 17)
  (type $i32-array (array (mut i32)))
  (global $asm-sym-ids (mut (ref null $i32-array)) (ref.null none))

  (func (export "init_asm_syms") (param $cap i32)
    (global.set $asm-sym-ids (array.new_default $i32-array (local.get $cap))))

  (func (export "store_asm_sym") (param $slot i32) (param $sym-handle i32)
    (array.set $i32-array
      (ref.as_non_null (global.get $asm-sym-ids))
      (local.get $slot)
      (struct.get $symbol $id
        (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle))))))

  (func (export "set_global_env") (param $env-handle i32)
    (global.set $global-env (call $deref-handle (local.get $env-handle))))

  (func (export "set_do_winds_sym") (param $sym-handle i32)
    (global.set $do-winds-sym
      (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle)))))

  (func (export "set_winding_stack_sym") (param $sym-handle i32)
    (global.set $winding-stack-sym
      (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle)))))

  (func (export "set_current_space") (param $space-id i32)
    (global.set $current-space-id (local.get $space-id)))

  ;; Reset current space for fresh run (discard compiled code, labels, pending instrs)
  (func (export "reset_current_space")
    (local $space (ref null $comp-space))
    (local.set $space
      (array.get $space-array
        (ref.as_non_null (global.get $spaces))
        (global.get $current-space-id)))
    ;; Guard: skip if space doesn't exist (not yet initialized)
    (if (ref.is_null (local.get $space))
      (then (return)))
    (struct.set $comp-space $len
      (ref.as_non_null (local.get $space))
      (i32.const 0))
    (struct.set $comp-space $labels
      (ref.as_non_null (local.get $space))
      (ref.null eq))
    (global.set $pending-instrs (ref.null eq)))

  ;; --- Resolve register name symbol to register ID (0-5) ---
  (func $resolve-reg-name (param $sym (ref $symbol)) (result i32)
    (local $id i32)
    (local $syms (ref $i32-array))
    (local.set $id (struct.get $symbol $id (local.get $sym)))
    (local.set $syms (ref.as_non_null (global.get $asm-sym-ids)))
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 7)))
      (then (return (i32.const 0))))  ;; val
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 8)))
      (then (return (i32.const 1))))  ;; env
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 9)))
      (then (return (i32.const 2))))  ;; proc
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 10)))
      (then (return (i32.const 3))))  ;; argl
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 11)))
      (then (return (i32.const 4))))  ;; continue
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 12)))
      (then (return (i32.const 5))))  ;; stack
    (i32.const 0))  ;; default: val

  ;; --- Resolve operation name symbol to op ID (0-20) ---
  (func $resolve-op-name (param $sym (ref $symbol)) (result i32)
    (local $id i32)
    (local $syms (ref $i32-array))
    (local $i i32)
    (local.set $id (struct.get $symbol $id (local.get $sym)))
    (local.set $syms (ref.as_non_null (global.get $asm-sym-ids)))
    ;; Linear scan slots 17-39 (ops 0-22)
    (local.set $i (i32.const 17))
    (block $done (loop $scan
      (br_if $done (i32.gt_u (local.get $i) (i32.const 39)))
      (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (local.get $i)))
        (then (return (i32.sub (local.get $i) (i32.const 17)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $scan)))
    (i32.const 0))  ;; default: lookup-variable-value

  ;; --- Resolve source type symbol (const/reg/label/op) ---
  (func $resolve-src-type (param $sym (ref $symbol)) (result i32)
    (local $id i32)
    (local $syms (ref $i32-array))
    (local.set $id (struct.get $symbol $id (local.get $sym)))
    (local.set $syms (ref.as_non_null (global.get $asm-sym-ids)))
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 13)))
      (then (return (i32.const 0))))  ;; const
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 14)))
      (then (return (i32.const 1))))  ;; reg
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 15)))
      (then (return (i32.const 2))))  ;; label
    (if (i32.eq (local.get $id) (array.get $i32-array (local.get $syms) (i32.const 16)))
      (then (return (i32.const 3))))  ;; op
    (i32.const 0))  ;; default: const

  ;; --- Space label helpers ---
  (func $space-label-set (param $space (ref $comp-space))
                         (param $label-sym (ref null eq)) (param $pc i32)
    (local $ht (ref $hash-table))
    ;; Ensure label table exists
    (if (ref.is_null (struct.get $comp-space $labels (local.get $space)))
      (then
        (struct.set $comp-space $labels (local.get $space)
          (struct.new $hash-table
            (array.new_default $hash-keys (i32.const 64))
            (array.new_default $hash-vals (i32.const 64))
            (i32.const 0)))))
    (local.set $ht (ref.cast (ref $hash-table)
      (struct.get $comp-space $labels (local.get $space))))
    (call $hash-set-impl (local.get $ht) (local.get $label-sym)
      (call $make-fixnum (local.get $pc))))

  (func $space-label-ref (param $space (ref $comp-space))
                         (param $label-sym (ref null eq)) (result i32)
    (local $ht (ref $hash-table))
    (local $val (ref null eq))
    (if (ref.is_null (struct.get $comp-space $labels (local.get $space)))
      (then (return (i32.const 0))))
    (local.set $ht (ref.cast (ref $hash-table)
      (struct.get $comp-space $labels (local.get $space))))
    (local.set $val (call $hash-ref-impl (local.get $ht) (local.get $label-sym)))
    (if (result i32) (ref.is_null (local.get $val))
      (then (i32.const 0))
      (else (call $fixnum-value (ref.cast (ref i31) (local.get $val))))))

  ;; --- Push instruction to space (append at len, grow if needed) ---
  (func $space-push-instr (param $space (ref $comp-space)) (param $ins (ref $instr))
    (local $len i32)
    (local $instrs (ref $instr-vec))
    (local $cap i32)
    (local $new-instrs (ref $instr-vec))
    (local $i i32)
    (local.set $len (struct.get $comp-space $len (local.get $space)))
    (local.set $instrs (struct.get $comp-space $instrs (local.get $space)))
    (local.set $cap (array.len (local.get $instrs)))
    ;; Grow if needed
    (if (i32.ge_u (local.get $len) (local.get $cap))
      (then
        (local.set $new-instrs
          (array.new_default $instr-vec (i32.shl (local.get $cap) (i32.const 1))))
        ;; Copy old instructions
        (local.set $i (i32.const 0))
        (block $done (loop $copy
          (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
          (array.set $instr-vec (local.get $new-instrs) (local.get $i)
            (array.get $instr-vec (local.get $instrs) (local.get $i)))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy)))
        (struct.set $comp-space $instrs (local.get $space) (local.get $new-instrs))
        (local.set $instrs (local.get $new-instrs))))
    ;; Set and increment
    (array.set $instr-vec (local.get $instrs) (local.get $len) (local.get $ins))
    (struct.set $comp-space $len (local.get $space)
      (i32.add (local.get $len) (i32.const 1))))

  ;; --- Build operand pair list from ECE operand list ---
  ;; Input: list of (const val), (reg name), (label name)
  ;; Output: list of (type . value) pairs for $eval-operand
  (func $build-operand-list (param $ops (ref null eq))
                            (param $space-id i32)
                            (result (ref null eq))
    (local $result (ref null eq))
    (local $tail (ref null eq))
    (local $cur (ref null eq))
    (local $op-pair (ref $pair))
    (local $type-sym (ref $symbol))
    (local $src-type i32)
    (local $val (ref null eq))
    (local $new-pair (ref null eq))
    (local $operand (ref null eq))
    ;; Build list in reverse, then reverse
    (local.set $result (global.get $nil))
    (local.set $cur (local.get $ops))
    (block $done (loop $iter
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      ;; Get current operand: (type value)
      (local.set $op-pair (ref.cast (ref $pair)
        (call $car (ref.cast (ref $pair) (local.get $cur)))))
      (local.set $type-sym (ref.cast (ref $symbol) (call $car (local.get $op-pair))))
      (local.set $src-type (call $resolve-src-type (local.get $type-sym)))
      ;; const → (0 . value)
      (if (i32.eqz (local.get $src-type))
        (then
          (local.set $operand (call $cons
            (call $make-fixnum (i32.const 0))
            (call $car (ref.cast (ref $pair) (call $cdr (local.get $op-pair))))))))
      ;; reg → (1 . reg-id)
      (if (i32.eq (local.get $src-type) (i32.const 1))
        (then
          (local.set $operand (call $cons
            (call $make-fixnum (i32.const 1))
            (call $make-fixnum (call $resolve-reg-name
              (ref.cast (ref $symbol)
                (call $car (ref.cast (ref $pair) (call $cdr (local.get $op-pair)))))))))))
      ;; label → (2 . pc)
      (if (i32.eq (local.get $src-type) (i32.const 2))
        (then
          (local.set $operand (call $cons
            (call $make-fixnum (i32.const 2))
            (call $make-fixnum
              (call $space-label-ref
                (call $get-space (local.get $space-id))
                (call $car (ref.cast (ref $pair) (call $cdr (local.get $op-pair))))))))))
      ;; Prepend to result (reverse order for now)
      (local.set $result (call $cons (local.get $operand) (local.get $result)))
      (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
      (br $iter)))
    ;; Reverse the list
    (call $reverse-list (local.get $result)))

  ;; --- Reverse a list ---
  (func $reverse-list (param $lst (ref null eq)) (result (ref null eq))
    (local $result (ref null eq))
    (local $cur (ref null eq))
    (local.set $result (global.get $nil))
    (local.set $cur (local.get $lst))
    (block $done (loop $iter
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      (local.set $result (call $cons
        (call $car (ref.cast (ref $pair) (local.get $cur)))
        (local.get $result)))
      (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
      (br $iter)))
    (local.get $result))

  ;; --- Finalize pending instructions (convert all deferred ECE lists to $instr) ---
  ;; Called by execute-from-pc before running compiled code.
  ;; At this point all labels are registered, so forward references resolve correctly.
  (func $finalize-pending-instrs
    (local $cur (ref null eq))
    (local $entry (ref $pair))
    (local $space-id i32)
    (local $pc i32)
    (local $instr-list (ref null eq))
    (local $space (ref $comp-space))
    (local $instrs (ref $instr-vec))
    (local $cap i32)
    (local $new-instrs (ref $instr-vec))
    (local $i i32)
    ;; Process pending instructions (list is in reverse order — reverse first)
    (local.set $cur (call $reverse-list (global.get $pending-instrs)))
    (global.set $pending-instrs (ref.null eq))
    (block $done (loop $iter
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      ;; Each entry is (space-id pc . instr-list)
      (local.set $entry (ref.cast (ref $pair)
        (call $car (ref.cast (ref $pair) (local.get $cur)))))
      (local.set $space-id
        (call $fixnum-value (ref.cast (ref i31) (call $car (local.get $entry)))))
      (local.set $entry (ref.cast (ref $pair) (call $cdr (local.get $entry))))
      (local.set $pc
        (call $fixnum-value (ref.cast (ref i31) (call $car (local.get $entry)))))
      (local.set $instr-list (call $cdr (local.get $entry)))
      ;; Convert and store at the correct PC
      (local.set $space (call $get-space (local.get $space-id)))
      (local.set $instrs (struct.get $comp-space $instrs (local.get $space)))
      (local.set $cap (array.len (local.get $instrs)))
      ;; Grow instruction vector if needed
      (if (i32.ge_u (local.get $pc) (local.get $cap))
        (then
          (local.set $new-instrs
            (array.new_default $instr-vec (i32.shl (local.get $cap) (i32.const 1))))
          (local.set $i (i32.const 0))
          (block $cdone (loop $ccopy
            (br_if $cdone (i32.ge_u (local.get $i) (local.get $cap)))
            (array.set $instr-vec (local.get $new-instrs) (local.get $i)
              (array.get $instr-vec (local.get $instrs) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $ccopy)))
          (struct.set $comp-space $instrs (local.get $space) (local.get $new-instrs))
          (local.set $instrs (local.get $new-instrs))))
      (array.set $instr-vec (local.get $instrs) (local.get $pc)
        (call $ece-instr-to-wasm-instr (local.get $instr-list) (local.get $space-id)))
      (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
      (br $iter))))

  ;; --- Convert ECE list instruction to $instr struct ---
  ;; Input: ECE list like (assign val (op lookup-variable-value) (const x) (reg env))
  ;; Output: $instr struct
  (func $ece-instr-to-wasm-instr (param $instr-list (ref null eq))
                                  (param $space-id i32)
                                  (result (ref $instr))
    (local $type-sym (ref $symbol))
    (local $type-id i32)
    (local $rest (ref null eq))
    (local $target i32)
    (local $src-pair (ref $pair))
    (local $src-type i32)
    (local $op-id i32)
    (local $label-pc i32)
    (local $operands (ref null eq))
    (local $syms (ref $i32-array))
    ;; Parse instruction type
    (local.set $type-sym (ref.cast (ref $symbol)
      (call $car (ref.cast (ref $pair) (local.get $instr-list)))))
    (local.set $rest (call $cdr (ref.cast (ref $pair) (local.get $instr-list))))
    (local.set $syms (ref.as_non_null (global.get $asm-sym-ids)))
    ;; Determine type by comparing symbol ID
    (local.set $type-id (struct.get $symbol $id (local.get $type-sym)))

    ;; === ASSIGN (type slot 0) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 0)))
      (then
        ;; (assign <target-reg> <source>)
        (local.set $target (call $resolve-reg-name
          (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (local.get $rest))))))
        (local.set $rest (call $cdr (ref.cast (ref $pair) (local.get $rest))))
        ;; Source is a pair (type ...) — e.g. (const val), (reg name), (label name), (op name ...)
        (local.set $src-pair (ref.cast (ref $pair)
          (call $car (ref.cast (ref $pair) (local.get $rest)))))
        (local.set $src-type (call $resolve-src-type
          (ref.cast (ref $symbol) (call $car (local.get $src-pair)))))
        ;; const → b=0, val=value
        (if (i32.eqz (local.get $src-type))
          (then (return (struct.new $instr
            (i32.const 0) (local.get $target) (i32.const 0) (i32.const 0)
            (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair))))))))
        ;; reg → b=1, c=reg-id
        (if (i32.eq (local.get $src-type) (i32.const 1))
          (then (return (struct.new $instr
            (i32.const 0) (local.get $target) (i32.const 1)
            (call $resolve-reg-name
              (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair))))))
            (ref.null eq)))))
        ;; label → b=2, c=pc
        (if (i32.eq (local.get $src-type) (i32.const 2))
          (then
            (local.set $label-pc (call $space-label-ref
              (call $get-space (local.get $space-id))
              (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair))))))
            (return (struct.new $instr
              (i32.const 0) (local.get $target) (i32.const 2)
              (local.get $label-pc) (ref.null eq)))))
        ;; op → b=3, c=op-id, val=operand list
        (local.set $op-id (call $resolve-op-name
          (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair)))))))
        ;; Remaining operands after (op name) start at cddr of rest
        (local.set $operands (call $build-operand-list
          (call $cdr (ref.cast (ref $pair) (local.get $rest)))
          (local.get $space-id)))
        (return (struct.new $instr
          (i32.const 0) (local.get $target) (i32.const 3)
          (local.get $op-id) (local.get $operands)))))

    ;; === TEST (type slot 1) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 1)))
      (then
        ;; (test (op <name>) <operands>...)
        (local.set $src-pair (ref.cast (ref $pair)
          (call $car (ref.cast (ref $pair) (local.get $rest)))))
        (local.set $op-id (call $resolve-op-name
          (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair)))))))
        (local.set $operands (call $build-operand-list
          (call $cdr (ref.cast (ref $pair) (local.get $rest)))
          (local.get $space-id)))
        (return (struct.new $instr
          (i32.const 1) (i32.const 0) (i32.const 0)
          (local.get $op-id) (local.get $operands)))))

    ;; === BRANCH (type slot 2) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 2)))
      (then
        ;; (branch (label <name>))
        (local.set $src-pair (ref.cast (ref $pair)
          (call $car (ref.cast (ref $pair) (local.get $rest)))))
        (local.set $label-pc (call $space-label-ref
          (call $get-space (local.get $space-id))
          (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair))))))
        (return (struct.new $instr
          (i32.const 2) (i32.const 0) (i32.const 0)
          (local.get $label-pc) (ref.null eq)))))

    ;; === GOTO (type slot 3) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 3)))
      (then
        ;; (goto (label <name>)) or (goto (reg <name>))
        (local.set $src-pair (ref.cast (ref $pair)
          (call $car (ref.cast (ref $pair) (local.get $rest)))))
        (local.set $src-type (call $resolve-src-type
          (ref.cast (ref $symbol) (call $car (local.get $src-pair)))))
        ;; label → b=0, c=pc
        (if (i32.eq (local.get $src-type) (i32.const 2))
          (then
            (local.set $label-pc (call $space-label-ref
              (call $get-space (local.get $space-id))
              (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair))))))
            (return (struct.new $instr
              (i32.const 3) (i32.const 0) (i32.const 0)
              (local.get $label-pc) (ref.null eq)))))
        ;; reg → b=1, c=reg-id
        (return (struct.new $instr
          (i32.const 3) (i32.const 0) (i32.const 1)
          (call $resolve-reg-name
            (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair))))))
          (ref.null eq)))))

    ;; === SAVE (type slot 4) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 4)))
      (then
        ;; (save <reg>)
        (return (struct.new $instr
          (i32.const 4)
          (call $resolve-reg-name
            (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (local.get $rest)))))
          (i32.const 0) (i32.const 0) (ref.null eq)))))

    ;; === RESTORE (type slot 5) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 5)))
      (then
        ;; (restore <reg>)
        (return (struct.new $instr
          (i32.const 5)
          (call $resolve-reg-name
            (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (local.get $rest)))))
          (i32.const 0) (i32.const 0) (ref.null eq)))))

    ;; === PERFORM (type slot 6) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 6)))
      (then
        ;; (perform (op <name>) <operands>...)
        (local.set $src-pair (ref.cast (ref $pair)
          (call $car (ref.cast (ref $pair) (local.get $rest)))))
        (local.set $op-id (call $resolve-op-name
          (ref.cast (ref $symbol) (call $car (ref.cast (ref $pair) (call $cdr (local.get $src-pair)))))))
        (local.set $operands (call $build-operand-list
          (call $cdr (ref.cast (ref $pair) (local.get $rest)))
          (local.get $space-id)))
        (return (struct.new $instr
          (i32.const 6) (i32.const 0) (i32.const 0)
          (local.get $op-id) (local.get $operands)))))

    ;; Unknown — return no-op
    (struct.new $instr (i32.const 6) (i32.const 0) (i32.const 0) (i32.const 0) (ref.null eq))
  )

  ;; --- Machine operation IDs ---
  ;; These are internal register machine operations, NOT ECE primitives.
  ;; The compiler emits (op-fn <name>); the .ececb loader maps names
  ;; to these numeric IDs.
  ;;
  ;;  0 = lookup-variable-value     10 = parameter?
  ;;  1 = compiled-procedure-entry  11 = apply-parameter
  ;;  2 = compiled-procedure-env    12 = false?
  ;;  3 = make-compiled-procedure   13 = list
  ;;  4 = extend-environment        14 = cons
  ;;  5 = primitive-procedure?      15 = car
  ;;  6 = apply-primitive-procedure 16 = cdr
  ;;  7 = continuation?             17 = lexical-ref
  ;;  8 = continuation-stack        18 = lexical-set!
  ;;  9 = continuation-conts        19 = define-variable!
  ;;                                20 = set-variable-value!
  ;;                                21 = capture-continuation
  ;;                                22 = do-continuation-winds

  ;; --- Evaluate a single operand ---
  ;; Operand is a pair: (type . value)
  ;;   type 0 = const (cdr is ECE value)
  ;;   type 1 = reg   (cdr is fixnum register ID)
  ;;   type 2 = label (cdr is fixnum PC)
  (func $eval-operand (param $operand (ref null eq))
                      (param $val (ref null eq)) (param $env (ref null eq))
                      (param $proc (ref null eq)) (param $argl (ref null eq))
                      (param $cont (ref null eq)) (param $stack (ref null eq))
                      (param $space-id i32)
                      (result (ref null eq))
    (local $p (ref $pair))
    (local $type i32)
    (local $raw-type i32)
    (local $reg-id i32)
    (local $pc i32)
    (local.set $p (ref.cast (ref $pair) (local.get $operand)))
    (local.set $raw-type (i31.get_s (ref.cast (ref i31) (call $car (local.get $p)))))
    (local.set $type (i32.shr_s (local.get $raw-type) (i32.const 1)))
    ;; const
    (if (i32.eqz (local.get $type))
      (then (return (call $cdr (local.get $p)))))
    ;; reg
    (if (i32.eq (local.get $type) (i32.const 1))
      (then
        (local.set $reg-id
          (i32.shr_s
            (i31.get_s (ref.cast (ref i31) (call $cdr (local.get $p))))
            (i32.const 1)))
        (return (call $get-reg (local.get $reg-id)
          (local.get $val) (local.get $env) (local.get $proc)
          (local.get $argl) (local.get $cont) (local.get $stack)))))
    ;; label — return as space-qualified address pair
    (local.set $pc
      (i32.shr_s
        (i31.get_s (ref.cast (ref i31) (call $cdr (local.get $p))))
        (i32.const 1)))
    (call $cons
      (call $make-fixnum (local.get $space-id))
      (call $make-fixnum (local.get $pc)))
  )

  ;; --- Get register by ID ---
  (func $get-reg (param $id i32)
                 (param $val (ref null eq)) (param $env (ref null eq))
                 (param $proc (ref null eq)) (param $argl (ref null eq))
                 (param $cont (ref null eq)) (param $stack (ref null eq))
                 (result (ref null eq))
    (if (result (ref null eq)) (i32.eqz (local.get $id))
      (then (local.get $val))
      (else (if (result (ref null eq)) (i32.eq (local.get $id) (i32.const 1))
        (then (local.get $env))
        (else (if (result (ref null eq)) (i32.eq (local.get $id) (i32.const 2))
          (then (local.get $proc))
          (else (if (result (ref null eq)) (i32.eq (local.get $id) (i32.const 3))
            (then (local.get $argl))
            (else (if (result (ref null eq)) (i32.eq (local.get $id) (i32.const 4))
              (then (local.get $cont))
              (else (local.get $stack)))))))))))
  )

  ;; --- Execute instructions ---
  ;; The core interpreter loop. Takes a space and start PC,
  ;; returns the value in the val register when PC reaches end.
  (func $execute (export "execute")
                 (param $init-space-id i32) (param $init-pc i32)
                 (param $init-env (ref null eq))
                 (result (ref null eq))
    (local $space-id i32)
    (local $pc i32)
    (local $val (ref null eq))
    (local $env (ref null eq))
    (local $proc (ref null eq))
    (local $argl (ref null eq))
    (local $cont (ref null eq))   ;; continue register
    (local $stack (ref null eq))
    (local $flag i32)
    (local $space (ref $comp-space))
    (local $instrs (ref $instr-vec))
    (local $len i32)
    (local $instr (ref $instr))
    (local $opcode i32)
    (local $target i32)
    (local $src-type i32)
    (local $src-arg i32)
    (local $op-result (ref null eq))
    (local $addr (ref null eq))
    (local $addr-pair (ref $pair))
    (local $dest-space i32)
    (local $dest-pc i32)

    ;; Initialize
    (local.set $space-id (local.get $init-space-id))
    (local.set $pc (local.get $init-pc))
    (local.set $env (local.get $init-env))
    (local.set $stack (global.get $nil))
    ;; Check for pending registers (set by apply-compiled-procedure / call_ece_proc)
    (if (i32.eqz (ref.is_null (global.get $execute-argl)))
      (then
        (local.set $argl (global.get $execute-argl))
        (global.set $execute-argl (ref.null eq))))
    (if (i32.eqz (ref.is_null (global.get $execute-proc)))
      (then
        (local.set $proc (global.get $execute-proc))
        (global.set $execute-proc (ref.null eq))
        ;; Set continue to a "return" sentinel: (space-id . len)
        ;; When the function does (goto (reg continue)), pc will be >= len,
        ;; causing $execute to exit and return $val.
        (local.set $cont
          (call $cons
            (call $make-fixnum (local.get $init-space-id))
            (call $make-fixnum (struct.get $comp-space $len
              (call $get-space (local.get $init-space-id))))))))
    ;; Check for pending val/stack (set by call_continuation)
    (if (i32.eqz (ref.is_null (global.get $execute-val)))
      (then
        (local.set $val (global.get $execute-val))
        (global.set $execute-val (ref.null eq))))
    (if (i32.eqz (ref.is_null (global.get $execute-stack)))
      (then
        (local.set $stack (global.get $execute-stack))
        (global.set $execute-stack (ref.null eq))))
    (local.set $space (call $get-space (local.get $space-id)))
    (local.set $instrs (struct.get $comp-space $instrs (local.get $space)))
    (local.set $len (struct.get $comp-space $len (local.get $space)))

    ;; Main dispatch loop
    (block $loop-end
      (loop $loop-start
        ;; End of instruction vector → done
        (br_if $loop-end (i32.ge_u (local.get $pc) (local.get $len)))

        ;; Yield check: if yield flag set, exit loop (return to JS)
        (if (global.get $yield-flag)
          (then
            (global.set $yield-flag (i32.const 0))
            (br $loop-end)))

        ;; Debug tracking
        (global.set $dbg-pc (local.get $pc))
        (global.set $dbg-space (local.get $space-id))
        ;; Tracing enabled temporarily
        (call $js-trace-pc (local.get $pc) (local.get $space-id))

        ;; Fetch instruction
        (local.set $instr
          (ref.as_non_null
            (array.get $instr-vec (local.get $instrs) (local.get $pc))))
        (local.set $opcode (struct.get $instr $opcode (local.get $instr)))
        (global.set $dbg-opcode (local.get $opcode))

        ;; ── assign (opcode 0) ──
        (if (i32.eqz (local.get $opcode))
          (then
            (local.set $target (struct.get $instr $a (local.get $instr)))
            (local.set $src-type (struct.get $instr $b (local.get $instr)))

            ;; assign from const (src-type 0)
            (if (i32.eqz (local.get $src-type))
              (then
                (local.set $op-result (struct.get $instr $val (local.get $instr)))))

            ;; assign from reg (src-type 1)
            (if (i32.eq (local.get $src-type) (i32.const 1))
              (then
                (local.set $op-result
                  (call $get-reg (struct.get $instr $c (local.get $instr))
                    (local.get $val) (local.get $env) (local.get $proc)
                    (local.get $argl) (local.get $cont) (local.get $stack)))))

            ;; assign from label (src-type 2)
            (if (i32.eq (local.get $src-type) (i32.const 2))
              (then
                ;; For continue register, store space-qualified address
                (if (i32.eq (local.get $target) (i32.const 4))
                  (then
                    (local.set $op-result
                      (call $cons
                        (call $make-fixnum (local.get $space-id))
                        (call $make-fixnum (struct.get $instr $c (local.get $instr))))))
                  (else
                    (local.set $op-result
                      (call $make-fixnum (struct.get $instr $c (local.get $instr))))))))

            ;; assign from op (src-type 3)
            (if (i32.eq (local.get $src-type) (i32.const 3))
              (then
                (local.set $op-result
                  (call $dispatch-op (struct.get $instr $c (local.get $instr))
                    (struct.get $instr $val (local.get $instr))
                    (local.get $val) (local.get $env) (local.get $proc)
                    (local.get $argl) (local.get $cont) (local.get $stack)
                    (local.get $space-id)))))

            ;; Store result in target register
            (if (i32.eqz (local.get $target))
              (then (local.set $val (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 1))
              (then (local.set $env (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 2))
              (then (local.set $proc (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 3))
              (then (local.set $argl (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 4))
              (then (local.set $cont (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 5))
              (then (local.set $stack (local.get $op-result))))
          ))

        ;; ── test (opcode 1) ──
        (if (i32.eq (local.get $opcode) (i32.const 1))
          (then
            (local.set $op-result
              (call $dispatch-op (struct.get $instr $c (local.get $instr))
                (struct.get $instr $val (local.get $instr))
                (local.get $val) (local.get $env) (local.get $proc)
                (local.get $argl) (local.get $cont) (local.get $stack)
                (local.get $space-id)))
            ;; Set flag: true unless result is #f
            (local.set $flag
              (i32.eqz (call $is-false (local.get $op-result))))
          ))

        ;; ── branch (opcode 2) ──
        (if (i32.eq (local.get $opcode) (i32.const 2))
          (then
            (if (local.get $flag)
              (then
                (local.set $pc (struct.get $instr $c (local.get $instr)))
                (br $loop-start)))))

        ;; ── goto (opcode 3) ──
        (if (i32.eq (local.get $opcode) (i32.const 3))
          (then
            ;; goto label (b=0)
            (if (i32.eqz (struct.get $instr $b (local.get $instr)))
              (then
                (local.set $pc (struct.get $instr $c (local.get $instr)))
                (br $loop-start)))
            ;; goto reg (b=1) — register contains an address
            (local.set $addr
              (call $get-reg (struct.get $instr $c (local.get $instr))
                (local.get $val) (local.get $env) (local.get $proc)
                (local.get $argl) (local.get $cont) (local.get $stack)))
            ;; Space-qualified address is a pair (space-id . pc)
            (if (ref.test (ref $pair) (local.get $addr))
              (then
                (local.set $addr-pair (ref.cast (ref $pair) (local.get $addr)))
                (local.set $dest-space
                  (call $fixnum-value
                    (ref.cast (ref i31) (call $car (local.get $addr-pair)))))
                (local.set $dest-pc
                  (call $fixnum-value
                    (ref.cast (ref i31) (call $cdr (local.get $addr-pair)))))
                ;; Cross-space jump?
                (if (i32.ne (local.get $dest-space) (local.get $space-id))
                  (then
                    (local.set $space-id (local.get $dest-space))
                    (local.set $space (call $get-space (local.get $space-id)))
                    (local.set $instrs (struct.get $comp-space $instrs (local.get $space)))
                    (local.set $len (struct.get $comp-space $len (local.get $space)))))
                (local.set $pc (local.get $dest-pc))
                (br $loop-start))
              (else
                ;; Bare fixnum PC (backward compat)
                (if (ref.test (ref i31) (local.get $addr))
                  (then
                    (local.set $pc
                      (call $fixnum-value (ref.cast (ref i31) (local.get $addr))))
                    (br $loop-start)))))
          ))

        ;; ── save (opcode 4) ──
        (if (i32.eq (local.get $opcode) (i32.const 4))
          (then
            (local.set $stack
              (call $cons
                (call $get-reg (struct.get $instr $a (local.get $instr))
                  (local.get $val) (local.get $env) (local.get $proc)
                  (local.get $argl) (local.get $cont) (local.get $stack))
                (local.get $stack)))
            (if (global.get $trace-sr)
              (then (call $js-trace-sr (local.get $pc) (local.get $space-id)
                (i32.const 1) ;; is-save
                (struct.get $instr $a (local.get $instr))
                (call $type-id (call $car (ref.cast (ref $pair) (local.get $stack))))
                (call $stack-depth (local.get $stack)))))))

        ;; ── restore (opcode 5) ──
        (if (i32.eq (local.get $opcode) (i32.const 5))
          (then
            (local.set $target (struct.get $instr $a (local.get $instr)))
            (local.set $op-result
              (call $car (ref.cast (ref $pair) (local.get $stack))))
            (local.set $stack
              (call $cdr (ref.cast (ref $pair) (local.get $stack))))
            ;; Set target register
            (if (i32.eqz (local.get $target))
              (then (local.set $val (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 1))
              (then (local.set $env (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 2))
              (then (local.set $proc (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 3))
              (then (local.set $argl (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 4))
              (then (local.set $cont (local.get $op-result))))
            (if (i32.eq (local.get $target) (i32.const 5))
              (then (local.set $stack (local.get $op-result))))
            (if (global.get $trace-sr)
              (then (call $js-trace-sr (local.get $pc) (local.get $space-id)
                (i32.const 0) ;; is-restore
                (local.get $target)
                (call $type-id (local.get $op-result))
                (call $stack-depth (local.get $stack)))))))

        ;; ── perform (opcode 6) ──
        (if (i32.eq (local.get $opcode) (i32.const 6))
          (then
            (drop
              (call $dispatch-op (struct.get $instr $c (local.get $instr))
                (struct.get $instr $val (local.get $instr))
                (local.get $val) (local.get $env) (local.get $proc)
                (local.get $argl) (local.get $cont) (local.get $stack)
                (local.get $space-id)))))

        ;; Advance PC and continue
        (local.set $pc (i32.add (local.get $pc) (i32.const 1)))
        (br $loop-start)))

    ;; Return val register
    (local.get $val)
  )

  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 8: Machine Operation Dispatch
  ;; ═══════════════════════════════════════════════════════════════════
  ;; Machine operations are internal to the register machine (NOT the
  ;; same as ECE primitives). The compiler emits (op-fn <name>); the
  ;; .ececb loader converts names to numeric IDs.

  (func $dispatch-op (param $op-id i32) (param $operands (ref null eq))
                     (param $val (ref null eq)) (param $env (ref null eq))
                     (param $proc (ref null eq)) (param $argl (ref null eq))
                     (param $cont (ref null eq)) (param $stack (ref null eq))
                     (param $space-id i32)
                     (result (ref null eq))
    (local $a (ref null eq))
    (local $b (ref null eq))
    (local $c (ref null eq))
    (local $rest (ref null eq))
    ;; Evaluate first operand (if any)
    (if (i32.and
          (i32.eqz (ref.is_null (local.get $operands)))
          (i32.eqz (call $is-null (local.get $operands))))
      (then
        (local.set $a (call $eval-operand
          (call $car (ref.cast (ref $pair) (local.get $operands)))
          (local.get $val) (local.get $env) (local.get $proc)
          (local.get $argl) (local.get $cont) (local.get $stack)
          (local.get $space-id)))
        (local.set $rest (call $cdr (ref.cast (ref $pair) (local.get $operands))))
        ;; Second operand
        (if (i32.and
              (i32.eqz (ref.is_null (local.get $rest)))
              (i32.eqz (call $is-null (local.get $rest))))
          (then
            (local.set $b (call $eval-operand
              (call $car (ref.cast (ref $pair) (local.get $rest)))
              (local.get $val) (local.get $env) (local.get $proc)
              (local.get $argl) (local.get $cont) (local.get $stack)
              (local.get $space-id)))
            (local.set $rest (call $cdr (ref.cast (ref $pair) (local.get $rest))))
            ;; Third operand
            (if (i32.and
                  (i32.eqz (ref.is_null (local.get $rest)))
                  (i32.eqz (call $is-null (local.get $rest))))
              (then
                (local.set $c (call $eval-operand
                  (call $car (ref.cast (ref $pair) (local.get $rest)))
                  (local.get $val) (local.get $env) (local.get $proc)
                  (local.get $argl) (local.get $cont) (local.get $stack)
                  (local.get $space-id)))))))))

    ;; Dispatch on operation ID
    ;; 0 = lookup-variable-value(name, env)
    (if (result (ref null eq)) (i32.eqz (local.get $op-id))
      (then (call $lookup-variable-value
              (ref.cast (ref $symbol) (local.get $a))
              (local.get $b)))

    ;; 1 = compiled-procedure-entry(proc) → space-qualified pair
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 1))
      (then
        (call $cons
          (call $make-fixnum
            (call $compiled-proc-space (ref.cast (ref $compiled-proc) (local.get $a))))
          (call $make-fixnum
            (call $compiled-proc-pc (ref.cast (ref $compiled-proc) (local.get $a))))))

    ;; 2 = compiled-procedure-env(proc)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 2))
      (then (call $compiled-proc-env (ref.cast (ref $compiled-proc) (local.get $a))))

    ;; 3 = make-compiled-procedure(label, env) → procedure
    ;; $a = evaluated label operand = pair (space-id . pc)
    ;; $b = env
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 3))
      (then
        (if (result (ref null eq)) (ref.test (ref $pair) (local.get $a))
          ;; Label operand was evaluated to a space-qualified pair
          (then
            (call $make-compiled-proc
              (call $fixnum-value (ref.cast (ref i31)
                (call $car (ref.cast (ref $pair) (local.get $a)))))
              (call $fixnum-value (ref.cast (ref i31)
                (call $cdr (ref.cast (ref $pair) (local.get $a)))))
              (local.get $b)))
          ;; Fallback: bare fixnum PC (same space)
          (else
            (call $make-compiled-proc
              (local.get $space-id)
              (if (result i32) (ref.test (ref i31) (local.get $a))
                (then (call $fixnum-value (ref.cast (ref i31) (local.get $a))))
                (else (i32.const 0)))
              (local.get $b)))))

    ;; 4 = extend-environment(names, vals, env, nvals)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 4))
      (then
        ;; a=names, b=vals, c=env; 4th operand is nvals
        (local.set $rest (call $cdr (ref.cast (ref $pair)
          (call $cdr (ref.cast (ref $pair)
            (call $cdr (ref.cast (ref $pair) (local.get $operands))))))))
        (call $extend-env (local.get $a) (local.get $b) (local.get $c)
          (if (result i32)
            (i32.and
              (i32.eqz (ref.is_null (local.get $rest)))
              (i32.eqz (call $is-null (local.get $rest))))
            (then
              (call $fixnum-value (ref.cast (ref i31)
                (call $eval-operand
                  (call $car (ref.cast (ref $pair) (local.get $rest)))
                  (local.get $val) (local.get $env) (local.get $proc)
                  (local.get $argl) (local.get $cont) (local.get $stack)
                  (local.get $space-id)))))
            (else (i32.const 0)))))

    ;; 5 = primitive-procedure?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 5))
      (then (if (result (ref null eq)) (call $is-primitive (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 6 = apply-primitive-procedure(proc, args) → result
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 6))
      (then (call $apply-primitive
              (ref.cast (ref $primitive) (local.get $a))
              (local.get $b)))

    ;; 7 = continuation?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 7))
      (then (if (result (ref null eq)) (call $is-continuation (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 8 = continuation-stack(cont)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 8))
      (then (struct.get $continuation $stack
              (ref.cast (ref $continuation) (local.get $a))))

    ;; 9 = continuation-conts(cont)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 9))
      (then (struct.get $continuation $conts
              (ref.cast (ref $continuation) (local.get $a))))

    ;; 10 = parameter?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 10))
      (then (if (result (ref null eq)) (call $is-parameter (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 11 = apply-parameter(param, args)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 11))
      (then
        ;; If no args, return value. If args, set value.
        (if (result (ref null eq)) (call $is-null (local.get $b))
          (then (struct.get $parameter $value
                  (ref.cast (ref $parameter) (local.get $a))))
          (else
            (struct.set $parameter $value
              (ref.cast (ref $parameter) (local.get $a))
              (call $car (ref.cast (ref $pair) (local.get $b))))
            (global.get $void))))

    ;; 12 = false?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 12))
      (then (if (result (ref null eq)) (call $is-false (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 13 = list(args...) → list built from operands
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 13))
      (then
        ;; Operands are already evaluated into a, b, c...
        ;; But list can have variable args. Build from evaluated operands.
        ;; Simple case: (list a), (list a b)
        (if (result (ref null eq)) (ref.is_null (local.get $b))
          (then (call $cons (local.get $a) (global.get $nil)))
          (else (if (result (ref null eq)) (ref.is_null (local.get $c))
            (then (call $cons (local.get $a)
                    (call $cons (local.get $b) (global.get $nil))))
            (else (call $cons (local.get $a)
                    (call $cons (local.get $b)
                      (call $cons (local.get $c) (global.get $nil)))))))))

    ;; 14 = cons(a, b)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 14))
      (then (call $cons (local.get $a) (local.get $b)))

    ;; 15 = car(pair)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 15))
      (then (call $car (ref.cast (ref $pair) (local.get $a))))

    ;; 16 = cdr(pair)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 16))
      (then (call $cdr (ref.cast (ref $pair) (local.get $a))))

    ;; 17 = lexical-ref(depth, offset, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 17))
      (then (call $lexical-ref
              (call $fixnum-value (ref.cast (ref i31) (local.get $a)))
              (call $fixnum-value (ref.cast (ref i31) (local.get $b)))
              (local.get $c)))

    ;; 18 = lexical-set!(depth, offset, value, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 18))
      (then
        ;; 4th operand is env
        (local.set $rest (call $cdr (ref.cast (ref $pair)
          (call $cdr (ref.cast (ref $pair)
            (call $cdr (ref.cast (ref $pair) (local.get $operands))))))))
        (call $lexical-set!
          (call $fixnum-value (ref.cast (ref i31) (local.get $a)))
          (call $fixnum-value (ref.cast (ref i31) (local.get $b)))
          (local.get $c)
          (if (result (ref null eq))
            (i32.and
              (i32.eqz (ref.is_null (local.get $rest)))
              (i32.eqz (call $is-null (local.get $rest))))
            (then (call $eval-operand
              (call $car (ref.cast (ref $pair) (local.get $rest)))
              (local.get $val) (local.get $env) (local.get $proc)
              (local.get $argl) (local.get $cont) (local.get $stack)
              (local.get $space-id)))
            (else (local.get $env))))
        (global.get $void))

    ;; 19 = define-variable!(name, value, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 19))
      (then
        (call $define-variable!
          (ref.cast (ref $symbol) (local.get $a))
          (local.get $b)
          (local.get $c))
        (global.get $void))

    ;; 20 = set-variable-value!(name, value, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 20))
      (then
        (call $set-variable-value!
          (ref.cast (ref $symbol) (local.get $a))
          (local.get $b)
          (local.get $c))
        (global.get $void))

    ;; 21 = capture-continuation(stack, continue) → continuation struct
    ;; Also captures the current winding stack from the ECE *winding-stack* variable.
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 21))
      (then
        (local.set $c  ;; reuse $c for winds
          (if (result (ref null eq)) (ref.is_null (global.get $winding-stack-sym))
            (then (global.get $nil))
            (else
              (call $lookup-variable-value
                (ref.as_non_null (global.get $winding-stack-sym))
                (global.get $global-env)))))
        (struct.new $continuation (local.get $a) (local.get $b)
          (if (result (ref null eq)) (ref.is_null (local.get $c))
            (then (global.get $nil))
            (else (local.get $c)))))

    ;; 22 = do-continuation-winds(proc) — transition winding stack before resuming
    ;; If the continuation's saved winds differ from the current *winding-stack*,
    ;; look up do-winds! and call it to run before/after thunks.
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 22))
      (then
        ;; $a = continuation's saved winds
        (local.set $a (struct.get $continuation $winds
          (ref.cast (ref $continuation) (local.get $a))))
        ;; $b = current *winding-stack* (from ECE env)
        (local.set $b
          (if (result (ref null eq)) (ref.is_null (global.get $winding-stack-sym))
            (then (global.get $nil))
            (else (call $lookup-variable-value
              (ref.as_non_null (global.get $winding-stack-sym))
              (global.get $global-env)))))
        (if (ref.is_null (local.get $b))
          (then (local.set $b (global.get $nil))))
        ;; Identity check: same object = no winding needed (common case)
        (if (ref.eq (local.get $b) (local.get $a))
          (then (return (global.get $void))))
        ;; Both nil = no winding needed
        (if (i32.and (call $is-null (local.get $b)) (call $is-null (local.get $a)))
          (then (return (global.get $void))))
        ;; Need to call do-winds!(current-winds, target-winds)
        (local.set $c (call $lookup-variable-value
          (ref.as_non_null (global.get $do-winds-sym))
          (global.get $global-env)))
        (global.set $execute-argl
          (call $cons (local.get $b)
            (call $cons (local.get $a) (global.get $nil))))
        (global.set $execute-proc (local.get $c))
        (drop (call $execute
          (call $compiled-proc-space (ref.cast (ref $compiled-proc) (local.get $c)))
          (call $compiled-proc-pc (ref.cast (ref $compiled-proc) (local.get $c)))
          (call $compiled-proc-env (ref.cast (ref $compiled-proc) (local.get $c)))))
        (global.get $void))

    ;; 23 = lookup-global-variable(name) — bypasses lexical frames for %global-ref hygiene
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 23))
      (then
        (return (call $lookup-variable-value
          (ref.cast (ref $symbol) (local.get $a))
          (global.get $global-env))))

    ;; Unknown op — return void
    (else (global.get $void)
    ))))))))))))))))))))))))))))))))))))))))))))))))
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 9: Primitive Dispatch
  ;; ═══════════════════════════════════════════════════════════════════
  ;; ECE primitives dispatched by numeric ID from primitives.def.
  ;; Called via machine op 6 (apply-primitive-procedure).

  ;; --- Argument extraction helpers ---
  ;; Args are an ECE list. These extract the 1st, 2nd, 3rd elements.
  (func $arg1 (param $args (ref null eq)) (result (ref null eq))
    (call $car (ref.cast (ref $pair) (local.get $args))))
  (func $arg2 (param $args (ref null eq)) (result (ref null eq))
    (call $car (ref.cast (ref $pair)
      (call $cdr (ref.cast (ref $pair) (local.get $args))))))
  (func $arg3 (param $args (ref null eq)) (result (ref null eq))
    (call $car (ref.cast (ref $pair)
      (call $cdr (ref.cast (ref $pair)
        (call $cdr (ref.cast (ref $pair) (local.get $args))))))))

  ;; --- Numeric helpers ---
  ;; Extract numeric value as f64 (works for both fixnum and float-box)
  (func $to-f64 (param $v (ref null eq)) (result f64)
    (if (result f64) (ref.test (ref i31) (local.get $v))
      (then (f64.convert_i32_s
              (call $fixnum-value (ref.cast (ref i31) (local.get $v)))))
      (else (call $float-value (ref.cast (ref $float-box) (local.get $v)))))
  )

  ;; Wrap an i32 result, promoting to float if it overflows i31 fixnum range
  (func $wrap-i32 (param $n i32) (result (ref null eq))
    ;; i31ref fixnum range after our tagging: -(2^29) to (2^29 - 1)
    (if (result (ref null eq))
      (i32.and
        (i32.ge_s (local.get $n) (i32.const -536870912))
        (i32.le_s (local.get $n) (i32.const 536870911)))
      (then (call $make-fixnum (local.get $n)))
      (else (call $make-float (f64.convert_i32_s (local.get $n)))))
  )

  ;; Safe f64 to i32 truncation (returns max/min i32 on overflow)
  (func $safe-trunc-i32 (param $n f64) (result i32)
    (if (result i32) (f64.ge (local.get $n) (f64.const 2147483647))
      (then (i32.const 2147483647))
      (else (if (result i32) (f64.le (local.get $n) (f64.const -2147483648))
        (then (i32.const -2147483648))
        (else (i32.trunc_f64_s (local.get $n))))))
  )

  ;; Wrap an f64 result, demoting to fixnum if it's an integer in range
  (func $wrap-f64 (param $n f64) (result (ref null eq))
    (local $i i32)
    ;; Check if it's an integer value
    (if (result (ref null eq)) (f64.eq (local.get $n) (f64.trunc (local.get $n)))
      (then
        (local.set $i (i32.trunc_f64_s (local.get $n)))
        (if (result (ref null eq))
          (i32.and
            (i32.ge_s (local.get $i) (i32.const -536870912))
            (i32.le_s (local.get $i) (i32.const 536870911)))
          (then (call $make-fixnum (local.get $i)))
          (else (call $make-float (local.get $n)))))
      (else (call $make-float (local.get $n))))
  )

  ;; --- Variadic arithmetic on a list ---
  ;; Walk the args list, accumulating with the given operation.
  (func $fold-add (param $args (ref null eq)) (result (ref null eq))
    (local $acc f64)
    (local $cur (ref null eq))
    (local $all-int i32)
    (local.set $acc (f64.const 0))
    (local.set $cur (local.get $args))
    (local.set $all-int (i32.const 1))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (if (i32.eqz (call $is-fixnum (call $car (ref.cast (ref $pair) (local.get $cur)))))
          (then (local.set $all-int (i32.const 0))))
        (local.set $acc (f64.add (local.get $acc)
          (call $to-f64 (call $car (ref.cast (ref $pair) (local.get $cur))))))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (if (result (ref null eq)) (local.get $all-int)
      (then (call $wrap-i32 (call $safe-trunc-i32 (local.get $acc))))
      (else (call $make-float (local.get $acc))))
  )

  (func $fold-mul (param $args (ref null eq)) (result (ref null eq))
    (local $acc f64)
    (local $cur (ref null eq))
    (local $all-int i32)
    (local.set $acc (f64.const 1))
    (local.set $cur (local.get $args))
    (local.set $all-int (i32.const 1))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (if (i32.eqz (call $is-fixnum (call $car (ref.cast (ref $pair) (local.get $cur)))))
          (then (local.set $all-int (i32.const 0))))
        (local.set $acc (f64.mul (local.get $acc)
          (call $to-f64 (call $car (ref.cast (ref $pair) (local.get $cur))))))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (if (result (ref null eq)) (local.get $all-int)
      (then (call $wrap-i32 (call $safe-trunc-i32 (local.get $acc))))
      (else (call $make-float (local.get $acc))))
  )

  (func $fold-sub (param $args (ref null eq)) (result (ref null eq))
    (local $first f64)
    (local $acc f64)
    (local $cur (ref null eq))
    (local $all-int i32)
    (local.set $first (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $args))))
    (local.set $all-int (i32.const 1))
    ;; Unary minus: (- x) = -x
    (if (call $is-null (local.get $cur))
      (then
        (local.set $first (f64.neg (local.get $first)))
        (local.set $cur (global.get $nil))))
    (local.set $acc (local.get $first))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (if (i32.eqz (call $is-fixnum (call $car (ref.cast (ref $pair) (local.get $cur)))))
          (then (local.set $all-int (i32.const 0))))
        (local.set $acc (f64.sub (local.get $acc)
          (call $to-f64 (call $car (ref.cast (ref $pair) (local.get $cur))))))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (if (result (ref null eq)) (local.get $all-int)
      (then (call $wrap-i32 (call $safe-trunc-i32 (local.get $acc))))
      (else (call $make-float (local.get $acc))))
  )

  (func $fold-div (param $args (ref null eq)) (result (ref null eq))
    (local $acc f64)
    (local $cur (ref null eq))
    (local.set $acc (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $args))))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $acc (f64.div (local.get $acc)
          (call $to-f64 (call $car (ref.cast (ref $pair) (local.get $cur))))))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (call $wrap-f64 (local.get $acc))
  )

  ;; --- Variadic comparison ---
  (func $cmp-eq (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $prev f64)
    (local $val f64)
    (local.set $prev (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $args))))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $val (call $to-f64 (call $car (ref.cast (ref $pair) (local.get $cur)))))
        (if (i32.eqz (f64.eq (local.get $prev) (local.get $val)))
          (then (return (global.get $false))))
        (local.set $prev (local.get $val))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (global.get $true)
  )

  (func $cmp-lt (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $prev f64)
    (local $val f64)
    (local.set $prev (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $args))))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $val (call $to-f64 (call $car (ref.cast (ref $pair) (local.get $cur)))))
        (if (i32.eqz (f64.lt (local.get $prev) (local.get $val)))
          (then (return (global.get $false))))
        (local.set $prev (local.get $val))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (global.get $true)
  )

  (func $cmp-gt (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $prev f64)
    (local $val f64)
    (local.set $prev (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $args))))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $val (call $to-f64 (call $car (ref.cast (ref $pair) (local.get $cur)))))
        (if (i32.eqz (f64.gt (local.get $prev) (local.get $val)))
          (then (return (global.get $false))))
        (local.set $prev (local.get $val))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (global.get $true)
  )

  ;; --- String primitives ---
  (func $prim-string-length (param $s (ref null eq)) (result (ref null eq))
    (call $make-fixnum (array.len (ref.cast (ref $string) (local.get $s))))
  )

  (func $prim-string-ref (param $s (ref null eq)) (param $i (ref null eq)) (result (ref null eq))
    (call $make-char
      (array.get_u $string
        (ref.cast (ref $string) (local.get $s))
        (call $fixnum-value (ref.cast (ref i31) (local.get $i)))))
  )

  (func $prim-string-append (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $total-len i32)
    (local $result (ref $string))
    (local $pos i32)
    (local $s (ref $string))
    (local $slen i32)
    (local $i i32)
    ;; First pass: compute total length
    (local.set $cur (local.get $args))
    (local.set $total-len (i32.const 0))
    (block $done1
      (loop $len-loop
        (br_if $done1 (ref.is_null (local.get $cur)))
        (br_if $done1 (call $is-null (local.get $cur)))
        (local.set $total-len (i32.add (local.get $total-len)
          (array.len (ref.cast (ref $string)
            (call $car (ref.cast (ref $pair) (local.get $cur)))))))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $len-loop)))
    ;; Allocate result
    (local.set $result (array.new_default $string (local.get $total-len)))
    ;; Second pass: copy
    (local.set $cur (local.get $args))
    (local.set $pos (i32.const 0))
    (block $done2
      (loop $copy-loop
        (br_if $done2 (ref.is_null (local.get $cur)))
        (br_if $done2 (call $is-null (local.get $cur)))
        (local.set $s (ref.cast (ref $string)
          (call $car (ref.cast (ref $pair) (local.get $cur)))))
        (local.set $slen (array.len (local.get $s)))
        (local.set $i (i32.const 0))
        (block $done-inner
          (loop $inner
            (br_if $done-inner (i32.ge_u (local.get $i) (local.get $slen)))
            (array.set $string (local.get $result)
              (i32.add (local.get $pos) (local.get $i))
              (array.get_u $string (local.get $s) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $inner)))
        (local.set $pos (i32.add (local.get $pos) (local.get $slen)))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $copy-loop)))
    (local.get $result)
  )

  (func $prim-substring (param $s (ref null eq)) (param $start (ref null eq))
                        (param $end (ref null eq)) (result (ref null eq))
    (local $src (ref $string))
    (local $s-idx i32)
    (local $e-idx i32)
    (local $len i32)
    (local $result (ref $string))
    (local $i i32)
    (local.set $src (ref.cast (ref $string) (local.get $s)))
    (local.set $s-idx (call $fixnum-value (ref.cast (ref i31) (local.get $start))))
    (local.set $e-idx (call $fixnum-value (ref.cast (ref i31) (local.get $end))))
    (local.set $len (i32.sub (local.get $e-idx) (local.get $s-idx)))
    (local.set $result (array.new_default $string (local.get $len)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $copy
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (array.set $string (local.get $result) (local.get $i)
          (array.get_u $string (local.get $src)
            (i32.add (local.get $s-idx) (local.get $i))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $copy)))
    (local.get $result)
  )

  (func $prim-string-eq (param $a (ref null eq)) (param $b (ref null eq)) (result (ref null eq))
    (if (result (ref null eq))
      (call $string-eq
        (ref.cast (ref $string) (local.get $a))
        (ref.cast (ref $string) (local.get $b)))
      (then (global.get $true))
      (else (global.get $false)))
  )

  (func $prim-string-lt (param $a (ref null eq)) (param $b (ref null eq)) (result (ref null eq))
    (local $sa (ref $string))
    (local $sb (ref $string))
    (local $la i32) (local $lb i32) (local $min i32) (local $i i32)
    (local $ca i32) (local $cb i32)
    (local.set $sa (ref.cast (ref $string) (local.get $a)))
    (local.set $sb (ref.cast (ref $string) (local.get $b)))
    (local.set $la (array.len (local.get $sa)))
    (local.set $lb (array.len (local.get $sb)))
    (local.set $min (if (result i32) (i32.lt_u (local.get $la) (local.get $lb))
      (then (local.get $la)) (else (local.get $lb))))
    (local.set $i (i32.const 0))
    (block $done
      (loop $loop
        (br_if $done (i32.ge_u (local.get $i) (local.get $min)))
        (local.set $ca (array.get_u $string (local.get $sa) (local.get $i)))
        (local.set $cb (array.get_u $string (local.get $sb) (local.get $i)))
        (if (i32.lt_u (local.get $ca) (local.get $cb))
          (then (return (global.get $true))))
        (if (i32.gt_u (local.get $ca) (local.get $cb))
          (then (return (global.get $false))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (if (result (ref null eq)) (i32.lt_u (local.get $la) (local.get $lb))
      (then (global.get $true))
      (else (global.get $false)))
  )

  (func $prim-string-gt (param $a (ref null eq)) (param $b (ref null eq)) (result (ref null eq))
    ;; a > b iff b < a
    (call $prim-string-lt (local.get $b) (local.get $a))
  )

  ;; --- equal? (structural equality) ---
  (func $prim-equal (param $a (ref null eq)) (param $b (ref null eq)) (result (ref null eq))
    (local $va (ref null $vector))
    (local $vb (ref null $vector))
    (local $vi i32)
    ;; Identity check first
    (if (ref.eq (local.get $a) (local.get $b))
      (then (return (global.get $true))))
    ;; Both fixnums
    (if (i32.and (call $is-fixnum (local.get $a)) (call $is-fixnum (local.get $b)))
      (then (return (if (result (ref null eq))
        (i32.eq
          (i31.get_s (ref.cast (ref i31) (local.get $a)))
          (i31.get_s (ref.cast (ref i31) (local.get $b))))
        (then (global.get $true))
        (else (global.get $false))))))
    ;; Both strings
    (if (i32.and (call $is-string (local.get $a)) (call $is-string (local.get $b)))
      (then (return (call $prim-string-eq (local.get $a) (local.get $b)))))
    ;; Both pairs — recursive
    (if (i32.and (call $is-pair (local.get $a)) (call $is-pair (local.get $b)))
      (then
        (if (call $is-false
              (call $prim-equal
                (call $car (ref.cast (ref $pair) (local.get $a)))
                (call $car (ref.cast (ref $pair) (local.get $b)))))
          (then (return (global.get $false))))
        (return (call $prim-equal
          (call $cdr (ref.cast (ref $pair) (local.get $a)))
          (call $cdr (ref.cast (ref $pair) (local.get $b)))))))
    ;; Both vectors — element-wise
    (if (i32.and (call $is-vector (local.get $a)) (call $is-vector (local.get $b)))
      (then
        (local.set $va (ref.cast (ref $vector) (local.get $a)))
        (local.set $vb (ref.cast (ref $vector) (local.get $b)))
        (if (i32.ne (array.len (local.get $va)) (array.len (local.get $vb)))
          (then (return (global.get $false))))
        (local.set $vi (i32.const 0))
        (block $vec-done
          (loop $vec-cmp
            (br_if $vec-done (i32.ge_u (local.get $vi) (array.len (local.get $va))))
            (if (call $is-false
                  (call $prim-equal
                    (array.get $vector (local.get $va) (local.get $vi))
                    (array.get $vector (local.get $vb) (local.get $vi))))
              (then (return (global.get $false))))
            (local.set $vi (i32.add (local.get $vi) (i32.const 1)))
            (br $vec-cmp)))
        (return (global.get $true))))
    ;; Both numbers (mixed fixnum/float)
    (if (i32.and (call $is-number (local.get $a)) (call $is-number (local.get $b)))
      (then (return (if (result (ref null eq))
        (f64.eq (call $to-f64 (local.get $a)) (call $to-f64 (local.get $b)))
        (then (global.get $true))
        (else (global.get $false))))))
    (global.get $false)
  )

  ;; --- Variadic list constructor ---
  (func $prim-list (param $args (ref null eq)) (result (ref null eq))
    ;; args is already a list — just return it
    (local.get $args)
  )

  ;; --- number->string ---
  (func $prim-number-to-string (param $v (ref null eq)) (result (ref null eq))
    ;; For fixnums, convert digit by digit
    (local $n i32)
    (local $neg i32)
    (local $buf (ref $string))
    (local $i i32)
    (local $len i32)
    (local $digit i32)
    (local $result (ref $string))
    (local $tmp i32)
    (if (call $is-fixnum (local.get $v))
      (then
        (local.set $n (call $fixnum-value (ref.cast (ref i31) (local.get $v))))
        (if (i32.eqz (local.get $n))
          (then
            (local.set $buf (array.new_default $string (i32.const 1)))
            (array.set $string (local.get $buf) (i32.const 0) (i32.const 48)) ;; '0'
            (return (local.get $buf))))
        (local.set $neg (i32.lt_s (local.get $n) (i32.const 0)))
        (if (local.get $neg)
          (then (local.set $n (i32.sub (i32.const 0) (local.get $n)))))
        ;; Write digits into buffer (reversed)
        (local.set $buf (array.new_default $string (i32.const 12)))
        (local.set $i (i32.const 0))
        (block $done
          (loop $digits
            (br_if $done (i32.eqz (local.get $n)))
            (local.set $digit (i32.rem_u (local.get $n) (i32.const 10)))
            (array.set $string (local.get $buf) (local.get $i)
              (i32.add (local.get $digit) (i32.const 48)))
            (local.set $n (i32.div_u (local.get $n) (i32.const 10)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $digits)))
        (if (local.get $neg)
          (then
            (array.set $string (local.get $buf) (local.get $i) (i32.const 45)) ;; '-'
            (local.set $i (i32.add (local.get $i) (i32.const 1)))))
        (local.set $len (local.get $i))
        ;; Reverse into result
        (local.set $result (array.new_default $string (local.get $len)))
        (local.set $i (i32.const 0))
        (block $done2
          (loop $rev
            (br_if $done2 (i32.ge_u (local.get $i) (local.get $len)))
            (array.set $string (local.get $result) (local.get $i)
              (array.get_u $string (local.get $buf)
                (i32.sub (i32.sub (local.get $len) (i32.const 1)) (local.get $i))))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $rev)))
        (return (local.get $result))))
    ;; Float — truncate to integer and convert
    (if (ref.test (ref $float-box) (local.get $v))
      (then
        (return (call $prim-number-to-string
          (call $make-fixnum
            (i32.trunc_f64_s
              (struct.get $float-box $val
                (ref.cast (ref $float-box) (local.get $v)))))))))
    (global.get $void)
  )

  ;; --- write-to-string for strings: wraps in quotes, escapes \ and " ---
  (func $wts-string (param $s (ref $string)) (result (ref null eq))
    (local $src-len i32)
    (local $dst-len i32)
    (local $i i32)
    (local $ch i32)
    (local $result (ref $string))
    (local $pos i32)
    (local.set $src-len (array.len (local.get $s)))
    ;; First pass: compute output length (2 for quotes + extras for escapes)
    (local.set $dst-len (i32.const 2)) ;; opening and closing "
    (local.set $i (i32.const 0))
    (block $cnt-done
      (loop $cnt
        (br_if $cnt-done (i32.ge_u (local.get $i) (local.get $src-len)))
        (local.set $ch (array.get_u $string (local.get $s) (local.get $i)))
        (if (i32.or (i32.eq (local.get $ch) (i32.const 34))   ;; "
                    (i32.eq (local.get $ch) (i32.const 92)))   ;; backslash
          (then (local.set $dst-len (i32.add (local.get $dst-len) (i32.const 2))))
          (else (local.set $dst-len (i32.add (local.get $dst-len) (i32.const 1)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $cnt)))
    ;; Allocate and fill
    (local.set $result (array.new_default $string (local.get $dst-len)))
    (array.set $string (local.get $result) (i32.const 0) (i32.const 34)) ;; opening "
    (local.set $pos (i32.const 1))
    (local.set $i (i32.const 0))
    (block $fill-done
      (loop $fill
        (br_if $fill-done (i32.ge_u (local.get $i) (local.get $src-len)))
        (local.set $ch (array.get_u $string (local.get $s) (local.get $i)))
        (if (i32.or (i32.eq (local.get $ch) (i32.const 34))
                    (i32.eq (local.get $ch) (i32.const 92)))
          (then
            (array.set $string (local.get $result) (local.get $pos) (i32.const 92)) ;; backslash
            (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
            (array.set $string (local.get $result) (local.get $pos) (local.get $ch))
            (local.set $pos (i32.add (local.get $pos) (i32.const 1))))
          (else
            (array.set $string (local.get $result) (local.get $pos) (local.get $ch))
            (local.set $pos (i32.add (local.get $pos) (i32.const 1)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $fill)))
    (array.set $string (local.get $result) (local.get $pos) (i32.const 34)) ;; closing "
    (local.get $result)
  )

  ;; --- display-to-string: like write-to-string but without string quoting ---
  ;; Used internally by wts-list/wts-vector for list element display.
  (func $display-to-string-impl (param $v (ref null eq)) (result (ref null eq))
    (if (call $is-string (local.get $v))
      (then (return (local.get $v))))
    (call $write-to-string-impl (local.get $v))
  )

  ;; --- write-to-string: convert any ECE value to its string representation ---
  ;; Uses display-value to write to linear memory, then copies to a string.
  ;; This is a simple approach: display to a buffer, capture as string.
  (func $write-to-string-impl (param $v (ref null eq)) (result (ref null eq))
    ;; Quick paths for common types (avoid display overhead)
    (if (call $is-fixnum (local.get $v))
      (then (return (call $prim-number-to-string (local.get $v)))))
    (if (call $is-string (local.get $v))
      (then
        (return
          (if (result (ref null eq)) (global.get $write-mode)
            (then (call $wts-string (ref.cast (ref $string) (local.get $v))))
            (else (local.get $v))))))
    (if (call $is-symbol (local.get $v))
      (then (return (call $symbol-to-string
        (ref.cast (ref $symbol) (local.get $v))))))
    (if (call $is-boolean (local.get $v))
      (then
        (if (result (ref null eq)) (ref.eq (local.get $v) (global.get $true))
          (then (return (call $make-static-string (i32.const 35) (i32.const 116))))  ;; "#t"
          (else (return (call $make-static-string (i32.const 35) (i32.const 102))))))) ;; "#f"
    (if (call $is-null (local.get $v))
      (then (return (call $make-static-string (i32.const 40) (i32.const 41)))))  ;; "()"
    (if (call $is-char (local.get $v))
      (then (return (call $prim-char-to-string
        (call $char-codepoint (ref.cast (ref i31) (local.get $v)))))))
    ;; Pairs/lists: build string by concatenating parts
    (if (call $is-pair (local.get $v))
      (then (return (call $wts-list (local.get $v)))))
    ;; Vectors
    (if (call $is-vector (local.get $v))
      (then (return (call $wts-vector (local.get $v)))))
    ;; Fallback
    (call $make-static-string (i32.const 35) (i32.const 63))  ;; "#?"
  )

  ;; Write-to-string for lists
  (func $wts-list (param $v (ref null eq)) (result (ref null eq))
    (local $parts (ref null eq))
    (local $cur (ref null eq))
    ;; Build list of string parts: "(" elem1 " " elem2 ... ")"
    (local.set $parts (global.get $nil))
    (local.set $parts (call $cons (call $make-1char-string (i32.const 40)) (local.get $parts)))  ;; "("
    (local.set $cur (local.get $v))
    (block $done
      (loop $loop
        ;; End of proper list
        (br_if $done (call $is-null (local.get $cur)))
        (br_if $done (ref.is_null (local.get $cur)))
        ;; Not first element: add space
        (if (i32.eqz (ref.eq (local.get $cur) (local.get $v)))
          (then
            (local.set $parts (call $cons (call $make-1char-string (i32.const 32)) (local.get $parts)))))
        (if (call $is-pair (local.get $cur))
          (then
            (local.set $parts (call $cons
              (call $write-to-string-impl (call $car (ref.cast (ref $pair) (local.get $cur))))
              (local.get $parts)))
            (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
            (br $loop))
          (else
            ;; Dotted pair
            (local.set $parts (call $cons (call $make-static-string (i32.const 32) (i32.const 46)) (local.get $parts)))  ;; " ."
            (local.set $parts (call $cons (call $make-1char-string (i32.const 32)) (local.get $parts)))  ;; " "
            (local.set $parts (call $cons (call $write-to-string-impl (local.get $cur)) (local.get $parts)))))))
    (local.set $parts (call $cons (call $make-1char-string (i32.const 41)) (local.get $parts)))  ;; ")"
    ;; Reverse and concatenate
    (call $prim-string-append (call $prim-reverse (local.get $parts)))
  )

  ;; Write-to-string for vectors
  (func $wts-vector (param $v (ref null eq)) (result (ref null eq))
    (local $vec (ref $vector))
    (local $parts (ref null eq))
    (local $i i32)
    (local $len i32)
    (local.set $vec (ref.cast (ref $vector) (local.get $v)))
    (local.set $len (array.len (local.get $vec)))
    (local.set $parts (global.get $nil))
    (local.set $parts (call $cons (call $make-static-string (i32.const 35) (i32.const 40)) (local.get $parts)))  ;; "#("
    (local.set $i (i32.const 0))
    (block $done
      (loop $loop
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (if (local.get $i)
          (then (local.set $parts (call $cons (call $make-1char-string (i32.const 32)) (local.get $parts)))))
        (local.set $parts (call $cons
          (call $write-to-string-impl (array.get $vector (local.get $vec) (local.get $i)))
          (local.get $parts)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (local.set $parts (call $cons (call $make-1char-string (i32.const 41)) (local.get $parts)))  ;; ")"
    (call $prim-string-append (call $prim-reverse (local.get $parts)))
  )

  ;; Helper: make a 1-char string
  (func $make-1char-string (param $c i32) (result (ref $string))
    (local $s (ref $string))
    (local.set $s (array.new_default $string (i32.const 1)))
    (array.set $string (local.get $s) (i32.const 0) (local.get $c))
    (local.get $s)
  )

  ;; Helper: make a 2-char string
  (func $make-static-string (param $c1 i32) (param $c2 i32) (result (ref $string))
    (local $s (ref $string))
    (local.set $s (array.new_default $string (i32.const 2)))
    (array.set $string (local.get $s) (i32.const 0) (local.get $c1))
    (array.set $string (local.get $s) (i32.const 1) (local.get $c2))
    (local.get $s)
  )

  ;; Reverse a list
  (func $prim-reverse (param $lst (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $result (ref null eq))
    (local.set $cur (local.get $lst))
    (local.set $result (global.get $nil))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $result (call $cons
          (call $car (ref.cast (ref $pair) (local.get $cur)))
          (local.get $result)))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (local.get $result)
  )

  ;; --- Char to string ---
  (func $prim-char-to-string (param $cp i32) (result (ref null eq))
    (local $s (ref $string))
    (local.set $s (array.new_default $string (i32.const 1)))
    (array.set $string (local.get $s) (i32.const 0) (local.get $cp))
    (local.get $s)
  )

  ;; --- Hash table operations (linear scan, eq-based) ---
  (func $hash-ref-impl (param $ht (ref $hash-table)) (param $key (ref null eq))
                       (result (ref null eq))
    (local $keys (ref $hash-keys))
    (local $vals (ref $hash-vals))
    (local $count i32)
    (local $i i32)
    (local.set $keys (struct.get $hash-table $keys (local.get $ht)))
    (local.set $vals (struct.get $hash-table $vals (local.get $ht)))
    (local.set $count (struct.get $hash-table $count (local.get $ht)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $scan
        (br_if $done (i32.ge_u (local.get $i) (local.get $count)))
        (if (ref.eq (array.get $hash-keys (local.get $keys) (local.get $i)) (local.get $key))
          (then (return (array.get $hash-vals (local.get $vals) (local.get $i)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
    (global.get $false)  ;; not found → #f
  )

  (func $hash-set-impl (param $ht (ref $hash-table)) (param $key (ref null eq))
                       (param $val (ref null eq))
    (local $keys (ref $hash-keys))
    (local $vals (ref $hash-vals))
    (local $count i32)
    (local $i i32)
    (local $cap i32)
    (local $new-keys (ref $hash-keys))
    (local $new-vals (ref $hash-vals))
    (local.set $keys (struct.get $hash-table $keys (local.get $ht)))
    (local.set $vals (struct.get $hash-table $vals (local.get $ht)))
    (local.set $count (struct.get $hash-table $count (local.get $ht)))
    ;; Check if key exists
    (local.set $i (i32.const 0))
    (block $not-found
      (loop $scan
        (br_if $not-found (i32.ge_u (local.get $i) (local.get $count)))
        (if (ref.eq (array.get $hash-keys (local.get $keys) (local.get $i)) (local.get $key))
          (then
            (array.set $hash-vals (local.get $vals) (local.get $i) (local.get $val))
            (return)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
    ;; Not found — add new entry
    (local.set $cap (array.len (local.get $keys)))
    (if (i32.ge_u (local.get $count) (local.get $cap))
      (then
        ;; Grow arrays
        (local.set $new-keys (array.new_default $hash-keys (i32.mul (local.get $cap) (i32.const 2))))
        (local.set $new-vals (array.new_default $hash-vals (i32.mul (local.get $cap) (i32.const 2))))
        (local.set $i (i32.const 0))
        (block $copied
          (loop $copy
            (br_if $copied (i32.ge_u (local.get $i) (local.get $count)))
            (array.set $hash-keys (local.get $new-keys) (local.get $i)
              (array.get $hash-keys (local.get $keys) (local.get $i)))
            (array.set $hash-vals (local.get $new-vals) (local.get $i)
              (array.get $hash-vals (local.get $vals) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $copy)))
        (struct.set $hash-table $keys (local.get $ht) (local.get $new-keys))
        (struct.set $hash-table $vals (local.get $ht) (local.get $new-vals))
        (local.set $keys (local.get $new-keys))
        (local.set $vals (local.get $new-vals))))
    (array.set $hash-keys (local.get $keys) (local.get $count) (local.get $key))
    (array.set $hash-vals (local.get $vals) (local.get $count) (local.get $val))
    (struct.set $hash-table $count (local.get $ht) (i32.add (local.get $count) (i32.const 1)))
  )

  (func $hash-has-key-impl (param $ht (ref $hash-table)) (param $key (ref null eq))
                           (result (ref null eq))
    (local $keys (ref $hash-keys))
    (local $count i32)
    (local $i i32)
    (local.set $keys (struct.get $hash-table $keys (local.get $ht)))
    (local.set $count (struct.get $hash-table $count (local.get $ht)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $scan
        (br_if $done (i32.ge_u (local.get $i) (local.get $count)))
        (if (ref.eq (array.get $hash-keys (local.get $keys) (local.get $i)) (local.get $key))
          (then (return (global.get $true))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
    (global.get $false)
  )

  (func $hash-remove-impl (param $ht (ref $hash-table)) (param $key (ref null eq))
    (local $keys (ref $hash-keys))
    (local $vals (ref $hash-vals))
    (local $count i32)
    (local $i i32)
    (local $last i32)
    (local.set $keys (struct.get $hash-table $keys (local.get $ht)))
    (local.set $vals (struct.get $hash-table $vals (local.get $ht)))
    (local.set $count (struct.get $hash-table $count (local.get $ht)))
    ;; Find the key
    (local.set $i (i32.const 0))
    (block $done
      (loop $scan
        (br_if $done (i32.ge_u (local.get $i) (local.get $count)))
        (if (ref.eq (array.get $hash-keys (local.get $keys) (local.get $i)) (local.get $key))
          (then
            ;; Found — swap with last element and decrement count
            (local.set $last (i32.sub (local.get $count) (i32.const 1)))
            (if (i32.ne (local.get $i) (local.get $last))
              (then
                (array.set $hash-keys (local.get $keys) (local.get $i)
                  (array.get $hash-keys (local.get $keys) (local.get $last)))
                (array.set $hash-vals (local.get $vals) (local.get $i)
                  (array.get $hash-vals (local.get $vals) (local.get $last)))))
            (array.set $hash-keys (local.get $keys) (local.get $last) (ref.null eq))
            (array.set $hash-vals (local.get $vals) (local.get $last) (ref.null eq))
            (struct.set $hash-table $count (local.get $ht) (local.get $last))
            (return)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
  )

  (func $hash-values-impl (param $ht (ref $hash-table)) (result (ref null eq))
    (local $vals (ref $hash-vals))
    (local $count i32)
    (local $i i32)
    (local $result (ref null eq))
    (local.set $vals (struct.get $hash-table $vals (local.get $ht)))
    (local.set $count (struct.get $hash-table $count (local.get $ht)))
    (local.set $result (global.get $nil))
    (local.set $i (i32.sub (local.get $count) (i32.const 1)))
    (block $done
      (loop $scan
        (br_if $done (i32.lt_s (local.get $i) (i32.const 0)))
        (local.set $result (call $cons
          (array.get $hash-vals (local.get $vals) (local.get $i))
          (local.get $result)))
        (local.set $i (i32.sub (local.get $i) (i32.const 1)))
        (br $scan)))
    (local.get $result)
  )

  (func $hash-keys-impl (param $ht (ref $hash-table)) (result (ref null eq))
    (local $keys (ref $hash-keys))
    (local $count i32)
    (local $i i32)
    (local $result (ref null eq))
    (local.set $keys (struct.get $hash-table $keys (local.get $ht)))
    (local.set $count (struct.get $hash-table $count (local.get $ht)))
    (local.set $result (global.get $nil))
    (local.set $i (i32.sub (local.get $count) (i32.const 1)))
    (block $done
      (loop $scan
        (br_if $done (i32.lt_s (local.get $i) (i32.const 0)))
        (local.set $result (call $cons
          (array.get $hash-keys (local.get $keys) (local.get $i))
          (local.get $result)))
        (local.set $i (i32.sub (local.get $i) (i32.const 1)))
        (br $scan)))
    (local.get $result)
  )

  ;; --- hash-ref with optional default ---
  (func $prim-hash-ref-with-default (param $args (ref null eq)) (result (ref null eq))
    (local $ht (ref $hash-table))
    (local $key (ref null eq))
    (local $result (ref null eq))
    (local $rest (ref null eq))
    (local.set $ht (ref.cast (ref $hash-table) (call $arg1 (local.get $args))))
    (local.set $key (call $arg2 (local.get $args)))
    (local.set $result (call $hash-ref-impl (local.get $ht) (local.get $key)))
    ;; If found (not #f), return it
    (if (i32.eqz (call $is-false (local.get $result)))
      (then (return (local.get $result))))
    ;; Not found — check for 3rd arg (default)
    (local.set $rest (call $cdr (ref.cast (ref $pair)
      (call $cdr (ref.cast (ref $pair) (local.get $args))))))
    (if (i32.and
          (i32.eqz (ref.is_null (local.get $rest)))
          (i32.eqz (call $is-null (local.get $rest))))
      (then (return (call $car (ref.cast (ref $pair) (local.get $rest))))))
    ;; No default — return #f
    (global.get $false)
  )

  ;; --- Gensym: now in prelude.scm ---

  ;; --- Vector/list conversion helpers ---
  (func $prim-vector-to-list (param $v (ref null eq)) (result (ref null eq))
    (local $vec (ref $vector))
    (local $i i32)
    (local $result (ref null eq))
    (local.set $vec (ref.cast (ref $vector) (local.get $v)))
    (local.set $i (i32.sub (array.len (local.get $vec)) (i32.const 1)))
    (local.set $result (global.get $nil))
    (block $done
      (loop $loop
        (br_if $done (i32.lt_s (local.get $i) (i32.const 0)))
        (local.set $result
          (call $cons (array.get $vector (local.get $vec) (local.get $i)) (local.get $result)))
        (local.set $i (i32.sub (local.get $i) (i32.const 1)))
        (br $loop)))
    (local.get $result)
  )

  (func $prim-list-to-vector (param $lst (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $len i32)
    (local $vec (ref $vector))
    (local $i i32)
    ;; Count
    (local.set $cur (local.get $lst))
    (local.set $len (i32.const 0))
    (block $counted
      (loop $count
        (br_if $counted (ref.is_null (local.get $cur)))
        (br_if $counted (call $is-null (local.get $cur)))
        (local.set $len (i32.add (local.get $len) (i32.const 1)))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $count)))
    ;; Fill
    (local.set $vec (array.new_default $vector (local.get $len)))
    (local.set $cur (local.get $lst))
    (local.set $i (i32.const 0))
    (block $done
      (loop $fill
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (array.set $vector (local.get $vec) (local.get $i)
          (call $car (ref.cast (ref $pair) (local.get $cur))))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $fill)))
    (local.get $vec)
  )

  ;; --- Display to port: write ECE value to a port buffer ---
  (func $display-to-port (param $v (ref null eq)) (param $p (ref $port))
    (local $str (ref $string))
    (local $i i32) (local $len i32)
    ;; String: write each char to port
    (if (call $is-string (local.get $v))
      (then
        (local.set $str (ref.cast (ref $string) (local.get $v)))
        (local.set $len (array.len (local.get $str)))
        (local.set $i (i32.const 0))
        (block $d (loop $l
          (br_if $d (i32.ge_u (local.get $i) (local.get $len)))
          (call $port-write-char (local.get $p)
            (array.get_u $string (local.get $str) (local.get $i)))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $l)))
        (return)))
    ;; Number: convert to string first, then write
    (if (call $is-fixnum (local.get $v))
      (then
        (local.set $str (ref.cast (ref $string) (call $prim-number-to-string (local.get $v))))
        (local.set $len (array.len (local.get $str)))
        (local.set $i (i32.const 0))
        (block $d (loop $l
          (br_if $d (i32.ge_u (local.get $i) (local.get $len)))
          (call $port-write-char (local.get $p)
            (array.get_u $string (local.get $str) (local.get $i)))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $l)))
        (return)))
    ;; Char: write single char
    (if (call $is-char (local.get $v))
      (then
        (call $port-write-char (local.get $p)
          (call $char-codepoint (ref.cast (ref i31) (local.get $v))))
        (return)))
    ;; For other types, convert to string via write-to-string, then write
    (local.set $str (ref.cast (ref $string) (call $write-to-string-impl (local.get $v))))
    (local.set $len (array.len (local.get $str)))
    (local.set $i (i32.const 0))
    (block $d (loop $l
      (br_if $d (i32.ge_u (local.get $i) (local.get $len)))
      (call $port-write-char (local.get $p)
        (array.get_u $string (local.get $str) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
  )

  ;; --- Display helper: write ECE value to JS output ---
  ;; Copies string content to linear memory, calls JS display_string.
  ;; Copy a $string to linear memory (for canvas-draw-text, no console output)
  ;; Read a string from linear memory (UTF-16, offset in bytes)
  (func $memory-to-string (param $offset i32) (param $len i32) (result (ref null eq))
    (local $str (ref $string))
    (local $i i32)
    (local.set $str (array.new_default $string (local.get $len)))
    (block $done
      (loop $copy
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (array.set $string (local.get $str) (local.get $i)
          (i32.load16_u
            (i32.add (local.get $offset)
              (i32.shl (local.get $i) (i32.const 1)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $copy)))
    (local.get $str)
  )

  (func $string-to-memory (param $str (ref $string))
    (local $len i32)
    (local $i i32)
    (local.set $len (array.len (local.get $str)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $copy
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (i32.store16 (i32.shl (local.get $i) (i32.const 1))
          (array.get_u $string (local.get $str) (local.get $i)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $copy)))
    ;; Null-terminate for JS
    (i32.store16 (i32.shl (local.get $len) (i32.const 1)) (i32.const 0)))

  (func $display-value (param $v (ref null eq))
    (local $str (ref $string))
    (local $len i32)
    (local $i i32)
    (if (call $is-string (local.get $v))
      (then
        (local.set $str (ref.cast (ref $string) (local.get $v)))
        (local.set $len (array.len (local.get $str)))
        ;; Copy UTF-16 chars to linear memory for JS
        (local.set $i (i32.const 0))
        (block $done
          (loop $copy
            (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
            (i32.store16 (i32.shl (local.get $i) (i32.const 1))
              (array.get_u $string (local.get $str) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $copy)))
        (call $js-display-string (local.get $len))
        (return)))
    (if (call $is-fixnum (local.get $v))
      (then
        (call $js-display-number
          (f64.convert_i32_s
            (call $fixnum-value (ref.cast (ref i31) (local.get $v)))))
        (return)))
    (if (ref.test (ref $float-box) (local.get $v))
      (then
        (call $js-display-number (call $float-value (ref.cast (ref $float-box) (local.get $v))))
        (return)))
    (if (call $is-boolean (local.get $v))
      (then
        ;; Write "#t" or "#f" to memory
        (i32.store16 (i32.const 0) (i32.const 35))  ;; '#'
        (if (ref.eq (local.get $v) (global.get $true))
          (then (i32.store16 (i32.const 2) (i32.const 116)))   ;; 't'
          (else (i32.store16 (i32.const 2) (i32.const 102))))  ;; 'f'
        (call $js-display-string (i32.const 2))
        (return)))
    (if (call $is-null (local.get $v))
      (then
        ;; Write "()" to memory
        (i32.store16 (i32.const 0) (i32.const 40))  ;; '('
        (i32.store16 (i32.const 2) (i32.const 41))  ;; ')'
        (call $js-display-string (i32.const 2))
        (return)))
    (if (call $is-symbol (local.get $v))
      (then
        (local.set $str (call $symbol-to-string (ref.cast (ref $symbol) (local.get $v))))
        (local.set $len (array.len (local.get $str)))
        (local.set $i (i32.const 0))
        (block $done2
          (loop $copy2
            (br_if $done2 (i32.ge_u (local.get $i) (local.get $len)))
            (i32.store16 (i32.shl (local.get $i) (i32.const 1))
              (array.get_u $string (local.get $str) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $copy2)))
        (call $js-display-string (local.get $len))
        (return)))
    (if (call $is-char (local.get $v))
      (then
        (i32.store16 (i32.const 0)
          (call $char-codepoint (ref.cast (ref i31) (local.get $v))))
        (call $js-display-string (i32.const 1))
        (return)))
    ;; Pairs: (display (a . b))
    (if (call $is-pair (local.get $v))
      (then
        (i32.store16 (i32.const 0) (i32.const 40))  ;; '('
        (call $js-display-string (i32.const 1))
        (call $display-value (call $car (ref.cast (ref $pair) (local.get $v))))
        (call $display-list-tail (call $cdr (ref.cast (ref $pair) (local.get $v))))
        (return)))
    ;; JS ref: display as #<js-ref N>
    (if (call $is-js-ref (local.get $v))
      (then
        (i32.store16 (i32.const 0) (i32.const 35))   ;; '#'
        (i32.store16 (i32.const 2) (i32.const 60))   ;; '<'
        (i32.store16 (i32.const 4) (i32.const 106))  ;; 'j'
        (i32.store16 (i32.const 6) (i32.const 115))  ;; 's'
        (i32.store16 (i32.const 8) (i32.const 62))   ;; '>'
        (call $js-display-string (i32.const 5))
        (call $js-display-number
          (f64.convert_i32_s
            (call $js-ref-idx (ref.cast (ref $js-ref) (local.get $v)))))
        (return)))
    ;; Fallback: display as #<object>
    (i32.store16 (i32.const 0) (i32.const 35))  ;; '#'
    (i32.store16 (i32.const 2) (i32.const 60))  ;; '<'
    (i32.store16 (i32.const 4) (i32.const 62))  ;; '>'
    (call $js-display-string (i32.const 3))
  )

  ;; Helper for displaying list tail (after first element)
  (func $display-list-tail (param $v (ref null eq))
    (if (call $is-null (local.get $v))
      (then
        (i32.store16 (i32.const 0) (i32.const 41))  ;; ')'
        (call $js-display-string (i32.const 1))
        (return)))
    (if (call $is-pair (local.get $v))
      (then
        (i32.store16 (i32.const 0) (i32.const 32))  ;; ' '
        (call $js-display-string (i32.const 1))
        (call $display-value (call $car (ref.cast (ref $pair) (local.get $v))))
        (call $display-list-tail (call $cdr (ref.cast (ref $pair) (local.get $v))))
        (return)))
    ;; Dotted pair
    (i32.store16 (i32.const 0) (i32.const 32))  ;; ' '
    (i32.store16 (i32.const 2) (i32.const 46))  ;; '.'
    (i32.store16 (i32.const 4) (i32.const 32))  ;; ' '
    (call $js-display-string (i32.const 3))
    (call $display-value (local.get $v))
    (i32.store16 (i32.const 0) (i32.const 41))  ;; ')'
    (call $js-display-string (i32.const 1))
  )

  ;; ═══════════════════════════════════════════════════════════════════
  ;; Primitive dispatch — by numeric ID from primitives.def
  ;; ═══════════════════════════════════════════════════════════════════

  (func $apply-primitive (param $prim (ref $primitive)) (param $args (ref null eq))
                         (result (ref null eq))
    (local $id i32)
    (local $cur (ref null eq))
    (local $key (ref null eq))
    (local $result (ref null eq))
    (local.set $id (call $primitive-id (local.get $prim)))
    ;; Debug: store prim ID for crash diagnosis
    (global.set $dbg-opcode (i32.add (local.get $id) (i32.const 1000)))

    ;; 0 = +
    (if (i32.eqz (local.get $id))
      (then (return (call $fold-add (local.get $args)))))
    ;; 1 = -
    (if (i32.eq (local.get $id) (i32.const 1))
      (then (return (call $fold-sub (local.get $args)))))
    ;; 2 = *
    (if (i32.eq (local.get $id) (i32.const 2))
      (then (return (call $fold-mul (local.get $args)))))
    ;; 3 = /
    (if (i32.eq (local.get $id) (i32.const 3))
      (then (return (call $fold-div (local.get $args)))))
    ;; 4 = modulo — migrated to ECE (prelude.scm), derived from floor
    ;; 5 = car
    (if (i32.eq (local.get $id) (i32.const 5))
      (then (return (call $car (ref.cast (ref $pair) (call $arg1 (local.get $args)))))))
    ;; 6 = cdr
    (if (i32.eq (local.get $id) (i32.const 6))
      (then (return (call $cdr (ref.cast (ref $pair) (call $arg1 (local.get $args)))))))
    ;; 7 = cons
    (if (i32.eq (local.get $id) (i32.const 7))
      (then (return (call $cons (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
    ;; 8 = list
    (if (i32.eq (local.get $id) (i32.const 8))
      (then (return (call $prim-list (local.get $args)))))
    ;; 9 = set-car!
    (if (i32.eq (local.get $id) (i32.const 9))
      (then
        (call $set-car! (ref.cast (ref $pair) (call $arg1 (local.get $args)))
                        (call $arg2 (local.get $args)))
        (return (global.get $void))))
    ;; 10 = set-cdr!
    (if (i32.eq (local.get $id) (i32.const 10))
      (then
        (call $set-cdr! (ref.cast (ref $pair) (call $arg1 (local.get $args)))
                        (call $arg2 (local.get $args)))
        (return (global.get $void))))
    ;; 11 = null?
    (if (i32.eq (local.get $id) (i32.const 11))
      (then (return (if (result (ref null eq)) (call $is-null (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 12 = pair?
    (if (i32.eq (local.get $id) (i32.const 12))
      (then (return (if (result (ref null eq)) (call $is-pair (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 13 = number?
    (if (i32.eq (local.get $id) (i32.const 13))
      (then (return (if (result (ref null eq)) (call $is-number (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 14 = string?
    (if (i32.eq (local.get $id) (i32.const 14))
      (then (return (if (result (ref null eq)) (call $is-string (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 15 = symbol?
    (if (i32.eq (local.get $id) (i32.const 15))
      (then (return (if (result (ref null eq)) (call $is-symbol (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 16 = integer?
    (if (i32.eq (local.get $id) (i32.const 16))
      (then (return (if (result (ref null eq)) (call $is-integer (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 17 = char?
    (if (i32.eq (local.get $id) (i32.const 17))
      (then (return (if (result (ref null eq)) (call $is-char (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 18 = vector?
    (if (i32.eq (local.get $id) (i32.const 18))
      (then (return (if (result (ref null eq)) (call $is-vector (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 19 = boolean? — migrated to ECE prelude
    ;; 20 = eq?
    (if (i32.eq (local.get $id) (i32.const 20))
      (then (return (if (result (ref null eq))
        (call $eq (call $arg1 (local.get $args)) (call $arg2 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 21 = equal? — now in prelude.scm
    ;; 22 = = (numeric)
    (if (i32.eq (local.get $id) (i32.const 22))
      (then (return (call $cmp-eq (local.get $args)))))
    ;; 23 = <
    (if (i32.eq (local.get $id) (i32.const 23))
      (then (return (call $cmp-lt (local.get $args)))))
    ;; 24 = >
    (if (i32.eq (local.get $id) (i32.const 24))
      (then (return (call $cmp-gt (local.get $args)))))
    ;; 25 = string-length
    (if (i32.eq (local.get $id) (i32.const 25))
      (then (return (call $prim-string-length (call $arg1 (local.get $args))))))
    ;; 26 = string-ref
    (if (i32.eq (local.get $id) (i32.const 26))
      (then (return (call $prim-string-ref
        (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
    ;; 27 = string-append
    (if (i32.eq (local.get $id) (i32.const 27))
      (then (return (call $prim-string-append (local.get $args)))))
    ;; 28 = substring
    (if (i32.eq (local.get $id) (i32.const 28))
      (then (return (call $prim-substring
        (call $arg1 (local.get $args)) (call $arg2 (local.get $args))
        (call $arg3 (local.get $args))))))
    ;; 29 = string->number — migrated to ECE prelude
    ;; 30 = number->string — migrated to ECE prelude
    ;; 31 = string->symbol
    (if (i32.eq (local.get $id) (i32.const 31))
      (then (return (call $string-to-symbol
        (ref.cast (ref $string) (call $arg1 (local.get $args)))))))
    ;; 32 = symbol->string
    (if (i32.eq (local.get $id) (i32.const 32))
      (then (return (call $symbol-to-string
        (ref.cast (ref $symbol) (call $arg1 (local.get $args)))))))
    ;; 33-35: string=?, string<?, string>? — now implemented in prelude.scm
    ;; 36-41: string-downcase, string-upcase, string-split, string-trim,
    ;; string-contains?, string-join — now implemented in prelude.scm

    ;; 42 = string (char->string)
    (if (i32.eq (local.get $id) (i32.const 42))
      (then
        (local.set $id (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args)))))
        (return (call $prim-char-to-string (local.get $id)))))
    ;; 57 = display (value [port])
    (if (i32.eq (local.get $id) (i32.const 57))
      (then
        ;; Check for port as 2nd arg
        (if (i32.and
              (i32.eqz (ref.is_null (call $cdr (ref.cast (ref $pair) (local.get $args)))))
              (i32.eqz (call $is-null (call $cdr (ref.cast (ref $pair) (local.get $args))))))
          (then
            (if (ref.test (ref $port) (call $arg2 (local.get $args)))
              (then
                (call $display-to-port
                  (call $arg1 (local.get $args))
                  (ref.cast (ref $port) (call $arg2 (local.get $args)))))))
          (else
            (call $display-value (call $arg1 (local.get $args)))))
        (return (global.get $void))))
    ;; 58 = write (value [port]) — enable write-mode for string quoting
    (if (i32.eq (local.get $id) (i32.const 58))
      (then
        (global.set $write-mode (i32.const 1))
        (if (i32.and
              (i32.eqz (ref.is_null (call $cdr (ref.cast (ref $pair) (local.get $args)))))
              (i32.eqz (call $is-null (call $cdr (ref.cast (ref $pair) (local.get $args))))))
          (then
            (if (ref.test (ref $port) (call $arg2 (local.get $args)))
              (then
                (call $display-to-port
                  (call $write-to-string-impl (call $arg1 (local.get $args)))
                  (ref.cast (ref $port) (call $arg2 (local.get $args)))))))
          (else
            (call $display-value
              (call $write-to-string-impl (call $arg1 (local.get $args))))))
        (global.set $write-mode (i32.const 0))
        (return (global.get $void))))
    ;; 59 = newline ([port])
    (if (i32.eq (local.get $id) (i32.const 59))
      (then
        (if (i32.and
              (i32.eqz (ref.is_null (local.get $args)))
              (i32.eqz (call $is-null (local.get $args))))
          (then
            (if (ref.test (ref $port) (call $arg1 (local.get $args)))
              (then
                (call $port-write-char
                  (ref.cast (ref $port) (call $arg1 (local.get $args)))
                  (i32.const 10)))  ;; newline char
              (else (call $js-newline))))
          (else (call $js-newline)))
        (return (global.get $void))))
    ;; 65 = eof?
    (if (i32.eq (local.get $id) (i32.const 65))
      (then (return (if (result (ref null eq)) (call $is-eof (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 67 = write-to-string
    (if (i32.eq (local.get $id) (i32.const 67))
      (then (return (call $write-to-string-impl (call $arg1 (local.get $args))))))

    ;; 136 = write-to-string-flat (quotes strings via write-mode flag)
    (if (i32.eq (local.get $id) (i32.const 136))
      (then
        (global.set $write-mode (i32.const 1))
        (local.set $result (call $write-to-string-impl (call $arg1 (local.get $args))))
        (global.set $write-mode (i32.const 0))
        (return (local.get $result))))

    ;; 66 = print — now implemented in prelude.scm

    ;; 68 = input-port?
    (if (i32.eq (local.get $id) (i32.const 68))
      (then (return (if (result (ref null eq)) (call $is-input-port (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 69 = output-port?
    (if (i32.eq (local.get $id) (i32.const 69))
      (then (return (if (result (ref null eq)) (call $is-output-port (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 70 = port?
    (if (i32.eq (local.get $id) (i32.const 70))
      (then (return (if (result (ref null eq)) (call $is-port (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 71 = current-input-port (stub — no console input yet)
    (if (i32.eq (local.get $id) (i32.const 71))
      (then (return (global.get $void))))
    ;; 72 = current-output-port (stub — console output handled by display)
    (if (i32.eq (local.get $id) (i32.const 72))
      (then (return (global.get $void))))
    ;; 73 = open-input-string → create proper $port from string
    (if (i32.eq (local.get $id) (i32.const 73))
      (then (return (call $open-input-string-port
        (ref.cast (ref $string) (call $arg1 (local.get $args)))))))
    ;; 74 = close-input-port
    (if (i32.eq (local.get $id) (i32.const 74))
      (then
        (if (ref.test (ref $port) (call $arg1 (local.get $args)))
          (then (struct.set $port $open
            (ref.cast (ref $port) (call $arg1 (local.get $args))) (i32.const 0))))
        (return (global.get $void))))
    ;; 75 = close-output-port (flush to localStorage if filename set)
    (if (i32.eq (local.get $id) (i32.const 75))
      (then
        (if (ref.test (ref $port) (call $arg1 (local.get $args)))
          (then
            (call $port-flush-to-storage (ref.cast (ref $port) (call $arg1 (local.get $args))))
            (struct.set $port $open
              (ref.cast (ref $port) (call $arg1 (local.get $args))) (i32.const 0))))
        (return (global.get $void))))
    ;; 100 = open-input-file (localStorage)
    (if (i32.eq (local.get $id) (i32.const 100))
      (then (return (call $open-input-file
        (ref.cast (ref $string) (call $arg1 (local.get $args)))))))
    ;; 101 = open-output-file (localStorage)
    (if (i32.eq (local.get $id) (i32.const 101))
      (then (return (call $make-output-port
        (ref.cast (ref $string) (call $arg1 (local.get $args)))))))
    ;; 60 = read-char ([port])
    (if (i32.eq (local.get $id) (i32.const 60))
      (then
        (if (result (ref null eq))
          (i32.and (i32.eqz (ref.is_null (local.get $args)))
                   (i32.eqz (call $is-null (local.get $args))))
          (then
            (if (result (ref null eq)) (ref.test (ref $port) (call $arg1 (local.get $args)))
              (then (return (call $port-read-char
                (ref.cast (ref $port) (call $arg1 (local.get $args))))))
              (else (return (global.get $eof)))))
          (else (return (global.get $eof))))))
    ;; 61 = peek-char ([port])
    (if (i32.eq (local.get $id) (i32.const 61))
      (then
        (if (result (ref null eq))
          (i32.and (i32.eqz (ref.is_null (local.get $args)))
                   (i32.eqz (call $is-null (local.get $args))))
          (then
            (if (result (ref null eq)) (ref.test (ref $port) (call $arg1 (local.get $args)))
              (then (return (call $port-peek-char
                (ref.cast (ref $port) (call $arg1 (local.get $args))))))
              (else (return (global.get $eof)))))
          (else (return (global.get $eof))))))
    ;; 62 = write-char (char [port])
    (if (i32.eq (local.get $id) (i32.const 62))
      (then
        ;; Check for port as 2nd arg
        (if (i32.and
              (i32.eqz (ref.is_null (call $cdr (ref.cast (ref $pair) (local.get $args)))))
              (i32.eqz (call $is-null (call $cdr (ref.cast (ref $pair) (local.get $args))))))
          (then
            ;; Write to port
            (if (ref.test (ref $port) (call $arg2 (local.get $args)))
              (then
                (call $port-write-char
                  (ref.cast (ref $port) (call $arg2 (local.get $args)))
                  (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args))))))))
          (else
            ;; Write to console (no port arg)
            (i32.store16 (i32.const 0)
              (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args)))))
            (call $js-display-string (i32.const 1))))
        (return (global.get $void))))
    ;; 63 = read-line ([port])
    (if (i32.eq (local.get $id) (i32.const 63))
      (then
        (if (result (ref null eq))
          (i32.and (i32.eqz (ref.is_null (local.get $args)))
                   (i32.eqz (call $is-null (local.get $args))))
          (then
            (if (result (ref null eq)) (ref.test (ref $port) (call $arg1 (local.get $args)))
              (then (return (call $port-read-line
                (ref.cast (ref $port) (call $arg1 (local.get $args))))))
              (else (return (global.get $eof)))))
          (else (return (global.get $eof))))))
    ;; 64 = char-ready? ([port])
    (if (i32.eq (local.get $id) (i32.const 64))
      (then
        (return
          (if (result (ref null eq))
            (i32.and (i32.eqz (ref.is_null (local.get $args)))
                     (ref.test (ref $port) (call $arg1 (local.get $args))))
            (then
              (if (result (ref null eq))
                (i32.lt_u
                  (struct.get $port $pos (ref.cast (ref $port) (call $arg1 (local.get $args))))
                  (struct.get $port $cap (ref.cast (ref $port) (call $arg1 (local.get $args)))))
                (then (global.get $true))
                (else (global.get $false))))
            (else (global.get $true))))))
    ;; 82 = gensym — now in prelude.scm
    ;; 50 = make-vector (size [fill])
    (if (i32.eq (local.get $id) (i32.const 50))
      (then
        (local.set $id (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args)))))
        ;; Check for fill value (2nd arg)
        (if (result (ref null eq))
          (i32.and
            (i32.eqz (ref.is_null (call $cdr (ref.cast (ref $pair) (local.get $args)))))
            (i32.eqz (call $is-null (call $cdr (ref.cast (ref $pair) (local.get $args))))))
          (then
            (return (array.new $vector
              (call $arg2 (local.get $args))
              (local.get $id))))
          (else
            (return (array.new_default $vector (local.get $id)))))))
    ;; 51 = vector (construct from args)
    (if (i32.eq (local.get $id) (i32.const 51))
      (then (return (call $prim-list-to-vector (local.get $args)))))
    ;; 52 = vector-ref
    (if (i32.eq (local.get $id) (i32.const 52))
      (then (return (array.get $vector
        (ref.cast (ref $vector) (call $arg1 (local.get $args)))
        (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args))))))))
    ;; 53 = vector-set!
    (if (i32.eq (local.get $id) (i32.const 53))
      (then
        (array.set $vector
          (ref.cast (ref $vector) (call $arg1 (local.get $args)))
          (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args))))
          (call $arg3 (local.get $args)))
        (return (global.get $void))))
    ;; 54 = vector-length
    (if (i32.eq (local.get $id) (i32.const 54))
      (then (return (call $make-fixnum
        (array.len (ref.cast (ref $vector) (call $arg1 (local.get $args))))))))
    ;; 55-56: vector->list, list->vector — now implemented in prelude.scm
    ;; 43 = char->integer
    (if (i32.eq (local.get $id) (i32.const 43))
      (then (return (call $make-fixnum
        (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args))))))))
    ;; 44 = integer->char
    (if (i32.eq (local.get $id) (i32.const 44))
      (then (return (call $make-char
        (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))))))
    ;; 45-49: char=?, char<?, char-whitespace?, char-alphabetic?, char-numeric? — now in prelude.scm
    ;; 76 = bitwise-and (handles fixnum and float args)
    (if (i32.eq (local.get $id) (i32.const 76))
      (then (return (call $make-fixnum (i32.and
        (call $safe-trunc-i32 (call $to-f64 (call $arg1 (local.get $args))))
        (call $safe-trunc-i32 (call $to-f64 (call $arg2 (local.get $args)))))))))
    ;; 77 = bitwise-or
    (if (i32.eq (local.get $id) (i32.const 77))
      (then (return (call $make-fixnum (i32.or
        (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
        (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))))))
    ;; 78 = bitwise-xor
    (if (i32.eq (local.get $id) (i32.const 78))
      (then (return (call $make-fixnum (i32.xor
        (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
        (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))))))
    ;; 79 = bitwise-not
    (if (i32.eq (local.get $id) (i32.const 79))
      (then (return (call $make-fixnum (i32.xor
        (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
        (i32.const -1))))))
    ;; 80 = arithmetic-shift
    (if (i32.eq (local.get $id) (i32.const 80))
      (then
        (local.set $id (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))
        (if (result (ref null eq)) (i32.ge_s (local.get $id) (i32.const 0))
          (then (return (call $make-fixnum (i32.shl
            (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
            (local.get $id)))))
          (else (return (call $make-fixnum (i32.shr_s
            (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
            (i32.sub (i32.const 0) (local.get $id)))))))))
    ;; 88 = make-parameter
    (if (i32.eq (local.get $id) (i32.const 88))
      (then
        ;; Create a parameter with initial value (or no-arg = void)
        (return (struct.new $parameter
          (if (result (ref null eq))
            (i32.and (i32.eqz (ref.is_null (local.get $args)))
                     (i32.eqz (call $is-null (local.get $args))))
            (then (call $arg1 (local.get $args)))
            (else (global.get $void)))))))
    ;; 116 = %eq-hash-table() → mutable cell wrapping alist: (cons '() '())
    (if (i32.eq (local.get $id) (i32.const 116))
      (then (return (call $cons (global.get $nil) (global.get $nil)))))
    ;; 117 = %eq-hash-ref(table, key) → value or #f (identity-based lookup)
    (if (i32.eq (local.get $id) (i32.const 117))
      (then
        (local.set $cur (call $car (ref.cast (ref $pair) (call $arg1 (local.get $args)))))
        (local.set $key (call $arg2 (local.get $args)))
        (block $not-found (loop $scan
          (br_if $not-found (call $is-null (local.get $cur)))
          (br_if $not-found (ref.is_null (local.get $cur)))
          (if (ref.eq (call $car (ref.cast (ref $pair) (call $car (ref.cast (ref $pair) (local.get $cur)))))
                      (local.get $key))
            (then (return (call $cdr (ref.cast (ref $pair) (call $car (ref.cast (ref $pair) (local.get $cur))))))))
          (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
          (br $scan)))
        (return (global.get $false))))
    ;; 118 = %eq-hash-set!(table, key, value) → void (mutates table cell)
    (if (i32.eq (local.get $id) (i32.const 118))
      (then
        (struct.set $pair $car
          (ref.cast (ref $pair) (call $arg1 (local.get $args)))
          (call $cons
            (call $cons (call $arg2 (local.get $args)) (call $arg3 (local.get $args)))
            (call $car (ref.cast (ref $pair) (call $arg1 (local.get $args))))))
        (return (global.get $void))))
    ;; 83 = sleep (no-op on WASM for now)
    (if (i32.eq (local.get $id) (i32.const 83))
      (then (return (global.get $void))))
    ;; 84 = clear-screen (no-op on WASM)
    (if (i32.eq (local.get $id) (i32.const 84))
      (then (return (global.get $void))))
    ;; 98 = platform-has?
    (if (i32.eq (local.get $id) (i32.const 98))
      (then (return (global.get $false))))  ;; conservative: nothing extra available
    ;; 114 = parameter?
    (if (i32.eq (local.get $id) (i32.const 114))
      (then (return (if (result (ref null eq)) (call $is-parameter (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 137 = keyword?
    (if (i32.eq (local.get $id) (i32.const 137))
      (then (return (global.get $false))))  ;; stub

    ;; --- Integer rounding primitives ---

    ;; 108 = truncate (toward zero)
    (if (i32.eq (local.get $id) (i32.const 108))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (if (result (ref null eq)) (call $is-fixnum (local.get $result))
          (then (return (local.get $result)))
          (else (return (call $make-fixnum
            (call $safe-trunc-i32
              (f64.trunc (call $float-value
                (ref.cast (ref $float-box) (local.get $result)))))))))))
    ;; 109 = floor (toward -infinity)
    (if (i32.eq (local.get $id) (i32.const 109))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (if (result (ref null eq)) (call $is-fixnum (local.get $result))
          (then (return (local.get $result)))
          (else (return (call $make-fixnum
            (call $safe-trunc-i32
              (f64.floor (call $float-value
                (ref.cast (ref $float-box) (local.get $result)))))))))))

    ;; 110 = exact->inexact (convert to float)
    (if (i32.eq (local.get $id) (i32.const 110))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (if (result (ref null eq)) (call $is-fixnum (local.get $result))
          (then (return (call $make-float (f64.convert_i32_s
            (call $fixnum-value (ref.cast (ref i31) (local.get $result)))))))
          (else (return (local.get $result))))))

    ;; --- Compiler/macro support primitives ---

    ;; 86 = get-macro (name) — look up compile-time macro, return transformer or #f
    (if (i32.eq (local.get $id) (i32.const 86))
      (then
        (if (ref.is_null (global.get $macro-table))
          (then (return (global.get $false))))
        ;; hash-ref returns null if not found
        (local.set $id (i32.const 0))  ;; reuse $id as temp
        (return
          (if (result (ref null eq))
            (ref.is_null
              (call $hash-ref-impl
                (ref.cast (ref $hash-table) (global.get $macro-table))
                (call $arg1 (local.get $args))))
            (then (global.get $false))
            (else (call $hash-ref-impl
              (ref.cast (ref $hash-table) (global.get $macro-table))
              (call $arg1 (local.get $args))))))))

    ;; 87 = set-macro! (name, transformer) — store compile-time macro
    (if (i32.eq (local.get $id) (i32.const 87))
      (then
        ;; Create macro table if needed
        (if (ref.is_null (global.get $macro-table))
          (then
            (global.set $macro-table
              (struct.new $hash-table
                (array.new_default $hash-keys (i32.const 64))
                (array.new_default $hash-vals (i32.const 64))
                (i32.const 0)))))
        (call $hash-set-impl
          (ref.cast (ref $hash-table) (global.get $macro-table))
          (call $arg1 (local.get $args))
          (call $arg2 (local.get $args)))
        (return (global.get $void))))

    ;; --- Assembler support primitives ---

    ;; 85 = execute-from-pc (address) — recursive executor entry
    (if (i32.eq (local.get $id) (i32.const 85))
      (then
        ;; Finalize any pending instructions before execution
        (if (i32.eqz (ref.is_null (global.get $pending-instrs)))
          (then (call $finalize-pending-instrs)))
        ;; arg1 = qualified address pair (space-id . pc)
        (return (call $execute
          (call $fixnum-value (ref.cast (ref i31)
            (call $car (ref.cast (ref $pair) (call $arg1 (local.get $args))))))
          (call $fixnum-value (ref.cast (ref i31)
            (call $cdr (ref.cast (ref $pair) (call $arg1 (local.get $args))))))
          (global.get $global-env)))))

    ;; 89 = apply-compiled-procedure (proc, args)
    (if (i32.eq (local.get $id) (i32.const 89))
      (then
        ;; Set pending proc and argl so $execute initializes registers
        (global.set $execute-proc (call $arg1 (local.get $args)))
        (global.set $execute-argl (call $arg2 (local.get $args)))
        (return (call $execute
          (call $compiled-proc-space
            (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args))))
          (call $compiled-proc-pc
            (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args))))
          (call $compiled-proc-env
            (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args))))))))

    ;; 90 = try-eval (expr) — evaluate with error trapping
    ;; On WASM, errors propagate as traps — JS catches them.
    ;; This primitive looks up 'evaluate' in the global env and calls it.
    (if (i32.eq (local.get $id) (i32.const 90))
      (then
        ;; Look up evaluate function
        (local.set $id (i32.const 0))  ;; reuse $id as temp
        ;; For now, just return void — try-eval needs full evaluate lookup
        ;; The ECE prelude defines try-eval as an ECE function calling mc-compile-and-go
        (return (global.get $void))))

    ;; 91 = extend-environment (names, vals, env, nvals)
    (if (i32.eq (local.get $id) (i32.const 91))
      (then
        (return (call $extend-env
          (call $arg1 (local.get $args))
          (call $arg2 (local.get $args))
          (call $arg3 (local.get $args))
          (call $fixnum-value (ref.cast (ref i31)
            (call $car (ref.cast (ref $pair)
              (call $cdr (ref.cast (ref $pair)
                (call $cdr (ref.cast (ref $pair)
                  (call $cdr (ref.cast (ref $pair) (local.get $args)))))))))))))))

    ;; 92 = %intern-ece (string) — intern string as symbol
    (if (i32.eq (local.get $id) (i32.const 92))
      (then
        (return (call $intern
          (ref.cast (ref $string) (call $arg1 (local.get $args)))))))

    ;; 93 = %instruction-vector-length — current space instruction count
    (if (i32.eq (local.get $id) (i32.const 93))
      (then
        (return (call $make-fixnum
          (struct.get $comp-space $len
            (call $get-space (global.get $current-space-id)))))))

    ;; 94 = %instruction-vector-push! (instr-list) — defer to current space
    (if (i32.eq (local.get $id) (i32.const 94))
      (then
        ;; Record the instruction's target PC (current len) and defer conversion
        (global.set $pending-instrs
          (call $cons
            (call $cons
              (call $make-fixnum (global.get $current-space-id))
              (call $cons
                (call $make-fixnum
                  (struct.get $comp-space $len
                    (call $get-space (global.get $current-space-id))))
                (call $arg1 (local.get $args))))
            (global.get $pending-instrs)))
        ;; Increment len so label PCs are correct
        (struct.set $comp-space $len
          (call $get-space (global.get $current-space-id))
          (i32.add
            (struct.get $comp-space $len
              (call $get-space (global.get $current-space-id)))
            (i32.const 1)))
        (return (global.get $void))))

    ;; 95 = %label-table-set! (label-sym, pc) — set in current space
    (if (i32.eq (local.get $id) (i32.const 95))
      (then
        (call $space-label-set
          (call $get-space (global.get $current-space-id))
          (call $arg1 (local.get $args))
          (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))
        (return (global.get $void))))

    ;; 96 = %label-table-ref (label-sym) — look up in current space
    (if (i32.eq (local.get $id) (i32.const 96))
      (then
        (return (call $make-fixnum
          (call $space-label-ref
            (call $get-space (global.get $current-space-id))
            (call $arg1 (local.get $args)))))))

    ;; 97 = %procedure-name-set! (pc, name) — no-op for now
    (if (i32.eq (local.get $id) (i32.const 97))
      (then (return (global.get $void))))

    ;; --- Compilation space primitives (core IDs 125-135) ---

    ;; 125 = %create-space (name) — name can be symbol or string
    (if (i32.eq (local.get $id) (i32.const 125))
      (then
        ;; If arg is a string, intern it as a symbol first
        (if (call $is-string (call $arg1 (local.get $args)))
          (then
            (call $register-space
              (struct.new $comp-space
                (call $intern (ref.cast (ref $string) (call $arg1 (local.get $args))))
                (array.new_default $instr-vec (i32.const 131072))
                (i32.const 0)
                (ref.null eq)))
            (return (call $make-fixnum
              (struct.get $symbol $id
                (call $intern (ref.cast (ref $string) (call $arg1 (local.get $args))))))))
          (else
            (call $register-space
              (struct.new $comp-space
                (ref.cast (ref $symbol) (call $arg1 (local.get $args)))
                (array.new_default $instr-vec (i32.const 131072))
                (i32.const 0)
                (ref.null eq)))
            (return (call $make-fixnum
              (struct.get $symbol $id
                (ref.cast (ref $symbol) (call $arg1 (local.get $args))))))))))

    ;; 126 = %space-instruction-length (space-id)
    (if (i32.eq (local.get $id) (i32.const 126))
      (then
        (return (call $make-fixnum
          (struct.get $comp-space $len
            (call $get-space
              (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))))))))

    ;; 127 = %space-name (space-id)
    (if (i32.eq (local.get $id) (i32.const 127))
      (then
        (return (struct.get $comp-space $name
          (call $get-space
            (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args)))))))))

    ;; 128 = %current-space-id
    (if (i32.eq (local.get $id) (i32.const 128))
      (then (return (call $make-fixnum (global.get $current-space-id)))))

    ;; 129 = %set-current-space-id! (space-id)
    (if (i32.eq (local.get $id) (i32.const 129))
      (then
        (global.set $current-space-id
          (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args)))))
        (return (global.get $void))))

    ;; 130 = %space-instruction-push! (space-id, instr-list) — defer
    (if (i32.eq (local.get $id) (i32.const 130))
      (then
        ;; Record: (space-id pc . instr-list) and defer conversion
        (global.set $pending-instrs
          (call $cons
            (call $cons
              (call $arg1 (local.get $args))
              (call $cons
                (call $make-fixnum
                  (struct.get $comp-space $len
                    (call $get-space
                      (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args)))))))
                (call $arg2 (local.get $args))))
            (global.get $pending-instrs)))
        ;; Increment len
        (struct.set $comp-space $len
          (call $get-space
            (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args)))))
          (i32.add
            (struct.get $comp-space $len
              (call $get-space
                (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))))
            (i32.const 1)))
        (return (global.get $void))))

    ;; 131 = %space-label-set! (space-id, label-sym, pc)
    (if (i32.eq (local.get $id) (i32.const 131))
      (then
        (call $space-label-set
          (call $get-space
            (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args)))))
          (call $arg2 (local.get $args))
          (call $fixnum-value (ref.cast (ref i31) (call $arg3 (local.get $args)))))
        (return (global.get $void))))

    ;; 132 = %space-label-ref (space-id, label-sym)
    (if (i32.eq (local.get $id) (i32.const 132))
      (then
        (return (call $make-fixnum
          (call $space-label-ref
            (call $get-space
              (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args)))))
            (call $arg2 (local.get $args)))))))

    ;; 133 = %space-count
    (if (i32.eq (local.get $id) (i32.const 133))
      (then (return (call $make-fixnum (global.get $space-count)))))

    ;; 134 = %space-source-ref — not applicable on WASM (instrs are structs, not lists)
    (if (i32.eq (local.get $id) (i32.const 134))
      (then (return (global.get $void))))

    ;; 135 = %space-label-entries — return label table as alist
    (if (i32.eq (local.get $id) (i32.const 135))
      (then (return (global.get $nil))))  ;; stub for now

    ;; --- Platform hash table primitives (core IDs 141-149) ---
    ;; 141 = %make-hash-table
    (if (i32.eq (local.get $id) (i32.const 141))
      (then (return (struct.new $hash-table
        (array.new_default $hash-keys (i32.const 16))
        (array.new_default $hash-vals (i32.const 16))
        (i32.const 0)))))
    ;; 142 = hash-table?
    (if (i32.eq (local.get $id) (i32.const 142))
      (then (return (if (result (ref null eq))
        (ref.test (ref $hash-table) (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 143 = hash-ref (ht key [default])
    (if (i32.eq (local.get $id) (i32.const 143))
      (then (return (call $prim-hash-ref-with-default (local.get $args)))))
    ;; 144 = hash-set! (ht key val)
    (if (i32.eq (local.get $id) (i32.const 144))
      (then
        (call $hash-set-impl
          (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))
          (call $arg2 (local.get $args))
          (call $arg3 (local.get $args)))
        (return (global.get $void))))
    ;; 145 = hash-remove! (ht key)
    (if (i32.eq (local.get $id) (i32.const 145))
      (then
        (call $hash-remove-impl
          (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))
          (call $arg2 (local.get $args)))
        (return (global.get $void))))
    ;; 146 = hash-has-key? (ht key)
    (if (i32.eq (local.get $id) (i32.const 146))
      (then (return (call $hash-has-key-impl
        (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))
        (call $arg2 (local.get $args))))))
    ;; 147 = hash-keys (ht)
    (if (i32.eq (local.get $id) (i32.const 147))
      (then (return (call $hash-keys-impl
        (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))))))
    ;; 148 = hash-values (ht)
    (if (i32.eq (local.get $id) (i32.const 148))
      (then (return (call $hash-values-impl
        (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))))))
    ;; 149 = hash-count (ht)
    (if (i32.eq (local.get $id) (i32.const 149))
      (then (return (call $make-fixnum
        (struct.get $hash-table $count
          (ref.cast (ref $hash-table) (call $arg1 (local.get $args))))))))

    ;; --- Yield primitive (core ID 150) ---
    ;; %yield!: store continuation arg, set yield flag. Executor exits on next iteration.
    (if (i32.eq (local.get $id) (i32.const 150))
      (then
        (global.set $yield-continuation (call $arg1 (local.get $args)))
        (global.set $yield-flag (i32.const 1))
        (return (global.get $void))))

    ;; 151 = current-milliseconds (ms since page load via performance.now)
    (if (i32.eq (local.get $id) (i32.const 151))
      (then (return (call $make-fixnum (call $js-performance-now)))))
    ;; 152-154 (sin, cos, wall-clock-ms) and 200-206 (canvas) — now in browser-lib.scm via FFI

    ;; ── JavaScript FFI primitives (210-221) ──

    ;; 210 = %js-eval (string) → js-ref
    (if (i32.eq (local.get $id) (i32.const 210))
      (then
        (local.set $id (i32.const 0))  ;; reuse $id as temp
        (local.set $id (array.len (ref.cast (ref $string) (call $arg1 (local.get $args)))))
        (call $string-to-memory (ref.cast (ref $string) (call $arg1 (local.get $args))))
        (return (call $make-js-ref (call $js-ffi-eval (i32.const 0) (local.get $id))))))

    ;; 211 = %js-get (js-ref prop-string) → js-ref
    (if (i32.eq (local.get $id) (i32.const 211))
      (then
        (local.set $id
          (array.len (ref.cast (ref $string) (call $arg2 (local.get $args)))))
        (call $string-to-memory (ref.cast (ref $string) (call $arg2 (local.get $args))))
        (return (call $make-js-ref
          (call $js-ffi-get
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args))))
            (i32.const 0) (local.get $id))))))

    ;; 212 = %js-set! (js-ref prop-string val-handle) → void
    (if (i32.eq (local.get $id) (i32.const 212))
      (then
        (local.set $id
          (array.len (ref.cast (ref $string) (call $arg2 (local.get $args)))))
        (call $string-to-memory (ref.cast (ref $string) (call $arg2 (local.get $args))))
        (call $js-ffi-set
          (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args))))
          (i32.const 0) (local.get $id)
          (call $alloc-handle (call $arg3 (local.get $args))))
        (return (global.get $void))))

    ;; 213 = %js-call (js-ref method-string args-list) → js-ref
    (if (i32.eq (local.get $id) (i32.const 213))
      (then
        (local.set $id
          (array.len (ref.cast (ref $string) (call $arg2 (local.get $args)))))
        (call $string-to-memory (ref.cast (ref $string) (call $arg2 (local.get $args))))
        (return (call $make-js-ref
          (call $js-ffi-call
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args))))
            (i32.const 0) (local.get $id)
            (call $alloc-handle (call $arg3 (local.get $args))))))))

    ;; 214 = %js-callback (proc) → js-ref
    (if (i32.eq (local.get $id) (i32.const 214))
      (then
        (return (call $make-js-ref
          (call $js-ffi-callback
            (call $alloc-handle (call $arg1 (local.get $args))))))))

    ;; 215 = %js-ref->number (js-ref) → number
    ;; JS side stores the number; we retrieve via ffi.get with special prop "__value__"
    ;; Simpler: just use the js handle idx and let JS convert
    ;; For now: export a helper that JS calls to set the value
    ;; Actually simplest: add a dedicated import for number extraction
    ;; But design says JS-side marshalling. Let's use js-ffi-get with a sentinel.
    ;; DECISION: Add two more imports for number/string extraction.
    ;; For MVP: implement via %js-call on a helper.
    ;; Actually, we can reuse ffi.get with a null property to mean "valueOf":
    ;; Simpler approach: these are handled entirely in JS via the handle table.
    ;; The WASM side passes the js-ref idx to JS and JS returns the value.

    ;; For 215-218: we need lightweight imports. Let me add them inline.
    ;; 215 = %js-ref->number: pass js handle idx, JS returns f64
    ;; 216 = %js-ref->string: pass js handle idx, JS writes to linear mem, returns len
    ;; 217 = %js-number: pass f64, JS stores and returns handle idx
    ;; 218 = %js-string: pass string ptr+len, JS creates string, returns handle idx
    ;; These need additional imports. But the design says 5 imports total.
    ;; Let's implement 215-218 by calling through ffi.eval with conversion expressions.
    ;; Actually simplest: just add 4 more imports. The "5 imports" was an estimate.

    ;; PUNT: For now return void for 215-218 and add imports in the JS bridge task.
    ;; Actually let me just do it properly with inline conversion:

    ;; 215 = %js-ref->number (js-ref) → ECE number (fixnum if integer, float otherwise)
    (if (i32.eq (local.get $id) (i32.const 215))
      (then
        (return (call $f64-to-ece-number
          (call $js-ffi-to-number
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args)))))))))

    ;; 216 = %js-ref->string (js-ref) → ECE string
    (if (i32.eq (local.get $id) (i32.const 216))
      (then
        ;; JS writes string to linear memory, returns char count
        (local.set $id
          (call $js-ffi-to-string
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args))))))
        ;; Build ECE string from linear memory
        (return (call $memory-to-string (i32.const 0) (local.get $id)))))

    ;; 217 = %js-number (ECE number) → js-ref
    (if (i32.eq (local.get $id) (i32.const 217))
      (then
        (return (call $make-js-ref
          (call $js-ffi-from-number
            (call $to-f64 (call $arg1 (local.get $args))))))))

    ;; 218 = %js-string (ECE string) → js-ref
    (if (i32.eq (local.get $id) (i32.const 218))
      (then
        (local.set $id
          (array.len (ref.cast (ref $string) (call $arg1 (local.get $args)))))
        (call $string-to-memory (ref.cast (ref $string) (call $arg1 (local.get $args))))
        (return (call $make-js-ref
          (call $js-ffi-from-string (i32.const 0) (local.get $id))))))

    ;; 219 = %js-null? (js-ref) → boolean
    (if (i32.eq (local.get $id) (i32.const 219))
      (then
        (return (if (result (ref null eq))
          (call $js-ffi-is-null
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args)))))
          (then (global.get $true)) (else (global.get $false))))))

    ;; 220 = %js-release! (js-ref) → void
    (if (i32.eq (local.get $id) (i32.const 220))
      (then
        (call $js-ffi-release
          (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args)))))
        (return (global.get $void))))

    ;; 221 = %js-ref? (value) → boolean
    (if (i32.eq (local.get $id) (i32.const 221))
      (then
        (return (if (result (ref null eq))
          (call $is-js-ref (call $arg1 (local.get $args)))
          (then (global.get $true)) (else (global.get $false))))))

    ;; --- Identity hash tables (alist-based with ref.eq) ---


    ;; 121 = %hash-frame?(val) → always #f on WASM (no CL hash frames)
    (if (i32.eq (local.get $id) (i32.const 121))
      (then (return (global.get $false))))

    ;; 138 = %primitive-name(id) → symbol name
    ;; For now, return #f (the serializer handles it)
    (if (i32.eq (local.get $id) (i32.const 138))
      (then (return (global.get $false))))

    ;; 139 = %primitive-id(name-sym) → fixnum id or #f
    ;; For now, return #f (serializer handles it via fallback)
    (if (i32.eq (local.get $id) (i32.const 139))
      (then (return (global.get $false))))

    ;; 140 = %global-env-frame() → first frame of global env
    (if (i32.eq (local.get $id) (i32.const 140))
      (then (return (global.get $global-env))))

    ;; --- Type introspection primitives ---

    ;; 155 = compiled-procedure?(val)
    (if (i32.eq (local.get $id) (i32.const 155))
      (then (return (if (result (ref null eq)) (call $is-compiled-proc (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))

    ;; 156 = continuation?(val)
    (if (i32.eq (local.get $id) (i32.const 156))
      (then (return (if (result (ref null eq)) (call $is-continuation (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))

    ;; 157 = primitive?(val)
    (if (i32.eq (local.get $id) (i32.const 157))
      (then (return (if (result (ref null eq)) (call $is-primitive (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))

    ;; 158 = compiled-procedure-entry(proc) → (space-id . pc) pair
    (if (i32.eq (local.get $id) (i32.const 158))
      (then
        (return (call $cons
          (call $make-fixnum (call $compiled-proc-space
            (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args)))))
          (call $make-fixnum (call $compiled-proc-pc
            (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args)))))))))

    ;; 159 = compiled-procedure-env(proc) → env
    (if (i32.eq (local.get $id) (i32.const 159))
      (then (return (call $compiled-proc-env
        (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args)))))))

    ;; 160 = continuation-stack(k) → stack
    (if (i32.eq (local.get $id) (i32.const 160))
      (then (return (struct.get $continuation $stack
        (ref.cast (ref $continuation) (call $arg1 (local.get $args)))))))

    ;; 161 = continuation-conts(k) → conts
    (if (i32.eq (local.get $id) (i32.const 161))
      (then (return (struct.get $continuation $conts
        (ref.cast (ref $continuation) (call $arg1 (local.get $args)))))))

    ;; 162 = %primitive-id-of(prim) → fixnum id
    (if (i32.eq (local.get $id) (i32.const 162))
      (then (return (call $make-fixnum (struct.get $primitive $id
        (ref.cast (ref $primitive) (call $arg1 (local.get $args))))))))

    ;; 163 = %make-compiled-procedure(entry, env) → compiled-proc
    ;; entry is (space-id . pc) pair
    (if (i32.eq (local.get $id) (i32.const 163))
      (then (return (struct.new $compiled-proc
        (call $fixnum-value (ref.cast (ref i31) (call $car (ref.cast (ref $pair) (call $arg1 (local.get $args))))))
        (call $fixnum-value (ref.cast (ref i31) (call $cdr (ref.cast (ref $pair) (call $arg1 (local.get $args))))))
        (call $arg2 (local.get $args))))))

    ;; 164 = %make-continuation(stack, conts, winds) → continuation
    (if (i32.eq (local.get $id) (i32.const 164))
      (then (return (struct.new $continuation
        (call $arg1 (local.get $args))
        (call $arg2 (local.get $args))
        (call $arg3 (local.get $args))))))

    ;; 165 = %make-primitive(id) → primitive struct
    (if (i32.eq (local.get $id) (i32.const 165))
      (then (return (struct.new $primitive
        (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))))))

    ;; 166 = %env-frame?(val) → bool
    (if (i32.eq (local.get $id) (i32.const 166))
      (then (return (if (result (ref null eq))
        (ref.test (ref $env-frame) (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))

    ;; 167 = %env-frame-names(frame) → names list
    (if (i32.eq (local.get $id) (i32.const 167))
      (then (return (struct.get $env-frame $names
        (ref.cast (ref $env-frame) (call $arg1 (local.get $args)))))))

    ;; 168 = %env-frame-vals(frame) → vals as a proper list (right-to-left build)
    (if (i32.eq (local.get $id) (i32.const 168))
      (then
        (local.set $cur (global.get $nil))
        (local.set $id  ;; reuse $id as loop counter
          (i32.sub
            (array.len (struct.get $env-frame $vals
              (ref.cast (ref $env-frame) (call $arg1 (local.get $args)))))
            (i32.const 1)))
        (block $done (loop $build
          (br_if $done (i32.lt_s (local.get $id) (i32.const 0)))
          (local.set $cur (call $cons
            (array.get $val-array
              (struct.get $env-frame $vals
                (ref.cast (ref $env-frame) (call $arg1 (local.get $args))))
              (local.get $id))
            (local.get $cur)))
          (local.set $id (i32.sub (local.get $id) (i32.const 1)))
          (br $build)))
        (return (local.get $cur))))

    ;; 169 = %env-frame-enclosing(frame) → enclosing frame or nil
    (if (i32.eq (local.get $id) (i32.const 169))
      (then
        (local.set $cur (struct.get $env-frame $enclosing
          (ref.cast (ref $env-frame) (call $arg1 (local.get $args)))))
        (return (if (result (ref null eq)) (ref.is_null (local.get $cur))
          (then (global.get $nil)) (else (local.get $cur))))))

    ;; 170 = %make-env-frame(names, vals-list, enclosing) → env-frame
    (if (i32.eq (local.get $id) (i32.const 170))
      (then
        ;; Count vals-list length
        (local.set $cur (call $arg2 (local.get $args)))
        (local.set $id (i32.const 0))
        (block $cnt (loop $c
          (br_if $cnt (ref.is_null (local.get $cur)))
          (br_if $cnt (call $is-null (local.get $cur)))
          (local.set $id (i32.add (local.get $id) (i32.const 1)))
          (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
          (br $c)))
        ;; Build vals array from list
        (local.set $key (array.new_default $val-array (local.get $id)))
        (local.set $cur (call $arg2 (local.get $args)))
        (local.set $id (i32.const 0))
        (block $fill (loop $f
          (br_if $fill (ref.is_null (local.get $cur)))
          (br_if $fill (call $is-null (local.get $cur)))
          (array.set $val-array (ref.cast (ref $val-array) (local.get $key))
            (local.get $id)
            (call $car (ref.cast (ref $pair) (local.get $cur))))
          (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
          (local.set $id (i32.add (local.get $id) (i32.const 1)))
          (br $f)))
        ;; Enclosing: nil → null
        (local.set $cur (call $arg3 (local.get $args)))
        (return (struct.new $env-frame
          (call $arg1 (local.get $args))
          (ref.cast (ref $val-array) (local.get $key))
          (if (result (ref null eq)) (call $is-null (local.get $cur))
            (then (ref.null eq))
            (else (local.get $cur)))))))

    ;; 171 = %set-winding-stack!(val) — sync WAT global
    (if (i32.eq (local.get $id) (i32.const 171))
      (then
        (global.set $winding-stack (call $arg1 (local.get $args)))
        (return (global.get $void))))

    ;; 172 = %get-winding-stack() — read WAT global
    (if (i32.eq (local.get $id) (i32.const 172))
      (then
        (return (if (result (ref null eq)) (ref.is_null (global.get $winding-stack))
          (then (global.get $nil))
          (else (global.get $winding-stack))))))

    ;; 173 = continuation-winds(cont) — get saved winding stack
    (if (i32.eq (local.get $id) (i32.const 173))
      (then (return (struct.get $continuation $winds
        (ref.cast (ref $continuation) (call $arg1 (local.get $args)))))))

    ;; Unknown primitive — return void
    (global.get $void)
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 10a: .ecec Text Reader (WAT-native s-expression loader)
  ;; ═══════════════════════════════════════════════════════════════════
  ;; Reads .ecec text from linear memory and loads instructions into
  ;; compilation spaces. Handles the limited .ecec grammar only (no
  ;; quasiquote, interpolation, hash literals, etc.).

  ;; Cursor: position in linear memory (UTF-16 code units)
  (global $ecec-pos (mut i32) (i32.const 0))
  (global $ecec-end (mut i32) (i32.const 0))

  ;; Parse-operand output (replaces multivalue return)
  (global $ecec-op-type (mut i32) (i32.const 0))   ;; 0=const, 1=reg, 2=label, 3=op
  (global $ecec-op-arg  (mut i32) (i32.const 0))   ;; reg-id or op-id
  (global $ecec-op-val  (mut (ref null eq)) (ref.null eq)) ;; constant or label symbol

  (func $ecec-peek (result i32)
    (if (result i32) (i32.ge_u (global.get $ecec-pos) (global.get $ecec-end))
      (then (i32.const -1))  ;; EOF
      (else (i32.load16_u (i32.shl (global.get $ecec-pos) (i32.const 1))))))

  (func $ecec-read (result i32)
    (local $ch i32)
    (if (result i32) (i32.ge_u (global.get $ecec-pos) (global.get $ecec-end))
      (then (i32.const -1))
      (else
        (local.set $ch (i32.load16_u (i32.shl (global.get $ecec-pos) (i32.const 1))))
        (global.set $ecec-pos (i32.add (global.get $ecec-pos) (i32.const 1)))
        (local.get $ch))))

  (func $ecec-skip-ws
    (local $ch i32)
    (block $done (loop $again
      (local.set $ch (call $ecec-peek))
      (br_if $done (i32.eq (local.get $ch) (i32.const -1)))
      ;; Whitespace: space, tab, newline, CR
      (if (i32.or (i32.or (i32.eq (local.get $ch) (i32.const 32))
                           (i32.eq (local.get $ch) (i32.const 9)))
                  (i32.or (i32.eq (local.get $ch) (i32.const 10))
                           (i32.eq (local.get $ch) (i32.const 13))))
        (then (drop (call $ecec-read)) (br $again)))
      ;; Comment: ;
      (if (i32.eq (local.get $ch) (i32.const 59))
        (then
          (block $eol (loop $skip
            (local.set $ch (call $ecec-read))
            (br_if $eol (i32.eq (local.get $ch) (i32.const -1)))
            (br_if $eol (i32.eq (local.get $ch) (i32.const 10)))
            (br $skip)))
          (br $again))))))

  ;; Read a symbol: accumulate chars until delimiter, intern the result
  (func $ecec-read-symbol (param $first-ch i32) (result (ref null eq))
    (local $buf (ref $string))
    (local $len i32)
    (local $cap i32)
    (local $ch i32)
    (local $new-buf (ref $string))
    (local $i i32)
    (local.set $cap (i32.const 32))
    (local.set $buf (array.new_default $string (local.get $cap)))
    ;; Store first char
    (array.set $string (local.get $buf) (i32.const 0) (local.get $first-ch))
    (local.set $len (i32.const 1))
    ;; Read remaining chars
    (block $done (loop $again
      (local.set $ch (call $ecec-peek))
      (br_if $done (i32.eq (local.get $ch) (i32.const -1)))
      (br_if $done (i32.eq (local.get $ch) (i32.const 32)))   ;; space
      (br_if $done (i32.eq (local.get $ch) (i32.const 9)))    ;; tab
      (br_if $done (i32.eq (local.get $ch) (i32.const 10)))   ;; newline
      (br_if $done (i32.eq (local.get $ch) (i32.const 13)))   ;; CR
      (br_if $done (i32.eq (local.get $ch) (i32.const 40)))   ;; (
      (br_if $done (i32.eq (local.get $ch) (i32.const 41)))   ;; )
      (br_if $done (i32.eq (local.get $ch) (i32.const 34)))   ;; "
      (br_if $done (i32.eq (local.get $ch) (i32.const 59)))   ;; ;
      (drop (call $ecec-read))
      ;; Grow buffer if needed
      (if (i32.ge_u (local.get $len) (local.get $cap))
        (then
          (local.set $cap (i32.mul (local.get $cap) (i32.const 2)))
          (local.set $new-buf (array.new_default $string (local.get $cap)))
          (local.set $i (i32.const 0))
          (block $d2 (loop $c2
            (br_if $d2 (i32.ge_u (local.get $i) (local.get $len)))
            (array.set $string (local.get $new-buf) (local.get $i)
              (array.get_u $string (local.get $buf) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $c2)))
          (local.set $buf (local.get $new-buf))))
      (array.set $string (local.get $buf) (local.get $len) (local.get $ch))
      (local.set $len (i32.add (local.get $len) (i32.const 1)))
      (br $again)))
    ;; Trim buffer to length and intern
    (local.set $new-buf (array.new_default $string (local.get $len)))
    (local.set $i (i32.const 0))
    (block $d3 (loop $c3
      (br_if $d3 (i32.ge_u (local.get $i) (local.get $len)))
      (array.set $string (local.get $new-buf) (local.get $i)
        (array.get_u $string (local.get $buf) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $c3)))
    (call $intern (local.get $new-buf)))

  ;; Read a string literal (opening " already consumed)
  (func $ecec-read-string (result (ref null eq))
    (local $buf (ref $string))
    (local $len i32)
    (local $cap i32)
    (local $ch i32)
    (local $new-buf (ref $string))
    (local $i i32)
    (local.set $cap (i32.const 64))
    (local.set $buf (array.new_default $string (local.get $cap)))
    (block $done (loop $again
      (local.set $ch (call $ecec-read))
      (br_if $done (i32.eq (local.get $ch) (i32.const -1)))
      (br_if $done (i32.eq (local.get $ch) (i32.const 34)))  ;; closing "
      ;; Escape sequences
      (if (i32.eq (local.get $ch) (i32.const 92))  ;; backslash
        (then
          (local.set $ch (call $ecec-read))
          (if (i32.eq (local.get $ch) (i32.const 110))   ;; \n
            (then (local.set $ch (i32.const 10))))
          (if (i32.eq (local.get $ch) (i32.const 116))   ;; \t
            (then (local.set $ch (i32.const 9))))))
      ;; Grow buffer if needed
      (if (i32.ge_u (local.get $len) (local.get $cap))
        (then
          (local.set $cap (i32.mul (local.get $cap) (i32.const 2)))
          (local.set $new-buf (array.new_default $string (local.get $cap)))
          (local.set $i (i32.const 0))
          (block $d2 (loop $c2
            (br_if $d2 (i32.ge_u (local.get $i) (local.get $len)))
            (array.set $string (local.get $new-buf) (local.get $i)
              (array.get_u $string (local.get $buf) (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $c2)))
          (local.set $buf (local.get $new-buf))))
      (array.set $string (local.get $buf) (local.get $len) (local.get $ch))
      (local.set $len (i32.add (local.get $len) (i32.const 1)))
      (br $again)))
    ;; Trim to length
    (local.set $new-buf (array.new_default $string (local.get $len)))
    (local.set $i (i32.const 0))
    (block $d3 (loop $c3
      (br_if $d3 (i32.ge_u (local.get $i) (local.get $len)))
      (array.set $string (local.get $new-buf) (local.get $i)
        (array.get_u $string (local.get $buf) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $c3)))
    (local.get $new-buf))

  ;; Read a number (first char is digit or sign followed by digit)
  (func $ecec-read-number (param $first-ch i32) (result (ref null eq))
    (local $val i32)
    (local $neg i32)
    (local $ch i32)
    (local $has-dot i32)
    (local $fval f64)
    (local $frac f64)
    (local $fdiv f64)
    ;; Handle sign
    (if (i32.eq (local.get $first-ch) (i32.const 45))  ;; '-'
      (then
        (local.set $neg (i32.const 1))
        (local.set $first-ch (call $ecec-read))))
    ;; Parse integer part
    (local.set $val (i32.sub (local.get $first-ch) (i32.const 48)))
    (block $done (loop $again
      (local.set $ch (call $ecec-peek))
      (if (i32.and (i32.ge_u (local.get $ch) (i32.const 48))
                   (i32.le_u (local.get $ch) (i32.const 57)))
        (then
          (drop (call $ecec-read))
          (local.set $val (i32.add (i32.mul (local.get $val) (i32.const 10))
                                   (i32.sub (local.get $ch) (i32.const 48))))
          (br $again)))
      ;; Check for decimal point
      (if (i32.eq (local.get $ch) (i32.const 46))  ;; '.'
        (then
          (local.set $has-dot (i32.const 1))
          (drop (call $ecec-read))))))
    ;; If has decimal point, parse fractional part
    (if (local.get $has-dot)
      (then
        (local.set $fval (f64.convert_i32_s (local.get $val)))
        (local.set $fdiv (f64.const 10))
        (block $done2 (loop $again2
          (local.set $ch (call $ecec-peek))
          (if (i32.and (i32.ge_u (local.get $ch) (i32.const 48))
                       (i32.le_u (local.get $ch) (i32.const 57)))
            (then
              (drop (call $ecec-read))
              (local.set $fval (f64.add (local.get $fval)
                (f64.div (f64.convert_i32_u (i32.sub (local.get $ch) (i32.const 48)))
                         (local.get $fdiv))))
              (local.set $fdiv (f64.mul (local.get $fdiv) (f64.const 10)))
              (br $again2)))))
        (if (local.get $neg)
          (then (local.set $fval (f64.neg (local.get $fval)))))
        (return (struct.new $float-box (local.get $fval)))))
    ;; Integer result
    (if (local.get $neg)
      (then (local.set $val (i32.sub (i32.const 0) (local.get $val)))))
    (call $make-fixnum (local.get $val)))

  ;; Read one s-expression from the ecec buffer
  (func $ecec-read-sexp (result (ref null eq))
    (local $ch i32)
    (call $ecec-skip-ws)
    (local.set $ch (call $ecec-peek))
    ;; EOF
    (if (i32.eq (local.get $ch) (i32.const -1))
      (then (return (global.get $eof))))
    ;; List
    (if (i32.eq (local.get $ch) (i32.const 40))  ;; (
      (then
        (drop (call $ecec-read))
        (return (call $ecec-read-list))))
    ;; String
    (if (i32.eq (local.get $ch) (i32.const 34))  ;; "
      (then
        (drop (call $ecec-read))
        (return (call $ecec-read-string))))
    ;; Hash dispatch: #t, #f, #\char
    (if (i32.eq (local.get $ch) (i32.const 35))  ;; #
      (then
        (drop (call $ecec-read))
        (return (call $ecec-read-hash))))
    ;; Negative number
    (if (i32.eq (local.get $ch) (i32.const 45))  ;; -
      (then
        (drop (call $ecec-read))
        ;; Check if next char is digit
        (local.set $ch (call $ecec-peek))
        (if (i32.and (i32.ge_u (local.get $ch) (i32.const 48))
                     (i32.le_u (local.get $ch) (i32.const 57)))
          (then (return (call $ecec-read-number (i32.const 45)))))
        ;; Otherwise it's the symbol -
        (return (call $ecec-read-symbol (i32.const 45)))))
    ;; Number
    (if (i32.and (i32.ge_u (local.get $ch) (i32.const 48))
                 (i32.le_u (local.get $ch) (i32.const 57)))
      (then
        (drop (call $ecec-read))
        (return (call $ecec-read-number (local.get $ch)))))
    ;; Symbol (anything else)
    (drop (call $ecec-read))
    (call $ecec-check-special (call $ecec-read-symbol (local.get $ch))))

  ;; Check if a symbol is a special name (NIL) and convert to the actual value
  (func $ecec-check-special (param $sym (ref null eq)) (result (ref null eq))
    (local $s (ref $symbol))
    (local $name (ref $string))
    (if (i32.eqz (call $is-symbol (local.get $sym)))
      (then (return (local.get $sym))))
    (local.set $s (ref.cast (ref $symbol) (local.get $sym)))
    (local.set $name (struct.get $symbol $name (local.get $s)))
    ;; Check for "NIL" (3 chars: N=78, I=73, L=76)
    (if (i32.eq (array.len (local.get $name)) (i32.const 3))
      (then
        (if (i32.and
              (i32.and
                (i32.eq (array.get_u $string (local.get $name) (i32.const 0)) (i32.const 78))
                (i32.eq (array.get_u $string (local.get $name) (i32.const 1)) (i32.const 73)))
              (i32.eq (array.get_u $string (local.get $name) (i32.const 2)) (i32.const 76)))
          (then (return (global.get $nil))))))
    ;; Check for "T" (1 char: T=84) — CL's true
    (if (i32.eq (array.len (local.get $name)) (i32.const 1))
      (then
        (if (i32.eq (array.get_u $string (local.get $name) (i32.const 0)) (i32.const 84))
          (then (return (global.get $true))))))
    (local.get $sym))

  ;; Read a list (opening paren already consumed)
  (func $ecec-read-list (result (ref null eq))
    (local $ch i32)
    (local $first (ref null eq))
    (call $ecec-skip-ws)
    (local.set $ch (call $ecec-peek))
    ;; Empty list
    (if (i32.eq (local.get $ch) (i32.const 41))  ;; )
      (then (drop (call $ecec-read)) (return (global.get $nil))))
    ;; Read first element
    (local.set $first (call $ecec-read-sexp))
    ;; Check for dotted pair
    (call $ecec-skip-ws)
    (if (i32.eq (call $ecec-peek) (i32.const 46))  ;; .
      (then
        (drop (call $ecec-read))
        ;; Check it's followed by whitespace (not a symbol starting with .)
        (local.set $ch (call $ecec-peek))
        (if (i32.or (i32.eq (local.get $ch) (i32.const 32))
                    (i32.eq (local.get $ch) (i32.const 10)))
          (then
            ;; Dotted pair
            (local.set $ch (i32.const 0))  ;; reuse as temp
            (local.set $first (call $cons (local.get $first) (call $ecec-read-sexp)))
            (call $ecec-skip-ws)
            (drop (call $ecec-read))  ;; consume )
            (return (local.get $first))))))
    ;; Regular list: cons first with rest
    (call $cons (local.get $first) (call $ecec-read-list)))

  ;; Read a vector literal: #(elem1 elem2 ...) — opening #( already consumed
  (func $ecec-read-vector (result (ref null eq))
    (local $elems (ref null eq))
    (local $len i32)
    (local $vec (ref $vector))
    (local $cur (ref null eq))
    (local $i i32)
    ;; Read elements into a list (then convert to vector)
    (local.set $elems (global.get $nil))
    (local.set $len (i32.const 0))
    (block $done (loop $again
      (call $ecec-skip-ws)
      (br_if $done (i32.eq (call $ecec-peek) (i32.const 41)))  ;; )
      (br_if $done (i32.eq (call $ecec-peek) (i32.const -1)))
      (local.set $elems (call $cons (call $ecec-read-sexp) (local.get $elems)))
      (local.set $len (i32.add (local.get $len) (i32.const 1)))
      (br $again)))
    (drop (call $ecec-read))  ;; consume )
    ;; Reverse the list and build vector
    (local.set $elems (call $prim-reverse (local.get $elems)))
    (local.set $vec (array.new_default $vector (local.get $len)))
    (local.set $cur (local.get $elems))
    (local.set $i (i32.const 0))
    (block $done2 (loop $fill
      (br_if $done2 (i32.ge_u (local.get $i) (local.get $len)))
      (array.set $vector (local.get $vec) (local.get $i)
        (call $car (ref.cast (ref $pair) (local.get $cur))))
      (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $fill)))
    (local.get $vec))

  ;; Read hash dispatch: #t, #f, #\char
  (func $ecec-read-hash (result (ref null eq))
    (local $ch i32)
    (local $ch2 i32)
    (local.set $ch (call $ecec-read))
    ;; #t
    (if (i32.eq (local.get $ch) (i32.const 116))  ;; t
      (then (return (global.get $true))))
    ;; #f
    (if (i32.eq (local.get $ch) (i32.const 102))  ;; f
      (then (return (global.get $false))))
    ;; #( — vector literal
    (if (i32.eq (local.get $ch) (i32.const 40))   ;; (
      (then (return (call $ecec-read-vector))))
    ;; #S(SCHEME-FALSE) — CL struct literal for boolean false
    (if (i32.eq (local.get $ch) (i32.const 83))   ;; S
      (then
        ;; Skip everything until closing )
        (block $sk-s (loop $skl-s
          (local.set $ch (call $ecec-read))
          (br_if $sk-s (i32.eq (local.get $ch) (i32.const -1)))
          (br_if $sk-s (i32.eq (local.get $ch) (i32.const 41)))  ;; )
          (br $skl-s)))
        (return (global.get $false))))
    ;; #\char
    (if (i32.eq (local.get $ch) (i32.const 92))   ;; backslash
      (then
        (local.set $ch (call $ecec-read))
        ;; Check for named characters
        (if (i32.and (i32.ge_u (local.get $ch) (i32.const 65))  ;; A-Z uppercase = named char
                     (i32.le_u (local.get $ch) (i32.const 90)))
          (then
            ;; Read the full name
            (local.set $ch2 (call $ecec-peek))
            (if (i32.and (i32.ge_u (local.get $ch2) (i32.const 97))
                         (i32.le_u (local.get $ch2) (i32.const 122)))
              (then
                ;; Multi-char name: Newline, Tab, Space
                ;; Check first two chars to distinguish
                (if (i32.eq (local.get $ch) (i32.const 78))  ;; N = Newline
                  (then
                    ;; Skip remaining chars of "ewline"
                    (block $sk (loop $skl
                      (local.set $ch2 (call $ecec-peek))
                      (br_if $sk (i32.lt_u (local.get $ch2) (i32.const 97)))
                      (br_if $sk (i32.gt_u (local.get $ch2) (i32.const 122)))
                      (drop (call $ecec-read)) (br $skl)))
                    (return (call $make-char (i32.const 10)))))
                (if (i32.eq (local.get $ch) (i32.const 84))  ;; T = Tab
                  (then
                    (block $sk2 (loop $skl2
                      (local.set $ch2 (call $ecec-peek))
                      (br_if $sk2 (i32.lt_u (local.get $ch2) (i32.const 97)))
                      (br_if $sk2 (i32.gt_u (local.get $ch2) (i32.const 122)))
                      (drop (call $ecec-read)) (br $skl2)))
                    (return (call $make-char (i32.const 9)))))
                (if (i32.eq (local.get $ch) (i32.const 83))  ;; S = Space
                  (then
                    (block $sk3 (loop $skl3
                      (local.set $ch2 (call $ecec-peek))
                      (br_if $sk3 (i32.lt_u (local.get $ch2) (i32.const 97)))
                      (br_if $sk3 (i32.gt_u (local.get $ch2) (i32.const 122)))
                      (drop (call $ecec-read)) (br $skl3)))
                    (return (call $make-char (i32.const 32)))))
                (if (i32.eq (local.get $ch) (i32.const 70))  ;; F = not used, but skip
                  (then
                    (block $sk4 (loop $skl4
                      (local.set $ch2 (call $ecec-peek))
                      (br_if $sk4 (i32.lt_u (local.get $ch2) (i32.const 97)))
                      (br_if $sk4 (i32.gt_u (local.get $ch2) (i32.const 122)))
                      (drop (call $ecec-read)) (br $skl4)))
                    (return (call $make-char (local.get $ch)))))))))
        (return (call $make-char (local.get $ch)))))
    ;; Unknown hash — return as symbol
    (call $ecec-read-symbol (local.get $ch)))

  ;; ── .ecec loader: parse header, create space, load instructions ──

  ;; Recognize register name symbol → register ID (0-5)
  ;; Uses the assembler symbol table (same one used by runtime instruction conversion)
  (func $ecec-reg-id (param $sym (ref $symbol)) (result i32)
    (local $id i32)
    (local.set $id (struct.get $symbol $id (local.get $sym)))
    ;; Check against known register symbol IDs (slots 7-12 in asm-sym-ids)
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 7)))
      (then (return (i32.const 0))))  ;; val
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 8)))
      (then (return (i32.const 1))))  ;; env
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 9)))
      (then (return (i32.const 2))))  ;; proc
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 10)))
      (then (return (i32.const 3))))  ;; argl
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 11)))
      (then (return (i32.const 4))))  ;; continue
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 12)))
      (then (return (i32.const 5))))  ;; stack
    (i32.const -1))

  ;; Recognize operation name symbol → op ID
  (func $ecec-op-id (param $sym (ref $symbol)) (result i32)
    (local $id i32)
    (local $i i32)
    (local.set $id (struct.get $symbol $id (local.get $sym)))
    ;; Op names are in asm-sym-ids slots 17-40 (ops 0-23, op-id = slot - 17)
    (local.set $i (i32.const 17))
    (block $done (loop $scan
      (br_if $done (i32.gt_u (local.get $i) (i32.const 40)))
      (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (local.get $i)))
        (then (return (i32.sub (local.get $i) (i32.const 17)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $scan)))
    (i32.const -1))

  ;; Parse an operand: (const val), (reg name), (label name), (op name)
  ;; Sets globals: $ecec-op-type, $ecec-op-arg, $ecec-op-val
  (func $ecec-parse-operand (param $sexp (ref null eq))
    (local $tag (ref $symbol))
    (local $tag-id i32)
    (local.set $tag (ref.cast (ref $symbol)
      (call $car (ref.cast (ref $pair) (local.get $sexp)))))
    (local.set $tag-id (struct.get $symbol $id (local.get $tag)))
    ;; const (slot 13)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 13)))
      (then
        (global.set $ecec-op-type (i32.const 0))
        (global.set $ecec-op-arg (i32.const 0))
        (global.set $ecec-op-val
          (call $car (ref.cast (ref $pair) (call $cdr-safe (local.get $sexp)))))
        (return)))
    ;; reg (slot 14)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 14)))
      (then
        (global.set $ecec-op-type (i32.const 1))
        (global.set $ecec-op-arg
          (call $ecec-reg-id (ref.cast (ref $symbol)
            (call $car (ref.cast (ref $pair) (call $cdr-safe (local.get $sexp)))))))
        (global.set $ecec-op-val (global.get $nil))
        (return)))
    ;; label (slot 15)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 15)))
      (then
        (global.set $ecec-op-type (i32.const 2))
        (global.set $ecec-op-arg (i32.const 0))
        (global.set $ecec-op-val
          (call $car (ref.cast (ref $pair) (call $cdr-safe (local.get $sexp)))))
        (return)))
    ;; op (slot 16)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 16)))
      (then
        (global.set $ecec-op-type (i32.const 3))
        (global.set $ecec-op-arg
          (call $ecec-op-id (ref.cast (ref $symbol)
            (call $car (ref.cast (ref $pair) (call $cdr-safe (local.get $sexp)))))))
        (global.set $ecec-op-val (global.get $nil))
        (return)))
    ;; Unknown
    (global.set $ecec-op-type (i32.const -1))
    (global.set $ecec-op-arg (i32.const 0))
    (global.set $ecec-op-val (global.get $nil)))

  ;; Safe cdr that handles nil
  (func $cdr-safe (param $v (ref null eq)) (result (ref null eq))
    (if (result (ref null eq)) (call $is-pair (local.get $v))
      (then (call $cdr (ref.cast (ref $pair) (local.get $v))))
      (else (global.get $nil))))

  ;; Build operand list from s-exp list of operands
  (func $ecec-build-operand-list (param $ops (ref null eq)) (param $labels (ref null eq))
                                  (result (ref null eq))
    (local $cur (ref null eq))
    (local $result (ref null eq))
    (local.set $cur (local.get $ops))
    (local.set $result (global.get $nil))
    (block $done (loop $again
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      (br_if $done (i32.eqz (call $is-pair (local.get $cur))))
      (call $ecec-parse-operand
        (call $car (ref.cast (ref $pair) (local.get $cur))))
      (local.set $result (call $cons
        (call $cons (call $make-fixnum (global.get $ecec-op-type))
          (if (result (ref null eq)) (i32.eq (global.get $ecec-op-type) (i32.const 1))
            (then (call $make-fixnum (global.get $ecec-op-arg)))  ;; reg
            (else
              ;; For label operands (type 2), resolve to PC fixnum immediately
              (if (result (ref null eq)) (i32.eq (global.get $ecec-op-type) (i32.const 2))
                (then (call $make-fixnum
                  (call $ecec-label-pc (global.get $ecec-op-val) (local.get $labels))))
                (else (global.get $ecec-op-val))))))  ;; const value
        (local.get $result)))
      (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
      (br $again)))
    ;; Reverse
    (call $prim-reverse (local.get $result)))

  ;; Check if a value is a symbol matching one of the 7 instruction keywords
  (func $ecec-is-instr-keyword (param $v (ref null eq)) (result i32)
    (local $id i32)
    (if (i32.eqz (call $is-symbol (local.get $v)))
      (then (return (i32.const 0))))
    (local.set $id (struct.get $symbol $id
      (ref.cast (ref $symbol) (local.get $v))))
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 0))) (then (return (i32.const 1))))
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 1))) (then (return (i32.const 1))))
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 2))) (then (return (i32.const 1))))
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 3))) (then (return (i32.const 1))))
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 4))) (then (return (i32.const 1))))
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 5))) (then (return (i32.const 1))))
    (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 6))) (then (return (i32.const 1))))
    (i32.const 0))

  ;; Parse a single instruction s-expression into an $instr struct
  ;; Labels resolved at creation using the labels alist.
  (func $ecec-parse-instr (param $sexp (ref null eq)) (param $space-id i32) (param $pc i32)
                           (param $labels (ref null eq)) (result (ref null $instr))
    (local $tag (ref $symbol))
    (local $tag-id i32)
    (local $rest (ref null eq))
    (local $target-reg i32)
    (local $src-type i32) (local $src-arg i32) (local $src-val (ref null eq))
    ;; Bare symbol = label (skip in phase 2)
    (if (call $is-symbol (local.get $sexp))
      (then (return (ref.null $instr))))
    ;; Must be a list: (opcode ...)
    (local.set $tag (ref.cast (ref $symbol)
      (call $car (ref.cast (ref $pair) (local.get $sexp)))))
    (local.set $tag-id (struct.get $symbol $id (local.get $tag)))
    (local.set $rest (call $cdr (ref.cast (ref $pair) (local.get $sexp))))

    ;; assign (slot 0): (assign reg source)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 0)))
      (then
        (local.set $target-reg (call $ecec-reg-id (ref.cast (ref $symbol)
          (call $car (ref.cast (ref $pair) (local.get $rest))))))
        (local.set $rest (call $cdr (ref.cast (ref $pair) (local.get $rest))))
        (call $ecec-parse-operand
          (call $car (ref.cast (ref $pair) (local.get $rest))))
        (local.set $src-type (global.get $ecec-op-type))
        (local.set $src-arg (global.get $ecec-op-arg))
        (local.set $src-val (global.get $ecec-op-val))
        ;; op source: build operand list with resolved labels
        (if (i32.eq (local.get $src-type) (i32.const 3))
          (then
            (local.set $src-val (call $ecec-build-operand-list
              (call $cdr (ref.cast (ref $pair) (local.get $rest)))
              (local.get $labels)))
            (return (struct.new $instr
              (i32.const 0) (local.get $target-reg) (i32.const 3) (local.get $src-arg)
              (local.get $src-val)))))
        ;; label source: resolve PC now, val = nil
        (if (i32.eq (local.get $src-type) (i32.const 2))
          (then
            (return (struct.new $instr
              (i32.const 0) (local.get $target-reg) (i32.const 2)
              (call $ecec-label-pc (local.get $src-val) (local.get $labels))
              (global.get $nil)))))
        ;; reg/const source
        (return (struct.new $instr
          (i32.const 0) (local.get $target-reg) (local.get $src-type) (local.get $src-arg)
          (local.get $src-val)))))

    ;; test (slot 1): (test (op name) operands...)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 1)))
      (then
        (call $ecec-parse-operand
          (call $car (ref.cast (ref $pair) (local.get $rest))))
        (local.set $src-arg (global.get $ecec-op-arg))
        (local.set $src-val (call $ecec-build-operand-list
          (call $cdr (ref.cast (ref $pair) (local.get $rest)))
          (local.get $labels)))
        (return (struct.new $instr
          (i32.const 1) (i32.const 0) (i32.const 0) (local.get $src-arg)
          (local.get $src-val)))))

    ;; branch (slot 2): resolve label PC now
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 2)))
      (then
        (call $ecec-parse-operand
          (call $car (ref.cast (ref $pair) (local.get $rest))))
        (return (struct.new $instr
          (i32.const 2) (i32.const 0) (i32.const 0)
          (call $ecec-label-pc (global.get $ecec-op-val) (local.get $labels))
          (global.get $nil)))))

    ;; goto (slot 3): (goto (label name)) or (goto (reg name))
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 3)))
      (then
        (call $ecec-parse-operand
          (call $car (ref.cast (ref $pair) (local.get $rest))))
        (if (i32.eq (global.get $ecec-op-type) (i32.const 1))
          (then
            (return (struct.new $instr
              (i32.const 3) (i32.const 0) (i32.const 1) (global.get $ecec-op-arg)
              (global.get $nil)))))
        ;; goto label: resolve PC now
        (return (struct.new $instr
          (i32.const 3) (i32.const 0) (i32.const 0)
          (call $ecec-label-pc (global.get $ecec-op-val) (local.get $labels))
          (global.get $nil)))))

    ;; save (slot 4): (save reg)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 4)))
      (then
        (return (struct.new $instr
          (i32.const 4)
          (call $ecec-reg-id (ref.cast (ref $symbol)
            (call $car (ref.cast (ref $pair) (local.get $rest)))))
          (i32.const 0) (i32.const 0) (global.get $nil)))))

    ;; restore (slot 5): (restore reg)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 5)))
      (then
        (return (struct.new $instr
          (i32.const 5)
          (call $ecec-reg-id (ref.cast (ref $symbol)
            (call $car (ref.cast (ref $pair) (local.get $rest)))))
          (i32.const 0) (i32.const 0) (global.get $nil)))))

    ;; perform (slot 6): (perform (op name) operands...)
    (if (i32.eq (local.get $tag-id)
          (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (i32.const 6)))
      (then
        (call $ecec-parse-operand
          (call $car (ref.cast (ref $pair) (local.get $rest))))
        (local.set $src-arg (global.get $ecec-op-arg))
        (local.set $src-val (call $ecec-build-operand-list
          (call $cdr (ref.cast (ref $pair) (local.get $rest)))
          (local.get $labels)))
        (return (struct.new $instr
          (i32.const 6) (i32.const 0) (i32.const 0) (local.get $src-arg)
          (local.get $src-val)))))

    ;; Unknown instruction type (e.g. procedure-name metadata) — skip
    (ref.null $instr))

  ;; Load a complete .ecec file from linear memory
  ;; Two-phase: (1) read all units + collect all labels, (2) create instructions with resolved labels.
  ;; Returns the space ID.
  (func (export "load_ecec") (param $offset i32) (param $len i32) (result i32)
    (local $header (ref null eq))
    (local $space-name (ref null eq))
    (local $macros (ref null eq))
    (local $space-id i32)
    (local $unit (ref null eq))
    (local $item (ref null eq))
    (local $instr (ref null $instr))
    (local $pc i32)
    (local $labels (ref null eq))   ;; alist of (symbol . pc) across ALL units
    (local $units (ref null eq))    ;; reversed list of unit s-expressions

    ;; Set up cursor
    (global.set $ecec-pos (local.get $offset))
    (global.set $ecec-end (i32.add (local.get $offset) (local.get $len)))

    ;; Read header: (ecec-header (space name) (macros (...)))
    (local.set $header (call $ecec-read-sexp))
    ;; Extract space name: (cadr (cadr header))
    (local.set $space-name
      (call $car (ref.cast (ref $pair)
        (call $cdr (ref.cast (ref $pair)
          (call $car (ref.cast (ref $pair)
            (call $cdr (ref.cast (ref $pair) (local.get $header))))))))))
    ;; Extract macros list: (cadr (caddr header))
    (local.set $macros
      (call $car (ref.cast (ref $pair)
        (call $cdr (ref.cast (ref $pair)
          (call $car (ref.cast (ref $pair)
            (call $cdr (ref.cast (ref $pair)
              (call $cdr (ref.cast (ref $pair) (local.get $header))))))))))))

    ;; Create compilation space (large enough for any bootstrap file)
    (local.set $space-id (call $create-space-internal
      (ref.cast (ref $symbol) (local.get $space-name)) (i32.const 65536)))

    ;; ── Phase 1: Read all units, collect all labels ──
    (local.set $labels (global.get $nil))
    (local.set $units (global.get $nil))
    (local.set $pc (i32.const 0))
    (block $eof (loop $read-units
      (local.set $unit (call $ecec-read-sexp))
      (br_if $eof (call $is-eof (local.get $unit)))
      ;; Save unit for phase 2
      (local.set $units (call $cons (local.get $unit) (local.get $units)))
      ;; Scan: collect labels, count instructions
      (local.set $item (local.get $unit))
      (block $end-scan (loop $scan
        (br_if $end-scan (ref.is_null (local.get $item)))
        (br_if $end-scan (call $is-null (local.get $item)))
        (br_if $end-scan (i32.eqz (call $is-pair (local.get $item))))
        (if (call $is-symbol (call $car (ref.cast (ref $pair) (local.get $item))))
          (then
            ;; Label: record (symbol . pc)
            (local.set $labels (call $cons
              (call $cons
                (call $car (ref.cast (ref $pair) (local.get $item)))
                (call $make-fixnum (local.get $pc)))
              (local.get $labels))))
          (else
            ;; List item: instruction or metadata (procedure-name etc.)
            ;; Only count if it's a recognized instruction (first element matches asm-sym-ids 0-6)
            (if (call $is-pair (call $car (ref.cast (ref $pair) (local.get $item))))
              (then
                (if (call $ecec-is-instr-keyword
                      (call $car (ref.cast (ref $pair)
                        (call $car (ref.cast (ref $pair) (local.get $item))))))
                  (then
                    (local.set $pc (i32.add (local.get $pc) (i32.const 1)))))))))
        (local.set $item (call $cdr (ref.cast (ref $pair) (local.get $item))))
        (br $scan)))
      ;; Count one extra instruction for the env-reset between units
      ;; (will be injected in Phase 2 between non-last units)
      (local.set $pc (i32.add (local.get $pc) (i32.const 1)))
      (br $read-units)))
    ;; Subtract 1 for the last unit (no env-reset after it)
    (local.set $pc (i32.sub (local.get $pc) (i32.const 1)))

    ;; ── Phase 2: Create instructions with all labels resolved ──
    (local.set $units (call $prim-reverse (local.get $units)))
    (local.set $pc (i32.const 0))
    (block $done-units (loop $build-units
      (br_if $done-units (call $is-null (local.get $units)))
      (br_if $done-units (i32.eqz (call $is-pair (local.get $units))))
      ;; Get current unit
      (local.set $item (call $car (ref.cast (ref $pair) (local.get $units))))
      ;; Walk items: skip labels, create instructions
      (block $end-build (loop $build
        (br_if $end-build (ref.is_null (local.get $item)))
        (br_if $end-build (call $is-null (local.get $item)))
        (br_if $end-build (i32.eqz (call $is-pair (local.get $item))))
        (if (i32.eqz (call $is-symbol (call $car (ref.cast (ref $pair) (local.get $item)))))
          (then
            ;; Instruction or metadata: parse (returns null for unknown types)
            (local.set $instr (call $ecec-parse-instr
              (call $car (ref.cast (ref $pair) (local.get $item)))
              (local.get $space-id) (local.get $pc) (local.get $labels)))
            (if (i32.eqz (ref.is_null (local.get $instr)))
              (then
                (call $space-set-instr (local.get $space-id) (local.get $pc)
                  (ref.as_non_null (local.get $instr)))
                (local.set $pc (i32.add (local.get $pc) (i32.const 1)))))))
        (local.set $item (call $cdr (ref.cast (ref $pair) (local.get $item))))
        (br $build)))
      ;; Between compilation units: inject (assign env (const <global-env>))
      ;; to prevent env register leaking from one top-level form to the next.
      (local.set $units (call $cdr (ref.cast (ref $pair) (local.get $units))))
      (if (i32.eqz (call $is-null (local.get $units)))
        (then
          (call $space-set-instr (local.get $space-id) (local.get $pc)
            (struct.new $instr
              (i32.const 0)   ;; opcode: assign
              (i32.const 1)   ;; a: env register
              (i32.const 0)   ;; b: from const
              (i32.const 0)   ;; c: unused
              (global.get $global-env)))  ;; val: the global env
          (local.set $pc (i32.add (local.get $pc) (i32.const 1)))))
      (br $build-units)))

    ;; Set final instruction count
    (struct.set $comp-space $len
      (call $get-space (local.get $space-id))
      (local.get $pc))

    ;; Register macros in the macro table
    (call $ecec-register-macros (local.get $macros) (local.get $space-id))

    (local.get $space-id))

  ;; Create a compilation space (internal, returns space-id = symbol-id)
  (func $create-space-internal (param $name-sym (ref $symbol)) (param $cap i32) (result i32)
    (local $space (ref $comp-space))
    (local.set $space (struct.new $comp-space
      (local.get $name-sym)
      (array.new_default $instr-vec (local.get $cap))
      (i32.const 0)
      (ref.null eq)))
    (call $register-space (local.get $space))
    (struct.get $symbol $id (local.get $name-sym)))

  ;; Store an instruction in a space at a given PC
  (func $space-set-instr (param $space-id i32) (param $pc i32) (param $instr (ref $instr))
    (array.set $instr-vec
      (struct.get $comp-space $instrs (call $get-space (local.get $space-id)))
      (local.get $pc)
      (local.get $instr)))


  ;; Look up a label symbol in the labels alist, return the PC
  (func $ecec-label-pc (param $sym (ref null eq)) (param $labels (ref null eq)) (result i32)
    (local $cur (ref null eq))
    (local $entry (ref $pair))
    (local.set $cur (local.get $labels))
    (block $done (loop $scan
      (br_if $done (call $is-null (local.get $cur)))
      (local.set $entry (ref.cast (ref $pair)
        (call $car (ref.cast (ref $pair) (local.get $cur)))))
      (if (ref.eq (struct.get $pair $car (local.get $entry)) (local.get $sym))
        (then (return (call $fixnum-value
          (ref.cast (ref i31) (struct.get $pair $cdr (local.get $entry)))))))
      (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
      (br $scan)))
    (i32.const 0))  ;; label not found — should not happen

  ;; Resolve label references in an operand list

  ;; Register macros from the header's macro list
  (func $ecec-register-macros (param $macros (ref null eq)) (param $space-id i32)
    ;; Macros are registered by the compiled code itself (set-macro! calls).
    ;; The header list is informational. No action needed here.
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 10: JS ↔ WASM Interop (Handle Table)
  ;; ═══════════════════════════════════════════════════════════════════
  ;; WasmGC refs can't cross the JS/WASM boundary directly.
  ;; We use a handle table: WASM stores (ref eq) values, JS gets i32 indices.
  ;; JS calls exported functions with i32 handles, WASM resolves them.

  ;; 1 page = 64KB linear memory for string transfer only
  (memory $transfer (export "memory") 1)

  ;; ── Runtime error helpers ──
  ;; Write a prefix string + symbol name to linear memory, then call runtime_error.
  (func $signal-error-sym (param $prefix (ref $string)) (param $sym (ref $symbol))
    (local $name (ref $string))
    (local $plen i32)
    (local $nlen i32)
    (local $i i32)
    (local $mem-offset i32)
    (local.set $name (struct.get $symbol $name (local.get $sym)))
    (local.set $plen (array.len (local.get $prefix)))
    (local.set $nlen (array.len (local.get $name)))
    ;; Write prefix
    (local.set $i (i32.const 0))
    (block $d1 (loop $c1
      (br_if $d1 (i32.ge_u (local.get $i) (local.get $plen)))
      (i32.store16 (i32.shl (local.get $i) (i32.const 1))
        (array.get_u $string (local.get $prefix) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $c1)))
    ;; Write symbol name after prefix
    (local.set $mem-offset (local.get $plen))
    (local.set $i (i32.const 0))
    (block $d2 (loop $c2
      (br_if $d2 (i32.ge_u (local.get $i) (local.get $nlen)))
      (i32.store16 (i32.shl (i32.add (local.get $mem-offset) (local.get $i)) (i32.const 1))
        (array.get_u $string (local.get $name) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $c2)))
    (call $js-runtime-error (i32.add (local.get $plen) (local.get $nlen))))

  ;; Handle table
  (type $handle-array (array (mut (ref null eq))))
  (global $handles (mut (ref null $handle-array))
    (array.new_default $handle-array (i32.const 8388608)))  ;; 8M handles (no recycling test)
  (global $handle-next (mut i32) (i32.const 1))  ;; 0 = nil handle

  ;; Watermark: handles below this are permanent (env, spaces, etc.)
  (global $handle-watermark (mut i32) (i32.const 1))

  (func $alloc-handle (param $val (ref null eq)) (result i32)
    (local $idx i32)
    (local.set $idx (global.get $handle-next))
    (array.set $handle-array (ref.as_non_null (global.get $handles))
      (local.get $idx) (local.get $val))
    (global.set $handle-next (i32.add (local.get $idx) (i32.const 1)))
    (local.get $idx)
  )

  ;; Mark current position as watermark (handles before this are permanent)
  (func (export "mark_handles") (global.set $handle-watermark (global.get $handle-next)))

  ;; Reset handles back to watermark (frees temporary handles)
  (func (export "reset_handles") (global.set $handle-next (global.get $handle-watermark)))

  (func $deref-handle (param $idx i32) (result (ref null eq))
    (if (result (ref null eq)) (i32.eqz (local.get $idx))
      (then (global.get $nil))
      (else (array.get $handle-array
              (ref.as_non_null (global.get $handles)) (local.get $idx))))
  )

  ;; ── Exported builder functions (JS calls these) ──

  ;; Intern a symbol from UTF-16 chars in linear memory
  (func (export "intern_sym") (param $offset i32) (param $len i32) (result i32)
    (local $str (ref $string))
    (local $i i32)
    (local.set $str (array.new_default $string (local.get $len)))
    (block $done
      (loop $copy
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (array.set $string (local.get $str) (local.get $i)
          (i32.load16_u
            (i32.add (local.get $offset)
              (i32.shl (local.get $i) (i32.const 1)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $copy)))
    (call $alloc-handle (call $intern (local.get $str)))
  )

  ;; Create a string from UTF-16 chars in linear memory
  (func (export "make_string") (param $offset i32) (param $len i32) (result i32)
    (local $str (ref $string))
    (local $i i32)
    (local.set $str (array.new_default $string (local.get $len)))
    (block $done
      (loop $copy
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (array.set $string (local.get $str) (local.get $i)
          (i32.load16_u
            (i32.add (local.get $offset)
              (i32.shl (local.get $i) (i32.const 1)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $copy)))
    (call $alloc-handle (local.get $str))
  )

  ;; Singleton handles
  (func (export "h_nil")   (result i32) (call $alloc-handle (global.get $nil)))
  (func (export "h_true")  (result i32) (call $alloc-handle (global.get $true)))
  (func (export "h_false") (result i32) (call $alloc-handle (global.get $false)))
  (func (export "h_eof")   (result i32) (call $alloc-handle (global.get $eof)))
  (func (export "h_void")  (result i32) (call $alloc-handle (global.get $void)))

  ;; Value constructors (return handles)
  (func (export "h_fixnum") (param $n i32) (result i32)
    (call $alloc-handle (call $make-fixnum (local.get $n))))

  (func (export "h_float") (param $n f64) (result i32)
    (call $alloc-handle (call $make-float (local.get $n))))

  (func (export "h_char") (param $cp i32) (result i32)
    (call $alloc-handle (call $make-char (local.get $cp))))

  (func (export "h_cons") (param $car i32) (param $cdr i32) (result i32)
    (call $alloc-handle
      (call $cons (call $deref-handle (local.get $car))
                  (call $deref-handle (local.get $cdr)))))

  (func (export "h_primitive") (param $id i32) (result i32)
    (call $alloc-handle (call $make-primitive (local.get $id))))

  ;; Create an instruction struct
  (func (export "make_instr") (param $opcode i32) (param $a i32)
        (param $b i32) (param $c i32) (param $val-handle i32) (result i32)
    (call $alloc-handle
      (struct.new $instr
        (local.get $opcode) (local.get $a) (local.get $b) (local.get $c)
        (call $deref-handle (local.get $val-handle)))))

  ;; Create a compilation space
  (func (export "create_space") (param $name-handle i32) (param $capacity i32) (result i32)
    (local $space (ref $comp-space))
    (local.set $space
      (struct.new $comp-space
        (ref.cast (ref $symbol) (call $deref-handle (local.get $name-handle)))
        (array.new_default $instr-vec (local.get $capacity))
        (i32.const 0)
        (ref.null eq)))  ;; no labels for .ececb-loaded spaces
    (call $register-space (local.get $space))
    (call $alloc-handle (local.get $space))
  )

  ;; Set an instruction in a space
  (func (export "space_set_instr") (param $space-handle i32) (param $pc i32)
        (param $instr-handle i32)
    (local $space (ref $comp-space))
    (local.set $space (ref.cast (ref $comp-space) (call $deref-handle (local.get $space-handle))))
    (array.set $instr-vec
      (struct.get $comp-space $instrs (local.get $space))
      (local.get $pc)
      (ref.cast (ref $instr) (call $deref-handle (local.get $instr-handle))))
    ;; Update length if needed
    (if (i32.ge_u (i32.add (local.get $pc) (i32.const 1))
                   (struct.get $comp-space $len (local.get $space)))
      (then
        (struct.set $comp-space $len (local.get $space)
          (i32.add (local.get $pc) (i32.const 1)))))
  )

  ;; Write a value in Scheme readable form to display output
  ;; Returns: 0=null (error), 1=void (silent ok), 2=printed value
  (func (export "write_val") (param $handle i32) (result i32)
    (local $v (ref null eq))
    (local.set $v (call $deref-handle (local.get $handle)))
    (if (ref.is_null (local.get $v)) (then (return (i32.const 0))))
    (if (ref.eq (local.get $v) (global.get $void)) (then (return (i32.const 1))))
    (call $display-value (call $write-to-string-impl (local.get $v)))
    (i32.const 2))

  ;; Look up a variable in an environment (returns handle)
  (func (export "env_lookup") (param $env-handle i32) (param $name-handle i32) (result i32)
    (call $alloc-handle
      (call $lookup-variable-value
        (ref.cast (ref $symbol) (call $deref-handle (local.get $name-handle)))
        (call $deref-handle (local.get $env-handle)))))

  ;; Call a compiled procedure with an argument list (returns handle)
  (func (export "call_ece_proc") (param $proc-handle i32) (param $args-handle i32) (result i32)
    (global.set $execute-argl (call $deref-handle (local.get $args-handle)))
    (global.set $execute-proc (call $deref-handle (local.get $proc-handle)))
    (call $alloc-handle
      (call $execute
        (call $compiled-proc-space
          (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $proc-handle))))
        (call $compiled-proc-pc
          (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $proc-handle))))
        (call $compiled-proc-env
          (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $proc-handle)))))))

  ;; Resume a captured continuation with a value (returns handle)
  (func (export "call_continuation") (param $cont-handle i32) (param $val-handle i32) (result i32)
    (local $cont (ref $continuation))
    (local $conts (ref $pair))
    (local $space-id i32)
    (local $pc i32)
    (local $saved-winds (ref null eq))
    (local $current-winds (ref null eq))
    (local $do-winds-fn (ref null eq))
    (local.set $cont (ref.cast (ref $continuation)
      (call $deref-handle (local.get $cont-handle))))
    ;; Do winding transition if needed
    (local.set $saved-winds (struct.get $continuation $winds (local.get $cont)))
    (if (ref.is_null (local.get $saved-winds))
      (then (local.set $saved-winds (global.get $nil))))
    (local.set $current-winds
      (if (result (ref null eq)) (ref.is_null (global.get $winding-stack-sym))
        (then (global.get $nil))
        (else (call $lookup-variable-value
          (ref.as_non_null (global.get $winding-stack-sym))
          (global.get $global-env)))))
    (if (ref.is_null (local.get $current-winds))
      (then (local.set $current-winds (global.get $nil))))
    (if (i32.eqz (ref.eq (local.get $current-winds) (local.get $saved-winds)))
      (then
        (if (i32.eqz (i32.and (call $is-null (local.get $current-winds))
                               (call $is-null (local.get $saved-winds))))
          (then
            (local.set $do-winds-fn (call $lookup-variable-value
              (ref.as_non_null (global.get $do-winds-sym))
              (global.get $global-env)))
            (global.set $execute-argl
              (call $cons (local.get $current-winds)
                (call $cons (local.get $saved-winds) (global.get $nil))))
            (global.set $execute-proc (local.get $do-winds-fn))
            (drop (call $execute
              (call $compiled-proc-space (ref.cast (ref $compiled-proc) (local.get $do-winds-fn)))
              (call $compiled-proc-pc (ref.cast (ref $compiled-proc) (local.get $do-winds-fn)))
              (call $compiled-proc-env (ref.cast (ref $compiled-proc) (local.get $do-winds-fn)))))))))
    ;; conts = saved continue register = (space-id . pc)
    (local.set $conts (ref.cast (ref $pair)
      (struct.get $continuation $conts (local.get $cont))))
    (local.set $space-id
      (call $fixnum-value (ref.cast (ref i31) (call $car (local.get $conts)))))
    (local.set $pc
      (call $fixnum-value (ref.cast (ref i31) (call $cdr (local.get $conts)))))
    ;; Set up executor: val = resume value, stack = saved stack
    (global.set $execute-val (call $deref-handle (local.get $val-handle)))
    (global.set $execute-stack (struct.get $continuation $stack (local.get $cont)))
    (call $alloc-handle
      (call $execute (local.get $space-id) (local.get $pc) (global.get $global-env))))

  ;; Debug: inspect instruction at (space-id, pc)
  (func (export "dbg_instr") (param $space-id i32) (param $pc i32) (param $field i32) (result i32)
    (local $space (ref $comp-space))
    (local $instr (ref $instr))
    (local.set $space (call $get-space (local.get $space-id)))
    (local.set $instr (ref.as_non_null
      (array.get $instr-vec
        (struct.get $comp-space $instrs (local.get $space))
        (local.get $pc))))
    ;; field: 0=opcode, 1=a, 2=b, 3=c, 4=val-type
    (if (result i32) (i32.eqz (local.get $field))
      (then (struct.get $instr $opcode (local.get $instr)))
    (else (if (result i32) (i32.eq (local.get $field) (i32.const 1))
      (then (struct.get $instr $a (local.get $instr)))
    (else (if (result i32) (i32.eq (local.get $field) (i32.const 2))
      (then (struct.get $instr $b (local.get $instr)))
    (else (if (result i32) (i32.eq (local.get $field) (i32.const 3))
      (then (struct.get $instr $c (local.get $instr)))
    (else
      ;; field 4: allocate handle for val and return its type
      (call $alloc-handle (struct.get $instr $val (local.get $instr)))
    )))))))))

  ;; Debug: inspect compiled procedure fields
  (func (export "dbg_proc_space") (param $handle i32) (result i32)
    (call $compiled-proc-space
      (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $handle)))))
  (func (export "dbg_proc_pc") (param $handle i32) (result i32)
    (call $compiled-proc-pc
      (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $handle)))))
  (func (export "dbg_proc_env") (param $handle i32) (result i32)
    (call $alloc-handle
      (call $compiled-proc-env
        (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $handle))))))

  ;; Build the global environment with primitive bindings
  (func (export "build_global_env") (param $prim-count i32) (result i32)
    ;; Create a frame with prim-count slots, all initially nil
    (local $names (ref null eq))
    (local $vals (ref $val-array))
    (local $frame (ref $env-frame))
    (local.set $names (global.get $nil))
    (local.set $vals (array.new_default $val-array (local.get $prim-count)))
    (local.set $frame
      (struct.new $env-frame (local.get $names) (local.get $vals) (ref.null eq)))
    (call $alloc-handle (local.get $frame))
  )

  ;; Add a binding to the global env frame
  (func (export "env_define") (param $env-handle i32)
        (param $name-handle i32) (param $val-handle i32)
    (call $define-variable!
      (ref.cast (ref $symbol) (call $deref-handle (local.get $name-handle)))
      (call $deref-handle (local.get $val-handle))
      (call $deref-handle (local.get $env-handle)))
  )

  ;; ── Test validation exports ──

  ;; Check if a symbol resolves to a valid op-id via $ecec-op-id.
  ;; Returns the op-id (0-21) or -1 if unrecognized.
  (func (export "check_op_id") (param $sym-handle i32) (result i32)
    (call $ecec-op-id (ref.cast (ref $symbol)
      (call $deref-handle (local.get $sym-handle)))))

  ;; Test export: trigger runtime_error with "Unbound variable: <sym>"
  (func (export "test_runtime_error") (param $sym-handle i32)
    (call $signal-error-sym (global.get $err-unbound-var)
      (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle)))))

  ;; Validate all instructions in a space. Returns 0 on success,
  ;; or -(pc+1) of first invalid instruction (negative = error).
  (func (export "validate_space") (param $space-id i32) (result i32)
    (local $space (ref $comp-space))
    (local $instrs (ref $instr-vec))
    (local $len i32)
    (local $i i32)
    (local $instr (ref $instr))
    (local $op i32)
    (local $b i32)
    (local $c i32)
    (local.set $space (call $get-space (local.get $space-id)))
    (local.set $instrs (struct.get $comp-space $instrs (local.get $space)))
    (local.set $len (struct.get $comp-space $len (local.get $space)))
    (local.set $i (i32.const 0))
    (block $done (loop $scan
      (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
      (local.set $instr (ref.as_non_null
        (array.get $instr-vec (local.get $instrs) (local.get $i))))
      (local.set $op (struct.get $instr $opcode (local.get $instr)))
      (local.set $b (struct.get $instr $b (local.get $instr)))
      (local.set $c (struct.get $instr $c (local.get $instr)))
      ;; Check: opcode must be 0-6
      (if (i32.gt_u (local.get $op) (i32.const 6))
        (then (return (i32.sub (i32.const 0) (i32.add (local.get $i) (i32.const 1))))))
      ;; Check: for assign-op (op=0,b=3), test (op=1), perform (op=6): c (op-id) must be 0-23
      (if (i32.or (i32.and (i32.eqz (local.get $op)) (i32.eq (local.get $b) (i32.const 3)))
                  (i32.or (i32.eq (local.get $op) (i32.const 1))
                          (i32.eq (local.get $op) (i32.const 6))))
        (then
          (if (i32.or (i32.lt_s (local.get $c) (i32.const 0))
                      (i32.gt_s (local.get $c) (i32.const 23)))
            (then (return (i32.sub (i32.const 0) (i32.add (local.get $i) (i32.const 1))))))))
      ;; Check: for branch (op=2), goto-label (op=3,b=0), assign-label (op=0,b=2): c must be 0..len
      (if (i32.or (i32.eq (local.get $op) (i32.const 2))
                  (i32.or (i32.and (i32.eq (local.get $op) (i32.const 3))
                                   (i32.eqz (local.get $b)))
                          (i32.and (i32.eqz (local.get $op))
                                   (i32.eq (local.get $b) (i32.const 2)))))
        (then
          (if (i32.or (i32.lt_s (local.get $c) (i32.const 0))
                      (i32.ge_u (local.get $c) (local.get $len)))
            (then (return (i32.sub (i32.const 0) (i32.add (local.get $i) (i32.const 1))))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $scan)))
    (i32.const 0))

  ;; Winding stack mirror: synced with ECE *winding-stack* by dynamic-wind.
  ;; Used by capture-continuation to snapshot the winding state.
  (global $winding-stack (mut (ref null eq)) (ref.null eq))

  ;; Cached symbols for winding support (set during bootstrap)
  (global $do-winds-sym (mut (ref null $symbol)) (ref.null $symbol))
  (global $winding-stack-sym (mut (ref null $symbol)) (ref.null $symbol))

  ;; Write mode flag: 0=display (no string quoting), 1=write (quote strings)
  (global $write-mode (mut i32) (i32.const 0))

  ;; Yield flag and stored continuation for cooperative multitasking
  ;; Save/restore trace flag (0=disabled, 1=enabled)
  (global $trace-sr (mut i32) (i32.const 0))
  (func (export "enable_trace_sr") (global.set $trace-sr (i32.const 1)))
  (func (export "disable_trace_sr") (global.set $trace-sr (i32.const 0)))

  ;; Count stack depth (number of pairs in the cons-list stack)
  (func $stack-depth (param $s (ref null eq)) (result i32)
    (local $d i32)
    (block $done (loop $count
      (br_if $done (call $is-null (local.get $s)))
      (br_if $done (ref.is_null (local.get $s)))
      (br_if $done (i32.eqz (call $is-pair (local.get $s))))
      (local.set $s (call $cdr (ref.cast (ref $pair) (local.get $s))))
      (local.set $d (i32.add (local.get $d) (i32.const 1)))
      (br $count)))
    (local.get $d))

  ;; Type ID for trace (matches dbg_type encoding)
  (func $type-id (param $v (ref null eq)) (result i32)
    (if (ref.is_null (local.get $v)) (then (return (i32.const 0))))
    (if (call $is-fixnum (local.get $v)) (then (return (i32.const 1))))
    (if (call $is-pair (local.get $v)) (then (return (i32.const 2))))
    (if (call $is-symbol (local.get $v)) (then (return (i32.const 3))))
    (if (call $is-string (local.get $v)) (then (return (i32.const 4))))
    (if (call $is-compiled-proc (local.get $v)) (then (return (i32.const 6))))
    (if (call $is-continuation (local.get $v)) (then (return (i32.const 7))))
    (if (call $is-primitive (local.get $v)) (then (return (i32.const 8))))
    (if (ref.test (ref i31) (local.get $v)) (then (return (i32.const 10))))
    (i32.const 99))

  (global $yield-flag (mut i32) (i32.const 0))
  (global $yield-continuation (mut (ref null eq)) (ref.null eq))
  (func (export "get_yield_flag") (result i32) (global.get $yield-flag))

  (func (export "set_yield_flag") (param $v i32) (global.set $yield-flag (local.get $v)))
  (func (export "get_yield_cont") (result i32)
    (call $alloc-handle (global.get $yield-continuation)))
  (func (export "clear_yield_cont")
    (global.set $yield-continuation (ref.null eq)))


  ;; Debug: last executed PC and space (for crash diagnosis)
  (global $dbg-pc (mut i32) (i32.const -1))
  (global $dbg-space (mut i32) (i32.const -1))
  (global $dbg-opcode (mut i32) (i32.const -1))
  (func (export "dbg_pc") (result i32) (global.get $dbg-pc))
  (func (export "dbg_space") (result i32) (global.get $dbg-space))
  (func (export "dbg_opcode") (result i32) (global.get $dbg-opcode))

  ;; Debug: check type of value at handle
  ;; Returns: 0=null, 1=fixnum, 2=pair, 3=symbol, 4=string, 5=float, 6=compiled-proc,
  ;;          7=continuation, 8=primitive, 9=parameter, 10=other-i31, 11=env-frame,
  ;;          12=js-ref, 99=unknown
  (func (export "dbg_type") (param $handle i32) (result i32)
    (local $v (ref null eq))
    (local.set $v (call $deref-handle (local.get $handle)))
    (if (ref.is_null (local.get $v)) (then (return (i32.const 0))))
    (if (call $is-fixnum (local.get $v)) (then (return (i32.const 1))))
    (if (call $is-pair (local.get $v)) (then (return (i32.const 2))))
    (if (call $is-symbol (local.get $v)) (then (return (i32.const 3))))
    (if (call $is-string (local.get $v)) (then (return (i32.const 4))))
    (if (ref.test (ref $float-box) (local.get $v)) (then (return (i32.const 5))))
    (if (call $is-compiled-proc (local.get $v)) (then (return (i32.const 6))))
    (if (call $is-continuation (local.get $v)) (then (return (i32.const 7))))
    (if (call $is-primitive (local.get $v)) (then (return (i32.const 8))))
    (if (call $is-parameter (local.get $v)) (then (return (i32.const 9))))
    (if (ref.test (ref $env-frame) (local.get $v)) (then (return (i32.const 11))))
    (if (call $is-js-ref (local.get $v)) (then (return (i32.const 12))))
    (if (ref.test (ref i31) (local.get $v)) (then (return (i32.const 10))))
    (i32.const 99)
  )

  ;; Get a symbol's numeric ID from its handle
  (func (export "sym_id") (param $handle i32) (result i32)
    (struct.get $symbol $id
      (ref.cast (ref $symbol) (call $deref-handle (local.get $handle)))))

  ;; Check if a handle points to a fixnum, return its value
  (func (export "h_fixnum_val") (param $handle i32) (result i32)
    (local $v (ref null eq))
    (local.set $v (call $deref-handle (local.get $handle)))
    (if (result i32) (call $is-fixnum (local.get $v))
      (then (call $fixnum-value (ref.cast (ref i31) (local.get $v))))
      (else (i32.const -999999)))
  )

  ;; Create a vector from handles
  (func (export "h_vector") (param $len i32) (result i32)
    (call $alloc-handle (array.new_default $vector (local.get $len))))

  (func (export "h_vector_set") (param $vec-handle i32) (param $idx i32) (param $val-handle i32)
    (array.set $vector
      (ref.cast (ref $vector) (call $deref-handle (local.get $vec-handle)))
      (local.get $idx)
      (call $deref-handle (local.get $val-handle))))

  ;; ── FFI support exports (for JS-side arg marshalling) ──

  (func (export "js_ref_idx") (param $handle i32) (result i32)
    (call $js-ref-idx (ref.cast (ref $js-ref) (call $deref-handle (local.get $handle)))))

  (func (export "make_js_ref") (param $idx i32) (result i32)
    (call $alloc-handle (call $make-js-ref (local.get $idx))))

  (func (export "fixnum_val") (param $handle i32) (result i32)
    (call $fixnum-value (ref.cast (ref i31) (call $deref-handle (local.get $handle)))))

  (func (export "float_val") (param $handle i32) (result f64)
    (call $float-value (ref.cast (ref $float-box) (call $deref-handle (local.get $handle)))))

  (func (export "string_len") (param $handle i32) (result i32)
    (array.len (ref.cast (ref $string) (call $deref-handle (local.get $handle)))))

  (func (export "string_to_mem") (param $handle i32)
    (call $string-to-memory (ref.cast (ref $string) (call $deref-handle (local.get $handle)))))

  (func (export "pair_car") (param $handle i32) (result i32)
    (call $alloc-handle (call $car (ref.cast (ref $pair) (call $deref-handle (local.get $handle))))))

  (func (export "pair_cdr") (param $handle i32) (result i32)
    (call $alloc-handle (call $cdr (ref.cast (ref $pair) (call $deref-handle (local.get $handle))))))

  ;; Execute from a space + PC with a given environment
  (func (export "run") (param $space-id i32) (param $pc i32)
        (param $env-handle i32) (result i32)
    (call $alloc-handle
      (call $execute (local.get $space-id) (local.get $pc)
        (call $deref-handle (local.get $env-handle))))
  )

)
