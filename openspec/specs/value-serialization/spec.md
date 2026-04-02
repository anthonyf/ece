## Requirements

### Requirement: O(n) memory serialization
The `serialize-value` function SHALL use O(n) total memory when serializing structures of depth n, where n is the total number of tokens in the output. The implementation SHALL use port-based output (`open-output-string` / `display` / `get-output-string`) rather than recursive string concatenation.

#### Scenario: Deep environment chain serialization
- **WHEN** serializing a compiled procedure with a deeply nested environment chain (100+ frames)
- **THEN** the serializer SHALL complete without exhausting heap memory and produce a valid serialized string

#### Scenario: Serialization inside nested execution context
- **WHEN** `serialize-value` is called on a compiled procedure created inside a nested compilation context
- **THEN** the serializer SHALL complete successfully and produce output that `deserialize-value` can reconstruct

#### Scenario: Output format unchanged
- **WHEN** serializing any value
- **THEN** the output SHALL be identical to the previous `string-append` implementation for the same input

#### Scenario: Cyclic structure round-trip via deserialize-value
- **WHEN** deserializing a serialized value that contains cyclic references (via `%ser/def`/`%ser/ref` tags where a `%ser/ref` appears inside the body of its own `%ser/def`)
- **THEN** `deserialize-value` SHALL reconstruct the cycle correctly with the back-reference resolving to the pre-allocated placeholder

### Requirement: serializer detects and skips code objects
The `serialize-value` function SHALL detect code-like objects (instruction vectors, compilation space internals) and emit skip sentinels instead of recursively serializing them.

#### Scenario: Vector containing instructions
- **WHEN** serializing a vector whose elements are instruction lists (e.g., `(assign val ...)`)
- **THEN** the serializer SHALL emit `(%ser/code-skip)` instead of serializing each instruction

#### Scenario: Data vector preserved
- **WHEN** serializing a vector like `#(1 2 3)` or `#("a" "b")`
- **THEN** the serializer SHALL serialize it normally as `(%ser/vector 1 2 3)`

### Requirement: String output ports
The runtime SHALL provide `open-output-string` and `get-output-string` as core primitives on all platforms.

#### Scenario: Basic string port round-trip
- **GIVEN** a port created by `(open-output-string)`
- **WHEN** characters or strings are written via `display` / `write` / `write-char`
- **THEN** `(get-output-string port)` SHALL return the accumulated content as a string

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
