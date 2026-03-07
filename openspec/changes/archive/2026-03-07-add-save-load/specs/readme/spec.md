## MODIFIED Requirements

### Requirement: README describes the project
The README SHALL include a title, a brief description of what ECE is (an explicit control evaluator for a small Lisp), and a list of supported language features. The roadmap SHALL accurately reflect implementation progress: Priorities 1 and 2 marked complete, Priority 3 marked current.

#### Scenario: Reader understands what ECE is
- **WHEN** a user reads the README
- **THEN** they SHALL understand that ECE is an explicit control evaluator implementing quote, lambda, if, begin, call/cc, and primitive procedures

#### Scenario: Roadmap reflects current progress
- **WHEN** a user reads the roadmap
- **THEN** Priorities 1 and 2 SHALL be marked as complete and Priority 3 SHALL be marked as current
