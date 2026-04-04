## 1. Port line/column tracking

- [x] 1.1 Add `line` and `col` fields to CL port structure (`ece-make-input-port`, `ece-make-output-port`); initialize to line=1, col=0
- [x] 1.2 Update CL `ece-read-char` to increment col on non-newline, reset col and increment line on newline
- [x] 1.3 Add `port-line` and `port-col` accessors as CL primitives
- [x] 1.4 Add `$line` and `$col` fields to WASM `$port` struct; initialize in `$make-input-port` and `$make-output-port`
- [x] 1.5 Update WASM `$port-read-char` to track line/col on newline
- [x] 1.6 Add `port-line` and `port-col` primitives to WASM runtime

## 2. Reader source location recording

- [x] 2.1 Add `*source-locations*` global hash table (cleared per compile-file invocation)
- [x] 2.2 Add `*source-file-name*` parameter to track current filename during compilation
- [x] 2.3 Update `read-list` in reader.scm to record `(file line col)` in `*source-locations*` for each list read, using port line/col at entry
- [x] 2.4 Ensure `open-input-file` ports carry the filename for `port-name` lookup

## 3. Compiler source-map emission

- [x] 3.1 Add `*current-source-location*` parameter to compiler
- [x] 3.2 Add `*source-map-entries*` accumulator (list of `(pc line col)` triples)
- [x] 3.3 Update `mc-compile` to check `*source-locations*` hash for each expression; update `*current-source-location*` if found, inherit if not
- [x] 3.4 Emit source-map entry at expression boundaries (lambda entry, application, assignment, define)
- [x] 3.5 Wire `compile-form` to reset and collect source-map entries per compilation unit

## 4. .ecec source-map storage

- [x] 4.1 Update `compile-file` to write `(source-map "filename.scm" (pc line col) ...)` field in ecec-header
- [x] 4.2 Update `merge-instruction-lists` to adjust source-map PCs when merging units (add unit offsets)
- [x] 4.3 Update CL `load-compiled` to read optional `source-map` from ecec-header and register in `*source-maps*`
- [ ] 4.4 Update WASM `.ecec` loader (`$ecec-load-unit`) to read optional `source-map` and register in a per-space hash table

## 5. Runtime PC-to-location resolution

- [x] 5.1 Add global `*source-maps*` table (space-name → hash-table of pc → (file line col)) on CL side
- [x] 5.2 Add `resolve-source-location` helper: given space and pc, return `(file line col)` or `#f`
- [x] 5.3 Update CL `ece-runtime-error` report to include resolved source location in procedure line
- [x] 5.4 Update CL `format-ece-backtrace` to show `file:line:col` instead of `pc=N` when available
- [ ] 5.5 Add source-map hash table storage in WASM runtime (global per-space structure)
- [ ] 5.6 Update WASM error path to resolve PC to source location before signaling

## 6. Bootstrap

- [x] 6.1 Run `make bootstrap` to generate new `.ecec` files with source-map headers
- [x] 6.2 Verify bootstrap succeeds (two-pass: boot from old, recompile with new)

## 7. Tests

- [x] 7.1 Test: port line/col tracking — read characters from a string port, verify line increments on newline and col resets
- [x] 7.2 Test: port starts at line 1, col 0
- [x] 7.3 Test: reader attaches source location to simple list `(+ 1 2)`
- [x] 7.4 Test: reader attaches distinct locations to nested lists in `(define (f x) (+ x 1))`
- [x] 7.5 Test: atoms (symbols, numbers) do NOT appear in `*source-locations*`
- [x] 7.6 Test: source location includes filename from file port
- [x] 7.7 Test: compile-file produces .ecec with source-map in header
- [x] 7.8 Test: source-map entries are sorted by PC
- [x] 7.9 Test: load-compiled reads source-map and registers in `*source-maps*`
- [x] 7.10 Test: error on unbound variable includes file:line in message
- [ ] 7.11 Test: backtrace frames show file:line:col instead of pc=N
- [x] 7.12 Test: missing source-map falls back to pc=N display
- [ ] 7.13 Test: `when` macro — error in body reports body's source line, not expanded `if` line
- [ ] 7.14 Test: `cond` macro — error in second clause reports that clause's source line
- [ ] 7.15 Test: `let` macro — error in let body reports body's source line
- [ ] 7.16 Test: `and`/`or` macro — error in third operand reports that operand's source line
- [ ] 7.17 Test: `define-syntax`/`syntax-rules` macro — error in matched sub-expression reports original source line
- [ ] 7.18 Test: nested macros (e.g., `when` inside `cond`) — innermost expression keeps its source location

## 8. Validation

- [x] 8.1 Run WASM test suite — all must pass
- [x] 8.2 Run CL test suite (rove + ECE self-hosted + conformance) — no regressions
