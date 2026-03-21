## 1. Yield Primitive

- [x] 1.1 Add yield flag global and check in executor loop (runtime.wat)
- [x] 1.2 Add `%yield!` primitive: stores continuation in global, sets yield flag (runtime.wat)
- [x] 1.3 Add prelude `yield` function wrapping `call/cc` + `%yield!`
- [x] 1.4 Export yield-related globals/functions for JS access
- [x] 1.5 Add yield primitive ID 150 to primitives.def

## 2. Canvas Primitives

- [x] 2.1 Add canvas JS imports to runtime.wat (7 functions)
- [x] 2.2 Add canvas primitive IDs (200-206) to primitives.def
- [x] 2.3 Wire canvas primitives in $apply-primitive dispatch
- [x] 2.4 Add canvas stubs to glue.js (overridden by sandbox.js)
- [x] 2.5 Register yield + canvas primitives in glue.js buildGlobalEnv

## 3. Build Tooling

- [x] 3.1 Create scripts/build-sandbox.sh (encode wasm+ececb as base64 in JS)
- [x] 3.2 Add `make sandbox` Makefile target
- [x] 3.3 Add generated files to .gitignore

## 4. Sandbox HTML/CSS

- [x] 4.1 Create sandbox/index.html with split-pane layout
- [x] 4.2 CSS flexbox layout with anchor classes
- [x] 4.3 Canvas element + console output div in sandbox area
- [x] 4.4 Tab bar with Editor/REPL tabs
- [x] 4.5 Anchor toggle button

## 5. Editor Panel

- [x] 5.1 Tabbed interface (Editor / REPL)
- [x] 5.2 Editor: dropdown, textarea, run/stop button
- [x] 5.3 Create ece-programs.js with Hello World
- [x] 5.4 Run: compile via ECE self-hosted compiler (localStorage temp file + load)
- [x] 5.5 Stop: drop continuation, reset yield flag

## 6. REPL Panel

- [x] 6.1 REPL: scrolling output div + multiline textarea + Eval button
- [x] 6.2 Eval: pass input through ECE compile-and-go, display result
- [x] 6.3 Ctrl+Enter shortcut for eval

## 7. Sandbox JS

- [x] 7.1 Create sandbox.js: WASM boot from base64, canvas bridge, REPL bridge
- [x] 7.2 Animation frame loop for yield resume (skeleton)
- [x] 7.3 Route display/newline to console div

## 8. Validation

- [x] 8.1 make sandbox builds successfully
- [ ] 8.2 Sandbox boots in browser from file://
- [ ] 8.3 REPL evaluates (+ 1 2)
- [ ] 8.4 Hello World runs from editor
- [x] 8.5 Existing WASM tests: 329/0
