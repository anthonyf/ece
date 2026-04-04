## Why

The README has accumulated factual errors (wrong function names, stale line counts, removed file formats) and is missing documentation for significant features added since it was last updated (syntax-rules, browser-lib, CL build target). ECE's key architectural differentiators — first-class continuations, full TCO, serializable continuations, and the small dual-runtime kernel — also deserve a dedicated subsection rather than being scattered across the document.

## What Changes

### Fix factual errors
- Replace `load-continuation` with `load-saved` in the serializable continuations example
- Replace `.ececb` with `.ecec` and update "per-file compiled boot" to "single-bundle bootstrap"
- Remove `fmt` and `lines` from Standard Library listing (never existed; leftover IF game references)
- Update CL runtime line count from "~2,100" to "~2,300" (actual: 2,265)
- Update WASM runtime line count from "~4,500" to "~6,500" (actual: 6,520)

### Add missing documentation
- Add `syntax-rules.scm` and `browser-lib.scm` to the Shared ECE Modules table
- Update macro Key Feature to describe both `define-macro` (CL-style unhygienic) and `define-syntax`/`syntax-rules` (R7RS hygienic pattern-matching)
- Add `define-syntax` to Core Forms list
- Document `--target cl` option for `ece-build`

### Fix misleading test documentation
- Update `make test` comment to reflect full suite (rove, ECE, WASM, conformance, golden, web-server)
- Remove separate `make test-wasm` line (already included in `make test`)

### Add "What Makes ECE Different" architecture subsection
- New subsection under Architecture highlighting: first-class continuations, full TCO, serializable continuations, dual runtime with small kernel

## Capabilities

### New Capabilities
- `readme-corrections`: Factual fixes to existing README content (function names, line counts, file formats, standard library listing, test commands)
- `readme-architecture-differentiators`: New "What Makes ECE Different" subsection explaining how the explicit-stack register machine enables continuations, TCO, and serialization
- `readme-missing-docs`: Documentation for features not currently covered (syntax-rules, browser-lib, CL build target)

### Modified Capabilities

(none — no existing spec-level behavior changes)

## Impact

- `README.md` is the only file changed
- No code changes, no API changes, no dependency changes
