## 1. Name Table Infrastructure

- [x] 1.1 Add `*procedure-name-table*` defvar (hash table, integer keys → symbol values)
- [x] 1.2 Update `assemble-into-global` to handle `(procedure-name <label> <name>)` pseudo-instructions: resolve label to PC, store in table, skip emitting to instruction vector

## 2. Compiler Integration

- [x] 2.1 Update `compile-define` in `compiler.lisp` to emit `(procedure-name <entry-label> <name>)` pseudo-instruction when the value expression is a lambda
- [x] 2.2 Update `mc-compile-define` in `compiler.scm` to emit `(procedure-name <entry-label> <name>)` pseudo-instruction when the value expression is a lambda

## 3. Error Display

- [x] 3.1 Update `format-ece-proc` to look up compiled procedure entry PCs in `*procedure-name-table*` and display the name when found

## 4. Image Save/Load

- [x] 4.1 Update `ece-save-image` to serialize `*procedure-name-table*` as a 5th element (alist of PC→name pairs)
- [x] 4.2 Update `ece-load-image` to restore `*procedure-name-table*` from the 5th element

## 5. Tests

- [x] 5.1 Test that `format-ece-proc` displays procedure name for a defined function
- [x] 5.2 Test that error messages show procedure name instead of raw PC
- [x] 5.3 Test that backtrace frames show procedure names
- [x] 5.4 Test that image save/load preserves procedure name mappings
- [x] 5.5 Test that anonymous lambdas still display as unnamed
- [x] 5.6 Test that MC-compiled defines also register procedure names
