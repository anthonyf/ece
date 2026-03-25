## Approach

The simplest correct approach: `write` converts the value to its string representation via `$write-to-string-impl` (which already handles quoting), then displays the resulting string.

### Console output path (no port)

Current:
```
write(val)  → $display-value(val)     ;; no quoting
display(val) → $display-value(val)     ;; no quoting
```

After:
```
write(val)  → $display-value($write-to-string-impl(val))  ;; val → quoted string → display string chars
display(val) → $display-value(val)     ;; unchanged
```

Since `$write-to-string-impl` returns a string, and `$display-value` for strings just copies chars to memory and calls `$js-display-string`, the result is correct quoted output.

### Port output path

Current:
```
write(val, port)   → $display-to-port(val, port)   ;; no quoting
display(val, port) → $display-to-port(val, port)    ;; no quoting
```

After:
```
write(val, port)   → $write-to-port(val, port)     ;; quotes strings
display(val, port) → $display-to-port(val, port)    ;; unchanged
```

`$write-to-port` converts via `$write-to-string-impl` then writes the result string's chars to the port.

## Key Decisions

- Reuse `$write-to-string-impl` rather than duplicating quoting logic. This keeps write and write-to-string consistent.
- The slight overhead of building an intermediate string for `write` is acceptable — write is I/O-bound anyway.
- `$wts-list` and `$wts-vector` already use `$write-to-string-impl` for elements, so nested structures will have proper quoting.
