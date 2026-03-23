## Context

Three TODOs in `runtime.wat` mark places where missing error handling or bounds checks cause confusing crashes. These were written during initial development and never addressed.

## Goals / Non-Goals

**Goals:**
- Clear error messages instead of cryptic WASM traps
- Arrays grow automatically instead of crashing on overflow
- No performance impact on the normal (non-error) path

**Non-Goals:**
- Full error recovery (catch and continue) — just signal clearly and abort
- Structured exception handling in WASM — use JS import for error reporting

## Decisions

### 1. Runtime error import

Add a new JS import `io.runtime_error(len)` that reads an error message string from linear memory (same convention as `display_string`) and throws a JS exception. The WASM side writes the message to memory then calls the import.

Helper function `$signal-error-symbol(prefix-str, sym)`:
- Writes the prefix string to memory
- Appends the symbol name
- Calls `$js-runtime-error(total-len)`

This is used by `lookup-variable-value` to report "Unbound variable: <name>".

### 2. Symbol table growth

In `$intern`, after the linear scan fails to find the symbol:
- Check if `sym-count >= array.len(sym-names)`
- If so, allocate new arrays at 2x capacity, copy old data, update globals
- Then proceed with normal insertion

The `$sym-capacity` global is removed — use `array.len` directly.

### 3. Space array growth

In `$register-space`:
- Check if `sym-id >= array.len(spaces)`
- If so, allocate a new array at `max(sym-id + 1, old-len * 2)`, copy old data, update global
- Then proceed with normal insertion

### 4. Where to add import handlers

- `wasm/glue.js`: `io.runtime_error(len)` reads message from memory, throws `Error`
- `wasm/test.js`: Same handler in test imports
- `sandbox/sandbox.js`: Same handler, also appends to console output

## Risks / Trade-offs

- **Growth copies**: Array doubling means occasional O(n) copies. Negligible — these arrays are small and growth is rare (only during bootstrap for symbols, almost never for spaces).
- **Error abort**: `runtime_error` throws a JS exception which unwinds through WASM. This is the simplest approach. A more sophisticated error-handling system (ECE-level `error` function) exists but requires the prelude to be loaded, which isn't guaranteed during bootstrap.
