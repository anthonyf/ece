## ADDED Requirements

### Requirement: README describes the project
The README SHALL include a title, a brief description of what ECE is (an explicit control evaluator for a small Lisp), and a list of supported language features.

#### Scenario: Reader understands what ECE is
- **WHEN** a user reads the README
- **THEN** they SHALL understand that ECE is an explicit control evaluator implementing quote, lambda, if, begin, call/cc, and primitive procedures

### Requirement: README includes setup and usage instructions
The README SHALL document prerequisites (SBCL, qlot), setup steps, how to load the system, and how to run tests.

#### Scenario: Reader can set up and run the project
- **WHEN** a user follows the README instructions
- **THEN** they SHALL be able to install dependencies with qlot, load the system, evaluate expressions, and run tests
