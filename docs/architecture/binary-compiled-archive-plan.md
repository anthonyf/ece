# Binary Compiled Archive Plan

ECE currently stores compiled programs as readable `.ecec` archive
s-expressions. That format is useful for debugging, diffs, tests, and
disassembly, but it makes the runtime depend on a reader before it can load
bytecode. The goal of this plan is to keep the printed archive representation
as the human-facing form while adding a compact binary representation that the
VM can load directly.

This is a normal project design note, not an OpenSpec change. Future work
should update this document or split out stable references as the binary format
settles.

## Goals

- Keep the existing archive semantics: archive sections, unit metadata,
  code-object entries, local `co-ref` references, labels, and init selection.
- Let runtimes load compiled bytecode without depending on the Scheme or CL
  reader.
- Reduce startup and reload time by avoiding text parsing and large
  intermediate sexp trees.
- Keep `.ecec` inspectable through a printed/disassembled representation.
- Use stable numeric operation ids from `operations.def` for encoded
  register-machine operations.
- Make the CL and WASM runtimes converge on the same compiled archive model.

## Non-Goals

- Replacing ECE source reading. Source `.scm` files still need the ECE reader.
- Changing the register-machine instruction set.
- Changing the executor's semantic model or procedure/environment shapes.
- Removing printed archive output from tooling.
- Designing a general-purpose binary Scheme object format for every use case.

The binary format should be a compiled archive codec. It may contain a small
typed datum codec for constants and metadata, but the dominant structure should
be archive and instruction aware.

## Current Format Boundary

The current compiler emits archive sexps shaped roughly as:

```scheme
(:ecec-archive
  :version 2
  :file "foo.scm"
  :entries ((:code-object
              :name foo
              :arity (("x") . 0)
              :source-loc #f
              :labels ((L1 . 3))
              :instructions ((assign val (const 42))
                             (halt)))))
```

The main boundaries are:

- `src/compilation-unit.scm` emits archive sexps and can parse them back into
  code objects.
- `src/runtime.lisp` has a CL-side archive parser so boot can load
  `bootstrap/bootstrap.ecec` before ECE code is available.
- `wasm/runtime.wat` and `wasm/glue.js` have archive loading paths for browser
  execution.
- `src/disassemble.scm` prints code objects and compiled procedures from live
  runtime values.
- Native-zone generation reads archive text today and should eventually work
  from materialized archive/code-object data instead.

The new binary codec should sit at this archive boundary. Compiler internals can
continue to build code objects and archive descriptors in the current way.

## Proposed Model

There are two representations of the same compiled archive:

1. Printed archive representation
   - Reader-compatible sexp text.
   - Used for debugging, golden tests, diffs, documentation, and disassembly.
   - May be emitted explicitly by developer commands.

2. Binary archive representation
   - Byte-oriented, versioned, and self-describing enough for disassembly.
   - Loaded directly by the VM.
   - Preferred for bootstrap, app bundles, and live reload.

The loader should not decode binary to a full archive sexp and then call the
old parser on the hot path. It should materialize code objects directly:

```text
bytes -> archive sections -> code-object vector -> executable code objects
```

A separate debug path can decode binary back to printed archive text.

## File Identity and Versioning

The binary format needs an unmistakable magic header and explicit versions.

Tentative header:

```text
magic           "ECEC\0BIN"
codec-version   u16
archive-version u16
flags           u32
section-count   u32
```

Initial choices:

- `codec-version = 1` for the binary byte layout.
- `archive-version = 3` for the semantic archive format if we decide binary is
  the new archive generation. If the semantics stay identical to current
  archive version 2, this can remain `2` and only the codec version changes.
- Multi-byte integers should use one byte order everywhere. Big-endian is a
  reasonable default because it is explicit and portable.

Open question: whether the file extension stays `.ecec` and the loader
auto-detects binary by magic bytes, or whether binary gets a separate extension
such as `.ececb`. Staying with `.ecec` keeps the user model simple, while a
separate extension makes raw file type obvious. The loader should be able to
detect both during migration either way.

## Archive Section Encoding

Each binary archive section should encode normalized archive metadata followed
by code-object entries.

Required fields:

- `kind`, default `:file`
- `unit-id`, explicit or synthesized from `file`
- `file` or `source` provenance
- `phase`, default `0`
- `imports`, default `()`
- `exports`, default `:all`
- `init`, default `0`
- `entries`

This mirrors the module/archive direction documented in
`docs/architecture/module-and-archive-plan.md`. Code-object identity should be
`(unit-id . index)`, not a filename-only key.

## Symbol and Datum Encoding

The codec needs a compact way to represent constants, metadata, names, module
ids, arity records, and labels.

Use a per-file or per-section symbol table:

```text
symbol-count u32
symbols:
  package-tag u8
  byte-length u32
  utf8-bytes
```

Package tags can start small:

- `0`: ECE symbol
- `1`: keyword-style ECE symbol such as `:file`
- `2`: uninterned/generated label symbol
- `3`: reserved

Datum tags should cover only what compiled archives need:

- nil
- `#t`
- `#f`
- integer
- float
- character, if needed by compiled constants
- symbol table reference
- string
- pair/list
- vector
- `co-ref` local code-object reference

The datum codec is not intended to be the public save/restore format. Save and
restore can share pieces later if that proves useful, but compiled archives
should stay optimized around code-object loading.

## Instruction Encoding

Instructions should be encoded with fixed instruction tags and compact operand
tags instead of generic list structure.

Instruction tags:

```text
0x01 assign
0x02 test
0x03 perform
0x04 save
0x05 restore
0x06 goto
0x07 branch
0x08 halt
```

Register ids should be a small enum:

```text
0 val
1 env
2 proc
3 argl
4 continue
5 stack
```

Operation references should use stable ids from `operations.def`. The binary
writer and readers must treat that manifest as the source of truth. New
operations can be added, but ids must not be reused.

Operand tags:

```text
reg       register-id
const     datum
op        operation-id
label     local-pc or label-id
co-ref    local code-object index
```

For execution, branch and goto labels can be encoded as local PCs. For
disassembly, label names should still be available through the code object's
label table. That keeps execution compact without making debug output opaque.

## Code Object Encoding

Each code-object entry should encode:

- optional name
- optional arity
- optional source location
- label table
- instruction count
- encoded instructions

Loading should allocate all code-object skeletons first, then patch local
`co-ref` constants to actual code-object values. This preserves the current
two-pass archive materialization model and handles nested lambdas cleanly.

## Loader Plan

### Phase 1: Shared Format Helpers

- Add a maintained design/test fixture for a tiny archive with one code object.
- Implement binary writer helpers for integers, strings, symbols, datums, and
  encoded instructions.
- Implement binary reader helpers that can round-trip the fixture to printed
  archive text for debugging.

### Phase 2: CL Runtime Loading

- Teach `load-ecec-file` to detect the binary magic header.
- Add a CL binary archive loader that materializes code objects directly.
- Register code objects under `(unit-id . index)` as the text loader does.
- Attach existing native-zone functions after binary materialization.
- Keep text archive loading as a compatibility and developer path.

### Phase 3: Compiler and Build Pipeline

- Add explicit APIs for binary and printed output, for example:
  - `compile-system` emits the default load artifact.
  - `compile-system/sexp` or a CLI flag emits printed archive text.
  - `compile-system/binary` can exist during migration if helpful.
- Regenerate bootstrap as binary once the loader is stable.
- Update install and packaging paths to copy binary `.ecec` byte-for-byte.
- Update golden tests to compare printed/disassembled output rather than raw
  binary bytes.

### Phase 4: WASM Runtime Loading

- Add a byte-oriented archive loader in `wasm/runtime.wat`.
- Change browser glue to fetch compiled archives with `Response.arrayBuffer()`
  and pass the resulting `ArrayBuffer` to the loader.
- Load binary archives into code objects without JavaScript parsing archive
  sexps.
- Keep or add a debug path that can request printed archive output.

### Phase 5: Native-Zone Generation

- Stop making native-zone generation depend on archive text parsing.
- Let zone generation consume materialized archive sections or a shared
  archive reader abstraction.
- Verify binary and printed archive forms produce the same native-zone keys and
  code-object fingerprints.

### Phase 6: Cleanup

- Remove stale `.ecec -> .ececb` conversion code after the new path replaces it.
- Simplify reader dependencies in the runtime once bootstrap and app loading no
  longer need archive sexp parsing on the hot path.
- Keep printed archive/disassembly commands as first-class developer tools.

## Disassembly Plan

The disassembler should become the bridge between compact runtime data and the
readable archive model.

Desired surfaces:

```scheme
(disassemble proc)
(disassemble code-object)
(disassemble 'global-procedure-name)
(disassemble-file "app.ecec")
(disassemble-file "app.ecec" ':with-hex #t)
```

Behavior:

- For live code objects, return or print the readable register-machine
  instructions as today.
- For binary files, decode enough structure to print archive metadata, code
  object entries, labels, and instructions.
- With `:with-hex #t`, include byte offsets or short hex spans next to the
  printed instruction representation.
- Prefer returning a string from the core formatter, with printing as a wrapper.

Example shape:

```text
; archive unit prelude, entry 0, init
; code-object <anonymous>, 2 instructions
0000  01 00 ...  (assign val (const 42))
0001  08         (halt)
```

The printed representation should be good enough that losing raw sexp output as
the default artifact does not make debugging worse.

## Testing Strategy

- Unit-test integer, string, symbol, datum, instruction, and section codecs.
- Round-trip small code objects:
  - code object -> printed archive -> binary -> printed archive
  - binary -> code objects -> disassembly
- Compare execution results for text-loaded and binary-loaded archives.
- Test nested lambdas and `co-ref` patching.
- Test module metadata, imports, exports, and non-zero init index.
- Test native-zone key compatibility.
- Test bootstrap loading from binary.
- Add a size and load-time smoke measurement for bootstrap and a representative
  app bundle.
- Add malformed binary tests for bad magic, version mismatch, truncated file,
  invalid operation id, invalid register id, invalid code-object index, and bad
  init index.

## Migration Notes

During migration, the runtime should accept both printed and binary archives.
This keeps developer workflows stable while bootstrap and packaging move over.

Likely order:

1. Binary reader/writer exists but default output remains printed text.
2. CL can load either format.
3. Binary output becomes available behind an explicit compile flag or helper.
4. Bootstrap switches to binary.
5. App packaging switches to binary by default.
6. WASM switches to binary archive loading.
7. Text archive loading remains as a developer/debug compatibility path.

## Open Questions

- Should binary archives keep the `.ecec` extension and rely on magic-byte
  detection, or use `.ececb`?
- Should the binary format store label names for all labels, or only labels
  needed for disassembly?
- Should source locations be mandatory in binary output once diagnostics mature?
- Should values use fixed-width integers first, or variable-length integers for
  smaller files?
- Should the first implementation encode operation ids directly, or include an
  operation table section for extra validation?
- How much of the binary datum codec should be shared with save/restore later?

## Future Checklist

- [x] Finalize magic header, byte order, and version fields.
- [x] Define exact datum tags and instruction tags.
- [x] Add binary codec helpers.
- [x] Add binary archive writer.
- [x] Add binary archive reader for debug round-tripping.
- [x] Add CL direct materializer and loader detection.
- [x] Add disassemble-file support for binary archives.
- [x] Add compiler/build flags for binary vs printed output.
- [ ] Switch bootstrap to binary after loader tests pass.
- [x] Update native-zone generation to avoid depending on archive text.
- [ ] Add WASM byte-oriented binary archive loader.
- [ ] Switch browser packaging/reload to fetch bytes.
- [ ] Remove obsolete `.ecec -> .ececb` conversion code.
