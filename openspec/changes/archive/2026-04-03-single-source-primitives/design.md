## Context

ECE's CL runtime maps primitive names to CL functions via two hand-maintained lists:
- `*primitive-procedures*` (~15 entries): direct CL function mappings like `car` → `#'car`
- `*wrapper-primitives*` (~130 entries): ECE-name → CL-wrapper mappings like `null?` → `#'ece-null?`

These lists must contain an entry for every non-`ece` platform primitive in `primitives.def`. A missing entry causes a "no CL implementation" warning at boot but silently fails at runtime. The WASM side already solved this: `scripts/gen-primitives-json.sh` generates `primitives.json` from `primitives.def`.

## Goals / Non-Goals

**Goals:**
- Eliminate `*primitive-procedures*` and `*wrapper-primitives*` as manual sync points
- Auto-resolve CL function names from ECE primitive names via naming convention
- Fail loudly at boot if a required primitive has no CL implementation
- Keep primitives.def as a clean cross-platform manifest (no CL-specific columns)

**Non-Goals:**
- Changing the WASM side (already single-sourced)
- Changing primitives.def format
- Auto-generating the CL wrapper functions themselves (they still need to exist in runtime.lisp)

## Decisions

### 1. Convention-based resolution

**Choice:** Resolve CL functions by trying names in order:
1. `ece-<name>` in the ECE package (covers ~115 wrappers)
2. `<name>` in the CL package (covers `car`, `cdr`, `cons`, `list`, `+`, `-`, `*`, `/`)
3. `<name>` in the ECE package (covers functions like `extend-environment`)

**Why:** ~130 of ~145 entries follow one of these patterns. Only ~15 need explicit overrides. This eliminates the large manually-maintained lists without adding CL-specific columns to the cross-platform manifest.

### 2. Small override table for non-conventional mappings

**Choice:** A single alist `*primitive-cl-overrides*` for the ~15 primitives where the CL function name doesn't follow convention:

```lisp
(defparameter *primitive-cl-overrides*
  '((char->integer . char-code)
    (integer->char . code-char)
    (%raw-error . error)
    (vector-length . length)
    (vector-ref . aref)
    (string-length . length)
    (bitwise-and . logand)
    (bitwise-or . logior)
    (bitwise-xor . logxor)
    (bitwise-not . lognot)
    (arithmetic-shift . ash)
    (set-car! . rplaca)
    (set-cdr! . rplacd)
    (string . string)))
```

**Why:** These CL functions have completely different names from their ECE equivalents. No convention can resolve `char->integer` to `char-code`. A small explicit table is the right tool.

### 3. Resolution function: `resolve-cl-primitive`

**Choice:** A single function that takes an ECE name symbol and returns a CL function (or nil):

```lisp
(defun resolve-cl-primitive (ece-name-sym)
  "Resolve ECE primitive name to CL function via override table or convention."
  (let* ((name-str (string-downcase (symbol-name ece-name-sym)))
         (override (assoc ece-name-sym *primitive-cl-overrides* :test #'string-equal
                          :key #'symbol-name)))
    (cond
      ;; Explicit override
      (override (and (fboundp (cdr override)) (symbol-function (cdr override))))
      ;; Convention 1: ece-<name> in ECE package
      ((let ((sym (find-symbol (concatenate 'string "ECE-" name-str) :ece)))
         (and sym (fboundp sym) (symbol-function sym))))
      ;; Convention 2: <name> in CL package
      ((let ((sym (find-symbol (string-upcase name-str) :cl)))
         (and sym (fboundp sym) (symbol-function sym))))
      ;; Convention 3: <name> in ECE package
      ((let ((sym (find-symbol name-str :ece)))
         (and sym (fboundp sym) (symbol-function sym)))))))
```

**Why:** Single resolution path replaces `build-cl-function-map` + two separate lists. Easy to debug: add a primitive, if it doesn't resolve, either name the wrapper `ece-<name>` or add an override.

### 4. Boot-time validation

**Choice:** During `init-primitive-dispatch-tables`, error (not warn) if a `core` or `cl` platform primitive with arity != `ece` has no resolved CL function.

**Why:** The current behavior warns but continues, leading to runtime crashes later. Failing at boot makes missing implementations immediately visible. `ece`-platform and `browser`-platform primitives are expected to have no CL implementation (they're implemented in ECE or in the browser).

### 5. `build-cl-function-map` removal

**Choice:** Remove `build-cl-function-map`, `*primitive-procedures*`, and `*wrapper-primitives*`. Replace `init-primitive-dispatch-tables` to call `resolve-cl-primitive` for each manifest entry directly.

**Why:** These are the manual sync points. With convention-based resolution, they serve no purpose.

## Risks / Trade-offs

**[Naming convention fragility]** If someone names a CL wrapper `ece-foo` where `foo` is NOT a primitive, false resolution could occur. → Mitigation: resolution only runs for names actually in the manifest. The function must also be `fboundp`.

**[Override table still manual]** The ~15 overrides must stay in sync with primitives.def if those primitives are renamed. → Mitigation: boot-time validation catches any breaks. The override table is small enough to audit by eye.
