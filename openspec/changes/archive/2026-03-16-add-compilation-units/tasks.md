## 1. Compiled Unit Type

- [x] 1.1 Implement `compile-form` — wrap `mc-compile` to return `(compiled-unit <instructions>)` tagged list
- [x] 1.2 Implement `compiled-unit?` predicate
- [x] 1.3 Implement `compiled-unit-instructions` accessor
- [x] 1.4 Implement `execute` — extract instructions, call `assemble-into-global`, call `execute-from-pc`

## 2. Serialization

- [x] 2.1 ~~Implement gensym renaming pass~~ Not needed — `mc-make-label` uses interned symbols with a global counter, not gensyms
- [x] 2.2 Implement `write-compiled-unit` — `write` the instruction list to a port
- [x] 2.3 Implement `read-compiled-unit` — `read` from port, return compiled unit or eof

## 3. File Compilation and Loading

- [x] 3.1 Implement `compile-file` — loop over forms with `ece-scheme-read`, compile each with `compile-form`, detect `define-macro` and execute at compile time, write compiled units to `.ecec` file
- [x] 3.2 Implement `load-compiled` — read compiled units from `.ecec` file, execute each in sequence

## 4. Integration

- [x] 4.1 Create `src/compilation-unit.scm` and add to boot sequence after `compiler.scm` and `assembler.scm`
- [x] 4.2 Rebuild the image with the new definitions

## 5. Tests

- [x] 5.1 Test `compile-form` / `compiled-unit?` / `compiled-unit-instructions` with simple expressions and definitions
- [x] 5.2 Test `execute` with expressions, definitions, and sequential units
- [x] 5.3 Test `write-compiled-unit` / `read-compiled-unit` round-trip serialization
- [x] 5.4 Test `compile-file` / `load-compiled` round-trip including macro definitions
- [x] 5.5 Test equivalence: `load-compiled` of compiled file produces same result as `load` of source
