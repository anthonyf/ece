# WASM Archive Loader + `$comp-space` Retirement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port `parse-archive-sexp` to WAT so the WASM runtime can boot the `(ecec-archive version 2 ...)` format, retire the `$comp-space` infrastructure, and restore `make test` as a single CI gate.

**Architecture:** New `$load-archive-impl` function in `wasm/runtime.wat` mirrors the CL two-pass parser (skeleton then co-ref patching). New JS glue helpers (`loadArchiveText`, `runCodeObject`) replace `loadEcecBundleText` / `run`. After the new path is validated end-to-end by `make test-wasm`, delete the legacy loader, the `$comp-space` struct + registry, the `$register-space`/`$get-space`/`$create-space-internal` functions, the legacy branch of `$execute`, the trapped `%space-*` primitive IDs, and the legacy source-map infrastructure.

**Tech Stack:** WebAssembly Text (WAT) with GC proposal, JavaScript (ES2020), Make, Common Lisp (SBCL) for the CL reference implementation, ECE Scheme for test suites.

**Spec:** `docs/superpowers/specs/2026-04-20-wasm-archive-loader-design.md`
**Roadmap:** `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`
**Base branch:** `wasm-archive-loader` (stacked on `per-procedure-code-objects`; will merge after PR #163 merges first)

---

## Pre-flight

Before starting any task below, run the baseline-green check. If this fails, stop and investigate — something drifted on `per-procedure-code-objects` since the spec was written.

- [ ] **Pre-flight Step 1: Verify base-branch test-wasm is red exactly where expected**

Run:
```
make clean-fasl 2>/dev/null || true
make ece
make test-wasm 2>&1 | tail -40
```

Expected: the "illegal cast" trap occurs while loading `bootstrap.ecec` in `$load_ecec_impl` (around line 6477). Any other failure is a baseline drift — stop and reconcile before proceeding.

- [ ] **Pre-flight Step 2: Verify reference symbols exist**

Run:
```
grep -n "parse-archive-sexp\|archive-plist-get\|archive-patch-co-refs" src/runtime.lisp
grep -n '\$code-object\|\$init-code-obj\|\$ecec-parse-instr\|\$ecec-read-sexp' wasm/runtime.wat | head
```

Expected: matches on both. If no matches, the branch is not correctly stacked on `per-procedure-code-objects`.

---

## Task 1: Add WAT archive-parse helpers

**Why first:** `$load-archive-impl` depends on these two helpers. Adding them first lets Task 2 be a straight port of the CL parser without intermixed helper definitions.

**Files:**
- Modify: `wasm/runtime.wat` — insert new functions just before `$load_ecec_impl` (currently around line 6453)

### Subtask 1a: `$archive-plist-get`

- [ ] **Step 1: Open `wasm/runtime.wat` at line 6452**

Locate the existing comment `;; Load one ecec section from current cursor position.` at line 6453. Insertion point is the blank line just above it.

- [ ] **Step 2: Insert the helper function**

Paste this block at the insertion point (blank line above line 6453):

```wat
  ;; Archive plist walk: find VALUE for KEY in a plist (k1 v1 k2 v2 ...).
  ;; Returns null if KEY is not present or PLIST runs out.
  ;; KEY matching is by symbol eq (symbol-id equality).
  (func $archive-plist-get (param $plist (ref null eq)) (param $key (ref $symbol))
                           (result (ref null eq))
    (local $cur (ref null eq))
    (local $k (ref null eq))
    (local $key-id i32)
    (local.set $cur (local.get $plist))
    (local.set $key-id (struct.get $symbol $id (local.get $key)))
    (block $done (loop $walk
      (br_if $done (ref.is_null (local.get $cur)))
      (br_if $done (call $is-null (local.get $cur)))
      (br_if $done (i32.eqz (call $is-pair (local.get $cur))))
      (local.set $k (call $xcar (local.get $cur)))
      (if (call $is-symbol (local.get $k))
        (then
          (if (i32.eq
                (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $k)))
                (local.get $key-id))
            (then
              ;; found key — next cons has the value
              (local.set $cur (call $xcdr (local.get $cur)))
              (br_if $done (ref.is_null (local.get $cur)))
              (return (call $xcar (local.get $cur)))))))
      ;; skip two cells: key and value
      (local.set $cur (call $xcdr (local.get $cur)))
      (br_if $done (ref.is_null (local.get $cur)))
      (local.set $cur (call $xcdr (local.get $cur)))
      (br $walk)))
    (ref.null eq))
```

- [ ] **Step 3: Compile WAT to verify syntax**

Run:
```
make wasm 2>&1 | tail -20
```

Expected: clean build (no wat2wasm errors). If the build pipeline is hidden behind another target, check `Makefile` for the `.wasm` rule — `wasm/runtime.wasm` should rebuild.

- [ ] **Step 4: Commit checkpoint (optional; bundled into Task 1 commit)**

Do not commit yet — subtask 1b goes in the same commit.

### Subtask 1b: `$archive-patch-co-refs`

- [ ] **Step 1: Locate insertion point just after `$archive-plist-get`**

Insertion point is the blank line immediately after the closing `)` of the function added in subtask 1a.

- [ ] **Step 2: Insert the recursive tree walker**

Paste this block:

```wat
  ;; Recursive walk: return a new tree identical to TREE except that every
  ;; subtree shaped (co-ref N) is replaced by (array.get $co-vec N), where
  ;; N is a positive fixnum index into the archive entries.
  ;; Traps "Archive co-ref out of range" if N >= COUNT.
  (func $archive-patch-co-refs (param $tree (ref null eq))
                               (param $cos (ref $co-vec))
                               (param $count i32)
                               (result (ref null eq))
    (local $head (ref null eq))
    (local $n i32)
    ;; Null or non-pair: return tree unchanged.
    (if (ref.is_null (local.get $tree)) (then (return (local.get $tree))))
    (if (i32.eqz (call $is-pair (local.get $tree)))
      (then (return (local.get $tree))))
    (local.set $head (call $xcar (local.get $tree)))
    ;; Check (co-ref N) shape: pair whose car is symbol "co-ref"
    (if (call $is-symbol (local.get $head))
      (then
        (if (i32.eq
              (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $head)))
              (global.get $sym-id-co-ref))
          (then
            ;; N = (car (cdr tree)) as fixnum
            (local.set $n (call $fixnum-value
              (call $xcar (call $xcdr (local.get $tree)))))
            (if (i32.ge_s (local.get $n) (local.get $count))
              (then (unreachable)))  ;; co-ref out of range
            (return (array.get $co-vec (local.get $cos) (local.get $n)))))))
    ;; General case: recurse into car and cdr, cons back.
    (return (call $cons
      (call $archive-patch-co-refs
        (call $xcar (local.get $tree)) (local.get $cos) (local.get $count))
      (call $archive-patch-co-refs
        (call $xcdr (local.get $tree)) (local.get $cos) (local.get $count)))))
```

- [ ] **Step 3: Add `$co-vec` type and `$sym-id-co-ref` global at the top of the module**

Search for the existing array type declarations (around line 1463 `$space-array`). Add, just after that line:

```wat
  ;; Vector of code-objects, used by the archive loader for co-ref patching.
  (type $co-vec (array (mut (ref null eq))))
```

Search for existing sym-id globals (grep `global \$sym-id-`). At the end of that block (or near `$ecec-parse-instr`'s symbol-id lookups, ~line 6336), add:

```wat
  (global $sym-id-co-ref (mut i32) (i32.const 0))
```

Find the `$init-ascii-chars` startup function (`(start $init-ascii-chars)` near the bottom, around line 7288). Locate its body (search the function definition). At the end of its body, before the closing `)`, add:

```wat
    (global.set $sym-id-co-ref
      (struct.get $symbol $id (call $intern-symbol-string "co-ref")))
```

Replace `"co-ref"` in the above with whatever form the existing code uses to intern a bare ASCII symbol from a string literal — grep `intern-symbol` / `intern-sym` / similar helpers to find the idiomatic helper already in use. Example from the current file for reference: search `call \$intern-` around lines 500-900.

- [ ] **Step 4: Rebuild WAT and verify**

Run:
```
make wasm 2>&1 | tail -20
```

Expected: clean build. If `$sym-id-co-ref` errors with "not found", the init path wasn't linked correctly — check the `start` function is still `$init-ascii-chars` and that the new line is inside its body.

- [ ] **Step 5: Stage the changes and move to Task 2**

Do not commit yet — `$load-archive-impl` (Task 2) goes in the same commit.

```
git diff --stat wasm/runtime.wat
```

Expected: one file changed, roughly +60 / -0 lines.

---

## Task 2: Add `$load-archive-impl` and new exports

**Why second:** builds on Task 1's helpers. Produces the parser that the JS glue will call in Task 3.

**Files:**
- Modify: `wasm/runtime.wat` — new function just after the Task 1 helpers; new exports near the existing `(export "load_ecec")` around line 6594

### Subtask 2a: Write `$load-archive-impl`

- [ ] **Step 1: Locate insertion point**

Immediately after the `$archive-patch-co-refs` function added in Task 1. Place the new function there so all archive-related helpers stay clustered. Do not delete `$load_ecec_impl` yet — legacy path stays until Task 5.

- [ ] **Step 2: Insert the two-pass loader**

Paste this block:

```wat
  ;; Parse a (ecec-archive version 2 file "..." entries (<entry>...)) sexp
  ;; and return the init code-object (entry 0). Two passes: skeleton first,
  ;; then instructions + co-ref patching. Cursor must be set up before calling
  ;; (either via the load_archive export or a direct $ecec-pos/$ecec-end pair).
  (func $load-archive-impl (result (ref $code-object))
    (local $archive (ref null eq))
    (local $head (ref null eq))
    (local $version (ref null eq))
    (local $entries (ref null eq))
    (local $count i32)
    (local $i i32)
    (local $cos (ref $co-vec))
    (local $entry (ref null eq))
    (local $fields (ref null eq))
    (local $co (ref $code-object))
    (local $labels-alist (ref null eq))
    (local $label-pair (ref null eq))
    (local $raw-instrs (ref null eq))
    (local $instr-sexp (ref null eq))
    (local $patched (ref null eq))
    (local $parsed-instr (ref null $instr))
    (local $pc i32)
    (local $entries-iter (ref null eq))

    ;; Read archive sexp.
    (local.set $archive (call $ecec-read-sexp))
    ;; Head symbol check: (ecec-archive ...)
    (local.set $head (call $xcar (local.get $archive)))
    (if (i32.eq
          (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $head)))
          (global.get $sym-id-ecec-header))
      (then (unreachable)))  ;; legacy header — "make bootstrap" required
    (if (i32.ne
          (struct.get $symbol $id (ref.cast (ref $symbol) (local.get $head)))
          (global.get $sym-id-ecec-archive))
      (then (unreachable)))  ;; unknown archive head

    ;; Version check: must be 2.
    (local.set $version
      (call $archive-plist-get (call $xcdr (local.get $archive))
            (call $intern-symbol-string "version")))
    (if (i32.ne (call $fixnum-value (local.get $version)) (i32.const 2))
      (then (unreachable)))  ;; version mismatch — "make bootstrap" required

    ;; Entries list.
    (local.set $entries
      (call $archive-plist-get (call $xcdr (local.get $archive))
            (call $intern-symbol-string "entries")))

    ;; Count entries.
    (local.set $count (i32.const 0))
    (local.set $entries-iter (local.get $entries))
    (block $cdone (loop $ccount
      (br_if $cdone (ref.is_null (local.get $entries-iter)))
      (br_if $cdone (call $is-null (local.get $entries-iter)))
      (br_if $cdone (i32.eqz (call $is-pair (local.get $entries-iter))))
      (local.set $count (i32.add (local.get $count) (i32.const 1)))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (br $ccount)))

    ;; Allocate code-object vector.
    (local.set $cos (array.new $co-vec (ref.null eq) (local.get $count)))

    ;; ─── Pass 1: skeletons ───
    (local.set $i (i32.const 0))
    (local.set $entries-iter (local.get $entries))
    (block $done1 (loop $pass1
      (br_if $done1 (i32.ge_s (local.get $i) (local.get $count)))
      (local.set $entry (call $xcar (local.get $entries-iter)))
      ;; Entry shape: (code-object name <v> arity <v> source-loc <v> labels <alist> instructions <list>)
      (local.set $fields (call $xcdr (local.get $entry)))
      (local.set $co (struct.new $code-object
        (array.new_default $instr-vec (i32.const 32))
        (i32.const 0)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)
        (ref.null eq)))
      ;; Set name / arity / source-loc (may all be #f/null).
      (struct.set $code-object $name (local.get $co)
        (call $archive-plist-get (local.get $fields)
              (call $intern-symbol-string "name")))
      (struct.set $code-object $arity (local.get $co)
        (call $archive-plist-get (local.get $fields)
              (call $intern-symbol-string "arity")))
      (struct.set $code-object $source-loc (local.get $co)
        (call $archive-plist-get (local.get $fields)
              (call $intern-symbol-string "source-loc")))
      ;; Walk labels alist and populate the code-object's label hash table.
      (local.set $labels-alist
        (call $archive-plist-get (local.get $fields)
              (call $intern-symbol-string "labels")))
      (block $ldone (loop $lwalk
        (br_if $ldone (ref.is_null (local.get $labels-alist)))
        (br_if $ldone (call $is-null (local.get $labels-alist)))
        (br_if $ldone (i32.eqz (call $is-pair (local.get $labels-alist))))
        (local.set $label-pair (call $xcar (local.get $labels-alist)))
        ;; Ensure labels hash-table exists
        (if (ref.is_null (struct.get $code-object $labels (local.get $co)))
          (then
            (struct.set $code-object $labels (local.get $co)
              (struct.new $hash-table
                (array.new_default $hash-keys (i32.const 16))
                (array.new_default $hash-vals (i32.const 16))
                (i32.const 0)))))
        (call $hash-set-impl
          (ref.cast (ref $hash-table)
            (struct.get $code-object $labels (local.get $co)))
          (call $xcar (local.get $label-pair))
          (call $xcdr (local.get $label-pair)))
        (local.set $labels-alist (call $xcdr (local.get $labels-alist)))
        (br $lwalk)))
      (array.set $co-vec (local.get $cos) (local.get $i) (local.get $co))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $pass1)))

    ;; ─── Pass 2: instructions ───
    (local.set $i (i32.const 0))
    (local.set $entries-iter (local.get $entries))
    (block $done2 (loop $pass2
      (br_if $done2 (i32.ge_s (local.get $i) (local.get $count)))
      (local.set $entry (call $xcar (local.get $entries-iter)))
      (local.set $fields (call $xcdr (local.get $entry)))
      (local.set $co
        (ref.cast (ref $code-object)
          (array.get $co-vec (local.get $cos) (local.get $i))))
      (local.set $raw-instrs
        (call $archive-plist-get (local.get $fields)
              (call $intern-symbol-string "instructions")))
      (local.set $pc (i32.const 0))
      (block $idone (loop $iwalk
        (br_if $idone (ref.is_null (local.get $raw-instrs)))
        (br_if $idone (call $is-null (local.get $raw-instrs)))
        (br_if $idone (i32.eqz (call $is-pair (local.get $raw-instrs))))
        (local.set $instr-sexp (call $xcar (local.get $raw-instrs)))
        (local.set $patched
          (call $archive-patch-co-refs
            (local.get $instr-sexp) (local.get $cos) (local.get $count)))
        ;; Only parse non-symbol (symbol = bare label, skipped).
        (if (i32.eqz (call $is-symbol (local.get $patched)))
          (then
            (local.set $parsed-instr
              (call $ecec-parse-instr
                (local.get $patched)
                (i32.const -1)  ;; space-id unused in parse path
                (local.get $pc)
                (struct.get $code-object $labels (local.get $co))))
            (if (i32.eqz (ref.is_null (local.get $parsed-instr)))
              (then
                (call $co-push-instr (local.get $co)
                      (ref.as_non_null (local.get $parsed-instr)))
                (local.set $pc (i32.add (local.get $pc) (i32.const 1)))))))
        (local.set $raw-instrs (call $xcdr (local.get $raw-instrs)))
        (br $iwalk)))
      ;; Final $len on the code-object.
      (struct.set $code-object $len (local.get $co) (local.get $pc))
      (local.set $entries-iter (call $xcdr (local.get $entries-iter)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $pass2)))

    ;; Return entry 0 = init code-object.
    (ref.cast (ref $code-object)
      (array.get $co-vec (local.get $cos) (i32.const 0))))
```

- [ ] **Step 3: Add `$sym-id-ecec-archive` and `$sym-id-ecec-header` globals**

At the same location where you added `$sym-id-co-ref` in Task 1 Step 3, add:

```wat
  (global $sym-id-ecec-archive (mut i32) (i32.const 0))
  (global $sym-id-ecec-header  (mut i32) (i32.const 0))
```

In `$init-ascii-chars`, add alongside the existing `$sym-id-co-ref` init:

```wat
    (global.set $sym-id-ecec-archive
      (struct.get $symbol $id (call $intern-symbol-string "ecec-archive")))
    (global.set $sym-id-ecec-header
      (struct.get $symbol $id (call $intern-symbol-string "ecec-header")))
```

- [ ] **Step 4: Add `$co-push-instr` helper**

Grep for an existing helper that appends to a `$code-object`'s `$instrs` vector:
```
grep -n 'struct.set \$code-object \$instrs\|array.set \$instr-vec' wasm/runtime.wat
```

If a suitable helper exists (e.g., used by `$finalize-co-pending-instrs`), reuse it. Otherwise add, just before `$load-archive-impl`:

```wat
  ;; Append an instruction to a code-object's $instrs vec at its current $len.
  ;; Grows the vec if needed.
  (func $co-push-instr (param $co (ref $code-object)) (param $instr (ref $instr))
    (local $vec (ref $instr-vec))
    (local $cap i32)
    (local $len i32)
    (local $newvec (ref $instr-vec))
    (local $j i32)
    (local.set $vec (struct.get $code-object $instrs (local.get $co)))
    (local.set $cap (array.len (local.get $vec)))
    (local.set $len (struct.get $code-object $len (local.get $co)))
    (if (i32.ge_s (local.get $len) (local.get $cap))
      (then
        (local.set $newvec (array.new_default $instr-vec
          (i32.mul (local.get $cap) (i32.const 2))))
        (local.set $j (i32.const 0))
        (block $cpdone (loop $cp
          (br_if $cpdone (i32.ge_s (local.get $j) (local.get $cap)))
          (array.set $instr-vec (local.get $newvec) (local.get $j)
            (array.get $instr-vec (local.get $vec) (local.get $j)))
          (local.set $j (i32.add (local.get $j) (i32.const 1)))
          (br $cp)))
        (struct.set $code-object $instrs (local.get $co) (local.get $newvec))
        (local.set $vec (local.get $newvec))))
    (array.set $instr-vec (local.get $vec) (local.get $len) (local.get $instr))
    (struct.set $code-object $len (local.get $co)
      (i32.add (local.get $len) (i32.const 1))))
```

Note: Pass 2 above manages `$pc` directly and sets `$len` at the end, but also calls `$co-push-instr` which bumps `$len`. Pick one mechanism — the simpler option is: delete the final `(struct.set $code-object $len (local.get $co) (local.get $pc))` line in Pass 2 since `$co-push-instr` already increments `$len`.

- [ ] **Step 5: Reconcile the `$len` bookkeeping**

Edit `$load-archive-impl` — remove the stray `(struct.set $code-object $len (local.get $co) (local.get $pc))` line near the end of Pass 2. `$co-push-instr` already increments `$len` eagerly.

- [ ] **Step 6: Rebuild WAT to verify**

Run:
```
make wasm 2>&1 | tail -40
```

Expected: clean build. Common errors to investigate:
- "symbol $sym-id-ecec-archive not found" — `$init-ascii-chars` edits didn't take.
- "array.new expects ref type" — `$co-vec` declaration wasn't added in Task 1 Step 3.
- "cannot cast ref null eq to ref $code-object" — a `ref.cast` is needed before `struct.get $code-object $...`; re-read the function for missing casts.

### Subtask 2b: Add the new exports

- [ ] **Step 1: Locate the existing `load_ecec` export at line ~6594**

Grep:
```
grep -n '(export "load_ecec"\|(export "run"' wasm/runtime.wat
```

- [ ] **Step 2: Insert new exports adjacent to the existing ones**

Immediately after the `(export "ecec_has_more")` block (~line 6607), insert:

```wat
  ;; New archive-format entry point. Returns a handle wrapping the init code-object.
  (func (export "load_archive") (param $offset i32) (param $len i32) (result i32)
    (global.set $ecec-pos (local.get $offset))
    (global.set $ecec-end (i32.add (local.get $offset) (local.get $len)))
    (call $alloc-handle (call $load-archive-impl)))

  ;; Run an init code-object with the given environment handle.
  (func (export "run_code_object") (param $co-handle i32) (param $env-handle i32)
        (result i32)
    (call $alloc-handle
      (call $execute
        (i32.const 0) (i32.const 0)  ;; $init-space-id, $init-pc — unused in code-object mode
        (call $deref-handle (local.get $env-handle))
        (call $deref-handle (local.get $co-handle)))))
```

- [ ] **Step 3: Rebuild WAT and verify**

Run:
```
make wasm 2>&1 | tail -20
```

Expected: clean build. Both new exports show up in the module.

- [ ] **Step 4: Quick smoke check — exports are callable**

Run:
```
node -e 'const ECE = require("./wasm/glue.js"); ECE.init("./wasm/runtime.wasm", null).then(() => { console.log("exports:", Object.keys(ECE.wasm).filter(k => k.includes("archive") || k.includes("code_object"))); }).catch(e => { console.error(e); process.exit(1); });'
```

Expected output includes `load_archive` and `run_code_object`. If empty, the `.wasm` rebuild did not pick up the WAT edits — `make wasm` may be caching; try `rm wasm/runtime.wasm && make wasm`.

- [ ] **Step 5: Commit Task 1 + Task 2 together**

```
git add wasm/runtime.wat
git commit -m "$(cat <<'EOF'
wasm: add archive-format loader and exports

Ports CL's parse-archive-sexp to WAT. Two-pass: pass 1 builds
code-object skeletons with labels, pass 2 constructs instructions
with (co-ref N) patched to direct code-object refs.

Adds helpers \$archive-plist-get, \$archive-patch-co-refs,
\$co-push-instr. Adds globals \$sym-id-ecec-archive,
\$sym-id-ecec-header, \$sym-id-co-ref wired up in
\$init-ascii-chars.

Adds load_archive and run_code_object exports. Legacy paths
remain in place; JS glue switches over in the next commit.

Spec: docs/superpowers/specs/2026-04-20-wasm-archive-loader-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: JS glue switchover

**Why next:** wires the new loader into the bootstrap path so `make test-wasm` actually exercises it end-to-end.

**Files:**
- Modify: `wasm/glue.js:290-340` (new helpers) and `:444` (bootstrap call site)

- [ ] **Step 1: Read current glue.js structure**

```
sed -n '285,340p' wasm/glue.js
```

Expected: `loadEcecText` and `loadEcecBundleText` helpers visible.

- [ ] **Step 2: Add `loadArchiveText` and `runCodeObject`**

Insert immediately after the existing `loadEcecBundleText` closing `},` (around line 336):

```javascript
  // Load a .ecec archive (single top-level sexp, no sections).
  // Returns a handle wrapping the init code-object.
  loadArchiveText(text) {
    const w = ECE.wasm;
    text = text.trimEnd();
    const needed = text.length * 2;
    const currentBytes = w.memory.buffer.byteLength;
    if (needed > currentBytes) {
      const pages = Math.ceil((needed - currentBytes) / 65536);
      w.memory.grow(pages);
    }
    const mem = new Uint16Array(w.memory.buffer);
    for (let i = 0; i < text.length; i++) {
      mem[i] = text.charCodeAt(i);
    }
    return w.load_archive(0, text.length);
  },

  // Execute a loaded archive's init code-object.
  runCodeObject(coHandle) {
    return ECE.wasm.run_code_object(coHandle, ECE.globalEnvHandle);
  },
```

- [ ] **Step 3: Switch the bootstrap call site (line 444)**

Current:
```javascript
    ECE.loadEcecBundleText(text);
```

Replace with:
```javascript
    const co = ECE.loadArchiveText(text);
    ECE.runCodeObject(co);
```

- [ ] **Step 4: Rebuild and run test-wasm**

```
make ece && make test-wasm 2>&1 | tail -40
```

Expected: `test-wasm` passes with zero failures. The bootstrap.ecec is now being loaded via the archive path — the "illegal cast" trap that motivated this work should be gone.

If the run traps: read the trap position. Common causes:
- "unreachable executed" inside `$load-archive-impl` → version gate fired. Check `bootstrap.ecec` head symbol; if it says `ecec-header`, the archive regeneration never happened on this branch — inspect `per-procedure-code-objects` state.
- "cast failed" during pass 1 → a field lookup returned null where a non-null value was expected. Add `console.log` JS-side to inspect which entry fails, then trace back to archive shape.
- Hang → infinite loop in `$archive-plist-get` or `$archive-patch-co-refs`. Verify the `$cur = $xcdr $cur` step runs at each iteration.

- [ ] **Step 5: Run test-web-server and test-web-apps for parity**

```
make test-web-server 2>&1 | tail -20
make test-web-apps 2>&1 | tail -20
```

Expected: both pass. These exercise the same JS glue in Node and browser-like harnesses.

- [ ] **Step 6: Commit**

```
git add wasm/glue.js
git commit -m "$(cat <<'EOF'
wasm/glue: switch bootstrap to loadArchiveText + runCodeObject

The bootstrap loader now uses the new WAT archive-format path.
test-wasm, test-web-server, and test-web-apps all pass.

The legacy loadEcecText / loadEcecBundleText helpers remain in
place for Commit 3 cleanup alongside the WAT legacy exports.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Delete legacy exports and JS helpers

**Why next:** with the new path validated end-to-end, legacy `load_ecec*` and `run` become dead code. Delete them before touching `$comp-space` so the retirement step has fewer live call sites to worry about.

**Files:**
- Modify: `wasm/runtime.wat` — delete `$load_ecec_impl` and the three legacy exports
- Modify: `wasm/glue.js` — delete `loadEcecText`, `loadEcecBundleText`, `runSpace`
- Modify: any external caller — grepped below

- [ ] **Step 1: Find all external callers of the legacy surface**

```
grep -rn 'loadEcec\|runSpace\|load_ecec\|ecec_has_more\|\.run(' --include='*.js' --include='*.html' --include='*.scm' --include='*.ecec' . | grep -v 'node_modules\|\.wasm\|:.*wasm/runtime\.wat\|:.*wasm/glue\.js' | head -40
```

Expected: a small set (under 10 matches) across `webapps/`, `tests/web-apps/`, `tests/web-server/`, `share/ece/repl-*`. Record the list for Step 3.

- [ ] **Step 2: Delete WAT legacy loader and exports**

In `wasm/runtime.wat`:
- Delete `$load_ecec_impl` function (around line 6456; extends to ~6590).
- Delete `(export "load_ecec")` wrapper (around line 6594).
- Delete `(export "load_ecec_continue")` wrapper (~line 6602).
- Delete `(export "ecec_has_more")` wrapper (~line 6607).
- Delete `(export "run")` wrapper (~line 7279).

Also delete the `$ecec-register-macros` function and `$register-source-map` function and any source-map hash-table global set up solely for them. Grep:
```
grep -n '\$ecec-register-macros\|\$register-source-map\|\$source-maps\b' wasm/runtime.wat
```

Expected: each is defined once and called only from the now-deleted `$load_ecec_impl`. If a reference survives outside the loader, leave the definition in place and flag it (subagent: report the surviving caller).

- [ ] **Step 3: Delete JS legacy helpers**

In `wasm/glue.js`:
- Delete `loadEcecText` (around line 295-310).
- Delete `loadEcecBundleText` (around line 312-336).
- Delete `runSpace` (around line 450-458).

- [ ] **Step 4: Update external callers**

For each match from Step 1:
- `loadEcecText(text)` → `loadArchiveText(text)` (then whatever the caller does with the return value — the handle is now a code-object handle).
- `loadEcecBundleText(text)` → `const co = loadArchiveText(text); runCodeObject(co);`
- `runSpace(name, pc)` → callers that used `runSpace` were trying to invoke compiled code by space-name. Post-retirement, this path is meaningless. Replace with whatever the new surface provides (likely: these callers are test harnesses that can be deleted).
- `w.run(space, pc, env)` → `w.run_code_object(co, env)` if the call was loading + running; delete if it was pure REPL (REPL now uses the compile-and-go path).
- `w.load_ecec(...)` / `w.load_ecec_continue(...)` / `w.ecec_has_more()` → replace with `w.load_archive(...)`.

Any match you can't cleanly migrate: flag it and stop. Do not leave the file half-migrated.

- [ ] **Step 5: Rebuild and test**

```
make ece && make test-wasm && make test-web-server && make test-web-apps 2>&1 | tail -40
```

Expected: all three pass. If `test-web-apps` fails with "load_ecec is not a function", a caller was missed in Step 1 — re-grep without the `--include` filters.

- [ ] **Step 6: Commit**

```
git add wasm/runtime.wat wasm/glue.js <any-external-files-touched>
git commit -m "$(cat <<'EOF'
wasm: delete legacy load_ecec / run / *BundleText surface

Removes \$load_ecec_impl, \$ecec-register-macros,
\$register-source-map, and the load_ecec / load_ecec_continue /
ecec_has_more / run exports.

Deletes loadEcecText, loadEcecBundleText, runSpace from glue.js.
Updates external callers in <list-each-file-touched>.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Retire `$comp-space`

**Why next:** with the legacy loader gone, nothing constructs `$comp-space` values any more. The struct, registry, and helpers are now pure dead code. Executor's legacy branch is unreachable.

**Files:**
- Modify: `wasm/runtime.wat` — delete types, globals, functions, shrink `$execute`, rename locals

### Subtask 5a: Delete types, globals, allocator functions

- [ ] **Step 1: Delete `$comp-space` type**

Around line 1441. Delete the whole `(type $comp-space (struct ...))` block.

- [ ] **Step 2: Delete `$space-array` type and `$spaces` / `$space-count` globals**

Around lines 1463-1466.

- [ ] **Step 3: Delete `$register-space`, `$get-space`, `$create-space-internal`, `$find-space-by-name`, `$space-set-instr`, `$space-set-labels`**

Grep:
```
grep -n '^\s*(func \$register-space\|^\s*(func \$get-space\|^\s*(func \$create-space-internal\|^\s*(func \$find-space-by-name\|^\s*(func \$space-set-' wasm/runtime.wat
```

Delete each function. Do not delete callers yet — Subtask 5b handles those.

### Subtask 5b: Shrink `$execute`

- [ ] **Step 1: Read `$execute` signature and top-of-body**

```
sed -n '2184,2230p' wasm/runtime.wat
```

- [ ] **Step 2: Delete `$init-space-id` and `$init-pc` parameters**

Signature becomes:
```wat
(func $execute (export "execute")
               (param $init-env (ref null eq))
               (param $init-code-obj (ref null eq))
               (result (ref null eq))
```

Update every call site:
```
grep -n 'call \$execute\|return_call \$execute' wasm/runtime.wat
```

Each call gets its first two `i32.const 0` arguments removed.

- [ ] **Step 3: Delete the legacy executor branch**

Inside `$execute`, find the block guarded by `(if (ref.is_null (local.get $init-code-obj)) ...)`. That entire `then` branch is the comp-space path. Delete it and the surrounding `if` — always enter the code-object path.

- [ ] **Step 4: Delete local `$space (ref null $comp-space)` and `$space-id i32`**

Search `(local \$space ` and `(local \$space-id` within `$execute`'s body. Delete both declarations.

- [ ] **Step 5: Rename `$current-code-obj` → `$co`**

Within `$execute` only (there's no module-level `$current-code-obj`). Use a sed-style rename, then rebuild.

- [ ] **Step 6: Scrub any surviving `$space-id` in cross-procedure dispatch**

Grep:
```
grep -n '\$space-id' wasm/runtime.wat
```

Expected: zero matches. Any surviving reference either belongs to `$ecec-parse-instr` (which had an unused `$space-id` param — delete that param now too, updating its one call site in `$load-archive-impl`), or is a bug.

- [ ] **Step 7: Rebuild and test**

```
make ece && make test-wasm && make test-web-server && make test-web-apps 2>&1 | tail -40
```

Expected: all pass. If `$execute` trap at launch, a call site still passes 4 args — re-grep.

- [ ] **Step 8: Commit**

```
git add wasm/runtime.wat
git commit -m "$(cat <<'EOF'
wasm: retire \$comp-space struct, registry, and legacy executor branch

Deletes \$comp-space, \$space-array, \$spaces, \$space-count,
\$register-space, \$get-space, \$create-space-internal,
\$find-space-by-name, \$space-set-instr, \$space-set-labels.

Shrinks \$execute signature to (env, code-obj). Deletes the
legacy comp-space path and its local \$space / \$space-id.
Renames \$current-code-obj → \$co.

Drops unused \$space-id param from \$ecec-parse-instr.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Retire trapped `%space-*` primitive IDs and source-map infrastructure

**Why next:** with `$comp-space` gone, the trapped primitive IDs and any residual source-map helpers become fully unreachable. Deleting their trap arms tightens the primitive-dispatch switch and reclaims the IDs.

**Files:**
- Modify: `wasm/runtime.wat` — primitive dispatch block, source-map globals

- [ ] **Step 1: Confirm the retired ID list**

Grep for trap-only primitive branches:
```
grep -nB1 -A2 'unreachable\|global.get \$void' wasm/runtime.wat | grep -B2 'i32.const 1\(12\|25\|26\|27\|28\|29\|30\|31\|32\|33\|34\|35\)' | head -60
```

Expected: trap arms at IDs 112, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135. Confirm each is still dead (grep for their callers in `.scm` and `.ecec` files — should be zero).

- [ ] **Step 2: Delete each trap arm**

For each confirmed ID, delete the `(if (i32.eq (local.get $id) (i32.const N)) (then ...))` block inside the primitives dispatch function.

- [ ] **Step 3: Delete source-map infrastructure**

Grep:
```
grep -n 'source-map\|\$srcmap\|\$source-maps' wasm/runtime.wat
```

Delete:
- The `$source-maps` global (hash-table keyed by space-id).
- `$register-source-map` function if it wasn't deleted in Task 4.
- `$get-source-loc-for-pc` (or similarly named) lookup function.
- Any JS glue accessors that referenced the above — grep `sourceMap` in `wasm/glue.js`.

- [ ] **Step 4: Rebuild and test**

```
make ece && make test-wasm && make test-web-server && make test-web-apps 2>&1 | tail -40
```

Expected: all pass.

- [ ] **Step 5: Commit**

```
git add wasm/runtime.wat wasm/glue.js
git commit -m "$(cat <<'EOF'
wasm: delete trapped %space-* primitives and source-map infra

Primitive IDs 112 and 125-135 had only trap branches after the
compilation-space retirement on the CL side. Now fully unreachable
on WASM too; removed.

Source-map infrastructure (\$source-maps, \$register-source-map,
\$get-source-loc-for-pc) is tied to per-space storage that no
longer exists. Removed. Per-PC source-map in the archive format
is diagnostics roadmap thread 5, designed from scratch later.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Restore single-step `make test` in CI

**Why last:** the split CI step was a workaround for the archive-loader trap that is now fixed. Restoring the single step closes the TODO and re-gates WASM-dependent suites.

**Files:**
- Modify: `.github/workflows/test.yml:81-107`

- [ ] **Step 1: Read the current split step**

```
sed -n '80,110p' .github/workflows/test.yml
```

- [ ] **Step 2: Replace lines 81-107 with the restored single-step form**

Delete lines 81 through 107 (inclusive) — the entire TODO comment block AND both test steps.

Insert in their place:

```yaml
      - name: Run all tests
        run: make test
```

Indentation: two spaces for the `-`, four for `run:` / `name:` — match the surrounding steps exactly. Double-check by running `yq '.jobs.test.steps[].name' .github/workflows/test.yml` (if `yq` is available) and confirming the step names read as expected.

- [ ] **Step 3: Commit**

```
git add .github/workflows/test.yml
git commit -m "$(cat <<'EOF'
ci: restore single-step 'make test' gate

The WASM archive-loader port is complete (Tasks 1-6); test-wasm,
test-web-server, and test-web-apps all pass gating. The split
continue-on-error workaround is no longer needed.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Final verification + push

- [ ] **Step 1: Run the full test suite locally**

```
make test 2>&1 | tail -80
```

Expected: rove, ece, wasm, conformance, golden, web-server, web-apps — all green.

- [ ] **Step 2: Confirm branch contains the expected commits**

```
git log --oneline main..HEAD
```

Expected (bottom to top):
```
<hash> ci: restore single-step 'make test' gate
<hash> wasm: delete trapped %space-* primitives and source-map infra
<hash> wasm: retire $comp-space struct, registry, and legacy executor branch
<hash> wasm: delete legacy load_ecec / run / *BundleText surface
<hash> wasm/glue: switch bootstrap to loadArchiveText + runCodeObject
<hash> wasm: add archive-format loader and exports
<hash> Roadmap: add P0.5 keywordize-archive-format between P0 and P1
<hash> Add WASM archive-loader design + code-objects completion roadmap
<hash> (+ per-procedure-code-objects commits from base branch)
```

- [ ] **Step 3: Push the branch**

```
git push -u origin wasm-archive-loader
```

- [ ] **Step 4: Open the PR**

Note: this PR must merge AFTER PR #163 (per-procedure-code-objects). Target `main` but flag in the PR description that it's stacked on #163.

```
gh pr create --title "Port archive loader to WASM and retire \$comp-space" --body "$(cat <<'EOF'
## Summary

- Ports CL's \`parse-archive-sexp\` to WAT; WASM runtime now loads the
  \`(ecec-archive version 2 ...)\` format instead of trapping.
- Retires the \$comp-space struct, its registry, and the legacy executor
  branch. WASM runtime matches CL: code-objects are the sole dispatch unit.
- Restores \`make test\` as a single gating CI step; removes the
  continue-on-error workaround.

**Stacked on #163 (per-procedure-code-objects).** Merge #163 first;
this PR rebases onto main after.

## Test plan

- [ ] make test-rove
- [ ] make test-ece
- [ ] make test-wasm
- [ ] make test-conformance
- [ ] make test-golden
- [ ] make test-web-server
- [ ] make test-web-apps

## Specs

- docs/superpowers/specs/2026-04-20-wasm-archive-loader-design.md
- docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 5: Update project memory — mark follow-up as done**

Edit `~/.claude/projects/-Users-anthonyfairchild-git-ece/memory/project_wasm_archive_loader_followup.md` and prepend a status line:

```
**Status (2026-04-NN):** Shipped in PR #<N>. WASM archive loader ported; \$comp-space retired; make test re-gated.
```

Also edit `MEMORY.md` — remove or annotate the "WASM archive-loader port (follow-up)" bullet under `## Known Tech Debt`.

---

## Self-Review Notes

**Spec coverage check:**
- Design §1 (archive format recap) — informational, no task needed.
- Design §2 (`$load-archive-impl`) — Task 2.
- Design §3 (new/retired exports) — Tasks 2b and 4.
- Design §4 (JS glue) — Task 3.
- Design §5 (\$comp-space retirement) — Task 5.
- Design §6 (error handling) — traps are embedded in Task 2 (legacy-header trap, version trap, co-ref-range trap via `unreachable`).
- Testing §integration — Tasks 3, 4, 5, 6 end with `make test-wasm` / full-suite runs.
- Testing §CI — Task 7.
- Implementation ordering (six commits) — realized as Tasks 2 (combined 1+2 from design), 3, 4, 5, 6, 7. The design's standalone "Commit 1" (scratch harness) is folded into Task 2's smoke check (Subtask 2b Step 4) since the scratch harness adds no durable value.

**Known minor deviations from spec:**
- Plan combines design's Commit 1 (new loader) and Commit 2 (JS switchover) into one sequence (Tasks 2+3), committed as two commits — matches spec's commit count.
- Task 5b Step 6 drops `$space-id` param from `$ecec-parse-instr` (spec didn't call this out explicitly; found during plan-writing that the param is unused in the function body, so now is the natural time to remove it).

If the implementer finds a third deviation: pause and surface it rather than silently adapting. Post-PR-#163 code is fresh enough that small divergences are fine; large ones want the user's eyes.
