## Context

The evaluator has a primitive system where CL functions are wrapped as `(primitive <cl-fn>)` and registered in `*primitive-procedure-names*` / `*primitive-procedure-objects*`. Some primitives map directly to CL functions (e.g., `+` → `cl:+`), while others use a dotted pair for renaming (e.g., `(null? . null)` → binds ECE `null?` to CL's `null`).

## Goals / Non-Goals

**Goals:**
- Add all primitives as simple entries in the existing primitive lists — no new evaluator machinery needed
- Use CL's existing functions where possible (e.g., `numberp`, `stringp`, `symbolp`, `eq`, `equal`, `mod`, `abs`, `min`, `max`, `evenp`, `oddp`, `plusp`, `minusp`, `zerop`)
- `boolean?` tests for `t` or `nil` since ECE uses CL's truthiness model

**Non-Goals:**
- `eqv?` (Scheme-specific, not needed with `eq?` and `equal?`)
- Char predicates (`char?`, etc.) — no character type in ECE yet

## Decisions

**Direct CL mapping via dotted pairs**: All new primitives map directly to CL functions using the existing `(ece-name . cl-name)` pattern. No wrapper functions needed.

Mapping table:
| ECE name | CL function |
|----------|-------------|
| `number?` | `numberp` |
| `string?` | `stringp` |
| `symbol?` | `symbolp` |
| `zero?` | `zerop` |
| `even?` | `evenp` |
| `odd?` | `oddp` |
| `positive?` | `plusp` |
| `negative?` | `minusp` |
| `eq?` | `eq` |
| `equal?` | `equal` |
| `modulo` | `mod` |
| `abs` | `abs` |
| `min` | `min` |
| `max` | `max` |

**`boolean?` needs a wrapper**: CL has no `booleanp` that checks for exactly `t` or `nil`. A simple lambda `(lambda (x) (or (eq x t) (eq x nil)))` handles this.

## Risks / Trade-offs

- [CL's `equal` is deeper than Scheme's — compares strings, arrays, etc.] → Fine for ECE's scope, strictly more capable
- [`symbol?` returns true for nil] → Consistent with CL; ECE uses nil as false/empty-list
