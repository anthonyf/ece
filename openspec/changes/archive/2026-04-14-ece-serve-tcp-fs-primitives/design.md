## Context

The parent change `ece-serve` (Stage 1 of the browser-dev-loop plan) needs a small CL-side host primitive surface so that ECE code can run a TCP server with non-blocking accept/recv/send and watch source files for modifications. The design doc for `ece-serve` already specifies the eight primitives in Decision 4 and the rationale for "thin CL primitive surface, fat ECE server logic" — that decision is unchanged. This change is the implementation of those eight primitives, extracted into its own openspec change for the same reasons `sha1-base64-utilities` was extracted: independent shippability, smaller diffs per PR, and earlier availability for any other dev-tooling that wants the same building blocks.

## Goals / Non-Goals

**Goals:**
- Eight new CL-only primitives wired through the standard `primitives.def` → `primitives.scm` → `bootstrap/primitives-auto.lisp` → `init-primitive-dispatch-tables` pipeline.
- Non-blocking semantics so the future scheduler can poll without ever blocking the calling fiber.
- Cross-platform: works on every SBCL target the rest of the ECE binary works on. Polling fs-watch is the cross-platform fallback; native event sources (inotify / fsevents / ReadDirectoryChangesW) are explicitly out of scope for this change.
- Helper defuns live in `src/runtime.lisp` (the existing convention for "primitive template references a longer CL helper", e.g. `ece-port-stream`, `ece-make-output-port`).

**Non-Goals:**
- HTTP, WebSocket, or any protocol parsing — that's `ece-serve` section 4.
- A real cooperative scheduler — `ece-serve` section 2.
- Native filesystem event integration — polling is good enough for an interactive dev loop and avoids cross-platform fragility. Revisit if polling becomes a bottleneck.
- Asynchronous *send* with a true `:would-block` return path. Pragmatically, TCP send buffers absorb small writes immediately, and the dev server's writes are small (HTTP headers, WebSocket text frames). Section 4 of `ece-serve` will revisit if a measurable hang materializes.
- Bytevector type for the recv return value — ECE has no native bytevector. Returning a list of byte integers is slow but simple and works for everything `ece-serve` needs to parse. Optimization is a future concern if profiling shows it matters.
- Adding the primitives to `boot-env.scm`. CL builds the global env from the manifest at boot time via `build-global-env-from-manifest`, so CL-only primitives don't need explicit `%register-primitive!` calls. WASM does need them, but these primitives are CL-only and would error if called from a WASM image regardless.

## Decisions

### 1. Use `usocket` for portable TCP

**Choice:** Add `usocket` as a CL dependency via qlfile and `ece.asd`. Wrap its socket-listen / wait-for-input / socket-accept / socket-close API directly. Use `:element-type '(unsigned-byte 8)` everywhere so reads and writes are byte-oriented, not character-oriented.

**Rationale:** `usocket` has been the de facto portable TCP layer for Common Lisp for over a decade. It works on SBCL, CCL, ECL, and CLISP across macOS, Linux, and Windows without per-OS conditional code. The alternative is `sb-bsd-sockets` (SBCL-only) or hand-rolling on top of `sb-unix:unix-socket`, both of which lock the dev tooling to SBCL forever. The cost of the dependency is a few hundred KB of FASLs at boot — invisible in practice.

**Tradeoff:** `usocket`'s non-blocking semantics aren't perfectly uniform across platforms. The primary mechanism for non-blocking I/O is `usocket:wait-for-input :timeout 0 :ready-only t`, which returns the list of ready sockets. After that, a regular `read-byte` on the underlying stream is guaranteed to return immediately (either with data or with EOF). For send, `write-sequence` may technically block if the kernel send buffer is full, but practical TCP send buffers (64+ KB on macOS / Linux) absorb dev-server writes without any visible latency. If this becomes a problem, section 4 of `ece-serve` can revisit by switching to `sb-bsd-sockets:socket-make-stream` with `:input` and `:output` set to `nil` and direct `recvfrom`/`sendto` syscalls — but only if profiling demands it.

### 2. Recv distinguishes "would-block" from "eof" via `wait-for-input` + first-byte read

**Choice:** `tcp-recv-nowait` first calls `(usocket:wait-for-input conn :timeout 0 :ready-only t)`. If that returns nil, the connection is idle → return `:would-block`. If it returns the conn (i.e., the socket is "ready"), do `(read-byte stream nil nil)` — `nil` means the peer closed, return `:eof`. Otherwise we got a byte; loop pulling more bytes via `(listen stream)` until we hit `max-bytes` or the buffer drains.

**Rationale:** The naive approach — using only `(listen stream)` — doesn't distinguish "no data, connection still open" from "no data, peer closed". Both return `nil` for `listen` because there are no bytes in the buffer. `usocket:wait-for-input`, by contrast, signals readiness on EITHER condition (this is how Berkeley sockets `select(2)` works). Once the socket reports ready, a single `read-byte` resolves the ambiguity: data byte vs `nil` (EOF).

The dev test at `tests/ece.lisp` `test-tcp-recv-eof-on-closed-peer` exercises this exact path — closing the client and verifying the server's recv returns `:eof` rather than spinning on `:would-block`. The first implementation used only `listen` and that test caught the bug immediately.

### 3. Polling-based file watcher with `file-write-date`

**Choice:** `fs-watch-start` snapshots the mtime of each watched path via `(file-write-date path)` and stores them in a hash table keyed by an integer watcher id. `fs-watch-poll` walks the table, compares each stored mtime to the current mtime, and returns the list of paths whose mtime advanced (also updating the stored mtimes so the next poll only reports new changes).

**Rationale:** Polling is the only filesystem-event mechanism that's portable across SBCL targets without conditional compilation. Native event sources are platform-specific and have rough edges around editor "atomic save" patterns (write to temp, rename over original — inotify sees this as a move, not a modify, and the file handle becomes stale). Polling is dumb but always correct.

**Tradeoff:** `file-write-date` returns 1-second resolution on most filesystems (it's a Common Lisp wrapper around POSIX `stat()` mtime, which is `time_t` seconds in older filesystems). That's fine for an interactive dev loop where the developer saves a file every few seconds. For sub-second edit detection, a future enhancement could call `(sb-posix:stat path)` directly and read the nanosecond-resolution `st_mtim` field — but only if we actually need it.

### 4. Non-blocking accept via `wait-for-input` + scheme-#f sentinel

**Choice:** `tcp-accept-nowait` checks `(usocket:wait-for-input server :timeout 0 :ready-only t)`. If nothing is ready, return the runtime's scheme-`#f` sentinel via `(scheme-bool nil)` so the caller can use the standard `if`/`when` predicate flow without distinguishing nil from `()`. If a connection is pending, return the new conn handle from `usocket:socket-accept`.

**Rationale:** ECE's `if` treats only `#f` as false, not `nil`/`()` (which are truthy). Returning bare `nil` from a primitive would make the caller see a truthy `()`-like value in `(if no-conn ...)`, which is the opposite of what we want. The `scheme-bool` helper in `src/runtime.lisp` exists precisely for this case.

### 5. Bridge `bootstrap/primitives-auto.lisp` manually before regen

**Choice:** Adding new entries to `primitives.def` causes `validate-primitive-dispatch-tables` (which runs at the end of `runtime.lisp` load) to error out unless every new entry has an `ece-NAME` defun visible. The codegen tool that produces `primitives-auto.lisp` runs *inside* a loaded ECE image — so the chicken-and-egg is: you can't regenerate `primitives-auto.lisp` until the image loads, and the image won't load until `primitives-auto.lisp` has the new defuns.

The workaround used here: hand-add the 8 new defuns to `primitives-auto.lisp` once. The hand-edit mirrors the eventual codegen output exactly (same template body, same sorted insertion order). Then `make bootstrap/primitives-auto.lisp` regenerates from the templates and produces a byte-identical file. The diff for the bridge step is included in the same commit so the repository is never in a broken state.

**Rationale:** This is the same trick used historically when the codegen pipeline was first introduced (see archive `2026-04-11-emit-host-primitives` Decision 5). It's awkward but it's a one-time cost per primitive, and the alternative (a special "build mode that skips validation") would add permanent complexity for something that happens once every few months when new CL primitives are added.

**Idempotency check:** the test plan includes regenerating `primitives-auto.lisp` from `primitives.scm` after the hand-edit and verifying byte-identical output. This guarantees the bridge step is correct.

## Risks / Trade-offs

- **`usocket` dependency footprint**: a few CL files plus its deps (`split-sequence`, etc.) get loaded at boot. Measured impact on boot time: indistinguishable from noise. The FASL cache hides any compile cost after the first run. This is the lowest-risk CL dependency available.
- **Polling overhead**: `fs-watch-poll` does N `stat()` calls per poll (where N is the size of the watch set). For a dev loop polling every 250ms over ~10 source files, that's 40 stats/second — trivially absorbed by the kernel page cache. Native event sources would cut this to zero, but the cross-platform complexity isn't worth the savings until profiling proves otherwise.
- **`tcp-send-nowait` is technically blocking**: under a misbehaving peer that stops reading, `write-sequence` could in theory block until the kernel send buffer fills. For the dev server's traffic pattern (small HTTP responses + small WebSocket text frames) this is not realistic. Documented as a known limitation; section 4 of `ece-serve` revisits if profiling demands it.
- **Hand-bridged `primitives-auto.lisp`**: there's a single-commit window where the file must be hand-correct or the build breaks. Mitigated by regenerating immediately after the hand-edit and verifying byte-identical output, all in the same commit.
- **No WASM port**: every primitive is marked platform `cl`. If somebody calls `tcp-listen` from an ECE program running under the WASM runtime, they get the standard "Primitive ~A requires ~A platform" error. This is intentional — the dev server runs on the developer's machine, not in the browser. WASM ports of these primitives would need entirely different host bridges (WebSockets in the browser, WASI sockets outside), and that's a separate discussion.

## Migration Plan

Not applicable. Pure additions. Nothing existing is deprecated or changed.

## Open Questions

- **Should `tcp-accept-nowait` return `#f` or a Scheme symbol like `'no-connection`?** Decided: `#f`. Matches the existing convention for "no result" predicates and works directly with `(if (tcp-accept-nowait server) ...)`.
- **Should `tcp-recv-nowait` return a string or a list of bytes?** Decided: list of bytes. ECE has no native bytevector and the recv path needs to compose with byte-level parsing (HTTP header lines, WebSocket frame bytes). A list is slow but correct and trivially convertible if a string is needed.
- **Should the file watcher fall back to native event sources on platforms where they're cleanly available?** Deferred to a follow-up if measurement shows polling overhead matters. Not worth the conditional compilation today.
- **Should this change also wire up the `ece-serve.scm` startup helper that uses these primitives?** No — that's section 4 of `ece-serve`, with its own scheduler dependency. Keeping this change pure host-primitive layer makes the diff focused and the validation gate trivial.
