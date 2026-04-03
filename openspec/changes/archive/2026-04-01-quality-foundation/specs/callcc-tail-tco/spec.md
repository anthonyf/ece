## MODIFIED Requirements

### Requirement: Tail-position call/cc executes in constant stack space
The compiler SHALL generate code for `call/cc` in tail position that does not save the `continue` register, capturing the continuation with the caller's return address directly and dispatching to the receiver as a true tail call. The stack SHALL NOT grow when `call/cc` is used in a tail-recursive loop. This SHALL work on both CL and WASM runtimes.

#### Scenario: Tail-recursive call/cc loop at 10,000 iterations on CL
- **WHEN** evaluating a tail-recursive function that calls `call/cc` in tail position for 10,000 iterations on the CL runtime
- **THEN** the result SHALL be a continuation (verified via `continuation?`) and execution SHALL complete without stack overflow

#### Scenario: Tail-recursive call/cc loop at 10,000 iterations on WASM
- **WHEN** evaluating a tail-recursive function that calls `call/cc` in tail position for 10,000 iterations on the WASM runtime
- **THEN** the result SHALL be a continuation (verified via `continuation?`) and execution SHALL complete without stack overflow or hanging

#### Scenario: Captured continuation size is O(1) regardless of iteration count
- **WHEN** capturing a continuation via tail-position `call/cc` after N iterations of a tail-recursive loop
- **THEN** the serialized size of the captured continuation SHALL NOT grow with N

#### Scenario: Non-tail call/cc is unchanged
- **WHEN** evaluating `call/cc` in a non-tail position (e.g., in a `let` binding)
- **THEN** the compiler SHALL generate the same return-label trampoline code as before, with save/restore of `continue`

### Requirement: Tail-position call/cc dispatches correctly for all procedure types
The tail-position `call/cc` code path SHALL correctly dispatch to compiled procedures, primitive procedures, and continuation objects as the receiver. This SHALL work on both CL and WASM runtimes.

#### Scenario: Compiled procedure as receiver in tail position
- **WHEN** `call/cc` is in tail position and the receiver is a compiled procedure (lambda)
- **THEN** the receiver SHALL be called as a true tail call with `continue` pointing to the original caller

#### Scenario: Continuation invoked from tail-position call/cc receiver
- **WHEN** a continuation captured by tail-position `call/cc` is invoked with a value
- **THEN** execution SHALL resume at the capture point with the given value, and dynamic-wind handlers SHALL be invoked correctly

#### Scenario: Tail-position call/cc in if alternative
- **WHEN** `call/cc` appears in the alternative branch of an `if` in tail position, looping 10,000 times
- **THEN** execution SHALL complete without stack overflow on both CL and WASM
