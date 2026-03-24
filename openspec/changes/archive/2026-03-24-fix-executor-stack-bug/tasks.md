## 1. Add WASM executor trace

- [ ] 1.1 Add `trace_save_restore` JS import to runtime.wat
- [ ] 1.2 Add `$trace-sr-enabled` global flag (default 0)
- [ ] 1.3 Add `$stack-depth` helper function
- [ ] 1.4 Instrument save handler (opcode 4): log pc, space, register, value-type, stack-depth
- [ ] 1.5 Instrument restore handler (opcode 5): same fields
- [ ] 1.6 Add import handler to glue.js, test.js (log to array when enabled)
- [ ] 1.7 Add `enable_trace_sr` / `disable_trace_sr` exports

## 2. Add CL executor trace

- [ ] 2.1 Add `*trace-save-restore*` flag to runtime.lisp
- [ ] 2.2 Instrument save/restore in the CL executor's tagbody loop
- [ ] 2.3 Format: same fields as WASM (pc, space, save/restore, register, type, depth)

## 3. Capture traces for failing case

- [ ] 3.1 Create comparison script: loads prelude, calls serialize-value on (cons 1 ()), captures WASM trace
- [ ] 3.2 Create matching CL script: same call, captures CL trace
- [ ] 3.3 Diff the two traces — find first divergence point

## 4. Diagnose and fix

- [ ] 4.1 Analyze the divergence: which save/restore is wrong?
- [ ] 4.2 Identify root cause in WASM executor
- [ ] 4.3 Fix the executor bug
- [ ] 4.4 Re-run trace comparison — verify zero divergence

## 5. Verify and clean up

- [ ] 5.1 Revert ser-pair workaround in prelude.scm (restore original string-append pattern)
- [ ] 5.2 Rebuild bootstrap (make bootstrap x2)
- [ ] 5.3 Run make test-wasm — all tests pass including serialization
- [ ] 5.4 Run make test — CL tests pass
- [ ] 5.5 Add regression test: 3-arg string-append with recursive named-let as argument
- [ ] 5.6 Disable trace flag for production
