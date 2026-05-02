# WASM Native Zone Host Plan

ECE's WASM runtime should gain native-zone support without turning JavaScript
glue into the owner of the runtime policy. The long-term model is the same as
the CL native-zone path: compiled ECE code objects are still the semantic unit,
the interpreter remains the fallback, and native code is an acceleration layer
registered against archive unit identity.

The difference is that the browser has an unavoidable host boundary. The root
ECE VM must be instantiated by JavaScript, and browser capabilities such as
`fetch`, `WebAssembly.instantiate`, promises, and import-object construction are
host APIs. The design should keep that boundary small: JavaScript provides raw
capabilities, while ECE code decides what to load, when to reload, how to
register zones, and how errors fall back.

## Goals

- Let ECE-authored code define the WASM host/loading policy.
- Keep JavaScript as a tiny capability substrate rather than a second runtime
  policy layer.
- Load `.ecec` archive bundles and optional native-zone WASM modules from an
  `ece-serve` session.
- Register native-zone exports by archive unit key and co-index.
- Dispatch to native zones when present and fall back to the interpreter when
  absent or when a zone chooses to bail.
- Preserve the single register-machine semantic model across interpreted and
  native execution.

## Non-Goals

- Replacing the root `wasm/glue.js` bootstrap. The browser still needs a small
  JS entry point to instantiate the first ECE VM and provide imports.
- Exposing raw WasmGC references from the ECE VM to side-loaded modules in the
  first pass.
- Compiling the entire VM to a second native backend immediately.
- Solving code-object migration for already-captured continuations during live
  reload. New calls can see new code; old continuations may still reference old
  code objects.

## Layering

The intended ownership split is:

| Layer | Owner | Responsibility |
| --- | --- | --- |
| Browser host capabilities | JavaScript | Root VM instantiation, `fetch`, side-module instantiation, promise bridging, import object construction. |
| WASM host library | ECE | User-facing loading API, manifest parsing, reload policy, native-zone registration, error reporting. |
| WASM runtime kernel | WAT | Archive/code-object loading, native-zone registry storage, executor dispatch hook, handle-table interop. |
| Native-zone module | Generated register-machine WASM | Fast-path implementation for selected code objects, with a narrow register ABI and interpreter bail-out. |

This mirrors the existing browser library pattern. Raw `%js-*` primitives are
host capabilities; [`src/browser-lib.scm`](../../src/browser-lib.scm) turns them
into ECE-level DOM, canvas, event, and math APIs. The native-zone host should use
the same shape: raw `%wasm-*` capabilities first, then an ECE library on top.

## ECE-Facing Host API

Add a new ECE library, tentatively `src/wasm-host.scm`, loaded on the browser
platform. Its public surface should start small:

```scheme
(fetch-text url)
(fetch-bytes url)
(wasm-instantiate bytes imports)
(wasm-export instance name)

(register-native-zone! unit-id co-index export-ref)
(load-native-zone-manifest manifest-url)
(load-native-zone-module module-url manifest-url)
(reload-program archive-url zone-module-url manifest-url)
```

The low-level functions may initially be wrappers around host primitives:

```scheme
(define (fetch-text url) (%wasm-fetch-text url))
(define (fetch-bytes url) (%wasm-fetch-bytes url))
(define (wasm-instantiate bytes imports)
  (%wasm-instantiate bytes imports))
(define (wasm-export instance name)
  (%wasm-export instance name))
```

The policy functions should live in ECE:

```scheme
(define (load-native-zone-module module-url manifest-url)
  (let* ((manifest (load-native-zone-manifest manifest-url))
         (bytes (fetch-bytes module-url))
         (instance (wasm-instantiate bytes (native-zone-imports))))
    (for-each
     (lambda (entry)
       (register-native-zone!
        (native-zone-manifest-unit-id manifest)
        (native-zone-entry-index entry)
        (wasm-export instance (native-zone-entry-export-name entry))))
     (native-zone-manifest-entries manifest))
    instance))
```

The exact async representation can evolve. For the first implementation, the JS
capability layer exposes synchronous reads from a JS-managed resource cache and
synchronous `WebAssembly.Module`/`WebAssembly.Instance` construction. That keeps
`wasm-host.scm` policy synchronous for now: browser or server glue fetches
artifacts first, seeds the cache, then asks ECE to load the native-zone module.
A promise-backed API can be layered above this once ECE's browser event model
needs direct fetch orchestration.

## Native Zone Manifest

Native-zone modules should not require JavaScript to know every code-object
mapping. The compiler should emit a manifest next to the native WASM module.

Initial readable shape:

```scheme
(:ece-native-zones
  :version 1
  :unit-id (module (game main) 0)
  :source "game/main.scm"
  :module-url "game-main-zones.wasm"
  :entries ((:index 0 :export "zone_0" :fingerprint "...optional...")
            (:index 1 :export "zone_1" :fingerprint "...optional...")))
```

Rules:

- `:unit-id` is the archive unit identity used by the `.ecec` archive.
- `:index` is the co-index, meaning the code-object index within that archive
  unit.
- `:export` names a function exported by the side-loaded native-zone module.
- Fingerprints are optional at first but should line up with archive
  save/restore fingerprints when available.
- Reloading the same `(unit-id . index)` replaces the registered zone.

## Runtime Registry

WASM should gain a native-zone registry parallel to its archive code-object
registry:

```text
(unit-id . co-index) -> native-zone-ref
```

The ECE-facing primitive should be:

```scheme
(register-native-zone! unit-id co-index export-ref)
```

Internally this can be represented however the WAT runtime can dispatch most
cheaply. The first implementation should favor correctness and inspectability
over direct function-table cleverness. An opaque host function reference or
integer handle is acceptable as long as:

- lookup uses the same archive unit key convention as code-object registration;
- duplicate registration overwrites the old zone;
- missing registration is ordinary and means interpreter fallback;
- tests can inspect whether a key is registered.

## Dispatch ABI

The CL native-zone ABI is:

```text
zone(pc, val, env, proc, argl, continue, stack)
  -> pc, val, env, proc, argl, continue, stack
```

WASM should keep the same logical register contract but avoid exposing raw
WasmGC internals to side-loaded modules in the first pass. A handle-oriented ABI
is safer:

```text
zone(pc,
     val_handle,
     env_handle,
     proc_handle,
     argl_handle,
     continue_handle,
     stack_handle)
  -> result_handle
```

`result_handle` should point to a small ECE-visible or WAT-internal result
record, for example:

```scheme
(:native-zone-result
  :mode :continue
  :pc 17
  :val <handle>
  :env <handle>
  :proc <handle>
  :argl <handle>
  :continue <handle>
  :stack <handle>)
```

Supported modes:

- `:continue`: update registers and continue execution from the returned PC.
- `:return`: update registers and return from `run_code_object` if the zone
  completed the code object.
- `:bail`: update registers and fall back to the interpreter at the returned PC.

This is intentionally less efficient than direct WasmGC calls. It is a
stability move: once the registry, reload, and dispatch semantics are proven,
the ABI can be optimized.

## Executor Dispatch

At code-object entry, the WASM executor should:

1. Read the code object's archive key.
2. Look up a native-zone ref for that key.
3. If no zone exists, run the interpreter exactly as today.
4. If a zone exists, call it with the current logical registers.
5. Apply the returned register updates.
6. Continue, return, or bail according to the result mode.

Native dispatch should only happen at code-object entry at first. That matches
the CL model closely and avoids mid-instruction replacement hazards. A future
optimization can add additional dispatch points after cross-code-object jumps if
profiling proves it worthwhile.

## Reload Semantics

Reload should be explicit and monotonic:

- Loading a new `.ecec` archive with the same unit-id materializes new code
  objects and replaces registry entries for those indices.
- Loading a native-zone module with the same `(unit-id . index)` replaces the
  native-zone registry entry.
- Existing continuations and closures may still reference old code objects.
  They are not rewritten in place.
- New imports, top-level lookups, and freshly-created closures should observe
  the newly loaded archive/module semantics.
- Durable save/restore remains governed by archive keys and fingerprints.
  Fingerprint mismatch should be loud.

For live coding, this is acceptable. It matches the general Scheme expectation
that reloading changes future bindings without pretending to edit every live
continuation already in the system.

## First Implementation Phases

### Phase 1: ECE Host Design Surface

- Add `src/wasm-host.scm` with ECE-level API stubs or wrappers.
- Add primitive IDs for minimal `%wasm-*` capabilities, but they may be fake or
  test-only at first.
- Add manifest reader/validator tests in ECE.
- Document manifest and reload policy.

No executor dispatch in this phase.

### Phase 2: Runtime Registry

- Add WASM native-zone registry storage.
- Add `register-native-zone!` and lookup/test primitives.
- Add JS glue only where required to turn exported side-module functions into
  opaque refs/handles.
- Test registration, overwrite, missing lookup, and reload behavior.

Still no native execution in this phase.

Registry keys should be normalized before they reach the runtime. File-style
unit ids may already be symbols or strings, but module unit ids are structured
lists such as `(module (game main) 0)`. The current WASM hash table is
identity-keyed, so the ECE host layer interns strings directly and interns a
stable textual key for structured unit ids before passing the normalized key to
the runtime registry. This keeps repeated equal module ids addressable without
requiring structural hash-table support in the WAT kernel.

### Phase 3: Hand-Written Dispatch Smoke

- Add the executor entry hook.
- Use a hand-written tiny native-zone module for one simple archive code
  object.
- Verify native dispatch, interpreter fallback, bail mode, and error reporting.

The initial dispatch protocol is deliberately handle-based because WasmGC refs
do not cross into JavaScript directly. A registered native-zone value must be a
`js-ref` wrapping a callable side-module export. At code-object entry, the WAT
executor wraps the current logical registers as handles and calls the host
bridge. The callable returns an ECE vector:

```scheme
#(mode pc val env proc argl continue stack)
```

Mode `0` returns `val` immediately. Mode `1` updates the logical registers and
continues interpreting the same code object at `pc`. Mode `2` is a bail: the
executor applies the vector's `pc` and register slots before resuming the
interpreter. This lets generated zones run a supported prefix and bail out at
the first unsupported instruction without losing register-machine state.

### Phase 4: Register-Machine WASM Zones

- Add a WASM native-zone code generator for a small register-machine
  instruction subset.
- Emit native-zone manifests.
- Fall back on unsupported instructions.
- Expand coverage only after cross-runtime tests are stable.

Generated zones are not direct-style Scheme procedures. They implement the
same logical register contract as the interpreter: `pc`, `val`, `env`, `proc`,
`argl`, `continue`, and `stack` are still the semantic state, and the zone
returns the normal native-zone result vector. Tail calls, `call/cc`,
`dynamic-wind`, and fallback correctness all depend on this: the WASM host call
stack is an implementation detail, not the Scheme continuation model.

The first generator slice is intentionally tiny. It emits a side-module WAT
function for a code object whose instruction stream stays within a small
register-machine subset:

```scheme
(assign <register> (const <fixnum>))
(assign <register> (const ()))
(assign <register> (const #t))
(assign <register> (const #f))
(assign <register> (reg <register>))
(assign <register> (op list) <operand> ...)
(assign <register> (op cons) <operand> <operand>)
(assign <register> (op car) <operand>)
(assign <register> (op cdr) <operand>)
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
(assign val (op compiled-procedure-entry) (reg proc))
(assign continue (label <local-label>))
(test (op false?) <operand>)
(test (op continuation?) <operand>)
(test (op parameter?) <operand>)
(branch (label <local-label>))
(goto (label <local-label>))
(save <register>)
(restore <register>)
(halt)
```

If the first instruction is unsupported, the code object declines generation and
continues through the interpreter. If a supported prefix reaches an unsupported
instruction, the generated zone returns `:bail` with updated registers and the
unsupported instruction's PC, so the interpreter continues from that point.
Generated WASM preserves the logical register machine: branch and goto update a
native-zone `pc` local and loop through a dispatch block rather than compiling
Scheme control flow onto the host WASM call stack.
Save and restore manipulate the ECE `stack` register as an ECE list, so
non-tail primitive calls can stay native without using the host WASM call stack
as Scheme control state.

Primitive operation support goes through ordinary VM lookup/application helpers.
Arithmetic such as `+` is not inlined or shortcut: generated zones still look
up the current binding, verify it is still primitive, call the VM primitive
dispatcher, and bail to the interpreter if rebinding or primitive errors require
the normal register-machine path.

Compiled-procedure call setup is also native for the caller side: generated
zones can perform the callable dispatch tests, qualify `continue` labels with
the current code object, and fetch the compiled-procedure entry. Register-valued
`goto` remains an interpreter bailout point, so cross-code-object transfer,
tail-call behavior, and continuation semantics still run through the existing
register-machine executor.

The generator can also walk an archive code-object vector and produce one
side-module WAT plus a native-zone manifest. Supported code-object indexes get
stable exports named `zone_<index>`; unsupported indexes are omitted from the
manifest and keep running through the interpreter. The `.ecec` archive remains
the semantic source of truth, while the side module is a replaceable
acceleration artifact keyed by the archive unit id and code-object index.
Generated manifest entries include code-object fingerprints when the runtime can
compute them. If the corresponding archive unit is already registered, the
loader rejects a fingerprint mismatch before registering the side-module export.

## Testing Strategy

- ECE tests for manifest parsing and validation.
- WASM unit tests for registry operations and replacement.
- A browser or Node WASM integration test that loads an archive plus a
  hand-written zone module and proves dispatch happened.
- Reload tests where a second zone replaces the first.
- Fallback tests where the archive loads without a zone and still runs
  interpreted.
- Stale manifest tests where the manifest references a missing export or wrong
  unit-id and fails loudly.

## Open Questions

- What async abstraction should ECE expose for browser promises?
- Should native-zone result records be ECE data, WAT structs, or a compact
  handle-table side channel?
- How early should fingerprints be mandatory for native-zone manifests?
- Should `ece-serve` send archive and zone URLs, raw payloads, or both?
- When modules are present, should zone manifests use source-relative module
  URLs or bundle-relative URLs?
