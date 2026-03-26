## Approach (revised)

The original plan (skip wrapper when winding stack is empty) breaks R7RS compliance: a continuation captured OUTSIDE `dynamic-wind` but invoked INSIDE must still run the `after` thunks. The wrapper is always needed for `call/cc`.

**Revised approach**: Add `save-game!` / `load-game!` macros that use `%raw-call/cc` directly. These are the public API for IF game save/load — they bypass `dynamic-wind` entirely. `call/cc` stays unchanged for R7RS compliance.

```scheme
(define-macro (save-game! filename)
  `(%raw-call/cc (lambda (k)
     (save-continuation! ,filename k)
     #t)))

(define (load-game! filename)
  (define k (load-continuation filename))
  (k #f))
```

Usage:
```scheme
(define saved? (save-game! "save.dat"))
(if saved?
    (display "Game saved!")
    (display "Game loaded!"))
```

- `save-game!` captures a raw continuation, saves it, returns `#t`
- `load-game!` loads and invokes it, returning `#f` at the capture point
- The `#t`/`#f` return distinguishes save vs load path

## Key Decision

Separate game save/load from `call/cc`. Game state uses parameters (not `dynamic-wind`), so raw continuations are correct. The IF library layer provides the clean API; `call/cc` stays R7RS-compliant.
