## 1. Symbol Space IDs

- [x] 1.1 Change `*space-registry*` from vector to hash table (`:test 'eq`, keyed by symbol)
- [x] 1.2 Change `create-space` to take a string, intern as symbol in `:ece`, store in hash table
- [x] 1.3 Change `get-space` to take a symbol, look up in hash table
- [x] 1.4 Change `*current-space-id*` and `*executing-space-id*` from integer 0 to symbol (e.g., `'bootstrap`)
- [x] 1.5 Update `make-compiled-procedure` to use symbol space ID (qualify when space is not the bootstrap space, or always qualify)
- [x] 1.6 Update `capture-continuation` to use symbol space ID
- [x] 1.7 Update `assign label` for `continue` in executor to use symbol `space-id`
- [x] 1.8 Update `switch-space` in executor to use `eq` comparison and hash table lookup
- [x] 1.9 Update `qualified-space-id` / `qualified-local-pc` helpers for symbol-keyed addresses
- [x] 1.10 Update ECE-side space primitives (`%create-space`, `%current-space-id`, etc.) to use symbols
- [x] 1.11 Run test suite — all existing tests pass with symbol space IDs

## 2. .ecec File Format

- [x] 2.1 Update `compile-file` to emit `(ecec-header (space <name>) (macros ...))` as first s-expression
- [x] 2.2 Derive space name from filename: strip directory and `.scm` extension, intern as symbol
- [x] 2.3 Track which macros are defined during `compile-file`, include in header
- [x] 2.4 Update `load-compiled` to read header, create named space, register macros, then execute units
- [x] 2.5 Update `load-compiled` to assemble into the named space (set `*current-space-id*`)
- [x] 2.6 Test: `compile-file` a .scm, `load-compiled` the .ecec, verify functions work

## 3. CL-Side Boot Loader

- [x] 3.1 Implement `load-ecec-file` in runtime.lisp — reads .ecec with CL reader, creates space, assembles and executes
- [x] 3.2 Implement `boot-from-compiled` — loads .ecec files from `bootstrap/` in fixed order
- [x] 3.3 Replace `ece-load-image` call at end of runtime.lisp with `boot-from-compiled`
- [x] 3.4 Test: system boots from .ecec files, `evaluate`, `repl`, `(load ...)` all work

## 4. Generate Bootstrap .ecec Files

- [x] 4.1 Boot from existing image, compile each .scm to .ecec using `compile-file`
- [x] 4.2 Place .ecec files in `bootstrap/` directory
- [x] 4.3 Remove `bootstrap/ece.image`
- [x] 4.4 Test: fresh boot from .ecec files, full test suite passes

## 5. Makefile Updates

- [x] 5.1 Replace `make image` with `make bootstrap` (two-pass: boot → recompile → replace .ecec files)
- [x] 5.2 Update `make test` and `make repl` to boot from .ecec files (automatic via ASDF load)
- [x] 5.3 Update `make test-ece` for new boot path
- [x] 5.4 Remove `make disasm` target (depends on image format)

## 6. Remove Image Machinery

- [x] 6.1 Remove `ece-save-image` / `ece-load-image` functions from runtime.lisp
- [x] 6.2 Remove `src/compaction.scm` from source tree and Makefile
- [x] 6.3 Remove binary image serializer (`binary-image-serialize`, section constants, byte-buffer-stream) from runtime.lisp
- [x] 6.4 Remove binary image deserializer (`binary-image-deserialize`) from runtime.lisp
- [x] 6.5 Remove flat-image serializer/deserializer from runtime.lisp
- [x] 6.6 Remove `*global-instruction-source*` (spaces have their own `instructions` field)
- [x] 6.7 Remove `sync-bootstrap-space` and the space-0 compatibility shim
- [x] 6.8 Remove image-related primitives from `primitives.def` (`%write-image`, `%instruction-source-ref`, `%instruction-source-length`, etc.)
- [x] 6.9 Remove image-related entries from `*wrapper-primitives*`
- [x] 6.10 Remove image save/load tests from test suite, update remaining tests
- [x] 6.11 Run full test suite — all tests pass without image machinery

## 7. Cleanup

- [x] 7.1 Remove `*global-instruction-vector*` and `*global-label-table*` — use only space structs
- [x] 7.2 Update `assemble-into-global` (CL version) to always use `assemble-into-space`
- [x] 7.3 Archive the `compilation-spaces` and `compile-to-host-cl` OpenSpec changes
- [x] 7.4 Update MEMORY.md to reflect new architecture (no image, .ecec boot, symbol spaces)
