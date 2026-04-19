# Per-Procedure Code Objects — Finishing Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the `per-procedure-code-objects` OpenSpec change by switching `.ecec` to archive format, regenerating zones per code-object, and retiring the legacy `compilation-space` machinery.

**Architecture:** Already done (branch `per-procedure-code-objects`, 17 commits): code-object defstruct, primitives, bottom-up compiler emission, pure assembler, executor dispatch, bottom-up closure shape, archive format reader/writer, disassemble accepts code-objects. Still to do: switch compile-system to emit archives, port the archive reader into CL so boot can read new-format `bootstrap.ecec`, refactor zone codegen to per-code-object defuns, retire `%space-*` primitives and `*space-registry*`, final doc+test+PR.

**Tech Stack:** Common Lisp (SBCL 2.6.3 via qlot), WebAssembly Text (WAT), ECE Scheme (self-hosted), Makefile build driver.

## Starting State

- Branch: `per-procedure-code-objects` (based on `main`)
- Last commit: `e115b78` (dual-format ECE loader, §9.2 prep)
- Done tasks: §1, §2, §3, §4, §5.1, §5.3, §5.4, §6.1, §6.3, §6.4, §6.5, §6.6, §7, §8, §9.1, §10.1, §10.3, §10.4
- Remaining tasks: §5.2, §6.2, §9.2–§9.4, §10.2, §10.5, §11, §12, §13, §14, §15
- **Blocker context:** §9.2 (format switch) requires CL-side archive parser because `bootstrap.ecec` loads via CL's `load-ecec-section` BEFORE ECE prelude boots. ECE's `archive-sexp->code-objects` isn't available at that point. Memory note: `project_9_2_archive_format_scope.md`.

## Required Reading Before Starting

Read these in full before Task 1 — they contain constraints that change how steps below are interpreted:

1. `openspec/changes/per-procedure-code-objects/proposal.md` — why we're doing this
2. `openspec/changes/per-procedure-code-objects/design.md` — locked decisions
3. `openspec/changes/per-procedure-code-objects/specs/code-object-compilation/spec.md` — the SHALL contracts with scenarios
4. `openspec/changes/per-procedure-code-objects/specs/compile-system/spec.md` — archive loading requirements
5. `openspec/changes/per-procedure-code-objects/specs/symbol-space-id/spec.md` — REMOVED requirements list
6. `openspec/changes/per-procedure-code-objects/tasks.md` — current checkbox state; truth source for "is §N done?"
7. `/Users/anthonyfairchild/.claude/projects/-Users-anthonyfairchild-git-ece/memory/project_9_2_archive_format_scope.md` — CL-side loader pitfall

## Conventions

- **Branch:** continue on `per-procedure-code-objects`. Don't rebase onto main unless asked.
- **Commits:** small, one-concept commits. No squashing. Each commit builds (`make bootstrap` succeeds or the Makefile target still works) and `make test-ece` still passes unless explicitly noted.
- **Co-author trailer:** every commit message ends with `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.
- **Task checkboxes:** after finishing a numbered OpenSpec task (e.g., §9.2), flip its `- [ ]` → `- [x]` in `openspec/changes/per-procedure-code-objects/tasks.md` in the SAME commit that lands the work. Add a short italic note below the checkbox explaining any non-obvious choice.
- **Do not add sandbox-restricted paths.** Tests must use `/tmp/claude/` or the project-local `.tmp/`, never bare `/tmp/`.
- **Bootstrap rebuild cadence:** full rebuild takes ~3–5 min. Don't do speculative rebuilds. Only rebuild after a change that actually affects bootstrap sources.
- **Test command:** `make test-ece` is the primary gate. Final PR gate also runs `make test` (all suites).
- **Formatter:** a pre-commit hook formats `*.scm` / `*.lisp` files. Let it run. If it renames, re-stage and commit.

---

## File Structure — What Each Task Touches

| File | Role | Tasks |
|---|---|---|
| `src/runtime.lisp` | CL boot loader; holds `load-ecec-section`, `*space-registry*`, `execute-instructions`. | A1–A5, E1, F1, F2, G1 |
| `src/compilation-unit.scm` | ECE archive reader/writer; `compile-system`, `load-bundle`. | B1, D1, D2, E2 |
| `src/codegen-cl-inline.scm` | Zone codegen (960 lines, reads spaces, emits `zone-NAME` defuns). | C1–C4 |
| `src/assembler.scm` | `assemble-into-global` shim to retire. | G2 |
| `src/compiler.scm` | Compiler; mostly done, minor touch-ups if §11 changes ripple. | F4 (maybe) |
| `src/primitives.scm` | Primitive definitions (`%space-*` to delete). | F3 |
| `src/boot-env.scm` | Primitive registrations. | F3 |
| `src/disassemble.scm` | Drop reachability walk after §11. | H1, H2 |
| `primitives.def` | Primitive manifest. | F3 |
| `wasm/runtime.wat` | WASM parallel changes. | F5, G3 |
| `Makefile` | Bootstrap target; zone regeneration target. | D2, D3 |
| `bootstrap/primitives-auto.lisp` | Generated; regenerates via `make bootstrap/primitives-auto.lisp`. | F3 |
| `bootstrap/*-zone.lisp` | Generated; regenerates via `make bootstrap/assembler-zone.lisp` (zone sentinel). | C4, D3 |
| `CLAUDE.md` | Doc updates. | J1 |
| `openspec/roadmap-if.md` | Doc updates. | J2 |
| `openspec/changes/per-procedure-code-objects/tasks.md` | Task checkboxes. | Every task |

---

## Phase A — CL-side Archive Parser and Dual-Format Boot Loader

**Why first:** `bootstrap.ecec` must be readable in new format before we flip `compile-system`. The ECE-level dual-format loader (already committed at `e115b78`) only handles post-boot loads. Boot time uses `load-ecec-section` in CL.

**Outcome:** A handwritten archive in `ecec-archive` format can load via the CL boot path. No changes to `compile-system` yet; `bootstrap.ecec` still uses the old format.

### Task A1: Add `make-code-object-from-archive` helper in CL runtime

**Files:**
- Modify: `src/runtime.lisp` (insert after existing `defstruct code-object` block around line 1529)

- [ ] **Step 1: Write the failing test**

Create `tests/ece/cl-only/test-cl-archive-parser.scm`:

```scheme
;;; tests/ece/cl-only/test-cl-archive-parser.scm
;;;
;;; Exercises CL-side archive parsing via a host shim. These tests run the
;;; CL parser on synthesized archive s-exprs, not on disk.

(test "CL archive parser: single-entry archive builds one code-object" (lambda ()
  ;; Build an ECE-side archive for (+ 1 2), then round-trip through the
  ;; CL parser by writing to a port and re-reading via the CL path.
  (define co (mc-compile-to-code-object '(+ 1 2)))
  (define archive (code-object->archive-sexp co "scratch.scm"))
  (define text (write-to-string-flat archive))
  ;; Write to /tmp/claude/ path
  (define tmp-path "/tmp/claude/test-archive-cl.ecec")
  (define out (open-output-file tmp-path))
  (display text out) (newline out) (close-output-port out)
  ;; The CL-side load path is what §9.2 will exercise. For now, use the
  ;; ECE-side to show round-trip parity with the archive sexp shape.
  (define loaded (load-archive tmp-path))
  (assert-equal 3 loaded)))
```

- [ ] **Step 2: Run test to verify it passes (ECE-side already supports this)**

```bash
make test-ece 2>&1 | grep -E "test-cl-archive-parser|Total:"
```

Expected: the new test passes (leveraging existing ECE archive loader). This is the baseline — A2 will add the CL boot path and expand tests.

- [ ] **Step 3: Commit baseline test**

```bash
git add tests/ece/cl-only/test-cl-archive-parser.scm
git commit -m "$(cat <<'EOF'
§9.2-prep: baseline test for archive round-trip via file path

Sets up the test file that §A2–A5 will extend with CL-side boot-loader
coverage. The current assertion just exercises the existing ECE archive
writer + reader through a file.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task A2: Port archive parser to CL (pure, no side effects)

**Files:**
- Modify: `src/runtime.lisp` (add after `resolve-operations` near line 1627)

- [ ] **Step 1: Add `parse-archive-sexp` defun**

Insert:

```lisp
;;; ─────────────────────────────────────────────────────────────────────────
;;; Archive-format parser (CL-side, mirrors archive-sexp->code-objects
;;; in src/compilation-unit.scm). Needed at boot because bootstrap.ecec
;;; is read by load-ecec-section BEFORE ECE prelude is loaded, so the
;;; ECE-side parser isn't available yet.
;;; ─────────────────────────────────────────────────────────────────────────

(defun archive-plist-get (plist key)
  "Walk a plain-symbol-keyed plist, return value after KEY or NIL."
  (cond
    ((null plist) nil)
    ((null (cdr plist)) nil)
    ((eq (car plist) key) (cadr plist))
    (t (archive-plist-get (cddr plist) key))))

(defun archive-patch-co-refs (tree cos-vec)
  "Replace every (const (co-ref N)) in TREE with (const <code-object-at-N>)."
  (cond
    ((null tree) nil)
    ((not (consp tree)) tree)
    ((and (eq (car tree) '|const|)
          (consp (cdr tree))
          (consp (cadr tree))
          (eq (caadr tree) '|co-ref|))
     (list '|const| (aref cos-vec (cadr (cadr tree)))))
    (t (cons (archive-patch-co-refs (car tree) cos-vec)
             (archive-patch-co-refs (cdr tree) cos-vec)))))

(defun parse-archive-sexp (archive)
  "Parse a read archive s-expr into a simple-vector of code-object structs.
The shape matches the ECE-side archive-sexp->code-objects output: entry 0 is
the file init; entries 1..N-1 are nested hoisted code-objects. Signals an
ece-runtime-error on version mismatch."
  (let* ((version (archive-plist-get (cdr archive) '|version|))
         (entries (archive-plist-get (cdr archive) '|entries|)))
    (unless (eql version 2)
      (error 'ece-runtime-error
             :procedure nil
             :arguments nil
             :environment *global-env*
             :instruction nil
             :backtrace nil
             :original-error
             (make-condition 'simple-error
                             :format-control "Unsupported .ecec archive version: ~A. Run `make bootstrap` to regenerate."
                             :format-arguments (list (or version "missing")))))
    (let* ((entries-vec (coerce entries 'simple-vector))
           (n (length entries-vec))
           (cos (make-array n)))
      ;; Pass 1: create code-objects, set metadata + labels.
      (dotimes (i n)
        (let* ((entry (aref entries-vec i))
               (fields (cdr entry))
               (co (make-code-object)))
          (let ((name (archive-plist-get fields '|name|)))
            (when name (setf (code-object-name co) name)))
          (let ((arity (archive-plist-get fields '|arity|)))
            (when arity (setf (code-object-arity co) arity)))
          (let ((src-loc (archive-plist-get fields '|source-loc|)))
            (when src-loc (setf (code-object-source-loc co) src-loc)))
          (dolist (pair (archive-plist-get fields '|labels|))
            (setf (gethash (car pair) (code-object-labels co)) (cdr pair)))
          (setf (aref cos i) co)))
      ;; Pass 2: push instructions (with (co-ref N) patched to code-objects).
      (dotimes (i n)
        (let* ((entry (aref entries-vec i))
               (co (aref cos i))
               (raw-instrs (archive-plist-get (cdr entry) '|instructions|)))
          (dolist (instr raw-instrs)
            (let ((patched (archive-patch-co-refs instr cos)))
              (vector-push-extend patched (code-object-source-instructions co))
              (vector-push-extend (resolve-operations patched)
                                  (code-object-resolved-instructions co))))))
      cos)))
```

- [ ] **Step 2: Test parser in a throwaway CL REPL script**

Create `/tmp/claude/test-parse-archive.lisp`:

```lisp
(in-package :ece)

(let* ((sexp '(|ecec-archive|
               |version| 2
               |file| "scratch.scm"
               |entries|
               ((|code-object|
                 |name| |%init|
                 |arity| nil
                 |source-loc| nil
                 |labels| ()
                 |instructions|
                 ((|assign| |val| (|const| 42))
                  (|goto| (|reg| |continue|)))))))
       (cos (parse-archive-sexp sexp))
       (init (aref cos 0)))
  (format t "count: ~A~%" (length cos))
  (format t "init name: ~A~%" (code-object-name init))
  (format t "init len: ~A~%" (length (code-object-source-instructions init))))
```

Run:

```bash
ASDF_OUTPUT_TRANSLATIONS='(:output-translations ("'$PWD'/" "'$PWD'/.fasl-cache/") :inherit-configuration)' \
  qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --load '/tmp/claude/test-parse-archive.lisp' \
  --quit
```

Expected:
```
count: 1
init name: |%init|
init len: 2
```

- [ ] **Step 3: Commit**

```bash
git add src/runtime.lisp
git commit -m "$(cat <<'EOF'
§9.2a CL: port archive parser — parse-archive-sexp in runtime.lisp

Mirrors archive-sexp->code-objects from src/compilation-unit.scm so that
bootstrap.ecec can be read by load-ecec-section at boot time, before the
ECE prelude loads. Pure function: takes a read s-expr, returns a vector
of code-object structs. Signals on version mismatch with the same
diagnostic the ECE version does.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task A3: Dual-format `load-ecec-section` in CL

**Files:**
- Modify: `src/runtime.lisp` (around line 1952, `load-ecec-section`)

- [ ] **Step 1: Replace `load-ecec-section` body**

Replace the existing `load-ecec-section` with:

```lisp
(defun load-ecec-section (stream &key skip)
  "Load one ecec section from STREAM. Dispatches on the first form:
  - (ecec-header ...) → legacy space-based section, reads a second form
    with the compiled instructions and executes against a new space.
  - (ecec-archive ...) → archive format, builds code-objects via
    parse-archive-sexp and invokes the init.
Returns T if a section was loaded, NIL on EOF."
  (let* ((*package* (find-package :ece))
         (*readtable* *ecec-readtable*)
         (raw-head (cl:read stream nil :eof)))
    (when (eq raw-head :eof) (return-from load-ecec-section nil))
    (let ((head (downcase-ece-symbols raw-head)))
      (cond
        ((and (consp head) (eq (car head) '|ecec-archive|))
         (load-ecec-archive-section head))
        (t
         (load-ecec-legacy-section head stream :skip skip))))
    t))

(defun load-ecec-archive-section (archive)
  "Archive-format dispatch: parse the archive, execute the init code-object.
Nested code-objects become globally reachable through whatever top-level
bindings the init sets up; no separate registry is needed."
  (let* ((canonicalized (downcase-ece-symbols
                          (canonicalize-ecec-constants archive)))
         (cos (parse-archive-sexp canonicalized))
         (init (aref cos 0)))
    (execute-instructions init 0 *global-env*)))

(defun load-ecec-legacy-section (header stream &key skip)
  "Legacy-format dispatch: HEADER is already read. Read instructions as a
second form and execute against a fresh space. Retires once old-format
.ecec files disappear (§9.3)."
  (let* ((space-sym (cadr (assoc '|space| (cdr header))))
         (space-name (symbol-name space-sym)))
    (when (and skip (member space-name skip :test #'string=))
      (cl:read stream)
      (return-from load-ecec-legacy-section nil))
    (let ((source-map-raw (cdr (assoc '|source-map| (cdr header))))
          (sid (create-space space-name)))
      (when source-map-raw
        (register-ecec-source-map space-sym source-map-raw))
      (let ((*current-space-id* sid))
        (let* ((instrs (cl:read stream))
               (fixed (downcase-ece-symbols
                        (canonicalize-ecec-constants instrs)))
               (start-pc (assemble-into-space sid fixed)))
          (execute-instructions sid start-pc *global-env*))))))
```

- [ ] **Step 2: Build bootstrap and run tests to confirm no regression**

`bootstrap.ecec` is still old format, so the legacy branch runs. Archive branch is unused but wired in.

```bash
make bootstrap 2>&1 | tail -5
make test-ece 2>&1 | tail -3
```

Expected:
- `make bootstrap`: completes with "Generated all compiled zones"
- `make test-ece`: `Total: 717 collected, 717 ran, 1318 passed, 0 failed`

- [ ] **Step 3: Commit**

```bash
git add src/runtime.lisp bootstrap/bootstrap.ecec
git commit -m "$(cat <<'EOF'
§9.2a CL: dual-format load-ecec-section — (ecec-archive ...) dispatch

Adds the CL-side half of the compatibility shim. Splits into three
pieces:
  - load-ecec-section now reads the first form and dispatches.
  - load-ecec-archive-section parses the archive and executes the init.
  - load-ecec-legacy-section keeps the prior behavior for old-format files.

bootstrap.ecec is still old format so only the legacy path runs; the
archive branch is exercised by Phase D once compile-system flips.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task A4: Write an archive file by hand and confirm CL loads it

**Files:**
- Create: `tests/ece/cl-only/test-cl-archive-boot.lisp` (CL-level smoke)

- [ ] **Step 1: Write the CL smoke test script**

Create `/tmp/claude/archive-boot-smoke.lisp`:

```lisp
(in-package :ece)

;; Compile a trivial top-level, serialize to archive, write to disk, then
;; re-read via load-ecec-section (the path boot uses).
(let* ((co-expr '(|define| |boot-smoke-val| 123))
       (unused (defparameter *last-boot-smoke* nil)))
  (declare (ignore unused))
  ;; Use the ECE-side compile and archive writer.
  (evaluate
   `(|load-archive|
     ,(let* ((expr co-expr)
             (tmp "/tmp/claude/archive-boot-smoke.ecec")
             (write-it (evaluate
                         `(|let| ((|co| (|mc-compile-to-code-object|
                                          (|quote| ,expr))))
                            (|let| ((|out| (|open-output-file| ,tmp)))
                              (|display|
                                (|write-to-string-flat|
                                  (|code-object->archive-sexp|
                                    |co| "scratch.scm"))
                                |out|)
                              (|newline| |out|)
                              (|close-output-port| |out|)
                              ,tmp)))))
        write-it))))

;; Now re-load via the CL path (simulating a boot).
(with-open-file (s "/tmp/claude/archive-boot-smoke.ecec")
  (load-ecec-section s))

;; Confirm the binding took effect.
(format t "boot-smoke-val = ~A~%" (lookup-variable-value
                                    (intern "boot-smoke-val" :ece)
                                    *global-env*))
```

- [ ] **Step 2: Run the smoke test**

```bash
ASDF_OUTPUT_TRANSLATIONS='(:output-translations ("'$PWD'/" "'$PWD'/.fasl-cache/") :inherit-configuration)' \
  qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --load '/tmp/claude/archive-boot-smoke.lisp' \
  --quit 2>&1 | tail -5
```

Expected output includes:
```
boot-smoke-val = 123
```

If it doesn't: investigate whether `execute-instructions` on a bare code-object hooks into `*global-env*` correctly. Look at `maybe-dispatch-compiled-zone` and the qualified-space-id helpers.

- [ ] **Step 3: Extend test-cl-archive-parser.scm with a load-section scenario**

Append to `tests/ece/cl-only/test-cl-archive-parser.scm`:

```scheme
(test "CL archive parser: define via load-bundle archives" (lambda ()
  ;; Compile a define to an archive, load via load-bundle, verify binding.
  (define co (mc-compile-to-code-object '(define *plan-a4-binding* 777)))
  (define archive (code-object->archive-sexp co "scratch.scm"))
  (define text (write-to-string-flat archive))
  (define tmp-path "/tmp/claude/test-archive-define.ecec")
  (define out (open-output-file tmp-path))
  (display text out) (newline out) (close-output-port out)
  (load-bundle tmp-path)
  (assert-equal 777 *plan-a4-binding*)))
```

- [ ] **Step 4: Run tests**

```bash
make test-ece 2>&1 | grep -E "test-cl-archive-parser|Total:"
```

Expected: new test passes.

- [ ] **Step 5: Commit**

```bash
git add tests/ece/cl-only/test-cl-archive-parser.scm
git commit -m "$(cat <<'EOF'
§9.2a: archive-format round-trip test through load-bundle

Verifies the ECE dual-format loader (committed e115b78) and the CL
dual-format loader (Task A3) produce identical behavior on a define
archive. Hand-written smoke test at /tmp/claude/archive-boot-smoke.lisp
validated the CL boot path.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task A5: Mark §9.2 partial progress (no checkbox flip yet — §9.2 is DONE in Phase D)

- [ ] **Step 1: Add a progress note in tasks.md**

Edit `openspec/changes/per-procedure-code-objects/tasks.md`:

Below `- [ ] 9.2 Switch compile-system output ...`, add an italic sub-note:

```markdown
      *Phase A (Apr 19 2026): CL-side archive parser + dual-format load-ecec-section landed (Tasks A2/A3). compile-system switch proper is Phase D.*
```

- [ ] **Step 2: Commit**

```bash
git add openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "$(cat <<'EOF'
tasks: note §9.2 Phase A progress (CL-side archive parser prerequisites)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase B — Per-Code-Object Zone Codegen

**Why now:** Once `compile-system` flips (Phase D), `bootstrap.ecec` stops populating `*space-registry*` with per-file spaces. The current codegen iterates `all-bootstrap-spaces` reading from that registry. It'll emit empty zones unless we teach it to walk code-objects instead.

**Outcome:** Codegen can walk either an archive or a space-id and produces byte-identical output for the same compiled source. Existing `bootstrap/*-zone.lisp` regenerates unchanged because source unchanged.

### Task B1: Extract instruction-walking abstraction

**Files:**
- Modify: `src/codegen-cl-inline.scm`

The codegen calls `(%space-source-ref space-id pc)` in at least three places (lines ~225, ~394, ~433). Introduce an indirection that accepts either a symbol (space) or a code-object.

- [ ] **Step 1: Read existing codegen orientation**

```bash
head -50 src/codegen-cl-inline.scm
```

Identify the three source-ref call sites:

```bash
grep -n "%space-source-ref\|%space-label-entries\|%space-instruction-length" src/codegen-cl-inline.scm
```

Expected: ~5 hits total.

- [ ] **Step 2: Introduce `cg/source-ref`, `cg/instruction-length`, `cg/label-entries` helpers**

Add near line 45 (after chunk-ctx helpers):

```scheme
;;; ─────────────────────────────────────────────────────────────────────────
;;; Source abstraction: accept either a space-id symbol OR a code-object.
;;; Lets the same emitter walk bootstrap spaces (legacy) or archive code-
;;; objects (post §9.2). Once the space path retires (§11), these collapse
;;; to the code-object branch.
;;; ─────────────────────────────────────────────────────────────────────────

(define (cg/source-ref src pc)
  (if (code-object? src)
      (vector-ref (code-object-instructions src) pc)
      (%space-source-ref src pc)))

(define (cg/instruction-length src)
  (if (code-object? src)
      (code-object-length src)
      (%space-instruction-length src)))

(define (cg/label-entries src)
  (if (code-object? src)
      (code-object-label-entries src)
      (%space-label-entries src)))
```

- [ ] **Step 3: Replace every `%space-source-ref space-id pc`, `%space-label-entries space-id`, `%space-instruction-length space-id` in this file with the `cg/*` equivalents**

Run:

```bash
grep -n "%space-source-ref space-id\|%space-label-entries space-id\|%space-instruction-length space-id" src/codegen-cl-inline.scm
```

For each hit, replace `%space-source-ref space-id` → `cg/source-ref space-id`, etc. The `space-id` parameter name stays — it's just an identifier.

- [ ] **Step 4: Verify bootstrap still regenerates zone files byte-identically**

```bash
make bootstrap/bootstrap.ecec 2>&1 | tail -2
rm -f bootstrap/*-zone.lisp .fasl-cache/bootstrap/*-zone.fasl
touch bootstrap/assembler-zone.lisp  # force sentinel to be considered stale
make bootstrap 2>&1 | tail -5
git diff --stat bootstrap/*-zone.lisp
```

Expected: `git diff --stat` shows no changes to `*-zone.lisp` files (or at most whitespace).

- [ ] **Step 5: Commit**

```bash
git add src/codegen-cl-inline.scm
git commit -m "$(cat <<'EOF'
§12.1 prep: codegen takes either space-id or code-object via cg/* shim

Introduces cg/source-ref, cg/instruction-length, cg/label-entries that
dispatch on code-object? vs symbol. Replaces the three direct %space-*
call sites. Bootstrap output unchanged (verified byte-identical zone
files after a full regen).

Lets Phase B2 add a code-object-aware emitter without duplicating the
instruction-walking code.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task B2: Add `generate-zone-cl-for-code-object!`

**Files:**
- Modify: `src/codegen-cl-inline.scm`

- [ ] **Step 1: Add the new entry point**

After the existing `generate-zone-cl!` (line 74), insert:

```scheme
;;; Code-object-oriented entry point. Mirrors generate-zone-cl! but takes
;;; a code-object directly (no registry lookup). Used by Phase D's archive
;;; codegen driver.
(define (generate-zone-cl-for-code-object! co zone-name output-path)
  "Emit one (defun zone-NAME ...) for CO. ZONE-NAME is the string used as
the function name suffix. OUTPUT-PATH is the destination .lisp file.
Returns OUTPUT-PATH."
  (let ((count (cg/instruction-length co)))
    (when (= count 0)
      (%raw-error
       (string-append "generate-zone-cl-for-code-object!: empty code-object "
                      zone-name)))
    (let ((out (open-output-file output-path)))
      (emit-zone-header out zone-name)
      (if (needs-splitting? count)
          (emit-zone-defun-split out zone-name co count)
          (emit-zone-defun out zone-name co count))
      (close-output-port out)
      output-path)))
```

Note: `emit-zone-defun` and `emit-zone-defun-split` previously took `space-id`. Since `cg/source-ref` et al. accept a code-object, they already work when `space-id` is actually a code-object — the parameter name is the only lie. Leave it for now; Phase F2 renames.

- [ ] **Step 2: Add a round-trip test**

Create `tests/ece/cl-only/test-codegen-code-object.scm`:

```scheme
;;; Codegen reads a code-object and emits a zone .lisp file with the same
;;; shape as the space-keyed path.

(test "codegen: emits zone .lisp from a code-object" (lambda ()
  (define co (mc-compile-to-code-object '(lambda (x) (* x x))))
  (define tmp-path "/tmp/claude/test-zone-from-co.lisp")
  (generate-zone-cl-for-code-object! co "test-square" tmp-path)
  ;; Confirm the file exists and starts with the expected header.
  (define in (open-input-file tmp-path))
  (define line1 (read-line in))
  (close-input-port in)
  (assert-equal ";;;; bootstrap/test-square-zone.lisp" line1)))

(test "codegen: emitted zone contains a defun whose name matches" (lambda ()
  (define co (mc-compile-to-code-object '(+ 1 2)))
  (define tmp-path "/tmp/claude/test-zone-addone.lisp")
  (generate-zone-cl-for-code-object! co "plan-b2-addone" tmp-path)
  ;; read the file as a string and search for the defun token
  (define in (open-input-file tmp-path))
  (let loop ((saw-defun #f))
    (let ((line (read-line in)))
      (cond
       ((eof? line)
        (close-input-port in)
        (assert-equal #t saw-defun))
       ((string-contains line "(defun zone-plan-b2-addone ")
        (loop #t))
       (else (loop saw-defun))))))
```

- [ ] **Step 3: Run tests**

```bash
make test-ece 2>&1 | grep -E "test-codegen-code-object|Total:"
```

Expected: two new tests pass, `Total: 719 collected, 719 ran, ... 0 failed`.

- [ ] **Step 4: Commit**

```bash
git add src/codegen-cl-inline.scm tests/ece/cl-only/test-codegen-code-object.scm
git commit -m "$(cat <<'EOF'
§12.1: add generate-zone-cl-for-code-object! entry point

Parallel to generate-zone-cl! but takes a code-object instead of a
space-id. Reuses the cg/* indirection so the emission path is shared.
Tests exercise the emitted file shape and defun naming.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task B3: Add `generate-all-zones-from-archive!`

**Files:**
- Modify: `src/codegen-cl-inline.scm`

- [ ] **Step 1: Add archive-driven batch generator**

After `generate-all-zones!` (around line 940), add:

```scheme
(define (zone-name-for-code-object file-stem index co)
  "Compose a zone filename stem. Uses the code-object's name if set
(for the init code-object of a source file, that's `%init`), falls back
to FILE-STEM-INDEX."
  (let ((name (code-object-name co)))
    (cond
     ((and name (symbol? name))
      (string-append file-stem "-" (symbol->string name)))
     ((and name (string? name))
      (string-append file-stem "-" name))
     (else
      (string-append file-stem "-" (number->string index))))))

(define (generate-all-zones-from-archive! archive-path output-dir)
  "Read an archive file from ARCHIVE-PATH, iterate its code-objects, and
emit one zone file per code-object under OUTPUT-DIR. Output filenames:
`<archive-stem>-<co-name-or-index>-zone.lisp`.

Signals an error if the archive has zero entries. Deterministic: entries
are processed in archive order, which matches collect-reachable order
(init first, then nested lambdas BFS)."
  (let* ((port (open-input-file archive-path))
         (archive (ece-scheme-read port))
         (unused (close-input-port port))
         (cos (archive-sexp->code-objects archive))
         (n (vector-length cos))
         (file-stem (filename-strip-extension
                      (filename-basename archive-path) ".ecec")))
    (declare (ignore unused))
    (when (= n 0)
      (%raw-error "generate-all-zones-from-archive!: archive has no code-objects"))
    (let loop ((i 0))
      (when (< i n)
        (let* ((co (vector-ref cos i))
               (zone-name (zone-name-for-code-object file-stem i co))
               (output-path (string-append output-dir "/" zone-name "-zone.lisp")))
          (display (string-append "Generating " output-path
                                  " (" (number->string (code-object-length co))
                                  " PCs)..."))
          (newline)
          (generate-zone-cl-for-code-object! co zone-name output-path)
          (display (string-append "  Done: " output-path))
          (newline))
        (loop (+ i 1))))))
```

Note: `declare` isn't real ECE — replace with a `begin`-style unused binding:

```scheme
         (archive (ece-scheme-read port))
         (_close (close-input-port port))
         (cos (archive-sexp->code-objects archive))
```

and drop the `(declare (ignore unused))` line.

- [ ] **Step 2: Manual smoke: generate zones from a fixture archive**

Create `/tmp/claude/fixture-compile.lisp`:

```lisp
(in-package :ece)
(evaluate '(|compile-file-archive| "src/boot-env.scm"))
(format t "~A~%" (probe-file "src/boot-env.ecec"))
```

Run:

```bash
ASDF_OUTPUT_TRANSLATIONS='(:output-translations ("'$PWD'/" "'$PWD'/.fasl-cache/") :inherit-configuration)' \
  qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --load '/tmp/claude/fixture-compile.lisp' \
  --quit 2>&1 | tail -3
```

Expected: prints `#P"/.../src/boot-env.ecec"`. Then:

```bash
ASDF_OUTPUT_TRANSLATIONS='(:output-translations ("'$PWD'/" "'$PWD'/.fasl-cache/") :inherit-configuration)' \
  qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --eval '(ece:evaluate (list (intern "generate-all-zones-from-archive!" :ece) "src/boot-env.ecec" "/tmp/claude/fixture-zones"))' \
  --quit 2>&1 | tail -10
```

Expected: `Generating /tmp/claude/fixture-zones/boot-env-%init-zone.lisp (N PCs)...` plus one per nested code-object.

```bash
ls /tmp/claude/fixture-zones/
```

Expected: multiple `*-zone.lisp` files.

Clean up:
```bash
rm -f src/boot-env.ecec
rm -rf /tmp/claude/fixture-zones
```

- [ ] **Step 3: Commit**

```bash
git add src/codegen-cl-inline.scm
git commit -m "$(cat <<'EOF'
§12.1: generate-all-zones-from-archive! — archive-driven zone codegen

Reads a .ecec archive, iterates its code-objects, emits one zone file
per code-object. Names zones by the code-object's name when set (e.g.
`prelude-%init-zone.lisp`, `prelude-append-zone.lisp`) with an index
fallback for anonymous lambdas.

Exercised manually against a fixture archive of src/boot-env.scm
(verified N zone files produced, one per reachable code-object).

Makefile switchover to use this in the zone target is Phase D.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase C — Archive Loader Attaches `native-fn` from Zones

**Why:** After Phase D flips compile-system, `bootstrap.ecec` is archive format and boot-loaded code-objects won't have `native-fn` set. We need a zone registry that maps `(file-stem . co-name)` to a zone function, and the archive loader populates each code-object's `native-fn` from it.

**Outcome:** Zone files register themselves in a new CL-side hash `*archive-zone-fns*`; archive loaders look up each code-object's zone fn and attach it to `code-object-native-fn`.

### Task C1: Add `*archive-zone-fns*` registry

**Files:**
- Modify: `src/runtime.lisp` (near existing `*compiled-zone-functions*` defvar around line 1603)

- [ ] **Step 1: Add defvar**

After `(defvar *compiled-zone-functions* ...)`:

```lisp
(defvar *archive-zone-fns* (make-hash-table :test #'equal)
  "Registry mapping (file-stem . co-name-or-index) keys to zone defuns
emitted by generate-zone-cl-for-code-object!. Archive loaders look up
each code-object's zone fn here and populate code-object-native-fn at
load time. Legacy *compiled-zone-functions* (symbol-keyed on space-id)
is kept during coexistence.")
```

- [ ] **Step 2: Update `emit-zone-registration` to accept a cons key**

In `src/codegen-cl-inline.scm` around line 150 find `emit-zone-registration`. It currently writes:

```scheme
(cl:setf (cl:gethash ...) (cl:function zone-...))
```

Add a parallel emission path for code-object mode. Simplest: change `generate-zone-cl-for-code-object!` to pass a second key-form arg to `emit-zone-defun`/`emit-zone-defun-split`.

Refactor `emit-zone-registration` to:

```scheme
(define (emit-zone-registration out name-str reg-key-form)
  "Emit the load-time effect that registers this zone. REG-KEY-FORM is the
CL source string for the hash-key expression; the target hash depends on
whether we're registering for a space (*compiled-zone-functions*, symbol
keyed) or an archive code-object (*archive-zone-fns*, cons keyed)."
  (write-string ";;; Self-registration: install zone-" out)
  (write-string name-str out)
  (newline out)
  (write-string "(cl:setf (cl:gethash " out)
  (write-string reg-key-form out)
  (write-string " *archive-zone-fns*)" out)
  (newline out)
  (write-string "         (cl:function zone-" out)
  (write-string name-str out)
  (write-string "))" out) (newline out))
```

Wait — this kills the space path. Keep a second variant:

```scheme
(define (emit-zone-registration-for-space out name-str space-id)
  "Legacy: register under *compiled-zone-functions* keyed on space-id symbol."
  (write-string "(cl:setf (cl:gethash " out)
  (write-cl-quoted-ece-symbol out space-id)
  (write-string " *compiled-zone-functions*)" out) (newline out)
  (write-string "         (cl:function zone-" out)
  (write-string name-str out)
  (write-string "))" out) (newline out))

(define (emit-zone-registration-for-co out name-str file-stem co-key)
  "New: register under *archive-zone-fns* keyed on (file-stem . co-key)."
  (write-string "(cl:setf (cl:gethash (cl:cons " out)
  (write-string "(cl:intern \"" out) (write-string file-stem out) (write-string "\" :ece)" out)
  (write-string " " out)
  (if (symbol? co-key)
      (begin (write-cl-quoted-ece-symbol out co-key))
      (write-string (number->string co-key) out))
  (write-string ")" out)
  (write-string " *archive-zone-fns*)" out) (newline out)
  (write-string "         (cl:function zone-" out)
  (write-string name-str out)
  (write-string "))" out) (newline out))
```

Callers (`emit-zone-defun`, `emit-zone-defun-split`) still call `emit-zone-registration` — rename that old call-site to `emit-zone-registration-for-space` (since the existing path is space-keyed). Add a separate argument to the code-object emission so it calls `emit-zone-registration-for-co`.

Simplest way to avoid churn: keep `emit-zone-registration` as a dispatcher and plumb through whether we're in space mode or co mode. See the detail in Step 3 below.

- [ ] **Step 3: Thread the mode through the emitter**

Mutate `emit-zone-defun` signature to accept a `reg-mode` list:

```scheme
(define (emit-zone-defun out zone-name src count reg-mode)
  ;; ... (unchanged body) ...
  (case (car reg-mode)
    ((space) (emit-zone-registration-for-space out zone-name (cadr reg-mode)))
    ((co) (emit-zone-registration-for-co
           out zone-name (cadr reg-mode) (caddr reg-mode)))))
```

And similarly `emit-zone-defun-split`. Both `generate-zone-cl!` (legacy) and `generate-zone-cl-for-code-object!` compute the appropriate `reg-mode`:

- Legacy: `(list 'space space-id)` — `space-id` is the symbol.
- Code-object: `(list 'co file-stem co-key)` — `co-key` is the name (symbol) or integer index.

Update `generate-zone-cl-for-code-object!`:

```scheme
(define (generate-zone-cl-for-code-object! co zone-name output-path
                                           file-stem co-key)
  ;; ...
  (if (needs-splitting? count)
      (emit-zone-defun-split out zone-name co count
                             (list 'co file-stem co-key))
      (emit-zone-defun out zone-name co count
                       (list 'co file-stem co-key))))
```

And update the single-file test from Task B2 to pass `file-stem` and `co-key`.

- [ ] **Step 4: Verify bootstrap zones still emit correctly (legacy path)**

```bash
make bootstrap 2>&1 | tail -5
git diff bootstrap/*-zone.lisp
```

Expected: zone files unchanged (legacy path took the `space` branch).

- [ ] **Step 5: Verify generate-all-zones-from-archive! emits correct registration**

Repeat the Task B3 Step 2 smoke test. Look at one generated file:

```bash
grep -A 2 "^;;; Self-registration" /tmp/claude/fixture-zones/boot-env-%init-zone.lisp
```

Expected: registration line targets `*archive-zone-fns*` with a `(cl:cons ... )` key.

- [ ] **Step 6: Commit**

```bash
git add src/codegen-cl-inline.scm src/runtime.lisp tests/ece/cl-only/test-codegen-code-object.scm
git commit -m "$(cat <<'EOF'
§12.1: code-object zone registration via *archive-zone-fns*

Zone files for archive code-objects register under *archive-zone-fns*
(cons-keyed on file-stem + co-name). Legacy space-keyed registration
keeps targeting *compiled-zone-functions*. Emitter threads a reg-mode
argument through emit-zone-defun / emit-zone-defun-split so both paths
share the instruction-emission code.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task C2: Archive loader attaches `native-fn` at load time

**Files:**
- Modify: `src/runtime.lisp` (`load-ecec-archive-section` from Task A3)

- [ ] **Step 1: Update `load-ecec-archive-section` to populate native-fn**

Replace the existing body with:

```lisp
(defun load-ecec-archive-section (archive)
  "Archive-format dispatch. After parsing, look up each code-object's
zone fn in *archive-zone-fns* and populate code-object-native-fn so
the executor's fast-path dispatch fires."
  (let* ((canonicalized (downcase-ece-symbols
                          (canonicalize-ecec-constants archive)))
         (cos (parse-archive-sexp canonicalized))
         (file-str (archive-plist-get (cdr canonicalized) '|file|))
         (file-stem (when file-str
                      (let ((dot (position #\. file-str :from-end t)))
                        (intern (if dot (subseq file-str 0 dot) file-str)
                                :ece)))))
    ;; Populate native-fn on each code-object (if a zone is registered).
    (when file-stem
      (dotimes (i (length cos))
        (let* ((co (aref cos i))
               (co-key (or (code-object-name co) i))
               (zone-fn (gethash (cons file-stem co-key) *archive-zone-fns*)))
          (when zone-fn
            (setf (code-object-native-fn co) zone-fn)))))
    (let ((init (aref cos 0)))
      (execute-instructions init 0 *global-env*))))
```

- [ ] **Step 2: Run tests**

```bash
make bootstrap 2>&1 | tail -3  # ensures runtime.lisp compiles
make test-ece 2>&1 | tail -3
```

Expected: 717+ pass, 0 fail.

- [ ] **Step 3: Commit**

```bash
git add src/runtime.lisp
git commit -m "$(cat <<'EOF'
§12.1: archive loader attaches native-fn from *archive-zone-fns*

At archive load time, look up each code-object's zone fn (keyed on
(file-stem . co-name)) and set code-object-native-fn. After Phase D,
maybe-dispatch-compiled-zone already reads this slot, so bootstrap
code continues running natively once zones regenerate.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase D — Switch `compile-system` to Archive Format (§9.2)

**Why:** The main event. Flips the bootstrap format. Two-pass rebuild: pass 1 uses old `bootstrap.ecec` + updated `compile-system` + updated codegen to produce new-format `bootstrap.ecec` + per-code-object zones; pass 2 validates the new format loads and dispatches zones correctly.

### Task D1: Flip `compile-system` to call `compile-file-to-archive`

**Files:**
- Modify: `src/compilation-unit.scm` (around line 234, `compile-system`)

- [ ] **Step 1: Replace body**

```scheme
(define (compile-system filenames output-path)
  "Compile a list of .scm FILENAMES into a single .ecec archive bundle at
OUTPUT-PATH. Each file is compiled to a code-object archive (§8 format);
the bundle is the concatenation of those archives. Loaders iterate
sections via load-section-from-port."
  (let ((out (open-output-file output-path)))
    (let loop ((files filenames))
      (when (pair? files)
        (compile-file-to-archive (car files) out)
        (loop (cdr files))))
    (close-output-port out)
    output-path))
```

- [ ] **Step 2: Two-pass bootstrap**

Pass 1 — OLD bootstrap loads, NEW compile-system runs, emits NEW bootstrap.ecec:

```bash
make bootstrap 2>&1 | tail -10
```

Expected: "Bootstrap bundle regenerated" line, followed by "Generated all compiled zones". The zones regenerated are still space-keyed (because the running image is still old-format). We'll fix that in D2.

Pass 2 — NEW bootstrap.ecec loads via archive path:

```bash
ASDF_OUTPUT_TRANSLATIONS='(:output-translations ("'$PWD'/" "'$PWD'/.fasl-cache/") :inherit-configuration)' \
  qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --eval '(format t "loaded cleanly~%")' \
  --quit 2>&1 | tail -5
```

Expected: `loaded cleanly`. If it errors with an unknown variable or missing primitive, the archive parser (A2) is missing a plist key; investigate.

- [ ] **Step 3: Run tests**

```bash
make test-ece 2>&1 | tail -3
```

Expected: 717 collected / 0 failed. If tests fail, likely causes:
- Zone dispatch mismatch (zones still built from old-format spaces, PCs now different). Fix in D2.
- Archive loader didn't set a metadata field the test reads. Add it.

If performance drops noticeably (tests take >2 min), it's the zone mismatch — expected; D2 fixes it.

- [ ] **Step 4: Commit**

```bash
git add src/compilation-unit.scm bootstrap/bootstrap.ecec bootstrap/*-zone.lisp openspec/changes/per-procedure-code-objects/tasks.md
# (don't forget to flip the §9.2 checkbox in tasks.md)
git commit -m "$(cat <<'EOF'
§9.2: compile-system emits .ecec archive format

Switches the bootstrap compilation path to produce code-object archives
instead of multi-space headers. bootstrap.ecec regenerated. CL-side
boot loader detects the new format via load-ecec-section's dual
dispatch (Task A3).

Zones still space-keyed in this commit — D2 regenerates them via the
archive-driven codegen so native-fn dispatch works under the new format.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task D2: Switch the Makefile zone target to archive-driven codegen

**Files:**
- Modify: `Makefile` (zone sentinel recipe around line 269)

- [ ] **Step 1: Update the recipe**

Replace the `$(ZONE_SENTINEL)` recipe body (`generate-all-zones!` → `generate-all-zones-from-archive!`):

Find:
```
  --eval '(ece:evaluate (list (intern "generate-all-zones!" :ece) "$(BOOTSTRAP_DIR)"))' \
```

Replace with:
```
  --eval '(ece:evaluate (list (intern "generate-all-zones-from-archive!" :ece) "$(BOOTSTRAP_DIR)/bootstrap.ecec" "$(BOOTSTRAP_DIR)"))' \
```

- [ ] **Step 2: Clean & regenerate**

```bash
rm -f bootstrap/*-zone.lisp .fasl-cache/bootstrap/*-zone.fasl
make bootstrap 2>&1 | tail -15
```

Expected: many more `Generating bootstrap/<name>-zone.lisp (N PCs)...` lines, one per code-object in bootstrap.ecec (dozens, not 7).

- [ ] **Step 3: Verify boot + tests**

```bash
ASDF_OUTPUT_TRANSLATIONS='(:output-translations ("'$PWD'/" "'$PWD'/.fasl-cache/") :inherit-configuration)' \
  qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --eval '(format t "loaded with N zone files~%")' \
  --quit 2>&1 | tail -5
```

Expected: `loaded with N zone files`. Then:

```bash
make test-ece 2>&1 | tail -3
```

Expected: 717+ pass. Speed should be comparable to pre-change.

If tests fail or boot fails: most likely the zone fn's signature doesn't match what `maybe-dispatch-compiled-zone` calls. Look at `src/runtime.lisp:1324` for the dispatch call; the fn should accept `pc val env proc argl continue stack` and return 7 multiple values.

- [ ] **Step 4: Commit**

```bash
git add Makefile bootstrap/*-zone.lisp
git commit -m "$(cat <<'EOF'
§12.2: Makefile zone sentinel uses archive-driven codegen

Switches generate-all-zones! → generate-all-zones-from-archive!. Now
each code-object in bootstrap.ecec gets its own zone file, registered
under *archive-zone-fns* with a (file-stem . co-name) key that the
archive loader populates into code-object-native-fn.

Bootstrap runs natively across all nested lambdas in addition to
top-level inits (prior scheme only accelerated top-level per-space).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task D3: Verify no legacy `.ecec` files remain

- [ ] **Step 1: Search tree for legacy format files**

```bash
find . -name '*.ecec' -not -path './.qlot/*' -not -path './.fasl-cache/*' | while read f; do
  head -c 20 "$f" | grep -q '(ecec-archive' && echo "ARCHIVE: $f" || echo "LEGACY: $f"
done
```

Expected: `ARCHIVE: ./bootstrap/bootstrap.ecec`, no `LEGACY` lines. If `share/ece/ece-main.ecec` exists, verify it's archive format too (the Makefile `ece-main.ecec` target runs `compile-system`, so it should be).

- [ ] **Step 2: Regenerate `share/ece/ece-main.ecec` if stale**

```bash
rm -f share/ece/ece-main.ecec
make share/ece/ece-main.ecec 2>&1 | tail -3
```

- [ ] **Step 3: Flip §9.2 checkbox — should already have been done in D1. Verify:**

```bash
grep -n "9.2" openspec/changes/per-procedure-code-objects/tasks.md
```

Expected: `- [x] 9.2 ...`.

---

## Phase E — Remove Old-Format Compatibility Shim (§9.3)

### Task E1: Delete legacy branches from loaders

**Files:**
- Modify: `src/runtime.lisp` (`load-ecec-section` + `load-ecec-legacy-section`)
- Modify: `src/compilation-unit.scm` (`load-section-from-port` + `load-legacy-section-from-port`)

- [ ] **Step 1: Collapse CL-side loader**

In `src/runtime.lisp`, replace `load-ecec-section` with:

```lisp
(defun load-ecec-section (stream &key skip)
  "Load one archive section. SKIP is retained for Makefile API compat
(skips sections whose archive file field matches) but is rarely used."
  (let* ((*package* (find-package :ece))
         (*readtable* *ecec-readtable*)
         (raw-head (cl:read stream nil :eof)))
    (when (eq raw-head :eof) (return-from load-ecec-section nil))
    (let ((head (downcase-ece-symbols raw-head)))
      (unless (and (consp head) (eq (car head) '|ecec-archive|))
        (error 'ece-runtime-error
               :procedure nil :arguments nil :environment *global-env*
               :instruction nil :backtrace nil
               :original-error
               (make-condition 'simple-error
                               :format-control "load-ecec-section: expected (ecec-archive ...), got ~A. Run `make bootstrap` to regenerate."
                               :format-arguments (list (if (consp head) (car head) head)))))
      (let ((file (archive-plist-get (cdr head) '|file|)))
        (when (and skip (member file skip :test #'string=))
          (return-from load-ecec-section t)))
      (load-ecec-archive-section head))
    t))
```

Delete `load-ecec-legacy-section`.

- [ ] **Step 2: Collapse ECE-side loader**

In `src/compilation-unit.scm`, replace `load-section-from-port` with:

```scheme
(define (load-section-from-port port)
  "Load one archive section. Returns eof if no more sections."
  (let ((head (ece-scheme-read port)))
    (cond
     ((eof? head) head)
     ((and (pair? head) (eq? (car head) 'ecec-archive))
      (load-archive-section-form head))
     (else
      (error "load-section-from-port: expected (ecec-archive ...). Run `make bootstrap` to regenerate.")))))
```

Delete `load-legacy-section-from-port`.

- [ ] **Step 3: Rebuild and test**

```bash
make bootstrap 2>&1 | tail -3
make test-ece 2>&1 | tail -3
```

Expected: all green.

- [ ] **Step 4: Commit**

```bash
git add src/runtime.lisp src/compilation-unit.scm openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "$(cat <<'EOF'
§9.3: remove old-format .ecec compatibility shim

Loaders now require (ecec-archive ...). The header-based legacy branch
is deleted from both load-ecec-section (CL) and load-section-from-port
(ECE). Error message points at `make bootstrap` for stale files.

All .ecec files under bootstrap/ and share/ece/ are archive format
after Phase D; nothing should hit the legacy branch.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase F — Retire `%space-*` Primitives and `compilation-space` (§9.4 + §11)

### Task F1: Survey remaining callers

- [ ] **Step 1: Find every non-codegen `%space-*` call**

```bash
grep -rn "%space-\|%current-space\|%create-space\|%set-current-space-id" \
  --include='*.scm' --include='*.lisp' --include='*.wat' \
  | grep -v codegen-cl-inline.scm | grep -v 'primitives\.scm' | grep -v 'boot-env\.scm'
```

Expected: few hits. Any remaining call sites need removal.

Likely candidates:
- `src/compiler.scm`: `mc-compile-and-go` and friends use the space path. Since archive is now the default, check whether any still-live code calls these.
- `src/disassemble.scm`: the reachability walk.
- `src/assembler.scm`: `assemble-into-global` shim.
- `src/runtime.lisp`: `assemble-into-space`, `create-space`, `get-space`, `*space-registry*`, `*current-space-id*`.

- [ ] **Step 2: For each hit, either remove the caller or convert it to the code-object API**

This is exploratory — file-by-file. Commit per file with a message like `§11: retire %space-* in <file>`.

- [ ] **Step 3: Full test run after each chunk**

```bash
make test-ece 2>&1 | tail -3
```

### Task F2: Rename executor locals (§6.2)

**Files:**
- Modify: `src/runtime.lisp` (`execute-instructions`, `switch-space`)

**Context:** `execute-instructions` maintains a local named `space-id` that currently holds either a symbol (legacy space-id) or a code-object. Every dispatch site has an `(if (code-object-p ...))` branch to pick the right source for `instrs`/`ltab`. After F1/F3/F4 retire the symbol path, the branches become dead code.

- [ ] **Step 1: Rename `space-id` local to `code-obj` throughout `execute-instructions`**

Use a global search-and-replace inside that defun. Verify no other function in `src/runtime.lisp` references a lexical `space-id` — the registry, if it still existed, would use the same name but it's been removed in F4.

- [ ] **Step 2: Rename `switch-space` → `switch-code-object`**

Rename the function and inline callers. Remove the `get-space` lookup. Dispatch is now pure field access.

- [ ] **Step 3: Test**

```bash
make test-ece 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add src/runtime.lisp
git commit -m "$(cat <<'EOF'
§6.2: rename switch-space → switch-code-object; drop get-space

Code-objects are the only dispatch target now. Executor local renamed
space-id → code-obj; get-space and its hash lookup retire.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task F3: Delete `%space-*` primitive definitions

**Files:**
- Modify: `src/primitives.scm` — remove `%space-*` define-host-primitive forms
- Modify: `src/boot-env.scm` — remove their register! calls
- Modify: `primitives.def` — remove their entries (keep ids reserved; don't reuse)
- Modify: `bootstrap/primitives-auto.lisp` — regenerate via `make bootstrap/primitives-auto.lisp`

- [ ] **Step 1: Identify primitive names**

```bash
grep -n "%space-source-ref\|%space-instruction-length\|%space-label-entries\|%space-label-ref\|%space-name\|%space-instruction-push!\|%space-label-set!\|%space-count\|%create-space\|%current-space-id\|%set-current-space-id!" primitives.def
```

Record the ids.

- [ ] **Step 2: Delete from primitives.def, primitives.scm, boot-env.scm**

Comment out rather than delete the entries in `primitives.def` so ids stay reserved (matches project convention on retired primitives).

- [ ] **Step 3: Regenerate primitives-auto.lisp**

```bash
rm -f bootstrap/primitives-auto.lisp
make bootstrap/primitives-auto.lisp 2>&1 | tail -3
```

- [ ] **Step 4: Full bootstrap + test**

```bash
make bootstrap 2>&1 | tail -5
make test-ece 2>&1 | tail -3
```

Expected: green.

- [ ] **Step 5: Commit**

```bash
git add primitives.def src/primitives.scm src/boot-env.scm bootstrap/primitives-auto.lisp bootstrap/*-zone.lisp bootstrap/bootstrap.ecec openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "$(cat <<'EOF'
§9.4 + §11.1: retire %space-* primitives

Removes all %space-source-ref, %space-instruction-length,
%space-label-entries, %space-label-ref, %space-name,
%space-instruction-push!, %space-label-set!, %space-count,
%create-space, %current-space-id, %set-current-space-id! from the
kernel. Ids stay reserved (commented in primitives.def).

Bootstrap regenerated; zones regenerated; all tests pass.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task F4: Retire `*space-registry*` and `compilation-space` struct (§11.3 + §11.4)

**Files:**
- Modify: `src/runtime.lisp`

- [ ] **Step 1: Find & remove references**

```bash
grep -n "\*space-registry\*\|compilation-space\|create-space\|get-space" src/runtime.lisp
```

Any caller still alive must be converted or deleted. After F2 the executor doesn't reference them.

- [ ] **Step 2: Delete defstruct, defvars, helper defuns**

Remove:
- `(defstruct compilation-space ...)`
- `(defvar *space-registry* ...)`
- `(defvar *current-space-id* ...)` — but check if anything still writes to it first.
- `(defun create-space ...)`, `(defun get-space ...)`
- `(defun assemble-into-space ...)` — this is the last legacy assembler path.

- [ ] **Step 3: Rebuild + test**

```bash
make bootstrap 2>&1 | tail -3
make test-ece 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add src/runtime.lisp bootstrap/bootstrap.ecec bootstrap/*-zone.lisp openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "$(cat <<'EOF'
§11.3 + §11.4: retire *space-registry* and compilation-space struct

The executor, assembler, and loader no longer reference the space
registry. Deletes the defstruct, defvars, create-space, get-space,
assemble-into-space.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Task F5: WASM parity (§6.6 cleanup + §11 WASM)

**Files:**
- Modify: `wasm/runtime.wat`

- [ ] **Step 1: Find legacy space references in WAT**

```bash
grep -n "space-id\|space-registry\|current-space" wasm/runtime.wat | head -30
```

- [ ] **Step 2: Rename `$current-space-id` → `$current-code-obj`; drop `$switch-space`; remove `get-space` equivalent**

The §6.6 note in tasks.md deferred these. Now is the time. Keep `$code-object` struct type.

- [ ] **Step 3: Rebuild WASM and test**

```bash
make wasm 2>&1 | tail -3
make test-wasm 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add wasm/runtime.wat wasm/runtime.wasm
git commit -m "$(cat <<'EOF'
§6.6 cleanup + §11: retire $current-space-id in WASM runtime

Matches the CL-side cleanup (F2/F4). WASM executor dispatch is now
solely code-object-based; get-space equivalent removed.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase G — Assembler + Compiler Cleanup

### Task G1: Retire `assemble-into-global` shim (§5.2)

**Files:**
- Modify: `src/assembler.scm`

- [ ] **Step 1: Find callers**

```bash
grep -rn "assemble-into-global" --include='*.scm' --include='*.lisp'
```

- [ ] **Step 2: Replace callers with `assemble-into-code-object` + a fresh code-object**

- [ ] **Step 3: Delete the shim**

- [ ] **Step 4: Rebuild + test**

- [ ] **Step 5: Commit**

```bash
git add src/assembler.scm bootstrap/bootstrap.ecec bootstrap/*-zone.lisp openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "§5.2: retire assemble-into-global — assemble-into-code-object is the only entry

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task G2: Retire `%procedure-name-*` side tables (§11.2)

**Files:**
- Modify: `src/primitives.scm` — remove `%procedure-name-ref`, `%procedure-name-set!` definitions
- Modify: `src/boot-env.scm` — remove their register! calls
- Modify: `primitives.def` — comment out their rows (ids stay reserved)
- Modify: `src/runtime.lisp` — remove `*procedure-name-table*` + `*procedure-params-table*` defvars; update any direct readers to go through `code-object-name` / `code-object-arity`

- [ ] **Step 1: Survey callers**

```bash
grep -rn "procedure-name-table\|procedure-params-table\|%procedure-name-ref\|%procedure-name-set!" \
  --include='*.scm' --include='*.lisp' --include='*.wat'
```

Likely hits: `src/compiler.scm` (sets names during compile), `src/runtime.lisp` (reads for format-ece-proc error paths), WASM runtime.

- [ ] **Step 2: For each reader, route through `code-object-name`**

In `src/runtime.lisp`, `format-ece-proc` already reads `code-object-name` for code-object closures (per §7.4 note in tasks.md). Check for any remaining `*procedure-name-table*` access and delete.

- [ ] **Step 3: Remove defvars + primitive definitions + registrations**

Delete `(defvar *procedure-name-table* ...)` and `(defvar *procedure-params-table* ...)` from `src/runtime.lisp`. Delete define-host-primitive entries in `src/primitives.scm`. Delete register! calls in `src/boot-env.scm`. Comment the rows in `primitives.def`.

- [ ] **Step 4: Regenerate primitives-auto.lisp + bootstrap + test**

```bash
rm -f bootstrap/primitives-auto.lisp
make bootstrap/primitives-auto.lisp 2>&1 | tail -3
make bootstrap 2>&1 | tail -3
make test-ece 2>&1 | tail -3
```

Expected: green.

- [ ] **Step 5: Commit**

```bash
git add primitives.def src/primitives.scm src/boot-env.scm src/runtime.lisp bootstrap/primitives-auto.lisp bootstrap/bootstrap.ecec bootstrap/*-zone.lisp openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "$(cat <<'EOF'
§11.2: retire %procedure-name-* side tables

Names and arity now live on code-object structs. *procedure-name-table*
and *procedure-params-table* delete; their primitive accessors retire
(ids stay reserved in primitives.def).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase H — Disassemble Cleanup (§10.2 + §10.5)

### Task H1: Delete reachability walk

**Files:**
- Modify: `src/disassemble.scm`

- [ ] **Step 1: Delete dead helpers**

`dis/reached-pcs`, `dis/labels-at`, `dis/unreached-labels-in-span`, `dis/successors`, `dis/branch-target-pc` all retire.

- [ ] **Step 2: Verify `disassemble` tests still pass**

```bash
make test-ece 2>&1 | grep -E "disassemble|Total:"
```

- [ ] **Step 3: Commit**

```bash
git add src/disassemble.scm openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "§10.2: delete reachability walk from disassemble

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task H2: Visual sanity check for `disassemble` on `square` (§10.5)

- [ ] **Step 1: Invoke disassemble**

```bash
qlot exec sbcl --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --eval '(ece:evaluate (list (quote define) (quote square) (list (quote lambda) (list (quote x)) (list (quote *) (quote x) (quote x)))))' \
  --eval '(ece:evaluate (list (quote disassemble) (quote square)))' \
  --quit 2>&1 | tail -50
```

Expected: header + instruction lines. Should be shorter than pre-change (no "unreached labels" padding).

- [ ] **Step 2: Flip §10.5 checkbox in tasks.md and commit**

---

## Phase I — Broader Test Coverage (§13)

### Task I1: Add `tests/ece/cl-only/test-code-objects.scm` (§13.1)

**Files:**
- Create: `tests/ece/cl-only/test-code-objects.scm`

- [ ] **Step 1: Write coverage tests**

```scheme
;;; Spec scenarios from code-object-compilation.

(test "code-object? on compile result" (lambda ()
  (assert-true (code-object? (mc-compile-to-code-object 42)))))

(test "code-object? on non-code-object returns #f" (lambda ()
  (assert-equal #f (code-object? 42))
  (assert-equal #f (code-object? "foo"))
  (assert-equal #f (code-object? (lambda (x) x)))
  (assert-equal #f (code-object? '(a b)))))

(test "compile returns fresh object each call" (lambda ()
  (define a (mc-compile-to-code-object '(lambda (x) x)))
  (define b (mc-compile-to-code-object '(lambda (x) x)))
  (assert-equal #f (eq? a b))
  (assert-true (eq? a a))))

(test "code-object-length positive for lambda" (lambda ()
  (define co (mc-compile-to-code-object '(lambda (x) (* x x))))
  (assert-true (> (code-object-length co) 0))))

(test "code-object-label-entries is a list of pairs" (lambda ()
  (define co (mc-compile-to-code-object '(if #t 1 2)))
  (define entries (code-object-label-entries co))
  (when (pair? entries)
    (assert-true (pair? (car entries))))))

(test "code-object-name set for define" (lambda ()
  (define co (mc-compile-to-code-object '(define (my-fn x) x)))
  ;; Top-level init has name %init; inner lambda (the defined fn) has name my-fn.
  ;; Walk the reachable code-objects and look for one named my-fn.
  (let ((all (archive/collect-reachable co)))
    (let loop ((xs all) (found #f))
      (cond
       ((null? xs) (assert-true found))
       ((eq? 'my-fn (code-object-name (car xs))) (loop (cdr xs) #t))
       (else (loop (cdr xs) found)))))))

(test "code-object-name #f for anonymous lambda" (lambda ()
  (define co (mc-compile-to-code-object '((lambda (x) x) 1)))
  (let ((all (archive/collect-reachable co)))
    (let loop ((xs all))
      (cond
       ((null? xs) #t)
       ((and (not (eq? (car xs) co))
             (eq? #f (code-object-name (car xs))))
        (assert-equal #f (code-object-name (car xs))))
       (else (loop (cdr xs))))))))

(test "code-object-native-fn defaults to #f" (lambda ()
  (define co (mc-compile-to-code-object '(+ 1 1)))
  (assert-equal #f (code-object-native-fn co))))

(test "nested lambdas: inner referenced as constant" (lambda ()
  (define outer (mc-compile-to-code-object '(lambda (x) (lambda (y) (+ x y)))))
  (define all (archive/collect-reachable outer))
  (assert-true (>= (length all) 3))
  (assert-true (eq? (car all) outer))))
```

- [ ] **Step 2: Run**

```bash
make test-ece 2>&1 | grep -E "test-code-objects|Total:"
```

Expected: new file reports >=8 tests, all pass.

- [ ] **Step 3: Commit**

```bash
git add tests/ece/cl-only/test-code-objects.scm openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "§13.1: add test-code-objects.scm covering code-object-compilation spec

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task I1b: File round-trip archive test (§13.3)

**Files:**
- Modify: `tests/ece/cl-only/test-archive-format.scm` (append)

- [ ] **Step 1: Append a file-round-trip test**

```scheme
(test "archive: file round-trip — compile→write→load→invoke" (lambda ()
  ;; Write a tiny .scm, compile it via compile-file-archive, load via
  ;; load-archive, call the defined procedure, compare to direct eval.
  (define scm-path "/tmp/claude/rt-src.scm")
  (define ecec-path "/tmp/claude/rt-src.ecec")
  (define out (open-output-file scm-path))
  (display "(define (triple x) (* x 3))" out)
  (newline out)
  (close-output-port out)
  (compile-file-archive scm-path)
  ;; compile-file-archive writes to <stem>.ecec next to source; move it.
  (rename-file "/tmp/claude/rt-src.ecec" ecec-path)
  (load-archive ecec-path)
  (assert-equal 21 (triple 7))))
```

- [ ] **Step 2: Run**

```bash
make test-ece 2>&1 | grep -E "archive: file round-trip|Total:"
```

Expected: test passes.

- [ ] **Step 3: Commit**

```bash
git add tests/ece/cl-only/test-archive-format.scm openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "§13.3: archive file round-trip test — write .ecec, load, invoke

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task I1c: Confirm §13.2 already covered

**Context:** §13.2 asks for end-to-end `(disassemble (compile '(lambda (x) (+ x 1))))` coverage. Per the §10.4 note in `tasks.md`, `tests/ece/cl-only/test-compile-to-code-object.scm` already has two such tests. Flip the §13.2 checkbox with a note:

- [ ] **Step 1: Edit tasks.md**

Change:
```
- [ ] 13.2 Add end-to-end compilation tests: ...
```
to:
```
- [x] 13.2 Add end-to-end compilation tests: ...
      *Already covered by `test-compile-to-code-object.scm` (disassemble on a code-object; disassemble on inner code-object of a defined procedure), per the §10.4 note.*
```

- [ ] **Step 2: Commit**

```bash
git add openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "§13.2: note existing disassemble-on-code-object coverage

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task I2: Run all test suites (§13.4)

- [ ] **Step 1: `make test`**

```bash
make test 2>&1 | tail -50
```

Expected: all suites (`test-rove`, `test-ece`, `test-wasm`, `test-conformance`, `test-golden`, `test-web-server`, `test-web-apps`) report 0 failures. This is the PR gate.

- [ ] **Step 2: If any suite fails, investigate and fix. Don't proceed to Phase J until green.**

### Task I3: Benchmarks (§13.5, §13.6)

Skip: defer to post-merge if time is tight. Note in tasks.md:

```markdown
      *Deferred: benchmarks were not run as part of the finishing plan. Self-recursion and higher-order unchanged; mutual recursion is worth measuring in a follow-up.*
```

---

## Phase J — Documentation (§14)

### Task J1: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Find existing "Architecture: Compiler & .ecec Boot" section**

```bash
grep -n "## Architecture: Compiler\|## Browser Port" CLAUDE.md
```

- [ ] **Step 2: Rewrite the section to describe code-object model**

Replace the "Compilation spaces" language with code-object language. Key points:
- `.ecec` is a code-object archive
- Each code-object has instructions, labels, name, arity, source-loc, native-fn
- Executor tracks current code-object; dispatch is field access, no hash lookup
- `disassemble` accepts code-objects directly

- [ ] **Step 3: Update "Browser Port: Compile-to-Host Strategy" to note native-fn is per-code-object**

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md openspec/changes/per-procedure-code-objects/tasks.md
git commit -m "§14.1 + §14.2: update CLAUDE.md for code-object model

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task J2: Update roadmap + add archive format doc (§14.3, §14.4)

- [ ] **Step 1: Update `openspec/roadmap-if.md` if it references per-space assumptions**

```bash
grep -n "space\|compilation-space" openspec/roadmap-if.md
```

- [ ] **Step 2: Add a short archive-format README at `bootstrap/README.md`** or an OpenSpec note documenting the new `.ecec` format.

- [ ] **Step 3: Commit**

---

## Phase K — Review + PR (§15)

### Task K1: Code-reviewer subagent pass (§15.1)

- [ ] **Step 1: Dispatch code-reviewer**

```
Agent(
  description: "Code review per-procedure-code-objects finish",
  subagent_type: "code-reviewer",
  prompt: "Review the commits on branch per-procedure-code-objects since the merge-base with main. Focus: code-object dispatch correctness, archive format round-trip, zone codegen output quality, dropped %space-* call sites. Report: (1) any correctness bugs, (2) any leaked legacy references, (3) readability concerns."
)
```

- [ ] **Step 2: Address findings**

### Task K2: Self-review walk (§15.2)

- [ ] **Step 1: Contract audit**

For each spec scenario in `openspec/changes/per-procedure-code-objects/specs/*/spec.md`, identify the test that covers it. Missing coverage → add a test.

- [ ] **Step 2: Edge-case brainstorm**

Think through: REPL redefinition (does the old code-object become GC'd?); `eq?` on separately-compiled same source; `disassemble` on anonymous lambda; archive files with zero entries; archive files referencing out-of-range co-refs.

Add tests for anything not already covered.

### Task K3: Final `make test` (§15.3)

```bash
make test 2>&1 | tail -20
```

Expected: zero failures across all suites.

### Task K4: Push + PR (§15.4)

- [ ] **Step 1: Push branch**

```bash
git push -u origin per-procedure-code-objects
```

- [ ] **Step 2: Open PR**

```bash
gh pr create --title "per-procedure-code-objects: code-object value type + archive format" --body "$(cat <<'EOF'
## Summary

- First-class `code-object` values: instructions, labels, name, arity, source-loc, native-fn
- Compiler returns code-objects; nested lambdas compose bottom-up
- `.ecec` switched from multi-space-header format to code-object archive (version 2)
- Executor dispatches by code-object field access (no `get-space` hash lookup)
- `disassemble` reads directly from code-objects; reachability walk retired
- `%space-*` primitives, `*space-registry*`, `compilation-space` struct retired
- Per-code-object zone codegen (one defun per code-object, registered in `*archive-zone-fns*`)
- CL + WASM runtimes updated in lockstep

OpenSpec proposal: `openspec/changes/per-procedure-code-objects/`.

## Test plan

- [ ] `make test` — all suites pass
- [ ] `disassemble square` output is qualitatively smaller than pre-change
- [ ] `test-serialization.scm` continuation-size tests pass
- [ ] CL + WASM boot times are comparable to pre-change
- [ ] Bootstrap is fully two-pass: first pass uses old `bootstrap.ecec` via the compat shim, second pass uses the new archive format with per-code-object zones

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: Archive the OpenSpec change in the same PR**

```bash
/opsx:archive per-procedure-code-objects
```

Commit + push the archive change.

---

## After All Tasks Complete

Use `superpowers:finishing-a-development-branch` per the executing-plans skill integration.

## Notes for the Executor

- **If a rebuild fails with "Unknown label" or "Unbound variable" in the second SBCL invocation** of a two-pass step (D1 especially), the likely cause is stale `.fasl-cache/`. `make clean-fasl` and retry.
- **If zone dispatch lands on the wrong PC** (runtime error with a strange instruction): check that the zone's `reg-mode` used the correct key and that the archive loader's `file-stem` intern matches the key the zone registered under.
- **If the test suite slows down dramatically after D1 but before D2:** expected. D2 (per-code-object zones) restores native dispatch.
- **If a commit's pre-commit hook reformats files,** re-stage the formatted versions and commit again. Do not skip with `--no-verify`.
