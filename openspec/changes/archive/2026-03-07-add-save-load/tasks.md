## 1. Save/Load Primitives

- [x] 1.1 Add `ece-save-continuation!` wrapper that writes a value to a file using `write` with `*print-circle*` and `:readably t`
- [x] 1.2 Add `ece-load-continuation` wrapper that reads a value from a file using `read` with `*ece-readtable*` and `*package*` bound to `:ece`
- [x] 1.3 Register `save-continuation!` and `load-continuation` in `*wrapper-primitives*` and add package exports

## 2. Tests

- [x] 2.1 Add tests for save/load round-trip with plain values, hash tables, and continuations

## 3. Roadmap Update

- [x] 3.1 Update `openspec/roadmap-if.md` to mark Priorities 1–2 complete and Priority 3 as current
