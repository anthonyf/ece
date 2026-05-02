;;; ECE WebAssembly Runtime
;;; =====================
;;; Hand-written WAT using WasmGC for the ECE register machine.
;;;
;;; Assembler: binaryen's wasm-as (--enable-gc)
;;; Build:     make wasm
;;;
;;; Architecture:
;;;   - 8 opcodes: assign, test, branch, goto, save, restore, perform, halt
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
  (import "ffi" "native_zone_call"
    (func $js-native-zone-call
      (param i32 i32 i32 i32 i32 i32 i32 i32 i32) (result i32)))

  ;; WASM native-zone host capabilities — side-module loading and exports
  (import "wasm_host" "fetch_text" (func $js-wasm-fetch-text (param i32 i32) (result i32)))
  (import "wasm_host" "fetch_bytes" (func $js-wasm-fetch-bytes (param i32 i32) (result i32)))
  (import "wasm_host" "instantiate" (func $js-wasm-instantiate (param i32 i32) (result i32)))
  (import "wasm_host" "wasm_export" (func $js-wasm-export (param i32 i32 i32) (result i32)))
  (import "wasm_host" "native_zone_imports" (func $js-wasm-native-zone-imports (result i32)))

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
    (field $env (ref null eq))
    ;; §6.6 coexistence: when non-null, this closure targets a code-object
    ;; (body at pc 0). $space and $pc are ignored in that case. §11 will
    ;; retire the old fields. Typed as (ref null eq) because $code-object
    ;; is defined later in the file — cast at use sites.
    (field $code-obj (mut (ref null eq)))))

  ;; --- Continuation ---
  ;; Captured by call/cc: the stack, return address, and winding stack at capture time.
  (type $continuation (struct
    (field $stack (ref null eq))
    (field $conts (ref null eq))
    (field $winds (ref null eq))))

  ;; --- Primitive ---
  ;; Just a numeric ID into the dispatch table (from primitives.def).
  (type $primitive (struct (field $id i32)))

  ;; --- Character ---
  ;; i32 codepoint + discriminator $tag field. The $tag field
  ;; distinguishes $char from $primitive (which is also a single-i32 struct),
  ;; preventing binaryen struct type deduplication. Only $codepoint is read;
  ;; $tag is always 0 and exists purely for type identity.
  ;; ASCII chars (0-127) are pre-interned in $ascii-chars, so hot-path char
  ;; creation is a single array load.
  (type $char (struct (field $codepoint i32) (field $tag i32)))

  ;; --- ASCII intern table ---
  ;; 128-element array of $char structs, populated at module init.
  (type $char-array (array (mut (ref $char))))

  ;; --- Special singletons ---
  ;; Each has its own empty struct type so $false, $true, $nil, $eof,
  ;; $void each have a unique type identity distinct from each other
  ;; and from every other heap value.
  (type $false-type (struct))
  (type $true-type  (struct))
  (type $nil-type   (struct))
  (type $eof-type   (struct))
  (type $void-type  (struct))

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

  ;; --- Error sentinel ---
  ;; Returned by $apply-primitive when a type error or division-by-zero is
  ;; detected. The execution loop checks for this and bridges to ECE's
  ;; error function, making the error catchable by guard/raise.
  (type $error-sentinel (struct
    (field $message (ref $string))
    (field $irritants (ref null eq))))

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
    (field $open (mut i32))                   ;; 1=open, 0=closed
    (field $line (mut i32))                   ;; current line number (1-based)
    (field $col  (mut i32))))                 ;; current column number (0-based)

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
  ;; Each is a heap-allocated singleton struct of its own type.
  ;;
  ;; Value representation scheme:
  ;;   i31ref                         →  fixnum (identity-encoded, full [-2^30, 2^30-1] range)
  ;;   (ref $char)                    →  character ($codepoint + $tag discriminator fields)
  ;;   (ref $false-type) $false       →  #f
  ;;   (ref $true-type)  $true        →  #t
  ;;   (ref $nil-type)   $nil         →  '()
  ;;   (ref $eof-type)   $eof         →  eof-object
  ;;   (ref $void-type)  $void        →  void
  ;;   (ref $primitive)               →  primitive procedure (numeric id field)
  ;;   (ref $pair) / $string / etc.   →  other heap values
  ;;
  ;; Chars in the ASCII range [0, 127] are pre-interned in $ascii-chars at
  ;; module init, so `(make-char 97)` twice returns the same heap reference.

  (global $false (ref eq) (struct.new $false-type))
  (global $true  (ref eq) (struct.new $true-type))
  (global $nil   (ref eq) (struct.new $nil-type))
  (global $eof   (ref eq) (struct.new $eof-type))
  (global $void  (ref eq) (struct.new $void-type))

  ;; ASCII intern table: populated at module init by $init-ascii-chars.
  (global $ascii-chars (mut (ref null $char-array)) (ref.null $char-array))

  ;; Error message strings (UTF-16 arrays)
  ;; "Unbound variable: " (18 chars)
  (global $err-unbound-var (ref $string)
    (array.new_fixed $string 18
      (i32.const 85)(i32.const 110)(i32.const 98)(i32.const 111)(i32.const 117)(i32.const 110)
      (i32.const 100)(i32.const 32)(i32.const 118)(i32.const 97)(i32.const 114)(i32.const 105)
      (i32.const 97)(i32.const 98)(i32.const 108)(i32.const 101)(i32.const 58)(i32.const 32)))

  ;; Cached symbol for looking up ECE's "error" function at runtime
  (global $error-sym (mut (ref null $symbol)) (ref.null $symbol))

  ;; Error message prefix strings for type-error sentinels
  ;; ": not a pair" (12 chars)
  (global $err-not-pair (ref $string)
    (array.new_fixed $string 12
      (i32.const 58)(i32.const 32)(i32.const 110)(i32.const 111)(i32.const 116)(i32.const 32)
      (i32.const 97)(i32.const 32)(i32.const 112)(i32.const 97)(i32.const 105)(i32.const 114)))
  ;; ": not a number" (14 chars)
  (global $err-not-number (ref $string)
    (array.new_fixed $string 14
      (i32.const 58)(i32.const 32)(i32.const 110)(i32.const 111)(i32.const 116)(i32.const 32)
      (i32.const 97)(i32.const 32)(i32.const 110)(i32.const 117)(i32.const 109)(i32.const 98)
      (i32.const 101)(i32.const 114)))
  ;; ": division by zero" (18 chars)
  (global $err-div-zero (ref $string)
    (array.new_fixed $string 18
      (i32.const 58)(i32.const 32)(i32.const 100)(i32.const 105)(i32.const 118)(i32.const 105)
      (i32.const 115)(i32.const 105)(i32.const 111)(i32.const 110)(i32.const 32)(i32.const 98)
      (i32.const 121)(i32.const 32)(i32.const 122)(i32.const 101)(i32.const 114)(i32.const 111)))
  ;; ": not a vector" (14 chars)
  (global $err-not-vector (ref $string)
    (array.new_fixed $string 14
      (i32.const 58)(i32.const 32)(i32.const 110)(i32.const 111)(i32.const 116)(i32.const 32)
      (i32.const 97)(i32.const 32)(i32.const 118)(i32.const 101)(i32.const 99)(i32.const 116)
      (i32.const 111)(i32.const 114)))
  ;; ": not a character" (17 chars)
  (global $err-not-char (ref $string)
    (array.new_fixed $string 17
      (i32.const 58)(i32.const 32)(i32.const 110)(i32.const 111)(i32.const 116)(i32.const 32)
      (i32.const 97)(i32.const 32)(i32.const 99)(i32.const 104)(i32.const 97)(i32.const 114)
      (i32.const 97)(i32.const 99)(i32.const 116)(i32.const 101)(i32.const 114)))
  ;; ": not a string" (14 chars)
  (global $err-not-string (ref $string)
    (array.new_fixed $string 14
      (i32.const 58)(i32.const 32)(i32.const 110)(i32.const 111)(i32.const 116)(i32.const 32)
      (i32.const 97)(i32.const 32)(i32.const 115)(i32.const 116)(i32.const 114)(i32.const 105)
      (i32.const 110)(i32.const 103)))
  ;; ": not a compiled procedure" (26 chars)
  (global $err-not-compiled-procedure (ref $string)
    (array.new_fixed $string 26
      (i32.const 58)(i32.const 32)(i32.const 110)(i32.const 111)(i32.const 116)(i32.const 32)
      (i32.const 97)(i32.const 32)(i32.const 99)(i32.const 111)(i32.const 109)(i32.const 112)
      (i32.const 105)(i32.const 108)(i32.const 101)(i32.const 100)(i32.const 32)(i32.const 112)
      (i32.const 114)(i32.const 111)(i32.const 99)(i32.const 101)(i32.const 100)(i32.const 117)
      (i32.const 114)(i32.const 101)))
  ;; "compiled-procedure-entry" (24 chars)
  (global $name-compiled-procedure-entry (ref $string)
    (array.new_fixed $string 24
      (i32.const 99)(i32.const 111)(i32.const 109)(i32.const 112)(i32.const 105)(i32.const 108)
      (i32.const 101)(i32.const 100)(i32.const 45)(i32.const 112)(i32.const 114)(i32.const 111)
      (i32.const 99)(i32.const 101)(i32.const 100)(i32.const 117)(i32.const 114)(i32.const 101)
      (i32.const 45)(i32.const 101)(i32.const 110)(i32.const 116)(i32.const 114)(i32.const 121)))

  ;; Archive loader error messages (used by $load-archive-impl and
  ;; $archive-patch-co-refs — actionable text surfaced to JS via runtime_error).
  ;; "Legacy .ecec format - run make bootstrap" (40 chars)
  (global $err-legacy-arch (ref $string)
    (array.new_fixed $string 40
      (i32.const 76)(i32.const 101)(i32.const 103)(i32.const 97)(i32.const 99)(i32.const 121)
      (i32.const 32)(i32.const 46)(i32.const 101)(i32.const 99)(i32.const 101)(i32.const 99)
      (i32.const 32)(i32.const 102)(i32.const 111)(i32.const 114)(i32.const 109)(i32.const 97)
      (i32.const 116)(i32.const 32)(i32.const 45)(i32.const 32)(i32.const 114)(i32.const 117)
      (i32.const 110)(i32.const 32)(i32.const 109)(i32.const 97)(i32.const 107)(i32.const 101)
      (i32.const 32)(i32.const 98)(i32.const 111)(i32.const 111)(i32.const 116)(i32.const 115)
      (i32.const 116)(i32.const 114)(i32.const 97)(i32.const 112)))
  ;; "Unknown .ecec archive head" (26 chars)
  (global $err-unknown-arch (ref $string)
    (array.new_fixed $string 26
      (i32.const 85)(i32.const 110)(i32.const 107)(i32.const 110)(i32.const 111)(i32.const 119)
      (i32.const 110)(i32.const 32)(i32.const 46)(i32.const 101)(i32.const 99)(i32.const 101)
      (i32.const 99)(i32.const 32)(i32.const 97)(i32.const 114)(i32.const 99)(i32.const 104)
      (i32.const 105)(i32.const 118)(i32.const 101)(i32.const 32)(i32.const 104)(i32.const 101)
      (i32.const 97)(i32.const 100)))
  ;; "Unsupported .ecec archive version - run make bootstrap" (54 chars)
  (global $err-bad-version (ref $string)
    (array.new_fixed $string 54
      (i32.const 85)(i32.const 110)(i32.const 115)(i32.const 117)(i32.const 112)(i32.const 112)
      (i32.const 111)(i32.const 114)(i32.const 116)(i32.const 101)(i32.const 100)(i32.const 32)
      (i32.const 46)(i32.const 101)(i32.const 99)(i32.const 101)(i32.const 99)(i32.const 32)
      (i32.const 97)(i32.const 114)(i32.const 99)(i32.const 104)(i32.const 105)(i32.const 118)
      (i32.const 101)(i32.const 32)(i32.const 118)(i32.const 101)(i32.const 114)(i32.const 115)
      (i32.const 105)(i32.const 111)(i32.const 110)(i32.const 32)(i32.const 45)(i32.const 32)
      (i32.const 114)(i32.const 117)(i32.const 110)(i32.const 32)(i32.const 109)(i32.const 97)
      (i32.const 107)(i32.const 101)(i32.const 32)(i32.const 98)(i32.const 111)(i32.const 111)
      (i32.const 116)(i32.const 115)(i32.const 116)(i32.const 114)(i32.const 97)(i32.const 112)))
  ;; "Archive co-ref out of range" (27 chars)
  (global $err-bad-coref (ref $string)
    (array.new_fixed $string 27
      (i32.const 65)(i32.const 114)(i32.const 99)(i32.const 104)(i32.const 105)(i32.const 118)
      (i32.const 101)(i32.const 32)(i32.const 99)(i32.const 111)(i32.const 45)(i32.const 114)
      (i32.const 101)(i32.const 102)(i32.const 32)(i32.const 111)(i32.const 117)(i32.const 116)
      (i32.const 32)(i32.const 111)(i32.const 102)(i32.const 32)(i32.const 114)(i32.const 97)
      (i32.const 110)(i32.const 103)(i32.const 101)))
  ;; "Archive has no entries - run make bootstrap" (43 chars)
  ;; Raised when an archive's entries plist is missing, empty, or improper.
  (global $err-empty-entries (ref $string)
    (array.new_fixed $string 43
      (i32.const 65)(i32.const 114)(i32.const 99)(i32.const 104)(i32.const 105)(i32.const 118)
      (i32.const 101)(i32.const 32)(i32.const 104)(i32.const 97)(i32.const 115)(i32.const 32)
      (i32.const 110)(i32.const 111)(i32.const 32)(i32.const 101)(i32.const 110)(i32.const 116)
      (i32.const 114)(i32.const 105)(i32.const 101)(i32.const 115)(i32.const 32)(i32.const 45)
      (i32.const 32)(i32.const 114)(i32.const 117)(i32.const 110)(i32.const 32)(i32.const 109)
      (i32.const 97)(i32.const 107)(i32.const 101)(i32.const 32)(i32.const 98)(i32.const 111)
      (i32.const 111)(i32.const 116)(i32.const 115)(i32.const 116)(i32.const 114)(i32.const 97)
      (i32.const 112)))

  ;; Native-zone dispatch errors. Native-zone result mode vector slots are:
  ;; 0 mode, 1 pc, 2 val, 3 env, 4 proc, 5 argl, 6 continue, 7 stack.
  ;; Modes: 0=return, 1=continue with updated registers, 2=bail to interpreter.
  ;; "native-zone export-ref must be a js-ref" (39 chars)
  (global $err-native-not-js-ref (ref $string)
    (array.new_fixed $string 39
      (i32.const 110)(i32.const 97)(i32.const 116)(i32.const 105)(i32.const 118)
      (i32.const 101)(i32.const 45)(i32.const 122)(i32.const 111)(i32.const 110)
      (i32.const 101)(i32.const 32)(i32.const 101)(i32.const 120)(i32.const 112)
      (i32.const 111)(i32.const 114)(i32.const 116)(i32.const 45)(i32.const 114)
      (i32.const 101)(i32.const 102)(i32.const 32)(i32.const 109)(i32.const 117)
      (i32.const 115)(i32.const 116)(i32.const 32)(i32.const 98)(i32.const 101)
      (i32.const 32)(i32.const 97)(i32.const 32)(i32.const 106)(i32.const 115)
      (i32.const 45)(i32.const 114)(i32.const 101)(i32.const 102)))
  ;; "native-zone result must be a vector" (35 chars)
  (global $err-native-result-vector (ref $string)
    (array.new_fixed $string 35
      (i32.const 110)(i32.const 97)(i32.const 116)(i32.const 105)(i32.const 118)
      (i32.const 101)(i32.const 45)(i32.const 122)(i32.const 111)(i32.const 110)
      (i32.const 101)(i32.const 32)(i32.const 114)(i32.const 101)(i32.const 115)
      (i32.const 117)(i32.const 108)(i32.const 116)(i32.const 32)(i32.const 109)
      (i32.const 117)(i32.const 115)(i32.const 116)(i32.const 32)(i32.const 98)
      (i32.const 101)(i32.const 32)(i32.const 97)(i32.const 32)(i32.const 118)
      (i32.const 101)(i32.const 99)(i32.const 116)(i32.const 111)(i32.const 114)))
  ;; "native-zone unknown result mode" (31 chars)
  (global $err-native-result-mode (ref $string)
    (array.new_fixed $string 31
      (i32.const 110)(i32.const 97)(i32.const 116)(i32.const 105)(i32.const 118)
      (i32.const 101)(i32.const 45)(i32.const 122)(i32.const 111)(i32.const 110)
      (i32.const 101)(i32.const 32)(i32.const 117)(i32.const 110)(i32.const 107)
      (i32.const 110)(i32.const 111)(i32.const 119)(i32.const 110)(i32.const 32)
      (i32.const 114)(i32.const 101)(i32.const 115)(i32.const 117)(i32.const 108)
      (i32.const 116)(i32.const 32)(i32.const 109)(i32.const 111)(i32.const 100)
      (i32.const 101)))

  ;; Type-tag strings for $write-to-string-impl's fallback. Each is
  ;; "#<TYPENAME>" in UTF-16, pre-interned as a $string constant.
  ;; When the fallback sees a value that isn't one of the well-known
  ;; primitives handled by the dispatch above (fixnum, float, string,
  ;; symbol, boolean, null, char, pair, vector, etc.), it does ref.test
  ;; against each tagged struct type — including singletons like eof and
  ;; void — and returns the matching tag. Unknown types fall through to
  ;; $type-tag-unknown so new struct types remain diagnosable.
  (global $type-tag-hash-table (ref $string)
    (array.new_fixed $string 13
      (i32.const 35) (i32.const 60) (i32.const 104) (i32.const 97) (i32.const 115) (i32.const 104) (i32.const 45) (i32.const 116) (i32.const 97) (i32.const 98) (i32.const 108) (i32.const 101) (i32.const 62)))
  (global $type-tag-code-object (ref $string)
    (array.new_fixed $string 14
      (i32.const 35) (i32.const 60) (i32.const 99) (i32.const 111) (i32.const 100) (i32.const 101) (i32.const 45) (i32.const 111) (i32.const 98) (i32.const 106) (i32.const 101) (i32.const 99) (i32.const 116) (i32.const 62)))
  (global $type-tag-compiled-proc (ref $string)
    (array.new_fixed $string 16
      (i32.const 35) (i32.const 60) (i32.const 99) (i32.const 111) (i32.const 109) (i32.const 112) (i32.const 105) (i32.const 108) (i32.const 101) (i32.const 100) (i32.const 45) (i32.const 112) (i32.const 114) (i32.const 111) (i32.const 99) (i32.const 62)))
  (global $type-tag-continuation (ref $string)
    (array.new_fixed $string 15
      (i32.const 35) (i32.const 60) (i32.const 99) (i32.const 111) (i32.const 110) (i32.const 116) (i32.const 105) (i32.const 110) (i32.const 117) (i32.const 97) (i32.const 116) (i32.const 105) (i32.const 111) (i32.const 110) (i32.const 62)))
  (global $type-tag-primitive (ref $string)
    (array.new_fixed $string 12
      (i32.const 35) (i32.const 60) (i32.const 112) (i32.const 114) (i32.const 105) (i32.const 109) (i32.const 105) (i32.const 116) (i32.const 105) (i32.const 118) (i32.const 101) (i32.const 62)))
  (global $type-tag-parameter (ref $string)
    (array.new_fixed $string 12
      (i32.const 35) (i32.const 60) (i32.const 112) (i32.const 97) (i32.const 114) (i32.const 97) (i32.const 109) (i32.const 101) (i32.const 116) (i32.const 101) (i32.const 114) (i32.const 62)))
  (global $type-tag-port (ref $string)
    (array.new_fixed $string 7
      (i32.const 35) (i32.const 60) (i32.const 112) (i32.const 111) (i32.const 114) (i32.const 116) (i32.const 62)))
  (global $type-tag-error-sentinel (ref $string)
    (array.new_fixed $string 17
      (i32.const 35) (i32.const 60) (i32.const 101) (i32.const 114) (i32.const 114) (i32.const 111) (i32.const 114) (i32.const 45) (i32.const 115) (i32.const 101) (i32.const 110) (i32.const 116) (i32.const 105) (i32.const 110) (i32.const 101) (i32.const 108) (i32.const 62)))
  (global $type-tag-js-ref (ref $string)
    (array.new_fixed $string 9
      (i32.const 35) (i32.const 60) (i32.const 106) (i32.const 115) (i32.const 45) (i32.const 114) (i32.const 101) (i32.const 102) (i32.const 62)))
  (global $type-tag-env-frame (ref $string)
    (array.new_fixed $string 12
      (i32.const 35) (i32.const 60) (i32.const 101) (i32.const 110) (i32.const 118) (i32.const 45) (i32.const 102) (i32.const 114) (i32.const 97) (i32.const 109) (i32.const 101) (i32.const 62)))
  (global $type-tag-eof (ref $string)
    (array.new_fixed $string 6
      (i32.const 35) (i32.const 60) (i32.const 101) (i32.const 111) (i32.const 102) (i32.const 62)))
  (global $type-tag-void (ref $string)
    (array.new_fixed $string 7
      (i32.const 35) (i32.const 60) (i32.const 118) (i32.const 111) (i32.const 105) (i32.const 100) (i32.const 62)))
  (global $type-tag-unknown (ref $string)
    (array.new_fixed $string 10
      (i32.const 35) (i32.const 60) (i32.const 117) (i32.const 110) (i32.const 107) (i32.const 110) (i32.const 111) (i32.const 119) (i32.const 110) (i32.const 62)))


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 3: Value Constructors and Accessors
  ;; ═══════════════════════════════════════════════════════════════════

  ;; --- Fixnum (i31ref, identity-encoded, full signed 31-bit range) ---

  (func $make-fixnum (param $n i32) (result (ref eq))
    (ref.i31 (local.get $n))
  )

  ;; Overflow-safe boxing for i32 outputs of bitwise primitives.
  ;; Fixnum range is the full signed i31: [-2^30, 2^30-1].
  ;; Values outside that range are boxed as an f64 float-box.
  (func $make-fixnum-or-float (param $n i32) (result (ref null eq))
    (if (i32.and (i32.ge_s (local.get $n) (i32.const -1073741824))
                 (i32.le_s (local.get $n) (i32.const 1073741823)))
      (then (return (call $make-fixnum (local.get $n)))))
    (struct.new $float-box (f64.convert_i32_s (local.get $n)))
  )

  (func $fixnum-value (param $v (ref i31)) (result i32)
    (i31.get_s (local.get $v))
  )

  (func $is-fixnum (param $v (ref null eq)) (result i32)
    (ref.test (ref i31) (local.get $v))
  )

  ;; --- Character ($char struct, ASCII-interned) ---

  (func $make-char (param $cp i32) (result (ref eq))
    (if (i32.lt_s (local.get $cp) (i32.const 128))
      (then
        (if (i32.ge_s (local.get $cp) (i32.const 0))
          (then (return (array.get $char-array
                          (ref.as_non_null (global.get $ascii-chars))
                          (local.get $cp)))))))
    (struct.new $char (local.get $cp) (i32.const 0))
  )

  (func $char-codepoint (param $v (ref $char)) (result i32)
    (struct.get $char $codepoint (local.get $v))
  )

  (func $is-char (param $v (ref null eq)) (result i32)
    (ref.test (ref $char) (local.get $v))
  )

  ;; Populate the 128-element ASCII intern table. Called from the $start function.
  (func $init-ascii-chars
    (local $arr (ref $char-array))
    (local $i i32)
    (local.set $arr (array.new $char-array
                      (struct.new $char (i32.const 0) (i32.const 0))
                      (i32.const 128)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $loop
        (br_if $done (i32.ge_s (local.get $i) (i32.const 128)))
        (array.set $char-array (local.get $arr) (local.get $i)
                   (struct.new $char (local.get $i) (i32.const 0)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (global.set $ascii-chars (local.get $arr))

    ;; Cache sym-ids used by the archive loader.
    ;; "const" (5 chars)
    (global.set $sym-id-const
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 5
          (i32.const 99) (i32.const 111) (i32.const 110) (i32.const 115)
          (i32.const 116)))))
    ;; "co-ref" (6 chars)
    (global.set $sym-id-co-ref
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 6
          (i32.const 99) (i32.const 111) (i32.const 45)
          (i32.const 114) (i32.const 101) (i32.const 102)))))
    ;; ":ecec-archive" (13 chars) — keyword-format archive head
    (global.set $sym-id-ecec-archive
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 13
          (i32.const 58)
          (i32.const 101) (i32.const 99) (i32.const 101) (i32.const 99)
          (i32.const 45) (i32.const 97) (i32.const 114) (i32.const 99)
          (i32.const 104) (i32.const 105) (i32.const 118) (i32.const 101)))))
    ;; "ecec-header" (11 chars) — legacy (pre-§9.3) header; kept only to
    ;; detect and report stale archives.
    (global.set $sym-id-ecec-header
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 11
          (i32.const 101) (i32.const 99) (i32.const 101) (i32.const 99)
          (i32.const 45) (i32.const 104) (i32.const 101) (i32.const 97)
          (i32.const 100) (i32.const 101) (i32.const 114)))))
    ;; ":version" (8 chars)
    (global.set $sym-id-version
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 8
          (i32.const 58)
          (i32.const 118) (i32.const 101) (i32.const 114) (i32.const 115)
          (i32.const 105) (i32.const 111) (i32.const 110)))))
    ;; ":entries" (8 chars)
    (global.set $sym-id-entries
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 8
          (i32.const 58)
          (i32.const 101) (i32.const 110) (i32.const 116) (i32.const 114)
          (i32.const 105) (i32.const 101) (i32.const 115)))))
    ;; ":name" (5 chars)
    (global.set $sym-id-arch-name
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 5
          (i32.const 58)
          (i32.const 110) (i32.const 97) (i32.const 109) (i32.const 101)))))
    ;; ":arity" (6 chars)
    (global.set $sym-id-arch-arity
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 6
          (i32.const 58)
          (i32.const 97) (i32.const 114) (i32.const 105) (i32.const 116)
          (i32.const 121)))))
    ;; ":source-loc" (11 chars)
    (global.set $sym-id-source-loc
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 11
          (i32.const 58)
          (i32.const 115) (i32.const 111) (i32.const 117) (i32.const 114)
          (i32.const 99) (i32.const 101) (i32.const 45) (i32.const 108)
          (i32.const 111) (i32.const 99)))))
    ;; ":labels" (7 chars)
    (global.set $sym-id-labels
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 7
          (i32.const 58)
          (i32.const 108) (i32.const 97) (i32.const 98) (i32.const 101)
          (i32.const 108) (i32.const 115)))))
    ;; ":instructions" (13 chars)
    (global.set $sym-id-instructions
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 13
          (i32.const 58)
          (i32.const 105) (i32.const 110) (i32.const 115) (i32.const 116)
          (i32.const 114) (i32.const 117) (i32.const 99) (i32.const 116)
          (i32.const 105) (i32.const 111) (i32.const 110) (i32.const 115)))))
    ;; ":file" (5 chars)
    (global.set $sym-id-file
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 5
          (i32.const 58)
          (i32.const 102) (i32.const 105) (i32.const 108) (i32.const 101)))))
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

  ;; Casting car/cdr: accept (ref null eq), cast to $pair internally
  (func $xcar (param $v (ref null eq)) (result (ref null eq))
    (struct.get $pair $car (ref.cast (ref $pair) (local.get $v))))

  (func $xcdr (param $v (ref null eq)) (result (ref null eq))
    (struct.get $pair $cdr (ref.cast (ref $pair) (local.get $v))))

  ;; Composed accessors
  (func $cadr (param $v (ref null eq)) (result (ref null eq))
    (call $xcar (call $xcdr (local.get $v))))

  (func $caddr (param $v (ref null eq)) (result (ref null eq))
    (call $xcar (call $xcdr (call $xcdr (local.get $v)))))

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
    (struct.new $compiled-proc (local.get $space) (local.get $pc) (local.get $env) (ref.null eq))
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
    (local $f f64)
    (if (call $is-fixnum (local.get $v))
      (then (return (i32.const 1))))
    (if (ref.test (ref $float-box) (local.get $v))
      (then
        (local.set $f (call $float-value
          (ref.cast (ref $float-box) (local.get $v))))
        ;; Finite AND equal to its own trunc — rejects NaN (NaN != anything)
        ;; and ±infinity (trunc(inf) == inf but inf is not finite).
        (return
          (i32.and
            (f64.lt (f64.abs (local.get $f)) (f64.const inf))
            (f64.eq (f64.trunc (local.get $f)) (local.get $f))))))
    (i32.const 0)
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

  ;; --- Error sentinel helpers ---
  ;; Build a type-error sentinel: "name: not a <type>" with the bad value as irritant.
  (func $make-type-error (param $name (ref $string)) (param $suffix (ref $string))
                         (param $bad-val (ref null eq)) (result (ref $error-sentinel))
    (struct.new $error-sentinel
      (call $string-concat (local.get $name) (local.get $suffix))
      (call $cons (local.get $bad-val) (global.get $nil))))

  ;; Concatenate two $string arrays into a new one
  (func $string-concat (param $a (ref $string)) (param $b (ref $string)) (result (ref $string))
    (local $len-a i32) (local $len-b i32) (local $result (ref $string)) (local $i i32)
    (local.set $len-a (array.len (local.get $a)))
    (local.set $len-b (array.len (local.get $b)))
    (local.set $result (array.new_default $string
      (i32.add (local.get $len-a) (local.get $len-b))))
    (local.set $i (i32.const 0))
    (block $d1 (loop $l1
      (br_if $d1 (i32.ge_u (local.get $i) (local.get $len-a)))
      (array.set $string (local.get $result) (local.get $i)
        (array.get_u $string (local.get $a) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l1)))
    (local.set $i (i32.const 0))
    (block $d2 (loop $l2
      (br_if $d2 (i32.ge_u (local.get $i) (local.get $len-b)))
      (array.set $string (local.get $result)
        (i32.add (local.get $len-a) (local.get $i))
        (array.get_u $string (local.get $b) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l2)))
    (local.get $result))

  ;; Check if all elements in a list are numbers
  (func $all-numbers (param $args (ref null eq)) (result i32)
    (local $cur (ref null eq))
    (local.set $cur (local.get $args))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (if (i32.eqz (call $is-number (call $xcar (local.get $cur))))
          (then (return (i32.const 0))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (i32.const 1))

  ;; Get the first non-number in a list (for error reporting)
  (func $first-non-number (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local.set $cur (local.get $args))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (if (i32.eqz (call $is-number (call $xcar (local.get $cur))))
          (then (return (call $xcar (local.get $cur)))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (global.get $nil))

  ;; Check if division args contain a zero divisor (skip first arg = dividend)
  (func $div-has-zero-divisor (param $args (ref null eq)) (result i32)
    (local $cur (ref null eq))
    ;; Skip the first argument (the dividend)
    (local.set $cur (call $xcdr (local.get $args)))
    ;; If only one arg: (/ x) = 1/x, check if x is 0
    (if (call $is-null (local.get $cur))
      (then
        (local.set $cur (local.get $args))))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (if (f64.eq (call $to-f64 (call $xcar (local.get $cur)))
                    (f64.const 0))
          (then (return (i32.const 1))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (i32.const 0))

  ;; Get primitive name string from ID (for error messages)
  (func $prim-name-str (param $id i32) (result (ref $string))
    (if (i32.eqz (local.get $id))
      (then (return (array.new_fixed $string 1 (i32.const 43)))))  ;; "+"
    (if (i32.eq (local.get $id) (i32.const 1))
      (then (return (array.new_fixed $string 1 (i32.const 45)))))  ;; "-"
    (if (i32.eq (local.get $id) (i32.const 2))
      (then (return (array.new_fixed $string 1 (i32.const 42)))))  ;; "*"
    (if (i32.eq (local.get $id) (i32.const 3))
      (then (return (array.new_fixed $string 1 (i32.const 47)))))  ;; "/"
    (if (i32.eq (local.get $id) (i32.const 5))
      (then (return (array.new_fixed $string 3
        (i32.const 99)(i32.const 97)(i32.const 114)))))  ;; "car"
    (if (i32.eq (local.get $id) (i32.const 6))
      (then (return (array.new_fixed $string 3
        (i32.const 99)(i32.const 100)(i32.const 114)))))  ;; "cdr"
    (if (i32.eq (local.get $id) (i32.const 9))
      (then (return (array.new_fixed $string 8
        (i32.const 115)(i32.const 101)(i32.const 116)(i32.const 45)
        (i32.const 99)(i32.const 97)(i32.const 114)(i32.const 33)))))  ;; "set-car!"
    (if (i32.eq (local.get $id) (i32.const 10))
      (then (return (array.new_fixed $string 8
        (i32.const 115)(i32.const 101)(i32.const 116)(i32.const 45)
        (i32.const 99)(i32.const 100)(i32.const 114)(i32.const 33)))))  ;; "set-cdr!"
    (if (i32.eq (local.get $id) (i32.const 22))
      (then (return (array.new_fixed $string 1 (i32.const 61)))))  ;; "="
    (if (i32.eq (local.get $id) (i32.const 23))
      (then (return (array.new_fixed $string 1 (i32.const 60)))))  ;; "<"
    (if (i32.eq (local.get $id) (i32.const 24))
      (then (return (array.new_fixed $string 1 (i32.const 62)))))  ;; ">"
    (if (i32.eq (local.get $id) (i32.const 43))
      (then (return (array.new_fixed $string 13
        (i32.const 99)(i32.const 104)(i32.const 97)(i32.const 114)(i32.const 45)
        (i32.const 62)(i32.const 105)(i32.const 110)(i32.const 116)(i32.const 101)
        (i32.const 103)(i32.const 101)(i32.const 114)))))  ;; "char->integer"
    (if (i32.eq (local.get $id) (i32.const 52))
      (then (return (array.new_fixed $string 10
        (i32.const 118)(i32.const 101)(i32.const 99)(i32.const 116)(i32.const 111)
        (i32.const 114)(i32.const 45)(i32.const 114)(i32.const 101)(i32.const 102)))))  ;; "vector-ref"
    (array.new_fixed $string 9
      (i32.const 112)(i32.const 114)(i32.const 105)(i32.const 109)(i32.const 105)
      (i32.const 116)(i32.const 105)(i32.const 118)(i32.const 101))  ;; "primitive"
  )

  ;; Convert f64 to ECE number: fixnum if integer in range, float-box otherwise.
  ;; The fixnum range is the full signed i31 range [-2^30, 2^30-1].
  ;; Values outside that range (or non-integers) are boxed as f64. The
  ;; f64 range check precedes the i32 trunc so SHA-1-style unsigned-valued
  ;; literals like 4023233417 don't trap.
  (func $f64-to-ece-number (param $v f64) (result (ref null eq))
    (if (f64.eq (f64.trunc (local.get $v)) (local.get $v))
      (then
        (if (i32.and (f64.ge (local.get $v) (f64.const -1073741824))
                     (f64.le (local.get $v) (f64.const 1073741823)))
          (then (return (call $make-fixnum (i32.trunc_f64_s (local.get $v))))))))
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
                      (local.get $name) (i32.const 0) (i32.const 1)
                      (i32.const 1) (i32.const 0))  ;; line=1, col=0
  )

  (func $make-output-port (param $name (ref null $string)) (result (ref $port))
    (struct.new $port
      (array.new_default $port-buf (i32.const 1024))
      (i32.const 0) (i32.const 1024)
      (local.get $name) (i32.const 1) (i32.const 1)
      (i32.const 1) (i32.const 0))  ;; line=1, col=0
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
  ;; Updates line/col tracking: newline increments line and resets col,
  ;; other characters increment col.
  (func $port-read-char (param $p (ref $port)) (result (ref null eq))
    (local $pos i32)
    (local $buf (ref $port-buf))
    (local $ch i32)
    (local.set $pos (struct.get $port $pos (local.get $p)))
    (if (ref.is_null (struct.get $port $buf (local.get $p)))
      (then (return (global.get $eof))))
    (local.set $buf (ref.as_non_null (struct.get $port $buf (local.get $p))))
    (if (i32.ge_u (local.get $pos) (array.len (local.get $buf)))
      (then (return (global.get $eof))))
    (local.set $ch (array.get_u $port-buf (local.get $buf) (local.get $pos)))
    (struct.set $port $pos (local.get $p) (i32.add (local.get $pos) (i32.const 1)))
    ;; Track line/col
    (if (i32.eq (local.get $ch) (i32.const 10))  ;; newline
      (then
        (struct.set $port $line (local.get $p)
          (i32.add (struct.get $port $line (local.get $p)) (i32.const 1)))
        (struct.set $port $col (local.get $p) (i32.const 0)))
      (else
        (struct.set $port $col (local.get $p)
          (i32.add (struct.get $port $col (local.get $p)) (i32.const 1)))))
    (call $make-char (local.get $ch))
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

  ;; Open output string: create an in-memory output port (no localStorage).
  (func $open-output-string-port (result (ref $port))
    (call $make-output-port (ref.null $string))
  )

  ;; Console ports: lazy-initialized singletons for the host's stdout/stdin.
  ;; Write primitives check ref.eq against these to route to JS console funcs.
  (global $console-out-port (mut (ref null $port)) (ref.null $port))
  (global $console-in-port  (mut (ref null $port)) (ref.null $port))

  (func $get-console-out-port (result (ref $port))
    (if (ref.is_null (global.get $console-out-port))
      (then (global.set $console-out-port (call $make-output-port (ref.null $string)))))
    (ref.as_non_null (global.get $console-out-port))
  )

  (func $get-console-in-port (result (ref $port))
    (if (ref.is_null (global.get $console-in-port))
      (then (global.set $console-in-port
        (call $make-input-port
          (array.new_default $port-buf (i32.const 0))
          (i32.const 0) (ref.null $string)))))
    (ref.as_non_null (global.get $console-in-port))
  )

  (func $is-console-out-port (param $p (ref $port)) (result i32)
    (if (result i32) (ref.is_null (global.get $console-out-port))
      (then (i32.const 0))
      (else (ref.eq (local.get $p) (global.get $console-out-port)))))

  ;; Get output string: extract accumulated buffer as an ECE $string.
  (func $get-output-string-port (param $p (ref $port)) (result (ref $string))
    (local $len i32) (local $buf (ref $port-buf)) (local $str (ref $string)) (local $i i32)
    (local.set $len (struct.get $port $pos (local.get $p)))
    (local.set $buf (ref.as_non_null (struct.get $port $buf (local.get $p))))
    (local.set $str (array.new_default $string (local.get $len)))
    (local.set $i (i32.const 0))
    (block $d (loop $l
      (br_if $d (i32.ge_u (local.get $i) (local.get $len)))
      (array.set $string (local.get $str) (local.get $i)
        (array.get_u $port-buf (local.get $buf) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
    (local.get $str)
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
            (local.set $cur-names (call $xcdr (local.get $cur-names)))
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
          (call $xcar (local.get $cur-vals)))
        (local.set $cur-vals (call $xcdr (local.get $cur-vals)))
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

  ;; --- try-lookup-variable-value ---
  ;; Walk the frame chain, searching by symbol name. Returns null on miss.
  ;; Use this for callers that treat "absent" as a normal case (platform-has?,
  ;; early-boot winding-stack/error-sym lookups, JS env_lookup export).
  ;; User-visible lookups should use $lookup-variable-value, which turns a
  ;; miss into an unbound-variable error sentinel.
  (func $try-lookup-variable-value (param $name (ref $symbol)) (param $env (ref null eq))
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
                (if (ref.test (ref $symbol) (call $xcar (local.get $cur)))
                  (then
                    (local.set $name-sym
                      (ref.cast (ref $symbol)
                        (call $xcar (local.get $cur))))
                    (if (i32.eq
                          (struct.get $symbol $id (local.get $name))
                          (struct.get $symbol $id (local.get $name-sym)))
                      (then
                        (return (array.get $val-array
                          (struct.get $env-frame $vals (local.get $frame))
                          (local.get $i)))))))))
            (if (ref.test (ref $pair) (local.get $cur))
              (then
                (local.set $cur (call $xcdr (local.get $cur))))
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

  ;; --- lookup-variable-value ---
  ;; Like $try-lookup-variable-value, but on miss returns a fresh
  ;; $error-sentinel ("Unbound variable: <name>") so the op-dispatch bridge
  ;; surfaces the error at the lookup site (catchable by guard). Callers
  ;; that need absent-as-null must use $try-lookup-variable-value instead.
  (func $lookup-variable-value (param $name (ref $symbol)) (param $env (ref null eq))
                               (result (ref eq))
    (local $result (ref null eq))
    (local.set $result
      (call $try-lookup-variable-value (local.get $name) (local.get $env)))
    (if (result (ref eq)) (ref.is_null (local.get $result))
      (then
        (struct.new $error-sentinel
          (call $string-concat
            (global.get $err-unbound-var)
            (call $symbol-to-string (local.get $name)))
          (global.get $nil)))
      (else (ref.as_non_null (local.get $result)))))

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
            (if (ref.test (ref $symbol) (call $xcar (local.get $cur)))
              (then
                (local.set $name-sym
                  (ref.cast (ref $symbol)
                    (call $xcar (local.get $cur))))
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
            (local.set $cur (call $xcdr (local.get $cur))))
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
            (local.set $cur (call $xcdr (local.get $cur)))
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
            (call $xcar (local.get $cur))
            (local.get $reversed)))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $rev)))
    ;; Step 2: fold reversed list onto (new-name) to get (old1 old2 ... new-name)
    (local.set $new-names (call $cons (local.get $name) (global.get $nil)))
    (block $build-done
      (loop $build
        (br_if $build-done
          (i32.or (ref.is_null (local.get $reversed)) (call $is-null (local.get $reversed))))
        (local.set $new-names
          (call $cons
            (call $xcar (local.get $reversed))
            (local.get $new-names)))
        (local.set $reversed (call $xcdr (local.get $reversed)))
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
                (if (ref.test (ref $symbol) (call $xcar (local.get $cur)))
                  (then
                    (local.set $name-sym
                      (ref.cast (ref $symbol)
                        (call $xcar (local.get $cur))))
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
                (local.set $cur (call $xcdr (local.get $cur))))
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

  ;; --- Instruction vector per code-object ---
  (type $instr-vec (array (mut (ref null $instr))))

  ;; --- Code object (per-procedure compilation unit) ---
  ;; Mirrors the CL `code-object` defstruct. Instruction storage uses the
  ;; already-resolved $instr struct (WASM instructions carry their op-id
  ;; directly), so source-instructions and resolved-instructions map to
  ;; the same $instrs field.
  (type $code-object (struct
    (field $instrs (mut (ref $instr-vec)))
    (field $len    (mut i32))
    (field $labels (mut (ref null eq)))     ;; hash-table or null
    (field $name       (mut (ref null eq))) ;; symbol or null
    (field $arity      (mut (ref null eq))) ;; fixnum or null
    (field $source-loc (mut (ref null eq))) ;; list or null
    (field $native-fn  (mut (ref null eq))) ;; procedure or null
    (field $archive-key (mut (ref null eq))))) ;; (cons stem index) when archive-registered, else null

  ;; Vector of code-objects, used by the archive loader for co-ref patching.
  (type $co-vec (array (mut (ref null eq))))

  ;; --- Archive loader: cached symbol IDs ---
  ;; Populated by $init-ascii-chars at module start. Used to cheaply compare
  ;; archive plist keys / archive-head / co-ref markers during $load-archive-impl.
  (global $sym-id-const        (mut i32) (i32.const 0))
  (global $sym-id-co-ref       (mut i32) (i32.const 0))
  (global $sym-id-ecec-archive (mut i32) (i32.const 0))
  (global $sym-id-ecec-header  (mut i32) (i32.const 0))
  (global $sym-id-version      (mut i32) (i32.const 0))
  (global $sym-id-entries      (mut i32) (i32.const 0))
  (global $sym-id-arch-name    (mut i32) (i32.const 0))
  (global $sym-id-arch-arity   (mut i32) (i32.const 0))
  (global $sym-id-source-loc   (mut i32) (i32.const 0))
  (global $sym-id-labels       (mut i32) (i32.const 0))
  (global $sym-id-instructions (mut i32) (i32.const 0))
  (global $sym-id-file         (mut i32) (i32.const 0))

  ;; Archive registry: outer $hash-table keyed by file-stem symbol ref
  ;; mapping to inner $hash-tables keyed by index-fixnum mapping to
  ;; $code-object refs. Null until first registration; lazy-initialized
  ;; by $archive-registry-put. Populated per-archive by
  ;; $load-archive-impl; read by primitive 260 (%archive-co-lookup).
  (global $archive-registry (mut (ref null eq)) (ref.null eq))

  ;; Native-zone registry: outer $hash-table keyed by normalized unit-key
  ;; symbol mapping to inner $hash-tables keyed by index-fixnum mapping to
  ;; opaque native-zone export refs. Populated by primitive 261; read by
  ;; primitive 262 and future executor dispatch.
  (global $native-zone-registry (mut (ref null eq)) (ref.null eq))

  ;; --- Compile-time macro table (symbol → transformer) ---
  (global $macro-table (mut (ref null eq)) (ref.null eq))

  ;; --- Global environment (set during bootstrap) ---
  (global $global-env (mut (ref null eq)) (ref.null eq))

  ;; --- Pending registers for apply-compiled-procedure / call_ece_proc ---
  (global $execute-argl (mut (ref null eq)) (ref.null eq))
  (global $execute-proc (mut (ref null eq)) (ref.null eq))
  (global $execute-val (mut (ref null eq)) (ref.null eq))
  (global $execute-stack (mut (ref null eq)) (ref.null eq))
  ;; Optional initial pc for $execute (used by call_continuation to resume
  ;; at a non-zero pc inside the saved code-object). -1 means "start at 0".
  (global $execute-init-pc (mut i32) (i32.const -1))

  ;; --- Pending code-object instructions (§6.6) ---
  ;; List of (code-obj pc . instr-list) entries. Flushed lazily by
  ;; $finalize-co-pending-instrs before a code-object is executed or
  ;; before its instruction vector is consulted. Forward-label
  ;; resolution uses the code-object's own $labels hash, so a deferred
  ;; flush guarantees all labels are set before any operand is resolved.
  (global $co-pending-instrs (mut (ref null eq)) (ref.null eq))

  ;; --- Assembler symbol ID table ---
  ;; Slots: 0-6 = instr types (assign,test,branch,goto,save,restore,perform)
  ;;        7-12 = register names (val,env,proc,argl,continue,stack)
  ;;        13-16 = source types (const,reg,label,op)
  ;;        17-43 = operation names from operations.def (op-id = slot - 17)
  ;;        44 = halt instruction
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

  (func (export "set_error_sym") (param $sym-handle i32)
    (global.set $error-sym
      (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle)))))

  (func (export "set_winding_stack_sym") (param $sym-handle i32)
    (global.set $winding-stack-sym
      (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle)))))

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

  ;; --- Resolve operation name symbol to op ID (0-26) ---
  (func $resolve-op-name (param $sym (ref $symbol)) (result i32)
    (local $id i32)
    (local $syms (ref $i32-array))
    (local $i i32)
    (local.set $id (struct.get $symbol $id (local.get $sym)))
    (local.set $syms (ref.as_non_null (global.get $asm-sym-ids)))
    ;; Linear scan slots 17-43 (ops 0-26, from operations.def)
    (local.set $i (i32.const 17))
    (block $done (loop $scan
      (br_if $done (i32.gt_u (local.get $i) (i32.const 43)))
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

  ;; §6.6: label lookup against a labels hash-table (from a code-object's
  ;; $labels field). Returns 0 if the hash is null or the label is absent.
  (func $labels-ht-ref (param $labels (ref null eq))
                       (param $label-sym (ref null eq)) (result i32)
    (local $ht (ref $hash-table))
    (local $val (ref null eq))
    (if (ref.is_null (local.get $labels))
      (then (return (i32.const 0))))
    (local.set $ht (ref.cast (ref $hash-table) (local.get $labels)))
    (local.set $val (call $hash-ref-impl (local.get $ht) (local.get $label-sym)))
    (if (result i32) (ref.is_null (local.get $val))
      (then (i32.const 0))
      (else (call $fixnum-value (ref.cast (ref i31) (local.get $val))))))

  ;; --- Build operand pair list from ECE operand list ---
  ;; Input: list of (const val), (reg name), (label name)
  ;; Output: list of (type . value) pairs for $eval-operand
  ;; §6.6: $labels-ht is a code-object's labels hash-table.
  (func $build-operand-list (param $ops (ref null eq))
                            (param $labels-ht (ref null eq))
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
        (call $xcar (local.get $cur))))
      (local.set $type-sym (ref.cast (ref $symbol) (call $car (local.get $op-pair))))
      (local.set $src-type (call $resolve-src-type (local.get $type-sym)))
      ;; const → (0 . value)
      (if (i32.eqz (local.get $src-type))
        (then
          (local.set $operand (call $cons
            (call $make-fixnum (i32.const 0))
            (call $cadr (local.get $op-pair))))))
      ;; reg → (1 . reg-id)
      (if (i32.eq (local.get $src-type) (i32.const 1))
        (then
          (local.set $operand (call $cons
            (call $make-fixnum (i32.const 1))
            (call $make-fixnum (call $resolve-reg-name
              (ref.cast (ref $symbol)
                (call $cadr (local.get $op-pair)))))))))
      ;; label → (2 . pc)
      (if (i32.eq (local.get $src-type) (i32.const 2))
        (then
          (local.set $operand (call $cons
            (call $make-fixnum (i32.const 2))
            (call $make-fixnum
              (call $labels-ht-ref
                (local.get $labels-ht)
                (call $cadr (local.get $op-pair))))))))
      ;; Prepend to result (reverse order for now)
      (local.set $result (call $cons (local.get $operand) (local.get $result)))
      (local.set $cur (call $xcdr (local.get $cur)))
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
        (call $xcar (local.get $cur))
        (local.get $result)))
      (local.set $cur (call $xcdr (local.get $cur)))
      (br $iter)))
    (local.get $result))

  ;; §6.6: flush pending code-object instructions. Each entry is
  ;; (code-obj pc . instr-list). Parses with the code-object's own
  ;; $labels hash so forward labels resolve correctly (all labels
  ;; are set by the time this is called).
  (func $finalize-co-pending-instrs
    (local $cur (ref null eq))
    (local $entry (ref $pair))
    (local $co (ref $code-object))
    (local $pc i32)
    (local $instr-list (ref null eq))
    (local $instrs (ref $instr-vec))
    (local $cap i32)
    (local $new-instrs (ref $instr-vec))
    (local $i i32)
    (local.set $cur (call $reverse-list (global.get $co-pending-instrs)))
    (global.set $co-pending-instrs (ref.null eq))
    (block $done (loop $iter
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      ;; Entry: (code-obj pc . instr-list)
      (local.set $entry (ref.cast (ref $pair)
        (call $xcar (local.get $cur))))
      (local.set $co (ref.cast (ref $code-object) (call $car (local.get $entry))))
      (local.set $entry (ref.cast (ref $pair) (call $cdr (local.get $entry))))
      (local.set $pc
        (call $fixnum-value (ref.cast (ref i31) (call $car (local.get $entry)))))
      (local.set $instr-list (call $cdr (local.get $entry)))
      ;; Grow $instrs vector if needed
      (local.set $instrs (struct.get $code-object $instrs (local.get $co)))
      (local.set $cap (array.len (local.get $instrs)))
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
          (struct.set $code-object $instrs (local.get $co) (local.get $new-instrs))
          (local.set $instrs (local.get $new-instrs))))
      ;; Parse source-instr using the code-object's $labels hash.
      (array.set $instr-vec (local.get $instrs) (local.get $pc)
        (call $ece-instr-to-wasm-instr (local.get $instr-list)
          (struct.get $code-object $labels (local.get $co))))
      (local.set $cur (call $xcdr (local.get $cur)))
      (br $iter))))

  ;; --- Convert ECE list instruction to $instr struct ---
  ;; Input: ECE list like (assign val (op lookup-variable-value) (const x) (reg env))
  ;; Output: $instr struct
  ;; §6.6: $labels-ht carries the label-resolution context. Callers that
  ;; that have a code-object pass `(struct.get $code-object $labels co)`.
  (func $ece-instr-to-wasm-instr (param $instr-list (ref null eq))
                                  (param $labels-ht (ref null eq))
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
      (call $xcar (local.get $instr-list))))
    (local.set $rest (call $xcdr (local.get $instr-list)))
    (local.set $syms (ref.as_non_null (global.get $asm-sym-ids)))
    ;; Determine type by comparing symbol ID
    (local.set $type-id (struct.get $symbol $id (local.get $type-sym)))

    ;; === ASSIGN (type slot 0) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 0)))
      (then
        ;; (assign <target-reg> <source>)
        (local.set $target (call $resolve-reg-name
          (ref.cast (ref $symbol) (call $xcar (local.get $rest)))))
        (local.set $rest (call $xcdr (local.get $rest)))
        ;; Source is a pair (type ...) — e.g. (const val), (reg name), (label name), (op name ...)
        (local.set $src-pair (ref.cast (ref $pair)
          (call $xcar (local.get $rest))))
        (local.set $src-type (call $resolve-src-type
          (ref.cast (ref $symbol) (call $car (local.get $src-pair)))))
        ;; const → b=0, val=value
        (if (i32.eqz (local.get $src-type))
          (then (return (struct.new $instr
            (i32.const 0) (local.get $target) (i32.const 0) (i32.const 0)
            (call $cadr (local.get $src-pair))))))
        ;; reg → b=1, c=reg-id
        (if (i32.eq (local.get $src-type) (i32.const 1))
          (then (return (struct.new $instr
            (i32.const 0) (local.get $target) (i32.const 1)
            (call $resolve-reg-name
              (ref.cast (ref $symbol) (call $cadr (local.get $src-pair))))
            (ref.null eq)))))
        ;; label → b=2, c=pc
        (if (i32.eq (local.get $src-type) (i32.const 2))
          (then
            (local.set $label-pc (call $labels-ht-ref
              (local.get $labels-ht)
              (call $cadr (local.get $src-pair))))
            (return (struct.new $instr
              (i32.const 0) (local.get $target) (i32.const 2)
              (local.get $label-pc) (ref.null eq)))))
        ;; op → b=3, c=op-id, val=operand list
        (local.set $op-id (call $resolve-op-name
          (ref.cast (ref $symbol) (call $cadr (local.get $src-pair)))))
        ;; Remaining operands after (op name) start at cddr of rest
        (local.set $operands (call $build-operand-list
          (call $xcdr (local.get $rest))
          (local.get $labels-ht)))
        (return (struct.new $instr
          (i32.const 0) (local.get $target) (i32.const 3)
          (local.get $op-id) (local.get $operands)))))

    ;; === TEST (type slot 1) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 1)))
      (then
        ;; (test (op <name>) <operands>...)
        (local.set $src-pair (ref.cast (ref $pair)
          (call $xcar (local.get $rest))))
        (local.set $op-id (call $resolve-op-name
          (ref.cast (ref $symbol) (call $cadr (local.get $src-pair)))))
        (local.set $operands (call $build-operand-list
          (call $xcdr (local.get $rest))
          (local.get $labels-ht)))
        (return (struct.new $instr
          (i32.const 1) (i32.const 0) (i32.const 0)
          (local.get $op-id) (local.get $operands)))))

    ;; === BRANCH (type slot 2) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 2)))
      (then
        ;; (branch (label <name>))
        (local.set $src-pair (ref.cast (ref $pair)
          (call $xcar (local.get $rest))))
        (local.set $label-pc (call $labels-ht-ref
          (local.get $labels-ht)
          (call $cadr (local.get $src-pair))))
        (return (struct.new $instr
          (i32.const 2) (i32.const 0) (i32.const 0)
          (local.get $label-pc) (ref.null eq)))))

    ;; === GOTO (type slot 3) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 3)))
      (then
        ;; (goto (label <name>)) or (goto (reg <name>))
        (local.set $src-pair (ref.cast (ref $pair)
          (call $xcar (local.get $rest))))
        (local.set $src-type (call $resolve-src-type
          (ref.cast (ref $symbol) (call $car (local.get $src-pair)))))
        ;; label → b=0, c=pc
        (if (i32.eq (local.get $src-type) (i32.const 2))
          (then
            (local.set $label-pc (call $labels-ht-ref
              (local.get $labels-ht)
              (call $cadr (local.get $src-pair))))
            (return (struct.new $instr
              (i32.const 3) (i32.const 0) (i32.const 0)
              (local.get $label-pc) (ref.null eq)))))
        ;; reg → b=1, c=reg-id
        (return (struct.new $instr
          (i32.const 3) (i32.const 0) (i32.const 1)
          (call $resolve-reg-name
            (ref.cast (ref $symbol) (call $cadr (local.get $src-pair))))
          (ref.null eq)))))

    ;; === SAVE (type slot 4) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 4)))
      (then
        ;; (save <reg>)
        (return (struct.new $instr
          (i32.const 4)
          (call $resolve-reg-name
            (ref.cast (ref $symbol) (call $xcar (local.get $rest))))
          (i32.const 0) (i32.const 0) (ref.null eq)))))

    ;; === RESTORE (type slot 5) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 5)))
      (then
        ;; (restore <reg>)
        (return (struct.new $instr
          (i32.const 5)
          (call $resolve-reg-name
            (ref.cast (ref $symbol) (call $xcar (local.get $rest))))
          (i32.const 0) (i32.const 0) (ref.null eq)))))

    ;; === PERFORM (type slot 6) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 6)))
      (then
        ;; (perform (op <name>) <operands>...)
        (local.set $src-pair (ref.cast (ref $pair)
          (call $xcar (local.get $rest))))
        (local.set $op-id (call $resolve-op-name
          (ref.cast (ref $symbol) (call $cadr (local.get $src-pair)))))
        (local.set $operands (call $build-operand-list
          (call $xcdr (local.get $rest))
          (local.get $labels-ht)))
        (return (struct.new $instr
          (i32.const 6) (i32.const 0) (i32.const 0)
          (local.get $op-id) (local.get $operands)))))

    ;; === HALT (type slot 44) ===
    (if (i32.eq (local.get $type-id) (array.get $i32-array (local.get $syms) (i32.const 44)))
      (then
        (return (struct.new $instr
          (i32.const 7) (i32.const 0) (i32.const 0) (i32.const 0) (ref.null eq)))))

    ;; Unknown — return no-op
    (struct.new $instr (i32.const 6) (i32.const 0) (i32.const 0) (i32.const 0) (ref.null eq))
  )

  ;; --- Machine operation IDs (from operations.def) ---
  ;; These are internal register machine operations, NOT ECE primitives.
  ;; The compiler emits (op-fn <name>); the .ececb loader maps names
  ;; to these numeric IDs. IDs match operations.def canonical assignment.
  ;;
  ;;  0 = lookup-variable-value     14 = apply-parameter
  ;;  1 = lookup-global-variable    15 = parameter-ref
  ;;  2 = set-variable-value!       16 = parameter-set!
  ;;  3 = define-variable!          17 = parameter-raw-set!
  ;;  4 = extend-environment        18 = capture-continuation
  ;;  5 = lexical-ref               19 = do-continuation-winds
  ;;  6 = lexical-set!              20 = continuation-stack
  ;;  7 = make-compiled-procedure   21 = continuation-conts
  ;;  8 = compiled-procedure-entry  22 = false?
  ;;  9 = compiled-procedure-env    23 = list
  ;; 10 = primitive-procedure?      24 = cons
  ;; 11 = continuation?             25 = car
  ;; 12 = parameter?                26 = cdr
  ;; 13 = apply-primitive-procedure

  ;; --- Evaluate a single operand ---
  ;; Operand is a pair: (type . value)
  ;;   type 0 = const (cdr is ECE value)
  ;;   type 1 = reg   (cdr is fixnum register ID)
  ;;   type 2 = label (cdr is fixnum PC)
  ;; $co is the current code-object (used to qualify label operands).
  (func $eval-operand (param $operand (ref null eq))
                      (param $val (ref null eq)) (param $env (ref null eq))
                      (param $proc (ref null eq)) (param $argl (ref null eq))
                      (param $cont (ref null eq)) (param $stack (ref null eq))
                      (param $co (ref null eq))
                      (result (ref null eq))
    (local $p (ref $pair))
    (local $type i32)
    (local $reg-id i32)
    (local.set $p (ref.cast (ref $pair) (local.get $operand)))
    (local.set $type
      (call $fixnum-value (ref.cast (ref i31) (call $car (local.get $p)))))
    ;; const
    (if (i32.eqz (local.get $type))
      (then (return (call $cdr (local.get $p)))))
    ;; reg
    (if (i32.eq (local.get $type) (i32.const 1))
      (then
        (local.set $reg-id
          (call $fixnum-value (ref.cast (ref i31) (call $cdr (local.get $p)))))
        (return (call $get-reg (local.get $reg-id)
          (local.get $val) (local.get $env) (local.get $proc)
          (local.get $argl) (local.get $cont) (local.get $stack)))))
    ;; label — return (code-obj . pc) qualified address pair
    (call $cons
      (local.get $co)
      (call $cdr (local.get $p)))
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
  ;; §6.6: $init-code-obj — when non-null, the executor starts inside a
  ;; code-object (reading $instrs/$labels/$len from it). $init-space-id
  ;; and $init-pc are ignored in that case. When null, the legacy space
  ;; path applies.
  (func $execute (export "execute")
                 (param $init-env (ref null eq))
                 (param $init-code-obj (ref null eq))
                 (result (ref null eq))
    (local $co (ref null eq))  ;; current code-object
    (local $pc i32)
    (local $val (ref null eq))
    (local $env (ref null eq))
    (local $proc (ref null eq))
    (local $argl (ref null eq))
    (local $cont (ref null eq))   ;; continue register
    (local $stack (ref null eq))
    (local $flag i32)
    (local $instrs (ref null $instr-vec))
    (local $len i32)
    (local $instr (ref $instr))
    (local $opcode i32)
    (local $target i32)
    (local $src-type i32)
    (local $op-result (ref null eq))
    (local $addr (ref null eq))
    (local $addr-pair (ref $pair))
    (local $native-entry-co (ref null eq))
    (local $native-key (ref null eq))
    (local $native-ref (ref null eq))
    (local $native-result (ref null eq))
    (local $native-vec (ref $vector))
    (local $native-mode i32)

    ;; Initialize
    (local.set $co (local.get $init-code-obj))
    (if (i32.ge_s (global.get $execute-init-pc) (i32.const 0))
      (then
        (local.set $pc (global.get $execute-init-pc))
        (global.set $execute-init-pc (i32.const -1)))
      (else (local.set $pc (i32.const 0))))
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
        ;; Set continue to a "return" sentinel. When the function does
        ;; (goto (reg continue)), pc will be >= len, causing $execute to
        ;; exit and return $val. Shape: (code-obj . len).
        (local.set $cont
          (call $cons
            (local.get $co)
            (call $make-fixnum (struct.get $code-object $len
              (ref.cast (ref $code-object) (local.get $co))))))))
    ;; Check for pending val/stack (set by call_continuation)
    (if (i32.eqz (ref.is_null (global.get $execute-val)))
      (then
        (local.set $val (global.get $execute-val))
        (global.set $execute-val (ref.null eq))))
    (if (i32.eqz (ref.is_null (global.get $execute-stack)))
      (then
        (local.set $stack (global.get $execute-stack))
        (global.set $execute-stack (ref.null eq))))
    ;; Init instrs/len from the code-object.
    (local.set $instrs (struct.get $code-object $instrs
      (ref.cast (ref $code-object) (local.get $co))))
    (local.set $len (struct.get $code-object $len
      (ref.cast (ref $code-object) (local.get $co))))

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

        ;; Native-zone entry hook. Only check at pc 0, and only once for a
        ;; given code-object entry. The native result vector protocol is:
        ;;   #(mode pc val env proc argl continue stack)
        ;;   mode 0 = return val, mode 1 = continue with updated registers,
        ;;   mode 2 = bail to the interpreter with updated registers.
        (if (i32.and
              (i32.eqz (local.get $pc))
              (i32.eqz (ref.eq (local.get $co) (local.get $native-entry-co))))
          (then
            (local.set $native-entry-co (local.get $co))
            (local.set $native-key
              (struct.get $code-object $archive-key
                (ref.cast (ref $code-object) (local.get $co))))
            (if (ref.test (ref $pair) (local.get $native-key))
              (then
                (local.set $addr-pair (ref.cast (ref $pair) (local.get $native-key)))
                (local.set $native-ref
                  (call $native-zone-registry-get
                    (call $car (local.get $addr-pair))
                    (call $cdr (local.get $addr-pair))))
                (if (i32.eqz (call $is-false (local.get $native-ref)))
                  (then
                    (if (i32.eqz (ref.test (ref $js-ref) (local.get $native-ref)))
                      (then (call $signal-error-str (global.get $err-native-not-js-ref))))
                    (local.set $native-result
                      (call $deref-handle
                        (call $js-native-zone-call
                          (call $js-ref-idx
                            (ref.cast (ref $js-ref) (local.get $native-ref)))
                          (local.get $pc)
                          (call $alloc-handle (local.get $val))
                          (call $alloc-handle (local.get $env))
                          (call $alloc-handle (local.get $proc))
                          (call $alloc-handle (local.get $argl))
                          (call $alloc-handle (local.get $cont))
                          (call $alloc-handle (local.get $stack))
                          (call $alloc-handle (local.get $co)))))
                    (if (i32.eqz (ref.test (ref $vector) (local.get $native-result)))
                      (then (call $signal-error-str (global.get $err-native-result-vector))))
                    (local.set $native-vec
                      (ref.cast (ref $vector) (local.get $native-result)))
                    (local.set $native-mode
                      (call $fixnum-value
                        (ref.cast (ref i31)
                          (array.get $vector (local.get $native-vec) (i32.const 0)))))
                    (if (i32.eqz (local.get $native-mode))
                      (then
                        (local.set $val
                          (array.get $vector (local.get $native-vec) (i32.const 2)))
                        (br $loop-end)))
                    (if (i32.eq (local.get $native-mode) (i32.const 1))
                      (then
                        (local.set $pc
                          (call $fixnum-value
                            (ref.cast (ref i31)
                              (array.get $vector (local.get $native-vec) (i32.const 1)))))
                        (local.set $val
                          (array.get $vector (local.get $native-vec) (i32.const 2)))
                        (local.set $env
                          (array.get $vector (local.get $native-vec) (i32.const 3)))
                        (local.set $proc
                          (array.get $vector (local.get $native-vec) (i32.const 4)))
                        (local.set $argl
                          (array.get $vector (local.get $native-vec) (i32.const 5)))
                        (local.set $cont
                          (array.get $vector (local.get $native-vec) (i32.const 6)))
                        (local.set $stack
                          (array.get $vector (local.get $native-vec) (i32.const 7)))
                        (br $loop-start)))
                    (if (i32.eq (local.get $native-mode) (i32.const 2))
                      (then
                        (local.set $pc
                          (call $fixnum-value
                            (ref.cast (ref i31)
                              (array.get $vector (local.get $native-vec) (i32.const 1)))))
                        (local.set $val
                          (array.get $vector (local.get $native-vec) (i32.const 2)))
                        (local.set $env
                          (array.get $vector (local.get $native-vec) (i32.const 3)))
                        (local.set $proc
                          (array.get $vector (local.get $native-vec) (i32.const 4)))
                        (local.set $argl
                          (array.get $vector (local.get $native-vec) (i32.const 5)))
                        (local.set $cont
                          (array.get $vector (local.get $native-vec) (i32.const 6)))
                        (local.set $stack
                          (array.get $vector (local.get $native-vec) (i32.const 7)))
                        (br $loop-start)))
                    (call $signal-error-str (global.get $err-native-result-mode))))))))

        ;; Debug tracking
        (global.set $dbg-pc (local.get $pc))
        ;; Debug trace. The second parameter was formerly a space-id for
        ;; the retired compilation-space model; with per-procedure code
        ;; objects there is no single integer identity for a code-object
        ;; that is both cheap to compute and meaningful to JS-side tooling.
        ;; All production imports (glue.js `trace_pc`, test.js `trace_pc`)
        ;; treat this parameter as opaque, so we pass 0 as a placeholder.
        ;; Follow-up: if a JS tracer is reintroduced, pipe a stable code-
        ;; object identity through here (a handle, or the symbol id of
        ;; the code-object's $name) — don't reuse the space-id meaning.
        (call $js-trace-pc (local.get $pc) (i32.const 0))

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
                ;; For continue register, store an identity-qualified address:
                ;; (code-obj . pc). §6.6.
                (if (i32.eq (local.get $target) (i32.const 4))
                  (then
                    (local.set $op-result
                      (call $cons
                        (local.get $co)
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
                    (local.get $co)))
                ;; Bridge error sentinel to ECE's error function
                (if (ref.test (ref $error-sentinel) (local.get $op-result))
                  (then
                    (global.set $error-pc (local.get $pc))
                    ;; Guard: error function must be available (not during early bootstrap)
                    (if (ref.is_null (global.get $error-sym))
                      (then (call $signal-error-str
                        (struct.get $error-sentinel $message
                          (ref.cast (ref $error-sentinel) (local.get $op-result))))))
                    (local.set $proc (call $try-lookup-variable-value
                      (ref.as_non_null (global.get $error-sym))
                      (global.get $global-env)))
                    (if (ref.is_null (local.get $proc))
                      (then (call $signal-error-str
                        (struct.get $error-sentinel $message
                          (ref.cast (ref $error-sentinel) (local.get $op-result))))))
                    (local.set $argl (call $cons
                      (struct.get $error-sentinel $message
                        (ref.cast (ref $error-sentinel) (local.get $op-result)))
                      (struct.get $error-sentinel $irritants
                        (ref.cast (ref $error-sentinel) (local.get $op-result)))))
                    ;; Jump to error handler's code-object (all error procs
                    ;; are now code-object-bound).
                    (local.set $co
                      (struct.get $compiled-proc $code-obj
                        (ref.cast (ref $compiled-proc) (local.get $proc))))
                    (local.set $instrs (struct.get $code-object $instrs
                      (ref.cast (ref $code-object) (local.get $co))))
                    (local.set $len (struct.get $code-object $len
                      (ref.cast (ref $code-object) (local.get $co))))
                    (local.set $pc (i32.const 0))
                    (br $loop-start)))))

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
                (local.get $co)))
            ;; Bridge error sentinel to ECE's error function
            (if (ref.test (ref $error-sentinel) (local.get $op-result))
              (then
                (global.set $error-pc (local.get $pc))
                (local.set $proc (call $try-lookup-variable-value
                  (ref.as_non_null (global.get $error-sym))
                  (global.get $global-env)))
                (local.set $argl (call $cons
                  (struct.get $error-sentinel $message
                    (ref.cast (ref $error-sentinel) (local.get $op-result)))
                  (struct.get $error-sentinel $irritants
                    (ref.cast (ref $error-sentinel) (local.get $op-result)))))
                (local.set $co
                  (struct.get $compiled-proc $code-obj
                    (ref.cast (ref $compiled-proc) (local.get $proc))))
                (local.set $instrs (struct.get $code-object $instrs
                  (ref.cast (ref $code-object) (local.get $co))))
                (local.set $len (struct.get $code-object $len
                  (ref.cast (ref $code-object) (local.get $co))))
                (local.set $pc (i32.const 0))
                (br $loop-start)))
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
            ;; §7.1: bare code-object → pc 0 of that code-object
            (if (ref.test (ref $code-object) (local.get $addr))
              (then
                (if (i32.eqz (ref.eq (local.get $addr) (local.get $co)))
                  (then
                    (local.set $co (local.get $addr))
                    (local.set $instrs (struct.get $code-object $instrs
                      (ref.cast (ref $code-object) (local.get $addr))))
                    (local.set $len (struct.get $code-object $len
                      (ref.cast (ref $code-object) (local.get $addr))))))
                (local.set $pc (i32.const 0))
                (br $loop-start)))
            ;; (code-obj . pc) pair
            (if (ref.test (ref $pair) (local.get $addr))
              (then
                (local.set $addr-pair (ref.cast (ref $pair) (local.get $addr)))
                (if (ref.test (ref $code-object) (call $car (local.get $addr-pair)))
                  (then
                    (if (i32.eqz (ref.eq
                          (call $car (local.get $addr-pair))
                          (local.get $co)))
                      (then
                        (local.set $co
                          (call $car (local.get $addr-pair)))
                        (local.set $instrs (struct.get $code-object $instrs
                          (ref.cast (ref $code-object)
                            (call $car (local.get $addr-pair)))))
                        (local.set $len (struct.get $code-object $len
                          (ref.cast (ref $code-object)
                            (call $car (local.get $addr-pair)))))))
                    (local.set $pc
                      (call $fixnum-value
                        (ref.cast (ref i31) (call $cdr (local.get $addr-pair)))))
                    (br $loop-start))))
              (else
                ;; Bare fixnum PC (backward compat within the current code-obj)
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
              (then (call $js-trace-sr (local.get $pc) (i32.const 0)
                (i32.const 1) ;; is-save
                (struct.get $instr $a (local.get $instr))
                (call $type-id (call $xcar (local.get $stack)))
                (call $stack-depth (local.get $stack)))))))

        ;; ── restore (opcode 5) ──
        (if (i32.eq (local.get $opcode) (i32.const 5))
          (then
            (local.set $target (struct.get $instr $a (local.get $instr)))
            (local.set $op-result
              (call $xcar (local.get $stack)))
            (local.set $stack
              (call $xcdr (local.get $stack)))
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
              (then (call $js-trace-sr (local.get $pc) (i32.const 0)
                (i32.const 0) ;; is-restore
                (local.get $target)
                (call $type-id (local.get $op-result))
                (call $stack-depth (local.get $stack)))))))

        ;; ── perform (opcode 6) ──
        (if (i32.eq (local.get $opcode) (i32.const 6))
          (then
            (local.set $op-result
              (call $dispatch-op (struct.get $instr $c (local.get $instr))
                (struct.get $instr $val (local.get $instr))
                (local.get $val) (local.get $env) (local.get $proc)
                (local.get $argl) (local.get $cont) (local.get $stack)
                (local.get $co)))
            ;; Bridge error sentinel to ECE's error function
            (if (ref.test (ref $error-sentinel) (local.get $op-result))
              (then
                (global.set $error-pc (local.get $pc))
                (local.set $proc (call $try-lookup-variable-value
                  (ref.as_non_null (global.get $error-sym))
                  (global.get $global-env)))
                (local.set $argl (call $cons
                  (struct.get $error-sentinel $message
                    (ref.cast (ref $error-sentinel) (local.get $op-result)))
                  (struct.get $error-sentinel $irritants
                    (ref.cast (ref $error-sentinel) (local.get $op-result)))))
                (local.set $co
                  (struct.get $compiled-proc $code-obj
                    (ref.cast (ref $compiled-proc) (local.get $proc))))
                (local.set $instrs (struct.get $code-object $instrs
                  (ref.cast (ref $code-object) (local.get $co))))
                (local.set $len (struct.get $code-object $len
                  (ref.cast (ref $code-object) (local.get $co))))
                (local.set $pc (i32.const 0))
                (br $loop-start)))))

        ;; ── halt (opcode 7) ──
        (if (i32.eq (local.get $opcode) (i32.const 7))
          (then (br $loop-end)))

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
                     (param $co (ref null eq))
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
          (call $xcar (local.get $operands))
          (local.get $val) (local.get $env) (local.get $proc)
          (local.get $argl) (local.get $cont) (local.get $stack)
          (local.get $co)))
        (local.set $rest (call $xcdr (local.get $operands)))
        ;; Second operand
        (if (i32.and
              (i32.eqz (ref.is_null (local.get $rest)))
              (i32.eqz (call $is-null (local.get $rest))))
          (then
            (local.set $b (call $eval-operand
              (call $xcar (local.get $rest))
              (local.get $val) (local.get $env) (local.get $proc)
              (local.get $argl) (local.get $cont) (local.get $stack)
              (local.get $co)))
            (local.set $rest (call $xcdr (local.get $rest)))
            ;; Third operand
            (if (i32.and
                  (i32.eqz (ref.is_null (local.get $rest)))
                  (i32.eqz (call $is-null (local.get $rest))))
              (then
                (local.set $c (call $eval-operand
                  (call $xcar (local.get $rest))
                  (local.get $val) (local.get $env) (local.get $proc)
                  (local.get $argl) (local.get $cont) (local.get $stack)
                  (local.get $co)))))))))

    ;; Dispatch on operation ID (canonical IDs from operations.def)

    ;; 0 = lookup-variable-value(name, env)
    (if (result (ref null eq)) (i32.eqz (local.get $op-id))
      (then (call $lookup-variable-value
              (ref.cast (ref $symbol) (local.get $a))
              (local.get $b)))

    ;; 1 = lookup-global-variable(name) — bypasses lexical frames for %global-ref hygiene
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 1))
      (then
        (return (call $lookup-variable-value
          (ref.cast (ref $symbol) (local.get $a))
          (global.get $global-env))))

    ;; 2 = set-variable-value!(name, value, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 2))
      (then
        (call $set-variable-value!
          (ref.cast (ref $symbol) (local.get $a))
          (local.get $b)
          (local.get $c))
        (global.get $void))

    ;; 3 = define-variable!(name, value, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 3))
      (then
        (call $define-variable!
          (ref.cast (ref $symbol) (local.get $a))
          (local.get $b)
          (local.get $c))
        (global.get $void))

    ;; 4 = extend-environment(names, vals, env, nvals)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 4))
      (then
        ;; a=names, b=vals, c=env; 4th operand is nvals
        (local.set $rest (call $xcdr (call $xcdr
            (call $xcdr (local.get $operands)))))
        (call $extend-env (local.get $a) (local.get $b) (local.get $c)
          (if (result i32)
            (i32.and
              (i32.eqz (ref.is_null (local.get $rest)))
              (i32.eqz (call $is-null (local.get $rest))))
            (then
              (call $fixnum-value (ref.cast (ref i31)
                (call $eval-operand
                  (call $xcar (local.get $rest))
                  (local.get $val) (local.get $env) (local.get $proc)
                  (local.get $argl) (local.get $cont) (local.get $stack)
                  (local.get $co)))))
            (else (i32.const 0)))))

    ;; 5 = lexical-ref(depth, offset, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 5))
      (then (call $lexical-ref
              (call $fixnum-value (ref.cast (ref i31) (local.get $a)))
              (call $fixnum-value (ref.cast (ref i31) (local.get $b)))
              (local.get $c)))

    ;; 6 = lexical-set!(depth, offset, value, env)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 6))
      (then
        ;; 4th operand is env
        (local.set $rest (call $xcdr (call $xcdr
            (call $xcdr (local.get $operands)))))
        (call $lexical-set!
          (call $fixnum-value (ref.cast (ref i31) (local.get $a)))
          (call $fixnum-value (ref.cast (ref i31) (local.get $b)))
          (local.get $c)
          (if (result (ref null eq))
            (i32.and
              (i32.eqz (ref.is_null (local.get $rest)))
              (i32.eqz (call $is-null (local.get $rest))))
            (then (call $eval-operand
              (call $xcar (local.get $rest))
              (local.get $val) (local.get $env) (local.get $proc)
              (local.get $argl) (local.get $cont) (local.get $stack)
              (local.get $co)))
            (else (local.get $env))))
        (global.get $void))

    ;; 7 = make-compiled-procedure(label, env) → procedure
    ;; $a = evaluated label operand (either a bare $code-object from a const
    ;;      operand, or a (code-obj . pc) pair from a label operand).
    ;; $b = env
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 7))
      (then
        ;; §7.1 bare code-object → closure with $code-obj = a, pc 0.
        (if (result (ref null eq)) (ref.test (ref $code-object) (local.get $a))
          (then
            (struct.new $compiled-proc
              (i32.const 0) (i32.const 0)
              (local.get $b)
              (local.get $a)))
          ;; (code-obj . pc) qualified-address pair
          (else
            (struct.new $compiled-proc
              (i32.const 0) (i32.const 0)
              (local.get $b)
              (call $car (ref.cast (ref $pair) (local.get $a)))))))

    ;; 8 = compiled-procedure-entry(proc) → $code-object.
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 8))
      (then
        (if (i32.eqz (ref.test (ref $compiled-proc) (local.get $a)))
          (then (return (call $make-type-error
            (global.get $name-compiled-procedure-entry)
            (global.get $err-not-compiled-procedure)
            (local.get $a)))))
        (struct.get $compiled-proc $code-obj
          (ref.cast (ref $compiled-proc) (local.get $a))))

    ;; 9 = compiled-procedure-env(proc)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 9))
      (then (call $compiled-proc-env (ref.cast (ref $compiled-proc) (local.get $a))))

    ;; 10 = primitive-procedure?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 10))
      (then (if (result (ref null eq)) (call $is-primitive (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 11 = continuation?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 11))
      (then (if (result (ref null eq)) (call $is-continuation (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 12 = parameter?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 12))
      (then (if (result (ref null eq)) (call $is-parameter (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 13 = apply-primitive-procedure(proc, args) → result
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 13))
      (then (call $apply-primitive
              (ref.cast (ref $primitive) (local.get $a))
              (local.get $b)))

    ;; 14 = apply-parameter(param, args)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 14))
      (then
        ;; If no args, return value. If args, set value.
        (if (result (ref null eq)) (call $is-null (local.get $b))
          (then (struct.get $parameter $value
                  (ref.cast (ref $parameter) (local.get $a))))
          (else
            (struct.set $parameter $value
              (ref.cast (ref $parameter) (local.get $a))
              (call $xcar (local.get $b)))
            (global.get $void))))

    ;; 15 = parameter-ref(param) — get current value of parameter
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 15))
      (then (struct.get $parameter $value
              (ref.cast (ref $parameter) (local.get $a))))

    ;; 16 = parameter-set!(param, value) — set with guard
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 16))
      (then
        ;; If parameter has a guard, call it; otherwise set directly
        ;; For now, set directly (guards are handled at ECE level)
        (struct.set $parameter $value
          (ref.cast (ref $parameter) (local.get $a))
          (local.get $b))
        (global.get $void))

    ;; 17 = parameter-raw-set!(param, value) — set without guard
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 17))
      (then
        (struct.set $parameter $value
          (ref.cast (ref $parameter) (local.get $a))
          (local.get $b))
        (global.get $void))

    ;; 18 = capture-continuation(stack, continue) → continuation struct
    ;; Also captures the current winding stack from the ECE *winding-stack* variable.
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 18))
      (then
        (local.set $c  ;; reuse $c for winds
          (if (result (ref null eq)) (ref.is_null (global.get $winding-stack-sym))
            (then (global.get $nil))
            (else
              (call $try-lookup-variable-value
                (ref.as_non_null (global.get $winding-stack-sym))
                (global.get $global-env)))))
        (struct.new $continuation (local.get $a) (local.get $b)
          (if (result (ref null eq)) (ref.is_null (local.get $c))
            (then (global.get $nil))
            (else (local.get $c)))))

    ;; 19 = do-continuation-winds(proc) — transition winding stack before resuming.
    ;; If the continuation's saved winds differ from the current *winding-stack*,
    ;; look up do-winds! and call it to run before/after thunks.
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 19))
      (then
        ;; $a = continuation's saved winds
        (local.set $a (struct.get $continuation $winds
          (ref.cast (ref $continuation) (local.get $a))))
        ;; $b = current *winding-stack* (from ECE env)
        (local.set $b
          (if (result (ref null eq)) (ref.is_null (global.get $winding-stack-sym))
            (then (global.get $nil))
            (else (call $try-lookup-variable-value
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
        (local.set $c (call $try-lookup-variable-value
          (ref.as_non_null (global.get $do-winds-sym))
          (global.get $global-env)))
        (global.set $execute-argl
          (call $cons (local.get $b)
            (call $cons (local.get $a) (global.get $nil))))
        (global.set $execute-proc (local.get $c))
        (drop (call $execute
          (call $compiled-proc-env (ref.cast (ref $compiled-proc) (local.get $c)))
          (struct.get $compiled-proc $code-obj
            (ref.cast (ref $compiled-proc) (local.get $c)))))
        (global.get $void))

    ;; 20 = continuation-stack(cont)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 20))
      (then (struct.get $continuation $stack
              (ref.cast (ref $continuation) (local.get $a))))

    ;; 21 = continuation-conts(cont)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 21))
      (then (struct.get $continuation $conts
              (ref.cast (ref $continuation) (local.get $a))))

    ;; 22 = false?(val) → bool
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 22))
      (then (if (result (ref null eq)) (call $is-false (local.get $a))
        (then (global.get $true))
        (else (global.get $false))))

    ;; 23 = list(args...) → list built from operands
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 23))
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

    ;; 24 = cons(a, b)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 24))
      (then (call $cons (local.get $a) (local.get $b)))

    ;; 25 = car(pair)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 25))
      (then (call $xcar (local.get $a)))

    ;; 26 = cdr(pair)
    (else (if (result (ref null eq)) (i32.eq (local.get $op-id) (i32.const 26))
      (then (call $xcdr (local.get $a)))

    ;; Unknown op — return void
    (else (global.get $void)
    ))))))))))))))))))))))))))))))))))))))))))))))))))))))
  )


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 9: Primitive Dispatch
  ;; ═══════════════════════════════════════════════════════════════════
  ;; ECE primitives dispatched by numeric ID from primitives.def.
  ;; Called via machine op 13 (apply-primitive-procedure).

  ;; --- Argument extraction helpers ---
  ;; Args are an ECE list. These extract the 1st, 2nd, 3rd elements.
  (func $arg1 (param $args (ref null eq)) (result (ref null eq))
    (call $xcar (local.get $args)))
  (func $arg2 (param $args (ref null eq)) (result (ref null eq))
    (call $cadr (local.get $args)))
  (func $arg3 (param $args (ref null eq)) (result (ref null eq))
    (call $caddr (local.get $args)))

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
    ;; i31ref fixnum range is the full signed i31: [-2^30, 2^30-1]
    (if (result (ref null eq))
      (i32.and
        (i32.ge_s (local.get $n) (i32.const -1073741824))
        (i32.le_s (local.get $n) (i32.const 1073741823)))
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

  ;; Wrap-around f64 to i32 truncation for bitwise semantics.
  ;; Unlike $safe-trunc-i32 (which clamps), this takes the low 32 bits of
  ;; the integer part of $n. SHA-1 and friends can produce intermediate
  ;; values outside [-2^31, 2^32-1] while summing large unsigned 32-bit
  ;; words, so the conversion goes via i64 to avoid an i32.trunc_f64_s
  ;; trap. f64 exactly represents integers up to 2^53, comfortably above
  ;; the range we care about for 32-bit bitwise operations.
  ;;
  ;; Values outside the f64-exact integer range (e.g. 1e30, NaN, infinity)
  ;; would trap `i64.trunc_f64_s` directly. Guard with a finite/range check
  ;; that returns 0 for unrepresentable inputs — bitwise semantics on such
  ;; values are implementation-defined and a trap would be surprising.
  (func $trunc-to-i32-wrap (param $n f64) (result i32)
    (if (result i32)
      (i32.and
        (f64.eq (local.get $n) (local.get $n))                       ;; not NaN
        (i32.and
          (f64.ge (local.get $n) (f64.const -9007199254740992))      ;; >= -2^53
          (f64.le (local.get $n) (f64.const 9007199254740992))))     ;; <= 2^53
      (then (i32.wrap_i64 (i64.trunc_f64_s (local.get $n))))
      (else (i32.const 0)))
  )

  ;; Portable arithmetic shift helper. WASM's i32.shl / i32.shr_s mask the
  ;; shift count to the low 5 bits, so shifting by >= 32 wraps around and
  ;; leaves the value unchanged. For parity with CL's unbounded bignum
  ;; shifting, we clamp shifts of 32+ to a full-width result:
  ;;   - left shift of 32+ bits  → 0 (all bits shifted out)
  ;;   - right shift of 32+ bits → signed extension: 0 or -1
  (func $arith-shift-i32 (param $val i32) (param $count i32) (result i32)
    (if (result i32) (i32.ge_s (local.get $count) (i32.const 0))
      (then
        (if (result i32) (i32.ge_s (local.get $count) (i32.const 32))
          (then (i32.const 0))
          (else (i32.shl (local.get $val) (local.get $count)))))
      (else
        (if (result i32) (i32.le_s (local.get $count) (i32.const -32))
          (then (i32.shr_s (local.get $val) (i32.const 31)))
          (else (i32.shr_s (local.get $val)
                  (i32.sub (i32.const 0) (local.get $count))))))))

  ;; Wrap an f64 result, demoting to fixnum if it's an integer in fixnum range.
  ;; Range check BEFORE i32.trunc_f64_s to avoid WASM trap on large floats.
  (func $wrap-f64 (param $n f64) (result (ref null eq))
    (local $i i32)
    ;; Check if it's an integer value AND in fixnum range (full i31 signed)
    (if (result (ref null eq))
      (i32.and
        (f64.eq (local.get $n) (f64.trunc (local.get $n)))
        (i32.and
          (f64.ge (local.get $n) (f64.const -1073741824))
          (f64.le (local.get $n) (f64.const 1073741823))))
      (then
        (local.set $i (i32.trunc_f64_s (local.get $n)))
        (call $make-fixnum (local.get $i)))
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
        (if (i32.eqz (call $is-fixnum (call $xcar (local.get $cur))))
          (then (local.set $all-int (i32.const 0))))
        (local.set $acc (f64.add (local.get $acc)
          (call $to-f64 (call $xcar (local.get $cur)))))
        (local.set $cur (call $xcdr (local.get $cur)))
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
        (if (i32.eqz (call $is-fixnum (call $xcar (local.get $cur))))
          (then (local.set $all-int (i32.const 0))))
        (local.set $acc (f64.mul (local.get $acc)
          (call $to-f64 (call $xcar (local.get $cur)))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (if (result (ref null eq)) (local.get $all-int)
      (then (call $wrap-i32 (call $safe-trunc-i32 (local.get $acc))))
      (else (call $make-float (local.get $acc))))
  )

  ;; --- Variadic bitwise ops ---
  ;; Shape mirrors $fold-add but the accumulator is i32 and the starting
  ;; value is the identity element for the op. Each arg is read via
  ;; $to-f64 (handles fixnum + float-box) and wrapped to i32 via
  ;; $trunc-to-i32-wrap so values > 2^31-1 retain their low-32-bit
  ;; pattern. The final accumulator is boxed via $make-fixnum-or-float
  ;; so results outside the 29-bit fixnum range become float-boxes.
  (func $fold-bitwise-and (param $args (ref null eq)) (result (ref null eq))
    (local $acc i32)
    (local $cur (ref null eq))
    (local.set $acc (i32.const -1))
    (local.set $cur (local.get $args))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $acc (i32.and (local.get $acc)
          (call $trunc-to-i32-wrap (call $to-f64 (call $xcar (local.get $cur))))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (call $make-fixnum-or-float (local.get $acc))
  )

  (func $fold-bitwise-or (param $args (ref null eq)) (result (ref null eq))
    (local $acc i32)
    (local $cur (ref null eq))
    (local.set $acc (i32.const 0))
    (local.set $cur (local.get $args))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $acc (i32.or (local.get $acc)
          (call $trunc-to-i32-wrap (call $to-f64 (call $xcar (local.get $cur))))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (call $make-fixnum-or-float (local.get $acc))
  )

  (func $fold-bitwise-xor (param $args (ref null eq)) (result (ref null eq))
    (local $acc i32)
    (local $cur (ref null eq))
    (local.set $acc (i32.const 0))
    (local.set $cur (local.get $args))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $acc (i32.xor (local.get $acc)
          (call $trunc-to-i32-wrap (call $to-f64 (call $xcar (local.get $cur))))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (call $make-fixnum-or-float (local.get $acc))
  )

  (func $fold-sub (param $args (ref null eq)) (result (ref null eq))
    (local $first f64)
    (local $acc f64)
    (local $cur (ref null eq))
    (local $all-int i32)
    (local.set $first (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $xcdr (local.get $args)))
    (local.set $all-int (i32.const 1))
    ;; Check first arg for float (loop only checks remaining args)
    (if (i32.eqz (call $is-fixnum (call $arg1 (local.get $args))))
      (then (local.set $all-int (i32.const 0))))
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
        (if (i32.eqz (call $is-fixnum (call $xcar (local.get $cur))))
          (then (local.set $all-int (i32.const 0))))
        (local.set $acc (f64.sub (local.get $acc)
          (call $to-f64 (call $xcar (local.get $cur)))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (if (result (ref null eq)) (local.get $all-int)
      (then (call $wrap-i32 (call $safe-trunc-i32 (local.get $acc))))
      (else (call $make-float (local.get $acc))))
  )

  (func $fold-div (param $args (ref null eq)) (result (ref null eq))
    (local $acc f64)
    (local $cur (ref null eq))
    (local.set $acc (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $xcdr (local.get $args)))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $acc (f64.div (local.get $acc)
          (call $to-f64 (call $xcar (local.get $cur)))))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (call $wrap-f64 (local.get $acc))
  )

  ;; --- Variadic comparison ---
  (func $cmp-eq (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $prev f64)
    (local $val f64)
    (local.set $prev (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $xcdr (local.get $args)))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $val (call $to-f64 (call $xcar (local.get $cur))))
        (if (i32.eqz (f64.eq (local.get $prev) (local.get $val)))
          (then (return (global.get $false))))
        (local.set $prev (local.get $val))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (global.get $true)
  )

  (func $cmp-lt (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $prev f64)
    (local $val f64)
    (local.set $prev (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $xcdr (local.get $args)))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $val (call $to-f64 (call $xcar (local.get $cur))))
        (if (i32.eqz (f64.lt (local.get $prev) (local.get $val)))
          (then (return (global.get $false))))
        (local.set $prev (local.get $val))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (global.get $true)
  )

  (func $cmp-gt (param $args (ref null eq)) (result (ref null eq))
    (local $cur (ref null eq))
    (local $prev f64)
    (local $val f64)
    (local.set $prev (call $to-f64 (call $arg1 (local.get $args))))
    (local.set $cur (call $xcdr (local.get $args)))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $val (call $to-f64 (call $xcar (local.get $cur))))
        (if (i32.eqz (f64.gt (local.get $prev) (local.get $val)))
          (then (return (global.get $false))))
        (local.set $prev (local.get $val))
        (local.set $cur (call $xcdr (local.get $cur)))
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
            (call $xcar (local.get $cur))))))
        (local.set $cur (call $xcdr (local.get $cur)))
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
          (call $xcar (local.get $cur))))
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
        (local.set $cur (call $xcdr (local.get $cur)))
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
          (call $fixnum-value (ref.cast (ref i31) (local.get $a)))
          (call $fixnum-value (ref.cast (ref i31) (local.get $b))))
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
                (call $xcar (local.get $a))
                (call $xcar (local.get $b))))
          (then (return (global.get $false))))
        (return (call $prim-equal
          (call $xcdr (local.get $a))
          (call $xcdr (local.get $b))))))
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

  ;; --- number->string ---
  ;; Integer-valued numbers (fixnum or float-box) are converted digit by
  ;; digit using an i64 accumulator so large float-boxes (values outside
  ;; fixnum range) are printed without going through $make-fixnum, which
  ;; would corrupt them via the 29-bit fixnum squeeze. Non-integer, NaN,
  ;; and infinite float-boxes are not formatted here — they return `#?`
  ;; as a non-trapping fallback. Full f64 decimal formatting is out of
  ;; scope for this change; callers that need it should print floats
  ;; via a future helper.
  (func $prim-number-to-string (param $v (ref null eq)) (result (ref null eq))
    (local $n i64)
    (local $fv f64)
    (local $neg i32)
    (local $buf (ref $string))
    (local $i i32)
    (local $len i32)
    (local $digit i32)
    (local $result (ref $string))
    (if (call $is-fixnum (local.get $v))
      (then
        (local.set $n (i64.extend_i32_s
          (call $fixnum-value (ref.cast (ref i31) (local.get $v))))))
      (else
        (if (ref.test (ref $float-box) (local.get $v))
          (then
            (local.set $fv (struct.get $float-box $val
              (ref.cast (ref $float-box) (local.get $v))))
            ;; Guard: integer-valued AND finite (NaN fails trunc == self,
            ;; infinity fails the in-range check below). i64 safely covers
            ;; any f64-exact integer up to 2^53.
            (if (i32.eqz (i32.and
                  (f64.eq (local.get $fv) (f64.trunc (local.get $fv)))
                  (i32.and
                    (f64.ge (local.get $fv) (f64.const -9007199254740992))
                    (f64.le (local.get $fv) (f64.const 9007199254740992)))))
              (then (return (call $make-static-string
                (i32.const 35) (i32.const 63)))))  ;; "#?"
            (local.set $n (i64.trunc_f64_s (local.get $fv))))
          (else (return (global.get $void))))))
    (if (i64.eqz (local.get $n))
      (then
        (local.set $buf (array.new_default $string (i32.const 1)))
        (array.set $string (local.get $buf) (i32.const 0) (i32.const 48)) ;; '0'
        (return (local.get $buf))))
    (local.set $neg (i64.lt_s (local.get $n) (i64.const 0)))
    (if (local.get $neg)
      (then (local.set $n (i64.sub (i64.const 0) (local.get $n)))))
    ;; f64 exactly represents integers up to ~16 digits, plus sign — 20 bytes is ample.
    (local.set $buf (array.new_default $string (i32.const 20)))
    (local.set $i (i32.const 0))
    (block $done
      (loop $digits
        (br_if $done (i64.eqz (local.get $n)))
        (local.set $digit (i32.wrap_i64 (i64.rem_u (local.get $n) (i64.const 10))))
        (array.set $string (local.get $buf) (local.get $i)
          (i32.add (local.get $digit) (i32.const 48)))
        (local.set $n (i64.div_u (local.get $n) (i64.const 10)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $digits)))
    (if (local.get $neg)
      (then
        (array.set $string (local.get $buf) (local.get $i) (i32.const 45)) ;; '-'
        (local.set $i (i32.add (local.get $i) (i32.const 1)))))
    (local.set $len (local.get $i))
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
    (local.get $result)
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
    (if (ref.test (ref $float-box) (local.get $v))
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
        (call $char-codepoint (ref.cast (ref $char) (local.get $v)))))))
    ;; Pairs/lists: build string by concatenating parts
    (if (call $is-pair (local.get $v))
      (then (return (call $wts-list (local.get $v)))))
    ;; Vectors
    (if (call $is-vector (local.get $v))
      (then (return (call $wts-vector (local.get $v)))))
    ;; Fallback — identify tagged struct types via ref.test and return
    ;; "#<TYPENAME>" so errors that format unknown values (e.g. mc-compile's
    ;; "Unknown expression type" path) remain diagnosable instead of opaque.
    ;; Ordered by estimated frequency; final $type-tag-unknown catches any
    ;; struct type we haven't explicitly listed so new types stay diagnosable.
    (if (ref.test (ref $hash-table) (local.get $v))
      (then (return (global.get $type-tag-hash-table))))
    (if (ref.test (ref $code-object) (local.get $v))
      (then (return (global.get $type-tag-code-object))))
    (if (ref.test (ref $compiled-proc) (local.get $v))
      (then (return (global.get $type-tag-compiled-proc))))
    (if (ref.test (ref $continuation) (local.get $v))
      (then (return (global.get $type-tag-continuation))))
    (if (ref.test (ref $primitive) (local.get $v))
      (then (return (global.get $type-tag-primitive))))
    (if (ref.test (ref $parameter) (local.get $v))
      (then (return (global.get $type-tag-parameter))))
    (if (ref.test (ref $port) (local.get $v))
      (then (return (global.get $type-tag-port))))
    (if (ref.test (ref $error-sentinel) (local.get $v))
      (then (return (global.get $type-tag-error-sentinel))))
    (if (ref.test (ref $js-ref) (local.get $v))
      (then (return (global.get $type-tag-js-ref))))
    (if (ref.test (ref $env-frame) (local.get $v))
      (then (return (global.get $type-tag-env-frame))))
    (if (call $is-eof (local.get $v))
      (then (return (global.get $type-tag-eof))))
    (if (ref.test (ref $void-type) (local.get $v))
      (then (return (global.get $type-tag-void))))
    (global.get $type-tag-unknown)
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
              (call $write-to-string-impl (call $xcar (local.get $cur)))
              (local.get $parts)))
            (local.set $cur (call $xcdr (local.get $cur)))
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
          (call $xcar (local.get $cur))
          (local.get $result)))
        (local.set $cur (call $xcdr (local.get $cur)))
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
    (local.set $rest (call $xcdr (call $xcdr (local.get $args))))
    (if (i32.and
          (i32.eqz (ref.is_null (local.get $rest)))
          (i32.eqz (call $is-null (local.get $rest))))
      (then (return (call $xcar (local.get $rest)))))
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
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $count)))
    ;; Fill
    (local.set $vec (array.new_default $vector (local.get $len)))
    (local.set $cur (local.get $lst))
    (local.set $i (i32.const 0))
    (block $done
      (loop $fill
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (array.set $vector (local.get $vec) (local.get $i)
          (call $xcar (local.get $cur)))
        (local.set $cur (call $xcdr (local.get $cur)))
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
          (call $char-codepoint (ref.cast (ref $char) (local.get $v))))
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
          (call $char-codepoint (ref.cast (ref $char) (local.get $v))))
        (call $js-display-string (i32.const 1))
        (return)))
    ;; Pairs: (display (a . b))
    (if (call $is-pair (local.get $v))
      (then
        (i32.store16 (i32.const 0) (i32.const 40))  ;; '('
        (call $js-display-string (i32.const 1))
        (call $display-value (call $xcar (local.get $v)))
        (call $display-list-tail (call $xcdr (local.get $v)))
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
        (call $display-value (call $xcar (local.get $v)))
        (call $display-list-tail (call $xcdr (local.get $v)))
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
    (local $wasm-host-string (ref $string))
    ;; --- Code-object primitive locals (ids 241-249) ---
    (local $co-for-labels (ref null $code-object))
    (local $lbl-ht (ref null $hash-table))
    (local $lbl-keys (ref null $hash-keys))
    (local $lbl-vals (ref null $hash-vals))
    (local $lbl-count i32)
    (local $lbl-i i32)
    (local $lbl-result (ref null eq))
    (local.set $id (call $primitive-id (local.get $prim)))
    ;; Debug: store prim ID for crash diagnosis
    (global.set $dbg-opcode (i32.add (local.get $id) (i32.const 1000)))

    ;; 0 = + (type-guarded: all args must be numbers)
    (if (i32.eqz (local.get $id))
      (then
        (if (i32.eqz (call $all-numbers (local.get $args)))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $first-non-number (local.get $args))))))
        (return (call $fold-add (local.get $args)))))
    ;; 1 = - (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 1))
      (then
        (if (i32.eqz (call $all-numbers (local.get $args)))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $first-non-number (local.get $args))))))
        (return (call $fold-sub (local.get $args)))))
    ;; 2 = * (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 2))
      (then
        (if (i32.eqz (call $all-numbers (local.get $args)))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $first-non-number (local.get $args))))))
        (return (call $fold-mul (local.get $args)))))
    ;; 3 = / (type-guarded + division by zero check)
    (if (i32.eq (local.get $id) (i32.const 3))
      (then
        (if (i32.eqz (call $all-numbers (local.get $args)))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $first-non-number (local.get $args))))))
        (if (call $div-has-zero-divisor (local.get $args))
          (then (return (struct.new $error-sentinel
            (call $string-concat
              (call $prim-name-str (local.get $id)) (global.get $err-div-zero))
            (global.get $nil)))))
        (return (call $fold-div (local.get $args)))))
    ;; 4 = modulo — migrated to ECE (prelude.scm), derived from floor
    ;; 5 = car (type-guarded: arg must be pair or nil)
    (if (i32.eq (local.get $id) (i32.const 5))
      (then
        (if (call $is-null (call $arg1 (local.get $args)))
          (then (return (global.get $nil))))
        (if (i32.eqz (call $is-pair (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-pair)
            (call $arg1 (local.get $args))))))
        (return (call $xcar (call $arg1 (local.get $args))))))
    ;; 6 = cdr (type-guarded: arg must be pair or nil)
    (if (i32.eq (local.get $id) (i32.const 6))
      (then
        (if (call $is-null (call $arg1 (local.get $args)))
          (then (return (global.get $nil))))
        (if (i32.eqz (call $is-pair (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-pair)
            (call $arg1 (local.get $args))))))
        (return (call $xcdr (call $arg1 (local.get $args))))))
    ;; 7 = cons
    (if (i32.eq (local.get $id) (i32.const 7))
      (then (return (call $cons (call $arg1 (local.get $args)) (call $arg2 (local.get $args))))))
    ;; 8 = list — now in prelude.scm (platform ece); no primitive dispatch.
    ;; 9 = set-car! (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 9))
      (then
        (if (i32.eqz (call $is-pair (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-pair)
            (call $arg1 (local.get $args))))))
        (call $set-car! (ref.cast (ref $pair) (call $arg1 (local.get $args)))
                        (call $arg2 (local.get $args)))
        (return (global.get $void))))
    ;; 10 = set-cdr! (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 10))
      (then
        (if (i32.eqz (call $is-pair (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-pair)
            (call $arg1 (local.get $args))))))
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
    ;; 22 = = (numeric, type-guarded)
    (if (i32.eq (local.get $id) (i32.const 22))
      (then
        (if (i32.eqz (call $all-numbers (local.get $args)))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $first-non-number (local.get $args))))))
        (return (call $cmp-eq (local.get $args)))))
    ;; 23 = < (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 23))
      (then
        (if (i32.eqz (call $all-numbers (local.get $args)))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $first-non-number (local.get $args))))))
        (return (call $cmp-lt (local.get $args)))))
    ;; 24 = > (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 24))
      (then
        (if (i32.eqz (call $all-numbers (local.get $args)))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $first-non-number (local.get $args))))))
        (return (call $cmp-gt (local.get $args)))))
    ;; 25 = string-length (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 25))
      (then
        (if (i32.eqz (call $is-string (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-string)
            (call $arg1 (local.get $args))))))
        (return (call $prim-string-length (call $arg1 (local.get $args))))))
    ;; 26 = string-ref (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 26))
      (then
        (if (i32.eqz (call $is-string (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-string)
            (call $arg1 (local.get $args))))))
        (return (call $prim-string-ref
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
        (local.set $id (call $char-codepoint (ref.cast (ref $char) (call $arg1 (local.get $args)))))
        (return (call $prim-char-to-string (local.get $id)))))
    ;; 57 = display (value [port])
    ;; IDs 57 (display), 58 (write), 59 (newline) retired —
    ;; replaced by %<op>-to-port primitives at IDs 179-181.
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
    ;; IDs 71 (current-input-port) and 72 (current-output-port) retired —
    ;; these are now ECE parameters defined in prelude.scm.
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
    ;; ID 62 (write-char) retired — replaced by %write-char-to-port at ID 182.
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
            (i32.eqz (ref.is_null (call $xcdr (local.get $args))))
            (i32.eqz (call $is-null (call $xcdr (local.get $args)))))
          (then
            (return (array.new $vector
              (call $arg2 (local.get $args))
              (local.get $id))))
          (else
            (return (array.new_default $vector (local.get $id)))))))
    ;; 51 = vector (construct from args)
    (if (i32.eq (local.get $id) (i32.const 51))
      (then (return (call $prim-list-to-vector (local.get $args)))))
    ;; 52 = vector-ref (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 52))
      (then
        (if (i32.eqz (ref.test (ref $vector) (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-vector)
            (call $arg1 (local.get $args))))))
        (return (array.get $vector
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
    ;; 43 = char->integer (type-guarded)
    (if (i32.eq (local.get $id) (i32.const 43))
      (then
        (if (i32.eqz (call $is-char (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-char)
            (call $arg1 (local.get $args))))))
        (return (call $make-fixnum
          (call $char-codepoint (ref.cast (ref $char) (call $arg1 (local.get $args))))))))
    ;; 44 = integer->char (type-guarded: integer in [0, 0x10FFFF])
    (if (i32.eq (local.get $id) (i32.const 44))
      (then
        (if (i32.eqz (call $is-integer (call $arg1 (local.get $args))))
          (then (return (call $make-type-error
            (call $prim-name-str (local.get $id)) (global.get $err-not-number)
            (call $arg1 (local.get $args))))))
        (local.set $id (i32.trunc_f64_s
          (call $to-f64 (call $arg1 (local.get $args)))))
        (if (i32.or
              (i32.lt_s (local.get $id) (i32.const 0))
              (i32.gt_s (local.get $id) (i32.const 0x10FFFF)))
          (then (return (call $make-type-error
            (call $prim-name-str (i32.const 44)) (global.get $err-not-number)
            (call $arg1 (local.get $args))))))
        (return (call $make-char (local.get $id)))))
    ;; 45-49: char=?, char<?, char-whitespace?, char-alphabetic?, char-numeric? — now in prelude.scm
    ;; Bitwise primitives 76-80: the three variadic ones (76/77/78)
    ;; delegate to $fold-bitwise-and/or/xor which walk the args list,
    ;; starting from the identity element and folding left with the
    ;; corresponding i32 op. 79 (unary) and 80 (binary) are not variadic
    ;; and read args directly. $trunc-to-i32-wrap + $to-f64 accept both
    ;; fixnum and float-box and wrap values > 2^31-1 back to the signed
    ;; low-32-bit pattern, so SHA-1 round constants like 0xEFCDAB89 work.
    ;; 76 = bitwise-and (variadic; identity -1)
    (if (i32.eq (local.get $id) (i32.const 76))
      (then (return (call $fold-bitwise-and (local.get $args)))))
    ;; 77 = bitwise-or (variadic; identity 0)
    (if (i32.eq (local.get $id) (i32.const 77))
      (then (return (call $fold-bitwise-or (local.get $args)))))
    ;; 78 = bitwise-xor (variadic; identity 0)
    (if (i32.eq (local.get $id) (i32.const 78))
      (then (return (call $fold-bitwise-xor (local.get $args)))))
    ;; 79 = bitwise-not
    (if (i32.eq (local.get $id) (i32.const 79))
      (then (return (call $make-fixnum-or-float (i32.xor
        (call $trunc-to-i32-wrap (call $to-f64 (call $arg1 (local.get $args))))
        (i32.const -1))))))
    ;; 80 = arithmetic-shift. Uses $arith-shift-i32 for portable shift
    ;; semantics (clamped shift counts) — see that helper for details.
    (if (i32.eq (local.get $id) (i32.const 80))
      (then
        (return (call $make-fixnum-or-float
          (call $arith-shift-i32
            (call $trunc-to-i32-wrap (call $to-f64 (call $arg1 (local.get $args))))
            (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))))))
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
        (local.set $cur (call $xcar (call $arg1 (local.get $args))))
        (local.set $key (call $arg2 (local.get $args)))
        (block $not-found (loop $scan
          (br_if $not-found (call $is-null (local.get $cur)))
          (br_if $not-found (ref.is_null (local.get $cur)))
          (if (ref.eq (call $xcar (call $xcar (local.get $cur)))
                      (local.get $key))
            (then (return (call $xcdr (call $xcar (local.get $cur))))))
          (local.set $cur (call $xcdr (local.get $cur)))
          (br $scan)))
        (return (global.get $false))))
    ;; 118 = %eq-hash-set!(table, key, value) → void (mutates table cell)
    (if (i32.eq (local.get $id) (i32.const 118))
      (then
        (struct.set $pair $car
          (ref.cast (ref $pair) (call $arg1 (local.get $args)))
          (call $cons
            (call $cons (call $arg2 (local.get $args)) (call $arg3 (local.get $args)))
            (call $xcar (call $arg1 (local.get $args)))))
        (return (global.get $void))))
    ;; 81 = %raw-error (fatal error — throws JS exception)
    (if (i32.eq (local.get $id) (i32.const 81))
      (then
        (call $signal-error-str
          (ref.cast (ref $string) (call $arg1 (local.get $args))))
        (return (global.get $void))))
    ;; 83 = sleep (no-op on WASM for now)
    (if (i32.eq (local.get $id) (i32.const 83))
      (then (return (global.get $void))))
    ;; 84 = clear-screen (no-op on WASM)
    (if (i32.eq (local.get $id) (i32.const 84))
      (then (return (global.get $void))))
    ;; 98 = platform-has?
    ;; Look up symbol in global env; return #t if bound to a non-stub primitive.
    (if (i32.eq (local.get $id) (i32.const 98))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (if (call $is-symbol (local.get $result))
          (then
            (local.set $result (call $try-lookup-variable-value
              (ref.cast (ref $symbol) (local.get $result))
              (global.get $global-env)))
            (if (ref.is_null (local.get $result))
              (then (return (global.get $false)))
              (else
                (if (call $is-primitive (local.get $result))
                  (then
                    ;; Exclude known WASM stubs/no-ops and retired primitives:
                    ;; sleep (83), clear-screen (84), try-eval (90),
                    ;; %procedure-name-set! (97, retired §11.2),
                    ;; open-input/output-file (100/101),
                    ;; %make-directory (194), %chmod (195),
                    ;; %procedure-name-ref (240, retired §11.2)
                    (local.set $id (struct.get $primitive $id
                          (ref.cast (ref $primitive) (local.get $result))))
                    (if (i32.or (i32.eq (local.get $id) (i32.const 83))
                          (i32.or (i32.eq (local.get $id) (i32.const 84))
                            (i32.or (i32.eq (local.get $id) (i32.const 90))
                              (i32.or (i32.eq (local.get $id) (i32.const 97))
                                (i32.or (i32.eq (local.get $id) (i32.const 100))
                                  (i32.or (i32.eq (local.get $id) (i32.const 101))
                                    (i32.or (i32.eq (local.get $id) (i32.const 194))
                                      (i32.or (i32.eq (local.get $id) (i32.const 195))
                                              (i32.eq (local.get $id) (i32.const 240))))))))))
                      (then (return (global.get $false)))
                      (else (return (global.get $true))))))
                (return (global.get $false))))))
        (return (global.get $false))))
    ;; 114 = parameter?
    (if (i32.eq (local.get $id) (i32.const 114))
      (then (return (if (result (ref null eq)) (call $is-parameter (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))
    ;; 137 = keyword?
    ;; Check if value is a symbol whose name starts with ":" or "|:" (CL pipe-escaping).
    ;; ECE keywords like :foo are interned as ":foo" on CL but "|:foo|" on WASM
    ;; because CL's write-to-string-flat adds pipe escaping for colon-prefixed names.
    (if (i32.eq (local.get $id) (i32.const 137))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (if (call $is-symbol (local.get $result))
          (then
            (if (i32.gt_u (array.len (struct.get $symbol $name
                  (ref.cast (ref $symbol) (local.get $result)))) (i32.const 1))
              (then
                ;; Check for ":" prefix (native ECE) or "|:" prefix (CL pipe-escaped)
                (if (i32.eq (array.get_u $string (struct.get $symbol $name
                      (ref.cast (ref $symbol) (local.get $result))) (i32.const 0)) (i32.const 58))  ;; ':'
                  (then (return (global.get $true))))
                (if (i32.and
                      (i32.gt_u (array.len (struct.get $symbol $name
                            (ref.cast (ref $symbol) (local.get $result)))) (i32.const 2))
                      (i32.eq (array.get_u $string (struct.get $symbol $name
                            (ref.cast (ref $symbol) (local.get $result))) (i32.const 0)) (i32.const 124)))  ;; '|'
                  (then
                    (if (i32.eq (array.get_u $string (struct.get $symbol $name
                          (ref.cast (ref $symbol) (local.get $result))) (i32.const 1)) (i32.const 58))  ;; ':'
                      (then (return (global.get $true))))))))))
        (return (global.get $false))))

    ;; --- Integer rounding primitives ---

    ;; 108 = truncate (toward zero)
    (if (i32.eq (local.get $id) (i32.const 108))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (if (result (ref null eq)) (call $is-fixnum (local.get $result))
          (then (return (local.get $result)))
          (else (return (call $f64-to-ece-number
            (f64.trunc (call $float-value
              (ref.cast (ref $float-box) (local.get $result))))))))))
    ;; 109 = floor (toward -infinity)
    (if (i32.eq (local.get $id) (i32.const 109))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (if (result (ref null eq)) (call $is-fixnum (local.get $result))
          (then (return (local.get $result)))
          (else (return (call $f64-to-ece-number
            (f64.floor (call $float-value
              (ref.cast (ref $float-box) (local.get $result))))))))))

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
        (if (i32.eqz (ref.is_null (global.get $co-pending-instrs)))
          (then (call $finalize-co-pending-instrs)))
        ;; arg1 must be a $code-object (post per-code-object refactor).
        (return (call $execute
          (global.get $global-env)
          (call $arg1 (local.get $args))))))

    ;; 89 = apply-compiled-procedure (proc, args)
    (if (i32.eq (local.get $id) (i32.const 89))
      (then
        ;; Set pending proc and argl so $execute initializes registers
        (global.set $execute-proc (call $arg1 (local.get $args)))
        (global.set $execute-argl (call $arg2 (local.get $args)))
        (return (call $execute
          (call $compiled-proc-env
            (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args))))
          (struct.get $compiled-proc $code-obj
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
            (call $xcar (call $xcdr (call $xcdr (call $xcdr (local.get $args)))))))))))

    ;; 92 = %intern-ece (string) — intern string as symbol
    (if (i32.eq (local.get $id) (i32.const 92))
      (then
        (return (call $intern
          (ref.cast (ref $string) (call $arg1 (local.get $args)))))))

    ;; 93-96 = %instruction-vector-* / %label-table-* — retired in Phase F
    ;; alongside the bootstrap-space assembler path. IDs stay reserved; any
    ;; call traps so stale archives surface loudly.
    (if (i32.or
          (i32.or
            (i32.eq (local.get $id) (i32.const 93))
            (i32.eq (local.get $id) (i32.const 94)))
          (i32.or
            (i32.eq (local.get $id) (i32.const 95))
            (i32.eq (local.get $id) (i32.const 96))))
      (then (unreachable)))

    ;; 97 = %procedure-name-set! and 240 = %procedure-name-ref retired in
    ;; per-procedure-code-objects §11.2 — name now lives on the code-object
    ;; struct (set at compile time via %code-object-set-name!, read via
    ;; code-object-name). IDs stay reserved; any call traps so stale
    ;; archives surface loudly.
    (if (i32.or
          (i32.eq (local.get $id) (i32.const 97))
          (i32.eq (local.get $id) (i32.const 240)))
      (then (unreachable)))

    ;; --- Compilation space primitives (core IDs 125-135) retired ---
    ;; Phase F of per-procedure-code-objects: the compilation-space
    ;; abstraction retired in favour of per-procedure code-objects
    ;; (primitive ids 241-249/254-257). IDs 125-135 stay reserved.
    ;; Any call traps so stale archives surface loudly.
    (if (i32.and
          (i32.ge_u (local.get $id) (i32.const 125))
          (i32.le_u (local.get $id) (i32.const 135)))
      (then (unreachable)))

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

    ;; 228 = procedure?(val) — any callable (compiled, primitive, or continuation)
    (if (i32.eq (local.get $id) (i32.const 228))
      (then
        (local.set $result (call $arg1 (local.get $args)))
        (return (if (result (ref null eq))
          (i32.or (i32.or (call $is-compiled-proc (local.get $result))
                          (call $is-primitive (local.get $result)))
                  (call $is-continuation (local.get $result)))
          (then (global.get $true)) (else (global.get $false))))))

    ;; 158 = compiled-procedure-entry(proc) → code-object (§7.1) or (space-id . pc).
    (if (i32.eq (local.get $id) (i32.const 158))
      (then
        (if (i32.eqz (ref.is_null
                       (struct.get $compiled-proc $code-obj
                         (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args))))))
          (then (return (struct.get $compiled-proc $code-obj
                          (ref.cast (ref $compiled-proc) (call $arg1 (local.get $args)))))))
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

    ;; 163 = %make-compiled-procedure(code-obj, env) → compiled-proc
    (if (i32.eq (local.get $id) (i32.const 163))
      (then
        (return (struct.new $compiled-proc
          (i32.const 0) (i32.const 0)
          (call $arg2 (local.get $args))
          (call $arg1 (local.get $args))))))

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
          (local.set $cur (call $xcdr (local.get $cur)))
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
            (call $xcar (local.get $cur)))
          (local.set $cur (call $xcdr (local.get $cur)))
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

    ;; 175 = open-output-string() — create in-memory output string port
    (if (i32.eq (local.get $id) (i32.const 175))
      (then (return (call $open-output-string-port))))

    ;; 176 = get-output-string(port) — extract accumulated string
    (if (i32.eq (local.get $id) (i32.const 176))
      (then (return (call $get-output-string-port
        (ref.cast (ref $port) (call $arg1 (local.get $args)))))))

    ;; 177 = port-line(port) — get current line number
    (if (i32.eq (local.get $id) (i32.const 177))
      (then (return (call $make-fixnum
        (struct.get $port $line
          (ref.cast (ref $port) (call $arg1 (local.get $args))))))))

    ;; 178 = port-col(port) — get current column number
    (if (i32.eq (local.get $id) (i32.const 178))
      (then (return (call $make-fixnum
        (struct.get $port $col
          (ref.cast (ref $port) (call $arg1 (local.get $args))))))))

    ;; 179 = %display-to-port(value port) — write value to explicit port
    (if (i32.eq (local.get $id) (i32.const 179))
      (then
        (if (call $is-console-out-port
              (ref.cast (ref $port) (call $arg2 (local.get $args))))
          (then (call $display-value (call $arg1 (local.get $args))))
          (else (call $display-to-port
                  (call $arg1 (local.get $args))
                  (ref.cast (ref $port) (call $arg2 (local.get $args))))))
        (return (global.get $void))))

    ;; 180 = %write-to-port(value port) — write value in readable form
    (if (i32.eq (local.get $id) (i32.const 180))
      (then
        (global.set $write-mode (i32.const 1))
        (if (call $is-console-out-port
              (ref.cast (ref $port) (call $arg2 (local.get $args))))
          (then (call $display-value
                  (call $write-to-string-impl (call $arg1 (local.get $args)))))
          (else (call $display-to-port
                  (call $write-to-string-impl (call $arg1 (local.get $args)))
                  (ref.cast (ref $port) (call $arg2 (local.get $args))))))
        (global.set $write-mode (i32.const 0))
        (return (global.get $void))))

    ;; 181 = %newline-to-port(port) — write newline to explicit port
    (if (i32.eq (local.get $id) (i32.const 181))
      (then
        (if (call $is-console-out-port
              (ref.cast (ref $port) (call $arg1 (local.get $args))))
          (then (call $js-newline))
          (else (call $port-write-char
                  (ref.cast (ref $port) (call $arg1 (local.get $args)))
                  (i32.const 10))))  ;; newline char
        (return (global.get $void))))

    ;; 182 = %write-char-to-port(char port) — write char to explicit port
    (if (i32.eq (local.get $id) (i32.const 182))
      (then
        (if (call $is-console-out-port
              (ref.cast (ref $port) (call $arg2 (local.get $args))))
          (then
            (i32.store16 (i32.const 0)
              (call $char-codepoint (ref.cast (ref $char) (call $arg1 (local.get $args)))))
            (call $js-display-string (i32.const 1)))
          (else
            (call $port-write-char
              (ref.cast (ref $port) (call $arg2 (local.get $args)))
              (call $char-codepoint (ref.cast (ref $char) (call $arg1 (local.get $args)))))))
        (return (global.get $void))))

    ;; 183 = %write-string-to-port(string port) — write string to explicit port
    (if (i32.eq (local.get $id) (i32.const 183))
      (then
        (if (call $is-console-out-port
              (ref.cast (ref $port) (call $arg2 (local.get $args))))
          (then
            (call $display-value (call $arg1 (local.get $args))))
          (else
            (call $display-to-port
              (call $arg1 (local.get $args))
              (ref.cast (ref $port) (call $arg2 (local.get $args))))))
        (return (global.get $void))))

    ;; 184 = %initial-output-port() — fresh port wrapping host stdout
    (if (i32.eq (local.get $id) (i32.const 184))
      (then (return (call $get-console-out-port))))

    ;; 185 = %initial-input-port() — fresh port wrapping host stdin
    (if (i32.eq (local.get $id) (i32.const 185))
      (then (return (call $get-console-in-port))))

    ;; 186 = command-line() — browser stub returns ("browser")
    (if (i32.eq (local.get $id) (i32.const 186))
      (then
        (return
          (call $cons
            (array.new_fixed $string 7
              (i32.const 98) (i32.const 114) (i32.const 111)
              (i32.const 119) (i32.const 115) (i32.const 101)
              (i32.const 114))   ;; "browser"
            (global.get $nil)))))

    ;; 187 = exit(code) — browser: signal as unrecoverable error
    (if (i32.eq (local.get $id) (i32.const 187))
      (then
        (call $signal-error-str
          (array.new_fixed $string 4
            (i32.const 101) (i32.const 120) (i32.const 105) (i32.const 116))) ;; "exit"
        (return (global.get $void))))

    ;; 188 = get-environment-variable(name) — browser: no env vars, always #f
    (if (i32.eq (local.get $id) (i32.const 188))
      (then (return (global.get $false))))

    ;; 189 = %exe-path() — browser has no executable path, empty string
    (if (i32.eq (local.get $id) (i32.const 189))
      (then (return (array.new_default $string (i32.const 0)))))

    ;; 190 = %list-directory(path) — no filesystem in browser
    (if (i32.eq (local.get $id) (i32.const 190))
      (then
        (call $signal-error-str
          (array.new_fixed $string 13
            (i32.const 110) (i32.const 111)                       ;; "no"
            (i32.const 32)                                        ;; " "
            (i32.const 102) (i32.const 105) (i32.const 108)       ;; "fil"
            (i32.const 101) (i32.const 115) (i32.const 121)       ;; "esy"
            (i32.const 115) (i32.const 116) (i32.const 101)       ;; "ste"
            (i32.const 109)))                                     ;; "m"
        (return (global.get $void))))

    ;; 191 = %file-exists?(path) — browser: no filesystem, always #f
    (if (i32.eq (local.get $id) (i32.const 191))
      (then (return (global.get $false))))

    ;; 192 = open-binary-input-file(path) — no filesystem in browser
    (if (i32.eq (local.get $id) (i32.const 192))
      (then
        (call $signal-error-str
          (array.new_fixed $string 13
            (i32.const 110) (i32.const 111)                       ;; "no"
            (i32.const 32)                                        ;; " "
            (i32.const 102) (i32.const 105) (i32.const 108)       ;; "fil"
            (i32.const 101) (i32.const 115) (i32.const 121)       ;; "esy"
            (i32.const 115) (i32.const 116) (i32.const 101)       ;; "ste"
            (i32.const 109)))                                     ;; "m"
        (return (global.get $void))))

    ;; 193 = read-byte(port) — browser: not implemented
    (if (i32.eq (local.get $id) (i32.const 193))
      (then
        (call $signal-error-str
          (array.new_fixed $string 13
            (i32.const 110) (i32.const 111)                       ;; "no"
            (i32.const 32)                                        ;; " "
            (i32.const 102) (i32.const 105) (i32.const 108)       ;; "fil"
            (i32.const 101) (i32.const 115) (i32.const 121)       ;; "esy"
            (i32.const 115) (i32.const 116) (i32.const 101)       ;; "ste"
            (i32.const 109)))                                     ;; "m"
        (return (global.get $void))))

    ;; 194 = %make-directory(path) — browser has no filesystem, no-op
    (if (i32.eq (local.get $id) (i32.const 194))
      (then (return (global.get $void))))

    ;; 195 = %chmod(path, mode) — browser has no filesystem, no-op
    (if (i32.eq (local.get $id) (i32.const 195))
      (then (return (global.get $void))))

    ;; 222 = %register-primitive!(name-sym, id-fixnum) — create primitive, define in global env
    (if (i32.eq (local.get $id) (i32.const 222))
      (then
        (call $define-variable!
          (ref.cast (ref $symbol) (call $arg1 (local.get $args)))
          (call $make-primitive
            (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))
          (global.get $global-env))
        (return (global.get $void))))

    ;; 223 = %init-asm-syms(count-fixnum) — allocate assembler symbol ID array
    (if (i32.eq (local.get $id) (i32.const 223))
      (then
        (global.set $asm-sym-ids
          (array.new_default $i32-array
            (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))))
        (return (global.get $void))))

    ;; 224 = %store-asm-sym(slot-fixnum, name-sym) — store symbol ID at slot
    (if (i32.eq (local.get $id) (i32.const 224))
      (then
        (array.set $i32-array
          (ref.as_non_null (global.get $asm-sym-ids))
          (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
          (struct.get $symbol $id
            (ref.cast (ref $symbol) (call $arg2 (local.get $args)))))
        (return (global.get $void))))

    ;; 225 = %set-continuation-syms!(do-winds-sym, winding-stack-sym)
    (if (i32.eq (local.get $id) (i32.const 225))
      (then
        (global.set $do-winds-sym
          (ref.cast (ref $symbol) (call $arg1 (local.get $args))))
        (global.set $winding-stack-sym
          (ref.cast (ref $symbol) (call $arg2 (local.get $args))))
        (return (global.get $void))))

    ;; 226 = %set-error-sym!(error-sym)
    (if (i32.eq (local.get $id) (i32.const 226))
      (then
        (global.set $error-sym
          (ref.cast (ref $symbol) (call $arg1 (local.get $args))))
        (return (global.get $void))))

    ;; 227 = %create-repl-space!(name-sym, size-fixnum) — no-op in the
    ;; per-code-object runtime. Retained so boot-env.scm's calls are
    ;; dispatched without error; the CL host treats this as a no-op too
    ;; (see primitives.scm).
    (if (i32.eq (local.get $id) (i32.const 227))
      (then (return (global.get $void))))

    ;; --- Code-object primitives (IDs 241-249) ---

    ;; 241 = code-object?(x)
    (if (i32.eq (local.get $id) (i32.const 241))
      (then (return (if (result (ref null eq))
        (ref.test (ref $code-object) (call $arg1 (local.get $args)))
        (then (global.get $true)) (else (global.get $false))))))

    ;; 242 = code-object-instructions(co)
    (if (i32.eq (local.get $id) (i32.const 242))
      (then
        (if (i32.eqz (ref.is_null (global.get $co-pending-instrs)))
          (then (call $finalize-co-pending-instrs)))
        (return
          (call $code-object-instructions-vector
            (ref.cast (ref $code-object) (call $arg1 (local.get $args)))))))

    ;; 243 = code-object-resolved-instructions(co) — same as 242 on WASM
    (if (i32.eq (local.get $id) (i32.const 243))
      (then
        (if (i32.eqz (ref.is_null (global.get $co-pending-instrs)))
          (then (call $finalize-co-pending-instrs)))
        (return
          (call $code-object-instructions-vector
            (ref.cast (ref $code-object) (call $arg1 (local.get $args)))))))

    ;; 244 = code-object-length(co)
    (if (i32.eq (local.get $id) (i32.const 244))
      (then (return (call $make-fixnum
        (struct.get $code-object $len
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))))))

    ;; 245 = code-object-label-entries(co) — alist of (label-sym . pc-fixnum)
    (if (i32.eq (local.get $id) (i32.const 245))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (if (ref.is_null (struct.get $code-object $labels
                           (ref.as_non_null (local.get $co-for-labels))))
          (then (return (global.get $nil))))
        (local.set $lbl-ht
          (ref.cast (ref $hash-table)
            (struct.get $code-object $labels
              (ref.as_non_null (local.get $co-for-labels)))))
        (local.set $lbl-keys (struct.get $hash-table $keys
                              (ref.as_non_null (local.get $lbl-ht))))
        (local.set $lbl-vals (struct.get $hash-table $vals
                              (ref.as_non_null (local.get $lbl-ht))))
        (local.set $lbl-count (struct.get $hash-table $count
                                (ref.as_non_null (local.get $lbl-ht))))
        (local.set $lbl-result (global.get $nil))
        (local.set $lbl-i (i32.sub (local.get $lbl-count) (i32.const 1)))
        (block $lblbuild (loop $lblscan
          (br_if $lblbuild (i32.lt_s (local.get $lbl-i) (i32.const 0)))
          (local.set $lbl-result (call $cons
            (call $cons
              (array.get $hash-keys
                (ref.as_non_null (local.get $lbl-keys)) (local.get $lbl-i))
              (array.get $hash-vals
                (ref.as_non_null (local.get $lbl-vals)) (local.get $lbl-i)))
            (local.get $lbl-result)))
          (local.set $lbl-i (i32.sub (local.get $lbl-i) (i32.const 1)))
          (br $lblscan)))
        (return (local.get $lbl-result))))

    ;; 246 = code-object-label-ref(co, label-sym) — pc-fixnum or #f
    (if (i32.eq (local.get $id) (i32.const 246))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (if (ref.is_null (struct.get $code-object $labels
                           (ref.as_non_null (local.get $co-for-labels))))
          (then (return (global.get $false))))
        (local.set $lbl-result
          (call $hash-ref-impl
            (ref.cast (ref $hash-table)
              (struct.get $code-object $labels
                (ref.as_non_null (local.get $co-for-labels))))
            (call $arg2 (local.get $args))))
        (return (if (result (ref null eq)) (ref.is_null (local.get $lbl-result))
          (then (global.get $false))
          (else (local.get $lbl-result))))))

    ;; 247 = code-object-name(co)
    (if (i32.eq (local.get $id) (i32.const 247))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (local.set $lbl-result (struct.get $code-object $name
                                 (ref.as_non_null (local.get $co-for-labels))))
        (return (if (result (ref null eq)) (ref.is_null (local.get $lbl-result))
          (then (global.get $false))
          (else (local.get $lbl-result))))))

    ;; 248 = code-object-native-fn(co)
    (if (i32.eq (local.get $id) (i32.const 248))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (local.set $lbl-result (struct.get $code-object $native-fn
                                 (ref.as_non_null (local.get $co-for-labels))))
        (return (if (result (ref null eq)) (ref.is_null (local.get $lbl-result))
          (then (global.get $false))
          (else (local.get $lbl-result))))))

    ;; 249 = code-object-source-loc(co)
    (if (i32.eq (local.get $id) (i32.const 249))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (local.set $lbl-result (struct.get $code-object $source-loc
                                 (ref.as_non_null (local.get $co-for-labels))))
        (return (if (result (ref null eq)) (ref.is_null (local.get $lbl-result))
          (then (global.get $false))
          (else (local.get $lbl-result))))))

    ;; 250 = %make-code-object() — return a fresh empty code object
    (if (i32.eq (local.get $id) (i32.const 250))
      (then (return (struct.new $code-object
        (array.new_default $instr-vec (i32.const 32))
        (i32.const 0)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)))))

    ;; 251 = %code-object-push-instruction!(co, source-instr)
    ;; Defer parsing until execute-code-object flushes. The entry shape
    ;; is (code-obj pc . instr-list) — pc is captured at push time so a
    ;; later flush knows where to write in the code-object's $instrs vec.
    ;; Increments the code-object's $len eagerly so code-object-length
    ;; reports the right count before any flush.
    (if (i32.eq (local.get $id) (i32.const 251))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        ;; Build entry: (cons co (cons (make-fixnum pc) instr-list))
        (global.set $co-pending-instrs
          (call $cons
            (call $cons
              (local.get $co-for-labels)
              (call $cons
                (call $make-fixnum
                  (struct.get $code-object $len
                    (ref.as_non_null (local.get $co-for-labels))))
                (call $arg2 (local.get $args))))
            (global.get $co-pending-instrs)))
        ;; Bump len
        (struct.set $code-object $len
          (ref.as_non_null (local.get $co-for-labels))
          (i32.add
            (struct.get $code-object $len
              (ref.as_non_null (local.get $co-for-labels)))
            (i32.const 1)))
        (return (global.get $void))))

    ;; 252 = %code-object-set-label!(co, label-sym, local-pc)
    (if (i32.eq (local.get $id) (i32.const 252))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        ;; Ensure labels hash-table exists
        (if (ref.is_null (struct.get $code-object $labels
                           (ref.as_non_null (local.get $co-for-labels))))
          (then
            (struct.set $code-object $labels
              (ref.as_non_null (local.get $co-for-labels))
              (struct.new $hash-table
                (array.new_default $hash-keys (i32.const 16))
                (array.new_default $hash-vals (i32.const 16))
                (i32.const 0)))))
        (call $hash-set-impl
          (ref.cast (ref $hash-table)
            (struct.get $code-object $labels
              (ref.as_non_null (local.get $co-for-labels))))
          (call $arg2 (local.get $args))
          (call $arg3 (local.get $args)))
        (return (global.get $void))))

    ;; 253 = %code-object-set-name!(co, name)
    (if (i32.eq (local.get $id) (i32.const 253))
      (then
        (struct.set $code-object $name
          (ref.cast (ref $code-object) (call $arg1 (local.get $args)))
          (call $arg2 (local.get $args)))
        (return (global.get $void))))

    ;; 254 = %code-object-set-arity!(co, arity)
    (if (i32.eq (local.get $id) (i32.const 254))
      (then
        (struct.set $code-object $arity
          (ref.cast (ref $code-object) (call $arg1 (local.get $args)))
          (call $arg2 (local.get $args)))
        (return (global.get $void))))

    ;; 255 = %code-object-set-source-loc!(co, loc)
    (if (i32.eq (local.get $id) (i32.const 255))
      (then
        (struct.set $code-object $source-loc
          (ref.cast (ref $code-object) (call $arg1 (local.get $args)))
          (call $arg2 (local.get $args)))
        (return (global.get $void))))

    ;; 256 = execute-code-object(co, [env]) — §6.6 runs it on WASM too.
    (if (i32.eq (local.get $id) (i32.const 256))
      (then
        (if (i32.eqz (ref.is_null (global.get $co-pending-instrs)))
          (then (call $finalize-co-pending-instrs)))
        (return (call $execute
          (global.get $global-env)
          (call $arg1 (local.get $args))))))

    ;; 257 = code-object-arity(co)
    (if (i32.eq (local.get $id) (i32.const 257))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (local.set $lbl-result (struct.get $code-object $arity
                                 (ref.as_non_null (local.get $co-for-labels))))
        (return (if (result (ref null eq)) (ref.is_null (local.get $lbl-result))
          (then (global.get $false))
          (else (local.get $lbl-result))))))

    ;; 258 = code-object-archive-key(co)
    (if (i32.eq (local.get $id) (i32.const 258))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (local.set $lbl-result (struct.get $code-object $archive-key
                                 (ref.as_non_null (local.get $co-for-labels))))
        (return (if (result (ref null eq)) (ref.is_null (local.get $lbl-result))
          (then (global.get $false))
          (else (local.get $lbl-result))))))

    ;; 259 = %code-object-set-archive-key!(co, key)
    (if (i32.eq (local.get $id) (i32.const 259))
      (then
        (local.set $co-for-labels
          (ref.cast (ref $code-object) (call $arg1 (local.get $args))))
        (struct.set $code-object $archive-key
          (ref.as_non_null (local.get $co-for-labels))
          (call $arg2 (local.get $args)))
        (return (global.get $void))))

    ;; 260 = %archive-co-lookup(stem, index) — resolve to code-object.
    ;; Reads $archive-registry (populated by $load-archive-impl Pass 1).
    ;; Returns #f on any miss (uninitialized registry, unknown stem, or
    ;; unknown index within a known stem) — matches CL's gethash miss
    ;; semantics; deser/lookup-archive-co then raises
    ;; ece-deser-missing-archive-error with the specific stem+index.
    (if (i32.eq (local.get $id) (i32.const 260))
      (then (return (call $archive-registry-get
        (call $arg1 (local.get $args))
        (call $arg2 (local.get $args))))))

    ;; 261 = %native-zone-register!(unit-key, index, export-ref)
    ;; UNIT-KEY is normalized in src/wasm-host.scm to an interned symbol so
    ;; this identity-keyed hash table can support structured module unit ids.
    (if (i32.eq (local.get $id) (i32.const 261))
      (then
        (call $native-zone-registry-put
          (call $arg1 (local.get $args))
          (call $arg2 (local.get $args))
          (call $arg3 (local.get $args)))
        (return (call $arg3 (local.get $args)))))

    ;; 262 = %native-zone-lookup(unit-key, index)
    (if (i32.eq (local.get $id) (i32.const 262))
      (then (return (call $native-zone-registry-get
        (call $arg1 (local.get $args))
        (call $arg2 (local.get $args))))))

    ;; 263 = %wasm-fetch-text(url) — JS host writes text into memory.
    (if (i32.eq (local.get $id) (i32.const 263))
      (then
        (local.set $wasm-host-string
          (ref.cast (ref $string) (call $arg1 (local.get $args))))
        (local.set $id (array.len (local.get $wasm-host-string)))
        (call $string-to-memory (local.get $wasm-host-string))
        (local.set $id
          (call $js-wasm-fetch-text (i32.const 0) (local.get $id)))
        (return (call $memory-to-string (i32.const 0) (local.get $id)))))

    ;; 264 = %wasm-fetch-bytes(url) — returns an opaque JS bytes ref.
    (if (i32.eq (local.get $id) (i32.const 264))
      (then
        (local.set $wasm-host-string
          (ref.cast (ref $string) (call $arg1 (local.get $args))))
        (local.set $id (array.len (local.get $wasm-host-string)))
        (call $string-to-memory (local.get $wasm-host-string))
        (return (call $make-js-ref
          (call $js-wasm-fetch-bytes (i32.const 0) (local.get $id))))))

    ;; 265 = %wasm-instantiate(bytes-js-ref, imports-js-ref) — returns instance js-ref.
    (if (i32.eq (local.get $id) (i32.const 265))
      (then
        (return (call $make-js-ref
          (call $js-wasm-instantiate
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args))))
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg2 (local.get $args)))))))))

    ;; 266 = %wasm-export(instance-js-ref, name) — returns export js-ref.
    (if (i32.eq (local.get $id) (i32.const 266))
      (then
        (local.set $wasm-host-string
          (ref.cast (ref $string) (call $arg2 (local.get $args))))
        (local.set $id (array.len (local.get $wasm-host-string)))
        (call $string-to-memory (local.get $wasm-host-string))
        (return (call $make-js-ref
          (call $js-wasm-export
            (call $js-ref-idx (ref.cast (ref $js-ref) (call $arg1 (local.get $args))))
            (i32.const 0) (local.get $id))))))

    ;; 267 = %wasm-native-zone-imports() — returns imports js-ref.
    (if (i32.eq (local.get $id) (i32.const 267))
      (then
        (return (call $make-js-ref (call $js-wasm-native-zone-imports)))))

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
    (local $val i64)
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
    ;; Parse integer part using i64 to cleanly hold any integer f64 can
    ;; exactly represent (up to 2^53), in particular the unsigned-valued
    ;; SHA-1 round constants and similar > 2^31 values.
    (local.set $val (i64.extend_i32_s
      (i32.sub (local.get $first-ch) (i32.const 48))))
    (block $done (loop $again
      (local.set $ch (call $ecec-peek))
      (if (i32.and (i32.ge_u (local.get $ch) (i32.const 48))
                   (i32.le_u (local.get $ch) (i32.const 57)))
        (then
          (drop (call $ecec-read))
          (local.set $val (i64.add (i64.mul (local.get $val) (i64.const 10))
                                   (i64.extend_i32_s
                                     (i32.sub (local.get $ch) (i32.const 48)))))
          (br $again)))
      ;; Check for decimal point
      (if (i32.eq (local.get $ch) (i32.const 46))  ;; '.'
        (then
          (local.set $has-dot (i32.const 1))
          (drop (call $ecec-read))))))
    ;; If has decimal point, parse fractional part
    (if (local.get $has-dot)
      (then
        (local.set $fval (f64.convert_i64_s (local.get $val)))
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
    ;; Integer result. Route through $f64-to-ece-number so the fixnum/
    ;; float-box decision matches the rest of the runtime (in particular,
    ;; values outside [-2^29, 2^29-1] are boxed rather than corrupted).
    (if (local.get $neg)
      (then (local.set $val (i64.sub (i64.const 0) (local.get $val)))))
    (call $f64-to-ece-number (f64.convert_i64_s (local.get $val))))

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
    (local $elem (ref null eq))
    (local $acc (ref null eq))    ;; reversed list of elements
    (local $tail (ref null eq))   ;; for dotted pair: the cdr value
    (local $dotted i32)           ;; 1 if dotted pair encountered
    (local.set $acc (global.get $nil))
    (local.set $dotted (i32.const 0))
    (block $done (loop $again
      (call $ecec-skip-ws)
      (local.set $ch (call $ecec-peek))
      ;; End of list?
      (br_if $done (i32.eq (local.get $ch) (i32.const 41)))  ;; )
      ;; Read next element
      (local.set $elem (call $ecec-read-sexp))
      ;; Check for dotted pair
      (call $ecec-skip-ws)
      (if (i32.eq (call $ecec-peek) (i32.const 46))  ;; .
        (then
          (drop (call $ecec-read))
          (local.set $ch (call $ecec-peek))
          (if (i32.or (i32.eq (local.get $ch) (i32.const 32))
                      (i32.eq (local.get $ch) (i32.const 10)))
            (then
              ;; Dotted pair: read cdr, consume )
              (local.set $tail (call $ecec-read-sexp))
              (local.set $acc (call $cons (local.get $elem) (local.get $acc)))
              (local.set $dotted (i32.const 1))
              (call $ecec-skip-ws)
              (br $done)))))
      ;; Regular element: prepend to accumulator
      (local.set $acc (call $cons (local.get $elem) (local.get $acc)))
      (br $again)))
    (drop (call $ecec-read))  ;; consume )
    ;; Build result: fold reversed acc onto tail (nil for proper list, value for dotted)
    (if (local.get $dotted)
      (then
        ;; Dotted pair: fold acc onto (last-elem . tail)
        ;; acc = (last-elem ... e2 e1), tail = cdr-value
        ;; We want (e1 e2 ... last-elem . tail)
        (local.set $elem (local.get $tail))  ;; reuse $elem as fold accumulator
        (block $fold-done (loop $fold
          (br_if $fold-done (call $is-null (local.get $acc)))
          (local.set $elem (call $cons
            (call $xcar (local.get $acc))
            (local.get $elem)))
          (local.set $acc (call $xcdr (local.get $acc)))
          (br $fold)))
        (return (local.get $elem))))
    ;; Proper list: reverse
    (call $prim-reverse (local.get $acc)))

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
        (call $xcar (local.get $cur)))
      (local.set $cur (call $xcdr (local.get $cur)))
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

  ;; Recognize operation name symbol → op ID. Exposed as the $check_op_id
  ;; test export (see below); no longer used for .ecec-format parsing now
  ;; that the compiler emits $code-objects directly.
  (func $ecec-op-id (param $sym (ref $symbol)) (result i32)
    (local $id i32)
    (local $i i32)
    (local.set $id (struct.get $symbol $id (local.get $sym)))
    ;; Op names are in asm-sym-ids slots 17-43 (ops 0-26, from operations.def)
    (local.set $i (i32.const 17))
    (block $done (loop $scan
      (br_if $done (i32.gt_u (local.get $i) (i32.const 43)))
      (if (i32.eq (local.get $id) (array.get $i32-array (ref.as_non_null (global.get $asm-sym-ids)) (local.get $i)))
        (then (return (i32.sub (local.get $i) (i32.const 17)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $scan)))
    (i32.const -1))

  ;; ─── Archive loader helpers (§8 archive format, version 2) ───

  ;; Archive plist walk: find VALUE for KEY-ID in a plist (k1 v1 k2 v2 ...).
  ;; KEY-ID is a symbol-id (i32) compared against symbol-key car eq.
  ;; Returns null if KEY is not present or PLIST runs out.
  (func $archive-plist-get-by-id (param $plist (ref null eq)) (param $key-id i32)
                                 (result (ref null eq))
    (local $cur (ref null eq))
    (local $k (ref null eq))
    (local.set $cur (local.get $plist))
    (block $done (loop $walk
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      (br_if $done (i32.eqz (call $is-pair (local.get $cur))))
      (local.set $k (call $xcar (local.get $cur)))
      (if (call $is-symbol (local.get $k))
        (then
          (if (i32.eq
                (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $k)))
                (local.get $key-id))
            (then
              ;; found key — next cons has the value
              (local.set $cur (call $xcdr (local.get $cur)))
              (br_if $done (ref.is_null (local.get $cur)))
              (br_if $done (call $is-null (local.get $cur)))
              (br_if $done (i32.eqz (call $is-pair (local.get $cur))))
              (return (call $xcar (local.get $cur)))))))
      ;; skip two cells: key and value
      (local.set $cur (call $xcdr (local.get $cur)))
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      (br_if $done (i32.eqz (call $is-pair (local.get $cur))))
      (local.set $cur (call $xcdr (local.get $cur)))
      (br $walk)))
    (ref.null eq))

  ;; Recursive walk: return a new tree identical to TREE except that every
  ;; subtree shaped (const (co-ref N)) is replaced by (const <co-at-N>), where
  ;; N is a non-negative fixnum index into the archive entries. Mirrors the
  ;; CL-side archive-patch-co-refs in src/runtime.lisp — matching only in the
  ;; (const ...) context prevents literal 'co-ref symbols (e.g. the compiled
  ;; form of (quote co-ref) inside the compiler's own source) from being
  ;; misidentified as co-ref forms. Traps if N >= COUNT.
  (func $archive-patch-co-refs (param $tree (ref null eq))
                               (param $cos (ref $co-vec))
                               (param $count i32)
                               (result (ref null eq))
    (local $head (ref null eq))
    (local $cdr1 (ref null eq))
    (local $sub (ref null eq))
    (local $sub-head (ref null eq))
    (local $cdr2 (ref null eq))
    (local $n i32)
    ;; Null or non-pair: return tree unchanged.
    (if (ref.is_null (local.get $tree)) (then (return (local.get $tree))))
    (if (call $is-null (local.get $tree)) (then (return (local.get $tree))))
    (if (i32.eqz (call $is-pair (local.get $tree)))
      (then (return (local.get $tree))))
    ;; Try to match (const (co-ref N)) — flatten via a block we fall out of
    ;; whenever the shape doesn't match. On full match, return early.
    (block $nomatch
      (local.set $head (call $xcar (local.get $tree)))
      (br_if $nomatch (i32.eqz (call $is-symbol (local.get $head))))
      (br_if $nomatch (i32.ne
        (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $head)))
        (global.get $sym-id-const)))
      (local.set $cdr1 (call $xcdr (local.get $tree)))
      (br_if $nomatch (ref.is_null (local.get $cdr1)))
      (br_if $nomatch (i32.eqz (call $is-pair (local.get $cdr1))))
      (local.set $sub (call $xcar (local.get $cdr1)))
      (br_if $nomatch (ref.is_null (local.get $sub)))
      (br_if $nomatch (i32.eqz (call $is-pair (local.get $sub))))
      (local.set $sub-head (call $xcar (local.get $sub)))
      (br_if $nomatch (i32.eqz (call $is-symbol (local.get $sub-head))))
      (br_if $nomatch (i32.ne
        (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $sub-head)))
        (global.get $sym-id-co-ref)))
      (local.set $cdr2 (call $xcdr (local.get $sub)))
      (br_if $nomatch (ref.is_null (local.get $cdr2)))
      (br_if $nomatch (i32.eqz (call $is-pair (local.get $cdr2))))
      ;; Require exact proper-list shapes: (const X) and (co-ref N) — no
      ;; trailing elements. (cdr cdr1) and (cdr cdr2) must both be nil;
      ;; otherwise fall through to general recursion so the subtree is
      ;; traversed as ordinary data.
      (br_if $nomatch (i32.eqz (call $is-null (call $xcdr (local.get $cdr1)))))
      (br_if $nomatch (i32.eqz (call $is-null (call $xcdr (local.get $cdr2)))))
      ;; Full shape match: (const (co-ref N)). Validate N is a fixnum
      ;; in [0, count), then rebuild as (const <co-at-N>).
      (if (i32.eqz (ref.test (ref i31) (call $xcar (local.get $cdr2))))
        (then
          (call $signal-error-str (global.get $err-bad-coref))
          (unreachable)))
      (local.set $n (call $fixnum-value
        (ref.cast (ref i31) (call $xcar (local.get $cdr2)))))
      (if (i32.or
            (i32.lt_s (local.get $n) (i32.const 0))
            (i32.ge_s (local.get $n) (local.get $count)))
        (then
          (call $signal-error-str (global.get $err-bad-coref))
          (unreachable)))
      (return (call $cons
        (local.get $head)
        (call $cons
          (array.get $co-vec (local.get $cos) (local.get $n))
          (global.get $nil)))))
    ;; General case: recurse into car and cdr, cons back.
    (return (call $cons
      (call $archive-patch-co-refs
        (call $xcar (local.get $tree)) (local.get $cos) (local.get $count))
      (call $archive-patch-co-refs
        (call $xcdr (local.get $tree)) (local.get $cos) (local.get $count)))))

  ;; Append an instruction to a code-object's $instrs vec at its current $len.
  ;; Grows the vec if needed.
  (func $co-push-instr (param $co (ref $code-object)) (param $instr (ref $instr))
    (local $vec (ref $instr-vec))
    (local $cap i32)
    (local $len i32)
    (local $newvec (ref $instr-vec))
    (local $j i32)
    (local.set $vec (struct.get $code-object $instrs (local.get $co)))
    (local.set $cap (array.len (local.get $vec)))
    (local.set $len (struct.get $code-object $len (local.get $co)))
    (if (i32.ge_s (local.get $len) (local.get $cap))
      (then
        (local.set $newvec (array.new_default $instr-vec
          (i32.mul (local.get $cap) (i32.const 2))))
        (local.set $j (i32.const 0))
        (block $cpdone (loop $cp
          (br_if $cpdone (i32.ge_s (local.get $j) (local.get $cap)))
          (array.set $instr-vec (local.get $newvec) (local.get $j)
            (array.get $instr-vec (local.get $vec) (local.get $j)))
          (local.set $j (i32.add (local.get $j) (i32.const 1)))
          (br $cp)))
        (struct.set $code-object $instrs (local.get $co) (local.get $newvec))
        (local.set $vec (local.get $newvec))))
    (array.set $instr-vec (local.get $vec) (local.get $len) (local.get $instr))
    (struct.set $code-object $len (local.get $co)
      (i32.add (local.get $len) (i32.const 1))))

  ;; Decode a stored instruction back to ECE data for compiler/codegen tools.
  ;; The runtime executes resolved $instr structs, but code generators need the
  ;; source-shaped vector exposed by `code-object-instructions`. Unsupported
  ;; instruction/source combinations decode to a raw numeric tuple so code
  ;; fingerprints still distinguish different instruction streams.
  (func $asm-sym-ref (param $slot i32) (result (ref $symbol))
    (ref.as_non_null
      (array.get $sym-ref-array
        (ref.as_non_null (global.get $sym-refs))
        (array.get $i32-array
          (ref.as_non_null (global.get $asm-sym-ids))
          (local.get $slot)))))

  (func $reg-id-sym (param $reg-id i32) (result (ref $symbol))
    (call $asm-sym-ref (i32.add (i32.const 7) (local.get $reg-id))))

  (func $decode-operand-sexp (param $operand (ref null eq)) (result (ref null eq))
    (local $p (ref $pair))
    (local $kind i32)
    (local.set $p (ref.cast (ref $pair) (local.get $operand)))
    (local.set $kind
      (call $fixnum-value (ref.cast (ref i31) (call $car (local.get $p)))))
    ;; (const <value>)
    (if (i32.eqz (local.get $kind))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 13))
            (call $cons
              (call $cdr (local.get $p))
              (global.get $nil))))))
    ;; (reg <register>)
    (if (i32.eq (local.get $kind) (i32.const 1))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 14))
            (call $cons
              (call $reg-id-sym
                (call $fixnum-value
                  (ref.cast (ref i31) (call $cdr (local.get $p)))))
              (global.get $nil))))))
    ;; (label <pc>)
    (if (i32.eq (local.get $kind) (i32.const 2))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 15))
            (call $cons
              (call $cdr (local.get $p))
              (global.get $nil))))))
    (local.get $operand))

  (func $decode-operands-sexp (param $operands (ref null eq)) (result (ref null eq))
    (local $result (ref null eq))
    (local $cur (ref null eq))
    (local.set $result (global.get $nil))
    (local.set $cur (local.get $operands))
    (block $done
      (loop $loop
        (br_if $done (ref.is_null (local.get $cur)))
        (br_if $done (call $is-null (local.get $cur)))
        (local.set $result
          (call $cons
            (call $decode-operand-sexp (call $xcar (local.get $cur)))
            (local.get $result)))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $loop)))
    (call $reverse-list (local.get $result)))

  (func $decode-instr-sexp (param $instr (ref null $instr)) (result (ref null eq))
    (local $i (ref $instr))
    (if (ref.is_null (local.get $instr))
      (then (return (global.get $void))))
    (local.set $i (ref.as_non_null (local.get $instr)))
    ;; (assign <reg> (const <value>))
    (if (i32.and
          (i32.eqz (struct.get $instr $opcode (local.get $i)))
          (i32.eqz (struct.get $instr $b (local.get $i))))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 0))
            (call $cons
              (call $reg-id-sym (struct.get $instr $a (local.get $i)))
              (call $cons
                (call $cons
                  (call $asm-sym-ref (i32.const 13))
                  (call $cons
                    (struct.get $instr $val (local.get $i))
                    (global.get $nil)))
                (global.get $nil)))))))
    ;; (assign <reg> (reg <reg>))
    (if (i32.and
          (i32.eqz (struct.get $instr $opcode (local.get $i)))
          (i32.eq (struct.get $instr $b (local.get $i)) (i32.const 1)))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 0))
            (call $cons
              (call $reg-id-sym (struct.get $instr $a (local.get $i)))
              (call $cons
                (call $cons
                  (call $asm-sym-ref (i32.const 14))
                  (call $cons
                    (call $reg-id-sym (struct.get $instr $c (local.get $i)))
                    (global.get $nil)))
                (global.get $nil)))))))
    ;; (assign <reg> (label <pc>))
    (if (i32.and
          (i32.eqz (struct.get $instr $opcode (local.get $i)))
          (i32.eq (struct.get $instr $b (local.get $i)) (i32.const 2)))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 0))
            (call $cons
              (call $reg-id-sym (struct.get $instr $a (local.get $i)))
              (call $cons
                (call $cons
                  (call $asm-sym-ref (i32.const 15))
                  (call $cons
                    (call $make-fixnum (struct.get $instr $c (local.get $i)))
                    (global.get $nil)))
                (global.get $nil)))))))
    ;; (assign <reg> (op <name>) <operands>...)
    (if (i32.and
          (i32.eqz (struct.get $instr $opcode (local.get $i)))
          (i32.eq (struct.get $instr $b (local.get $i)) (i32.const 3)))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 0))
            (call $cons
              (call $reg-id-sym (struct.get $instr $a (local.get $i)))
              (call $cons
                (call $cons
                  (call $asm-sym-ref (i32.const 16))
                  (call $cons
                    (call $asm-sym-ref
                      (i32.add (i32.const 17)
                               (struct.get $instr $c (local.get $i))))
                    (global.get $nil)))
                (call $decode-operands-sexp
                  (struct.get $instr $val (local.get $i)))))))))
    ;; (test (op <name>) <operands>...)
    (if (i32.eq (struct.get $instr $opcode (local.get $i)) (i32.const 1))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 1))
            (call $cons
              (call $cons
                (call $asm-sym-ref (i32.const 16))
                (call $cons
                  (call $asm-sym-ref
                    (i32.add (i32.const 17)
                             (struct.get $instr $c (local.get $i))))
                  (global.get $nil)))
              (call $decode-operands-sexp
                (struct.get $instr $val (local.get $i))))))))
    ;; (branch (label <pc>))
    (if (i32.eq (struct.get $instr $opcode (local.get $i)) (i32.const 2))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 2))
            (call $cons
              (call $cons
                (call $asm-sym-ref (i32.const 15))
                (call $cons
                  (call $make-fixnum (struct.get $instr $c (local.get $i)))
                  (global.get $nil)))
              (global.get $nil))))))
    ;; (goto (label <pc>)) or (goto (reg <reg>))
    (if (i32.eq (struct.get $instr $opcode (local.get $i)) (i32.const 3))
      (then
        (if (i32.eqz (struct.get $instr $b (local.get $i)))
          (then
            (return
              (call $cons
                (call $asm-sym-ref (i32.const 3))
                (call $cons
                  (call $cons
                    (call $asm-sym-ref (i32.const 15))
                    (call $cons
                      (call $make-fixnum (struct.get $instr $c (local.get $i)))
                      (global.get $nil)))
                  (global.get $nil))))))
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 3))
            (call $cons
              (call $cons
                (call $asm-sym-ref (i32.const 14))
                (call $cons
                  (call $reg-id-sym (struct.get $instr $c (local.get $i)))
                  (global.get $nil)))
              (global.get $nil))))))
    ;; (save <reg>)
    (if (i32.eq (struct.get $instr $opcode (local.get $i)) (i32.const 4))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 4))
            (call $cons
              (call $reg-id-sym (struct.get $instr $a (local.get $i)))
              (global.get $nil))))))
    ;; (restore <reg>)
    (if (i32.eq (struct.get $instr $opcode (local.get $i)) (i32.const 5))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 5))
            (call $cons
              (call $reg-id-sym (struct.get $instr $a (local.get $i)))
              (global.get $nil))))))
    ;; (perform (op <name>) <operands>...)
    (if (i32.eq (struct.get $instr $opcode (local.get $i)) (i32.const 6))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 6))
            (call $cons
              (call $cons
                (call $asm-sym-ref (i32.const 16))
                (call $cons
                  (call $asm-sym-ref
                    (i32.add (i32.const 17)
                             (struct.get $instr $c (local.get $i))))
                  (global.get $nil)))
              (call $decode-operands-sexp
                (struct.get $instr $val (local.get $i))))))))
    ;; (halt)
    (if (i32.eq (struct.get $instr $opcode (local.get $i)) (i32.const 7))
      (then
        (return
          (call $cons
            (call $asm-sym-ref (i32.const 44))
            (global.get $nil)))))
    (call $cons
      (call $make-fixnum (struct.get $instr $opcode (local.get $i)))
      (call $cons
        (call $make-fixnum (struct.get $instr $a (local.get $i)))
        (call $cons
          (call $make-fixnum (struct.get $instr $b (local.get $i)))
          (call $cons
            (call $make-fixnum (struct.get $instr $c (local.get $i)))
            (call $cons
              (if (result (ref null eq))
                (ref.is_null (struct.get $instr $val (local.get $i)))
                (then (global.get $nil))
                (else (struct.get $instr $val (local.get $i))))
              (global.get $nil)))))))

  (func $code-object-instructions-vector (param $co (ref $code-object))
                                         (result (ref $vector))
    (local $out (ref $vector))
    (local $instrs (ref $instr-vec))
    (local $len i32)
    (local $i i32)
    (local.set $len (struct.get $code-object $len (local.get $co)))
    (local.set $instrs (struct.get $code-object $instrs (local.get $co)))
    (local.set $out (array.new_default $vector (local.get $len)))
    (block $done
      (loop $loop
        (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
        (array.set $vector
          (local.get $out)
          (local.get $i)
          (call $decode-instr-sexp
            (array.get $instr-vec (local.get $instrs) (local.get $i))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (local.get $out))

  ;; Parse a (ecec-archive version 2 file "..." entries (<entry>...)) sexp
  ;; and return the init code-object (entry 0). Two passes: skeleton first,
  ;; then instructions + co-ref patching. Cursor must be set up before calling
  ;; (either via the load_archive export or a direct $ecec-pos/$ecec-end pair).
  ;;
  ;; Instruction parsing goes through $ece-instr-to-wasm-instr, matching
  ;; §6.6's code-object-based label store. $ece-instr-to-wasm-instr always
  ;; returns a non-null $instr, so we skip bare-symbol "label" rows
  ;; (archives don't emit them, but we guard anyway) before calling.

  ;; Extract the archive's file-stem as an interned symbol.
  ;; Mirrors CL's archive-file-stem-symbol in src/runtime.lisp.
  ;;
  ;; Reads :file from the archive (expected to be a string like
  ;; "boot-env.scm"), strips any trailing dotted extension
  ;; (everything from the last `.` onward), and interns the prefix.
  ;;
  ;; Returns (ref.null eq) if :file is missing or not a string, so
  ;; callers can skip registration rather than erroring — matches CL's
  ;; graceful-degrade behavior.
  (func $archive-file-stem-symbol (param $archive (ref null eq))
                                  (result (ref null eq))
    (local $file (ref null eq))
    (local $name (ref $string))
    (local $len i32)
    (local $last-dot i32)
    (local $i i32)
    (local $stem-len i32)
    (local $stem (ref $string))
    (local.set $file
      (call $archive-plist-get-by-id
        (call $xcdr (local.get $archive))
        (global.get $sym-id-file)))
    ;; Missing or non-string → null.
    (if (ref.is_null (local.get $file)) (then (return (ref.null eq))))
    (if (i32.eqz (call $is-string (local.get $file)))
      (then (return (ref.null eq))))
    (local.set $name (ref.cast (ref $string) (local.get $file)))
    (local.set $len (array.len (local.get $name)))
    ;; Scan for the last `.` (char code 46).
    (local.set $last-dot (i32.const -1))
    (local.set $i (i32.const 0))
    (block $scan-done (loop $scan
      (br_if $scan-done (i32.ge_u (local.get $i) (local.get $len)))
      (if (i32.eq
            (array.get_u $string (local.get $name) (local.get $i))
            (i32.const 46))
        (then (local.set $last-dot (local.get $i))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $scan)))
    ;; Choose stem length: up to last-dot, or full length if no dot.
    (local.set $stem-len
      (if (result i32) (i32.lt_s (local.get $last-dot) (i32.const 0))
        (then (local.get $len))
        (else (local.get $last-dot))))
    ;; Build the stem string by copying $stem-len chars.
    (local.set $stem (array.new_default $string (local.get $stem-len)))
    (local.set $i (i32.const 0))
    (block $copy-done (loop $copy
      (br_if $copy-done (i32.ge_u (local.get $i) (local.get $stem-len)))
      (array.set $string (local.get $stem) (local.get $i)
        (array.get_u $string (local.get $name) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $copy)))
    ;; Intern and return.
    (call $intern (local.get $stem)))

  ;; Put a (stem, index) → co mapping into $archive-registry.
  ;; Lazy-creates the outer hash and per-stem inner hash on first use.
  ;; On re-registration (same stem), reuses the existing inner hash and
  ;; overwrites matching index entries via $hash-set-impl's key-scan.
  ;; Stale entries for indices absent in the re-loaded archive are NOT
  ;; purged — safe for current use (each archive's index space is fixed
  ;; at compile time; archives are loaded once at boot), but a future
  ;; explicit-reload path should clear the inner hash first.
  (func $archive-registry-put (param $stem (ref null eq))
                              (param $index-fx (ref null eq))
                              (param $co (ref $code-object))
    (local $outer (ref null $hash-table))
    (local $inner (ref null eq))
    (local $inner-ht (ref null $hash-table))
    ;; Lazy-create outer.
    (if (ref.is_null (global.get $archive-registry))
      (then
        (global.set $archive-registry
          (struct.new $hash-table
            (array.new_default $hash-keys (i32.const 32))
            (array.new_default $hash-vals (i32.const 32))
            (i32.const 0)))))
    (local.set $outer
      (ref.cast (ref $hash-table) (global.get $archive-registry)))
    ;; Look up existing inner. $hash-ref-impl returns $false (a boolean
    ;; singleton, not a hash-table) if missing — test by ref.test.
    (local.set $inner
      (call $hash-ref-impl (ref.as_non_null (local.get $outer)) (local.get $stem)))
    (if (i32.eqz (ref.test (ref $hash-table) (local.get $inner)))
      (then
        ;; Missing — create an inner hash and insert.
        (local.set $inner-ht
          (struct.new $hash-table
            (array.new_default $hash-keys (i32.const 32))
            (array.new_default $hash-vals (i32.const 32))
            (i32.const 0)))
        (call $hash-set-impl (ref.as_non_null (local.get $outer))
          (local.get $stem) (ref.as_non_null (local.get $inner-ht))))
      (else
        (local.set $inner-ht
          (ref.cast (ref $hash-table) (local.get $inner)))))
    ;; Insert (index → co) into inner. $hash-set-impl overwrites on
    ;; matching key per its existing semantics.
    (call $hash-set-impl (ref.as_non_null (local.get $inner-ht))
      (local.get $index-fx) (local.get $co)))

  ;; Look up (stem, index) in $archive-registry.
  ;; Returns $false on any miss (uninitialized registry, unknown stem,
  ;; or unknown index within a known stem). Matches CL's gethash
  ;; miss behavior.
  (func $archive-registry-get (param $stem (ref null eq))
                              (param $index-fx (ref null eq))
                              (result (ref null eq))
    (local $outer (ref null $hash-table))
    (local $inner (ref null eq))
    (if (ref.is_null (global.get $archive-registry))
      (then (return (global.get $false))))
    (local.set $outer
      (ref.cast (ref $hash-table) (global.get $archive-registry)))
    (local.set $inner
      (call $hash-ref-impl (ref.as_non_null (local.get $outer)) (local.get $stem)))
    (if (i32.eqz (ref.test (ref $hash-table) (local.get $inner)))
      (then (return (global.get $false))))
    (call $hash-ref-impl
      (ref.cast (ref $hash-table) (local.get $inner))
      (local.get $index-fx)))

  (func $native-zone-registry-put (param $unit-key (ref null eq))
                                  (param $index-fx (ref null eq))
                                  (param $export-ref (ref null eq))
    (local $outer (ref null $hash-table))
    (local $inner (ref null eq))
    (local $inner-ht (ref null $hash-table))
    (if (ref.is_null (global.get $native-zone-registry))
      (then
        (global.set $native-zone-registry
          (struct.new $hash-table
            (array.new_default $hash-keys (i32.const 32))
            (array.new_default $hash-vals (i32.const 32))
            (i32.const 0)))))
    (local.set $outer
      (ref.cast (ref $hash-table) (global.get $native-zone-registry)))
    (local.set $inner
      (call $hash-ref-impl (ref.as_non_null (local.get $outer)) (local.get $unit-key)))
    (if (i32.eqz (ref.test (ref $hash-table) (local.get $inner)))
      (then
        (local.set $inner-ht
          (struct.new $hash-table
            (array.new_default $hash-keys (i32.const 32))
            (array.new_default $hash-vals (i32.const 32))
            (i32.const 0)))
        (call $hash-set-impl (ref.as_non_null (local.get $outer))
          (local.get $unit-key) (ref.as_non_null (local.get $inner-ht))))
      (else
        (local.set $inner-ht
          (ref.cast (ref $hash-table) (local.get $inner)))))
    (call $hash-set-impl (ref.as_non_null (local.get $inner-ht))
      (local.get $index-fx) (local.get $export-ref)))

  (func $native-zone-registry-get (param $unit-key (ref null eq))
                                  (param $index-fx (ref null eq))
                                  (result (ref null eq))
    (local $outer (ref null $hash-table))
    (local $inner (ref null eq))
    (if (ref.is_null (global.get $native-zone-registry))
      (then (return (global.get $false))))
    (local.set $outer
      (ref.cast (ref $hash-table) (global.get $native-zone-registry)))
    (local.set $inner
      (call $hash-ref-impl (ref.as_non_null (local.get $outer)) (local.get $unit-key)))
    (if (i32.eqz (ref.test (ref $hash-table) (local.get $inner)))
      (then (return (global.get $false))))
    (call $hash-ref-impl
      (ref.cast (ref $hash-table) (local.get $inner))
      (local.get $index-fx)))

  (func $load-archive-impl (result (ref $code-object))
    (local $archive (ref null eq))
    (local $head (ref null eq))
    (local $version (ref null eq))
    (local $entries (ref null eq))
    (local $count i32)
    (local $i i32)
    (local $cos (ref $co-vec))
    (local $entry (ref null eq))
    (local $fields (ref null eq))
    (local $co (ref $code-object))
    (local $labels-alist (ref null eq))
    (local $label-pair (ref null eq))
    (local $labels-ht (ref $hash-table))
    (local $raw-instrs (ref null eq))
    (local $instr-sexp (ref null eq))
    (local $patched (ref null eq))
    (local $parsed-instr (ref $instr))
    (local $entries-iter (ref null eq))
    (local $stem (ref null eq))

    ;; Read archive sexp.
    (local.set $archive (call $ecec-read-sexp))
    ;; Head symbol check: (ecec-archive ...)
    (local.set $head (call $xcar (local.get $archive)))
    (if (i32.eq
          (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $head)))
          (global.get $sym-id-ecec-header))
      (then
        (call $signal-error-str (global.get $err-legacy-arch))
        (unreachable)))
    (if (i32.ne
          (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $head)))
          (global.get $sym-id-ecec-archive))
      (then
        (call $signal-error-str (global.get $err-unknown-arch))
        (unreachable)))

    ;; Version check: must be 2.
    (local.set $version
      (call $archive-plist-get-by-id (call $xcdr (local.get $archive))
            (global.get $sym-id-version)))
    (if (i32.ne (call $fixnum-value (ref.cast (ref i31) (local.get $version)))
                (i32.const 2))
      (then
        (call $signal-error-str (global.get $err-bad-version))
        (unreachable)))

    ;; Entries list.
    (local.set $entries
      (call $archive-plist-get-by-id (call $xcdr (local.get $archive))
            (global.get $sym-id-entries)))

    ;; Count entries. Stops at the first null/non-pair; an improper tail
    ;; (atom != nil) is treated the same as an empty list and rejected
    ;; below so we never dereference garbage.
    (local.set $count (i32.const 0))
    (local.set $entries-iter (local.get $entries))
    (block $cdone (loop $ccount
      (br_if $cdone (ref.is_null (local.get $entries-iter)))
      (br_if $cdone (call $is-null (local.get $entries-iter)))
      (br_if $cdone (i32.eqz (call $is-pair (local.get $entries-iter))))
      (local.set $count (i32.add (local.get $count) (i32.const 1)))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (br $ccount)))

    ;; Guard: entries must be a non-empty proper list. An empty or missing
    ;; `entries` plist value would otherwise trap in the final
    ;; (array.get $co-vec ... (i32.const 0)) with an opaque bounds error.
    ;; Improper lists (non-null, non-pair tail) are also rejected.
    (if (i32.eqz (local.get $count))
      (then
        (call $signal-error-str (global.get $err-empty-entries))
        (unreachable)))
    (if (i32.and
          (i32.eqz (ref.is_null (local.get $entries-iter)))
          (i32.eqz (call $is-null (local.get $entries-iter))))
      (then
        (call $signal-error-str (global.get $err-empty-entries))
        (unreachable)))

    ;; Extract archive file-stem once for archive-key stamping + registry.
    ;; Null when :file is missing/non-string → Pass 1 below skips stamping.
    (local.set $stem (call $archive-file-stem-symbol (local.get $archive)))

    ;; Allocate code-object vector.
    (local.set $cos (array.new $co-vec (ref.null eq) (local.get $count)))

    ;; ─── Pass 1: skeletons ───
    (local.set $i (i32.const 0))
    (local.set $entries-iter (local.get $entries))
    (block $done1 (loop $pass1
      (br_if $done1 (i32.ge_s (local.get $i) (local.get $count)))
      (local.set $entry (call $xcar (local.get $entries-iter)))
      ;; Entry shape: (code-object name <v> arity <v> source-loc <v> labels <alist> instructions <list>)
      (local.set $fields (call $xcdr (local.get $entry)))
      (local.set $co (struct.new $code-object
        (array.new_default $instr-vec (i32.const 32))
        (i32.const 0)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)))
      ;; Set name / arity / source-loc (may all be #f/null).
      (struct.set $code-object $name (local.get $co)
        (call $archive-plist-get-by-id (local.get $fields)
              (global.get $sym-id-arch-name)))
      (struct.set $code-object $arity (local.get $co)
        (call $archive-plist-get-by-id (local.get $fields)
              (global.get $sym-id-arch-arity)))
      (struct.set $code-object $source-loc (local.get $co)
        (call $archive-plist-get-by-id (local.get $fields)
              (global.get $sym-id-source-loc)))
      ;; Walk labels alist and populate the code-object's label hash table.
      (local.set $labels-alist
        (call $archive-plist-get-by-id (local.get $fields)
              (global.get $sym-id-labels)))
      ;; Create an empty hash-table up front so $ece-instr-to-wasm-instr sees
      ;; a non-null labels-ht even when the code-object has no labels.
      (local.set $labels-ht (struct.new $hash-table
        (array.new_default $hash-keys (i32.const 16))
        (array.new_default $hash-vals (i32.const 16))
        (i32.const 0)))
      (struct.set $code-object $labels (local.get $co) (local.get $labels-ht))
      (block $ldone (loop $lwalk
        (br_if $ldone (ref.is_null (local.get $labels-alist)))
        (br_if $ldone (call $is-null (local.get $labels-alist)))
        (br_if $ldone (i32.eqz (call $is-pair (local.get $labels-alist))))
        (local.set $label-pair (call $xcar (local.get $labels-alist)))
        (call $hash-set-impl
          (local.get $labels-ht)
          (call $xcar (local.get $label-pair))
          (call $xcdr (local.get $label-pair)))
        (local.set $labels-alist (call $xcdr (local.get $labels-alist)))
        (br $lwalk)))
      (array.set $co-vec (local.get $cos) (local.get $i) (local.get $co))
      ;; Stamp archive-key = (stem . index-fixnum) and register in the
      ;; archive registry. Skip when stem is null (archive missing :file)
      ;; — matches CL's skip-registration semantics.
      (if (i32.eqz (ref.is_null (local.get $stem)))
        (then
          (struct.set $code-object $archive-key (local.get $co)
            (call $cons
              (local.get $stem)
              (call $make-fixnum (local.get $i))))
          (call $archive-registry-put
            (local.get $stem)
            (call $make-fixnum (local.get $i))
            (local.get $co))))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $pass1)))

    ;; ─── Pass 2: instructions ───
    (local.set $i (i32.const 0))
    (local.set $entries-iter (local.get $entries))
    (block $done2 (loop $pass2
      (br_if $done2 (i32.ge_s (local.get $i) (local.get $count)))
      (local.set $entry (call $xcar (local.get $entries-iter)))
      (local.set $fields (call $xcdr (local.get $entry)))
      (local.set $co
        (ref.cast (ref $code-object)
          (array.get $co-vec (local.get $cos) (local.get $i))))
      (local.set $raw-instrs
        (call $archive-plist-get-by-id (local.get $fields)
              (global.get $sym-id-instructions)))
      (block $idone (loop $iwalk
        (br_if $idone (ref.is_null (local.get $raw-instrs)))
        (br_if $idone (call $is-null (local.get $raw-instrs)))
        (br_if $idone (i32.eqz (call $is-pair (local.get $raw-instrs))))
        (local.set $instr-sexp (call $xcar (local.get $raw-instrs)))
        ;; Bare symbol = defensive label row; archives don't emit them, skip.
        (if (i32.eqz (call $is-symbol (local.get $instr-sexp)))
          (then
            (local.set $patched
              (call $archive-patch-co-refs
                (local.get $instr-sexp) (local.get $cos) (local.get $count)))
            (local.set $parsed-instr
              (call $ece-instr-to-wasm-instr
                (local.get $patched)
                (struct.get $code-object $labels (local.get $co))))
            (call $co-push-instr (local.get $co) (local.get $parsed-instr))))
        (local.set $raw-instrs (call $xcdr (local.get $raw-instrs)))
        (br $iwalk)))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $pass2)))

    ;; Return entry 0 = init code-object. Invariant: count > 0 here — the
    ;; empty/improper-entries guard above signals $err-empty-entries and
    ;; traps, so this array.get is always within bounds.
    (ref.cast (ref $code-object)
      (array.get $co-vec (local.get $cos) (i32.const 0))))

  ;; Archive-format entry point. Returns a handle wrapping the init code-object.
  (func (export "load_archive") (param $offset i32) (param $len i32) (result i32)
    (global.set $ecec-pos (local.get $offset))
    (global.set $ecec-end (i32.add (local.get $offset) (local.get $len)))
    (call $alloc-handle (call $load-archive-impl)))

  ;; Continue loading the next archive from the current cursor position.
  ;; Used by the JS glue to load multi-archive bootstrap bundles one archive
  ;; at a time, executing each init code-object so its definitions are
  ;; available to the next archive.
  (func (export "load_archive_continue") (result i32)
    (call $alloc-handle (call $load-archive-impl)))

  ;; 1 iff the archive cursor has not reached end, 0 otherwise. Used by
  ;; the JS glue to iterate over a multi-archive bundle.
  (func (export "archive_has_more") (result i32)
    (i32.lt_u (global.get $ecec-pos) (global.get $ecec-end)))

  ;; Run an init code-object with the given environment handle.
  (func (export "run_code_object") (param $co-handle i32) (param $env-handle i32)
        (result i32)
    (call $alloc-handle
      (call $execute
        (call $deref-handle (local.get $env-handle))
        (call $deref-handle (local.get $co-handle)))))


  ;; ═══════════════════════════════════════════════════════════════════
  ;; Section 10: JS ↔ WASM Interop (Handle Table)
  ;; ═══════════════════════════════════════════════════════════════════
  ;; WasmGC refs can't cross the JS/WASM boundary directly.
  ;; We use a handle table: WASM stores (ref eq) values, JS gets i32 indices.
  ;; JS calls exported functions with i32 handles, WASM resolves them.

  ;; 1 page = 64KB linear memory for string transfer only
  (memory $transfer (export "memory") 1)

  ;; ── Source location for error messages ──
  ;; Set by the executor before signaling errors.
  (global $error-pc (mut i32) (i32.const -1))

  ;; Write an ECE $string to linear memory starting at byte offset $off.
  ;; Returns the number of chars written.
  (func $mem-write-string (param $str (ref $string)) (param $off i32) (result i32)
    (local $len i32)
    (local $i i32)
    (local.set $len (array.len (local.get $str)))
    (local.set $i (i32.const 0))
    (block $done (loop $copy
      (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
      (i32.store16 (i32.add (local.get $off) (i32.shl (local.get $i) (i32.const 1)))
        (array.get_u $string (local.get $str) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $copy)))
    (local.get $len))

  ;; Write an integer (decimal) to linear memory starting at char offset $off.
  ;; Returns the number of chars written.
  (func $mem-write-int (param $n i32) (param $off i32) (result i32)
    (local $digits i32)
    (local $tmp i32)
    (local $pos i32)
    ;; Count digits
    (local.set $tmp (local.get $n))
    (local.set $digits (i32.const 1))
    (block $cnt-done (loop $cnt
      (local.set $tmp (i32.div_u (local.get $tmp) (i32.const 10)))
      (br_if $cnt-done (i32.eqz (local.get $tmp)))
      (local.set $digits (i32.add (local.get $digits) (i32.const 1)))
      (br $cnt)))
    ;; Write digits right-to-left
    (local.set $tmp (local.get $n))
    (local.set $pos (i32.sub (i32.add (local.get $off) (local.get $digits)) (i32.const 1)))
    (block $wr-done (loop $wr
      (i32.store16 (i32.shl (local.get $pos) (i32.const 1))
        (i32.add (i32.const 48) (i32.rem_u (local.get $tmp) (i32.const 10))))
      (local.set $tmp (i32.div_u (local.get $tmp) (i32.const 10)))
      (local.set $pos (i32.sub (local.get $pos) (i32.const 1)))
      (br_if $wr (i32.gt_s (local.get $pos) (i32.sub (local.get $off) (i32.const 1))))
    ))
    (local.get $digits))

  ;; ── Runtime error helpers ──
  ;; Write a plain string to linear memory, then call runtime_error.
  ;; TODO (archive-loader follow-up): re-introduce per-code-object
  ;; source-map lookup for error decoration once archive format ships it.
  (func $signal-error-str (param $msg (ref $string))
    (local $len i32)
    (local $i i32)
    ;; Write main message
    (local.set $len (array.len (local.get $msg)))
    (local.set $i (i32.const 0))
    (block $done (loop $copy
      (br_if $done (i32.ge_u (local.get $i) (local.get $len)))
      (i32.store16 (i32.shl (local.get $i) (i32.const 1))
        (array.get_u $string (local.get $msg) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $copy)))
    ;; Reset error location
    (global.set $error-pc (i32.const -1))
    (call $js-runtime-error (local.get $len)))

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
  (func (export "h_false_p") (param $handle i32) (result i32)
    (call $is-false (call $deref-handle (local.get $handle))))
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

  (func (export "h_symbol_1") (param $cp i32) (result i32)
    (local $str (ref $string))
    (local.set $str (array.new_default $string (i32.const 1)))
    (array.set $string (local.get $str) (i32.const 0) (local.get $cp))
    (call $alloc-handle (call $intern (local.get $str))))

  (func (export "h_symbol_from_chars") (param $chars-handle i32) (result i32)
    (local $chars (ref null eq))
    (local $cur (ref null eq))
    (local $str (ref $string))
    (local $len i32)
    (local $i i32)
    (local $ch (ref $char))
    (local.set $chars (call $deref-handle (local.get $chars-handle)))
    (local.set $cur (local.get $chars))
    (block $counted
      (loop $count
        (br_if $counted (ref.is_null (local.get $cur)))
        (br_if $counted (call $is-null (local.get $cur)))
        (local.set $len (i32.add (local.get $len) (i32.const 1)))
        (local.set $cur (call $xcdr (local.get $cur)))
        (br $count)))
    (local.set $str (array.new_default $string (local.get $len)))
    (local.set $cur (local.get $chars))
    (local.set $i (i32.const 0))
    (block $filled
      (loop $fill
        (br_if $filled (i32.ge_u (local.get $i) (local.get $len)))
        (local.set $ch (ref.cast (ref $char) (call $xcar (local.get $cur))))
        (array.set $string (local.get $str) (local.get $i)
          (call $char-codepoint (local.get $ch)))
        (local.set $cur (call $xcdr (local.get $cur)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $fill)))
    (call $alloc-handle (call $intern (local.get $str))))

  (func (export "h_lookup") (param $name-handle i32) (param $env-handle i32) (result i32)
    (call $alloc-handle
      (call $lookup-variable-value
        (ref.cast (ref $symbol) (call $deref-handle (local.get $name-handle)))
        (call $deref-handle (local.get $env-handle)))))

  (func (export "h_primitive_p") (param $handle i32) (result i32)
    (call $is-primitive (call $deref-handle (local.get $handle))))

  (func (export "h_continuation_p") (param $handle i32) (result i32)
    (call $is-continuation (call $deref-handle (local.get $handle))))

  (func (export "h_parameter_p") (param $handle i32) (result i32)
    (call $is-parameter (call $deref-handle (local.get $handle))))

  (func (export "h_compiled_entry") (param $proc-handle i32) (result i32)
    (local $proc (ref null eq))
    (local.set $proc (call $deref-handle (local.get $proc-handle)))
    (if (i32.eqz (ref.test (ref $compiled-proc) (local.get $proc)))
      (then
        (return (call $alloc-handle
          (call $make-type-error
            (global.get $name-compiled-procedure-entry)
            (global.get $err-not-compiled-procedure)
            (local.get $proc))))))
    (call $alloc-handle
      (struct.get $compiled-proc $code-obj
        (ref.cast (ref $compiled-proc)
          (local.get $proc)))))

  (func (export "h_apply_primitive") (param $prim-handle i32) (param $args-handle i32) (result i32)
    (call $alloc-handle
      (call $apply-primitive
        (ref.cast (ref $primitive) (call $deref-handle (local.get $prim-handle)))
        (call $deref-handle (local.get $args-handle)))))

  (func (export "h_error_sentinel_p") (param $handle i32) (result i32)
    (ref.test (ref $error-sentinel) (call $deref-handle (local.get $handle))))

  (func (export "h_primitive") (param $id i32) (result i32)
    (call $alloc-handle (call $make-primitive (local.get $id))))

  ;; Create an instruction struct
  (func (export "make_instr") (param $opcode i32) (param $a i32)
        (param $b i32) (param $c i32) (param $val-handle i32) (result i32)
    (call $alloc-handle
      (struct.new $instr
        (local.get $opcode) (local.get $a) (local.get $b) (local.get $c)
        (call $deref-handle (local.get $val-handle)))))

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
      (call $try-lookup-variable-value
        (ref.cast (ref $symbol) (call $deref-handle (local.get $name-handle)))
        (call $deref-handle (local.get $env-handle)))))

  ;; Call a compiled procedure with an argument list (returns handle)
  (func (export "call_ece_proc") (param $proc-handle i32) (param $args-handle i32) (result i32)
    (global.set $execute-argl (call $deref-handle (local.get $args-handle)))
    (global.set $execute-proc (call $deref-handle (local.get $proc-handle)))
    (call $alloc-handle
      (call $execute
        (call $compiled-proc-env
          (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $proc-handle))))
        (struct.get $compiled-proc $code-obj
          (ref.cast (ref $compiled-proc) (call $deref-handle (local.get $proc-handle)))))))

  ;; Resume a captured continuation with a value (returns handle).
  ;; Continuation's $conts is a (code-obj . pc) pair after the per-code-object
  ;; refactor — see op 18 / capture-continuation.
  (func (export "call_continuation") (param $cont-handle i32) (param $val-handle i32) (result i32)
    (local $cont (ref $continuation))
    (local $conts (ref $pair))
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
        (else (call $try-lookup-variable-value
          (ref.as_non_null (global.get $winding-stack-sym))
          (global.get $global-env)))))
    (if (ref.is_null (local.get $current-winds))
      (then (local.set $current-winds (global.get $nil))))
    (if (i32.eqz (ref.eq (local.get $current-winds) (local.get $saved-winds)))
      (then
        (if (i32.eqz (i32.and (call $is-null (local.get $current-winds))
                               (call $is-null (local.get $saved-winds))))
          (then
            (local.set $do-winds-fn (call $try-lookup-variable-value
              (ref.as_non_null (global.get $do-winds-sym))
              (global.get $global-env)))
            (global.set $execute-argl
              (call $cons (local.get $current-winds)
                (call $cons (local.get $saved-winds) (global.get $nil))))
            (global.set $execute-proc (local.get $do-winds-fn))
            (drop (call $execute
              (call $compiled-proc-env (ref.cast (ref $compiled-proc) (local.get $do-winds-fn)))
              (struct.get $compiled-proc $code-obj
                (ref.cast (ref $compiled-proc) (local.get $do-winds-fn)))))))))
    ;; conts = saved continue register = (code-obj . pc).
    (local.set $conts (ref.cast (ref $pair)
      (struct.get $continuation $conts (local.get $cont))))
    ;; Set up executor: val = resume value, stack = saved stack, start-pc
    ;; tells $execute to begin at the saved pc in the saved code-object.
    (global.set $execute-val (call $deref-handle (local.get $val-handle)))
    (global.set $execute-stack (struct.get $continuation $stack (local.get $cont)))
    (global.set $execute-init-pc
      (call $fixnum-value (ref.cast (ref i31) (call $cdr (local.get $conts)))))
    (call $alloc-handle
      (call $execute (global.get $global-env) (call $car (local.get $conts)))))

  ;; Debug: inspect instruction at a code-object handle + pc
  (func (export "dbg_instr") (param $co-handle i32) (param $pc i32) (param $field i32) (result i32)
    (local $co (ref $code-object))
    (local $instr (ref $instr))
    (local.set $co (ref.cast (ref $code-object) (call $deref-handle (local.get $co-handle))))
    (local.set $instr (ref.as_non_null
      (array.get $instr-vec
        (struct.get $code-object $instrs (local.get $co))
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
  ;; Returns the op-id (0-26) or -1 if unrecognized.
  (func (export "check_op_id") (param $sym-handle i32) (result i32)
    (call $ecec-op-id (ref.cast (ref $symbol)
      (call $deref-handle (local.get $sym-handle)))))

  ;; Test export: trigger runtime_error with "Unbound variable: <sym>"
  (func (export "test_runtime_error") (param $sym-handle i32)
    (call $signal-error-sym (global.get $err-unbound-var)
      (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle)))))

  ;; Test export: call $lookup-variable-value on a symbol and report whether
  ;; the result is an error sentinel. 1 = sentinel, 0 = normal binding.
  (func (export "test_lookup_returns_sentinel") (param $sym-handle i32) (result i32)
    (local $result (ref eq))
    (local.set $result (call $lookup-variable-value
      (ref.cast (ref $symbol) (call $deref-handle (local.get $sym-handle)))
      (global.get $global-env)))
    (if (result i32) (ref.test (ref $error-sentinel) (local.get $result))
      (then (i32.const 1))
      (else (i32.const 0))))

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
      (local.set $s (call $xcdr (local.get $s)))
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


  ;; Debug: last executed PC and opcode (for crash diagnosis)
  (global $dbg-pc (mut i32) (i32.const -1))
  (global $dbg-opcode (mut i32) (i32.const -1))
  (func (export "dbg_pc") (result i32) (global.get $dbg-pc))
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
    (call $alloc-handle (call $xcar (call $deref-handle (local.get $handle)))))

  (func (export "pair_cdr") (param $handle i32) (result i32)
    (call $alloc-handle (call $xcdr (call $deref-handle (local.get $handle)))))

  ;; Module-init hook: populate the ASCII intern table before any code runs.
  (start $init-ascii-chars)
)
