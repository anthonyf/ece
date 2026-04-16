## Context

Day 1 (PR #158) shipped a working Geiser backend: `C-x C-e`, `C-c C-l`, REPL buffer. The completions stub returns an empty list, so `C-M-i` does nothing. ECE's global environment is a hash-frame (`(:hash-frame . <hash-table>)`) — the hash-table keys are interned ECE symbols. There's currently no ECE-callable primitive to enumerate those keys.

Chibi's completions handler (`geiser:completions` in `src/geiser/geiser.scm`) calls `(interaction-environment)` then walks the environment. ECE doesn't have `interaction-environment` but has direct access to `*global-env*` via a new primitive.

Day 1 also discovered two ECE bugs during implementation:
- **guard+eval double-invocation**: `guard` around `eval` fires the continuation twice. Worked around by using `try-eval` in the REPL loop.
- **Pipe-escape roundtrip**: ECE's reader doesn't parse CL `|symbol|` syntax, so colon-containing symbols don't roundtrip through file compilation. Handler names use hyphens.

Neither bug affects day 2's scope — completions don't need `guard` around `eval`, and the primitive name `%global-env-symbols` has no colons.

## Goals / Non-Goals

**Goals:**

- `C-M-i` in a `.scm` buffer shows prefix-matched completions from ECE's global environment.
- TAB in the Geiser REPL buffer triggers the same completions.
- `%global-env-symbols` primitive is a general-purpose introspection hook, usable beyond Geiser.
- Completions include all global bindings: prelude functions, compiler internals, user defines, primitives.

**Non-Goals:**

- Autodoc / arglist hints (`geiser-autodoc`) — day 3, needs compiled-procedure signature extraction.
- Module-scoped completions — ECE has no user-visible module system. All completions come from `*global-env*`.
- Fuzzy matching — prefix match only for day 2. Fuzzy/substring matching is a UX polish item.
- Completion annotations (type, arity, source) — day 2 returns bare symbol names. Annotations need more introspection.
- Local variable completions — would need lexical environment walking at the cursor position. Out of scope.

## Decisions

### Decision 1: Host primitive over ECE-level hash-table walk

**Choice:** Add `%global-env-symbols` as a CL host primitive that returns a list of strings.

**Rationale:** The global environment's hash-frame is a CL hash-table. Walking it from ECE would require either (a) exposing `hash-table-keys` as a primitive (which doesn't exist), or (b) using `hash-ref` with every possible symbol name (impossible without the key list). A single host primitive that does `maphash` and collects `symbol-name` is ~5 lines and O(n) in the number of bindings.

**Alternatives considered:**
- **Expose `hash-table-keys` as a general primitive** — more powerful but adds a general-purpose hash introspection API we don't need yet. `%global-env-symbols` is more focused.
- **Walk the environment chain in ECE** — the env is a list of frames ending at the hash-frame. ECE code could walk it, but the hash-frame itself is opaque from ECE. Still needs a primitive to enumerate the hash-table.

### Decision 2: Prefix filtering in ECE, not CL

**Choice:** `%global-env-symbols` returns ALL symbols. `geiser-completions` in `src/geiser-ece.scm` does the prefix filtering.

**Rationale:** Keeps the primitive general-purpose. Filtering is trivial in ECE (`string-prefix?` + `filter`). If performance matters later, we can add a `%global-env-symbols-matching prefix` variant, but ~750 symbols is fast enough for interactive use.

### Decision 3: Return strings, not symbols

**Choice:** `%global-env-symbols` returns a list of strings (via `symbol-name`), not a list of symbols.

**Rationale:** Geiser's elisp side expects completion candidates as strings. Returning strings avoids a `symbol->string` map in ECE. Also avoids the `write-to-string-flat` symbol-escaping issues discovered in day 1 — strings roundtrip cleanly through any serialization.

### Decision 4: Sorted results

**Choice:** `geiser-completions` returns results sorted alphabetically.

**Rationale:** Geiser's completion popup displays candidates in the order received. Sorted results are easier to scan. The sort happens in ECE via `sort` on strings.

## Risks / Trade-offs

- **[Risk] Bootstrap rebuild required.** Adding a new primitive ID requires `make bootstrap && make`. Single-pass (no migration), but takes ~2 minutes. Low risk.
- **[Risk] Large completion list on empty prefix.** If the user hits `C-M-i` with no prefix, they get ~750+ candidates. Geiser's popup handles this fine (scrollable list), but it's noisy. Mitigation: document that a few characters of prefix are recommended. Phase 2+ could add a minimum-prefix-length filter.
- **[Trade-off] No local variable completions.** Only global symbols are completed. A user defining `(let ((my-local-var 42)) my-lo|)` and hitting `C-M-i` won't see `my-local-var`. This is consistent with chibi's day-1 Geiser completions and is acceptable for now.
