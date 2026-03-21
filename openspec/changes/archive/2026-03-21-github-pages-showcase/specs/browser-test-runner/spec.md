## ADDED Requirements

### Requirement: ECE test suite runs in browser
A self-contained HTML page SHALL boot the ECE WASM runtime, run the compiled test suite, and display results as styled HTML.

#### Scenario: Tests execute and display results
- **WHEN** a user visits the test page
- **THEN** the page SHALL boot ECE, run all WASM tests, and display the pass/fail count with individual test results

#### Scenario: Pass/fail styling
- **WHEN** tests complete
- **THEN** passing tests SHALL be shown in green and failing tests in red
