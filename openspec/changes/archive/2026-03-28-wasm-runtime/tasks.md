## 1. Project Setup

- [x] 1.1 Create `wasm/` directory with initial file structure (runtime.wat, glue.js, index.html)
- [x] 1.2 Add `write-byte` primitive to `primitives.def` (CL range, ID 104) and implement in CL runtime
- [x] 1.3 Add Makefile target `make wasm` using binaryen's `wasm-as --enable-gc --enable-reference-types`

## 2. WasmGC Value Types

- [x] 2.1 Define all WasmGC struct/array types ($pair, $symbol, $string, $float-box, $vector, $compiled-proc, $continuation, $primitive, $parameter, $hash-table, $port)
- [x] 2.2 Define singleton globals ($true, $false, $nil, $eof, $void)
- [x] 2.3 Implement i31ref fixnum boxing/unboxing helpers
- [x] 2.4 Implement type predicate functions (pair?, number?, string?, symbol?, boolean?, null?, etc.) using ref.test
- [x] 2.5 Implement eq? using ref.eq for GC references and value comparison for i31ref

## 3. Symbol Interning

- [x] 3.1 Implement symbol intern table (array-based, linear scan for lookup)
- [x] 3.2 Implement intern function (lookup existing or allocate new ID)
- [x] 3.3 Implement symbol->string and string->symbol
- [ ] 3.4 Pre-intern primitive names from primitives.def at startup (deferred to .ececb loader)

## 4. Environment Operations

- [x] 4.1 Define $env-frame struct type (vals array, enclosing ref)
- [x] 4.2 Implement extend-environment (create new frame, link to parent)
- [x] 4.3 Implement lexical-ref (walk depth frames, index into vals)
- [x] 4.4 Implement lexical-set! (walk depth frames, mutate vals)
- [x] 4.5 Implement lookup-variable-value (walk frames by name, for globals)
- [x] 4.6 Implement define-variable! (add/update binding in innermost frame)
- [x] 4.7 Implement set-variable-value! (find and mutate in frame chain)
- [ ] 4.8 Build initial global environment with primitive bindings (deferred to .ececb loader)

## 5. Executor Loop

- [x] 5.1 Define instruction representation in WasmGC ($instr struct: opcode, a, b, c, val)
- [x] 5.2 Implement compilation space struct ($comp-space: name, instrs, len)
- [x] 5.3 Implement space registry (array indexed by symbol ID)
- [x] 5.4 Implement register file as WASM locals (val, env, proc, argl, continue, stack) + flag
- [x] 5.5 Implement assign opcode (const, reg, label, op sources)
- [x] 5.6 Implement test opcode (call operation, set flag)
- [x] 5.7 Implement branch opcode (conditional jump on flag)
- [x] 5.8 Implement goto opcode (label, register with same-space and cross-space addresses)
- [x] 5.9 Implement save/restore opcodes (push/pop stack as pair list)
- [x] 5.10 Implement perform opcode (call operation, discard result)
- [x] 5.11 Implement operation dispatch (21 machine ops: lookup, extend-env, lexical-ref, etc.)
- [x] 5.12 Wire up execute-instructions entry point (exported as "execute")

## 6. Core Primitives (Milestone 1 subset)

- [x] 6.1 Arithmetic: +, -, *, /, modulo, =, <, > (variadic, with fixnum/float handling)
- [x] 6.2 Pair ops: cons, car, cdr, set-car!, set-cdr!, list
- [x] 6.3 Type predicates: null?, pair?, number?, string?, symbol?, boolean?, integer?, char?, vector?
- [x] 6.4 Equality: eq? (identity), equal? (structural recursive)
- [x] 6.5 String ops: string-length, string-ref, string-append, substring, string=?, string<?, string>?
- [x] 6.6 Conversion: string->number, number->string, string->symbol, symbol->string
- [x] 6.7 I/O: display (stub), newline (JS delegate), write-to-string (partial), eof?
- [x] 6.8 Compiler support: all 21 machine operations in dispatch-op
- [x] 6.9 Primitive dispatch by ID (if chain in $apply-primitive, IDs 0-67)

## 7. Binary .ececb Format

- [x] 7.1 Design and document binary encoding (wasm/ececb-format.md)
- [x] 7.2 Write `ecec-to-binary.scm` converter in ECE (CL bridge reads .ecec, ECE writes binary)
- [x] 7.3 Integrate into Makefile — `make bootstrap` produces .ececb alongside .ecec
- [x] 7.4 Implement .ececb loader in JS glue — binary parser verified on all 5 bootstrap files

## 8. JS Glue & HTML Harness

- [x] 8.1 Create `glue.js` — WASM instantiation, .ececb parser, value builders
- [x] 8.2 Implement I/O imports (display_number, newline) writing to `<pre>` element
- [x] 8.3 Implement .ececb fetch and load sequence (bootstrap files in correct order)
- [x] 8.4 Create `index.html` with output `<pre>` element and script loading
- [x] 8.5 Add `serve.sh` static file server script for local testing

## 9. Test Suite Reorganization

- [x] 9.1 Audit all test files — 22 common, 4 CL-only (file-io, serialization, compilation-units, cross-space)
- [x] 9.2 Create `tests/ece/run-common.scm` — 22 common test files
- [x] 9.3 Create `tests/ece/run-cl.scm` — 4 CL-only test files
- [x] 9.4 Create `tests/ece/run-wasm.scm` — placeholder for WASM-specific tests
- [x] 9.5 Update `tests/ece/run-all.scm` to compose run-common.scm + run-cl.scm
- [x] 9.6 Verify all 498 CL tests still pass after reorganization

## 10. Integration & Milestone 1 Validation

- [x] 10.1 End-to-end test: (+ 1 2)=3, (- 10 3)=7, (* 6 7)=42, (display 42)(newline) all PASS
- [x] 10.2 Boot prelude.ececb — 36,108 instructions, 100 units, boots in 65ms!
- [x] 10.3 Run in browser — WASM+prelude loads, all files served (index.html, glue.js, runtime.wasm, prelude.ececb)
- [x] 10.4 Benchmark fib(30)=832040: CL 2735ms, WASM 4741ms (1.7x slower — no optimizations yet)

## 11. Remaining Core Primitives

- [x] 11.1 Character ops: char->integer, integer->char, char=?, char<?, char-whitespace?
- [x] 11.2 Vector ops: make-vector, vector, vector-ref, vector-set!, vector-length, vector->list, list->vector
- [x] 11.3 Bitwise ops: bitwise-and, bitwise-or, bitwise-xor, bitwise-not, arithmetic-shift
- [ ] 11.4 String ops (remaining): string-downcase, string-upcase, string-split, string-trim, string-contains?, string-join
- [ ] 11.5 Port ops: stubs for open-input-string, read-char, peek-char, write-char, char-ready?
- [x] 11.6 Misc: gensym, sleep (stub), clear-screen (stub), platform-has? (stub), keyword? (stub), print
- [ ] 11.7 Compiler support (remaining): execute-from-pc, get-macro, set-macro!, make-parameter, apply-compiled-procedure, try-eval
- [ ] 11.8 Assembler support: %intern-ece, %instruction-vector-length, %instruction-vector-push!, %label-table-set!, %label-table-ref, %procedure-name-set!
- [x] 11.9 Display/write: full type coverage (strings via linear memory, numbers, bools, nil, symbols, chars, pairs, lists)

## 12. WASM Host Validation

- [x] 12.1 Boot full bootstrap — all 5 .ececb files boot successfully (65K instructions, 99ms total)
- [x] 12.2 Run common tests — 306 passed, 23 failed (15 test files, 3s incl. TCO at 1M). Remaining: hash tables (i31 range too small for 32-bit HAMT), string->number float edge cases, 1 parameter test.
- [x] 12.3 Fixed: write-to-string lists/vectors, #f normalization, string-split 1-arg/char, make-vector fill, i32 overflow, bitwise floats, vector .ececb, hash table primitives, string->number floats, make-parameter
- [ ] 12.4 Add WASM-specific tests to `run-wasm.scm`
