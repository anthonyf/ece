# Browser App Libraries Plan

ECE browser apps should move toward ECE-owned UI code with a small host
surface. The browser still provides the WebAssembly runtime, WebSocket, DOM, and
canvas capabilities, but application structure should increasingly live in ECE
modules instead of app-specific JavaScript and handwritten HTML.

This plan tracks the work across multiple PRs so the next step is visible after
each merge.

## Design Rules

- Keep JavaScript as capability glue: runtime startup, WebAssembly loading,
  WebSocket transport, and low-level FFI handles.
- Put reusable app behavior in ECE modules.
- Keep generated HTML as ordinary data or strings so it is easy to test without
  a browser.
- Keep canvas drawing as an explicit module over the existing browser FFI.
- Preserve the current `ece-serve` workflow while templates become smaller.

## Phase 1 - HTML and DOM Foundation

Status: in progress.

- Add `(ece browser dom)` as a module boundary over the existing DOM FFI helpers.
- Add `(ece browser html)` with an `(html ...)` convenience macro and pure
  `html-render` / `html-render-fragment` functions.
- Update the web-app skeleton so ECE renders the app surface into a minimal root
  element.
- Add CL-side tests for HTML rendering and module imports.

Example:

```scheme
(set-html!
 (get-element-by-id "app-root")
 (html (:main :class "app-shell"
        (:canvas :id "sandbox-canvas")
        (:section :class "hud"
          (:p "Hello from ECE")))))
```

## Phase 2 - Canvas Module

- Add `(ece browser canvas)` as the public home for canvas functions.
- Keep compatibility aliases for current global `canvas-*` helpers while
  sandbox apps migrate.
- Document the expected canvas element id and initialization path.
- Convert one sandbox program to import/use the module shape.

## Phase 3 - Runtime Service Modules

- Identify reusable browser services already implemented in ECE:
  scheduler, dev reload policy, JSON/websocket codec helpers, and wasm host
  resource helpers.
- Move browser-facing service APIs behind modules where they have stable
  boundaries.
- Keep transport ownership clear: JavaScript owns the socket capability; ECE
  owns message policy and app behavior.

## Phase 4 - Template and Sandbox Reduction

- Reduce `templates/web-app/index.html` to runtime boot, one app root, and one
  output/log root.
- Convert sandbox demos incrementally so app DOM structure is built from ECE.
- Document browser app structure with small module examples.

## Open Questions

- Macro exports are not a full module-system feature yet. Phase 1 installs the
  `html` macro during bootstrap, while the module exports testable renderer
  functions. A later module phase can add proper macro exports/imports.
- The current DOM renderer writes HTML strings into an element. A future
  structured DOM builder may create nodes directly through FFI when event-rich
  views need it.
