## 1. Add CL accessor primitives

- [x] 1.1 Add `%instruction-source-ref` primitive — return source instruction at a given PC index
- [x] 1.2 Add `%instruction-source-length` primitive — return length of source vector
- [x] 1.3 Add `%procedure-name-entries` primitive — return alist of `(pc . name)` from procedure-name table
- [x] 1.4 Add `%label-table-entries` primitive — return alist of `(label . pc)` from label table
- [x] 1.5 Add `%macro-table-entries` primitive — return alist of `(name . proc)` from macro table

## 2. Add CL serialization primitive

- [x] 2.1 Add `%write-image` primitive — takes filename and 7-element data list, serializes with `*print-circle*` and unreadable-object handling
- [x] 2.2 Rewrite `save-image!` binding to point to the ECE-side `save-image!` (defined in compaction.scm) instead of CL `ece-save-image`

## 3. Write ECE compaction

- [x] 3.1 Create `src/compaction.scm` with ECE implementation of `compact-for-save` and all helpers (collect PCs, mark blocks, compact vector, remap, deep-copy)
- [x] 3.2 Implement ECE `save-image!` in compaction.scm — calls `compact-for-save` then `%write-image`

## 4. Remove CL compaction code

- [x] 4.1 Remove all compaction functions from runtime.lisp (~257 lines)
- [x] 4.2 Remove old `ece-save-image` function (replaced by ECE-side save-image!)

## 5. Remove prelude functions

- [x] 5.1 Remove `print-text` definition from prelude.scm
- [x] 5.2 Remove `lines` definition from prelude.scm
- [x] 5.3 Remove `fmt` definition from prelude.scm
- [x] 5.4 Remove `print-text`, `lines`, and `fmt` exports from the ECE package declaration in runtime.lisp

## 5b. Update reader string interpolation

- [x] 5b.1 Update `read-string-literal` in reader.scm (line 122) — replace `(cons 'fmt segs)` with expansion to `(string-append ...)` where each interpolated expression is wrapped in `(write-to-string expr)` and literal string segments pass through as-is
- [x] 5b.2 Handle edge case: single interpolated expression with no literal segments should produce `(write-to-string expr)` not `(string-append (write-to-string expr))`

## 6. Update cold boot

- [x] 6.1 Add `src/compaction.scm` to the cold-boot load sequence (after assembler, before image save)

## 7. Verify

- [x] 7.1 Regenerate bootstrap image (`make image`) and verify it loads
- [x] 7.2 Run `make test` — all existing tests pass
- [x] 7.3 Verify compaction tests still pass (redefine + save + load)
- [x] 7.4 Count runtime.lisp lines — confirm net reduction of 175 lines (289 removed, 114 added for new primitives)
