## 1. Investigation

- [x] 1.1 Add diagnostic instrumentation to `serialize-value`: count objects by type (pair, vector, string, number, symbol, compiled-proc, continuation, hash-table, other) and report total and per-type sizes
- [x] 1.2 Serialize a trivial continuation (call/cc with no game state) and categorize what's in it — identify which objects are "code" vs "data"
- [x] 1.3 Trace the exact path: for each large object found, determine HOW it entered the continuation (stack frame? environment frame? transitive reference from a closure?)
- [x] 1.4 Document findings: the "leak" is NOT in the serializer — it's caused by the `(eval (read ...))` double-evaluate pattern used by `ece-eval-string`. When ECE's `eval` calls `mc-compile-and-go` recursively, the inner `call/cc` captures frames from the OUTER mc-compile-and-go executor, which contain compiled instruction sequences and source expressions. Direct `evaluate` from CL produces 72-byte continuations. The serializer is correct; the test helper creates the bloat.

## 2. Root Cause Fix

- [x] 2.1 Restructure `mc-compile-and-go` in compiler.scm to inline `mc-compile` + `mc-instructions` into the `assemble-into-global` call, eliminating the `compiled` let binding that captured the instruction sequence in an env frame
- [x] 2.2 Rebuild bootstrap .ecec files with the fix

## 3. NOT NEEDED — Serializer Filtering

Investigation showed the leak is in mc-compile-and-go's env, not the serializer. No serializer changes needed.

## 4. Verification

- [x] 4.1 Size test: trivial continuation via eval+read serializes to 203 bytes (was 2,563)
- [x] 4.2 Size test: continuation with game-state serializes to 317 bytes (was 4,122)
- [x] 4.3 Size assertion in ECE test: trivial continuation < 500 bytes
- [x] 4.4 Size assertion in ECE test: continuation + game state < 1KB
- [x] 4.5 Functional: all 437 ECE native tests pass
- [x] 4.6 Functional: all 431 rove CL tests pass
