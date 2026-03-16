## Context

The metacircular compiler (`compiler.scm`) is a line-for-line port of the CL compiler (`compiler.lisp`), but it was ported before lexical addressing was added. The CL compiler (SICP 5.41–5.43) computes `(depth . offset)` addresses for bound variables, emits `lexical-ref`/`lexical-set!` instructions, and creates vector-backed frames via 4-arg `extend-environment`. The MC compiler always uses name-based ops and creates list-based frames via 3-arg `extend-environment`.

The runtime already supports both paths — `lexical-ref`, `lexical-set!`, and the 4-arg `extend-environment` with extra-slots all exist in `runtime.lisp`. This change only modifies `compiler.scm`.

Current MC compiler state:
- `*mc-compile-lexical-env*` is a `(make-parameter '())` — a flat list of names used only for macro shadowing
- `mc-compile-variable` always emits `(op lookup-variable-value)`
- `mc-compile-assignment` always emits `(op set-variable-value!)`
- `mc-compile-define` always emits `(op define-variable!)`
- `mc-compile-lambda-body` emits 3-arg `extend-environment`, no extra-slots
- `mc-extract-define-names` only checks top-level forms (no begin recursion, no macro expansion)

## Goals / Non-Goals

**Goals:**
- MC compiler emits `lexical-ref`/`lexical-set!` for bound variables, identical to CL compiler output
- MC compiler emits 4-arg `extend-environment` with extra-slots for vector frame creation
- Internal defines compile as `lexical-set!` into pre-allocated frame slots
- `mc-extract-define-names` matches CL compiler's depth (recurse into `begin`, expand macros)
- After this change, all ECE-compiled code produces vector frames with O(1) lexical access

**Non-Goals:**
- Removing `compiler.lisp` (separate follow-up change)
- Removing list-based frame code from `runtime.lisp` (separate follow-up)
- Optimizing open-coded primitives or other compiler optimizations
- Changing runtime.lisp — all needed runtime support already exists

## Decisions

### Restructure `*mc-compile-lexical-env*` as a list of frames

Change from a flat name list to a list of frames (each frame a list of variable names), matching the CL compiler's `*compile-lexical-env*`.

Currently: `(x y z a b)` — flat list, only for `(member name env)` macro shadow check.

After: `((x y z) (a b))` — list of frames, where each frame corresponds to a lambda's parameters (+ internal define names).

**Why frames, not flat?** `find-variable` needs to compute `(depth . offset)` — depth is the frame index, offset is the position within a frame. A flat list loses frame boundaries.

### Add `mc-find-variable`

New function that searches the frame-structured env and returns `(depth . offset)` or `#f`:

```scheme
(define (mc-find-variable var env)
  ;; Walk frames, return (depth . offset) or #f
  ...)
```

This is the ECE equivalent of the CL compiler's `find-variable` (line 179 of `compiler.lisp`).

### Add `*mc-compile-macro-shadows*`

New parameter (flat list) for names that shadow macros but don't create lexical frames — i.e., internal defines found in `begin` blocks at the top level. Matches the CL compiler's `*compile-macro-shadows*`.

The macro shadow check in `mc-compile` (line 502) must check both:
1. `mc-find-variable` in the lexical env (lexically bound names)
2. `member` in `*mc-compile-macro-shadows*` (begin-level define names)

### Update compilation functions

**`mc-compile-variable`**: Check `mc-find-variable`. If address found, emit `lexical-ref`. Otherwise emit `lookup-variable-value` (unchanged).

**`mc-compile-assignment`**: Check `mc-find-variable`. If address found, emit `lexical-set!`. Otherwise emit `set-variable-value!` (unchanged).

**`mc-compile-define`**: Check `mc-find-variable`. If address found (internal define), emit `lexical-set!`. Otherwise emit `define-variable!` (top-level define, unchanged).

**`mc-compile-lambda-body`**:
1. Call `mc-extract-define-names` to find internal defines
2. Build frame = `(append param-names define-names)`
3. Compute `extra-slots = (length define-names)`
4. Push frame onto `*mc-compile-lexical-env*` via `parameterize`
5. Emit 4-arg `extend-environment` with `(const extra-slots)`

**`mc-compile-begin`**: Extract define names and add to `*mc-compile-macro-shadows*` (not to lexical env, since begin doesn't create a frame).

### Deep `mc-extract-define-names`

Port the CL compiler's `extract-define-names` logic:
1. If form is `(define ...)`, extract the name
2. If form is `(begin ...)`, recurse into its body
3. If form is `(if ...)`, recurse into consequent and alternative
4. If form is a macro application (not lexically shadowed), expand it and recurse into the expansion
5. Otherwise, skip

This ensures hidden defines (e.g., from `named let` expanding to `(begin (define ...) ...)`) are found and get pre-allocated slots.

### Macro shadow check update

The macro shadow check at application dispatch (line 502) currently does:
```scheme
(member (car expr) (*mc-compile-lexical-env*))
```

This must change to:
```scheme
(mc-lexically-shadows-macro? (car expr))
```

Where `mc-lexically-shadows-macro?` checks both `mc-find-variable` in the frame-structured env and `member` in `*mc-compile-macro-shadows*`.

## Risks / Trade-offs

- **[Risk] Bootstrap circularity** — The image is booted from `compiler.scm`, which compiles itself. If the new compiler produces broken code, it can't compile itself. → **Mitigation**: The CL compiler (`compiler.lisp`) remains available as a bootstrap fallback. Test thoroughly before rebuilding the image.

- **[Risk] `mc-extract-define-names` calls macro expansion** — Deep extraction needs to expand macros to find hidden defines. This is the same approach the CL compiler uses and is well-tested there. The MC compiler's `mc-expand-macro-at-compile-time` already works for this purpose.

- **[Risk] `*mc-compile-lexical-env*` is a `parameterize` parameter** — The flat-to-frames restructuring changes what callers see. Currently `mc-compile-begin` appends names to a flat list; it must instead append to `*mc-compile-macro-shadows*`. `mc-compile-lambda-body` appends names to the flat list; it must instead `cons` a new frame. Both call sites are identified and well-understood.

- **[Trade-off] Two compilers temporarily coexist** — Until `compiler.lisp` is removed, both compilers exist. This is intentional — the CL compiler serves as reference and bootstrap fallback.
