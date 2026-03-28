## Why

ECE's design principle is "anything that CAN be written in ECE SHOULD be written in ECE." Several primitives currently in host runtimes are pure algorithmic operations that don't need host-level access. Moving them to prelude.scm shrinks both host runtimes, directly supporting the WASM port goal (smaller CL kernel = easier rewrite). The WASM runtime already moved string ops (36-41) and `print` (66) to prelude; CL hasn't followed suit.

## What Changes

Move ~16 primitives from host runtimes to ECE prelude:

**Already in prelude for WASM — remove from CL host:**
- `string-downcase` (36), `string-upcase` (37), `string-split` (38), `string-trim` (39), `string-contains?` (40), `string-join` (41)
- `print` (66)

**New moves from both hosts to ECE:**
- `char-whitespace?` (47), `char-alphabetic?` (48), `char-numeric?` (49) — range checks on `char->integer`
- `equal?` (21) — recursive structural equality using `eq?`, `pair?`, `vector?`, `string=?`
- `eqv?` (174) — `eq?` plus numeric `=`
- `input-port?` (68), `output-port?` (69), `port?` (70) — tag checks on pair structure
- `gensym` (82) — counter + `string->symbol`

**Update primitives.def:**
- Change platform annotation from `core` to `ece` for migrated primitives to document they're now prelude-level

## Capabilities

### New Capabilities

- `ece-level-primitives`: Specification for which primitives are implemented in ECE prelude rather than host runtimes, and their ECE implementations

### Modified Capabilities

_None — all primitives keep the same external behavior. This is an implementation layer change only._

## Impact

- **src/prelude.scm**: Add ECE implementations of newly migrated primitives; existing string/print implementations already present for WASM
- **src/runtime.lisp**: Remove ~16 primitive wrapper implementations from CL dispatch tables
- **wasm/runtime.wat**: Remove ~6 primitive implementations (char classification, equality, port predicates, gensym) that are moving to prelude
- **primitives.def**: Update platform annotations for migrated primitives
- **bootstrap/*.ecec**: Regenerated via `make bootstrap` (prelude grows, hosts shrink)
