## 1. Short compiler labels

- [x] 1.1 Change `mc-make-label` in `compiler.scm` to emit `L<counter>` instead of `mc-<name>-<counter>`
- [x] 1.2 Rebuild bootstrap (`make bootstrap` x2), verify .ecec files have short labels (2.7→2.2 MB)
- [x] 1.3 Run `make test` — all tests pass with short labels

## 2. WAT s-expression reader

- [x] 2.1 Add character reading helpers to `runtime.wat`: cursor position global, `$read-char-mem`, `$peek-char-mem`, `$skip-ws-mem`
- [x] 2.2 Add atom readers: `$read-symbol-mem` (intern result), `$read-number-mem` (fixnum/float), `$read-string-mem`
- [x] 2.3 Add `$read-sexp-mem` — recursive s-expression reader dispatching on first char
- [x] 2.4 Add instruction builder: `$parse-instruction` — recognize assign/test/branch/goto/save/restore/perform keywords, build `$instr` structs
- [x] 2.5 Add `$load-ecec` — parse header, create space, load units (labels + instructions), register macros
- [x] 2.6 Export `load_ecec(offset, len)` — entry point called from JS
- [x] 2.7 Test: load prelude.ecec via WAT reader in Node.js, verify space is created with correct instruction count

## 3. Wire up JS side

- [x] 3.1 Add `loadEcecText(name, text)` helper to `glue.js` — writes text to linear memory, calls `wasm.load_ecec`, runs the space
- [x] 3.2 Update `sandbox.js` bootECE to use `loadEcecText` with base64-decoded .ecec text instead of parseBinary/loadParsed
- [x] 3.3 Update `wasm/test.js` to load .ecec files via WAT reader
- [x] 3.4 Update `sandbox.js` evalECE pre-compiled program path to use .ecec instead of .ececb

## 4. Update build pipeline

- [x] 4.1 Update `build-sandbox.sh` to embed .ecec files (base64) instead of .ececb
- [x] 4.2 Update `build-sandbox.sh` pre-compiled programs to use .ecec (drop ecec-to-binary step)
- [x] 4.3 Update Makefile `bootstrap` target to drop the ecec-to-binary step
- [x] 4.4 Update Makefile `test-wasm` target to compile tests to .ecec (not .ececb)

## 5. Remove binary format

- [x] 5.1 Remove `parseBinary`, `buildValue`, `buildOperand`, `buildOperandList`, `buildInstruction`, `loadParsed` from `glue.js`
- [x] 5.2 Delete `src/ecec-to-binary.scm`
- [x] 5.3 Delete `wasm/ececb-format.md`
- [x] 5.4 Delete all `bootstrap/*.ececb` files

## 6. Final verification

- [x] 6.1 Run `make test` and `make test-wasm` — all tests pass
- [x] 6.2 Rebuild sandbox, verify all 5 programs work
