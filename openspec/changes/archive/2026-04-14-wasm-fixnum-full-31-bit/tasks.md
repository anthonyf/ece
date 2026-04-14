## 1. New struct types in wasm/runtime.wat

- [x] 1.1 Add `(type $char (struct (field $codepoint i32)))` in the type section near `$primitive` and `$pair`.
- [x] 1.2 Add five empty struct types for the specials: `$false-type`, `$true-type`, `$nil-type`, `$eof-type`, `$void-type`. Each is `(struct)` with no fields.
- [x] 1.3 Add `$char-array` array type: `(type $char-array (array (ref $char)))` for the ASCII intern table.

## 2. Replace i31-tagged globals with struct singletons

- [x] 2.1 Replace the five `(global $false ... (ref.i31 ...))` / `(global $true ...)` / `(global $nil ...)` / `(global $eof ...)` / `(global $void ...)` declarations with struct-instance globals: `(global $false (ref eq) (struct.new $false-type))`, etc.
- [x] 2.2 Update the tag-encoding comment block (lines 180-191) to describe the new scheme: i31ref is fixnums only; chars are `$char` structs; specials are singleton struct globals.
- [x] 2.3 Verify `ref.eq` call sites still compile — the parameter type is still `(ref eq)` so no changes should be needed at call sites, but grep to confirm.

## 3. ASCII char intern table

- [x] 3.1 Add `(global $ascii-chars (mut (ref null $char-array)) (ref.null $char-array))` near the other globals.
- [x] 3.2 Add `$init-ascii-chars` helper that allocates the 128-element `$char-array` and populates it by looping from 0 to 127, calling `struct.new $char (local.get $i)` into each slot.
- [x] 3.3 Call `$init-ascii-chars` from the module's start function (or whatever equivalent initialization hook exists — check `$runtime-init` or the `start` directive).

## 4. Rewrite core fixnum helpers

- [x] 4.1 `$make-fixnum`: change body to `(ref.i31 (local.get $n))` — remove the `i32.shl` by 1.
- [x] 4.2 `$fixnum-value`: change body to `(i31.get_s (local.get $v))` — remove the `i32.shr_s` by 1.
- [x] 4.3 `$is-fixnum`: simplify to `(ref.test (ref i31) (local.get $v))` — remove the secondary bit check.
- [x] 4.4 `$make-fixnum-or-float`: update the range check bounds from `-536870912`/`536870911` to `-1073741824`/`1073741823`.
- [x] 4.5 `$f64-to-ece-number`: update the f64 range check bounds to match. Note the comment explaining the range on lines 570-571 — update it to say `[-2^30, 2^30-1]`.

## 5. Rewrite char helpers

- [x] 5.1 `$make-char`: new body checks `cp < 128`; if so, `array.get $char-array (global.get $ascii-chars) cp`; else `struct.new $char (local.get $cp)`.
- [x] 5.2 `$char-codepoint`: change body to `(struct.get $char $codepoint (local.get $v))` — parameter type changes from `(ref i31)` to `(ref $char)`.
- [x] 5.3 `$is-char`: change body to `(ref.test (ref $char) (local.get $v))`.
- [x] 5.4 Audit call sites of `$char-codepoint` — they currently pass `(ref.cast (ref i31) v)` before calling. After the change, they must pass `(ref.cast (ref $char) v)` instead.

## 6. Audit direct i31 usages

- [x] 6.1 Grep `runtime.wat` for `i32.shl ... (i32.const 1))` and `i32.shr_s ... (i32.const 1))` — any site that manually encoded/decoded a fixnum by shifting. Replace with calls to `$make-fixnum` / `$fixnum-value`.
- [x] 6.2 Grep for `i31.get_s` / `i31.get_u` — any site that read an i31 directly. If the caller is extracting a fixnum, switch to `$fixnum-value`; if the caller is inspecting for a special or char, update for the new struct-based scheme.
- [x] 6.3 Grep for `(i32.const 11)` / `0x0B` / `(i32.const 15)` — the old char tag mask and low-4-bit mask. Any remaining uses should be deleted or repurposed.
- [x] 6.4 Grep for the old special i31 constants `(i32.const 1)` through `(i32.const 9)` in contexts other than the global initializers — unlikely but check.

## 7. Validate the runtime parses and builds

- [x] 7.1 `wasm-as --enable-gc --enable-reference-types wasm/runtime.wat -o wasm/runtime.wasm` — should assemble cleanly. Fix any syntax errors before continuing.
- [x] 7.2 `make wasm` — confirms the build target still works end-to-end.

## 8. Bootstrap regeneration

- [x] 8.1 Run `make bootstrap`. Confirm it completes without errors.
- [x] 8.2 Run `make bootstrap` a second time. Diff the second pass's `.ecec` outputs against the first pass — they MUST be byte-identical (self-hosting stability gate).
- [x] 8.3 Stage the regenerated `bootstrap/*.ecec` files.

## 9. Regression tests

- [x] 9.1 Create `tests/ece/common/test-fixnum-full-range.scm` with tests for:
  - Values `536870912`, `1073741823`, `-536870913`, `-1073741824` — round-trip through `(+ v 0)` / `(- v 0)` and assert identity. Previously these were float-boxes; now they're fixnums.
  - Display round-trip: `(string->number (number->string v))` = `v` for each.
  - `fixnum?` returns `#t` for each (previously returned `#f`).
  - `(+ 536870000 912)` = `536870912` and the result is a fixnum.
  - Overflow check: `(+ 1073741823 1)` = `1073741824`, result is NOT a fixnum (float-box), arithmetic still works.
- [x] 9.2 Verify `test-bitwise-large.scm` (PR #150) still passes.
- [x] 9.3 Verify `test-bitwise-variadic.scm` (PR #152) still passes.
- [x] 9.4 Verify `test-sha1.scm` still passes (RFC 3174 test vector for "abc").
- [x] 9.5 Verify `test-strings.scm` + `test-types.scm` + `test-misc.scm` — char handling must be unchanged.

## 10. Full validation gate

- [x] 10.1 `make test-ece` — CL-side ECE tests must all pass.
- [x] 10.2 `make test-wasm` — WASM tests must all pass, specifically including the new fixnum-full-range tests.
- [x] 10.3 `make test` — every suite (rove, ece, wasm, conformance, golden, web-server, web-apps) must pass with zero regressions.
- [x] 10.4 `make ece` — CL binary rebuilds.

## 11. Archive and commit

- [x] 11.1 Archive the change in-PR BEFORE merging per the archive-before-merge rule.
- [x] 11.2 Commit with a message describing the scope: "Move chars and specials off i31ref; widen fixnum range to full i31 signed [-2^30, 2^30-1]".
- [x] 11.3 Open a PR that:
  - Points at `project_wasm_fixnum_range.md` as the motivation and says the memory will be deleted on merge.
  - Lists the new struct types, the rewritten helpers, the ASCII intern table addition.
  - Confirms SHA-1 / bitwise-large / bitwise-variadic tests still pass.
  - Includes the two-pass bootstrap stability check result.
