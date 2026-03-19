## Context

ECE currently boots from a monolithic image file (`bootstrap/ece.image`). This image contains the entire instruction vector, label table, global environment, macro table, and procedure names serialized in a custom binary format. The image architecture requires ~800 lines of CL serialization code, 462 lines of ECE compaction code, and the compilation-spaces machinery to split the blob for native compilation.

ECE already has `compile-file` and `load-compiled` in compilation-unit.scm which serialize/deserialize register machine instructions as s-expressions. These work today but aren't used for boot.

## Goals / Non-Goals

**Goals:**
- Boot from per-file `.ecec` files instead of a monolithic image
- Symbol-based space IDs for readable, stable addresses
- Eliminate image serialization, compaction, and binary format code
- Keep the register machine instruction set exactly as-is
- Keep `call/cc` and continuation capture working across files
- Keep the self-hosting property (ECE can recompile itself)

**Non-Goals:**
- Native compilation (deferred to separate change)
- Continuation serialization for IF save/load (separate concern)
- Changing the compiler or instruction set
- Performance optimization of the executor

## Decisions

### 1. Symbol space IDs

**Choice:** Space IDs are CL symbols interned in the ECE package. The space registry is a hash table keyed by symbol. Addresses are `(symbol . local-pc)` cons pairs.

```lisp
;; Space registry
(defvar *space-registry* (make-hash-table :test 'eq))

;; Addresses
(make-compiled-procedure '(prelude . 4523) env)
(capture-continuation stack '(compiler . 891))
```

**Why:** Symbols compare with `eq` (O(1), same as integer comparison). They're human-readable in backtraces and serialized continuations. They're stable across rebuilds — `prelude` always means prelude, regardless of load order. The current integer-indexed vector becomes a symbol-keyed hash table with identical performance characteristics for the common case (lookup by key).

### 2. .ecec file format with metadata header

**Choice:** Each `.ecec` file starts with a metadata header (an s-expression), followed by compiled unit instructions (one per form). The header captures the space name and any compile-time macro registrations needed at load time.

```scheme
;; prelude.ecec
(ecec-header
  (space prelude)
  (macros (let and or cond when unless case do let* letrec named-let)))
;; Compiled instructions follow, one unit per line
((assign val (op make-compiled-procedure) (label entry-0) (reg env)) ...)
((assign val (op make-compiled-procedure) (label entry-1) (reg env)) ...)
```

**Why:** The header lets `load-compiled` create the correct named space and know which macros were defined (so dependent files can use them). The instruction format stays identical — each line is a flat list of register machine instructions, same as today's compilation-unit.scm output. S-expression serialization is simple, portable, and already implemented.

### 3. Boot sequence: CL-side loader

**Choice:** The CL runtime includes a `boot-from-compiled` function that loads `.ecec` files in a fixed order. This runs at ASDF load time, replacing `ece-load-image`.

```lisp
(defun boot-from-compiled ()
  (dolist (name '("prelude" "compiler" "reader" "assembler"
                  "compilation-unit"))
    (load-ecec-file
      (asdf:system-relative-pathname :ece
        (format nil "bootstrap/~A.ecec" name)))))
```

**Why:** The boot order is fixed and known — prelude must load before compiler (compiler uses prelude macros), reader before assembler, etc. A simple list in the CL code is the right level of abstraction. No manifest file needed.

### 4. load-ecec-file: CL-side .ecec loader

**Choice:** A CL function that reads the `.ecec` header, creates a named space, then reads and executes each compiled unit. This is the CL equivalent of `load-compiled` but creates the space from the header metadata.

```lisp
(defun load-ecec-file (pathname)
  (with-open-file (stream pathname)
    (let* ((header (cl:read stream))
           (space-name (intern (string-upcase (cadr (assoc 'space (cdr header)))) :ece))
           (sid (create-space space-name)))
      ;; Register macros from header
      ...
      ;; Read and execute compiled units
      (let ((*current-space-id* sid))
        (loop for instrs = (cl:read stream nil :eof)
              until (eq instrs :eof)
              do (let ((start-pc (assemble-into-space sid instrs)))
                   (execute-instructions sid start-pc *global-env*)))))))
```

**Why:** The CL reader can parse the s-expression format directly. No custom deserializer needed. The CL-side loader handles the bootstrap case (before the ECE reader exists). After boot, `load-compiled` (ECE-side) handles user `.ecec` files using the ECE reader.

### 5. Two-pass bootstrap build

**Choice:** `make bootstrap` runs two passes:
1. Boot from existing `.ecec` files → gives us a working compiler
2. Re-compile all `.scm` → `.ecec` → produces fresh `.ecec` files

```makefile
bootstrap:
	# Pass 1: boot from existing compiled files
	# Pass 2: re-compile sources to refresh bootstrap
	sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (quote (begin
	    (compile-file "src/prelude.scm")
	    (compile-file "src/compiler.scm")
	    (compile-file "src/reader.scm")
	    (compile-file "src/assembler.scm")
	    (compile-file "src/compilation-unit.scm"))))'
	mv src/*.ecec bootstrap/
```

**Why:** This breaks the chicken-and-egg: you need the compiler to compile, and the compiler is compiled. The existing `.ecec` files (checked into the repo) provide the initial compiler. The two-pass build regenerates them from source, like SBCL's FASL bootstrap.

### 6. Removal plan for image machinery

**Choice:** Remove in this order:
1. Remove `ece-save-image` / `ece-load-image` entry points
2. Remove `compaction.scm` from the source tree
3. Remove binary serializer/deserializer from runtime.lisp
4. Remove flat-image serializer/deserializer from runtime.lisp
5. Remove `*global-instruction-source*` (only needed for image serialization — the space struct's `instructions` field replaces it)
6. Remove image-related primitives from `primitives.def` and `*wrapper-primitives*`

**Why:** Ordered to minimize breakage. Entry points first (nothing calls them after boot changes), then implementation code, then the data structures they depended on.

### 7. Space 0 goes away

**Choice:** There is no special "bootstrap" space 0. All spaces are named. The first space loaded is `prelude`. The global vectors (`*global-instruction-vector*` etc.) are removed along with `sync-bootstrap-space`. Each space is accessed by name from `*space-registry*`.

**Why:** Space 0 was a compatibility shim for the migration from the monolithic vector. With per-file boot, every file has its own named space from the start. No special case needed.

## Risks / Trade-offs

**[Boot time]** Loading 5 `.ecec` files via s-expression parsing may be slower than loading a binary image. Mitigation: the files are small (the current image is 1.7MB, split across 5 files each is ~350KB). S-expression parsing in CL is fast. If needed, a binary `.ecec` format could be added later without changing the architecture.

**[Bootstrap fragility]** If the `.ecec` files get corrupted or out of sync with the source, boot fails. Mitigation: CI runs `make bootstrap` to verify round-trip. The `.ecec` files are checked into git so they can always be restored.

**[Dead code accumulation]** Without compaction, dead code from macro expansion stays in the `.ecec` files. Mitigation: each file is small (prelude ~5K instructions), and dead code is harmless. A future optimizer can be added per-file if needed.

**[Macro ordering]** `compile-file` must handle `define-macro` at compile time so subsequent forms can use macros. Mitigation: this already works in the current `compile-file` implementation (line 68 of compilation-unit.scm).
