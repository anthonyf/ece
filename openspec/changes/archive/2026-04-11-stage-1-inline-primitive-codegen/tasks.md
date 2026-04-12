## 1. Foundations and Refactoring

- [x] 1.1 Extract `expand-host-primitive-template` from `src/codegen-cl.scm` as a public entry point reusable by the inline codegen
- [x] 1.2 Add a `host-primitive-cl-body` helper that, given a primitive name and a list of CL forms representing argument values, returns the inlined template body
- [x] 1.3 Ensure existing `bootstrap/primitives-auto.lisp` regenerates byte-identically after the refactor (no behavior change)
- [x] 1.4 Add a small `*compiled-zone-functions*` defvar in `src/runtime.lisp` keyed by space symbol → CL function

## 2. Tiny Test Space (Walking Skeleton)

- [x] 2.1 Hand-write a 5-10 instruction toy ECE space (`tests/zone-toy.scm` or similar) doing fixed arithmetic with one primitive call
- [x] 2.2 Hand-write the equivalent CL `(defun zone-toy ...)` `tagbody` form that produces the same result
- [x] 2.3 Run the toy space through the existing interpreter; record the final register state
- [x] 2.4 Run the hand-written compiled-zone function; confirm identical final register state
- [x] 2.5 Add a CL test that invokes both paths and asserts equality — this becomes the parity-test seed

## 3. Codegen MVP

- [x] 3.1 Create `src/codegen-cl-inline.scm` with a top-level `(generate-zone-cl! space-name output-path)` entry point
- [x] 3.2 Implement an instruction walker that iterates over a space's instruction vector via `%space-instruction-length` / `%space-source-ref`
- [x] 3.3 Implement a per-instruction CL emitter for `assign`, `test`, `branch`, `goto`, `save`, `restore`, `perform`, `halt`
- [x] 3.4 Implement label collection and `tagbody` PC labeling so jumps land on the right form
- [x] 3.5 Implement primitive call-site detection: track preceding `(assign proc (const (primitive ID)))` so the codegen can substitute the matching template
- [x] 3.6 Implement the inline substitution: call `host-primitive-cl-body` and splice the result into the call-site form
- [x] 3.7 Implement the fall-back path that emits `(funcall #'ece-NAME args...)` when the primitive identity is not statically known
- [x] 3.8 Implement operation-call inlining via the operations dispatch table
- [x] 3.9 Run the codegen on the toy space from §2; diff against the hand-written reference until byte-equivalent or clearly equivalent
- [x] 3.10 Iterate on edge cases (empty space, space with no primitive calls, space with only operation calls)

## 4. Runtime Hook

- [x] 4.1 Add a check at the top of `execute-instructions` that consults `*compiled-zone-functions*` and dispatches to the registered function if found
- [x] 4.2 Define the calling convention: compiled-zone function takes `(initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)` and returns `(values pc val env proc argl continue stack)`
- [x] 4.3 Handle cross-space jumps from compiled to interpreted: when the compiled-zone function returns because `continue` targets another space, the executor picks up and runs the dispatch loop on the target space
- [x] 4.4 Handle cross-space jumps from interpreted to compiled: when the dispatch loop sees a `goto` to a space that has a registered compiled-zone function, it invokes that function with current register state
- [x] 4.5 Confirm `*executing-space-id*` is correctly updated at every transition (test by capturing a continuation inside compiled code)
- [x] 4.6 Verify the safety check in §4.1 is a single comparison on the hot path so the dynamic-zone overhead is negligible

## 5. Continuation and dynamic-wind Parity

- [x] 5.1 Write a parity test: capture a continuation inside the compiled zone, resume it from interpreted code, assert identical result
- [x] 5.2 Write a parity test: capture a continuation inside interpreted code, resume it from the compiled zone, assert identical result
- [x] 5.3 Write a parity test: `dynamic-wind` whose body crosses the zone boundary multiple times; assert wind/unwind ordering is identical to all-interpreted
- [x] 5.4 Write a parity test: `(serialize-continuation ...)` → `(deserialize ...)` round-trip for a continuation captured in compiled code; assert resumed state matches
- [x] 5.5 Write a parity test: REPL `(define foo ...)` redefinition takes effect for compiled-zone callers without recompilation
- [x] 5.6 Run all five parity tests against the toy space; fix any divergence

## 6. First Real Space

- [x] 6.1 Pick a candidate real space — start with the smallest sensible one (likely a small subset of `prelude` or a dedicated benchmark space)
- [x] 6.2 Generate the compiled-zone file for that space
- [x] 6.3 Inspect the generated file: spot-check that primitive calls were inlined where expected, that fall-back funcalls only appear for genuinely-dynamic call sites, and that the `tagbody` is well-formed
- [x] 6.4 Load the compiled-zone file alongside the runtime; run the parity test harness against every test program that exercises the chosen space
- [x] 6.5 Triage any failures (typos in the codegen, missing instruction handlers, register state mismatches)
- [x] 6.6 If `tagbody` size limits hit, split the function into multiple sub-tagbodies returning continuation PCs
- [x] 6.7 Iterate until parity is 100% for the chosen space

## 7. Build Integration

- [x] 7.1 Add a Makefile rule `bootstrap/<space>-zone.lisp: primitives.def src/primitives.scm src/codegen-cl.scm src/codegen-cl-inline.scm src/<space>.scm`
- [x] 7.2 Wire the rule into `make bootstrap` so generated files refresh as part of the standard build
- [x] 7.3 Add a runtime loader that scans `bootstrap/*-zone.lisp` and loads each, after `bootstrap/primitives-auto.lisp` and before `(boot-from-compiled)`
- [x] 7.4 Verify two-pass regeneration: delete the file, run `make bootstrap`, confirm regeneration produces a byte-identical file
- [x] 7.5 Document the regeneration command in the header of the generated file and at the top of `src/codegen-cl-inline.scm`
- [x] 7.6 Confirm the generated file's header clearly warns against hand-editing

## 8. Validation

- [x] 8.1 Run `make test-rove` — confirm zero failures
- [x] 8.2 Run ECE self-hosted test suite (common + cl-only) — confirm zero failures
- [x] 8.3 Run conformance test suite — confirm zero failures
- [x] 8.4 Run WASM test suite — confirm zero failures (no regressions; WASM still uses the interpreted path)
- [x] 8.5 Confirm `make bootstrap` rebuilds the entire `bootstrap/` tree cleanly from a cold state
- [x] 8.6 Add a smoke test that loads each `bootstrap/*-zone.lisp` file and asserts the corresponding `*compiled-zone-functions*` entry is `fboundp`
- [x] 8.7 Add a determinism test that regenerates the compiled-zone file twice and verifies byte-identical output
- [x] 8.8 Confirm the parity-test harness covers REPL function redefinition end to end

## 9. Cleanup and Documentation

- [x] 9.1 Verify `src/runtime.lisp` line count delta is small (<100 lines added) — Stage 1 is mostly new files, not runtime surgery
- [x] 9.2 Add a brief note in `src/runtime.lisp` near `*compiled-zone-functions*` describing the dual-zone model and pointing at `src/codegen-cl-inline.scm`
- [x] 9.3 Document the calling convention for compiled-zone functions in a comment block in `src/codegen-cl-inline.scm`
- [x] 9.4 Check that no stale references to a removed `*compiled-zone-function*` (singular) or earlier compile-to-host attempts remain in the codebase
- [x] 9.5 Update `openspec/specs/host-primitive-templates/spec.md` if any clarifying note about template-as-IR consumption is warranted (likely not — Stage 0's spec already covers the template format)
