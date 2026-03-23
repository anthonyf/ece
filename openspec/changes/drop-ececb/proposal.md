## Why

ECE currently maintains two compiled formats: `.ecec` (text s-expressions) for the CL runtime and `.ececb` (custom binary) for the WASM runtime. This means maintaining a binary encoder (`ecec-to-binary.scm`, 358 lines), a binary decoder (`parseBinary` in `glue.js`, 150 lines), JS instruction builders (`buildValue`/`buildInstruction`/`loadParsed`, 140 lines), a binary format spec (`ececb-format.md`, 187 lines), and a build step converting between them. The binary format exists only because the WASM runtime couldn't read s-expressions — but it can with a WAT-native reader.

Additionally, compiler-generated labels like `mc-primitive-branch-11163` account for 23% of .ecec file size (~640 KB across all bootstrap files). Shortening them to `L11163` eliminates this overhead at the source.

## What Changes

- **Add WAT s-expression reader** (~365 lines) to `runtime.wat` — reads .ecec text from linear memory, parses s-expressions, and loads instructions directly into compilation spaces
- **Shorten compiler labels** — change `mc-make-label` to emit `L<counter>` instead of `mc-<name>-<counter>` (~600 KB savings)
- **Remove binary encoder** — delete `src/ecec-to-binary.scm` (358 lines)
- **Remove binary decoder/builders** — remove `parseBinary`, `buildValue`, `buildOperand`, `buildOperandList`, `buildInstruction`, `loadParsed` from `glue.js` (~290 lines)
- **Remove binary format spec** — delete `wasm/ececb-format.md` (187 lines)
- **Remove .ececb files** — delete all `bootstrap/*.ececb` files
- **Update sandbox build** — embed .ecec (base64) instead of .ececb
- **Update sandbox boot** — call WAT reader instead of JS parseBinary+loadParsed
- **Update test runner** — load .ecec directly via WAT reader
- **Update Makefile** — remove ecec-to-binary step from `make bootstrap`

## Capabilities

### New Capabilities
- `wat-ecec-reader`: WAT-native s-expression reader for loading .ecec files into WASM compilation spaces

### Modified Capabilities

(none — same bootstrap behavior, different loading mechanism)

## Impact

- **runtime.wat**: +~365 lines (s-expression reader + loader)
- **glue.js**: -~290 lines (binary parser + instruction builders removed)
- **src/ecec-to-binary.scm**: deleted (-358 lines)
- **wasm/ececb-format.md**: deleted (-187 lines)
- **bootstrap/**: .ececb files deleted, .ecec files ~23% smaller (short labels)
- **Sandbox size**: ece-bootstrap.js changes from ~1.5 MB (binary base64) to ~2.8 MB (text base64 with short labels). Acceptable for `file://` use; gzip-friendly for served deployments.
- **Build**: simpler — no ecec-to-binary conversion step
- **Risk**: Low — mechanical replacement with test suite validation. The WAT reader only needs to handle the limited .ecec grammar (no quasiquote, interpolation, hash literals, etc.).
