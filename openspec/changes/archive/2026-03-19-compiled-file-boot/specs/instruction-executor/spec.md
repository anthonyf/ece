## MODIFIED Requirements

### Requirement: executor uses symbol space IDs
The executor's `space-id` local variable, `*executing-space-id*`, and `*current-space-id*` SHALL be symbols, not integers.

#### Scenario: Space switch with symbols
- **WHEN** `(goto (reg continue))` targets `(prelude . 4523)`
- **AND** the current space is `compiler`
- **THEN** the executor SHALL compare symbols with `eq`
- **AND** SHALL look up `prelude` in the symbol-keyed `*space-registry*`
- **AND** SHALL update `instrs`, `ltab`, and `space-id` locals

### Requirement: assign label qualifies with symbol
The `assign` instruction for `continue` with a `label` source SHALL qualify the resolved PC with the current space's symbol.

#### Scenario: Label assignment in space
- **WHEN** `(assign continue (label after-call-42))` executes in space `compiler`
- **THEN** the `continue` register SHALL be set to `(compiler . <resolved-pc>)`
