## 1. Sub-function splitting in the codegen

- [x] 1.1 Add a `chunk-size` constant (4096) and a predicate `needs-splitting?` that checks instruction count against it
- [x] 1.2 Implement `emit-zone-defun-split` that emits ceil(N/chunk-size) chunk `defun`s, each with its own tagbody covering [start, end)
- [x] 1.3 Implement the dispatcher `defun` that loops: pick chunk by pc range, call it, check halt/bail
- [x] 1.4 Update goto/branch emitters to detect cross-chunk targets and emit return-to-dispatcher instead of `(go pc-N)`
- [x] 1.5 Update `emit-entry-dispatch` in each chunk to only cover its own [start, end) range
- [x] 1.6 Wire `generate-zone-cl!` to call `emit-zone-defun-split` when `needs-splitting?` is true, keeping the existing single-function path for small spaces
- [x] 1.7 Verify the assembler zone (962 PCs) regenerates byte-identically (small-space path unchanged)
- [x] 1.8 Generate boot-env zone (5262 PCs) and verify it loads and passes parity tests
- [x] 1.9 Generate compilation-unit zone (7267 PCs) and verify it loads — this is the first space that requires splitting
- [x] 1.10 Generate all remaining spaces (reader, syntax-rules, compiler, prelude) and verify each loads

## 2. Batch generation entry point

- [x] 2.1 Implement `(generate-all-zones! output-dir)` that iterates `*space-registry*`, filters spaces with > 0 instructions, and calls `generate-zone-cl!` for each
- [x] 2.2 Verify byte-determinism: two consecutive calls to `generate-all-zones!` produce identical files for every space
- [x] 2.3 Time the full batch: target < 3 min in a single SBCL session

## 3. Build integration

- [x] 3.1 Replace the single `assembler-zone.lisp` Makefile rule with a batch rule that invokes `generate-all-zones!` once for all spaces
- [x] 3.2 Ensure the batch rule depends on `bootstrap/bootstrap.ecec` so zones are always generated from fresh instruction vectors
- [x] 3.3 Generate and check in all seven `bootstrap/<space>-zone.lisp` files
- [x] 3.4 Add `*-zone.lisp linguist-generated` to `.gitattributes` so GitHub suppresses diffs
- [x] 3.5 Verify `make bootstrap` regenerates the entire tree cleanly from a cold state

## 4. Validation

- [x] 4.1 Run `make test-rove` with all zones loaded — confirm zero failures
- [x] 4.2 Run ECE self-hosted test suite (common + cl-only) — confirm zero failures
- [x] 4.3 Run conformance test suite — confirm zero failures
- [x] 4.4 Run WASM test suite — confirm zero failures (WASM still uses interpreted path)
- [x] 4.5 Add a parity smoke test that registers each zone in turn and runs `(+ 1 2 3)` — confirms every zone loads and the runtime hook dispatches correctly
- [x] 4.6 Verify deterministic regeneration: `generate-all-zones!` twice produces byte-identical output for all spaces
