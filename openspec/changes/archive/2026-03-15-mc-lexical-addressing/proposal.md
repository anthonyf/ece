## Why

The metacircular compiler (`compiler.scm`) emits name-based variable access for all variables — every reference does an O(n) environment scan. The CL compiler (`compiler.lisp`) already emits O(1) lexical-ref/lexical-set! instructions with vector-backed frames, but it's the bootstrap compiler we want to remove. Porting lexical addressing to the ECE compiler is the prerequisite for eliminating `compiler.lisp` entirely and making ECE fully self-hosted.

## What Changes

- Restructure `*mc-compile-lexical-env*` from a flat name list into a list of frames (each frame a list of variable names), matching the CL compiler's `*compile-lexical-env*`
- Add `mc-find-variable` that returns `(depth . offset)` lexical addresses
- Emit `lexical-ref` / `lexical-set!` for variables with known lexical addresses; fall back to name-based ops only for globals
- `mc-compile-lambda-body` computes extra-slots from internal defines and emits 4-arg `extend-environment` to create vector frames
- Internal defines compile as `lexical-set!` into pre-allocated frame slots instead of `define-variable!`
- `mc-extract-define-names` recurses into `begin` blocks and expands compile-time macros to find all internal defines (matching the CL compiler's depth of analysis)

## Capabilities

### New Capabilities
- `mc-lexical-addressing`: Lexical address computation and O(1) variable access in the metacircular compiler

### Modified Capabilities
- `lexical-addressing`: Requirement "global environment retains list-based frames" changes — global frame is now a hash-table frame (from recent hash-table-global-frame change). Update scenario accordingly.

## Impact

- `src/compiler.scm`: Major changes — lexical env restructured, new find-variable, all variable/assignment/define compilation updated
- `src/runtime.lisp`: No changes — `lexical-ref`, `lexical-set!`, `extend-environment` with extra-slots already exist
- Performance: All ECE-compiled code gains O(1) variable access (currently O(n) name scan)
- After this change: `compiler.lisp` can be removed, list-based frame code (`make-frame`, `frame-variables`, `frame-values`, 3-arg `extend-environment` path, list-scan in lookup/set/define) becomes dead code
