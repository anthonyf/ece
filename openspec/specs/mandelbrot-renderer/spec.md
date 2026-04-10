## ADDED Requirements

### Requirement: Mandelbrot set computation
The program SHALL compute the Mandelbrot set by iterating z = z² + c for each pixel, mapping canvas coordinates to the complex plane range approximately (-2.5, 1.0) on the real axis and (-1.2, 1.2) on the imaginary axis.

#### Scenario: Point inside the set
- **WHEN** a pixel maps to a point where iteration does not escape (|z| never exceeds 2.0 within max iterations)
- **THEN** the pixel SHALL be rendered black

#### Scenario: Point outside the set
- **WHEN** a pixel maps to a point where |z| exceeds 2.0 at iteration count N
- **THEN** the pixel SHALL be colored based on N using an RGB gradient

### Requirement: Progressive scanline rendering
The program SHALL render the fractal progressively, yielding between rows so the image visibly sweeps down the screen.

#### Scenario: Row-by-row rendering
- **WHEN** the program runs
- **THEN** it SHALL render one or more complete rows per frame, calling `yield` between batches

### Requirement: Color gradient mapping
The program SHALL map iteration counts to visually distinct RGB colors using a smooth gradient.

#### Scenario: Color variation across escape speeds
- **WHEN** pixels have different iteration escape counts
- **THEN** they SHALL display visually distinguishable colors forming a smooth gradient

### Requirement: Manifest registration
The program SHALL be registered in `sandbox/programs/manifest.sexp` with a descriptive name.

#### Scenario: Program appears in sandbox
- **WHEN** a user opens the sandbox
- **THEN** "Mandelbrot" SHALL appear as a selectable program in the dropdown
