## ADDED Requirements

### Requirement: Split-pane layout with sandbox and editor/REPL
The sandbox app SHALL have a resizable split-pane layout with a sandbox area (canvas + console output) and a tabbed editor/REPL panel.

#### Scenario: Default layout
- **WHEN** the page loads
- **THEN** the sandbox area SHALL be on the left and the editor/REPL panel on the right

### Requirement: Editor/REPL panel anchorable to any edge
The editor/REPL panel SHALL be anchorable to the left, right, top, or bottom of the sandbox area via a toggle button. The choice SHALL persist across sessions via localStorage.

#### Scenario: Anchor to bottom
- **WHEN** the user clicks the anchor toggle to "bottom"
- **THEN** the sandbox area SHALL be on top and the editor/REPL on the bottom

### Requirement: Tabbed editor and REPL
The editor/REPL panel SHALL have two tabs: Editor and REPL. Each shows its content when selected.

#### Scenario: Switch to REPL tab
- **WHEN** the user clicks the REPL tab
- **THEN** the REPL input/output SHALL be visible and the editor hidden

### Requirement: Code editor with dropdown and run/stop
The editor tab SHALL have a dropdown to select canned programs, a multiline code textarea, and a run/stop button.

#### Scenario: Run a program
- **WHEN** the user clicks [▶ Run]
- **THEN** the editor contents SHALL be compiled and executed in the WASM runtime

#### Scenario: Stop a running program
- **WHEN** the user clicks [■ Stop] while a program is running
- **THEN** the program's continuation SHALL be dropped and execution stops

### Requirement: REPL with multiline input
The REPL tab SHALL have a scrolling output div and a multiline textarea input. Submitting input SHALL compile and evaluate the expression and display the result.

#### Scenario: Evaluate expression
- **WHEN** the user types `(+ 1 2)` and submits
- **THEN** `3` SHALL appear in the output area

### Requirement: Works from file:// protocol
The sandbox SHALL load and run without a web server, using `<script src>` for all assets.

#### Scenario: Open from filesystem
- **WHEN** the user opens `sandbox/index.html` via `file://`
- **THEN** the app SHALL load, boot ECE, and be ready for use
