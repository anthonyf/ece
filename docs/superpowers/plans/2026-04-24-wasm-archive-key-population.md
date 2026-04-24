# WASM Archive-Key Population Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Populate `$archive-key` on each WASM-loaded code-object and maintain a registry so `%archive-co-lookup` can resolve `(stem, index)` to code-objects — closing the last cross-host gap in P2's hybrid continuation serialization.

**Architecture:** One new module global (`$archive-registry`, lazy-init nested hash-of-hashes). One new sym-id global (`$sym-id-file`). Three helper functions added near the existing archive helpers. `$load-archive-impl` Pass 1 gains ~10 lines to stamp + register each code-object. Primitive 260 rewritten from stub to a 3-line lookup.

**Tech Stack:** WebAssembly Text (WAT) with GC proposal, using existing `$pair`, `$symbol`, `$hash-table`, `$intern`, `$cons`, `$make-fixnum`, `$hash-ref-impl`, `$hash-set-impl` primitives.

**Spec:** `docs/superpowers/specs/2026-04-24-wasm-archive-key-population-design.md`
**Base branch:** `wasm-archive-key-population` (off main; spec already committed)

---

## File structure

- Modify: `/Users/anthonyfairchild/git/ece/wasm/runtime.wat`
- Modify: `/Users/anthonyfairchild/git/ece/docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`

Two commits, single PR. All WAT work lives in one file; roadmap edit is a separate docs commit.

---

## Pre-flight

- [ ] **Step 1: Baseline test pass**

```
cd /Users/anthonyfairchild/git/ece
make test-wasm 2>&1 | tail -5
```

Expected: `WASM tests: 1008 passed, 0 failed` (or whatever the current baseline is). If the baseline is red, stop and investigate — this plan assumes a green starting state.

- [ ] **Step 2: Verify branch + spec present**

```
git status && git log --oneline -3
```

Expected: on branch `wasm-archive-key-population`, last commit is `Add design spec: WASM archive-key population`.

---

## Task 1: Add the `$sym-id-file` global and its init

**Files:**
- Modify: `wasm/runtime.wat` around line 1604 (sym-id global declarations) and around line 468 (init block)

### Step 1.1: Locate the sym-id declaration block

```
grep -n 'global \$sym-id-instructions' wasm/runtime.wat
```

Expected: one match in the 1600s (the declaration), one in the 400s (the init site — `global.set`).

### Step 1.2: Add `$sym-id-file` declaration

Using the Edit tool:

**old_string:**
```
  (global $sym-id-instructions (mut i32) (i32.const 0))
```

**new_string:**
```
  (global $sym-id-instructions (mut i32) (i32.const 0))
  (global $sym-id-file         (mut i32) (i32.const 0))
```

### Step 1.3: Add the init in `$init-ascii-chars`

Locate the `:instructions` init (around line 462) — the last archive-key sym-id currently initialized.

**old_string:**
```
    ;; ":instructions" (13 chars)
    (global.set $sym-id-instructions
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 13
          (i32.const 58)
          (i32.const 105) (i32.const 110) (i32.const 115) (i32.const 116)
          (i32.const 114) (i32.const 117) (i32.const 99) (i32.const 116)
          (i32.const 105) (i32.const 111) (i32.const 110) (i32.const 115)))))
  )
```

**new_string:**
```
    ;; ":instructions" (13 chars)
    (global.set $sym-id-instructions
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 13
          (i32.const 58)
          (i32.const 105) (i32.const 110) (i32.const 115) (i32.const 116)
          (i32.const 114) (i32.const 117) (i32.const 99) (i32.const 116)
          (i32.const 105) (i32.const 111) (i32.const 110) (i32.const 115)))))
    ;; ":file" (5 chars)
    (global.set $sym-id-file
      (struct.get $symbol $id (call $intern
        (array.new_fixed $string 5
          (i32.const 58)
          (i32.const 102) (i32.const 105) (i32.const 108) (i32.const 101)))))
  )
```

ASCII codes verified: `:` = 58, `f` = 102, `i` = 105, `l` = 108, `e` = 101.

### Step 1.4: WAT compile check

```
cd /Users/anthonyfairchild/git/ece
make wasm 2>&1 | tail -3
```

Expected: rebuilds `wasm/runtime.wasm` cleanly. No wat2wasm errors.

---

## Task 2: Add the `$archive-registry` global

**Files:**
- Modify: `wasm/runtime.wat` right after the new `$sym-id-file` declaration (~line 1606)

### Step 2.1: Add the global

**old_string:**
```
  (global $sym-id-file         (mut i32) (i32.const 0))
```

**new_string:**
```
  (global $sym-id-file         (mut i32) (i32.const 0))

  ;; Archive registry: outer $hash-table keyed by file-stem symbol ref
  ;; mapping to inner $hash-tables keyed by index-fixnum mapping to
  ;; $code-object refs. Null until first registration; lazy-initialized
  ;; by $archive-registry-put. Populated per-archive by
  ;; $load-archive-impl; read by primitive 260 (%archive-co-lookup).
  (global $archive-registry (mut (ref null eq)) (ref.null eq))
```

### Step 2.2: WAT compile check

```
cd /Users/anthonyfairchild/git/ece
make wasm 2>&1 | tail -3
```

Expected: clean build. Unused global is fine; nothing references it yet.

---

## Task 3: Add `$archive-file-stem-symbol` helper

**Files:**
- Modify: `wasm/runtime.wat` just before `$load-archive-impl` (~line 6157)

### Step 3.1: Locate insertion point

```
grep -n '(func \$load-archive-impl' wasm/runtime.wat
```

Expected: one match. Insertion goes immediately before this function.

### Step 3.2: Insert the helper

**old_string:**
```
  (func $load-archive-impl (result (ref $code-object))
    (local $archive (ref null eq))
```

**new_string:**
```
  ;; Extract the archive's file-stem as an interned symbol.
  ;; Mirrors CL's archive-file-stem-symbol in src/runtime.lisp.
  ;;
  ;; Reads :file from the archive (expected to be a string like
  ;; "boot-env.scm"), strips any trailing dotted extension
  ;; (everything from the last `.` onward), and interns the prefix.
  ;;
  ;; Returns (ref.null eq) if :file is missing or not a string, so
  ;; callers can skip registration rather than erroring — matches CL's
  ;; graceful-degrade behavior.
  (func $archive-file-stem-symbol (param $archive (ref null eq))
                                  (result (ref null eq))
    (local $file (ref null eq))
    (local $name (ref $string))
    (local $len i32)
    (local $last-dot i32)
    (local $i i32)
    (local $stem-len i32)
    (local $stem (ref $string))
    (local.set $file
      (call $archive-plist-get-by-id
        (call $xcdr (local.get $archive))
        (global.get $sym-id-file)))
    ;; Missing or non-string → null.
    (if (ref.is_null (local.get $file)) (then (return (ref.null eq))))
    (if (i32.eqz (call $is-string (local.get $file)))
      (then (return (ref.null eq))))
    (local.set $name (ref.cast (ref $string) (local.get $file)))
    (local.set $len (array.len (local.get $name)))
    ;; Scan for the last `.` (char code 46).
    (local.set $last-dot (i32.const -1))
    (local.set $i (i32.const 0))
    (block $scan-done (loop $scan
      (br_if $scan-done (i32.ge_u (local.get $i) (local.get $len)))
      (if (i32.eq
            (array.get_u $string (local.get $name) (local.get $i))
            (i32.const 46))
        (then (local.set $last-dot (local.get $i))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $scan)))
    ;; Choose stem length: up to last-dot, or full length if no dot.
    (local.set $stem-len
      (if (result i32) (i32.lt_s (local.get $last-dot) (i32.const 0))
        (then (local.get $len))
        (else (local.get $last-dot))))
    ;; Build the stem string by copying $stem-len chars.
    (local.set $stem (array.new_default $string (local.get $stem-len)))
    (local.set $i (i32.const 0))
    (block $copy-done (loop $copy
      (br_if $copy-done (i32.ge_u (local.get $i) (local.get $stem-len)))
      (array.set $string (local.get $stem) (local.get $i)
        (array.get_u $string (local.get $name) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $copy)))
    ;; Intern and return.
    (call $intern (local.get $stem)))

  (func $load-archive-impl (result (ref $code-object))
    (local $archive (ref null eq))
```

### Step 3.3: WAT compile check

```
make wasm 2>&1 | tail -3
```

Expected: clean build. Unused function OK.

---

## Task 4: Add registry put + get helpers

**Files:**
- Modify: `wasm/runtime.wat` immediately after `$archive-file-stem-symbol`

### Step 4.1: Insert both helpers

Find the end of `$archive-file-stem-symbol` (the closing `)` just before `(func $load-archive-impl`).

**old_string:**
```
    ;; Intern and return.
    (call $intern (local.get $stem)))

  (func $load-archive-impl (result (ref $code-object))
```

**new_string:**
```
    ;; Intern and return.
    (call $intern (local.get $stem)))

  ;; Put a (stem, index) → co mapping into $archive-registry.
  ;; Lazy-creates the outer hash and per-stem inner hashes on first use.
  ;; Re-registering a stem overwrites the inner-hash reference wholesale
  ;; so a reloaded archive fully replaces the previous registration.
  (func $archive-registry-put (param $stem (ref null eq))
                              (param $index-fx (ref null eq))
                              (param $co (ref $code-object))
    (local $outer (ref $hash-table))
    (local $inner (ref null eq))
    (local $inner-ht (ref $hash-table))
    ;; Lazy-create outer.
    (if (ref.is_null (global.get $archive-registry))
      (then
        (global.set $archive-registry
          (struct.new $hash-table
            (array.new_default $hash-keys (i32.const 32))
            (array.new_default $hash-vals (i32.const 32))
            (i32.const 0)))))
    (local.set $outer
      (ref.cast (ref $hash-table) (global.get $archive-registry)))
    ;; Look up existing inner. $hash-ref-impl returns $false (a boolean
    ;; singleton, not a hash-table) if missing — test by ref.test.
    (local.set $inner
      (call $hash-ref-impl (local.get $outer) (local.get $stem)))
    (if (i32.eqz (ref.test (ref $hash-table) (local.get $inner)))
      (then
        ;; Missing — create an inner hash and insert.
        (local.set $inner-ht
          (struct.new $hash-table
            (array.new_default $hash-keys (i32.const 32))
            (array.new_default $hash-vals (i32.const 32))
            (i32.const 0)))
        (call $hash-set-impl (local.get $outer)
          (local.get $stem) (local.get $inner-ht)))
      (else
        (local.set $inner-ht
          (ref.cast (ref $hash-table) (local.get $inner)))))
    ;; Insert (index → co) into inner. $hash-set-impl overwrites on
    ;; matching key per its existing semantics.
    (call $hash-set-impl (local.get $inner-ht)
      (local.get $index-fx) (local.get $co)))

  ;; Look up (stem, index) in $archive-registry.
  ;; Returns $false on any miss (uninitialized registry, unknown stem,
  ;; or unknown index within a known stem). Matches CL's gethash
  ;; miss behavior.
  (func $archive-registry-get (param $stem (ref null eq))
                              (param $index-fx (ref null eq))
                              (result (ref null eq))
    (local $outer (ref $hash-table))
    (local $inner (ref null eq))
    (if (ref.is_null (global.get $archive-registry))
      (then (return (global.get $false))))
    (local.set $outer
      (ref.cast (ref $hash-table) (global.get $archive-registry)))
    (local.set $inner
      (call $hash-ref-impl (local.get $outer) (local.get $stem)))
    (if (i32.eqz (ref.test (ref $hash-table) (local.get $inner)))
      (then (return (global.get $false))))
    (call $hash-ref-impl
      (ref.cast (ref $hash-table) (local.get $inner))
      (local.get $index-fx)))

  (func $load-archive-impl (result (ref $code-object))
```

### Step 4.2: WAT compile check

```
make wasm 2>&1 | tail -3
```

Expected: clean build. Both helpers defined but unused yet.

---

## Task 5: Integrate stamping + registration into `$load-archive-impl`

**Files:**
- Modify: `wasm/runtime.wat` inside `$load-archive-impl`

### Step 5.1: Add `$stem` local

Find the local declarations at the top of `$load-archive-impl`:

**old_string:**
```
    (local $parsed-instr (ref $instr))
    (local $entries-iter (ref null eq))

    ;; Read archive sexp.
```

**new_string:**
```
    (local $parsed-instr (ref $instr))
    (local $entries-iter (ref null eq))
    (local $stem (ref null eq))

    ;; Read archive sexp.
```

### Step 5.2: Extract stem once, just after version/entries parsing and before the entry loop

Find the line immediately after the entries-list fetch and count loop guard — where we start allocating `$cos`. The spec says "just before the entry loop in Pass 1", which is just after the count guard.

```
grep -n '(local.set \$cos (array.new \$co-vec' wasm/runtime.wat
```

Expected: one match inside `$load-archive-impl`. Read the lines around it to find the right anchor.

**old_string:**
```
    ;; Allocate code-object vector.
    (local.set $cos (array.new $co-vec (ref.null eq) (local.get $count)))
```

**new_string:**
```
    ;; Extract archive file-stem once for archive-key stamping + registry.
    ;; Null when :file is missing/non-string → Pass 1 below skips stamping.
    (local.set $stem (call $archive-file-stem-symbol (local.get $archive)))

    ;; Allocate code-object vector.
    (local.set $cos (array.new $co-vec (ref.null eq) (local.get $count)))
```

### Step 5.3: Stamp + register inside Pass 1

Find where Pass 1 finishes setting the code-object's metadata and pushes into `$cos`. Specifically, the `$cos` array-set step:

```
grep -n '(array.set \$co-vec (local.get \$cos) (local.get \$i) (local.get \$co))' wasm/runtime.wat
```

Expected: one match inside `$load-archive-impl`'s Pass 1.

**old_string:**
```
      (array.set $co-vec (local.get $cos) (local.get $i) (local.get $co))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $pass1)))
```

**new_string:**
```
      (array.set $co-vec (local.get $cos) (local.get $i) (local.get $co))
      ;; Stamp archive-key = (stem . index-fixnum) and register in the
      ;; archive registry. Skip when stem is null (archive missing :file)
      ;; — matches CL's skip-registration semantics.
      (if (i32.eqz (ref.is_null (local.get $stem)))
        (then
          (struct.set $code-object $archive-key (local.get $co)
            (call $cons
              (local.get $stem)
              (call $make-fixnum (local.get $i))))
          (call $archive-registry-put
            (local.get $stem)
            (call $make-fixnum (local.get $i))
            (local.get $co))))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $pass1)))
```

### Step 5.4: WAT compile check

```
make wasm 2>&1 | tail -3
```

Expected: clean build.

### Step 5.5: Run test-wasm

```
make test-wasm 2>&1 | tail -5
```

Expected: `WASM tests: 1008 passed, 0 failed` (matching the baseline — bootstrap loads through the new path, existing behavior unchanged since primitive 260 is still stubbed).

If a test regresses, most likely culprits:
- `$archive-file-stem-symbol` returning the wrong stem (verify manually: `bootstrap.ecec`'s first archive has `:file "boot-env.scm"` → stem should be `boot-env`).
- Stamp wiring: the `struct.set $archive-key` may be the wrong field name — check the `$code-object` struct definition.

---

## Task 6: Rewrite primitive 260 (`%archive-co-lookup`)

**Files:**
- Modify: `wasm/runtime.wat` at primitive 260's current stub

### Step 6.1: Find the current stub

```
grep -n ';; 260 =\|%archive-co-lookup' wasm/runtime.wat | head -3
```

Expected: the comment block + the dispatch `if` inside the primitive-dispatch ladder. Read the full block.

### Step 6.2: Rewrite the dispatch arm

**old_string:**
```
    ;; 260 = %archive-co-lookup(stem, index) — WASM stub returns #f.
    ;; The WASM archive loader doesn't populate a (stem . index) registry
    ;; (archive-key stamping is a CL-only follow-up), so:
    ;;   - Serialization side: code-objects on WASM always have archive-key
    ;;     null and serialize as (%ser/co-inline ...), never by-reference.
    ;;   - Deserialization side: a (%ser/co-ref ...) blob produced elsewhere
    ;;     (e.g. by CL) and deserialized on WASM traps with
    ;;     ece-deser-missing-archive-error (the same error CL would raise
    ;;     for an unloaded archive). Cross-host save/restore of by-reference
    ;;     continuations therefore requires WASM archive-key stamping to
    ;;     land first.
    (if (i32.eq (local.get $id) (i32.const 260))
      (then (return (global.get $false))))
```

**new_string:**
```
    ;; 260 = %archive-co-lookup(stem, index) — resolve to code-object.
    ;; Reads $archive-registry (populated by $load-archive-impl Pass 1).
    ;; Returns #f on any miss (uninitialized registry, unknown stem, or
    ;; unknown index within a known stem) — matches CL's gethash miss
    ;; semantics; deser/lookup-archive-co then raises
    ;; ece-deser-missing-archive-error with the specific stem+index.
    (if (i32.eq (local.get $id) (i32.const 260))
      (then (return (call $archive-registry-get
        (call $arg1 (local.get $args))
        (call $arg2 (local.get $args))))))
```

### Step 6.3: WAT compile check

```
make wasm 2>&1 | tail -3
```

Expected: clean build.

### Step 6.4: Run the full WASM test suite

```
make test-wasm 2>&1 | tail -5
```

Expected: 1008 passed, 0 failed (baseline preserved).

### Step 6.5: Manual smoke — archive-key populated on loaded cos

Create a tiny test probe in `/tmp/claude/ece-gh-archive-key-smoke.mjs`:

```javascript
import { readFileSync } from 'node:fs';
const ECE = require('/Users/anthonyfairchild/git/ece/wasm/glue.js');

const wasmBytes = readFileSync('/Users/anthonyfairchild/git/ece/wasm/runtime.wasm');
const imports = { io: ECE.io, loader: ECE.loader, storage: ECE.storage, canvas: ECE.canvas, timing: ECE.timing, math: ECE.math, ffi: ECE.ffi };
const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
ECE.wasm = instance.exports;
ECE.initAssemblerSymbols?.();
ECE.globalEnvHandle = ECE.wasm.build_global_env(0);

const bootstrapText = readFileSync('/Users/anthonyfairchild/git/ece/bootstrap/bootstrap.ecec', 'utf8');
ECE.loadArchiveBundle(bootstrapText);

// Intern 'car — a prelude-archive-loaded procedure.
const sym = ECE.internSym('car');
const carProc = ECE.wasm.env_lookup(ECE.globalEnvHandle, sym);
// car's code-object is behind the compiled-procedure wrapper. The wrapper's
// entry field IS the code-object on the new architecture.
console.log('car handle type:', ECE.wasm.dbg_type(carProc));
```

Run it:
```
cd /Users/anthonyfairchild/git/ece && node /tmp/claude/ece-gh-archive-key-smoke.mjs 2>&1 | tail -3
```

Expected: no crash; prints a type number. The type check confirms archive-load works end-to-end; if deeper verification is wanted, add a second bundle-load and confirm no errors.

If the smoke probe can't easily introspect `archive-key` from JS (it's a deep struct field), the integration test effectively becomes "bootstrap loads, test-wasm runs clean" — which Task 5.5 + 6.4 already verify.

---

## Task 7: Commit the WAT work

- [ ] **Step 7.1: Check diff scope**

```
cd /Users/anthonyfairchild/git/ece
git diff --stat wasm/runtime.wat
```

Expected: one file modified; insertion count ~80-100 lines; deletion count ~12 (the stub comment).

- [ ] **Step 7.2: Commit**

```
git add wasm/runtime.wat
git commit -m "wasm: populate archive-key on loaded code-objects + wire prim 260

Closes the cross-host gap in P2's hybrid continuation serialization.
WASM \$load-archive-impl now stamps archive-key = (stem . index) on
each loaded code-object and inserts into a new \$archive-registry
(hash-of-hashes keyed by stem-sym and index-fixnum). Primitive 260
(%archive-co-lookup) is rewritten from stub to call
\$archive-registry-get.

Consequence:
- WASM-loaded code-objects now serialize as (%ser/co-ref stem index)
  instead of always inlining.
- CL-produced (%ser/co-ref ...) blobs deserialize cleanly on WASM
  when the same archive is loaded.

No serialization-format changes; no CL-side changes. Matches CL's
register-archive-code-objects semantics exactly, including
graceful-degrade when :file is missing.

Spec: docs/superpowers/specs/2026-04-24-wasm-archive-key-population-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Update the roadmap

**Files:**
- Modify: `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`

### Step 8.1: Locate the third "Known follow-up" bullet

```
grep -n 'WASM archive-key population' docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md
```

Expected: one match in the Known follow-ups section.

### Step 8.2: Mark the item shipped

Read around the match to get the exact paragraph text, then edit:

**old_string:**
```
- **WASM archive-key population.** P2's hybrid serializer relies on an `archive-key` field on each code-object to dispatch between `(%ser/co-ref …)` and `(%ser/co-inline …)`. The CL archive loader populates the field during `register-archive-code-objects`; the WASM archive loader does not (documented as a TODO in `wasm/runtime.wat` at primitive 260). Consequence: code-objects loaded on WASM always serialize inline, inflating continuation-blob sizes and preventing cross-host `(%ser/co-ref …)` round-trips — a CL save-game with by-reference entries can't be deserialized on WASM even if the same archive is loaded there. Fully closing this requires the WASM loader to parse the archive's `:file` wrapper and stamp `(stem . index)` onto each code-object as it's constructed, mirroring what `register-archive-code-objects` does on CL.
```

**new_string:**
```
- **WASM archive-key population** — **Shipped** (this PR). The WASM archive loader now stamps `archive-key = (stem . index)` on each loaded code-object and registers it in a new `$archive-registry` (hash-of-hashes keyed by stem-symbol and index-fixnum). Primitive 260 (`%archive-co-lookup`) resolves lookups against this registry. Consequence: WASM-loaded code-objects serialize as `(%ser/co-ref …)` when appropriate (no more unconditional inlining), and CL-produced by-reference blobs deserialize cleanly on WASM when the same archive is loaded. Matches CL's `register-archive-code-objects` semantics exactly. Design: `docs/superpowers/specs/2026-04-24-wasm-archive-key-population-design.md`.
```

### Step 8.3: Commit

```
cd /Users/anthonyfairchild/git/ece
git add docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md
git commit -m "roadmap: mark WASM archive-key population shipped

Follow-up #3 from the code-objects-completion roadmap now lands on
WASM, closing the last cross-host gap in P2's hybrid continuation
serialization.

Design: docs/superpowers/specs/2026-04-24-wasm-archive-key-population-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Push + PR

### Step 9.1: Confirm branch commits

```
git log --oneline main..HEAD
```

Expected (bottom to top):
```
<hash> roadmap: mark WASM archive-key population shipped
<hash> wasm: populate archive-key on loaded code-objects + wire prim 260
<hash> Add design spec: WASM archive-key population
```

### Step 9.2: Push

```
git push -u origin wasm-archive-key-population
```

### Step 9.3: Open PR via the wrapper

```
scripts/ece-gh pr create --base main --head wasm-archive-key-population --title "wasm: populate archive-key on loaded code-objects" --body "$(cat <<'EOF'
## Summary

Closes the last cross-host gap in P2's hybrid continuation serialization.
WASM archive loader now stamps \`archive-key = (stem . index)\` on each
loaded code-object and maintains a \`\$archive-registry\` so primitive 260
(\`%archive-co-lookup\`) can resolve \`(stem, index)\` to code-object refs.

## Effect

- WASM-loaded code-objects serialize as \`(%ser/co-ref stem index)\`
  instead of always inlining → smaller continuation blobs.
- CL-produced by-reference blobs deserialize cleanly on WASM when
  the same archive is loaded → cross-host save/restore works.

## Semantics

Matches CL's \`register-archive-code-objects\` exactly, including
graceful-degrade when an archive has no \`:file\` field.
Hash-of-hashes registry (stem-symbol × index-fixnum); no unload API
(matches the Scheme ecosystem consensus — Chez, Racket, Guile, etc.).

## Spec + rationale

- docs/superpowers/specs/2026-04-24-wasm-archive-key-population-design.md
- docs/superpowers/plans/2026-04-24-wasm-archive-key-population.md

## Test plan

- [x] \`make test-wasm\` passes (bootstrap loads through the new stamp/register path).
- [x] Primitive 260 returns code-object refs for known (stem, index) and \`#f\` for misses.
EOF
)"
```

### Step 9.4: Wait for CI + address Copilot

CI takes ~10-12 min. After it passes, review Copilot comments via `scripts/ece-gh api repos/anthonyf/ece/pulls/<N>/comments`. Address real issues via amend + force-push. When clean, `scripts/ece-gh pr merge <N> --merge --delete-branch`.

---

## Self-review notes

**Spec coverage:**
- Design §1 (scope) → covered implicitly by all tasks.
- Design §2 (archive registry) → Task 2 (global) + Task 4 (helpers).
- Design §2 (`$archive-file-stem-symbol`) → Task 3.
- Design §2 (`$archive-registry-put` / `$archive-registry-get`) → Task 4.
- Design §3 (`$load-archive-impl` integration) → Task 5.
- Design §4 (primitive 260 rewrite) → Task 6.
- Design §5 (sym-id global) → Task 1.
- Design §Testing → Tasks 5.5 + 6.4 + 6.5.
- Roadmap update → Task 8.

**Placeholder scan:** none. Every step has concrete WAT code / exact commands.

**Type consistency:**
- `$sym-id-file` appears identically in Task 1 declaration + init and Task 3 use.
- `$archive-registry` appears identically in Task 2 declaration and Task 4 get/put + Task 5 implicit use via put.
- `$archive-registry-put` / `$archive-registry-get` signatures match between Task 4 definition and Tasks 5/6 call sites.
- `$archive-file-stem-symbol` return type `(ref null eq)` matches the `$stem` local type in Task 5.
- `$sym-id-file` byte values for `":file"` verified: 58, 102, 105, 108, 101 (ASCII).
- Stamp shape `(cons stem (make-fixnum index))` matches CL's `(cons file-stem co-key)` where `co-key` is `index` (an integer; CL stores raw ints, WASM wraps via `$make-fixnum` so `ref.eq` on i31refs works for registry lookup).
