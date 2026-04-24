# Re-enable WASM Yield Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Re-enable the three WASM yield tests removed in commit `7403276` by diagnosing and fixing the `illegal cast` trap in the `do-continuation-winds` + resume path.

**Architecture:** Two-phase single-PR work. Phase 1 restores tests and reproduces the trap uncommitted; diagnoses the root cause from the concrete trap location. Phase 2 applies a surgical WAT fix identified by the diagnosis, verifies, commits. An explicit decision point between phases aborts cleanly if the fix turns out to be structural.

---

> **OUTCOME NOTE (added post-execution, PR #175):** Phase 1's repro (Task 1 + Task 2) revealed the illegal-cast trap does NOT reproduce today — `make test-wasm` shows 1011/0 on the restored tests without any WAT change. The trap was incidentally resolved by subsequent code-object work in PRs #164/#165 and #174. The executed path was:
>
> - Tasks 1 + 2: restore tests, run test-wasm → unexpectedly passing.
> - Task 7 (Step 7.3 stability 3×): all green.
> - Task 8 Step 8.3: removed the stale TODO near op 19 in `wasm/runtime.wat`.
> - Tasks 8 + 9 + 10: commit, roadmap update, push + PR.
>
> Tasks 3 (map function indices), 4 (diagnose), 5 (decision point), 6 (apply WAT fix) were skipped because they assumed a trap that didn't materialize. The plan below is retained as historical context for what Phase 1 would have done if the trap had reproduced.

**Tech Stack:** WebAssembly Text (WAT) with GC proposal, JavaScript (ES2020 Node), Binaryen toolchain (`wasm-as`, `wasm-objdump`), Make.

**Spec:** `docs/superpowers/specs/2026-04-24-wasm-yield-tests-reenable-design.md`
**Base branch:** `wasm-yield-tests-reenable` (off main; spec already committed)

---

## Execution-mode caveat

This plan is unusual for a debugging task: Phase 2's exact fix cannot be specified in advance because it depends on Phase 1's diagnosis. What IS specified:
- Exact commands for Phase 1 (restore, repro, trace extraction, function-name mapping).
- An explicit decision-point step that forces a narrow-fix-or-abort classification.
- The Phase 2 *shape* (one surgical WAT edit + test bodies already restored + TODO removal + commit template with a placeholder for the root-cause summary).
- Verification steps (targeted + full-suite + 3× stability).

If you hit Phase 2 and the fix is more than ~10 lines of WAT across more than one function, pause and treat that as a failed Phase 1 exit: the fix is structural and the spec aborts. Do not expand scope silently.

---

## Pre-flight

- [ ] **Step 1: Verify baseline is green**

```
cd /Users/anthonyfairchild/git/ece
git status
git log --oneline -3
make test-wasm 2>&1 | tail -5
```

Expected:
- On branch `wasm-yield-tests-reenable`.
- Last commit is `Add design spec: re-enable WASM yield tests`.
- test-wasm summary line shows `WASM tests: 1008 passed, 0 failed`.

If any of these don't hold, stop and investigate before proceeding.

- [ ] **Step 2: Record baseline counts for later comparison**

Capture in your own working notes:
- Total passing tests: 1008 (expected).
- The three tests to restore: `yield single frame`, `yield multi-frame (3 cycles)`, `handle table stable over 100 yield cycles`.
- Expected post-fix count: 1011.

---

## Phase 1 — Reproduce and diagnose (uncommitted)

Work from the main checkout. Phase 1 edits are exploratory; nothing commits until Phase 2 or the abort path.

### Task 1: Restore the three yield tests into `wasm/test.js`

**Files:**
- Modify: `/Users/anthonyfairchild/git/ece/wasm/test.js`

- [ ] **Step 1.1: Extract the three test bodies from git history**

```
cd /Users/anthonyfairchild/git/ece
git show 7403276^:wasm/test.js | sed -n '60,150p' > /tmp/claude/yield-tests-original.js
cat /tmp/claude/yield-tests-original.js | head -5
cat /tmp/claude/yield-tests-original.js | wc -l
```

Expected: about 85 lines captured; the first few lines show the closing of the `validate_space` block (lines we will NOT restore — those tests were deliberately and permanently removed because `validate_space` itself is gone). The yield tests begin at the first `// ── Yield/resume: single frame ──` comment.

- [ ] **Step 1.2: Read the captured bodies to identify the exact slice**

```
grep -n 'Yield/resume\|Handle stability' /tmp/claude/yield-tests-original.js
```

Expected: three matches — `// ── Yield/resume: single frame ──`, `// ── Yield/resume: multi-frame ──`, `// ── Handle stability: reset_handles keeps handles bounded ──`.

Manually inspect the file and determine the exact line range containing just those three tests. Their bodies start at the first `// ── Yield/resume:` and end at the closing `});` of the handle-stability test (which is followed by the opening of the `runtime_error` test).

- [ ] **Step 1.3: Locate the current insertion point in `wasm/test.js`**

```
grep -n 'TODO (archive-loader follow-up): yield' wasm/test.js
```

Expected: `55:  // TODO (archive-loader follow-up): yield/resume tests are temporarily`.

The entire TODO block (lines ~55-68) will be replaced by the three test bodies. Read the current block:

```
sed -n '53,70p' wasm/test.js
```

Confirm lines 55-68 are the TODO block. The surrounding context: line 53-54 ends the op-id loop; the first test after the block is `iTest("runtime_error produces readable exception", ...)`.

- [ ] **Step 1.4: Replace the TODO block with the three restored tests**

Using the Edit tool. Read the TODO block as `old_string` exactly (every comment line, including the blank lines and the trailing `//`); paste the three test bodies (verified in Step 1.2) as `new_string`. The three test bodies should be pasted verbatim as they appear in `/tmp/claude/yield-tests-original.js`. No modifications yet — restore exactly as they were.

Typical shape of `new_string`:

```javascript
  // ── Yield/resume: single frame ──
  iTest("yield single frame", () => {
    const output = [];
    // Temporarily capture display output
    const origDisplay = ECE.io.display_string;
    const origNumber = ECE.io.display_number;
    // We can't easily redirect — use eval-string and check yield cont
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string"));
    const src = '(begin (define (test-yield-1) (display "A") (yield) (display "B")) (test-yield-1))';
    w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));

    // Check yield continuation exists (type 7 = raw continuation with unified call/cc)
    const contH = w.get_yield_cont();
    const contType = w.dbg_type(contH);
    assert(contType === 6 || contType === 7, `expected compiled-proc (6) or continuation (7), got type ${contType}`);

    // Resume
    w.clear_yield_cont();
    if (contType === 7)
      w.call_continuation(contH, w.h_void());
    else
      w.call_ece_proc(contH, w.h_cons(w.h_void(), w.h_nil()));
  });

  // ── Yield/resume: multi-frame ──
  iTest("yield multi-frame (3 cycles)", () => {
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string"));
    const src = '(begin (define *yc* 0) (define (test-yield-loop) (set! *yc* (+ *yc* 1)) (yield) (test-yield-loop)) (test-yield-loop))';
    w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));

    for (let frame = 0; frame < 3; frame++) {
      const contH = w.get_yield_cont();
      const contType = w.dbg_type(contH);
      assert(contType === 6 || contType === 7, `frame ${frame}: expected compiled-proc (6) or continuation (7), got type ${contType}`);
      w.clear_yield_cont();
      if (contType === 7)
        w.call_continuation(contH, w.h_void());
      else
        w.call_ece_proc(contH, w.h_cons(w.h_void(), w.h_nil()));
    }

    // Verify counter advanced
    const ycH = w.env_lookup(envH, ECE.internSym("*yc*"));
    const ycVal = w.h_fixnum_val(ycH);
    assert(ycVal === 4, `expected *yc* = 4, got ${ycVal}`);
  });

  // ── Handle stability: reset_handles keeps handles bounded ──
  iTest("handle table stable over 100 yield cycles", () => {
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string"));
    const src = '(begin (define *hc* 0) (define (test-handle-loop) (set! *hc* (+ *hc* 1)) (yield) (test-handle-loop)) (test-handle-loop))';
    w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));

    for (let frame = 0; frame < 100; frame++) {
      w.reset_handles();  // simulate what sandbox animationLoop does
      ECE._symCache = {};
      const contH = w.get_yield_cont();
      const contType = w.dbg_type(contH);
      w.clear_yield_cont();
      if (contType === 7)
        w.call_continuation(contH, w.h_void());
      else
        w.call_ece_proc(contH, w.h_cons(w.h_void(), w.h_nil()));
    }

    // Verify counter advanced and we didn't crash
    const hcH = w.env_lookup(envH, ECE.internSym("*hc*"));
    const hcVal = w.h_fixnum_val(hcH);
    assert(hcVal === 101, `expected *hc* = 101, got ${hcVal}`);
  });

```

(Verbatim content from `/tmp/claude/yield-tests-original.js`; only paste the body, not the surrounding `validate_space` block context captured by the broader sed.)

- [ ] **Step 1.5: Verify the restoration parses**

```
node -c wasm/test.js
```

Expected: no output (JS parses). If there's a SyntaxError, re-check the paste.

- [ ] **Step 1.6: Do NOT commit.** Phase 1 is all uncommitted exploration.

---

### Task 2: Run the repro and capture the trap

**Files:** none modified.

- [ ] **Step 2.1: Rebuild `.wasm` (in case of prior edits)**

```
cd /Users/anthonyfairchild/git/ece
make wasm 2>&1 | tail -3
```

Expected: clean build (just the `wasm-as` invocation line).

- [ ] **Step 2.2: Run `make test-wasm` and capture output**

```
mkdir -p /tmp/claude
make test-wasm 2>&1 | tee /tmp/claude/yield-repro.log
```

Expected: at least one of the three yield tests fails. The summary line will show some count less than 1011, with non-zero failed count. The failure output should include a RuntimeError stack trace.

- [ ] **Step 2.3: Extract trap locations**

```
grep -A 8 'yield single frame\|yield multi-frame\|handle table stable' /tmp/claude/yield-repro.log | grep -iE 'FAIL|RuntimeError|at wasm-function|illegal cast|cast|at Object' | head -40
```

Expected: per-test `FAIL:` lines followed by the RuntimeError `at wasm-function[N]:0xOFFSET` frames. Record for each failing test:
- The test name.
- The WAT function index at the top of the stack (e.g., `wasm-function[33]`).
- The byte offset within that function (e.g., `0xe9f`).
- The exception type (likely `illegal cast`; verify).

If all three fail at the same WAT function index, the bug has one location. If they fail at different indices, there are multiple sites.

---

### Task 3: Map function indices to WAT function names

**Files:** temporarily modifies `Makefile` (step 3.2, reverted at end of Phase 1).

- [ ] **Step 3.1: First try without rebuilding — use `wasm-objdump`**

```
cd /Users/anthonyfairchild/git/ece
which wasm-objdump 2>&1 && wasm-objdump --help 2>&1 | head -3
```

Expected: either wasm-objdump is found (from `wabt` brew package), or it's not installed. If it's installed:

```
wasm-objdump -j Function -x wasm/runtime.wasm 2>&1 | head -20
```

Expected: some function listing. If it contains names in `<>` brackets (e.g., `<$xcar>`), you can look up the trap index directly:

```
wasm-objdump -j Function -x wasm/runtime.wasm 2>&1 | grep -E "^\s*[0-9]+:" | sed -n '33p;34p;203p;204p'
```

(Replace 33/34/203/204 with whatever indices the trap showed.)

If wasm-objdump is not installed or the binary has no debug names (common — Binaryen strips by default), go to Step 3.2.

- [ ] **Step 3.2: Rebuild with debug names for the diagnosis run**

Temporarily add `--debug-names` to the wasm build. Using the Edit tool:

**old_string:**
```
	wasm-as --enable-gc --enable-reference-types wasm/runtime.wat -o wasm/runtime.wasm
```

**new_string:**
```
	wasm-as --enable-gc --enable-reference-types --debug-names wasm/runtime.wat -o wasm/runtime.wasm
```

Then rebuild and re-run the repro:

```
make wasm 2>&1 | tail -1
make test-wasm 2>&1 | tee /tmp/claude/yield-repro-named.log
grep -A 8 'RuntimeError\|yield single' /tmp/claude/yield-repro-named.log | head -30
```

Expected: the RuntimeError stack trace now includes function names like `at wasm-function[$xcar] (wasm://wasm/…)` instead of numeric indices. Record the function names at the top of the trap stack.

- [ ] **Step 3.3: Revert the Makefile edit (we'll restore it in Phase 2's commit if needed)**

Using the Edit tool, revert to the original:

**old_string:**
```
	wasm-as --enable-gc --enable-reference-types --debug-names wasm/runtime.wat -o wasm/runtime.wasm
```

**new_string:**
```
	wasm-as --enable-gc --enable-reference-types wasm/runtime.wat -o wasm/runtime.wasm
```

The diagnosis run gave us the names. Don't leave debug names on for the commit unless the commit is explicitly about diagnostics.

---

### Task 4: Diagnose the root cause

**Files:** none modified. Reading + reasoning only.

- [ ] **Step 4.1: Locate each trap call-site in the WAT source**

For each function name identified in Step 3.2, read its definition in `wasm/runtime.wat`. Walk up the call chain from the trap:
- The top-of-stack function: where does the illegal `ref.cast` happen? What did it cast *from*? What did it expect?
- The caller (next frame up): which call site passed the wrong-type value?
- Continue until you identify the original source of the misshapen value.

Use focused reads:

```
grep -n '^\s*(func \$FUNCNAME' wasm/runtime.wat
```

Then read that function. Look specifically for:
- `ref.cast (ref $code-object)` on something that might not be a code-object.
- `ref.cast (ref $pair)` on something null or of wrong type.
- `ref.cast (ref $continuation)` in resume paths.

- [ ] **Step 4.2: Check the three hypotheses from the spec**

Against the trap location:

- **Hypothesis A** — `$continuation.$conts` holds a `(space-id . pc)` pair instead of a pair with code-object car. Read op 18 (`capture-continuation`) and op 19 (`do-continuation-winds`) at `wasm/runtime.wat:2708-2720` and downstream.
- **Hypothesis B** — `do-winds!` is invoked with a null `$code-obj`. Check the `$execute` resume path for the `$init-code-obj` and `$init-pc` parameters when restarting a continuation.
- **Hypothesis C** — `%yield!` primitive mis-shapes the stashed continuation. Find it: `grep -n '%yield!\|\$yield\b' wasm/runtime.wat`.

- [ ] **Step 4.3: Read `%yield!` and `call_continuation` in full**

```
grep -n '%yield!\|\$yield-cont\|call_continuation\|call-continuation' wasm/runtime.wat | head -20
```

Read each. Understand:
- What state `%yield!` writes when called.
- How `call_continuation` reads that state and invokes it.
- Where the trap happens along this path.

- [ ] **Step 4.4: Classify the diagnosis**

Write down (in your scratch notes, not a committed file):
1. The root-cause summary in one sentence.
2. The list of WAT file:line sites that need to change.
3. Estimated fix size in lines.

---

### Task 5: Decision point — narrow fix or abort?

- [ ] **Step 5.1: Apply the narrow-fix criteria**

Proceed to Phase 2 only if ALL of the following are true:
- The fix is concentrated in at most 2 functions (not a cross-cutting change).
- The fix is at most ~10 lines of WAT across those functions.
- The fix does NOT require modifying the `$continuation` struct definition, the `$execute` signature, or introducing new global state.
- The fix does NOT require coordinating edits in Scheme sources (`src/prelude.scm`) or JS (`wasm/glue.js`) to land atomically.

If ANY of those are violated, the fix is structural and the spec aborts.

- [ ] **Step 5.2a (narrow): Continue to Task 6**

Document the root cause in your scratch notes. Move to Phase 2.

- [ ] **Step 5.2b (abort): Update TODOs and close out**

If aborting:

1. **Revert your Phase 1 edits**:

```
cd /Users/anthonyfairchild/git/ece
git checkout wasm/test.js wasm/runtime.wasm
```

(The Makefile debug-names edit was already reverted in Step 3.3. Verify: `git status` should show no modifications.)

2. **Update the TODO in `wasm/runtime.wat`** to name the concrete root cause found:

Using the Edit tool, replace the current TODO block near op 19 (`wasm/runtime.wat:2711`) with one that names what was discovered. The existing text:

```
    ;; TODO (archive-loader follow-up): yield/resume tests in wasm/test.js
    ;; were disabled here because they hit an "illegal cast" under the new
    ;; 2-param $execute signature. The fix likely involves double-checking
    ;; that the continuation's $conts pair always holds a $code-object (not
    ;; a legacy (space-id . pc) pair) and that do-winds! itself has a
    ;; non-null $code-obj. Re-enable once that's diagnosed.
```

Replace with a new version that cites the specific root cause, the WAT sites involved, and the reason the fix is structural (e.g., "fix requires reshaping `$continuation.$conts` across 5 call sites and coordinated JS-glue changes — out of scope for a narrow WAT edit; see follow-up brainstorm TBD").

3. **Update the TODO in `wasm/test.js`** (line 55) similarly.

4. **Commit the updated TODOs** on the current branch:

```
git add wasm/runtime.wat wasm/test.js
git commit -m "wasm: update yield-test TODOs with concrete root cause

Phase 1 diagnosis of the illegal-cast trap identified <root cause>
at <location>. The fix is structural (exceeds this spec's narrow-fix
criteria); filing a follow-up brainstorm for the structural work.

Tests remain disabled; the restored bodies from this branch's
exploration are not committed (preserved in git stash for the
follow-up).

Design spec (aborted): docs/superpowers/specs/2026-04-24-wasm-yield-tests-reenable-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

5. **Push and convert to a closed PR** (or don't open one; let the branch sit). Report completion to the user summarizing the diagnosis.

---

## Phase 2 — Fix + verify (commit path)

Only proceed here if Step 5.1's narrow-fix criteria all hold.

### Task 6: Apply the WAT fix

**Files:**
- Modify: `/Users/anthonyfairchild/git/ece/wasm/runtime.wat` at the site identified by Phase 1

- [ ] **Step 6.1: Write the surgical edit**

The exact code for this step depends on the Phase 1 diagnosis. Apply the Edit tool at the identified WAT location. The fix must:
- Live entirely within the call sites identified in Task 4.
- Be at most ~10 lines total.
- Not modify `$continuation`, `$execute` signatures, or global state shape.

Record the one-sentence root-cause summary from Task 4 Step 4.4 — this goes into the commit message template in Task 8.

- [ ] **Step 6.2: Rebuild**

```
cd /Users/anthonyfairchild/git/ece
make wasm 2>&1 | tail -3
```

Expected: clean build, no wat2wasm errors.

---

### Task 7: Verify

**Files:** none modified.

- [ ] **Step 7.1: Targeted verification — are the three tests passing?**

```
make test-wasm 2>&1 | tail -10
```

Expected:
- Summary line: `WASM tests: 1011 passed, 0 failed` (previous 1008 baseline + 3 re-enabled).
- No `FAIL:` lines for `yield single frame`, `yield multi-frame (3 cycles)`, or `handle table stable over 100 yield cycles`.
- No `CRASH:` lines.

If any test still fails, go back to Task 4 and refine the diagnosis.

- [ ] **Step 7.2: Full-suite verification — nothing else regressed**

```
make test 2>&1 | grep -iE 'passed|failed|crash' | tail -15
```

Expected: every subsuite shows `0 failed`. The totals (rove + ece + wasm + conformance + golden + web-apps) should match the pre-change counts except for WASM being +3.

If any other suite regressed, re-examine the fix; it may have over-reached.

- [ ] **Step 7.3: Stability spot-check — run 3×**

```
for i in 1 2 3; do echo "=== Run $i ==="; make test-wasm 2>&1 | tail -3; done
```

Expected: all three runs show `1011 passed, 0 failed`. Specifically relevant for the "handle table stable over 100 yield cycles" test.

If any run fails with flaky behavior (e.g., 1 fail in one of the three runs), that signals an incomplete fix — investigate further before committing.

---

### Task 8: Commit the WAT fix + test restoration

**Files:**
- Commit: `wasm/runtime.wat` + `wasm/test.js`

- [ ] **Step 8.1: Verify scope of the diff**

```
cd /Users/anthonyfairchild/git/ece
git diff --stat
```

Expected: two files modified — `wasm/runtime.wat` (small — ~5-15 lines changed) and `wasm/test.js` (three tests added + TODO block removed, net +~80 lines).

- [ ] **Step 8.2: Remove the TODO in `wasm/test.js`**

Already done in Task 1 Step 1.4 (the TODO block was replaced by the restored tests). Verify:

```
grep -c 'TODO (archive-loader follow-up): yield' wasm/test.js
```

Expected: `0`.

- [ ] **Step 8.3: Remove the TODO near op 19 in `wasm/runtime.wat`**

Using the Edit tool, find the current op-19 TODO block (should be at approximately `wasm/runtime.wat:2715-2720` depending on where your fix shifted lines):

```
grep -n 'TODO (archive-loader follow-up): yield/resume tests' wasm/runtime.wat
```

If a match exists, delete that comment block (preserving the surrounding op 19 dispatch structure). If no match, the fix itself must have removed or displaced the TODO — that's fine.

- [ ] **Step 8.4: Commit with a message that names the root cause**

Replace `<ROOT-CAUSE-SUMMARY>` and `<FILE:LINE>` below with the one-sentence summary and the edit location from your Phase 1 notes:

```
git add wasm/runtime.wat wasm/test.js
git commit -m "wasm: fix <ROOT-CAUSE-SUMMARY> to restore yield tests

Closes Known follow-up #1 from the code-objects-completion roadmap.

Root cause: <one-sentence diagnosis from Phase 1>.

Fix: <one-sentence description of the WAT edit> at <FILE:LINE>.

Re-enables the three yield tests in wasm/test.js removed by commit
7403276 during P0's \$comp-space retirement. Removes the matching
TODOs in wasm/test.js and wasm/runtime.wat near op 19.

Verification:
- make test-wasm: 1011 passed, 0 failed (was 1008 + 3 re-enabled).
- make test full suite: no regressions.
- 3× consecutive make test-wasm runs all pass.

Spec: docs/superpowers/specs/2026-04-24-wasm-yield-tests-reenable-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

Make sure to substitute `<ROOT-CAUSE-SUMMARY>` and the bracketed placeholders with actual content from Task 4. Do not commit with literal placeholder text.

---

### Task 9: Update the roadmap

**Files:**
- Modify: `/Users/anthonyfairchild/git/ece/docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`

- [ ] **Step 9.1: Locate the Known follow-up #1 bullet**

```
cd /Users/anthonyfairchild/git/ece
grep -n 'Three disabled WASM yield tests' docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md
```

Expected: one match (likely the first bullet under "Known follow-ups").

- [ ] **Step 9.2: Mark shipped**

Using the Edit tool. Read the current paragraph to get the exact `old_string`:

```
sed -n '90,100p' docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md
```

Replace the bullet text. Shape of the replacement (substitute the actual root-cause summary):

```
- **Three disabled WASM yield tests** — **Shipped** (this PR). Phase 1 of the diagnosis in `docs/superpowers/specs/2026-04-24-wasm-yield-tests-reenable-design.md` identified <ROOT-CAUSE-SUMMARY>. A surgical WAT fix at <FILE:LINE> restores the three tests; `make test-wasm` now shows 1011 passed, 0 failed. TODOs in `wasm/test.js:55` and `wasm/runtime.wat` (op 19) removed.
```

- [ ] **Step 9.3: Commit the roadmap update**

```
git add docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md
git commit -m "roadmap: mark WASM yield tests re-enabled

Follow-up #1 from the code-objects-completion roadmap shipped.
The illegal-cast trap in do-continuation-winds was <ROOT-CAUSE-SUMMARY>;
fix at <FILE:LINE> of wasm/runtime.wat.

Design: docs/superpowers/specs/2026-04-24-wasm-yield-tests-reenable-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Push + PR

- [ ] **Step 10.1: Confirm branch state**

```
cd /Users/anthonyfairchild/git/ece
git log --oneline main..HEAD
```

Expected (bottom to top):
```
<hash> roadmap: mark WASM yield tests re-enabled
<hash> wasm: fix <ROOT-CAUSE-SUMMARY> to restore yield tests
<hash> Add design spec: re-enable WASM yield tests
```

- [ ] **Step 10.2: Push**

```
git push -u origin wasm-yield-tests-reenable
```

- [ ] **Step 10.3: Open PR via the wrapper**

```
scripts/ece-gh pr create --base main --head wasm-yield-tests-reenable --title "wasm: re-enable yield tests" --body "$(cat <<'EOF'
## Summary

Closes Known follow-up #1 from the code-objects-completion roadmap.
Fixes the illegal-cast trap in the \`do-continuation-winds\` + resume
path and restores the three WASM yield tests removed during P0's
\`\$comp-space\` retirement (commit 7403276).

## Root cause

<ONE-SENTENCE SUMMARY — replace before running>

## Fix

<ONE-SENTENCE DESCRIPTION — replace before running>

at \`<FILE:LINE>\`.

## Test plan

- [x] \`make test-wasm\` passes: 1011/0 (1008 baseline + 3 restored).
- [x] \`make test\` full suite: no regressions.
- [x] 3× consecutive \`make test-wasm\` runs all green.

## Spec + design

- docs/superpowers/specs/2026-04-24-wasm-yield-tests-reenable-design.md
- docs/superpowers/plans/2026-04-24-wasm-yield-tests-reenable.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Substitute `<ONE-SENTENCE SUMMARY>` and `<ONE-SENTENCE DESCRIPTION>` with the Task 4 notes before running. Copilot will auto-review via the repo ruleset.

- [ ] **Step 10.4: Wait for CI, address Copilot, merge**

Follow the established flow: poll `scripts/ece-gh run view <id>`; on success, fetch `scripts/ece-gh api repos/anthonyf/ece/pulls/<N>/comments`; amend + force-push any real concerns; `scripts/ece-gh pr merge <N> --merge --delete-branch`.

---

## Self-Review Notes

**Spec coverage:**
- Spec §1 (scope + deliverables) → Phase 1 (Tasks 1-5) + Phase 2 (Tasks 6-10).
- Spec §2 (Phase 1 investigation plan) → Tasks 1-4.
- Spec §2 (Phase 1 exit criteria) → Task 5.
- Spec §3 (Phase 2 fix + verification) → Tasks 6-8 (incl. verification triad in Task 7).
- Spec §4 (commits) → Tasks 8, 9; PR in Task 10.
- Spec non-goal "no ECE migration" → reflected in Task 1 (restore to `wasm/test.js`, not `.scm`).

**Placeholder scan:** all `<ROOT-CAUSE-SUMMARY>` / `<FILE:LINE>` / `<ONE-SENTENCE SUMMARY>` markers are explicitly called out as substitute-before-running — they are NOT "TBD"s the implementer is expected to fabricate. They are instructions to paste real content from the Phase 1 diagnosis, which is the mandatory prior step.

**Type consistency:** test names match between Task 1 (restoration), Task 7 (expected passes), and the verification step; `1011` appears consistently in Tasks 7 + 8 + 9 + 10; branch name is consistent throughout.
