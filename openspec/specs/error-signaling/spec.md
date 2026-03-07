## ADDED Requirements

### Requirement: error signals an error with a message
The evaluator SHALL provide `error` as a primitive that signals an error condition with a string message.

#### Scenario: Signal an error
- **WHEN** evaluating `(error "something went wrong")`
- **THEN** an error condition SHALL be signaled with the message "something went wrong"

#### Scenario: Error is catchable by try-eval
- **WHEN** evaluating `(try-eval (error "oops"))`
- **THEN** the result SHALL be nil (error was caught, no crash)
