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
  ;; Captured by call/cc: the stack and return address at capture time.
  (type $continuation (struct
    (field $stack (ref null eq))
    (field $conts (ref null eq))))

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

  ;; Intern table capacity (grows if needed)
  (global $sym-capacity (mut i32) (i32.const 1024))
  (global $sym-count    (mut i32) (i32.const 0))
  (global $sym-names    (mut (ref null $sym-name-array))
    (array.new_default $sym-name-array (i32.const 1024)))
  (global $sym-refs     (mut (ref null $sym-ref-array))
    (array.new_default $sym-ref-array (i32.const 1024)))

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
    ;; TODO: grow arrays if sym-count == sym-capacity
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
    (array.get $val-array
      (struct.get $env-frame $vals (local.get $frame))
      (local.get $offset))
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
    ;; Not found — return null (caller should signal error)
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
  ;; Creates a new vals array with one more slot, copies existing values,
  ;; prepends the name to the names list.
  (func $frame-append (param $frame (ref $env-frame))
                      (param $name (ref $symbol)) (param $value (ref null eq))
    (local $old-vals (ref $val-array))
    (local $new-vals (ref $val-array))
    (local $old-len i32)
    (local $i i32)
    (local.set $old-vals (struct.get $env-frame $vals (local.get $frame)))
    (local.set $old-len (array.len (local.get $old-vals)))
    (local.set $new-vals (array.new_default $val-array
      (i32.add (local.get $old-len) (i32.const 1))))
    ;; New value at index 0 (names list is prepended, so index 0 = newest)
    (array.set $val-array (local.get $new-vals) (i32.const 0) (local.get $value))
    ;; Copy existing values shifted right by 1
    (local.set $i (i32.const 0))
    (block $done
      (loop $copy
        (br_if $done (i32.ge_u (local.get $i) (local.get $old-len)))
        (array.set $val-array (local.get $new-vals)
          (i32.add (local.get $i) (i32.const 1))
          (array.get $val-array (local.get $old-vals) (local.get $i)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $copy)))
    ;; Update frame: new vals, prepend name to names list
    (struct.set $env-frame $vals (local.get $frame) (local.get $new-vals))
    (struct.set $env-frame $names (local.get $frame)
      (call $cons
        (local.get $name)
        (struct.get $env-frame $names (local.get $frame))))
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
    ;; Not found — TODO: signal error via JS import
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
    (field $instrs (ref $instr-vec))
    (field $len (mut i32))))     ;; used length (may be less than array length)

  ;; --- Space registry (array of spaces, indexed by symbol ID) ---
  (type $space-array (array (mut (ref null $comp-space))))
  (global $spaces (mut (ref null $space-array))
    (array.new_default $space-array (i32.const 4096)))  ;; room for many symbol IDs
  (global $space-count (mut i32) (i32.const 0))

  ;; --- Register a space ---
  (func $register-space (param $space (ref $comp-space))
    (local $sym-id i32)
    (local.set $sym-id (struct.get $symbol $id
      (struct.get $comp-space $name (local.get $space))))
    ;; TODO: grow array if needed
    (array.set $space-array
      (ref.as_non_null (global.get $spaces))
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
    (local.set $space (call $get-space (local.get $space-id)))
    (local.set $instrs (struct.get $comp-space $instrs (local.get $space)))
    (local.set $len (struct.get $comp-space $len (local.get $space)))

    ;; Main dispatch loop
    (block $loop-end
      (loop $loop-start
        ;; End of instruction vector → done
        (br_if $loop-end (i32.ge_u (local.get $pc) (local.get $len)))

        ;; Debug tracking
        (global.set $dbg-pc (local.get $pc))
        (global.set $dbg-space (local.get $space-id))
        ;; Tracing disabled for production runs
        ;; (call $js-trace-pc (local.get $pc)
        ;;   (call $alloc-handle (local.get $proc)))

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
                (local.get $stack)))))

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
          ))

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

    ;; Unknown op — return void
    (else (global.get $void)
    ))))))))))))))))))))))))))))))))))))))))))
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
    ;; Float — delegate to JS for now (TODO: implement in WAT)
    (global.get $void)
  )

  ;; --- string->number (simple integer parser) ---
  (func $prim-string-to-number (param $s (ref null eq)) (result (ref null eq))
    (local $str (ref $string))
    (local $len i32)
    (local $i i32)
    (local $neg i32)
    (local $acc i32)
    (local $ch i32)
    (local.set $str (ref.cast (ref $string) (local.get $s)))
    (local.set $len (array.len (local.get $str)))
    (if (i32.eqz (local.get $len)) (then (return (global.get $false))))
    (local.set $i (i32.const 0))
    ;; Check for leading minus
    (if (i32.eq (array.get_u $string (local.get $str) (i32.const 0)) (i32.const 45))
      (then
        (local.set $neg (i32.const 1))
        (local.set $i (i32.const 1))))
    (local.set $acc (i32.const 0))
    (block $done
      (loop $parse
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (local.set $ch (array.get_u $string (local.get $str) (local.get $i)))
        ;; Check digit 0-9 or decimal point
        (if (i32.eq (local.get $ch) (i32.const 46))  ;; '.'
          (then
            ;; Switch to float parsing
            (return (call $parse-float-after-dot
              (local.get $str) (local.get $len)
              (local.get $i) (local.get $acc) (local.get $neg)))))
        (if (i32.or
              (i32.lt_u (local.get $ch) (i32.const 48))
              (i32.gt_u (local.get $ch) (i32.const 57)))
          (then (return (global.get $false)))) ;; not a number
        (local.set $acc (i32.add
          (i32.mul (local.get $acc) (i32.const 10))
          (i32.sub (local.get $ch) (i32.const 48))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $parse)))
    (if (local.get $neg)
      (then (local.set $acc (i32.sub (i32.const 0) (local.get $acc)))))
    (call $make-fixnum (local.get $acc))
  )

  ;; --- Float parser: continue after decimal point ---
  (func $parse-float-after-dot (param $str (ref $string)) (param $len i32)
                               (param $dot-pos i32) (param $int-part i32)
                               (param $neg i32)
                               (result (ref null eq))
    (local $i i32)
    (local $frac f64)
    (local $divisor f64)
    (local $ch i32)
    (local $result f64)
    (local.set $i (i32.add (local.get $dot-pos) (i32.const 1)))
    (local.set $frac (f64.const 0))
    (local.set $divisor (f64.const 1))
    (block $done
      (loop $parse
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (local.set $ch (array.get_u $string (local.get $str) (local.get $i)))
        (if (i32.or (i32.lt_u (local.get $ch) (i32.const 48))
                    (i32.gt_u (local.get $ch) (i32.const 57)))
          (then (return (global.get $false))))
        (local.set $divisor (f64.mul (local.get $divisor) (f64.const 10)))
        (local.set $frac (f64.add (local.get $frac)
          (f64.div (f64.convert_i32_u (i32.sub (local.get $ch) (i32.const 48)))
                   (local.get $divisor))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $parse)))
    (local.set $result (f64.add (f64.convert_i32_s (local.get $int-part)) (local.get $frac)))
    (if (local.get $neg)
      (then (local.set $result (f64.neg (local.get $result)))))
    (call $make-float (local.get $result))
  )

  ;; --- write-to-string: convert any ECE value to its string representation ---
  ;; Uses display-value to write to linear memory, then copies to a string.
  ;; This is a simple approach: display to a buffer, capture as string.
  (func $write-to-string-impl (param $v (ref null eq)) (result (ref null eq))
    ;; Quick paths for common types (avoid display overhead)
    (if (call $is-fixnum (local.get $v))
      (then (return (call $prim-number-to-string (local.get $v)))))
    (if (call $is-string (local.get $v))
      (then (return (local.get $v))))
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

  ;; --- String case conversion ---
  ;; mode: 0=upcase, 1=downcase
  (func $prim-string-case (param $s (ref null eq)) (param $mode i32) (result (ref null eq))
    (local $src (ref $string))
    (local $len i32)
    (local $result (ref $string))
    (local $i i32)
    (local $ch i32)
    (local.set $src (ref.cast (ref $string) (local.get $s)))
    (local.set $len (array.len (local.get $src)))
    (local.set $result (array.new_default $string (local.get $len)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $loop
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (local.set $ch (array.get_u $string (local.get $src) (local.get $i)))
        (if (local.get $mode)
          (then ;; downcase
            (if (i32.and (i32.ge_u (local.get $ch) (i32.const 65))
                         (i32.le_u (local.get $ch) (i32.const 90)))
              (then (local.set $ch (i32.add (local.get $ch) (i32.const 32))))))
          (else ;; upcase
            (if (i32.and (i32.ge_u (local.get $ch) (i32.const 97))
                         (i32.le_u (local.get $ch) (i32.const 122)))
              (then (local.set $ch (i32.sub (local.get $ch) (i32.const 32)))))))
        (array.set $string (local.get $result) (local.get $i) (local.get $ch))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (local.get $result)
  )

  ;; --- String split ---
  (func $prim-string-split (param $s (ref null eq)) (param $delim (ref null eq)) (result (ref null eq))
    (local $src (ref $string))
    (local $dsrc (ref $string))
    (local $slen i32) (local $dlen i32)
    (local $i i32) (local $start i32)
    (local $result (ref null eq))
    (local $match i32) (local $j i32)
    ;; Handle non-string delimiters (e.g., char)
    (if (call $is-char (local.get $delim))
      (then
        (local.set $delim (call $prim-char-to-string
          (call $char-codepoint (ref.cast (ref i31) (local.get $delim)))))))
    (local.set $src (ref.cast (ref $string) (local.get $s)))
    (local.set $dsrc (ref.cast (ref $string) (local.get $delim)))
    (local.set $slen (array.len (local.get $src)))
    (local.set $dlen (array.len (local.get $dsrc)))
    (local.set $result (global.get $nil))
    (local.set $start (i32.const 0))
    (local.set $i (i32.const 0))
    (block $done
      (loop $scan
        (br_if $done (i32.gt_u (i32.add (local.get $i) (local.get $dlen)) (local.get $slen)))
        ;; Check if delimiter matches at position i
        (local.set $match (i32.const 1))
        (local.set $j (i32.const 0))
        (block $no-match
          (loop $cmp
            (br_if $no-match (i32.ge_u (local.get $j) (local.get $dlen)))
            (if (i32.ne (array.get_u $string (local.get $src) (i32.add (local.get $i) (local.get $j)))
                        (array.get_u $string (local.get $dsrc) (local.get $j)))
              (then (local.set $match (i32.const 0)) (br $no-match)))
            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $cmp)))
        (if (local.get $match)
          (then
            ;; Add substring [start, i) to result
            (local.set $result (call $cons
              (call $prim-substring (local.get $s)
                (call $make-fixnum (local.get $start))
                (call $make-fixnum (local.get $i)))
              (local.get $result)))
            (local.set $start (i32.add (local.get $i) (local.get $dlen)))
            (local.set $i (local.get $start)))
          (else
            (local.set $i (i32.add (local.get $i) (i32.const 1)))))
        (br $scan)))
    ;; Add final segment
    (local.set $result (call $cons
      (call $prim-substring (local.get $s)
        (call $make-fixnum (local.get $start))
        (call $make-fixnum (local.get $slen)))
      (local.get $result)))
    ;; Reverse the result
    (call $prim-reverse (local.get $result))
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

  ;; --- String trim ---
  (func $prim-string-trim (param $s (ref null eq)) (result (ref null eq))
    (local $src (ref $string))
    (local $len i32) (local $start i32) (local $end i32) (local $ch i32)
    (local.set $src (ref.cast (ref $string) (local.get $s)))
    (local.set $len (array.len (local.get $src)))
    (local.set $start (i32.const 0))
    (local.set $end (local.get $len))
    ;; Skip leading whitespace
    (block $done1 (loop $l1
      (br_if $done1 (i32.ge_u (local.get $start) (local.get $end)))
      (local.set $ch (array.get_u $string (local.get $src) (local.get $start)))
      (br_if $done1 (i32.and (i32.ne (local.get $ch) (i32.const 32))
                              (i32.ne (local.get $ch) (i32.const 9))))
      (local.set $start (i32.add (local.get $start) (i32.const 1)))
      (br $l1)))
    ;; Skip trailing whitespace
    (block $done2 (loop $l2
      (br_if $done2 (i32.le_u (local.get $end) (local.get $start)))
      (local.set $ch (array.get_u $string (local.get $src) (i32.sub (local.get $end) (i32.const 1))))
      (br_if $done2 (i32.and (i32.ne (local.get $ch) (i32.const 32))
                              (i32.ne (local.get $ch) (i32.const 9))))
      (local.set $end (i32.sub (local.get $end) (i32.const 1)))
      (br $l2)))
    (call $prim-substring (local.get $s)
      (call $make-fixnum (local.get $start))
      (call $make-fixnum (local.get $end)))
  )

  ;; --- String contains? ---
  (func $prim-string-contains (param $s (ref null eq)) (param $sub (ref null eq)) (result (ref null eq))
    (local $src (ref $string)) (local $ssub (ref $string))
    (local $slen i32) (local $sublen i32) (local $i i32) (local $j i32) (local $match i32)
    (local.set $src (ref.cast (ref $string) (local.get $s)))
    (local.set $ssub (ref.cast (ref $string) (local.get $sub)))
    (local.set $slen (array.len (local.get $src)))
    (local.set $sublen (array.len (local.get $ssub)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $scan
        (br_if $done (i32.gt_u (i32.add (local.get $i) (local.get $sublen)) (local.get $slen)))
        (local.set $match (i32.const 1))
        (local.set $j (i32.const 0))
        (block $no (loop $cmp
          (br_if $no (i32.ge_u (local.get $j) (local.get $sublen)))
          (if (i32.ne (array.get_u $string (local.get $src) (i32.add (local.get $i) (local.get $j)))
                      (array.get_u $string (local.get $ssub) (local.get $j)))
            (then (local.set $match (i32.const 0)) (br $no)))
          (local.set $j (i32.add (local.get $j) (i32.const 1)))
          (br $cmp)))
        (if (local.get $match) (then (return (global.get $true))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
    (global.get $false)
  )

  ;; --- String join ---
  (func $prim-string-join (param $lst (ref null eq)) (param $sep (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $first i32)
    (local $parts (ref null eq))
    (local.set $cur (local.get $lst))
    (local.set $first (i32.const 1))
    (local.set $parts (global.get $nil))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (if (local.get $first)
          (then (local.set $first (i32.const 0)))
          (else (local.set $parts (call $cons (local.get $sep) (local.get $parts)))))
        (local.set $parts (call $cons
          (call $car (ref.cast (ref $pair) (local.get $cur)))
          (local.get $parts)))
        (local.set $cur (call $cdr (ref.cast (ref $pair) (local.get $cur))))
        (br $loop)))
    (call $prim-string-append (call $prim-reverse (local.get $parts)))
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

  ;; --- Gensym counter ---
  (global $gensym-counter (mut i32) (i32.const 0))

  (func $gensym-name (result (ref $string))
    ;; Generate "g<N>" as a string
    (local $n i32)
    (local $buf (ref $string))
    (local $i i32)
    (local $len i32)
    (local $digit i32)
    (local $result (ref $string))
    (local.set $n (global.get $gensym-counter))
    ;; Build digits reversed
    (local.set $buf (array.new_default $string (i32.const 12)))
    (local.set $i (i32.const 0))
    (if (i32.eqz (local.get $n))
      (then
        (array.set $string (local.get $buf) (i32.const 0) (i32.const 48))
        (local.set $i (i32.const 1)))
      (else
        (block $done
          (loop $digits
            (br_if $done (i32.eqz (local.get $n)))
            (array.set $string (local.get $buf) (local.get $i)
              (i32.add (i32.rem_u (local.get $n) (i32.const 10)) (i32.const 48)))
            (local.set $n (i32.div_u (local.get $n) (i32.const 10)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $digits)))))
    (local.set $len (i32.add (local.get $i) (i32.const 1)))
    (local.set $result (array.new_default $string (local.get $len)))
    (array.set $string (local.get $result) (i32.const 0) (i32.const 103))  ;; 'g'
    ;; Copy digits reversed
    (local.set $n (i32.const 0))
    (block $done2
      (loop $rev
        (br_if $done2 (i32.ge_u (local.get $n) (local.get $i)))
        (array.set $string (local.get $result)
          (i32.add (local.get $n) (i32.const 1))
          (array.get_u $string (local.get $buf)
            (i32.sub (i32.sub (local.get $i) (i32.const 1)) (local.get $n))))
        (local.set $n (i32.add (local.get $n) (i32.const 1)))
        (br $rev)))
    (local.get $result)
  )

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
    ;; 4 = modulo
    (if (i32.eq (local.get $id) (i32.const 4))
      (then (return (call $wrap-i32
        (i32.rem_s
          (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
          (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))))))
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
    ;; 19 = boolean?
    (if (i32.eq (local.get $id) (i32.const 19))
      (then (return (if (result (ref null eq)) (call $is-boolean (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 20 = eq?
    (if (i32.eq (local.get $id) (i32.const 20))
      (then (return (if (result (ref null eq))
        (call $eq (call $arg1 (local.get $args)) (call $arg2 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 21 = equal?
    (if (i32.eq (local.get $id) (i32.const 21))
      (then (return (call $prim-equal (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
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
    ;; 29 = string->number
    (if (i32.eq (local.get $id) (i32.const 29))
      (then (return (call $prim-string-to-number (call $arg1 (local.get $args))))))
    ;; 30 = number->string
    (if (i32.eq (local.get $id) (i32.const 30))
      (then (return (call $prim-number-to-string (call $arg1 (local.get $args))))))
    ;; 31 = string->symbol
    (if (i32.eq (local.get $id) (i32.const 31))
      (then (return (call $string-to-symbol
        (ref.cast (ref $string) (call $arg1 (local.get $args)))))))
    ;; 32 = symbol->string
    (if (i32.eq (local.get $id) (i32.const 32))
      (then (return (call $symbol-to-string
        (ref.cast (ref $symbol) (call $arg1 (local.get $args)))))))
    ;; 33 = string=?
    (if (i32.eq (local.get $id) (i32.const 33))
      (then (return (call $prim-string-eq
        (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
    ;; 34 = string<?
    (if (i32.eq (local.get $id) (i32.const 34))
      (then (return (call $prim-string-lt
        (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
    ;; 35 = string>?
    (if (i32.eq (local.get $id) (i32.const 35))
      (then (return (call $prim-string-gt
        (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
    ;; 36 = string-downcase
    (if (i32.eq (local.get $id) (i32.const 36))
      (then (return (call $prim-string-case (call $arg1 (local.get $args)) (i32.const 1)))))
    ;; 37 = string-upcase
    (if (i32.eq (local.get $id) (i32.const 37))
      (then (return (call $prim-string-case (call $arg1 (local.get $args)) (i32.const 0)))))
    ;; 38 = string-split (str [delim]) — default delim is " "
    (if (i32.eq (local.get $id) (i32.const 38))
      (then
        ;; Check if 2nd arg exists
        (if (result (ref null eq))
          (i32.and
            (i32.eqz (ref.is_null (call $cdr (ref.cast (ref $pair) (local.get $args)))))
            (i32.eqz (call $is-null (call $cdr (ref.cast (ref $pair) (local.get $args))))))
          (then (return (call $prim-string-split
            (call $arg1 (local.get $args)) (call $arg2 (local.get $args)))))
          (else (return (call $prim-string-split
            (call $arg1 (local.get $args))
            (call $make-1char-string (i32.const 32))))))))
    ;; 39 = string-trim
    (if (i32.eq (local.get $id) (i32.const 39))
      (then (return (call $prim-string-trim (call $arg1 (local.get $args))))))
    ;; 40 = string-contains?
    (if (i32.eq (local.get $id) (i32.const 40))
      (then (return (call $prim-string-contains
        (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
    ;; 41 = string-join
    (if (i32.eq (local.get $id) (i32.const 41))
      (then (return (call $prim-string-join
        (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
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
    ;; 58 = write (value [port])
    (if (i32.eq (local.get $id) (i32.const 58))
      (then
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

    ;; 66 = print (display + newline)
    (if (i32.eq (local.get $id) (i32.const 66))
      (then
        (call $display-value (call $arg1 (local.get $args)))
        (call $js-newline)
        (return (global.get $void))))
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
    ;; 82 = gensym
    (if (i32.eq (local.get $id) (i32.const 82))
      (then
        ;; Simple gensym: create a symbol with a unique name
        (global.set $gensym-counter (i32.add (global.get $gensym-counter) (i32.const 1)))
        (return (call $intern (call $gensym-name)))))
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
    ;; 55 = vector->list
    (if (i32.eq (local.get $id) (i32.const 55))
      (then (return (call $prim-vector-to-list (call $arg1 (local.get $args))))))
    ;; 56 = list->vector
    (if (i32.eq (local.get $id) (i32.const 56))
      (then (return (call $prim-list-to-vector (call $arg1 (local.get $args))))))
    ;; 43 = char->integer
    (if (i32.eq (local.get $id) (i32.const 43))
      (then (return (call $make-fixnum
        (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args))))))))
    ;; 44 = integer->char
    (if (i32.eq (local.get $id) (i32.const 44))
      (then (return (call $make-char
        (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))))))
    ;; 45 = char=?
    (if (i32.eq (local.get $id) (i32.const 45))
      (then (return (if (result (ref null eq))
        (i32.eq
          (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args))))
          (call $char-codepoint (ref.cast (ref i31) (call $arg2 (local.get $args)))))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 46 = char<?
    (if (i32.eq (local.get $id) (i32.const 46))
      (then (return (if (result (ref null eq))
        (i32.lt_u
          (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args))))
          (call $char-codepoint (ref.cast (ref i31) (call $arg2 (local.get $args)))))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 47 = char-whitespace?
    (if (i32.eq (local.get $id) (i32.const 47))
      (then
        (local.set $id (call $char-codepoint (ref.cast (ref i31) (call $arg1 (local.get $args)))))
        (return (if (result (ref null eq))
          (i32.or (i32.or (i32.eq (local.get $id) (i32.const 32))
                          (i32.eq (local.get $id) (i32.const 9)))
                  (i32.or (i32.eq (local.get $id) (i32.const 10))
                          (i32.eq (local.get $id) (i32.const 13))))
          (then (global.get $true)) (else (global.get $false))))))
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
    ;; 116 = %eq-hash-table (create empty)
    (if (i32.eq (local.get $id) (i32.const 116))
      (then
        (return (struct.new $hash-table
          (array.new_default $hash-keys (i32.const 16))
          (array.new_default $hash-vals (i32.const 16))
          (i32.const 0)))))
    ;; 117 = %eq-hash-ref (table key)
    (if (i32.eq (local.get $id) (i32.const 117))
      (then (return (call $hash-ref-impl
        (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))
        (call $arg2 (local.get $args))))))
    ;; 118 = %eq-hash-set! (table key value)
    (if (i32.eq (local.get $id) (i32.const 118))
      (then
        (call $hash-set-impl
          (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))
          (call $arg2 (local.get $args))
          (call $arg3 (local.get $args)))
        (return (global.get $void))))
    ;; 119 = %eq-hash-has-key? (table key)
    (if (i32.eq (local.get $id) (i32.const 119))
      (then (return (call $hash-has-key-impl
        (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))
        (call $arg2 (local.get $args))))))
    ;; 120 = %eq-hash-keys (table)
    (if (i32.eq (local.get $id) (i32.const 120))
      (then (return (call $hash-keys-impl
        (ref.cast (ref $hash-table) (call $arg1 (local.get $args)))))))
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

    ;; Unknown primitive — return void
    (global.get $void)
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 10: JS ↔ WASM Interop (Handle Table)
  ;; ═══════════════════════════════════════════════════════════════════
  ;; WasmGC refs can't cross the JS/WASM boundary directly.
  ;; We use a handle table: WASM stores (ref eq) values, JS gets i32 indices.
  ;; JS calls exported functions with i32 handles, WASM resolves them.

  ;; 1 page = 64KB linear memory for string transfer only
  (memory $transfer (export "memory") 1)

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
        (i32.const 0)))
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

  ;; Debug: last executed PC and space (for crash diagnosis)
  (global $dbg-pc (mut i32) (i32.const -1))
  (global $dbg-space (mut i32) (i32.const -1))
  (global $dbg-opcode (mut i32) (i32.const -1))
  (func (export "dbg_pc") (result i32) (global.get $dbg-pc))
  (func (export "dbg_space") (result i32) (global.get $dbg-space))
  (func (export "dbg_opcode") (result i32) (global.get $dbg-opcode))

  ;; Debug: check type of value at handle
  ;; Returns: 0=null, 1=fixnum, 2=pair, 3=symbol, 4=string, 5=float, 6=compiled-proc,
  ;;          7=continuation, 8=primitive, 9=parameter, 10=other-i31, 99=unknown
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

  ;; Execute from a space + PC with a given environment
  (func (export "run") (param $space-id i32) (param $pc i32)
        (param $env-handle i32) (result i32)
    (call $alloc-handle
      (call $execute (local.get $space-id) (local.get $pc)
        (call $deref-handle (local.get $env-handle))))
  )

)
