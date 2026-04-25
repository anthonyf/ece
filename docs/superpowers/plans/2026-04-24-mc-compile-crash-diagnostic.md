# MC-COMPILE CRASH Diagnostic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace `write-to-string`'s opaque `#?` fallback with an informative `#<type-name>`, then use the improved error to find and fix the `mc-compile` caller that's throwing the trailing CRASH from `make test-wasm`.

**Architecture:** Phase 1 (always ships) adds type-identifying tag strings to `$write-to-string-impl` in `wasm/runtime.wat` and the CL mirror in `src/runtime.lisp`. Phase 2 (investigation + narrow fix, with abort path) uses the revealed type to locate the offending `mc-compile` call site.

**Tech Stack:** WebAssembly Text (WAT) with GC proposal, Common Lisp (SBCL), ECE Scheme, Make.

**Spec:** `docs/superpowers/specs/2026-04-24-mc-compile-crash-diagnostic-design.md`
**Base branch:** `mc-compile-crash-diagnostic` (off main; spec already committed)

---

## Pre-flight

- [ ] **Step 1: Verify baseline**

```
cd "$(git rev-parse --show-toplevel)"
git log --oneline -3
make test-wasm 2>&1 | tail -5
```

Expected:
- Branch: `mc-compile-crash-diagnostic`.
- Last commit: `Add design spec: diagnose and fix trailing MC-COMPILE CRASH`.
- test-wasm output shows `CRASH: Unknown expression type -- MC-COMPILE: #?` followed by `WASM tests: 1011 passed, 0 failed`.

If the CRASH line has disappeared from output, the underlying issue was already fixed by other session work — stop and re-check the roadmap; this follow-up may no longer need doing.

- [ ] **Step 2: Record baseline test counts**

Baseline: `1011 passed, 0 failed (977 ECE + 34 integration)`. Both phases must preserve this; Phase 2's success adds the elimination of the CRASH line.

---

## Phase 1 — Improve write-to-string fallback (always ships)

### Task 1: Declare tag-string globals in WAT

**Files:**
- Modify: `wasm/runtime.wat`

Tag strings go with the other string globals near the top of the module. There are 12 tags to add — one per user-visible struct type not already handled by the existing write-to-string branches.

### Step 1.1: Locate the sym-id declaration block

Tag globals sit near the other module-globals. The `$sym-id-file` and related globals live around line 1610 per prior work; the archive-loader error strings sit around line 270. Put the tag globals just after the archive-loader error strings so they're with other UTF-16 `$string` constants.

```
grep -n 'global \$err-bad-coref\|global \$archive-registry' wasm/runtime.wat | head -3
```

Expected: `$err-bad-coref` is declared around line 309 (end of the archive error-string block); `$archive-registry` is around line 1618. Insertion point is right after `$err-bad-coref`.

### Step 1.2: Add the tag globals

Paste this block immediately after the `$err-bad-coref` global declaration (find it via `grep -n 'global \$err-bad-coref' wasm/runtime.wat`):

```wat

  ;; Type-tag strings for $write-to-string-impl's fallback. Each is
  ;; "#<TYPENAME>" in UTF-16, pre-interned as a $string constant.
  ;; When the fallback sees a value that isn't one of the well-known
  ;; primitives (fixnum/float/string/symbol/boolean/null/char/pair/vector),
  ;; it does a $ref.test against each tagged struct type and returns
  ;; the matching tag. Unknown types fall through to $type-tag-unknown
  ;; so new struct types remain diagnosable.
  (global $type-tag-hash-table (ref $string)
    (array.new_fixed $string 14
      (i32.const 35) (i32.const 60) (i32.const 104) (i32.const 97)
      (i32.const 115) (i32.const 104) (i32.const 45) (i32.const 116)
      (i32.const 97) (i32.const 98) (i32.const 108) (i32.const 101)
      (i32.const 62) (i32.const 0)))
  (global $type-tag-code-object (ref $string)
    (array.new_fixed $string 14
      (i32.const 35) (i32.const 60) (i32.const 99) (i32.const 111)
      (i32.const 100) (i32.const 101) (i32.const 45) (i32.const 111)
      (i32.const 98) (i32.const 106) (i32.const 101) (i32.const 99)
      (i32.const 116) (i32.const 62)))
  (global $type-tag-compiled-proc (ref $string)
    (array.new_fixed $string 22
      (i32.const 35) (i32.const 60) (i32.const 99) (i32.const 111)
      (i32.const 109) (i32.const 112) (i32.const 105) (i32.const 108)
      (i32.const 101) (i32.const 100) (i32.const 45) (i32.const 112)
      (i32.const 114) (i32.const 111) (i32.const 99) (i32.const 101)
      (i32.const 100) (i32.const 117) (i32.const 114) (i32.const 101)
      (i32.const 62) (i32.const 0)))
  (global $type-tag-continuation (ref $string)
    (array.new_fixed $string 16
      (i32.const 35) (i32.const 60) (i32.const 99) (i32.const 111)
      (i32.const 110) (i32.const 116) (i32.const 105) (i32.const 110)
      (i32.const 117) (i32.const 97) (i32.const 116) (i32.const 105)
      (i32.const 111) (i32.const 110) (i32.const 62) (i32.const 0)))
  (global $type-tag-primitive (ref $string)
    (array.new_fixed $string 12
      (i32.const 35) (i32.const 60) (i32.const 112) (i32.const 114)
      (i32.const 105) (i32.const 109) (i32.const 105) (i32.const 116)
      (i32.const 105) (i32.const 118) (i32.const 101) (i32.const 62)))
  (global $type-tag-parameter (ref $string)
    (array.new_fixed $string 12
      (i32.const 35) (i32.const 60) (i32.const 112) (i32.const 97)
      (i32.const 114) (i32.const 97) (i32.const 109) (i32.const 101)
      (i32.const 116) (i32.const 101) (i32.const 114) (i32.const 62)))
  (global $type-tag-port (ref $string)
    (array.new_fixed $string 7
      (i32.const 35) (i32.const 60) (i32.const 112) (i32.const 111)
      (i32.const 114) (i32.const 116) (i32.const 62)))
  (global $type-tag-error-sentinel (ref $string)
    (array.new_fixed $string 18
      (i32.const 35) (i32.const 60) (i32.const 101) (i32.const 114)
      (i32.const 114) (i32.const 111) (i32.const 114) (i32.const 45)
      (i32.const 115) (i32.const 101) (i32.const 110) (i32.const 116)
      (i32.const 105) (i32.const 110) (i32.const 101) (i32.const 108)
      (i32.const 62) (i32.const 0)))
  (global $type-tag-js-ref (ref $string)
    (array.new_fixed $string 10
      (i32.const 35) (i32.const 60) (i32.const 106) (i32.const 115)
      (i32.const 45) (i32.const 114) (i32.const 101) (i32.const 102)
      (i32.const 62) (i32.const 0)))
  (global $type-tag-env-frame (ref $string)
    (array.new_fixed $string 12
      (i32.const 35) (i32.const 60) (i32.const 101) (i32.const 110)
      (i32.const 118) (i32.const 45) (i32.const 102) (i32.const 114)
      (i32.const 97) (i32.const 109) (i32.const 101) (i32.const 62)))
  (global $type-tag-eof (ref $string)
    (array.new_fixed $string 6
      (i32.const 35) (i32.const 60) (i32.const 101) (i32.const 111)
      (i32.const 102) (i32.const 62)))
  (global $type-tag-void (ref $string)
    (array.new_fixed $string 7
      (i32.const 35) (i32.const 60) (i32.const 118) (i32.const 111)
      (i32.const 105) (i32.const 100) (i32.const 62)))
  (global $type-tag-unknown (ref $string)
    (array.new_fixed $string 10
      (i32.const 35) (i32.const 60) (i32.const 117) (i32.const 110)
      (i32.const 107) (i32.const 110) (i32.const 111) (i32.const 119)
      (i32.const 110) (i32.const 62)))
```

**Byte-count verification:** each `array.new_fixed $string N` expects exactly `N` `i32.const` bytes. Count before committing. The strings in order with their char counts:
- `#<hash-table>` = 13 chars (but fixed array is 14 with trailing NUL for 4-char alignment — adjust as needed; drop the trailing NUL for exact count)

Actually let me rewrite without padding — the lengths should be exactly the character count:

**Corrected block — recount each before pasting.** For each tag:
- `#<hash-table>` → 13 chars: `#<hash-table>`
- `#<code-object>` → 14 chars
- `#<compiled-procedure>` → 21 chars
- `#<continuation>` → 15 chars
- `#<primitive>` → 12 chars
- `#<parameter>` → 12 chars
- `#<port>` → 7 chars
- `#<error-sentinel>` → 17 chars
- `#<js-ref>` → 9 chars
- `#<env-frame>` → 12 chars
- `#<eof>` → 6 chars
- `#<void>` → 7 chars
- `#<unknown>` → 10 chars

Replace the block above with the correct counts. Implementer: use Python (or any shell scripting) to generate each `array.new_fixed $string LEN (i32.const …) (i32.const …) …` with exact character-by-character codes. A helper:

```
python3 -c 'import sys
for name in ["hash-table","code-object","compiled-procedure","continuation","primitive","parameter","port","error-sentinel","js-ref","env-frame","eof","void","unknown"]:
    s = f"#<{name}>"
    codes = [ord(c) for c in s]
    glob = f"type-tag-{name}"
    print(f"  (global ${glob} (ref $string)")
    print(f"    (array.new_fixed $string {len(s)}")
    inner = " ".join(f"(i32.const {c})" for c in codes)
    print(f"      {inner}))")'
```

Use that output as the authoritative block — paste it verbatim in place of the 13 globals. Skip the hand-written block above; this is cleaner.

### Step 1.3: Rebuild and verify WAT parses

```
cd "$(git rev-parse --show-toplevel)"
make wasm 2>&1 | tail -3
```

Expected: clean build. If `array.new_fixed` errors on argument count, re-check the Python output's `len(s)` matches the number of `i32.const`s per global.

### Step 1.4: Stage the change (don't commit yet — Task 2 continues)

---

### Task 2: Rewrite the fallback in `$write-to-string-impl`

**Files:**
- Modify: `wasm/runtime.wat` at `$write-to-string-impl`'s fallback (around line 3470)

### Step 2.1: Locate the fallback

```
cd "$(git rev-parse --show-toplevel)"
grep -n 'Fallback' wasm/runtime.wat | head
```

Expected: a match near line 3470 with the comment `;; Fallback` just before `(call $make-static-string (i32.const 35) (i32.const 63))`.

### Step 2.2: Replace the fallback

Use the Edit tool. The `old_string` is the two-line block ending the function body:

**old_string:**
```wat
    ;; Fallback
    (call $make-static-string (i32.const 35) (i32.const 63))  ;; "#?"
  )
```

**new_string:**
```wat
    ;; Fallback — identify tagged struct types via ref.test and return
    ;; "#<TYPENAME>" so errors that format unknown values (e.g. mc-compile's
    ;; "Unknown expression type" path) remain diagnosable instead of opaque.
    ;; Ordered by estimated frequency; final $type-tag-unknown catches any
    ;; struct type we haven't explicitly listed so new types stay diagnosable.
    (if (ref.test (ref $hash-table) (local.get $v))
      (then (return (global.get $type-tag-hash-table))))
    (if (ref.test (ref $code-object) (local.get $v))
      (then (return (global.get $type-tag-code-object))))
    (if (ref.test (ref $compiled-proc) (local.get $v))
      (then (return (global.get $type-tag-compiled-proc))))
    (if (ref.test (ref $continuation) (local.get $v))
      (then (return (global.get $type-tag-continuation))))
    (if (ref.test (ref $primitive) (local.get $v))
      (then (return (global.get $type-tag-primitive))))
    (if (ref.test (ref $parameter) (local.get $v))
      (then (return (global.get $type-tag-parameter))))
    (if (ref.test (ref $port) (local.get $v))
      (then (return (global.get $type-tag-port))))
    (if (ref.test (ref $error-sentinel) (local.get $v))
      (then (return (global.get $type-tag-error-sentinel))))
    (if (ref.test (ref $js-ref) (local.get $v))
      (then (return (global.get $type-tag-js-ref))))
    (if (ref.test (ref $env-frame) (local.get $v))
      (then (return (global.get $type-tag-env-frame))))
    (if (call $is-eof (local.get $v))
      (then (return (global.get $type-tag-eof))))
    (if (ref.test (ref $void-type) (local.get $v))
      (then (return (global.get $type-tag-void))))
    (global.get $type-tag-unknown)
  )
```

### Step 2.3: Rebuild and verify

```
make wasm 2>&1 | tail -3
```

Expected: clean build. If any `ref.test (ref $TYPE)` errors with "unknown type", the struct type name is wrong — grep `^\s*(type \$TYPE` to verify and adjust.

### Step 2.4: Run test-wasm — observe improved CRASH message

```
make test-wasm 2>&1 | grep -E 'CRASH|passed'
```

Expected:
- `CRASH: Unknown expression type -- MC-COMPILE: #<SOMETYPE>` where `SOMETYPE` is one of the tagged types.
- `WASM tests: 1011 passed, 0 failed`.

**Record `<SOMETYPE>`** — Phase 2's diagnosis pivots on this.

If `<SOMETYPE>` is `unknown`, a new struct type has surfaced that isn't in our list. Add it to Task 1's tag globals and Task 2's dispatch, repeat.

---

### Task 3: CL parity — update `ece-print-flat` fallback

**Files:**
- Modify: `src/runtime.lisp` at `ece-print-flat` (around line 670-701)

### Step 3.1: Find the current fallback

```
grep -n '(t (prin1 x s))\|defun ece-print-flat' src/runtime.lisp | head
```

Expected: `defun ece-print-flat` declaration around line 670, `(t (prin1 x s))` as the catch-all around line 701.

### Step 3.2: Add the helper `ece-type-tag`

Before `ece-print-flat`, insert a helper that produces the same `#<type-name>` format as WAT:

Use the Edit tool:

**old_string:**
```lisp
(defun ece-print-flat (x s)
  "Recursively print X to S using ECE-readable syntax."
```

**new_string:**
```lisp
(defun ece-type-tag (x)
  "Return a `#<type-name>` string identifying X's tagged type.
Mirrors WAT's $write-to-string-impl fallback so CL and WASM errors
that format unknown values produce the same output shape."
  (cond
    ((hash-table-p x) "#<hash-table>")
    ((typep x 'ece-code-object) "#<code-object>")
    ((typep x 'ece-compiled-proc) "#<compiled-proc>")
    ((typep x 'ece-continuation) "#<continuation>")
    ((typep x 'ece-primitive) "#<primitive>")
    ((typep x 'ece-parameter) "#<parameter>")
    ((typep x 'ece-port) "#<port>")
    ((typep x 'ece-error-sentinel) "#<error-sentinel>")
    (t (format nil "#<~A>"
               (string-downcase (symbol-name (type-of x)))))))

(defun ece-print-flat (x s)
  "Recursively print X to S using ECE-readable syntax."
```

### Step 3.3: Replace the catch-all in `ece-print-flat`

**old_string:**
```lisp
    (t (prin1 x s))))
```

**new_string:**
```lisp
    (t (write-string (ece-type-tag x) s))))
```

### Step 3.4: Verify struct-name guesses

The CL defstruct names in the `typep` calls (`ece-code-object`, `ece-compiled-proc`, etc.) may not match the actual struct names in `src/runtime.lisp`. Verify:

```
grep -n 'defstruct\|cl:defstruct' src/runtime.lisp | head -10
```

Expected: a list of `(defstruct <name> ...)` declarations. Match each `typep` call against these names. If names differ (e.g. `code-object` without the `ece-` prefix), adjust the `typep` calls.

For any type that has no defstruct (e.g. `$port` might be represented as a CLOS class or a raw CL struct), fall through to the `(format nil "#<~A>" ...)` branch — acceptable.

### Step 3.5: Load the CL side and verify syntax

```
cd "$(git rev-parse --show-toplevel)"
qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' --quit 2>&1 | tail -5
```

Expected: loads without error. If any symbol (e.g. `ece-code-object`) is undefined, Task 3.4's verification was incomplete — grep and fix.

---

### Task 4: Verify Phase 1 end-to-end

- [ ] **Step 4.1: Full `make test-wasm`**

```
make test-wasm 2>&1 | tail -10
```

Expected: `CRASH: Unknown expression type -- MC-COMPILE: #<SOMETYPE>` where `SOMETYPE` is now informative (not `unknown`, unless we legitimately missed a type). `1011 passed, 0 failed` preserved.

- [ ] **Step 4.2: Confirm CL side doesn't regress**

```
make test-ece 2>&1 | tail -5
```

Expected: `Total: <N> collected, <N> ran, <M> passed, 0 failed`.

If any ECE tests now fail (e.g. because a test was implicitly depending on `prin1`-style output in an error message), investigate; the fallback change may have broken a test's expected-string matching. Fix by adjusting the test's expected output to match the new `#<type-name>` format.

- [ ] **Step 4.3: Commit Phase 1**

```
cd "$(git rev-parse --show-toplevel)"
git add wasm/runtime.wat src/runtime.lisp
git commit -m "wasm+cl: identify tagged struct types in write-to-string fallback

Replaces \`#?\` (WAT) and verbose \`prin1\` output (CL) with
\`#<type-name>\` for tagged struct types that fall through the main
write-to-string dispatch. Unknown types fall through to
\`#<unknown>\` so new struct types stay diagnosable.

Makes error messages like \"Unknown expression type -- MC-COMPILE: ...\"
self-diagnosing: the format now names the offending value's type.

Spec: docs/superpowers/specs/2026-04-24-mc-compile-crash-diagnostic-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

Phase 1 is now committable regardless of Phase 2's outcome.

---

## Phase 2 — Diagnose + fix the mc-compile caller

### Task 5: Interpret the revealed type

Read the CRASH line from Task 4.1's output. Record `SOMETYPE`.

Based on which type surfaced:

- **`#<hash-table>`**: the bad value is a hash-table. Likely `(eval …)` or `(apply …)` on a hash-table, or a macro returning a hash-table.
- **`#<code-object>`**: a code-object is being compiled as source. Check `compile-and-go` paths or accidental double-compile.
- **`#<continuation>`** / **`#<compiled-proc>`**: a resumed continuation or closure is being evaluated as source.
- **`#<error-sentinel>`**: an error-propagation path is passing the sentinel to eval instead of short-circuiting.
- **`#<primitive>`** / **`#<parameter>`** / **`#<port>`** / **`#<js-ref>`** / **`#<env-frame>`** / **`#<eof>`** / **`#<void>`**: investigate per type.
- **`#<unknown>`**: a struct type we haven't tagged surfaced. Return to Task 1 + 2 to add it, then re-run.

### Task 6: Locate the caller

**Search strategy based on revealed type:**

- [ ] **Step 6.1: Enumerate `mc-compile` call sites**

```
grep -rn 'mc-compile\|compile-and-go\|\(eval\b' src/prelude.scm src/compiler.scm src/ece-unit.scm src/ece-serve.scm src/scheduler.scm src/http-codec.scm src/websocket-codec.scm src/json.scm src/geiser-ece.scm src/sdk-lib.scm tests/ece/common/test-*.scm wasm/wasm-test-runner.scm | head -40
```

Expected: a list of every site in the WASM test bundle that might call into `mc-compile` or `eval`.

- [ ] **Step 6.2: Narrow to likely culprits for the revealed type**

For each caller matching the type-appropriate pattern (e.g. `(eval …)` for hash-table, `compile-and-go` for code-object), read surrounding context. Form a hypothesis about which site is passing the bad value.

- [ ] **Step 6.3: Confirm with targeted tracing (optional)**

If the hypothesis isn't obvious from reading, add a temporary `(display ...)` trace at each candidate site. For example:

```scheme
(display "about to eval: ")
(display (ece-type-tag sus-value))  ; or similar type-inspection
(newline)
(eval sus-value)
```

Re-run `make test-wasm` with the trace in place; the `(display ...)` output will appear BEFORE the CRASH line and narrow the site.

Remove traces after the caller is found.

### Task 7: Classify the fix scope

**Narrow fix criteria (proceed to Task 8):**
- Fix is in 1-2 files.
- ≤20 lines of change.
- Does not require modifying `mc-compile`, `$execute`, the test runner framework, or any data structure.
- Matches the shape of a "bad value reaches eval; guard or correct the source."

**Structural fix criteria (abort Phase 2, skip to Task 10):**
- Requires restructuring the evaluator or test harness.
- Requires changes across many files.
- Requires modifying a data structure or value protocol.

### Task 8 (narrow path): Apply the fix

Exact code depends on Task 6's diagnosis. The fix shape is one of:
- Guard around the offending call (skip when the value isn't what was expected).
- Fix the upstream function returning the wrong value.
- Correct a macro producing a struct where a form was expected.

Apply the Edit tool at the identified site. Keep the change ≤20 lines, ≤2 files.

### Task 9 (narrow path): Verify

- [ ] **Step 9.1: Targeted**

```
make test-wasm 2>&1 | tail -10
```

Expected: **no `CRASH:` line** in the output. `1011 passed, 0 failed` preserved.

- [ ] **Step 9.2: Full-suite**

```
make test 2>&1 | grep -E 'passed|failed' | tail -15
```

Expected: no regressions in other suites.

- [ ] **Step 9.3: Stability 3×**

```
for i in 1 2 3; do make test-wasm 2>&1 | grep -E 'CRASH|passed' | head -3; echo "---"; done
```

Expected: no `CRASH` line in any of the 3 runs.

- [ ] **Step 9.4: Commit the Phase 2 fix**

Replace `<ROOT-CAUSE>` and `<FILE:LINE>` with the actual content from Task 6:

```
git add <files-touched-by-fix>
git commit -m "<area>: fix <ROOT-CAUSE> to eliminate trailing MC-COMPILE CRASH

With Phase 1's improved write-to-string fallback, the CRASH message
became \"Unknown expression type -- MC-COMPILE: #<TYPE>\" which
revealed <ROOT-CAUSE>. Fix at <FILE:LINE>: <ONE-SENTENCE-FIX-SUMMARY>.

Verification:
- make test-wasm output no longer contains CRASH: line.
- 1011 passed, 0 failed preserved.
- 3x consecutive runs are stable.

Spec: docs/superpowers/specs/2026-04-24-mc-compile-crash-diagnostic-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Abort path (only if Phase 2 classified structural in Task 7)

- [ ] **Step A.1: Update the current-state TODO or note**

The CRASH will still print, but with an informative type. Update the roadmap's Known follow-up #2 bullet to cite the revealed type and the location of the offending caller (so the next person has a running start). Don't remove the bullet — it's still unresolved.

- [ ] **Step A.2: Skip to Task 10 (roadmap update), marking this "Phase 1 shipped only, Phase 2 deferred"**

---

## Task 10: Update the roadmap

**Files:**
- Modify: `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`

### Step 10.1: Locate Known follow-up #2

```
grep -n 'MC-COMPILE: #?' docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md
```

### Step 10.2: Update the bullet

**If Phase 2 succeeded (narrow fix landed):** mark **Shipped (PR #<N>)** with a one-sentence root-cause summary and a pointer to the spec.

**If Phase 2 aborted (structural):** mark **Partially shipped (PR #<N>)** — Phase 1 diagnostic improvement landed; underlying bug still present with informative type `#<TYPE>`; open a new brainstorm.

Use the Edit tool. The two possible replacement shapes:

**Narrow-fix success:**
```
- **`CRASH: Unknown expression type -- MC-COMPILE: #?` diagnostic** — **Shipped** (PR #<N>). Phase 1 improved `write-to-string`'s fallback to emit `#<type-name>` identifiers for tagged struct types; Phase 2 used that to locate a <ONE-LINE-ROOT-CAUSE> at <FILE:LINE> and fixed it. `make test-wasm` output no longer contains the CRASH line. Design: `docs/superpowers/specs/2026-04-24-mc-compile-crash-diagnostic-design.md`.
```

**Abort:**
```
- **`CRASH: Unknown expression type -- MC-COMPILE: #?` diagnostic** — **Phase 1 shipped** (PR #<N>); Phase 2 deferred. `write-to-string`'s fallback now emits `#<type-name>` identifiers; the CRASH message now reads `#<TYPE>` instead of `#?`, making it self-diagnosing. The underlying `mc-compile` caller that passes the bad value is at <FILE:LINE>-ish; fix is structural and out of scope for a narrow edit. Tracked as a new follow-up (TBD brainstorm).
```

### Step 10.3: Commit the roadmap update

```
git add docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md
git commit -m "roadmap: mark MC-COMPILE CRASH <shipped|partially-shipped>

<brief summary matching the narrow-fix-success or abort case above>

Design: docs/superpowers/specs/2026-04-24-mc-compile-crash-diagnostic-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Push + PR

### Step 11.1: Confirm commits

```
cd "$(git rev-parse --show-toplevel)"
git log --oneline main..HEAD
```

Expected (narrow-fix success, bottom to top):
```
<hash> roadmap: mark MC-COMPILE CRASH shipped
<hash> <area>: fix <ROOT-CAUSE> to eliminate trailing MC-COMPILE CRASH
<hash> wasm+cl: identify tagged struct types in write-to-string fallback
<hash> Add design spec: diagnose and fix trailing MC-COMPILE CRASH
```

Expected (abort):
```
<hash> roadmap: mark MC-COMPILE CRASH partially-shipped
<hash> wasm+cl: identify tagged struct types in write-to-string fallback
<hash> Add design spec: diagnose and fix trailing MC-COMPILE CRASH
```

### Step 11.2: Push

```
git push -u origin mc-compile-crash-diagnostic
```

### Step 11.3: Open PR via wrapper

For narrow-fix:

```
scripts/ece-gh pr create --base main --head mc-compile-crash-diagnostic --title "wasm+cl: fix trailing MC-COMPILE CRASH + improve write-to-string fallback" --body "$(cat <<'EOF'
## Summary

Closes Known follow-up #2 from the code-objects-completion roadmap.

**Phase 1** improves \`write-to-string\`'s generic fallback in
\`wasm/runtime.wat\` (\`\$write-to-string-impl\`) and \`src/runtime.lisp\`
(\`ece-print-flat\`) to emit \`#<type-name>\` for tagged struct types
instead of the opaque \`#?\` (WAT) or verbose \`prin1\` output (CL).
Pure diagnostic-quality improvement.

**Phase 2** uses Phase 1's informative error to identify
<ONE-LINE-ROOT-CAUSE> at <FILE:LINE>. Fix: <ONE-LINE-FIX-SUMMARY>.

## Effect

\`make test-wasm\` output no longer contains the \`CRASH:\` line.
\`1011 passed, 0 failed\` preserved.

## Test plan

- [x] \`make test-wasm\` passes without CRASH line.
- [x] 3× consecutive runs stable.
- [x] \`make test\` full suite has no regressions.

## Specs + plan

- docs/superpowers/specs/2026-04-24-mc-compile-crash-diagnostic-design.md
- docs/superpowers/plans/2026-04-24-mc-compile-crash-diagnostic.md

Copilot will auto-review via the repo ruleset.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

For abort: similar PR body but replace Phase 2 section with "Phase 2 deferred; underlying bug tracked as a new follow-up with the informative error as starting point."

### Step 11.4: Wait for CI + address Copilot + merge

Follow the established flow. CI ~10-12 min. After success:
- `scripts/ece-gh api repos/anthonyf/ece/pulls/<N>/comments` — fetch Copilot feedback.
- Amend + force-push any real concerns.
- `scripts/ece-gh pr merge <N> --merge --delete-branch` when clean.
- `git checkout main && git pull && git branch -D mc-compile-crash-diagnostic`.

---

## Self-Review Notes

**Spec coverage:**
- Spec §Goals → Phase 1 (Tasks 1-4), Phase 2 (Tasks 5-9), roadmap (Task 10), PR (Task 11).
- Spec §Non-goals → reflected in Task 7's narrow-fix criteria (rejects restructuring).
- Spec §Design Phase 1 WAT → Tasks 1-2.
- Spec §Design Phase 1 CL → Task 3.
- Spec §Design Phase 2 workflow → Tasks 5-9.
- Spec §Testing verification triad → Task 9 Steps 9.1-9.3.
- Spec §Commits → Tasks 4.3, 9.4, 10.3.

**Placeholder scan:** The `<ROOT-CAUSE>`, `<FILE:LINE>`, `<ONE-LINE-ROOT-CAUSE>`, `<ONE-LINE-FIX-SUMMARY>` markers are explicit substitute-before-running placeholders — the implementer has concrete diagnosis from Task 6 to fill them. Not "TBD"s to fabricate.

**Type consistency:** `$type-tag-*` globals declared in Task 1, referenced in Task 2. Type-tag names match between WAT (Task 1) and CL (Task 3). `ece-type-tag` helper signature consistent across Task 3 steps.

**Known fragility:** Task 3.4 (CL defstruct name verification) is critical — if I guessed a struct name wrong, Task 3.5's `qlot exec sbcl` load will fail. That's caught by the explicit verification step; fix is to adjust `typep` calls to match actual struct names.
