# Code-Object Serialization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the `%ser/opaque-co` placeholder in continuation serialization with a hybrid by-reference/inline strategy. Re-enable the three disabled `test-serialization.scm` tests.

**Architecture:** Code-objects gain an `archive-key` field populated at archive-load time. Serialization dispatches on the field: non-null → `(%ser/co-ref <stem> <index>)`; null → `(%ser/co-inline :name ... :instructions ...)`. Deserialization looks up the registry for by-ref, or reconstructs the struct for inline. Parity on CL + WASM.

**Tech Stack:** ECE Scheme (serializer lives in `src/prelude.scm`), Common Lisp (defstruct + registry in `src/runtime.lisp`), WebAssembly Text (`$code-object` struct in `wasm/runtime.wat`).

**Spec:** `docs/superpowers/specs/2026-04-22-codeobj-serialization-design.md`
**Base branch:** `codeobj-serialization` (this branch; off main)

**Prerequisite:** P0.5 (keywordize archive format) merged. This plan emits keyword keys in the inline form (`:name`, `:instructions`, etc.) to match the P0.5 archive format.

---

## Pre-flight

- [ ] **Step 1: Verify base branch compiles and tests pass**

```
make ece && make test 2>&1 | tail -10
```

Expected: 0 failed. If not, baseline is broken — reconcile before proceeding.

- [ ] **Step 2: Verify P0.5 merged**

```
head -c 100 bootstrap/bootstrap.ecec
```

Expected: starts with `(:ecec-archive :version 2 ...)`. If plain symbols, P0.5 hasn't merged yet — rebase onto main once it has.

- [ ] **Step 3: Check the three disabled tests exist**

```
grep -n 'TODO(per-procedure-code-objects §G1)' tests/ece/cl-only/test-serialization.scm
```

Expected: ≥3 matches. These are the tests that will re-enable.

---

## Task 1: Add `archive-key` field to `code-object` struct

**Files:**
- Modify `src/runtime.lisp` — `defstruct code-object` definition
- Modify `src/compilation-unit.scm` — ECE-side `code-object` record
- Modify `wasm/runtime.wat` — `$code-object` struct type + `%make-code-object` primitive (id 250)
- Modify archive-load paths to populate the field

### Step 1.1: Find the CL `code-object` defstruct

```
grep -n 'defstruct code-object\|(defstruct (code-object' src/runtime.lisp
```

### Step 1.2: Add `archive-key` slot with default `nil`

Inside the defstruct, add:
```lisp
(archive-key nil)
```

### Step 1.3: Find the ECE-side `code-object` definition

```
grep -n 'make-code-object\|code-object-archive-key' src/compilation-unit.scm src/prelude.scm
```

Add the field + accessor in the same idiom the other fields use.

### Step 1.4: Find the WAT `$code-object` struct

```
grep -n '(type \$code-object' wasm/runtime.wat
```

Add field:
```wat
(field $archive-key (mut (ref null eq)))
```

Update `(struct.new $code-object ...)` sites to pass `(ref.null eq)` for the new field.

### Step 1.5: Find archive-load hooks

- `register-archive-code-objects` in `src/runtime.lisp` — set `archive-key = (cons <stem> <index>)` on each code-object as it's registered.
- WAT `$load-archive-impl` — likewise, set `$archive-key` during Pass 1 skeleton construction.
- ECE `archive-sexp->code-objects` in `src/compilation-unit.scm` — similar.

### Step 1.6: Run tests to verify no regression

```
make ece && make test-ece 2>&1 | tail -5
```

Expected: 1305 passed, 0 failed. The field addition is inert — no serialization changes yet.

### Step 1.7: Commit

```
git commit -m "Add archive-key field to code-object struct

Populated at archive-load time (nil for REPL-compiled code-objects).
Groundwork for code-object serialization dispatch in a later commit.
No behavior change."
```

---

## Task 2: Add `ser/walk-instruction` walker

**Files:**
- Modify `src/prelude.scm` — add the helper near the existing `ser/` helpers

### Step 2.1: Locate the existing serialization helpers

```
grep -n 'ser/\|%ser/' src/prelude.scm | head
```

### Step 2.2: Add the walker

```scheme
;; Walk an instruction sexp, rewriting any code-object literal as
;; (%ser/co-ref ...) or (%ser/co-inline ...) via ser/code-object.
(define (ser/walk-instruction instr)
  (cond
    ((null? instr) instr)
    ((not (pair? instr)) instr)
    ((code-object? instr) (ser/code-object instr))
    (else (cons (ser/walk-instruction (car instr))
                (ser/walk-instruction (cdr instr))))))
```

### Step 2.3: Commit

```
git commit -m "Add ser/walk-instruction helper"
```

---

## Task 3: Replace `%ser/opaque-co` with real dispatch

**Files:**
- Modify `src/prelude.scm:~1202` — `ser/code-object` function

### Step 3.1: Read the current `ser/code-object`

```
grep -n 'ser/code-object\|%ser/opaque-co' src/prelude.scm
```

### Step 3.2: Rewrite

```scheme
(define (ser/code-object co)
  (let ((key (code-object-archive-key co)))
    (if key
        `(%ser/co-ref ,(car key) ,(cdr key))
        `(%ser/co-inline
           :name ,(code-object-name co)
           :arity ,(code-object-arity co)
           :source-loc ,(code-object-source-loc co)
           :labels ,(code-object-labels->alist co)
           :instructions ,(map ser/walk-instruction (code-object-source-instructions co))))))
```

### Step 3.3: Verify the existing test that exercises this path DOES round-trip to the new form

```
grep -n '%ser/opaque-co\|%ser/co-ref\|%ser/co-inline' tests/ece/cl-only/test-serialization.scm
```

(Likely: add a new test OR temporarily adjust an existing one to check the emission format.)

### Step 3.4: Commit

```
git commit -m "Replace %ser/opaque-co with real serialization dispatch"
```

---

## Task 4: Add `%ser/co-ref` and `%ser/co-inline` readers + re-enable tests

**Files:**
- Modify `src/prelude.scm:~1285` — extend the `%ser/read` dispatch
- Modify `tests/ece/cl-only/test-serialization.scm` — re-enable three `TODO(per-procedure-code-objects §G1)` tests

### Step 4.1: Find the existing dispatch

```
grep -n '%ser/global-env\|%ser/read\|%ser/opaque-co' src/prelude.scm
```

### Step 4.2: Add the two new handler branches

```scheme
((string=? tag "%ser/co-ref")
 (let* ((stem (cadr form))
        (idx  (caddr form))
        (key  (cons stem idx))
        (co   (hash-table-ref/default *archive-code-objects* key #f)))
   (if co
       co
       (raise-ece-deser-missing-archive-error stem idx))))

((string=? tag "%ser/co-inline")
 (ser/reconstruct-code-object-inline (cdr form)))
```

Then add `ser/reconstruct-code-object-inline` helper that:
1. Extracts `:name`, `:arity`, `:source-loc`, `:labels`, `:instructions` from the plist.
2. Builds a fresh code-object struct with `archive-key = #f`.
3. Recursively processes instructions via an inverse walker that catches nested `(%ser/co-ref ...)` / `(%ser/co-inline ...)`.

### Step 4.3: Re-enable the three tests

```
grep -n 'TODO(per-procedure-code-objects §G1)' tests/ece/cl-only/test-serialization.scm
```

Remove the `;` commenting them out. Adjust as needed for the new `(%ser/co-ref ...)` format.

### Step 4.4: Run tests

```
make test-ece 2>&1 | tail -10
```

Expected: 1305+3 = 1308 passed.

### Step 4.5: Commit

```
git commit -m "Deserialize %ser/co-ref and %ser/co-inline; re-enable G1 tests"
```

---

## Task 5: Error class + UX test

**Files:**
- Modify `src/prelude.scm` — define `ece-deser-missing-archive-error`
- Modify `tests/ece/cl-only/test-serialization.scm` — add error-path test

### Step 5.1: Define the error record

```scheme
(define-record-type ece-deser-missing-archive-error
  (make-deser-missing-archive stem index)
  deser-missing-archive-error?
  (stem deser-missing-archive-stem)
  (index deser-missing-archive-index))
```

### Step 5.2: Raise helper

```scheme
(define (raise-ece-deser-missing-archive-error stem idx)
  (raise (make-deser-missing-archive stem idx)))
```

### Step 5.3: Add a test that exercises the fail path

```scheme
(test "%ser/co-ref fails gracefully when archive absent"
  (let* ((blob "(%ser/co-ref |fake-archive| 0)")
         (raised #f)
         (stem  #f)
         (idx   #f))
    (guard (e ((deser-missing-archive-error? e)
               (set! raised #t)
               (set! stem (deser-missing-archive-stem e))
               (set! idx (deser-missing-archive-index e))))
      (deserialize-from-string blob))
    (assert-equal #t raised)
    (assert-equal 'fake-archive stem)
    (assert-equal 0 idx)))
```

### Step 5.4: Run tests and commit

```
make test-ece && git commit -m "Add ece-deser-missing-archive-error + UX test"
```

---

## Task 6: Remove `%ser/opaque-co` placeholder

**Files:**
- Modify `src/prelude.scm` — delete the dispatch branch for `%ser/opaque-co`
- Modify any other files that reference the placeholder

### Step 6.1: Find remaining references

```
grep -rn '%ser/opaque-co' . | grep -v docs/
```

### Step 6.2: Delete each

The symbol `%ser/opaque-co` should no longer appear anywhere in `src/` after this.

### Step 6.3: Run tests

```
make test 2>&1 | tail -10
```

Expected: all 0 failed.

### Step 6.4: Commit

```
git commit -m "Remove dead %ser/opaque-co placeholder dispatch"
```

---

## Task 7: Update roadmap and push

- [ ] Edit `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md` — update P2 section with status "Shipped".
- [ ] Push the branch.
- [ ] Open PR against main.

---

## Self-Review Notes

**Spec coverage:** all six design-spec sections map to tasks 1-6.

**Placeholder scan:** each step's code block is complete. No `<fill-in-later>` tokens.

**Type consistency:** `code-object-archive-key` accessor name appears identically in Task 1 (add field) and Task 3 (serialize dispatch). `ser/walk-instruction` signature appears in Task 2 and Task 3. `deser-missing-archive-error?` appears in Task 5 definition and test.
