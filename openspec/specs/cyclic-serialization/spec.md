## Requirements

### Requirement: Cyclic pair structures survive serialization round-trip
The `deserialize-value` function SHALL correctly reconstruct cyclic object graphs where pairs form the cycle link, by pre-allocating a mutable pair placeholder in the ref-table before recursing into `%ser/def` bodies.

#### Scenario: Letrec with self-referencing closure
- **WHEN** serializing and deserializing a closure created by `letrec` that references its own binding frame (e.g., `(letrec ((f (lambda (x) (if (= x 0) 1 (* x (f (- x 1))))))) f)`)
- **THEN** the deserialized closure SHALL be callable and produce correct results (e.g., `(f 5)` returns `120`)

#### Scenario: Recursive define in let body
- **WHEN** serializing and deserializing a closure created by `define` inside a `let` body where the closure references itself
- **THEN** the deserialized closure SHALL be callable and correctly recurse

#### Scenario: Mutual recursion in shared frame
- **WHEN** serializing and deserializing two closures that reference each other through a shared frame (e.g., `(letrec ((even? (lambda (n) (if (= n 0) #t (odd? (- n 1))))) (odd? (lambda (n) (if (= n 0) #f (even? (- n 1)))))) (list even? odd?))`)
- **THEN** both deserialized closures SHALL be callable and correctly dispatch to each other

### Requirement: Non-cyclic serialization is unchanged
The pre-allocate-and-patch mechanism SHALL NOT alter the behavior or output of non-cyclic serialization round-trips.

#### Scenario: Plain values round-trip unchanged
- **WHEN** serializing and deserializing non-cyclic values (numbers, strings, lists, vectors, compiled procedures without self-reference)
- **THEN** the deserialized values SHALL be identical to the originals

#### Scenario: Shared but non-cyclic structure preserved
- **WHEN** serializing a value with shared sub-structure that is NOT cyclic (e.g., two references to the same list)
- **THEN** `%ser/def`/`%ser/ref` SHALL still correctly deduplicate, and the deserialized structure SHALL share identity where the original did
