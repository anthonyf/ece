## REMOVED Requirements

### Requirement: print-text displays formatted text
**Reason**: Non-standard Scheme. Trivial wrapper around `(display (apply fmt args))`. Not used outside the prelude.
**Migration**: Use `(display (string-append ...))` directly.

### Requirement: lines joins arguments with newlines
**Reason**: Non-standard Scheme. Not used outside the prelude.
**Migration**: Use `(string-append str1 "\n" str2 "\n")` or build manually.

### Requirement: fmt concatenates arguments as strings
**Reason**: Non-standard Scheme. Only existed to back string interpolation. Reader now expands interpolation to `string-append`/`write-to-string` directly.
**Migration**: Use `(string-append ... (write-to-string expr) ...)` directly.
