;;; boot-env.scm — ECE environment initialization
;;;
;;; This file is compiled to boot-env.ecec and loads FIRST in the
;;; bootstrap sequence, before prelude.ecec. It registers all host
;;; primitives in the global environment, sets up the assembler symbol
;;; table, caches continuation/error symbols, and creates the REPL
;;; compilation space.
;;;
;;; CONSTRAINTS:
;;;   - NO macros (prelude hasn't loaded yet)
;;;   - NO prelude functions (this runs first)
;;;   - Only core special forms: define, begin, if, quote, lambda, set!
;;;   - The 6 boot-registration primitives (%register-primitive! etc.)
;;;     must be pre-registered by the host before this file executes.
;;;
;;; Data is baked in as literals from primitives.def and operations.def
;;; at compile time. The .def files remain the single source of truth.

;;; ═══════════════════════════════════════════════════════════════════
;;; 1. Register all core + browser primitives
;;; ═══════════════════════════════════════════════════════════════════
;;; Generated from primitives.def — core and browser platform entries.

;; --- Arithmetic ---
(%register-primitive! '+ 0)
(%register-primitive! '- 1)
(%register-primitive! '* 2)
(%register-primitive! '/ 3)

;; --- Pair operations ---
(%register-primitive! 'car 5)
(%register-primitive! 'cdr 6)
(%register-primitive! 'cons 7)
(%register-primitive! 'list 8)
(%register-primitive! 'set-car! 9)
(%register-primitive! 'set-cdr! 10)

;; --- Type predicates ---
(%register-primitive! 'null? 11)
(%register-primitive! 'pair? 12)
(%register-primitive! 'number? 13)
(%register-primitive! 'string? 14)
(%register-primitive! 'symbol? 15)
(%register-primitive! 'integer? 16)
(%register-primitive! 'char? 17)
(%register-primitive! 'vector? 18)

;; --- Equality and comparison ---
(%register-primitive! 'eq? 20)
(%register-primitive! '= 22)
(%register-primitive! '< 23)
(%register-primitive! '> 24)

;; --- String operations ---
(%register-primitive! 'string-length 25)
(%register-primitive! 'string-ref 26)
(%register-primitive! 'string-append 27)
(%register-primitive! 'substring 28)
(%register-primitive! 'string->symbol 31)
(%register-primitive! 'symbol->string 32)
(%register-primitive! 'string 42)

;; --- Character operations ---
(%register-primitive! 'char->integer 43)
(%register-primitive! 'integer->char 44)

;; --- Vector operations ---
(%register-primitive! 'make-vector 50)
(%register-primitive! 'vector 51)
(%register-primitive! 'vector-ref 52)
(%register-primitive! 'vector-set! 53)
(%register-primitive! 'vector-length 54)

;; --- I/O operations ---
(%register-primitive! 'read-char 60)
(%register-primitive! 'peek-char 61)
(%register-primitive! 'read-line 63)
(%register-primitive! 'char-ready? 64)
(%register-primitive! 'eof? 65)
(%register-primitive! 'write-to-string 67)

;; --- Port operations ---
(%register-primitive! 'input-port? 68)
(%register-primitive! 'output-port? 69)
(%register-primitive! 'port? 70)
(%register-primitive! 'open-input-string 73)
(%register-primitive! 'close-input-port 74)
(%register-primitive! 'close-output-port 75)

;; --- Bitwise operations ---
(%register-primitive! 'bitwise-and 76)
(%register-primitive! 'bitwise-or 77)
(%register-primitive! 'bitwise-xor 78)
(%register-primitive! 'bitwise-not 79)
(%register-primitive! 'arithmetic-shift 80)

;; --- Error handling ---
(%register-primitive! '%raw-error 81)

;; --- Miscellaneous ---
(%register-primitive! 'sleep 83)
(%register-primitive! 'clear-screen 84)

;; --- Compiler support ---
(%register-primitive! 'execute-from-pc 85)
(%register-primitive! 'get-macro 86)
(%register-primitive! 'set-macro! 87)
(%register-primitive! 'make-parameter 88)
(%register-primitive! 'apply-compiled-procedure 89)
(%register-primitive! 'try-eval 90)
(%register-primitive! 'extend-environment 91)

;; --- Instruction vector / assembler support ---
(%register-primitive! '%intern-ece 92)
(%register-primitive! '%instruction-vector-length 93)
(%register-primitive! '%instruction-vector-push! 94)
(%register-primitive! '%label-table-set! 95)
(%register-primitive! '%label-table-ref 96)
(%register-primitive! '%procedure-name-set! 97)

;; --- Platform discovery ---
(%register-primitive! 'platform-has? 98)
(%register-primitive! '%platform-primitives 99)

;; --- File I/O ---
(%register-primitive! 'open-input-file 100)
(%register-primitive! 'open-output-file 101)
(%register-primitive! 'with-input-from-file 102)
(%register-primitive! 'with-output-to-file 103)

;; --- Integer rounding ---
(%register-primitive! 'truncate 108)
(%register-primitive! 'floor 109)
(%register-primitive! 'exact->inexact 110)
(%register-primitive! 'parameter? 114)

;; --- Hash table (eq hash) ---
(%register-primitive! '%eq-hash-table 116)
(%register-primitive! '%eq-hash-ref 117)
(%register-primitive! '%eq-hash-set! 118)
(%register-primitive! '%hash-frame? 121)

;; --- Compilation spaces ---
(%register-primitive! '%create-space 125)
(%register-primitive! '%space-instruction-length 126)
(%register-primitive! '%space-name 127)
(%register-primitive! '%current-space-id 128)
(%register-primitive! '%set-current-space-id! 129)
(%register-primitive! '%space-instruction-push! 130)
(%register-primitive! '%space-label-set! 131)
(%register-primitive! '%space-label-ref 132)
(%register-primitive! '%space-count 133)
(%register-primitive! '%space-source-ref 134)
(%register-primitive! '%space-label-entries 135)

;; --- Miscellaneous core ---
(%register-primitive! 'write-to-string-flat 136)
(%register-primitive! 'keyword? 137)
(%register-primitive! '%primitive-name 138)
(%register-primitive! '%primitive-id 139)
(%register-primitive! '%global-env-frame 140)

;; --- Hash table (general) ---
(%register-primitive! '%make-hash-table 141)
(%register-primitive! 'hash-table? 142)
(%register-primitive! 'hash-ref 143)
(%register-primitive! 'hash-set! 144)
(%register-primitive! 'hash-remove! 145)
(%register-primitive! 'hash-has-key? 146)
(%register-primitive! 'hash-keys 147)
(%register-primitive! 'hash-values 148)
(%register-primitive! 'hash-count 149)

;; --- Yield and timing ---
(%register-primitive! '%yield! 150)
(%register-primitive! 'current-milliseconds 151)
(%register-primitive! 'sin 152)
(%register-primitive! 'cos 153)
(%register-primitive! 'wall-clock-ms 154)

;; --- Type introspection / save-load support ---
(%register-primitive! 'compiled-procedure? 155)
(%register-primitive! 'continuation? 156)
(%register-primitive! 'primitive? 157)
(%register-primitive! 'procedure? 228)
(%register-primitive! 'compiled-procedure-entry 158)
(%register-primitive! 'compiled-procedure-env 159)
(%register-primitive! 'continuation-stack 160)
(%register-primitive! 'continuation-conts 161)
(%register-primitive! '%primitive-id-of 162)
(%register-primitive! '%make-compiled-procedure 163)
(%register-primitive! '%make-continuation 164)
(%register-primitive! '%make-primitive 165)

;; --- Env-frame introspection ---
(%register-primitive! '%env-frame? 166)
(%register-primitive! '%env-frame-names 167)
(%register-primitive! '%env-frame-vals 168)
(%register-primitive! '%env-frame-enclosing 169)
(%register-primitive! '%make-env-frame 170)

;; --- Winding stack ---
(%register-primitive! '%set-winding-stack! 171)
(%register-primitive! '%get-winding-stack 172)
(%register-primitive! 'continuation-winds 173)

;; --- String output ports ---
(%register-primitive! 'open-output-string 175)
(%register-primitive! 'get-output-string 176)
(%register-primitive! 'port-line 177)
(%register-primitive! 'port-col 178)

;; --- Port-required write primitives ---
(%register-primitive! '%display-to-port 179)
(%register-primitive! '%write-to-port 180)
(%register-primitive! '%newline-to-port 181)
(%register-primitive! '%write-char-to-port 182)
(%register-primitive! '%write-string-to-port 183)
(%register-primitive! '%initial-output-port 184)
(%register-primitive! '%initial-input-port 185)

;; --- Process environment and filesystem ---
(%register-primitive! 'command-line 186)
(%register-primitive! 'exit 187)
(%register-primitive! 'get-environment-variable 188)
(%register-primitive! '%exe-path 189)
(%register-primitive! '%list-directory 190)
(%register-primitive! '%file-exists? 191)
(%register-primitive! 'open-binary-input-file 192)
(%register-primitive! 'read-byte 193)
(%register-primitive! '%make-directory 194)
(%register-primitive! '%chmod 195)

;; --- Canvas 2D drawing (browser) ---
(%register-primitive! 'canvas-clear 200)
(%register-primitive! 'canvas-set-fill-color 201)
(%register-primitive! 'canvas-fill-rect 202)
(%register-primitive! 'canvas-fill-circle 203)
(%register-primitive! 'canvas-draw-text 204)
(%register-primitive! 'canvas-width 205)
(%register-primitive! 'canvas-height 206)

;; --- JavaScript FFI (browser) ---
(%register-primitive! '%js-eval 210)
(%register-primitive! '%js-get 211)
(%register-primitive! '%js-set! 212)
(%register-primitive! '%js-call 213)
(%register-primitive! '%js-callback 214)
(%register-primitive! '%js-ref->number 215)
(%register-primitive! '%js-ref->string 216)
(%register-primitive! '%js-number 217)
(%register-primitive! '%js-string 218)
(%register-primitive! '%js-null? 219)
(%register-primitive! '%js-release! 220)
(%register-primitive! '%js-ref? 221)

;; --- Boot registration (self-register for completeness) ---
(%register-primitive! '%register-primitive! 222)
(%register-primitive! '%init-asm-syms 223)
(%register-primitive! '%store-asm-sym 224)
(%register-primitive! '%set-continuation-syms! 225)
(%register-primitive! '%set-error-sym! 226)
(%register-primitive! '%create-repl-space! 227)

;;; ═══════════════════════════════════════════════════════════════════
;;; 2. Initialize assembler symbol table
;;; ═══════════════════════════════════════════════════════════════════
;;; Slots 0-6: instruction types
;;; Slots 7-12: register names
;;; Slots 13-16: source/dest types
;;; Slots 17-44: operations from operations.def (op-ids 0-27; op-id = slot - 17)

(%init-asm-syms 45)

;; Instruction types (0-6)
(%store-asm-sym 0 'assign)
(%store-asm-sym 1 'test)
(%store-asm-sym 2 'branch)
(%store-asm-sym 3 'goto)
(%store-asm-sym 4 'save)
(%store-asm-sym 5 'restore)
(%store-asm-sym 6 'perform)

;; Register names (7-12)
(%store-asm-sym 7 'val)
(%store-asm-sym 8 'env)
(%store-asm-sym 9 'proc)
(%store-asm-sym 10 'argl)
(%store-asm-sym 11 'continue)
(%store-asm-sym 12 'stack)

;; Source/dest types (13-16)
(%store-asm-sym 13 'const)
(%store-asm-sym 14 'reg)
(%store-asm-sym 15 'label)
(%store-asm-sym 16 'op)

;; Operations from operations.def (17+, op-id = slot - 17)
(%store-asm-sym 17 'lookup-variable-value)
(%store-asm-sym 18 'lookup-global-variable)
(%store-asm-sym 19 'set-variable-value!)
(%store-asm-sym 20 'define-variable!)
(%store-asm-sym 21 'extend-environment)
(%store-asm-sym 22 'lexical-ref)
(%store-asm-sym 23 'lexical-set!)
(%store-asm-sym 24 'make-compiled-procedure)
(%store-asm-sym 25 'compiled-procedure-entry)
(%store-asm-sym 26 'compiled-procedure-env)
(%store-asm-sym 27 'primitive-procedure?)
(%store-asm-sym 28 'continuation?)
(%store-asm-sym 29 'parameter?)
(%store-asm-sym 30 'apply-primitive-procedure)
(%store-asm-sym 31 'apply-parameter)
(%store-asm-sym 32 'parameter-ref)
(%store-asm-sym 33 'parameter-set!)
(%store-asm-sym 34 'parameter-raw-set!)
(%store-asm-sym 35 'capture-continuation)
(%store-asm-sym 36 'do-continuation-winds)
(%store-asm-sym 37 'continuation-stack)
(%store-asm-sym 38 'continuation-conts)
(%store-asm-sym 39 'false?)
(%store-asm-sym 40 'list)
(%store-asm-sym 41 'cons)
(%store-asm-sym 42 'car)
(%store-asm-sym 43 'cdr)
(%store-asm-sym 44 'enclosing-environment)

;;; ═══════════════════════════════════════════════════════════════════
;;; 3. Cache continuation and error symbols
;;; ═══════════════════════════════════════════════════════════════════

(%set-continuation-syms! 'do-winds! '*winding-stack*)
(%set-error-sym! 'error)

;;; ═══════════════════════════════════════════════════════════════════
;;; 4. Create REPL compilation space
;;; ═══════════════════════════════════════════════════════════════════

(%create-repl-space! 'repl 524288)

;;; NOTE: #t and #f variable bindings are defined by the host runtime
;;; (JS: buildGlobalEnv, CL: boot-from-compiled) because the ecec text
;;; format cannot distinguish (const #t) as a boolean value from (const #t)
;;; as the symbol name "#t" — the WAT ecec reader always parses #t as
;;; boolean true, causing an illegal cast when define-variable! expects
;;; a symbol name.
