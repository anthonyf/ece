## Why

The current .ecec format stores one instruction list per top-level source expression — a file with 50 top-level forms produces 50 separate instruction units. This makes bytecode hard to read, hard to diff, and adds complexity to both loaders (CL and WASM must inject env-reset instructions between units and resolve labels across boundaries). Flattening to one instruction vector per file makes the format human-readable, enables golden-file compiler output tests (diff against checked-in expected output), and simplifies the path to the native compiler whose input will be a flat instruction stream.

## What Changes

- **Flatten .ecec format** — `compile-file` emits a single merged instruction list per file instead of one per top-level expression. Env-reset instructions between expressions become explicit in the merged list. The ecec-header remains unchanged.
- **Simplify loaders** — CL loader reads one instruction list instead of looping. WASM loader does a single-pass scan instead of multi-unit two-phase processing.
- **Two-pass bootstrap** — existing .ecec files use the old format. First pass: boot from old .ecec, recompile with new `compile-file`. Second pass: boot from new flat .ecec, recompile again to verify idempotence.
- **Add golden-file compiler tests** — compile a fixed set of known Scheme expressions, write the instruction output to golden files checked into the repo. CI diffs compiler output against golden files and fails on unexpected changes.
- **Pretty-print .ecec output** — with one flat list, format instructions one-per-line for readability and better git diffs.

## Capabilities

### New Capabilities
- `flat-ecec-format`: Single flat instruction vector per .ecec file with explicit env-reset boundaries and one-per-line instruction formatting
- `compiler-golden-tests`: Golden-file tests that compile known expressions and diff against checked-in expected instruction output

### Modified Capabilities
- `compiled-unit`: `compile-file` merges all units into one flat instruction list instead of emitting separate units
- `compile-file`: Output format changes from multi-unit to single flat list with pretty-printed instructions

## Impact

- `src/compilation-unit.scm` — `compile-file` and `write-compiled-unit` change to emit flat merged output
- `src/runtime.lisp` — `load-ecec-file` simplifies to single-read
- `wasm/runtime.wat` — `load_ecec` simplifies to single-pass scan
- `wasm/glue.js` — may need minor updates for new format parsing
- `bootstrap/*.ecec` — all regenerated in new flat format
- **BREAKING**: Old multi-unit .ecec files will not load with the new loader. Mitigated by two-pass bootstrap.
