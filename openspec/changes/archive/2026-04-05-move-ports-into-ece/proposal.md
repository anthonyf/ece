## Why

Output capture for test harnesses is broken. `display`, `write`, `newline`, `write-char`, and `write-string` are defined in `runtime.lisp` as host primitives that write directly to CL's `*standard-output*`, ignoring ECE's `current-output-port` entirely. Meanwhile, `current-output-port` is a zero-argument CL accessor — not a real R7RS parameter — so `(parameterize ((current-output-port p)) ...)` cannot actually rebind it. A pure-ECE test runner cannot capture output, which blocks the ECE SDK toolchain work (ece-test) and the Dunge port. This change makes port handling conform to R7RS and aligns with the project's kernel-minimization goal by moving behavior out of the CL kernel into ECE.

## What Changes

- **Kernel primitives take explicit ports.** Replace host `ece-display` / `ece-write` / `ece-newline` / `ece-write-char` / `ece-write-string` with port-required low-level primitives (`%display-to-port`, `%write-to-port`, `%newline-to-port`, `%write-char-to-port`, `%write-string-to-port`). These mandate an explicit port argument; no fallback to `*standard-output*`.
- **ECE wrappers provide R7RS signatures.** In `prelude.scm`, define `display`, `write`, `newline`, `write-char`, `write-string` as ECE procedures that accept an optional port argument and default to `(current-output-port)` when omitted.
- **`current-output-port` / `current-input-port` become real parameters.** Replace the CL-defvar-accessor pattern with ECE-side `(make-parameter initial-port)` definitions. Initial values come from primitives `%initial-output-port` / `%initial-input-port` that wrap `*standard-output*` / `*standard-input*` (called once at boot).
- **Add `with-output-to-string` and `with-input-from-string` macros** in `prelude.scm`, plus `with-output-to-port` / `with-input-from-port` for completeness.
- **BREAKING** for any CL-side caller that mutated the `*current-output-port*` defvar expecting `(display x)` to honor it — that never actually worked, but the defvar itself is removed.
- **Two-pass bootstrap** required to migrate primitives safely (add wrappers → bootstrap → remove host primitives → bootstrap again).

**Out of scope:** record ports, bytevector ports, R7RS textual/binary port distinction, changes to `read` / `peek-char` / `read-char` (already port-parameterized correctly).

## Capabilities

### New Capabilities

- `output-capture`: R7RS-compatible output and input capture macros (`with-output-to-string`, `with-input-from-string`, `with-output-to-port`, `with-input-from-port`) built on top of parameter-based current ports.

### Modified Capabilities

- `ports`: `current-output-port` and `current-input-port` become R7RS parameters (callable with 0 or 1-2 args). Initial values come from boot-time primitives. Host `display` / `write` / `newline` / `write-char` / `write-string` primitives are replaced with low-level `%<op>-to-port` primitives that require an explicit port.
- `parameterize`: Scenario coverage extends to verify `(parameterize ((current-output-port p)) ...)` correctly rebinds and restores, including dynamic-wind interactions across continuation invocations.

## Impact

- **Affected code:**
  - `src/runtime.lisp`: replace `ece-display` / `ece-write` / `ece-newline` / `ece-write-char` / `ece-write-string`; remove `*current-output-port*` / `*current-input-port*` CL defvars and their ECE-facing accessors; add `%display-to-port`, `%write-to-port`, `%newline-to-port`, `%write-char-to-port`, `%write-string-to-port`, `%initial-output-port`, `%initial-input-port` primitives.
  - `src/prelude.scm`: add ECE wrappers for `display` / `write` / `newline` / `write-char` / `write-string`; define `current-output-port` / `current-input-port` as parameters; add `with-output-to-string` / `with-input-from-string` / `with-output-to-port` / `with-input-from-port` macros.
  - `primitives.def`: add new primitive IDs for the `%<op>-to-port` operations and `%initial-*-port` constructors.
- **Bootstrap:** Two-pass rebuild (per the "Known Pitfalls" two-pass protocol). Bootstrap bundle `bootstrap/bootstrap.ecec` will be regenerated twice during implementation.
- **WASM runtime:** `wasm/runtime.wat` also needs the new `%<op>-to-port` primitives (mirroring the CL kernel).
- **Tests:** Existing tests calling `(display x)` without a port continue to work; new test file `tests/ece/test-output-capture.scm` covers parameterize rebinding, capture macros, and dynamic-wind interactions.
- **Callers outside ECE:** CL-side code in `tests/ece.lisp` that uses `(with-output-to-string (*standard-output*) ...)` continues to work — it captures CL's `*standard-output*`, which the fresh port still wraps at boot.
