## 1. Investigate

- [x] 1.1 Identified: string->number float = f64 encoding bug in .ececb converter, hash-ref default = missing 3rd arg handling, make-parameter converter = needs prelude wrapper
- [x] 1.2 make-parameter converter requires calling compiled proc from primitive — deferred

## 2. Fix hash-ref default

- [x] 2.1 Added $prim-hash-ref-with-default helper; checks 3rd argl element when key not found

## 3. Fix string->number / float constants

- [x] 3.1 Fixed f64 encoding: CL bridge extracts IEEE 754 bytes via sb-kernel, ECE converter writes them
- [x] 3.2 Fixed write-value ordering: float-bytes tag checked before generic pair check
- [x] 3.3 Fixed float precision: CL bridge reads .ecec with *read-default-float-format* = double-float

## 4. Fix make-parameter converter

- [ ] 4.1 Deferred: requires calling compiled procedure from WAT primitive (architecture change)

## 5. Validate

- [x] 5.1 Bootstrap rebuilt (double pass)
- [x] 5.2 CL: 496 passed, 0 failed
- [x] 5.3 WASM: 328 passed, 1 failed (only make-parameter converter remains)
