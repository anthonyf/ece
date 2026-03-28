## ADDED Requirements

### Requirement: Canvas drawing primitives
Browser platform primitives (IDs 200+) SHALL provide basic 2D canvas operations.

#### Scenario: Clear and draw
- **WHEN** `(canvas-clear)` then `(canvas-fill-rect 10 10 50 50)` are called
- **THEN** the canvas SHALL be cleared and a 50x50 rectangle drawn at (10,10)

### Requirement: Canvas primitives registered in primitives.def
Canvas primitives SHALL have stable IDs in the browser platform range (200-299).

#### Scenario: Primitives available
- **WHEN** the sandbox boots
- **THEN** `canvas-clear`, `canvas-set-fill-color`, `canvas-fill-rect`, `canvas-fill-circle`, `canvas-draw-text`, `canvas-width`, `canvas-height` SHALL be available
