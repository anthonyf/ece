## MODIFIED Requirements

### Requirement: Continuation serialization completes in bounded memory
`serialize-value` SHALL serialize any continuation produced by `call/cc` or `%raw-call/cc` without unbounded memory growth. The serializer SHALL correctly detect shared structure and cycles in all object types (pairs, vectors, compiled procedures, continuations, env chains).

#### Scenario: Trivial continuation round-trip
- **WHEN** a continuation is captured at top level via `(%raw-call/cc (lambda (c) (set! k c) 0))` and serialized via `serialize-value`
- **THEN** serialization SHALL complete with output under 1KB and no OOM

#### Scenario: Continuation captured inside eval-string
- **WHEN** a continuation is captured inside `eval-string` (which adds ECE-level call frames to the stack)
- **THEN** serialization SHALL complete without OOM, correctly handling the deeper env chain

#### Scenario: Self-referencing compiled procedure in env
- **WHEN** a continuation's env chain contains a compiled procedure that closes over itself (recursive function)
- **THEN** the serializer SHALL detect the cycle via shared-structure refs and emit a back-reference, not recurse infinitely

### Requirement: Serializer does not use %env-frame? for object classification
The serializer SHALL NOT use `%env-frame?` to classify objects during scan or serialization passes. Vector frames SHALL be handled by the `(vector? obj)` branch. Env chains (cons lists) SHALL be handled by the `(pair? obj)` branch. Hash frames SHALL be handled by the `(%hash-frame? obj)` branch.

#### Scenario: Env chain traversal
- **WHEN** the serializer encounters an env chain `(#(v1 v2) #(v3) (:hash-frame . ht))`
- **THEN** the pair branch SHALL walk car (vector frame) and cdr (rest of chain), the vector branch SHALL serialize frame values, and the hash-frame check SHALL emit a sentinel
