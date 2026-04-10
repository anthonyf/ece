## ADDED Requirements

### Requirement: Animated sine-wave color field
The program SHALL render an animated plasma effect by combining multiple sine wave functions to produce smoothly varying color values across the canvas.

#### Scenario: Smooth color variation
- **WHEN** the program renders a frame
- **THEN** each block SHALL have a color determined by a combination of sine functions of its position and a time parameter

#### Scenario: Continuous animation
- **WHEN** the program runs
- **THEN** it SHALL animate continuously, updating colors each frame via `yield`, producing a flowing color effect

### Requirement: Block-based rendering for performance
The program SHALL render in NxN blocks (e.g., 4x4) rather than individual pixels to maintain smooth frame rates.

#### Scenario: Block rendering
- **WHEN** the program draws a frame
- **THEN** it SHALL iterate over blocks covering the canvas, drawing one filled rectangle per block

### Requirement: RGB color synthesis
The program SHALL produce colors by mapping sine wave output values to separate R, G, B channels.

#### Scenario: Full color range
- **WHEN** the plasma renders across the canvas
- **THEN** it SHALL display a range of colors spanning multiple hues, not just grayscale

### Requirement: Manifest registration
The program SHALL be registered in `sandbox/programs/manifest.sexp` with a descriptive name.

#### Scenario: Program appears in sandbox
- **WHEN** a user opens the sandbox
- **THEN** "Plasma" SHALL appear as a selectable program in the dropdown
