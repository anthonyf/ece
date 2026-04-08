## 1. Refactor Sandbox Programs

- [x] 1.1 Refactor `analog-clock.scm` — replace internal `define`s in `draw-clock`, `marks`, and `hand` with `let*`
- [x] 1.2 Refactor `game-loop.scm` — replace internal `define`s in `game-loop` with `let*`
- [x] 1.3 Refactor `sierpinski-triangle.scm` — replace internal `define`s in `go` with `let*`
- [x] 1.4 Refactor `starfield.scm` — replace internal `define`s in `update` with `let*`

## 2. Verify

- [x] 2.1 Run `make test-wasm` to confirm sandbox programs still work (WASM runtime loads them)
