## 1. Fix Factual Errors

- [x] 1.1 Replace `load-continuation` with `load-saved` in serializable continuations example (line 128)
- [x] 1.2 Replace `.ececb` with `.ecec` in Key Features bullet (line 20) and change "per-file compiled boot" to "single-bundle bootstrap"
- [x] 1.3 Update `.ececb` to `.ecec` in Architecture intro paragraph (line 22-24)
- [x] 1.4 Remove `fmt` and `lines` from Standard Library listing (line 60)
- [x] 1.5 Update CL runtime line count from "~2,100" to "~2,300" (line 28)
- [x] 1.6 Update WASM runtime line count from "~4,500" to "~6,500" (line 32)

## 2. Add Missing Documentation

- [x] 2.1 Add `syntax-rules.scm` row to Shared ECE Modules table
- [x] 2.2 Add `browser-lib.scm` row to Shared ECE Modules table
- [x] 2.3 Update macro Key Feature bullet: remove "hygienic-ish", describe both `define-macro` and `define-syntax`/`syntax-rules`
- [x] 2.4 Add `define-syntax` to Core Forms listing
- [x] 2.5 Add CL target section for `ece-build` (after the web target sections)

## 3. Fix Test Documentation

- [x] 3.1 Update `make test` comment to list full suite (rove, ECE, WASM, conformance, golden)
- [x] 3.2 Remove separate `make test-wasm` line; add note that individual targets can be run separately

## 4. Add "What Makes ECE Different" Subsection

- [x] 4.1 Add new `### What Makes ECE Different` subsection after WASM Runtime, before Shared ECE Modules
- [x] 4.2 Write first-class continuations paragraph (explicit stack → call/cc captures full machine state)
- [x] 4.3 Write full TCO paragraph (all tail positions in constant stack space)
- [x] 4.4 Write serializable continuations paragraph (ECE data structures → serializable to disk)
- [x] 4.5 Write dual runtime / small kernel paragraph (same .ecec on CL and WASM, ~2,300 line kernel)
