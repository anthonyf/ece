## Context

The README is the primary user-facing documentation for ECE. It was written when ECE used binary `.ececb` files and lacked `syntax-rules`, `browser-lib`, and the `ece-build` CL target. Several facts have drifted (line counts, function names) and the document doesn't highlight what makes ECE architecturally distinctive.

Current README structure:
```
Key Features → Architecture (CL / WASM / Modules table) → Language Overview →
Continuations → Use Cases → Getting Started (setup, REPL, embedding, testing, building, bootstrap)
```

## Goals / Non-Goals

**Goals:**
- Fix all factual errors so code examples actually work
- Document features that exist but are missing from the README
- Add a "What Makes ECE Different" subsection that explains how the explicit-stack architecture enables continuations, TCO, and serialization
- Keep the README concise and scannable

**Non-Goals:**
- Rewriting the README from scratch or changing its overall structure
- Adding tutorial content or extended examples
- Documenting internal APIs or implementation details beyond what's user-facing

## Decisions

### 1. Place "What Makes ECE Different" after WASM Runtime, before Shared ECE Modules

The new subsection goes under Architecture because the differentiators are architectural consequences (explicit stack → continuations/TCO/serialization). Placing it before the modules table means readers hit the "why this matters" framing before the "what's in it" details.

Alternative: fold into the opening paragraph. Rejected because the differentiators need enough space to explain the causal chain (explicit stack → consequence), which would bloat the intro.

### 2. Update macro description to cover both systems

The Key Features bullet currently says "Hygienic-ish macros — `define-macro`...". This will become two sub-points: `define-macro` (CL-style, unhygienic) and `define-syntax`/`syntax-rules` (R7RS hygienic pattern-matching). The "hygienic-ish" qualifier goes away since ECE now has proper hygienic macros.

### 3. Remove `fmt` and `lines` rather than implement them

These are not standard Scheme functions. They were leftover references from IF game examples and never existed in ECE source. Removing from docs is correct; no code change needed.

### 4. Consolidate test documentation to just `make test`

Since `make test` runs the full suite (rove, ECE, WASM, conformance, golden, web-server), showing `make test-wasm` separately is misleading. Replace with a single `make test` line that lists what it covers, and mention individual targets can be run separately.

## Risks / Trade-offs

- **Line counts will drift again** → Acceptable; "~2,300" and "~6,500" are approximate and won't need updating until a major change. Using `~` signals these are ballpark.
- **New subsection adds length** → The README is already comprehensive. A focused 8-10 line subsection is worth it for positioning ECE's unique value.
