## Context

ECE's reader (`src/reader.scm`) currently calls `string-upcase` before interning symbols, inheriting CL's case-folding convention. The CL runtime (`src/runtime.lisp`) mirrors this: `ece-string->symbol` upcases, `ece-symbol->string` downcases. Space creation and primitive loading also upcase names. All `.ecec` bootstrap files contain upcased symbols.

Since ECE source files are written in lowercase (standard Scheme convention), the round-trip is: `hello` → stored as `HELLO` → displayed as `hello`. This works but prevents mixed-case symbols and diverges from R6RS/R7RS.

## Goals / Non-Goals

**Goals:**
- Make the reader case-preserving: `hello` stays `hello`, `MyVar` stays `MyVar`
- Update all CL-side symbol operations to stop case-folding
- Rebuild bootstrap `.ecec` files with lowercase symbols
- Update the ece-reader spec to reflect new behavior

**Non-Goals:**
- Adding `#!fold-case` / `#!no-fold-case` directives (R7RS optional feature — can be added later)
- Changing how ECE keywords (`:foo`) work — they already have their own interning path
- Modifying any `.scm` source files — they're already lowercase

## Decisions

### 1. Case-preserving interning (not lowercase folding)

Symbols are interned exactly as written. No case transformation in either direction. `string->symbol` passes through, `symbol->string` returns `symbol-name` as-is.

**Alternative considered**: Fold to lowercase (R5RS style). Rejected because case-sensitive is the modern default and enables mixed-case identifiers.

### 2. CL package implications

CL's `:ece` package stores symbol names as strings. Currently these are uppercase (`"HELLO"`). After this change they'll be whatever case the source uses (`"hello"`). Since ECE controls all interning via `%intern-ece` and `ece-string->symbol`, CL's own readtable case setting is irrelevant — we bypass it entirely.

**Risk**: Any CL-side code that refers to ECE symbols by literal name (e.g., `'ece::DEFINE`) will break. These references must be updated.

### 3. Bootstrap rebuild strategy

After modifying the reader and runtime, run `make bootstrap` to recompile all `.scm` → `.ecec`. The two-pass bootstrap ensures consistency: pass 1 boots from old `.ecec` (which still works — the runtime changes only affect new interning), pass 2 recompiles with the new reader producing lowercase symbols.

### 4. Primitive loading

`primitives.def` names are read by CL's `read` and then upcased before interning into `:ece`. After this change, we'll intern them as-is (they're already lowercase in the def file). The primitive dispatch table uses numeric IDs, so the name change is cosmetic.

## Risks / Trade-offs

- **[Bootstrap chicken-and-egg]** → The first pass boots from old `.ecec` files with uppercase symbols while the runtime now interns lowercase. This works because pass 1 uses the *old* reader (from `.ecec`) which still upcases. Pass 2 uses the *new* reader (just compiled) which preserves case. The two-pass `make bootstrap` handles this naturally.
- **[CL-side test breakage]** → Tests that reference ECE symbols as uppercase CL symbols will fail. Mitigation: update symbol references in test files.
- **[Third-party code]** → Any external code assuming uppercase ECE symbols will break. Mitigation: ECE has no external consumers yet.
