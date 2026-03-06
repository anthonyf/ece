## Context

The `ece` package exports core special form names (`define`, `set`, `call/cc`, etc.) but not several ECE-specific primitive names (`display`, `newline`, `null?`, `eof?`) or the `primitive` tag symbol. Tests use `ece::` internal access for these, which is unnecessary and inconsistent.

## Goals / Non-Goals

**Goals:**
- Export all ECE-specific symbols that tests or users need to reference
- Remove all `ece::` prefixes in tests where the symbol is exported

**Non-Goals:**
- Exporting CL-standard symbols that are already available via `:use :cl` (e.g., `read`, `print`, `+`, `car`)

## Decisions

**Export `display`, `newline`, `null?`, `eof?`, `primitive`**: These are ECE-specific symbols not in CL. Without exporting, any package using `:ece` must use `ece::` to reference them. Exporting makes them available as first-class symbols.

**No conflict risk**: None of these names clash with CL symbols, so exporting them is safe for any package that `:use`s both `:cl` and `:ece`.

## Risks / Trade-offs

- [No risks] → Straightforward addition of exports and test cleanup
