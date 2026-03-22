## Context

The sandbox has canvas primitives (clear, fill-rect, fill-circle, draw-text, width, height), animation via `yield`, and timing via `current-milliseconds`. Missing: trig functions for circular motion. WAT provides `f64.sin` and `f64.cos` natively.

## Goals / Non-Goals

**Goals:**
- sin/cos work with both fixnum and float args, return float
- Three visually distinct examples: static recursive, animated particles, animated trig
- Each example is self-contained and readable (~30-50 lines)

**Non-Goals:**
- Full math library (tan, atan, sqrt, etc.) — just sin/cos for now
- Keyboard/mouse input

## Decisions

### 1. sin/cos primitive implementation

Both take one numeric arg (radians) and return a float. Use `$to-f64` to handle both fixnum and float inputs, then `f64.sin`/`f64.cos`, wrap result in `$make-float`.

IDs 152 and 153 (right after `current-milliseconds` at 151).

### 2. Sierpinski Triangle

Draw using the chaos game algorithm: pick a random point, repeatedly move halfway toward a random vertex, plot each point. This avoids recursion depth issues and produces the fractal progressively. Use `canvas-fill-rect` with 1x1 rectangles as pixels.

Runs once (no animation) — plots ~10,000 points.

### 3. Starfield

Create a list of star structs (x, y, z). Each frame: move z closer, project to 2D using perspective division (`screen-x = x/z`, `screen-y = y/z`), draw as small rectangles. When z <= 0, reset to far distance. Brightness varies with z.

Animated via yield loop.

### 4. Analog Clock

Draw clock face as 12 hour marks (small circles at trig positions). Three hands (hour, minute, second) drawn as lines from center using sin/cos. Time from `current-milliseconds` converted to h/m/s.

Lines drawn as thin filled rectangles (no line primitive). Or use canvas-fill-circle at two endpoints connected by... actually, simplest: draw hands as sequences of small circles along the line, or just draw the endpoint circle.

**Choice:** Draw each hand as a filled circle at the tip position. Simple and clean. Hour marks as small circles at the 12 positions.

Animated via yield loop.
