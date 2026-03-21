## ADDED Requirements

### Requirement: current-milliseconds primitive
The `current-milliseconds` primitive SHALL return the elapsed time since page load as an integer (fixnum), using `performance.now()` for precision without fixnum overflow.

#### Scenario: Time measurement
- **WHEN** `(current-milliseconds)` is called twice with work in between
- **THEN** the second call SHALL return a value greater than or equal to the first

#### Scenario: FPS calculation
- **WHEN** a program computes `(/ frames (/ (- (current-milliseconds) start-time) 1000))`
- **THEN** the result SHALL approximate the actual frames-per-second rate
