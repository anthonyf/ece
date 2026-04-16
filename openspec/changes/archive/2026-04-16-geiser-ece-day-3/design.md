## Context

Day 2 (PR #159) shipped symbol completions via `%global-env-symbols` and a custom CAPF function that queries the REPL through comint. Autodoc is the next Geiser feature — it shows function signatures in the minibuffer as the cursor moves through a call form.

The key constraint is that ECE's compiled procedures don't store parameter names. The compiler processes `(lambda (x y) body)` and creates a compiled-procedure object with just an entry address and captured environment. Parameter names are used to set up `extend-environment` at call time but are discarded from the procedure object itself. Procedure *names* are tracked separately via `*procedure-name-table*` (populated by `%procedure-name-set!` at assembly time).

For host primitives, arity is stored in `primitives.def` (third column) but parameter names exist only in the `define-host-primitive` templates in `src/primitives.scm`.

## Goals / Non-Goals

**Goals:**

- `eldoc-mode` shows parameter names in the minibuffer when cursor is inside a function call.
- Works for compiled procedures defined via `(define (name params...) body)`.
- Works for host primitives (shows arity, best-effort parameter names).
- Parameter metadata persists through `.ecec` bootstrap — available for all prelude/compiler functions.

**Non-Goals:**

- Autodoc for local `let`-bound lambdas — only globally-defined procedures.
- Type information or return type hints — ECE is dynamically typed.
- Documentation strings — no docstring convention exists yet.
- Jump-to-definition (day 5, needs source locations).
- Macro parameter display — macros don't have runtime callable objects.

## Decisions

### Decision 1: New `*procedure-params-table*` mirroring `*procedure-name-table*`

**Choice:** Add a CL-side `*procedure-params-table*` hash table mapping entry addresses to `(param-names . rest?)` pairs. Populated at assembly time via a new `%procedure-params-set!` primitive.

**Rationale:** This follows the exact pattern of `*procedure-name-table*` + `%procedure-name-set!` which already works through the .ecec bootstrap pipeline. The assembler already emits `%procedure-name-set!` after each lambda — adding `%procedure-params-set!` in the same location is minimal change.

**Alternatives considered:**
- **Store params in the procedure object itself** — would require changing the `(compiled-procedure entry env)` structure to a 4-element list, breaking all existing accessors and .ecec files. Too invasive.
- **Parse the instruction sequence at runtime** — the `extend-environment` call at lambda entry contains the parameter count, but not names. Fragile and incomplete.

### Decision 2: Compiler emits parameter metadata at define-time

**Choice:** When the compiler compiles `(define (name params...) body)`, the assembler emits `(perform (op %procedure-params-set!) (const entry) (const (params . rest?)))` alongside the existing name registration.

**Rationale:** The assembler already has the parameter list available (it's in the lambda form). The cost is one hash-table insertion per defined procedure.

### Decision 3: Autodoc via direct REPL query (same as completions)

**Choice:** Wire `geiser-autodoc` through the same `comint-redirect-send-command-to-process` mechanism used for completions in day 2.

**Rationale:** Day 2 discovered that Geiser's `geiser-eval--send/wait` doesn't connect to our REPL process. The comint-redirect workaround works reliably. Autodoc has the same constraint.

### Decision 4: Geiser autodoc response format

**Choice:** Return `((name (args (required param1 param2 ...) (optional) (key))))` for each queried identifier. For rest-parameter procedures like `(define (foo x . rest) ...)`, include `rest` in a separate group.

**Rationale:** This is the format Geiser's `geiser-autodoc--autodoc` function expects. The `required`/`optional`/`key` structure is what eldoc-mode uses to highlight the current argument position.

## Risks / Trade-offs

- **[Risk] Bootstrap size increase.** Every `define` now emits an additional `%procedure-params-set!` instruction. For ~400 defined procedures, this adds ~400 instructions to the .ecec files. Estimated size increase: <5KB. Negligible.
- **[Risk] Two-pass bootstrap for compiler change.** Modifying the compiler/assembler to emit param metadata requires the same two-pass bootstrap as any compiler change. Standard procedure, ~4 minutes total.
- **[Trade-off] No autodoc for anonymous lambdas.** Only procedures registered in the global env via `define` get autodoc. Lambdas passed as arguments or stored in local bindings have no global name to look up. This matches chibi's Geiser autodoc behavior.
- **[Trade-off] Primitive parameter names are best-effort.** Host primitives have arity from `primitives.def` but parameter names only if we add a separate mapping. Day 3 can use generic names (`arg1`, `arg2`, `...args`) for primitives and refine later.
