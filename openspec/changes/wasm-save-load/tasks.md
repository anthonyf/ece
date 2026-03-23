## 1. Add type predicate primitives

- [ ] 1.1 Add primitives 155-157 to primitives.def (compiled-procedure?, continuation?, primitive?)
- [ ] 1.2 Implement in runtime.wat $apply-primitive dispatch
- [ ] 1.3 Add CL implementations in runtime.lisp (trivial — check tagged pair car)
- [ ] 1.4 Regenerate primitives.json

## 2. Add type accessor primitives

- [ ] 2.1 Add primitives 158-162 to primitives.def
- [ ] 2.2 Implement in runtime.wat: extract struct fields, return as ECE values
- [ ] 2.3 Add CL implementations in runtime.lisp
- [ ] 2.4 Regenerate primitives.json

## 3. Add reconstruction primitives

- [ ] 3.1 Add primitives 163-164 to primitives.def
- [ ] 3.2 Implement in runtime.wat: struct.new from ECE args
- [ ] 3.3 Add CL implementations (trivial — list construction)
- [ ] 3.4 Regenerate primitives.json

## 4. Port identity hash tables to WASM

- [ ] 4.1 Change primitives 116-118 from cl to core in primitives.def
- [ ] 4.2 Implement %eq-hash-table/ref/set! in runtime.wat (alist with ref.eq)
- [ ] 4.3 Regenerate primitives.json

## 5. Port helper primitives to WASM

- [ ] 5.1 Change primitives 121, 138-140 from cl to core in primitives.def
- [ ] 5.2 Implement %global-env-frame, %primitive-name, %primitive-id, %hash-frame? in runtime.wat
- [ ] 5.3 Regenerate primitives.json

## 6. Update serializer/deserializer

- [ ] 6.1 Update `ser-compound` in prelude.scm: use callable predicates instead of tagged pair checks
- [ ] 6.2 Update `deser` in prelude.scm: use %make-compiled-procedure / %make-continuation
- [ ] 6.3 Rebuild bootstrap (make bootstrap x2)

## 7. Tests

- [ ] 7.1-7.6 BLOCKED: serialize-value crashes on WASM when called from prelude-compiled code due to WAT reader closure corruption (same class of bug as the yield issue). Runtime-compiled identical code works. Individual primitives (compiled-procedure?, %eq-hash-table, etc.) all work. The crash is `cdr` called on a non-pair deep in the compiled serialize-value dispatch.

## 8. Verification

- [x] 8.1 Run make test-wasm — 420 passed, 0 failed (existing tests unbroken)
- [x] 8.2 Run make test — CL tests pass
- [ ] 8.3 Run make sandbox — BLOCKED on serializer crash
