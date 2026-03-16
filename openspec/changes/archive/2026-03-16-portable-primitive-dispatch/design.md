## Context

ECE primitives currently work as follows:

1. `*primitive-procedures*` and `*wrapper-primitives*` in `runtime.lisp` define ~90 primitives as `(ece-name . cl-function)` pairs
2. These are stored in `*global-env*` as `(primitive <cl-symbol>)`
3. `apply-primitive-procedure` dispatches via `(symbol-function name)` — a CL-specific call
4. Binary image serialization stores the CL symbol name, which only CL can resolve

This design assumes CL is the only runtime. For multi-platform support (CL + WASM + future), primitives need platform-neutral identification and per-platform dispatch.

## Goals / Non-Goals

**Goals:**
- Single source of truth for all primitive definitions (the manifest)
- Stable numeric IDs that never change once assigned (image compatibility)
- Platform tagging so each runtime knows what it must implement
- Runtime discovery so ECE code can check what's available
- Zero performance regression on CL — table lookup should be as fast or faster than symbol-function

**Non-Goals:**
- Dynamic primitive registration from ECE code (all primitives come from the manifest + runtime)
- Changing the `(op ...)` mechanism for internal VM operations (separate system)
- Building the WASM runtime itself

## Decisions

### Manifest format

S-expression file (`primitives.def`) readable by both CL tooling and ECE itself:

```scheme
;; (id name arity platform description)
;; arity: N = exact, -1 = variadic

;; Core — all runtimes must implement
(0   +                -1   core    "Addition")
(1   -                -1   core    "Subtraction")
(2   *                -1   core    "Multiplication")
(3   /                -1   core    "Division")
(4   car               1   core    "First element of pair")
(5   cdr               1   core    "Rest of pair")
(6   cons              2   core    "Construct pair")
...

;; CL platform (100-199)
(100  open-input-file    1   cl      "Open file for reading")
(101  open-output-file   1   cl      "Open file for writing")
...

;; Browser platform (200-299)
(200  %create-element         1   browser   "Create DOM element")
(201  %set-attribute!         3   browser   "Set element attribute")
...
```

ID ranges: 0-99 core, 100-199 CL, 200-299 browser, 300+ future. Gaps allowed for future insertion within a range.

**Rationale:** S-expressions are natural for an ECE project. The manifest is small enough to be human-maintained. ID ranges prevent collisions when platforms evolve independently.

### Primitive representation change

Current: `(primitive ece-display)` — CL symbol
New: `(primitive 14)` — numeric ID

Each runtime maintains a dispatch table (array/vector indexed by ID):

```
CL:   *primitive-dispatch-table*  →  #(#'+ #'- #'* ... #'ece-display ...)
WASM: primitive_table             →  [func $add, func $sub, ... func $display, ...]
```

`apply-primitive-procedure` becomes:
```lisp
;; Before
(apply (symbol-function name) argl)

;; After
(apply (aref *primitive-dispatch-table* id) argl)
```

Array index lookup is O(1) and likely faster than `symbol-function`.

### Image serialization

The binary format already has a primitive tag. Change what follows it:

```
Before: PRIM_TAG + symbol-package-tag + symbol-name-bytes
After:  PRIM_TAG + uint16 (primitive ID)
```

On load, each runtime resolves the ID to its local representation. If a platform encounters an ID it doesn't support (e.g., CL loading an image with `%create-element`), it stores a stub that errors with a clear message: "Primitive %create-element requires browser platform."

### Platform discovery

Two new primitives (themselves in the manifest as core primitives):

- `platform-has?` (name → boolean): Returns `#t` if the named primitive is available on the current platform
- `%platform-primitives` (→ list): Returns list of all primitive names available on the current platform

Implementation: the runtime builds a set of available names at startup from its dispatch table. `platform-has?` checks membership. `%platform-primitives` returns the list.

```scheme
;; Usage in ECE
(if (platform-has? '%canvas-context)
    (setup-canvas-renderer!)
    (setup-text-renderer!))
```

### %-prefix convention

The `%` prefix is a **naming convention only** — it signals "platform-specific, may not be available everywhere." The compiler does not treat `%`-prefixed names specially. The convention is documented in the manifest and enforced socially.

### Migration path

The CL runtime is updated in place:
1. Parse `primitives.def` at load time (or at compile time via macro)
2. Build `*primitive-dispatch-table*` array from manifest + CL function mappings
3. Change `apply-primitive-procedure` to use table lookup
4. Update image serializer/deserializer to use numeric IDs
5. Re-save the image — old images with CL symbols become incompatible (acceptable, images are rebuilt from source)

## Prior Art

This design follows **Smalltalk/Squeak's numbered primitive model** (1983→present). Squeak stores `<primitive: 70>` in the portable image. Each VM implementation (C, SqueakJS, RSqueak) fills a `primitiveTable` array where index 70 maps to the platform's implementation. The image is bit-identical across platforms. Squeak later added *named* plugin primitives (`<primitive: 'sndPlay' module: 'SoundPlugin'>`) for extensions — analogous to the separate FFI proposal planned for ECE.

Lua takes a name-based approach (host registers C functions by name), but Lua bytecode isn't designed for cross-VM portability. WASM/WASI uses named imports with type signatures via WIT. Both are name-based because they don't have Smalltalk/ECE's portable image requirement.

The numbered approach is chosen because ECE, like Smalltalk, has a **portable image that must load on different runtimes**. Numeric IDs are compact (2 bytes), O(1) to dispatch, and proven over 40+ years of Smalltalk.

## Risks / Trade-offs

- **Image format break**: Images saved before this change won't load after. Acceptable — images are always rebuilt from `.scm` source files. No user data in images.
- **Manifest maintenance**: Adding a primitive now requires editing `primitives.def` in addition to the runtime. Small overhead, but ensures the registry stays canonical.
- **Fixed IDs**: Once an ID is assigned, it can never be reused for a different primitive (or old images break). IDs can be retired/deprecated but not reassigned. The ID space (uint16 = 65535 slots) is large enough this shouldn't be a practical concern.
- **Arity field is advisory**: The runtime doesn't enforce arity from the manifest — CL functions handle their own arity checking. The field is for documentation and tooling (e.g., a future WASM runtime could use it for validation).
