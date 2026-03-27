## Context

ECE has a working `define-macro` system. Macros are compiled as lambdas and stored in `*compile-time-macros*`. The compiler dispatches macro expansion via `get-macro`/`set-macro!` at compile time. `gensym` is available in the prelude. The boot sequence loads `.ecec` files in order: prelude, compiler, reader, assembler, compilation-unit.

## Goals / Non-Goals

**Goals:**
- Implement `syntax-rules` conforming to R7RS section 4.3.2
- Implement `define-syntax` as the standard binding form
- Support ellipsis (`...`) patterns and templates for repeated elements
- Support `_` as a wildcard in patterns
- Provide automatic hygiene via gensym so introduced bindings don't capture user variables
- Implement entirely in ECE (`.scm` → `.ecec`), keeping the CL kernel unchanged
- Enable running published R7RS conformance tests that depend on `syntax-rules`

**Non-Goals:**
- `syntax-case` (R6RS low-level macro system) — much more complex, not needed for R7RS-small
- `let-syntax` / `letrec-syntax` — can be added later if needed
- Full Dybvig-style marks/substitutions hygiene — gensym-based hygiene is sufficient for practical use and is the approach used by Chicken (pre-5) and other production Schemes
- `identifier-syntax` (R6RS)

## Decisions

### 1. syntax-rules expands to define-macro

`define-syntax` generates a `define-macro` form. The pattern matcher and template instantiator are runtime helpers called by the generated macro body. This means:

- No compiler changes needed — the existing macro infrastructure handles everything
- `syntax-rules` macros and `define-macro` macros share the same macro table
- Macro shadowing by lexical variables works identically for both

**Alternative considered:** Adding `define-syntax` as a new special form in the compiler. Rejected because it would require compiler changes and duplicate the macro storage mechanism for no benefit.

### 2. Gensym-based hygiene (α-renaming)

When a `syntax-rules` template introduces a binding (e.g., `let`, `lambda` temporaries), the template instantiator wraps it in a `gensym` call. This prevents accidental capture of user variables.

This is "good enough" hygiene — it handles the common cases (temporary variables, helper bindings) but does not handle all R7RS edge cases around referential transparency of free variables in templates. Full hygiene would require marks/substitutions, which is significantly more complex.

**Alternative considered:** Explicit renaming (ER) macros as the primitive, with syntax-rules layered on top. This is what Chibi-Scheme does. Rejected for now because ECE already has `define-macro` as the primitive, and ER macros would be a larger change. Could be revisited later if full hygiene is needed.

### 3. Implementation as a single ECE source file

`src/syntax-rules.scm` compiles to `bootstrap/syntax-rules.ecec`. Contains:
- Pattern matching: `syntax-match` — matches an expression against a pattern, returning bindings or `#f`
- Ellipsis handling: collect repeated sub-matches into lists
- Template instantiation: `syntax-instantiate` — fills a template using matched bindings, applying gensym to introduced identifiers
- `syntax-rules` form: generates a lambda that tries each clause in order
- `define-syntax` form: wraps `syntax-rules` in `define-macro`

### 4. Boot order: after prelude, before user code

`syntax-rules.ecec` loads after prelude (needs `gensym`, `map`, `append`, etc.) and after compiler (needs `define-macro` infrastructure). In practice, it goes at the end of the boot sequence since it depends on the full environment being available but nothing in the bootstrap depends on it.

Boot order becomes: prelude → compiler → reader → assembler → compilation-unit → syntax-rules

### 5. Ellipsis support strategy

Ellipsis (`...`) in patterns matches zero or more repetitions. The matcher collects repeated sub-pattern bindings into lists. The template instantiator maps over these lists to produce repeated output.

Example:
```scheme
(define-syntax my-list
  (syntax-rules ()
    ((_ x ...) (list x ...))))

(my-list 1 2 3) → (list 1 2 3)
```

Nested ellipsis (ellipsis within ellipsis) is deferred — single-level ellipsis covers the vast majority of real-world usage.

## Risks / Trade-offs

**[Gensym hygiene is incomplete]** → Some R7RS edge cases around referential transparency won't pass. Mitigation: document known limitations; these are rare in practice and the Chibi test suite mostly tests the common cases. Can upgrade to ER macros later if needed.

**[No nested ellipsis initially]** → Some advanced `syntax-rules` patterns won't work. Mitigation: single-level ellipsis covers ~95% of real usage. Add nested support as a follow-up if conformance tests require it.

**[Boot sequence grows by one file]** → Minimal impact. One additional `.ecec` file adds negligible boot time.
