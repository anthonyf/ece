## Context

`serialize-value` in `src/prelude.scm` builds output strings via recursive `string-append`. Each intermediate call copies all previously accumulated characters, yielding O(n²) total allocation. For small values this is fine, but inside `run-tests` → `try-eval`, compiled procedures capture deep environment chains (the compiler, prelude, and test framework bindings). Serializing these produces megabytes of output; the quadratic copying exhausts the heap.

A previous attempt (archived change) proposed a CL-only reimplementation of the serializer in `runtime.lisp`. This was rejected because it violates the project's "minimize the CL kernel" principle — anything that CAN be written in ECE SHOULD be written in ECE.

## Goals / Non-Goals

**Goals:**
- `make test-ece` completes without OOM
- All existing tests continue to pass (`make test`, `make test-wasm`)
- Serialization logic stays in ECE (`src/prelude.scm`), not duplicated in CL
- Both CL and WASM runtimes support the new primitives

**Non-Goals:**
- Rewriting the serialization format
- Changing the scan pass (it's already O(n))

## Decisions

### 1. Port-based serialization in ECE

**Decision:** Rewrite the `ser` pass in `serialize-value` (prelude.scm) to write to a string output port instead of returning intermediate strings. The top-level function opens a port with `(open-output-string)`, passes it to the `ser` helpers, and returns `(get-output-string port)`.

**Rationale:** Each token is written once to a resizable stream buffer — O(n) total. The serialization logic stays in ECE, matching the project principle that the CL kernel should be minimal. Both platforms benefit from the same fix.

**Rejected alternative — CL-native reimplementation:** Duplicating ~200 lines of serialization logic in `runtime.lisp` contradicts kernel minimization and creates a maintenance burden (two implementations of the same format).

### 2. Add `open-output-string` and `get-output-string` as core primitives

**Decision:** Register these as core primitives in `primitives.def` and implement on both CL and WASM.

**Rationale:** These are standard R7RS operations. CL already has `make-string-output-stream` / `get-output-stream-string`. WASM already has output port infrastructure with growable buffers (`$make-output-port`, `$port-write-char`) — just needs a function to extract the buffer as a string. ~5 lines each platform.

### 3. Use `display` for writing tokens to the port

**Decision:** The `ser` helpers call `(display token port)` for each piece of output. Pre-formatted tokens (from `write-to-string-flat`, `symbol->string`) are displayed as-is. Literal strings like `"(%ser/def "` are displayed directly.

**Rationale:** `display` with a port argument is already implemented on both platforms. No new primitives needed beyond the string port pair.

## Risks / Trade-offs

- **[Serialization output format unchanged]** → The port-based approach writes the same tokens in the same order, just via `display` instead of `string-append`. Deserialization is unaffected. All existing round-trip tests verify correctness.
- **[Two new primitives added to kernel]** → These are standard R7RS, ~5 lines each on CL/WASM. Much smaller than the 200-line CL alternative.
- **[Bootstrap rebuild required]** → prelude.scm changes require `make bootstrap` to regenerate .ecec files. Standard procedure.
