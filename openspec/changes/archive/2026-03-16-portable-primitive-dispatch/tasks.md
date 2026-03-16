## Tasks

### Task 1: Create primitives.def manifest
- [x] Create `primitives.def` in project root
- [x] Enumerate all primitives from `*primitive-procedures*` (direct CL mappings)
- [x] Enumerate all primitives from `*wrapper-primitives*` (boolean wrappers, I/O, strings, etc.)
- [x] Enumerate all primitives registered elsewhere (compiler support: `try-eval`, `load`, `save-image!`, `load-image!`)
- [x] Assign stable numeric IDs (0-99 core, 100-199 CL)
- [x] Tag each as `core` or `cl` based on whether a non-CL runtime could reasonably implement it
- [x] Add arity and description fields
- [x] Reserve 200-299 range for future browser platform (empty for now)

### Task 2: Build dispatch table from manifest in CL runtime
- [x] Parse `primitives.def` at load time in `runtime.lisp`
- [x] Create `*primitive-dispatch-table*` — a vector indexed by primitive ID containing CL functions
- [x] Create `*primitive-name-table*` — a vector indexed by primitive ID containing ECE name symbols
- [x] Map each manifest entry to its CL implementation function
- [x] Install stub functions for platform-tagged primitives that CL doesn't implement (browser range)
- [x] Verify all existing primitives have manifest entries (startup validation)

### Task 3: Change primitive representation to numeric IDs
- [x] Change `*global-env*` initialization to store `(primitive <id>)` instead of `(primitive <cl-symbol>)`
- [x] Update `apply-primitive-procedure` to dispatch via `(aref *primitive-dispatch-table* id)` instead of `(symbol-function name)`
- [x] Update `primitive-procedure-p` if needed
- [x] Update `format-ece-proc` to display primitive names from `*primitive-name-table*`
- [x] Update parameter table dispatch (if it uses primitive symbols)

### Task 4: Update binary image serialization
- [x] Change primitive serialization: write `PRIM_TAG` + uint16 ID instead of symbol
- [x] Change primitive deserialization: read uint16 ID, construct `(primitive <id>)`
- [x] Handle unknown IDs gracefully (create error stub)
- [x] Update any source-instruction serialization that references primitives

### Task 5: Add platform discovery primitives
- [x] Add `platform-has?` to manifest as core primitive
- [x] Add `%platform-primitives` to manifest as core primitive
- [x] Implement `ece-platform-has-p` in `runtime.lisp` — checks if name exists in name table with a non-stub function
- [x] Implement `ece-%platform-primitives` in `runtime.lisp` — returns list of available primitive names
- [x] Register both in dispatch table

### Task 6: Rebuild image and run tests
- [x] Clear FASL cache
- [x] Rebuild the image from source (`make image` or equivalent)
- [x] Run full test suite — all existing tests must pass
- [x] Add tests for `platform-has?` with core primitives (returns #t)
- [x] Add tests for `platform-has?` with unknown names (returns #f)
- [x] Add tests for `%platform-primitives` returning expected names
- [x] Verify image save/load round-trip with numeric primitive IDs
