## ADDED Requirements

### Requirement: room macro defines a room function
The IF library SHALL provide a `room` macro that defines a zero-argument function for each room. The room function SHALL display description text and evaluate the body.

#### Scenario: Define and enter a room
- **WHEN** defining `(room my-room "Description text." body...)` and calling `(my-room)`
- **THEN** the description text SHALL be displayed and the body SHALL be evaluated

### Requirement: room navigation via tail calls
Rooms defined with the `room` macro SHALL be navigable via tail calls (GOTO pattern), meaning navigation between rooms does not consume stack space.

#### Scenario: Navigate between rooms
- **WHEN** a choice in one room calls another room function in tail position
- **THEN** control SHALL transfer to the new room without consuming stack space
