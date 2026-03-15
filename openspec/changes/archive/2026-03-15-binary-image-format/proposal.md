## Why

The test suite takes ~9 minutes locally (12 in CI) because image round-trip tests perform 45 save/load cycles against the 220k-line text-based flat image format. Each cycle parses 220k lines of text one-by-one, then makes a second pass to resolve operations to function pointers. A binary format eliminates text parsing overhead and the resolve-operations pass, dramatically cutting test time. It also produces smaller images (~620KB vs 2MB).

## What Changes

- **New binary image format**: Compact binary encoding with a symbol table, typed instruction encoding (register/operation enums), and a binary stack-machine format for data sections (environment, macros, parameter table). Deserialization builds resolved instructions directly in a single pass.
- **New disassembler**: Converts binary images to human-readable instruction listings showing reconstituted register machine instructions, labels, environment bindings, and metadata. Better for inspection than the raw text format ever was.
- **Replace text format as default**: `ece-save-image` and `ece-load-image` produce/consume binary format. The text serializer code is retained and repurposed as the disassembler's output renderer.
- **Bootstrap image converted**: `bootstrap/ece.image` ships in binary format.

## Capabilities

### New Capabilities
- `binary-image-serializer`: Binary serialization of ECE images — symbol table, typed instruction encoding, binary data section
- `binary-image-deserializer`: Single-pass binary deserialization that builds resolved instructions directly
- `image-disassembler`: Human-readable disassembly of binary images showing register machine instructions, labels, and environment

### Modified Capabilities
- `flat-image-serializer`: Repurposed as disassembler output format (no longer the primary serialization path)
- `flat-image-deserializer`: Retained for backward compatibility with old `.image` files, but no longer the default load path
- `image-serialization`: Updated to use binary format by default

## Impact

- `src/runtime.lisp`: Major changes to serialization/deserialization functions, new binary format functions, new disassembler
- `src/boot.lisp`: `ece-load-image` call unchanged (same API, different format underneath)
- `bootstrap/ece.image`: Regenerated in binary format
- `tests/ece.lisp`: All 45 image round-trip tests run faster (no code changes needed — same API)
- Test suite runtime: expected reduction from ~9 min to ~2-3 min locally
