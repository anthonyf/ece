## REMOVED Requirements

### Requirement: space IDs are symbols

**Reason:** The `compilation-space` construct retires as the runtime unit of compilation. Code objects take its place; they are self-identifying values carried by reference, not by a symbol keyed into a registry. There is no longer a "space id" as a runtime value. (A code-object archive — i.e., a `.ecec` file — may carry a source-file name as a label for diagnostics, but that is an archive-level artifact, not a runtime dispatch key.)

**Migration:** All uses of `(space-id . local-pc)` addresses at runtime migrate to direct code-object references. The compiler, assembler, and executor stop interning per-file symbols as space IDs. `.ecec` files may still record source filenames for source-map and disassembly diagnostics, but those names are strings on code objects, not hash-table keys.

### Requirement: space registry is symbol-keyed

**Reason:** `*space-registry*` retires. Code objects are reachable through normal value references (closures that embed them, the global environment that binds procedures that embed them, top-level archive references), not through a separate registry hash. This is the "GC reclaims redefined procedures naturally" property we want.

**Migration:** All `get-space`/`%create-space`/`%space-count` uses remove. Introspection primitives that previously enumerated spaces (for diagnostics) are replaced by code-object introspection APIs where still needed.

### Requirement: qualified addresses use symbols

**Reason:** Compiled-procedure entries and continuation return addresses no longer use `(symbol . local-pc)` pairs. They now use direct `(code-object . local-pc)` pairs, where `code-object` is a first-class value rather than a symbol hash key.

**Migration:** Callers of `compiled-procedure-entry` receive a code object rather than a `(space-id . local-pc)` pair. Callers of `continuation-conts` and similar observers receive continuations whose saved `continue` register holds `(code-object . local-pc)` values. Serialization formats that previously stored space-id symbols now store code-object identifiers (a scheme for this is defined in `code-object-compilation`'s archive-format requirement).

### Requirement: cross-space jump by symbol

**Reason:** The executor no longer dispatches by symbol lookup. Cross-procedure transitions update the executor's "current code object" field directly from a target code-object value; no hash lookup on a symbol is performed.

**Migration:** The `execute-instructions` top-level loop migrates from `(space-id, instrs, ltab)` locals to `(code-object, instrs, ltab)` locals. The `switch-space` helper becomes `switch-code-object` (or is inlined). No user-facing migration is required; the behavior is identical from ECE's perspective.
