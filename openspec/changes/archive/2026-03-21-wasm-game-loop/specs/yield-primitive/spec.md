## ADDED Requirements

### Requirement: %yield! has working resume on WASM
The `%yield!` primitive SHALL have a complete yield-and-resume cycle on the WASM platform, with the sandbox invoking the stored continuation via the WASM `call_continuation` export.

#### Scenario: Yield stores and resume invokes
- **WHEN** ECE code calls `(%yield! k)` where `k` is a continuation
- **THEN** the continuation SHALL be stored, the executor SHALL exit, and the JS animation loop SHALL invoke the continuation with void as the resume value
